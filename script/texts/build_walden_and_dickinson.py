#!/usr/bin/env python3
"""Builds db/texts/walden.txt and db/texts/dickinson.txt from Project Gutenberg.

Sources (public domain; download first, not checked in):
  walden     https://www.gutenberg.org/cache/epub/205/pg205.txt    (Walden, and On the Duty of Civil Disobedience)
  dickinson  https://www.gutenberg.org/cache/epub/12242/pg12242.txt (Poems, Three Series, Complete)

Unlike the Bible, these have a single source (Gutenberg's proofread edition).
Walden: one section per chapter, one unit per paragraph ("On the Duty of Civil
Disobedience" is left out). Dickinson: one section per poem (titled, or by its
first line), one unit per stanza, line breaks kept.

Usage: build_walden_and_dickinson.py WALDEN.txt DICKINSON.txt [OUT_DIR]
"""
import re, sys
from pathlib import Path

CHAPTERS = ["Economy", "Where I Lived, and What I Lived For", "Reading", "Sounds", "Solitude", "Visitors", "The Bean-Field",
            "The Village", "The Ponds", "Baker Farm", "Higher Laws", "Brute Neighbors", "House-Warming",
            "Former Inhabitants and Winter Visitors", "Winter Animals", "The Pond in Winter", "Spring", "Conclusion"]


def typography(s):
    s = s.replace("_", "")
    s = re.sub(r"\s*--\s*", " — ", s) if " -- " in s else s.replace("--", "—")
    s = re.sub(r'(^|[\s(\[—])"', r"\1“", s).replace('"', "”")
    return s.replace("'", "’")


SMALL = {"a", "an", "and", "as", "at", "but", "by", "et", "for", "in", "of", "on", "or", "the", "to", "with"}


def title_case(s):
    words = s.lower().split()
    return " ".join(w if (i and w in SMALL) else w[:1].upper() + w[1:] for i, w in enumerate(words)).replace("'S", "’s")


def gutenberg_body(path):
    text = Path(path).read_text(encoding="utf-8-sig").replace("\r", "")
    start = text.index("*** START OF")
    start = text.index("\n", start) + 1
    return text[start:text.index("*** END OF")]


def build_walden(path):
    body = gutenberg_body(path)
    body = body[body.index("\nWALDEN\n\nEconomy\n") + len("\nWALDEN\n"):body.index("\nTHE END")]
    lines = body.split("\n")
    heads, i = [], 0
    for title in CHAPTERS:
        while not (lines[i].strip() == title and lines[i - 1].strip() == "" and lines[i + 1].strip() == ""):
            i += 1
        heads.append(i)
        i += 1
    out = ["work: Walden", "slug: walden", "collection: prose", "position: 200", "unit: paragraph", ""]
    for n, (title, start) in enumerate(zip(CHAPTERS, heads), start=1):
        end = heads[n] if n < len(heads) else len(lines)
        paras = [" ".join(l.strip() for l in p.strip().split("\n")) for p in re.split(r"\n\s*\n", "\n".join(lines[start + 1:end])) if p.strip()]
        paras = [typography(p) for p in paras if not re.fullmatch(r"[\s*]+", p)]
        out += [f"section: {n}", f"label: {title}"] + [f"{k}. {p}" for k, p in enumerate(paras, start=1)] + [""]
    return "\n".join(out)


def build_dickinson(path):
    body = gutenberg_body(path)
    body = body[body.index("\nI. LIFE.\n"):]
    poems = []
    for block in re.split(r"\n{3,}", body):
        paras = [p for p in re.split(r"\n\s*\n", block.strip("\n")) if p.strip()]
        if not paras or not re.fullmatch(r"[IVXLCDM]+\.", paras[0].strip()):
            continue
        title, stanzas = None, []
        for p in paras[1:]:
            lines = [l.strip() for l in p.split("\n")]
            if p.lstrip().startswith("["):                      # editors' bracketed notes
                continue
            if not stanzas and title is None and not any(c.islower() for c in p) and any(c.isalpha() for c in p):
                title = " ".join(lines).rstrip(".")
                continue
            stanzas.append("\n".join(typography(l) for l in lines))
        if stanzas:
            label = title_case(title) if title else stanzas[0].split("\n")[0].rstrip(",;:—- ")
            poems.append((typography(label), stanzas))
    out = ["work: Emily Dickinson", "slug: dickinson", "collection: poetry", "position: 100", "unit: stanza", "lines: keep", ""]
    for n, (label, stanzas) in enumerate(poems, start=1):
        out += [f"section: {n}", f"label: {label}"]
        for k, st in enumerate(stanzas, start=1):
            first, *rest = st.split("\n")
            out += [f"{k}. {first}"] + rest
        out.append("")
    return "\n".join(out), len(poems)


if __name__ == "__main__":
    walden, dickinson = sys.argv[1:3]
    out = Path(sys.argv[3] if len(sys.argv) > 3 else "db/texts")
    (out / "walden.txt").write_text(build_walden(walden))
    d, n = build_dickinson(dickinson)
    (out / "dickinson.txt").write_text(d)
    print("Walden written;", n, "Dickinson poems written")
