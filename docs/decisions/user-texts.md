# User texts

**Users can add their own texts** (decided 2026-10-06; built the same day: adding, the review, reading, search, Random, the Your Texts page (`/texts`), revising (`TextRevision`) and deleting, with detached notes (`DetachedNote`)), first for prose such as journals and transcripts of talks. Prototype: `prototype/upload.html` (`?revise` for a revision, `?poetry` for poetry).

## Privacy

**Private to the uploader, always.**

- `works.user_id` (null = bundled), and every lookup goes through one visibility scope (reader, search, Random, Kept, history, export), with tests that another user gets a 404 everywhere.
- Making a private text public is a manual step for the admin (clear `user_id`, file it in a collection); users can't do it.
- Uploads get a random slug suffix (`journal-k3f9`) so a URL never reveals another user's titles.
- Encrypting user texts at rest is wanted later.

## Format

**Plain text only** (`.txt`/`.md` or pasted), one work per upload, title and author from the form. Other formats are converted outside the app (the admin helps).

- If a blank line falls between two lines of text, blank lines separate paragraphs and single line breaks are joined; otherwise each line is a paragraph. Blank lines around headings don't count, so a journal with one paragraph per line can still space out its headings.
- A line starting `# ` starts a section and labels it (none means one section).
- Everything else is literal, never rendered as Markdown.

## Sentence splitting

Paragraphs are split into sentences as in [prose-by-sentence.md](prose-by-sentence.md) (`SentenceSplitter`, a Ruby port of `sentences.py`, tested to split all the bundled prose identically).

**A backslash beside `.` `?` `!` overrides the split** (decided 2026-10-06): `Sgt\. Pepper` is not an ending, `with M.\ We` is, and `\\` is a literal backslash; anywhere else a backslash shows as typed. Markers stay in the stored source, so they survive revisions, but never reach a unit's text. The review lists every marker, says when one changes nothing, and flags a backslash left as typed.

## Saving and review

The upload is saved directly by `UserText#publish!` (not through `TextLoader`, whose matching by section and paragraph number doesn't suit revisions). A review screen shows the result before it is published:

- counts, and which paragraph rule applied;
- a "Worth a look" list: initials that didn't split, short words that did, lines that look like headings, Markdown left as typed, markers;
- every sentence shaded in turn;
- a reader-style preview.

## Where they appear

- A per-user "Your Texts" at the top of the library (and in the ⋯ menu).
- The Your Texts page has its own search box and Random scope (`OwnTexts`; `?texts=yours`, `/texts/random`).
- In the reader, Random defaults to Your Texts. User texts are included in search and are one more branch for Random.
- Revise is on Your Texts and on the work page.

## Revising

Revising replaces the whole source, and the review shows what happens to each note and keep before saving.

Matching must be looser than the bundled loader's, which goes by section and paragraph number (adding a heading or a paragraph renumbers everything after it):

- Sections by name, then place.
- Sentences by exact text in their section, then anywhere in the work.
- Each old paragraph is paired with the new one most of its sentences went to, and a leftover sentence matches the most alike one there (a rewording, or one half of a sentence split in two), or in its section when its paragraph has no pair (a one-line paragraph reworded), if they share at least 30% of their words.
- **A sentence merely in the same place is not a match** (revised 2026-10-07; the prototype fell back to it): a note is set aside with its passage rather than hung on words it wasn't written about.

## Detached notes

A note whose unit is gone (after a revision, or when a work is deleted) moves to `detached_notes`, keeping its focus (if any), body, citation, work title, the passage text and its original times, plus when and why it was detached.

- They show after the focus's notes under "From passages that changed or were removed", are exported with them, and can be discarded.
- A keep with a remark always becomes a detached note of its own, never merged into a note, since keeps belong to no focus: its focus is blank, and it is shown as a special case at the foot of the Kept page under the same heading (no focus, so not in any focus's export).
- A keep without a remark is dropped, as are visits.
- Deleting a text sets aside everything on it first (the confirmation says how much).
- This could later replace the bundled loader's keeping of leftover rows. (Deleting a focus doesn't use it: with the focus gone its detached notes would have nowhere to be shown; see [foci-and-notes.md](foci-and-notes.md#deleting).)

## Poetry and song lyrics

Decided and built 2026-10-06; prototype `prototype/upload.html?poetry`.

- The form asks **Prose** or **Poetry or lyrics**, never guessed, though text with mostly short, open lines added as prose gets a "This looks like verse" hint on the form and in the review.
- Poetry is read a stanza at a time like Frost (`unit_name` "stanza", no paragraph or sentence).
- Blank lines separate stanzas, line breaks are kept, and a section with no blank lines is one stanza. `# ` headings make a poem or song a section. Lines are trimmed, so indents are lost.
- Cited "Songs: Low Water, stanza 2", or "Low Water, stanza 2" with no headings.
- Part labels like `[Chorus]` and "Repeat chorus (x2)" stay literal. The review flags them (labels as one check that doesn't shade every stanza), along with a stanza that comes more than once (each is read and noted on its own), a line that looks like a title without `# `, lost indents, and very long lines or stanzas.
- A revision keeps the text's form.
- Stanzas are matched like sentences, but with no paragraphs to pair: exact text in the section, nearest place first (a chorus sung twice keeps each note on its own chorus), then the most alike leftover stanza in the section, best pairs first, sharing at least 30% of its words.
