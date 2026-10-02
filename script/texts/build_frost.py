#!/usr/bin/env python3
"""Builds db/texts/frost-*.txt from Project Gutenberg #78327.

Source (public domain; download first, not checked in):
  https://www.gutenberg.org/cache/epub/78327/pg78327.txt   (Collected Poems of Robert Frost, Henry Holt, 1930)

The 1930 collection entered the US public domain in 2026. It holds Frost's first
five books (A Boy's Will through West-Running Brook), and "The Pasture", which
opens the volume. Each book is a Work in the "robert-frost" collection, each
poem a section (labelled by title), each stanza a unit with line breaks kept.
Unbroken blank-verse passages are split into units of at most MAX_LINES lines,
at the end of a sentence where possible.

Usage: build_frost.py PG78327.txt [OUT_DIR]
"""
import re, sys
from pathlib import Path

MAX_LINES = 22
BOOKS = [("The Pasture", "the-pasture"), ("A Boy’s Will", "a-boys-will"), ("North of Boston", "north-of-boston"),
         ("Mountain Interval", "mountain-interval"), ("New Hampshire", "new-hampshire"), ("West-Running Brook", "west-running-brook")]
BOOK_HEADINGS = {"A BOY’S WILL": 1, "NORTH OF BOSTON": 2, "MOUNTAIN INTERVAL": 3, "NEW HAMPSHIRE": 4, "WEST-RUNNING BROOK": 5}
SMALL = {"a", "an", "and", "as", "at", "but", "by", "for", "in", "of", "on", "or", "the", "to", "with"}


def typography(s):
    return s.replace("_", "").replace("--", "—")


def title_case(s):
    words = s.lower().split()
    return " ".join(w if (i and w in SMALL) else w[:1].upper() + w[1:] for i, w in enumerate(words))


def split_long(lines):
    if len(lines) <= MAX_LINES:
        return [lines]
    # Break after the sentence end nearest the middle, so halves stay comparable in size.
    mid = len(lines) / 2
    ends = [i + 1 for i, l in enumerate(lines[:-1]) if re.search(r"[.?!:;—][’”]?$", l) and 4 <= i + 1 <= len(lines) - 4]
    cut = min(ends, key=lambda i: abs(i - mid)) if ends else len(lines) // 2
    return split_long(lines[:cut]) + split_long(lines[cut:])


def parse(path):
    text = Path(path).read_text(encoding="utf-8-sig").replace("\r", "")
    body = text[text.index("_The Pasture_"):text.index("*** END OF")]
    body = body[:body.index("Transcriber’s Note")]
    toc = text[text.index("CONTENTS"):text.index("_The Pasture_")]
    toc_titles = [re.sub(r"\s+(page\s+)?\d+$", "", l.strip()) for l in toc.split("\n") if re.search(r"\s\d+$", l)]
    norm = lambda t: re.sub(r"[^a-z]", "", t.lower())
    books = [[] for _ in BOOKS]   # each: list of (title, [paragraphs of lines])
    book = 0
    for block in re.split(r"\n{3,}", body.strip("\n")):
        lines = block.strip("\n").split("\n")
        first = lines[0].strip()
        if len(lines) == 1 and first in BOOK_HEADINGS:
            book = BOOK_HEADINGS[first]
        elif re.fullmatch(r"_[^_]+_", first):   # a poem's title, possibly followed by a subtitle or dedication
            title = first.strip("_")
            title = next((t for t in toc_titles if norm(t).endswith(norm(title)) and len(t) - len(title) <= 2), title)  # "A Prayer in Spring"
            books[book].append((title, [] if len(lines) == 1 else ["\n".join(lines[1:])]))
        else:
            books[book][-1][1].append(block.strip("\n"))
    return books


def stanzas(blocks):
    """Paragraphs of a poem; a heading paragraph (not indented) leads the stanza after it."""
    out, lead = [], []
    for block in blocks:
        for para in re.split(r"\n\s*\n", block):
            lines = [l for l in para.split("\n") if l.strip()]
            if not lines or all(re.fullmatch(r"[\s*]+", l) for l in lines):   # blank, or a "* * *" break
                continue
            if all(not l.startswith("    ") for l in lines):   # headings, epigraphs, dedications
                lead += [title_case(l) if l.upper() == l and len(l) > 3 else l for l in (x.strip() for x in lines)]
                continue
            out.append(lead + [l.strip() for l in lines])
            lead = []
    if lead:
        out.append(lead)
    return [u for st in out for u in split_long(st)]


def main(src, out="db/texts"):
    books = parse(src)
    total = 0
    for pos, ((title, slug), poems) in enumerate(zip(BOOKS, books)):
        lines = [f"work: {title}", "edition: Collected Poems (1930)", f"slug: frost-{slug}", "collection: robert-frost",
                 f"position: {pos}", "unit: stanza", "lines: keep", ""]
        for n, (ptitle, blocks) in enumerate(poems, start=1):
            units = stanzas(blocks)
            assert units, ptitle
            lines += [f"section: {n}", f"label: {typography(ptitle)}"]
            for k, u in enumerate(units, start=1):
                u = [typography(l) for l in u]
                lines += [f"{k}. {u[0]}"] + u[1:]
                total += 1
            lines.append("")
        (Path(out) / f"frost-{slug}.txt").write_text("\n".join(lines))
        print(f"{title}: {len(poems)} poems")
    print("stanza units:", total)


if __name__ == "__main__":
    main(*sys.argv[1:])
