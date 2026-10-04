#!/usr/bin/env python3
"""Builds db/texts for the world-scripture batch and Marcus Aurelius, from Project Gutenberg.

Sources (all public domain; download first, none are checked in):
  dhammapada  https://www.gutenberg.org/cache/epub/2017/pg2017.txt   F. Max Müller (Sacred Books of the East, 1881)
  tao         https://www.gutenberg.org/cache/epub/216/pg216.txt     James Legge (Sacred Books of the East, 1891)
  gita        https://www.gutenberg.org/cache/epub/2388/pg2388.txt   Sir Edwin Arnold, The Song Celestial (1885)
  quran       https://www.gutenberg.org/cache/epub/2800/pg2800.txt   J. M. Rodwell (1861)
  meditations https://www.gutenberg.org/cache/epub/2680/pg2680.txt   Meric Casaubon (1634)

Each has a single source (Gutenberg's proofreading). Works go in "sacred-texts"
(Meditations in "prose"), a section per chapter, a unit per verse or paragraph.
The Quran is Rodwell's, with the suras put back in the traditional order (his
edition arranges them chronologically) and numbered traditionally.

Usage: build_world_scripture.py DIR_WITH_pgNNNN.txt_FILES [OUT_DIR]
"""
import re, sys
from pathlib import Path

DEBUG = False
ROMAN = {"I": 1, "V": 5, "X": 10, "L": 50, "C": 100}


def roman(s):
    n, prev = 0, 0
    for ch in reversed(s):
        v = ROMAN[ch]
        n += v if v >= prev else -v
        prev = max(prev, v)
    return n


def body(path):
    t = Path(path).read_text(encoding="utf-8-sig").replace("\r", "")
    start = t.index("\n", t.index("*** START OF")) + 1
    return t[start:t.index("*** END OF")]


def paras(text):
    return [p for p in re.split(r"\n\s*\n", text) if p.strip()]


def flat(s):
    return " ".join(s.split())


def typography(s):
    s = s.replace("``", "“").replace("''", "”").replace("_", "")
    s = re.sub(r"\s*--\s*", "—", s)
    s = re.sub(r'(^|[\s(\[—])"', r"\1“", s).replace('"', "”")
    s = re.sub(r"(^|[\s(\[—“])'(?=\w)", r"\1‘", s)
    return s.replace("'", "’")


def write(out, slug, header, sections, keep_lines=False):
    """sections: list of (number, label or None, [unit text, ...])"""
    lines = header + (["lines: keep"] if keep_lines else []) + [""]
    for number, label, units in sections:
        lines.append(f"section: {number}")
        if label:
            lines.append(f"label: {label}")
        for k, u in enumerate(units, start=1) if not isinstance(units, dict) else units.items():
            first, *rest = u.split("\n")
            lines += [f"{k}. {first}"] + rest
        lines.append("")
    (Path(out) / f"{slug}.txt").write_text("\n".join(lines))
    print(f"{slug}: {len(sections)} sections, {sum(len(u) for _, _, u in sections)} units")


def build_dhammapada(src, out):
    text = body(src)
    parts = re.split(r"^Chapter ([IVXL]+)\.\s+(.*?)\.?\s*$", text[text.index("Chapter I. The Twin-Verses"):], flags=re.M)
    sections, last = [], 0
    for i in range(1, len(parts), 3):
        n, title, chunk = roman(parts[i]), parts[i + 1].strip(), parts[i + 2]
        verses = {}
        for p in paras(chunk):
            m = re.match(r"(\d+)(?:, (\d+))?\. (.*)", flat(p), re.S)   # "58, 59." is one passage
            assert m, p[:60]
            v = int(m.group(1))
            assert v == last + 1, (v, last)
            last = int(m.group(2) or v)
            verses[v] = typography(m.group(3))
        sections.append((n, title, verses))
    assert [s[0] for s in sections] == list(range(1, 27)) and last == 423, last
    write(out, "dhammapada", ["work: Dhammapada", "edition: Müller translation (1881)", "slug: dhammapada",
                              "collection: sacred-texts", "position: 1", "unit: verse"], sections)


def build_tao(src, out):
    text = body(src)
    text = text[text.index("Ch. 1. 1. The Tao"):]
    chapters, cur, expect, para_no = [], None, 1, 0
    for p in paras(text):
        raw = p.rstrip()
        f = flat(raw)
        m = re.match(r"(?:Ch\. )?(\d+)\. (\d+)\. (.*)", f, re.S)        # "13. 1. text": a chapter and its first paragraph
        num = re.match(r"(\d+)\.(?: (.*))?$", f, re.S)                     # "5. text" or a bare "5."
        if re.match(r"PART [I12]+\.", f):
            continue
        if m and int(m.group(1)) == expect:
            cur, para_no = [typography(m.group(3))], int(m.group(2))
            chapters.append(cur)
            expect += 1
        elif num and int(num.group(1)) == para_no + 1 and cur is not None and not (raw.startswith("  ")):
            para_no += 1                                                 # the next paragraph of this chapter
            if num.group(2):
                cur.append(typography(num.group(2)))
        elif num and int(num.group(1)) == expect:                        # "11. text" or a bare "12.": a chapter
            cur, para_no = [], 1 if num.group(2) else 0
            chapters.append(cur)
            expect += 1
            if num.group(2):
                cur.append(typography(num.group(2)))
        elif raw.lstrip("\n").startswith("  "):                          # a block of verse
            cur.append("\n".join(typography(l.strip()) for l in raw.split("\n") if l.strip()))
        else:
            cur.append(typography(f))
    assert len(chapters) == 81, len(chapters)
    sections = [(i, None, units) for i, units in enumerate(chapters, start=1)]
    write(out, "tao-te-ching", ["work: Tao Te Ching", "edition: Legge translation (1891)", "slug: tao-te-ching",
                                "collection: sacred-texts", "position: 2", "unit: paragraph"], sections, keep_lines=True)


def build_gita(src, out):
    text = body(src)
    contents = text[text.index("CONTENTS"):text.index("CHAPTER I\n")]
    titles = {roman(n): t.strip() for n, t in re.findall(r"^\s*([IVXL]+)\.\s+(.*)$", contents, re.M)}
    small = {"a", "an", "and", "by", "of", "the", "to", "in", "on", "for"}
    pretty = lambda t: " ".join(w.lower() if i and w.lower() in small else w for i, w in enumerate(t.title().split())).replace("’S", "’s")
    chunks = re.split(r"^\s*CHAPTER ([IVXL]+)\s*$", text[text.index("CHAPTER I\n"):], flags=re.M)
    sections = []
    for i in range(1, len(chunks), 2):
        n, chunk = roman(chunks[i]), chunks[i + 1]
        chunk = re.split(r"^\s*HERE ENDE?T?H?S?[, ]", chunk, flags=re.M)[0]
        units, lead = [], []
        for p in paras(chunk):
            lines = [typography(l.strip()) for l in p.split("\n") if l.strip()]
            if len(lines) == 1 and re.fullmatch(r"[A-Z][A-Za-z]+(?: [A-Za-z]+)?[:.]", lines[0]):   # who speaks next
                lead = lines
                continue
            units.append("\n".join(lead + lines))
            lead = []
        sections.append((n, f"{n}. {pretty(titles[n])}", units))
    assert [s[0] for s in sections] == list(range(1, 19))
    write(out, "bhagavad-gita", ["work: Bhagavad Gita (The Song Celestial)", "edition: Arnold translation (1885)", "slug: bhagavad-gita",
                                 "collection: sacred-texts", "position: 3", "unit: stanza"], sections, keep_lines=True)


def build_meditations(src, out):
    text = body(src)
    text = text[text.index("\nTHE FIRST BOOK\n"):text.index("\nNOTES\n")]
    names = "FIRST SECOND THIRD FOURTH FIFTH SIXTH SEVENTH EIGHTH NINTH TENTH ELEVENTH TWELFTH".split()
    parts = re.split(r"^THE (%s) BOOK\s*$" % "|".join(names), text, flags=re.M)
    sections = []
    for i in range(1, len(parts), 2):
        n = names.index(parts[i]) + 1
        # Sections are numbered in roman numerals, sometimes run on inside the previous
        # paragraph ("... unhappy. V. For not observing"), so split on numerals that
        # continue the sequence.
        chunk = parts[i + 1].split("\nAPPENDIX\n")[0]       # the last book is followed by Fronto's letters
        book = "\n".join(flat(p) for p in paras(chunk) if not re.fullmatch(r"_[^_]+_", flat(p)))
        marks, last = [], 0
        for m in re.finditer(r"(?:^|(?<=\s))([IVXL]+)\. (?=\S)|^([IVXL]+) (?=[A-Z])", book, re.M):   # a few numerals lack their period, at a paragraph start
            if roman(m.group(1) or m.group(2)) == last + 1:
                marks.append((last + 1, m.start(), m.end()))
                last += 1
        assert marks and marks[0][1] == 0, n
        units = {v: typography(flat(book[end:(marks[k + 1][1] if k + 1 < len(marks) else len(book))]))
                 for k, (v, _, end) in enumerate(marks)}
        sections.append((n, None, units))
    assert len(sections) == 12
    write(out, "meditations", ["work: Meditations", "edition: Casaubon translation (1634)", "slug: meditations",
                               "collection: prose", "position: 201", "unit: section"], sections)


def build_quran(src, out):
    text = body(src)
    heads = list(re.finditer(r"^SURA\d*[- ]*([IVXLC]+)\.?\d*[-. ]*(.*?)\s*\[([IVXLC]+)\.\]\s*$", text, re.M))
    assert len(heads) == 114, len(heads)
    small = {"a", "an", "and", "by", "of", "the", "to", "in", "on", "for", "or", "who", "he", "she"}
    sections, mismatches = [], []
    for k, m in enumerate(heads):
        n = roman(m.group(1))
        chunk = text[m.end():heads[k + 1].start() if k + 1 < len(heads) else len(text)]
        parts = re.split(r"^_{10,}\s*$", chunk, flags=re.M)
        chunk, notes = parts[0], parts[1] if len(parts) > 1 else ""
        name = re.sub(r"(?<=[A-Za-z])\d+", "", m.group(2).strip().rstrip("."))
        label = "Al-Fatihah" if n == 1 else " ".join(w if i and w in small else w[:1].upper() + w[1:] for i, w in enumerate(name.lower().split()))
        ps = [flat(p) for p in paras(chunk)]
        assert re.match(r"(MECCA|MEDINA)", ps[0], re.I), (n, ps[0])
        dm = re.search(r"([0-9]+|[IVXLC]+)\s*Vers\w*", ps[0])
        assert dm, (n, ps[0])
        declared = int(dm.group(1)) if dm.group(1).isdigit() else roman(dm.group(1))

        # Footnote marks run 1, 2, 3 ... through the sura (title first), glued to words or set off by
        # spaces, so strip each number that is the next mark expected; ordinary numbers ("300 years")
        # almost never coincide with it.
        expected = 2 if re.search(r"\d", m.group(0)) else 1
        def strip_marks(v):
            nonlocal expected
            def sub(mm):
                nonlocal expected
                glued, num = mm.group(1), int(mm.group(2))
                # a mark glued to a word may follow one the source dropped
                if (glued and expected <= num <= expected + 3) or num == expected:
                    expected = num + 1
                    if not glued and DEBUG:
                        print("   spaced mark removed:", num, "in", repr(mm.string[max(0, mm.start() - 30):mm.end() + 20]))
                    return glued
                return mm.group(0)
            return " ".join(re.sub(r"([A-Za-z.,;:!?\"')\]-]?)(\d+)(?!\d)", sub, v).split())
        verses = [strip_marks(v) for v in ps[1:]]
        count = 0   # footnotes are numbered consecutively; count the run from 1 (later lines may begin with other numbers)
        for x in re.findall(r"^(\d+) ", notes, re.M):
            count += int(x) == count + 1
        if expected - 1 != count:
            print(f"  note: sura {n}: stripped {expected - 1} footnote marks, the footnotes number {count}")
        verses = [re.sub(r" +([,.;:!?])", r"\1", v) for v in verses]
        if n != 1 and verses[0].lower().startswith("in the name of god"):
            verses = verses[1:]
        if len(verses) != declared:
            mismatches.append((n, label, declared, len(verses)))
        sections.append((n, f"{n}. {label}", [typography(v) for v in verses]))
    sections.sort()
    assert [s[0] for s in sections] == list(range(1, 115))
    for mm in mismatches:
        print("  verse count differs from the header:", mm)
    left = [(n, u[:60]) for n, _, us in sections for u in us if re.search(r"\d", u)]
    print("  units still containing digits:", len(left), left[:5])
    write(out, "quran", ["work: Quran", "edition: Rodwell translation (1861)", "slug: quran", "collection: sacred-texts",
                          "position: 4", "unit: verse"], sections)


if __name__ == "__main__":
    d, out = Path(sys.argv[1]), sys.argv[2] if len(sys.argv) > 2 else "db/texts"
    build_quran(d / "pg2800.txt", out)
    build_dhammapada(d / "pg2017.txt", out)
    build_tao(d / "pg216.txt", out)
    build_gita(d / "pg2388.txt", out)
    build_meditations(d / "pg2680.txt", out)
