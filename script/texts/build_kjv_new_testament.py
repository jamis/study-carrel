#!/usr/bin/env python3
"""Builds db/texts/<book>-kjv.txt for the 27 books of the New Testament.

Same method and sources as build_kjv_old_testament.py (see there for how the
three sources are compared and reconciled); the Gutenberg file is the whole
Bible, and this script reads its New Testament half. Books are positioned 1-27
within the "new-testament" collection.

Usage: build_kjv_new_testament.py GUTENBERG.txt B.json C.json [OUT_DIR]
"""
import json, re, sys, collections
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from build_kjv_old_testament import words as _words, clean_b as _clean_b


def clean_b(s):
    # Gutenberg writes Caesar, not Cæsar; keep the whole book consistent when source b's text is used.
    return _clean_b(s).replace("æ", "ae").replace("Æ", "Ae").replace("œ", "oe").replace("Œ", "Oe")


def words(s):
    # Proper names are spelled Caesar / Cæsar / Cesar in the three sources; compare them as one.
    return re.sub(r"ae|oe|æ|œ", "e", _words(s.lower()))

CHAPTERS = [28,16,24,21,28,16,16,13,6,6,4,4,5,3,6,4,3,1,13,5,5,3,5,1,1,1,22]
BOOKS = ["Matthew","Mark","Luke","John","Acts","Romans","1 Corinthians","2 Corinthians","Galatians","Ephesians","Philippians","Colossians","1 Thessalonians","2 Thessalonians","1 Timothy","2 Timothy","Titus","Philemon","Hebrews","James","1 Peter","2 Peter","1 John","2 John","3 John","Jude","Revelation"]
OT_COUNT = 39  # the other two sources list all 66 books


def parse_gutenberg(path):
    text = Path(path).read_text(encoding="utf-8-sig").replace("\r", "")
    marker = "The New Testament of the King James Bible"
    start = text.index("1:1 The book of the generation of Jesus Christ")
    end = text.index("*** END OF THE PROJECT GUTENBERG", start)
    body = text[start:end]
    first_title = text.index("The Gospel According to Saint Matthew")
    toc = [l.strip() for l in text[first_title:].splitlines()[:27]]
    is_title = lambda p: any(p.startswith(t) for t in toc) and not re.match(r"\d+:\d+", p)

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
    assert book == 26, book

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


def main(gutenberg, bpath, cpath, out="db/texts"):
    base = parse_gutenberg(gutenberg)
    b_src = json.loads(Path(bpath).read_text(encoding="utf-8-sig"))[OT_COUNT:]
    c_src = json.loads(Path(cpath).read_text())["books"][OT_COUNT:]
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
        lines = [f"work: {name}", "edition: KJV", f"slug: {slug}", "collection: new-testament", f"position: {bi}", ""]
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
