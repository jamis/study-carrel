"""Splits prose into sentences, for works read a sentence at a time ("unit: sentence").

A sentence ends at . ? or ! (with any closing quotes or brackets) followed by a space and a capital letter or an
opening quote, unless:
  - the period ends a known abbreviation ("Mr.", "viz.") or an initial ("J. Smith"),
  - the text so far is only a list number ("1. In what prayers..."), or
  - it falls inside parentheses or square brackets opened within the sentence, which hold citations like
    "[Cicero, Tusc. Quaes., i. 34.]" (a bracket that opens a sentence may run over several, as in Pascal).

A paragraph with dot leaders ("Laths,........ 1.25", Thoreau's accounts) is a table, kept whole as one unit.

A lone word ending in a period (a speaker in quoted dialogue, "Hermit.", a heading in Pascal, "Contraries.", or a
citation, "Senec.") or a bare "..." joins the sentence after it, or the one before at the end of a paragraph.

The build scripts write the result as "P.S text" lines, paragraph (or thought, or section) P, sentence S; see
TextLoader.
"""
import re

ABBREVIATIONS = set("""
    Mr Mrs Messrs Dr St Mt Esq Rev Capt Col Gen Lieut Hon Prof Sen Jr Sr Mme Mlle Co No
    viz vs etc cf ch chap vol pp ibid Ib Id Lib Ep
""".split())

END = re.compile(r"""([.?!][”’")\]]*)\s+(?=[“‘"(\[]?[A-Z])""")
FRAGMENT = re.compile(r"""[“‘(\[]?[A-Za-zÀ-ÿ’]+\.[”’)\]]*|[^A-Za-zÀ-ÿ]+""")


def split(text):
    if re.search(r"\.{6,}\s*\$?\s*\d", text):
        return [text]
    out, start = [], 0
    for m in END.finditer(text):
        before = text[start:m.start()]
        word = re.search(r"([A-Za-z]+)$", before)
        if m.group(1) == ".":
            if word and (word.group(1) in ABBREVIATIONS or (len(word.group(1)) == 1 and word.group(1).isupper())):
                continue
            if re.fullmatch(r"\s*\d+", before):
                continue
        if bracket_depth(text[start:m.end(1)].lstrip("[(")) > 0:
            continue
        out.append(text[start:m.end(1)].strip())
        start = m.end()
    out.append(text[start:].strip())
    return join_fragments([s for s in out if s])


def join_fragments(sentences):
    out, carry = [], []
    for s in sentences:
        if FRAGMENT.fullmatch(s):
            carry.append(s)
        else:
            out.append(" ".join(carry + [s]))
            carry = []
    if carry:
        out[-1:] = [" ".join(out[-1:] + carry)]
    return out


def bracket_depth(text):
    return max(0, text.count("(") - text.count(")")) + max(0, text.count("[") - text.count("]"))


def lines(groups):
    """groups: [(number, text), ...] for each paragraph, thought or section. Returns its "P.S text" lines."""
    return [f"{p}.{s} {sentence}" for p, text in groups for s, sentence in enumerate(split(text), start=1)]
