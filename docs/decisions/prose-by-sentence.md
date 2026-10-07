# Prose by sentence

**Every work in the Prose collection is read a sentence at a time** (decided 2026-10-06; Walden, both series of Emerson's *Essays*, Montaigne, *Meditations*, the *Pensées*), after the prototype showed it was "so much more impactful for the long prose passages" than a paragraph at a time. Prototype: `prototype/reader/sentences.html`.

## Model

- Each sentence is a unit, so notes, keeps, history, search and Random work on sentences unchanged.
- A sentence also knows its group (a paragraph, Pascal's thought, Marcus's numbered section; `works.group_name`) and its place in it.
- Units are numbered in reading order through the chapter (`/read/walden/2/112`, "112 of 219").
- Cited by group and sentence: "Walden: Economy 12:3", "Meditations: Book 3 12:2" (its books are labelled "Book 3" for this).

## Display

- A group's first sentence opens with a ¶, hung in the left margin (inline on phones).
- The verse grid has a row per group.
- A ¶ button after the arrows (or `p`) shows the whole group with the current sentence marked and each sentence a link.

## Splitting

Splitting happens when the texts are built (`script/texts/sentences.py`), so the text files list sentences as `12.3 Text` and a bad split is fixed in a reviewable diff.

- Abbreviations, initials, list numbers and citations in brackets don't end a sentence.
- A lone "Hermit." or "Ibid." joins its neighbour.
- Thoreau's account tables stay whole.

## Reloading

Reloading keeps unit ids by matching a sentence's text in its group, then its place. A paragraph loaded before the split became its first sentence, carrying its notes, keeps and history. A row left unmatched is deleted unless something hangs off it.

Trade-off accepted: some sentences are still very long (one Montaigne catalogue runs 5,900 characters).
