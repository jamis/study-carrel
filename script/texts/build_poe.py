#!/usr/bin/env python3
"""Builds db/texts/poe-*.txt from Project Gutenberg #76996.

Source (public domain; download first, not checked in):
  https://www.gutenberg.org/cache/epub/76996/pg76996.txt   (The Poems of Edgar Allan Poe, Bell, 1900)

Four Works in the "edgar-allan-poe" collection: "Poems" (The Raven through The
Valley of Unrest), "Poems Written in Youth", "Tamerlane" and "Al Aaraaf" (Part I
and Part II). Each poem is a section labelled by title (a repeated title gets
its first line too), each stanza a unit with line breaks kept; long unbroken
passages are split at sentence ends. Left out: the introduction, the notes, the
Politian scenes, the letter and the two essays.

Usage: build_poe.py PG76996.txt [OUT_DIR]
"""
import re, sys
from pathlib import Path

MAX_LINES = 22
SMALL = {"a", "an", "and", "as", "at", "but", "by", "for", "in", "of", "on", "or", "the", "to", "with"}


TITLES = {"TO F—S S. O—D": "To F——s S. O——d", "TO ——": "To ——", "TO ——.": "To ——", "TO F——": "To F——",
          "TO M. L. S——": "To M. L. S——", "SONNET—TO SCIENCE": "Sonnet: To Science", "THE LAKE—": "The Lake:"}


def title_case(s):
    s = s.strip()
    if s in TITLES:
        return TITLES[s]
    words = s.lower().split()
    return " ".join(w if (i and w in SMALL) else w[:1].upper() + w[1:] for i, w in enumerate(words))


def split_long(lines):
    if len(lines) <= MAX_LINES:
        return [lines]
    mid = len(lines) / 2
    ends = [i + 1 for i, l in enumerate(lines[:-1]) if re.search(r"[.?!:;—][’”]?$", l) and 4 <= i + 1 <= len(lines) - 4]
    cut = min(ends, key=lambda i: abs(i - mid)) if ends else len(lines) // 2
    return split_long(lines[:cut]) + split_long(lines[cut:])


def segments(path):
    text = Path(path).read_text(encoding="utf-8-sig").replace("\r", "")
    text = text[text.index("\nTHE RAVEN\n\n[Illustration]"):text.index("NOTES TO AL AARAAF\n\n")]
    text = re.sub(r"\[Illustration[^\]]*\]", "", text)
    segs, cur = [], None
    for line in text.split("\n"):
        if line.strip() and not line.startswith(" "):
            cur = [line.strip(), []]
            segs.append(cur)
        elif cur:
            cur[1].append(line)
    return segs


def stanzas(lines):
    out = []
    for para in re.split(r"\n\s*\n", "\n".join(lines)):
        ls = [l.strip().replace("_", "") for l in para.split("\n") if l.strip()]
        if ls:
            out += split_long(ls)
    return out


def main(src, out="db/texts"):
    poems = []   # (group, title, stanzas)
    group, lake = "Poems", None
    for head, body in segments(src):
        if head == "POEMS WRITTEN IN YOUTH":
            group = "Poems Written in Youth"
            continue
        if head == "TAMERLANE":
            group = "Tamerlane"
        elif head == "AL AARAAF":
            group = "Al Aaraaf"
            continue
        elif head in ("AL AARAAF. PART I.", "PART II."):
            poems.append((group, "Part I" if head.endswith("I.") and "PART II" not in head else "Part II", stanzas(body)))
            continue
        st = stanzas(body)
        title = title_case(head)
        if not st:      # "The Lake—" has no body; its "To ——" line follows as part of the same title
            lake = title
            continue
        if lake:
            title, lake = f"{lake} {title}", None
        poems.append((group, title, st))

    seen = {}
    for g, t, st in poems:
        seen[(g, t)] = seen.get((g, t), 0) + 1
    works = {}
    for g, t, st in poems:
        label = t
        if seen[(g, t)] > 1:
            first = st[0][0].rstrip(",;:—- ")
            label = f"{t} (“{first}”)"
        works.setdefault(g, []).append((label, st))

    order = ["Poems", "Poems Written in Youth", "Tamerlane", "Al Aaraaf"]
    for pos, g in enumerate(order, start=1):
        slug = "poe-" + g.lower().replace(" ", "-")
        lines = [f"work: {g}", "edition: 1900 edition", "author: Edgar Allan Poe", "author_short: Poe", f"slug: {slug}", "collection: edgar-allan-poe", f"position: {pos}",
                 "unit: stanza", "lines: keep", ""]
        for n, (label, st) in enumerate(works[g], start=1):
            lines += [f"section: {n}", f"label: {label}"]
            for k, u in enumerate(st, start=1):
                lines += [f"{k}. {u[0]}"] + u[1:]
            lines.append("")
        (Path(out) / f"{slug}.txt").write_text("\n".join(lines))
        print(f"{g}: {len(works[g])} sections, {sum(len(st) for _, st in works[g])} stanzas")


if __name__ == "__main__":
    main(*sys.argv[1:])
