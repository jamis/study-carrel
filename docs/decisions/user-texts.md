# User texts

**Users can add their own texts** (decided 2026-10-06; built the same day: adding, the review, reading, search, Random, the Your Texts page (`/texts`), revising (`TextRevision`) and deleting, with detached notes (`DetachedNote`)), first for prose such as journals and transcripts of talks. Prototype: `prototype/upload.html` (`?revise` for a revision, `?poetry` for poetry).

## Privacy

**Private to the uploader, always.**

- `works.user_id` (null = bundled), and every lookup goes through one visibility scope (reader, search, Random, Kept, history, export), with tests that another user gets a 404 everywhere.
- Making a private text public is a manual step for the admin (clear `user_id`, file it in a collection); users can't do it. A user's own collection goes public the same way, its `user_id` cleared with its texts'.
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

- A per-user "Your Texts" at the top of the library (and in the phone menu).
- The Your Texts page has its own search box and Random scope (`OwnTexts`; `?texts=yours`, `/texts/random`).
- In the reader, Random defaults to Your Texts. User texts are included in search and are one more branch for Random.
- Revise is on Your Texts and on the work page.

## Collections

**Users can gather their texts into collections of their own** (decided and built 2026-10-27), toward one day uploading a whole collection of works at once (the Pearl of Great Price). Prototype: `prototype/private-collections/index.html`.

- **Private like their texts.** `collections.user_id`, and every lookup goes through `Collection.visible_to(user)`: the collection page, search and Random scoped to it, shelves and the search picker; another user gets a 404. Slugs get a random suffix (`pearl-of-great-price-k3f9`).
- **Kept out of the bundled tree.** A user's collection nests only under their own, and holds only their own texts; a bundled collection holds only bundled works (validated both ways). So a bundled page's counts and lists never depend on who is looking.
- **Made empty**, from "New collection" on Your Texts: a name, a line about it, and **One work in parts** (`single_work`, as for the Bible; decided 2026-10-27), described on the form in one sentence: "Like the Bible: its texts are books of a single work, and Random picks evenly from all their passages rather than giving each text an equal chance." Such a collection is listed like a work (upright, quiet) and counts its texts as books; others are listed like Sacred Texts and count texts. The box was put under the Bible alone, the archetype, and doesn't say it can't be changed: nothing hangs off it, and it can't only because nothing edits a collection yet (an edit page, for the name, the line and this, is for later; until then the console). Nothing in the app nests one collection in another.
- **Filled by adding texts.** Add a text has an optional Collection (None by default); "Add a text here" on the collection's page picks it. A revision leaves a text where it is; moving one in or out isn't built yet.
- **Where they show:** Your Texts lists the collections first (each with its count and Delete), then the texts "In no collection". The library's Your Texts row counts them. The collection page is like a bundled one's, under Library › Your Texts, with "Add a text here", "Put on a shelf…" and Delete. In the shelf editor they're under Your Texts.
- **Random:** Your Texts branches into the user's collections and their texts in none, each a branch; a text in a collection chains out through it, then Your Texts, then the library.
- **Deleting one deletes its texts** (and any collection nested in it), after a page of its own listing them and how many notes and kept passages will be set aside, which they are as when deleting a text. Letting the user keep the texts instead may come later.

## Revising

Revising replaces the whole source, and the review shows what happens to each note and keep before saving.

Matching must be looser than the bundled loader's, which goes by section and paragraph number (adding a heading or a paragraph renumbers everything after it):

- Sections by name, then place.
- Sentences by exact text in their section, then anywhere in the work.
- Each old paragraph is paired with the new one most of its sentences went to, and a leftover sentence matches the most alike one there (a rewording, or one half of a sentence split in two), or in its section when its paragraph has no pair (a one-line paragraph reworded), if they share at least 30% of their words.
- **A sentence merely in the same place is not a match** (revised 2026-10-07; the prototype fell back to it): a note is set aside with its passage rather than hung on words it wasn't written about.
- **A revision too different to match is refused** (decided 2026-10-26). Finding the most alike leftover compares each one with every leftover sharing a word with it, which grows with the square of the text: a long text with most of its sentences changed (or a different text pasted over it, perhaps deliberately, to tie up the server) took minutes. Past a budget (`TextRevision::COMPARISONS`, about two seconds' work), the review says it's too different to save as a revision and offers to add it as a new text instead; saving refuses it too. Chosen over a share of unchanged sentences, which would refuse a short text reworded throughout, cheap to match; and over searching only nearby paragraphs, which would lose a reworded one-liner moved far. Reviews and saves are also limited to 10 a minute per user.

## Detached notes

A note whose unit is gone (after a revision, or when a work is deleted) moves to `detached_notes`, keeping its focus (if any), body, citation, work title, the passage text and its original times, plus when and why it was detached.

- They show after the focus's notes under "From passages that changed or were removed", are exported with them, and can be discarded.
- A keep with a remark always becomes a detached note of its own, never merged into a note, since keeps belong to no focus: its focus is blank, and it is shown on the Kept page among the keeps, by when it was kept, with why it was set aside (no focus, so not in any focus's export). Until 2026-10-25 these stood at the foot of the Kept page under the same heading as a focus's.
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
