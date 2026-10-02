#!/usr/bin/env python3
"""Builds db/texts/<book>-bom.txt for the 15 books of the Book of Mormon.

Source (public domain; download it first, it is not checked in):
  https://www.gutenberg.org/cache/epub/17/pg17.txt   (Project Gutenberg #17)

This is the older, public-domain text, not the Church's current edition (whose
headings, footnotes and some wording are under copyright). Chapter headings and
summaries are dropped; each file keeps the chapter:verse numbering of the source.

Usage: build_book_of_mormon.py PG17.txt [OUT_DIR]
"""
import re, sys
from pathlib import Path

BOOKS = ["1 Nephi", "2 Nephi", "Jacob", "Enos", "Jarom", "Omni", "Words of Mormon", "Mosiah", "Alma", "Helaman", "3 Nephi", "4 Nephi", "Mormon", "Ether", "Moroni"]
CHAPTERS = [22, 33, 7, 1, 1, 1, 1, 29, 63, 16, 30, 1, 9, 15, 10]
VERSES = {"Enos": 27, "Jarom": 15, "Omni": 30, "Words of Mormon": 18, "4 Nephi": 49}  # single-chapter books, as a check
HEADINGS = {"THE BOOK OF ENOS": "Enos", "THE BOOK OF JAROM": "Jarom", "THE BOOK OF OMNI": "Omni",
            "THE WORDS OF MORMON": "Words of Mormon", "FOURTH NEPHI": "4 Nephi"}


def parse(path):
    text = Path(path).read_text(encoding="utf-8-sig").replace("\r", "")
    text = text[text.index("THE FIRST BOOK OF NEPHI HIS REIGN AND MINISTRY (1 Nephi)"):text.index("*** END OF THE PROJECT GUTENBERG")]

    # Collect each book's verse paragraphs, dropping headings and chapter summaries.
    flat = {b: [] for b in BOOKS}
    book, in_summary = None, True
    for para in re.split(r"\n\s*\n", text):
        line = " ".join(para.split())
        if line in HEADINGS:
            book, in_summary = HEADINGS[line], True
        elif (m := re.fullmatch(r"(.+) Chapter (\d+)", line)) and m.group(1) in flat:
            book, in_summary = m.group(1), True
        elif re.match(r"(4 Nephi )?\d+:\d+ ", line):
            in_summary = False
            flat[book].append(line)
        elif line.upper() == line:  # a book title; its introduction follows and is skipped
            in_summary = True
        elif not in_summary:
            raise ValueError(f"unexpected paragraph in {book}: {line[:70]}")

    # A verse can begin in the middle of a paragraph, so split on the chapter:verse
    # marks, accepting only those that continue the sequence (a cross-reference like
    # "Isaiah 48:1" in the text won't).
    books = {b: {} for b in BOOKS}
    for name, paras in flat.items():
        body = " ".join(paras)
        if name == "4 Nephi":  # this book's verses are numbered "4 Nephi 1:1"
            body = re.sub(r"(?<!\S)4 Nephi (?=\d+:\d+ )", "", body)
        marks, last = [], (0, 0)
        for m in re.finditer(r"(?:(?<=\s)|^)(\d+):(\d+) ", body):
            c, v = int(m.group(1)), int(m.group(2))
            if (c, v) == (last[0], last[1] + 1) or (c == last[0] + 1 and v == 1) or last == (0, 0) and (c, v) == (1, 1):
                marks.append((c, v, m.start(), m.end()))
                last = (c, v)
        for k, (c, v, _, end) in enumerate(marks):
            stop = marks[k + 1][2] if k + 1 < len(marks) else len(body)
            books[name].setdefault(c, {})[v] = body[end:stop].strip()
    return books


def main(src, out="db/texts"):
    books = parse(src)
    for name, n in zip(BOOKS, CHAPTERS):
        chapters = books[name]
        assert sorted(chapters) == list(range(1, n + 1)), (name, sorted(chapters))
        for c, vs in chapters.items():
            assert sorted(vs) == list(range(1, len(vs) + 1)), (name, c)
        if name in VERSES:
            assert len(chapters[1]) == VERSES[name], (name, len(chapters[1]))

    for pos, name in enumerate(BOOKS, start=1):
        slug = f"{name} bom".lower().replace(" ", "-")
        lines = [f"work: {name}", "edition: Public-domain text", f"slug: {slug}", "collection: book-of-mormon", f"position: {pos}", ""]
        for c in sorted(books[name]):
            lines.append(f"section: {c}")
            lines += [f"{v}. {books[name][c][v]}" for v in sorted(books[name][c])]
            lines.append("")
        (Path(out) / f"{slug}.txt").write_text("\n".join(lines))
    print("verses:", sum(len(vs) for b in books.values() for vs in b.values()))
    for name in BOOKS:
        print(f"  {name}: {sum(len(vs) for vs in books[name].values())}")


if __name__ == "__main__":
    main(*sys.argv[1:])
