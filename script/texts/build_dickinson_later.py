#!/usr/bin/env python3
"""Builds db/texts/dickinson-single-hound.txt and db/texts/dickinson-further-poems.txt from Wikisource.

Neither book is on Project Gutenberg. Both are public domain (1914/1915 and 1929) and have been
transcribed and proofread on English Wikisource, which stores the text one scanned page at a time in the
Page namespace. Fetch the pages once (not checked in):

  python3 build_dickinson_later.py --fetch DIR      # writes DIR/sh.json and DIR/fp.json (a few API requests)
  python3 build_dickinson_later.py DIR [OUT_DIR]    # builds the two text files

  sh  "Page:The Single Hound; poems of a lifetime.djvu/N"   (Bianchi, 1914; poems numbered I-CXLIV)
  fp  "Page:Further Poems Emily-1929.djvu/N"                (Bianchi and Hampson, 1929; six parts and an appendix)

The Single Hound poems are numbered, untitled; Further Poems are unnumbered and untitled, so each section is
labelled by its first line, as in the Gutenberg series. One unit per stanza, line breaks kept.
"""
import json, re, sys, time, urllib.parse, urllib.request
from pathlib import Path

API = "https://en.wikisource.org/w/api.php"
BOOKS = {"sh": "The Single Hound; poems of a lifetime.djvu", "fp": "Further Poems Emily-1929.djvu"}


def fetch(out):
    out = Path(out); out.mkdir(parents=True, exist_ok=True)
    for key, index in BOOKS.items():
        pages, cont = {}, {}
        while True:
            q = {"action": "query", "generator": "allpages", "gapnamespace": 104, "gapprefix": index + "/", "gaplimit": 50,
                 "prop": "revisions", "rvprop": "content", "rvslots": "main", "format": "json", **cont}
            req = urllib.request.Request(API + "?" + urllib.parse.urlencode(q), headers={"User-Agent": "study-carrel-build/1.0"})
            d = json.load(urllib.request.urlopen(req, timeout=60))
            for p in d.get("query", {}).get("pages", {}).values():
                pages[int(p["title"].rsplit("/", 1)[1])] = p["revisions"][0]["slots"]["main"]["*"]
            if "continue" not in d:
                break
            cont = d["continue"]; time.sleep(3)
        (out / f"{key}.json").write_text(json.dumps(pages))
        print(key, len(pages), "pages")


def typography(s):
    s = s.replace("''", "")
    s = re.sub(r"(^|[\s(\[—])\"", r"\1“", s).replace('"', "”")
    s = re.sub(r"(^|[\s(\[—])'(?=(?:[Tt]is|[Tt]was|[Tt]were|[Tt]will|[Tt]wixt|[Tt]ween|[Nn]eath|[Tt]il)\b)", r"\1’", s)   # 'Tis
    s = re.sub(r"(^|[\s(\[—])'(?=\w)", r"\1‘", s)                          # opening single quote
    return s.replace("'", "’")


def page_text(pages, n):
    return re.sub(r"<noinclude>.*?</noinclude>", "", pages.get(str(n), ""), flags=re.S).strip()


def clean_lines(raw):
    s = raw
    s = re.sub(r"<ref>.*?</ref>", "", s, flags=re.S)
    s = re.sub(r"width=\d+px\|", "", s)
    s = re.sub(r"\{\{right\|\{\{smaller block\|.*?\}\}\s*\}\}", "", s, flags=re.S)       # editors' notes: [Sent with flowers.]
    s = re.sub(r"\{\{right\|([^{}]*)\}\}", r"\1", s)
    s = re.sub(r"<section [^>]*/>", "", s)
    s = re.sub(r"\{\{(?:li|dropinitial|drop initial|di)\|(['’]?\w)(?:\|fl=(.))?\}\}(\s*)(?:\{\{uc\|(\s*)(\w+)\}\}|(['’]?[A-Za-z]+(?:['’][A-Za-z]+)*))",
               lambda m: (m.group(2) or "") + m.group(1) + (m.group(3) or m.group(4) or "")
               + lowercase_rest_word(m.group(5) or m.group(6), attached=not (m.group(3) or m.group(4))), s)
    s = re.sub(r"\{\{uc\|([^}]*)\}\}", r"\1", s)
    s = re.sub(r"\{\{fqm\|(.?)\}\}", r"\1", s).replace("{{fqm}}", '"')
    s = re.sub(r"</?br\s*/?>|<br />", "", s)
    s = re.sub(r"\{\{gap\}\}", "", s)
    s = re.sub(r"\{\{[Cc]\|''\([^}]*\)''\}\}", "", s)
    s = re.sub(r"\n\|(?:start|end)=\w+", "", s)
    s = re.sub(r"\{\{(?:ppoem|center block|centre block|italic block)(?:/[se])? ?\|?(?:\s*(?:start|end)=\w+\|?)*", "", s)
    s = s.replace("{{center block/s}}", "").replace("{{center block/e}}", "")
    s = re.sub(r"\{\{(?:nop|nopt|em|em-dash)[^{}]*\}\}", "", s)
    s = re.sub(r"\{\{centre\|\s*[IVXLC]+\.\s*\}\}", "", s)
    s = re.sub(r"\}\}", "", s)
    return s


def lowercase_rest_word(w, attached):
    """A drop initial leaves the rest of the first word in capitals: {{li|W}}HO -> Who, {{li|I}} FEAR -> I fear."""
    caps = w.isupper() and (attached or len(w) > 1)
    return w.lower() if caps or re.fullmatch(r"['’][A-Z]+", w) else w


def stanzas_of(raw):
    stanzas = []
    for block in re.split(r"\n\s*\n", clean_lines(raw).strip()):
        lines = [typography(l.strip()) for l in block.split("\n") if l.strip()]
        if lines:
            stanzas.append("\n".join(lines))
    return stanzas


def label_of(stanzas):
    return stanzas[0].split("\n")[0].rstrip(",;:—- ")


def single_hound(pages):
    text = ""
    for n in range(35, 184):
        t = page_text(pages, n)
        text += ("\n" if text.rstrip().endswith("<br />") else "\n\n\x00") + t     # a stanza can run over the page break
    parts = re.split(r"\{\{centre\|\s*([IVXLC]+)\.\s*\}\}", text)
    poems = []
    for numeral, body in zip(parts[1::2], parts[2::2]):
        body = re.sub(r"\{\{l\|[^}]*\}\}\}?|\{\{center\|\{\{l\|.*?\}\}\}\}", "", body.replace("\x00", "\n\n"))
        poems.append(stanzas_of(body))
    return poems


def further_poems(pages):
    poems = []
    for n in range(27, 227):
        t = page_text(pages, n)
        if not t or re.match(r"\{\{c\|\{\{lsp", t):
            continue
        t = re.sub(r"<section begin=\"s1\" />\{\{Pseudoheading/main\|APPENDIX\}\}.*?(?=\{\{ppoem)", "", t, flags=re.S)
        t = re.sub(r"\{\{[Cc](?:enter)?\|\(''[^}]*''\)\}\}", "", t)           # "(With a Daisy)" dedications
        stanzas = stanzas_of(t)
        if re.search(r"\{\{li\|", t) or not poems:
            poems.append(stanzas)
        elif "start=follow" in t and stanzas:                                  # a stanza running over the page break
            poems[-1][-1] += "\n" + stanzas[0]
            poems[-1] += stanzas[1:]
        else:
            poems[-1] += stanzas                                               # continuation page
    return poems


def work_file(title, edition, slug, position, poems):
    out = [f"work: {title}", f"edition: {edition}", "author: Emily Dickinson", "author_short: Dickinson", f"slug: {slug}",
           "collection: emily-dickinson", f"position: {position}", "unit: stanza", "lines: keep", ""]
    for n, stanzas in enumerate(poems, start=1):
        out += [f"section: {n}", f"label: {label_of(stanzas)}"]
        for k, st in enumerate(stanzas, start=1):
            first, *rest = st.split("\n")
            out += [f"{k}. {first}"] + rest
        out.append("")
    return "\n".join(out)


if __name__ == "__main__":
    if sys.argv[1] == "--fetch":
        fetch(sys.argv[2]); sys.exit()
    src = Path(sys.argv[1]); out = Path(sys.argv[2] if len(sys.argv) > 2 else "db/texts")
    sh = single_hound(json.loads((src / "sh.json").read_text()))
    fp = further_poems(json.loads((src / "fp.json").read_text()))
    (out / "dickinson-single-hound.txt").write_text(work_file("The Single Hound", "1914", "dickinson-single-hound", 4, sh))
    (out / "dickinson-further-poems.txt").write_text(work_file("Further Poems", "1929", "dickinson-further-poems", 5, fp))
    print(len(sh), "Single Hound poems;", len(fp), "Further Poems")
