#!/usr/bin/env python3
"""Builds db/texts for the second prose batch, from Project Gutenberg.

Sources (all public domain; download first, none are checked in):
  emerson1  https://www.gutenberg.org/cache/epub/2944/pg2944.txt    Emerson, Essays: First Series (1841)
  emerson2  https://www.gutenberg.org/cache/epub/2945/pg2945.txt    Emerson, Essays: Second Series (1844)
  montaigne https://www.gutenberg.org/cache/epub/3600/pg3600.txt    Montaigne, Essays (Charles Cotton's translation, ed. W. C. Hazlitt, 1877)
  pensees   https://www.gutenberg.org/cache/epub/18269/pg18269.txt   Pascal, Pensées (W. F. Trotter's translation; the file doesn't name the translator)

Works go in "prose". A section is a part of the work and a unit is one numbered
fragment (Pensées), essay paragraph (Emerson) or paragraph (Montaigne).

Usage: build_prose.py DIR_WITH_pgNNNN.txt_FILES [OUT_DIR]
"""
import re, sys
from pathlib import Path

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


SMALL = {"of", "the", "and", "on", "in", "to", "a", "an", "for", "at", "is", "are", "as", "by", "from", "or", "not", "with", "than", "upon"}


def title_case(s):
    words = s.lower().split()
    cap = lambda w: "-".join(part[:1].upper() + part[1:] for part in w.split("-"))
    return " ".join(w if i and w in SMALL else cap(w) for i, w in enumerate(words))


def write(out, slug, header, sections):
    """sections: list of (number, label or None, [unit text, ...] or {number: text})"""
    lines = header + [""]
    for number, label, units in sections:
        lines.append(f"section: {number}")
        if label:
            lines.append(f"label: {label}")
        for k, u in enumerate(units, start=1) if not isinstance(units, dict) else units.items():
            lines.append(f"{k}. {u}")
        lines.append("")
    (Path(out) / f"{slug}.txt").write_text("\n".join(lines))
    print(f"{slug}: {len(sections)} sections, {sum(len(u) for _, _, u in sections)} units")


def build_pensees(src, out):
    text = body(src)
    # Skip T. S. Eliot's introduction (still in copyright elsewhere) and stop before the editor's notes.
    text = text[text.index("\nSECTION I\n"):text.index("\nNOTES\n")]
    parts = re.split(r"^SECTION ([IVXL]+)\s*\n\s*\n([^\n]+)\s*$", text, flags=re.M)
    sections = []
    for i in range(1, len(parts), 3):
        n, label = roman(parts[i]), title_case(parts[i + 1].strip())
        units = {}
        pieces = re.split(r"^(\d+)\s*$", parts[i + 2], flags=re.M)[1:]
        for m in zip(pieces[::2], pieces[1::2]):
            num, frag = int(m[0]), " ".join(flat(p) for p in paras(m[1]))
            frag = re.sub(r"\[\d+\]", "", frag)       # pointers to the editor's notes
            frag = typography(frag).replace(" ,", ",").strip()
            units[num] = frag
        sections.append((n, label, units))
    nums = [k for _, _, u in sections for k in u]
    assert nums == list(range(1, 924)), (nums[:3], nums[-3:], len(nums))
    assert [s[0] for s in sections] == list(range(1, 15))
    write(out, "pensees", ["work: Pensées", "edition: Trotter translation", "author: Blaise Pascal", "author_short: Pascal",
                            "slug: pensees", "collection: prose", "position: 202", "unit: thought"], sections)


SECOND_SERIES = ["THE POET", "EXPERIENCE", "CHARACTER", "MANNERS", "GIFTS", "NATURE", "POLITICS",
                 "NOMINALIST AND REALIST", "NEW ENGLAND REFORMERS"]


def emerson_essays(text, first_series):
    """Yields (number, title, [paragraphs]) for each essay; the epigraph verse is left out."""
    if first_series:
        marks = [(roman(m.group(1)), m.group(2), m.start(), m.end())
                 for m in re.finditer(r"^([IVX]+)\.\n([A-Z][A-Z -]+)\n", text, flags=re.M)]
    else:
        marks = []
        for n, title in enumerate(SECOND_SERIES, start=1):
            # The source misspells one heading ("NONIMALIST"); the epigraph's own copy of the title is indented.
            pat = title.replace("NOMINALIST", "NO[NM]I[NM]ALIST")
            m = re.search(r"^(?:[IVX]+\. )?%s\.?[ ]*$" % pat, text, flags=re.M)
            marks.append((n, title, m.start(), m.end()))
    for k, (n, title, _, end) in enumerate(marks):
        chunk = text[end:(marks[k + 1][2] if k + 1 < len(marks) else len(text))]
        if first_series:
            # The title is repeated after the epigraphs, just before the essay itself.
            chunk = re.split(r"^\s*%s\s*$" % re.escape(title), chunk, maxsplit=1, flags=re.M)[1]
        else:
            chunk = chunk.split("\n*****")[0]        # then comes the next essay's epigraph
        ps = []
        for p in paras(chunk):
            if re.fullmatch(r"[\s*]+", p) or re.match(r"\s*\[\d+\]", p) or p.strip() == "Next Volume":
                continue
            ps.append(" / ".join(l.strip() for l in p.split("\n")) if p.startswith("   ") else p)    # quoted verse
        yield n, title, ps


def build_montaigne(src, out):
    text = body(src)
    start = text.index("\nBOOK THE FIRST\n\nCONTENTS OF VOLUME 2.")
    text = text[start:]
    # Every volume carries a list of "bookmarks" (quotable lines); the last runs on to the end of the file.
    text = re.sub(r"^[ ]+ETEXT EDITOR’S BOOKMARKS[^\n]*\n(?:[ ]+\S[^\n]*\n|[ \t]*\n)*", "", text, flags=re.M)
    # Each volume of the source repeats a title page and table of contents; drop them.
    text = re.sub(r"(?:ESSAYS OF MICHEL DE MONTAIGNE\s+Translated by Charles Cotton\s+Edited by William Carew Hazlitt\s+1877\s+)?"
                  r"CONTENTS OF VOLUME \d+\.\n\s*(?:[^\n]+\n)+\s*(?:ESSAYS OF MONTAIGNE\s*\n\s*)?", "", text)
    text = text.replace("\nCHAPTER  V.\n", "\n")     # a duplicated heading in the source
    text = re.sub(r"^BOOK THE (?:FIRST|SECOND|THIRD)\.?\s*$", "", text, flags=re.M)
    assert "CONTENTS OF VOLUME" not in text, text[text.index("CONTENTS OF VOLUME") - 200:][:600]
    # Notes by the Gutenberg transcribers (signed D.W.), including the "--[note]--" form that interrupts a sentence.
    text = re.sub(r"--\[[^\[\]]*?D\.W\.[\]\)}]--", " ", text)
    text = re.sub(r"[ ]*[\[(][^\[\]()]*?D\.W\.[\]\)}]", "", text)
    marks = list(re.finditer(r"^(?:CHAPTER\s+([IVXL]+)\.?[ ]*\n\s*\n((?:[^\n]+\n)+)|Chapter ([IVXL]+)\.\s+([^\n]+)\n)", text, flags=re.M))
    sections, book, last_roman = [], 0, 0
    for k, m in enumerate(marks):
        num = roman(m.group(1) or m.group(3))
        title = flat(m.group(2) or m.group(4)).rstrip(".")
        book += num == 1
        chunk = text[m.end():(marks[k + 1].start() if k + 1 < len(marks) else len(text))]
        units = []
        for p in paras(chunk):
            q = flat(p)
            if units and (p.startswith("   ") or q[:1].islower()):      # a quoted passage (Latin, then its translation) or a sentence it interrupted: part of the paragraph before
                units[-1] += " " + q
            else:
                units.append(q)
        units = [typography(u) for u in units]
        units = [u for u in units if not u.startswith("APOLOGY: [In fact, the first edition")]
        label = f"{'I' * book if book < 4 else book}.{num} {title_case(title)}"
        sections.append((len(sections) + 1, label.replace("III.", "III.").strip(), units))
    assert len(sections) == 107, len(sections)
    write(out, "montaigne-essays", ["work: Essays", "edition: Cotton translation (1877)", "author: Michel de Montaigne",
                                    "author_short: Montaigne", "slug: montaigne-essays", "collection: prose", "position: 205",
                                    "unit: paragraph"], sections)


def unshout(s):
    """The first words of an essay are set in small caps in the source: WHERE do we find ... -> Where do we find ..."""
    words = s.split(" ")
    start = 1 if words[0] == "I" else 0         # "I HAVE read ..." -> "I have read ..."
    k = start
    while k < len(words) and re.fullmatch(r"[A-Z]{2,}", words[k]):
        k += 1
    if k == start or k == len(words) or not words[k][:1].islower():
        return s
    words[start:k] = [w.lower() for w in words[start:k]]
    words[0] = words[0].capitalize()
    return " ".join(words)


def build_emerson(src, out, slug, name, year, first_series, position):
    text = body(src)
    text = text[text.index("\nI.\nHISTORY\n") if first_series else text.index("\nI. THE POET.\n"):]
    text = text.split("\nEnd of Project Gutenberg")[0]
    sections = []
    for n, title, ps in emerson_essays(text, first_series):
        title = title_case(title)
        units = [unshout(typography(flat(p))) for p in ps]
        sections.append((n, title, units))
    write(out, slug, [f"work: {name}", f"edition: {year}", "author: Ralph Waldo Emerson", "author_short: Emerson",
                      f"slug: {slug}", "collection: prose", f"position: {position}", "unit: paragraph"], sections)


if __name__ == "__main__":
    d, out = Path(sys.argv[1]), sys.argv[2] if len(sys.argv) > 2 else "db/texts"
    build_montaigne(d / "pg3600.txt", out)
    build_pensees(d / "pg18269.txt", out)
    build_emerson(d / "pg2944.txt", out, "emerson-essays-first-series", "Essays, First Series", "1841", True, 203)
    build_emerson(d / "pg2945.txt", out, "emerson-essays-second-series", "Essays, Second Series", "1844", False, 204)
