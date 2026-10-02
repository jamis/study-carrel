#!/usr/bin/env python3
"""Builds db/texts/<book>-kjv.txt for the 39 books of the Old Testament.

Sources (all public domain; download them first, none are checked in):
  gutenberg  https://www.gutenberg.org/cache/epub/10/pg10.txt
  b          https://raw.githubusercontent.com/thiagobodruk/bible/master/json/en_kjv.json
  c          https://raw.githubusercontent.com/scrollmapper/bible_databases/master/formats/json/KJV.json

The Gutenberg text is the base because it has the nicest typography (curly
quotes, small-caps LORD). Every verse is compared, word by word and ignoring
punctuation/case/hyphens/spacing, with the other two sources:

  * if the base agrees with either other source, the base text is kept;
  * if the two other sources agree with each other against the base, the base
    has a transcription difference, so source b's text (spacing cleaned) is used;
  * if all three differ, source b is used and the verse is listed in the report.

Gutenberg's book-title and subtitle lines ("Otherwise Called: ...") are stripped.

Usage: build_kjv_old_testament.py GUTENBERG.txt B.json C.json [OUT_DIR]
"""
import json, re, sys, collections
from pathlib import Path

CHAPTERS = [50,40,27,36,34,24,21,4,31,24,22,25,29,36,10,13,10,42,150,31,12,8,66,52,5,48,12,14,3,9,1,4,7,3,3,3,2,14,4]
BOOKS = ["Genesis","Exodus","Leviticus","Numbers","Deuteronomy","Joshua","Judges","Ruth","1 Samuel","2 Samuel","1 Kings","2 Kings","1 Chronicles","2 Chronicles","Ezra","Nehemiah","Esther","Job","Psalms","Proverbs","Ecclesiastes","Song of Solomon","Isaiah","Jeremiah","Lamentations","Ezekiel","Daniel","Hosea","Joel","Amos","Obadiah","Jonah","Micah","Nahum","Habakkuk","Zephaniah","Haggai","Zechariah","Malachi"]
SUBTITLES = {"Otherwise Called:", "Commonly Called:", "or", "The Preacher"}


def parse_gutenberg(path):
    text = Path(path).read_text(encoding="utf-8-sig").replace("\r", "")
    start = text.index("1:1 In the beginning God created")
    body = text[start:text.index("The New Testament of the King James Bible", start)]
    toc = [l.strip() for l in text.splitlines()[24:64] if l.strip()]
    is_title = lambda p: (any(p.startswith(t) for t in toc) and not re.match(r"\d+:\d+", p)) or p in SUBTITLES

    marks, book, last = [], -1, (0, 0)
    for m in re.finditer(r"(?:(?<=\s)|^)(\d+):(\d+)(?=\s)", body):
        c, v = int(m.group(1)), int(m.group(2))
        if (c, v) == (1, 1) and (book == -1 or last[0] == CHAPTERS[book]):
            book += 1
        elif c == last[0] and v == last[1] + 1:
            pass
        elif c == last[0] + 1 and v == 1 and c <= CHAPTERS[book]:
            pass
        else:
            continue
        marks.append((book, c, v, m.end()))
        last = (c, v)
    assert book == 38, book

    books = [{} for _ in BOOKS]
    for i, (b, c, v, end) in enumerate(marks):
        nxt = marks[i + 1] if i + 1 < len(marks) else None
        stop = len(body) if nxt is None else body.rfind(f"{nxt[1]}:{nxt[2]}", end, nxt[3])
        paras = [" ".join(p.split()) for p in re.split(r"\n\s*\n", body[end:stop]) if p.strip()]
        if nxt is None or nxt[0] != b:
            paras = [p for p in paras if not is_title(p)]
        books[b].setdefault(c, {})[v] = " ".join(paras)

    for b, n in zip(books, CHAPTERS):
        assert sorted(b) == list(range(1, n + 1))
        for c, vs in b.items():
            assert sorted(vs) == list(range(1, len(vs) + 1))
    return books


def words(s):
    s = re.sub(r"\{[^}]*\}", "", s).lower().replace("¶", "")
    s = re.sub(r"^[֐-׿]+\s+[a-z]+\.\s+", "", s)  # source c's Hebrew stanza headings (Psalm 119)
    return "".join(re.findall(r"[a-z0-9]+", re.sub(r"[-'’–]", "", s)))


def clean_b(s):
    s = s.replace("¶", "")
    s = re.sub(r"\s+([,.;:?!)”’])", r"\1", s)
    s = re.sub(r"([(“‘])\s+", r"\1", s)
    return " ".join(s.split())


def main(gutenberg, bpath, cpath, out="db/texts"):
    base = parse_gutenberg(gutenberg)
    b_src = json.loads(Path(bpath).read_text(encoding="utf-8-sig"))
    c_src = json.loads(Path(cpath).read_text())["books"]
    stats, patched, unresolved = collections.Counter(), [], []

    for bi, book in enumerate(base):
        assert len(b_src[bi]["chapters"]) == CHAPTERS[bi] == len(c_src[bi]["chapters"])
        for c, verses in book.items():
            for v in verses:
                g = verses[v]
                b = b_src[bi]["chapters"][c - 1][v - 1]
                cc = c_src[bi]["chapters"][c - 1]["verses"][v - 1]["text"]
                wg, wb, wc = words(g), words(b), words(cc)
                if wg == wb == wc:
                    stats["all three agree"] += 1
                elif wg in (wb, wc):
                    stats["base agrees with one other"] += 1
                elif wb == wc:
                    verses[v] = clean_b(b)
                    stats["base replaced (others agree)"] += 1
                    patched.append((BOOKS[bi], c, v, g, verses[v]))
                else:
                    verses[v] = clean_b(b)
                    stats["all differ (used b)"] += 1
                    unresolved.append((BOOKS[bi], c, v, g, b, cc))

    outdir = Path(out)
    for bi, (name, book) in enumerate(zip(BOOKS, base), start=1):
        slug = f"{name} KJV".lower().replace(" ", "-")
        lines = [f"work: {name}", "edition: KJV", f"slug: {slug}", "collection: old-testament", f"position: {bi}", ""]
        for c in sorted(book):
            lines.append(f"section: {c}")
            lines += [f"{v}. {book[c][v]}" for v in sorted(book[c])]
            lines.append("")
        (outdir / f"{slug}.txt").write_text("\n".join(lines))

    print(dict(stats))
    print("verses written:", sum(len(vs) for b in base for vs in b.values()))
    print("\nReplaced because the other two sources agree against the base:")
    for b, c, v, old, new in patched:
        print(f"  {b} {c}:{v}")
    print("\nAll three differ (used source b):")
    for b, c, v, g, bb, cc in unresolved:
        print(f"  {b} {c}:{v}\n    base: {g}\n    b:    {bb}\n    c:    {cc}")


if __name__ == "__main__":
    main(*sys.argv[1:])
