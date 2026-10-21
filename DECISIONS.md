# Study Carrel: Decisions

Last updated: 2026-10-20

A web app for reading text (scripture, poetry, prose) against a **focus**: a question, metaphor, or thesis ("What does it mean to be holy?" while reading Isaiah 40). The reader sees one passage at a time with the focus pinned above it and writes a note on it.

This is the index. Each line is the rule in force; the linked file has the details, rationale and trade-offs. **Read the topic file before changing that area, and when a decision changes, update both the file and its line here.**

## Always true

- **Stack:** Rails + Hotwire + SQLite; Lexxy 1.0.0 on Action Text for notes. New features are prototyped as plain HTML in `prototype/` first; prototypes aren't kept in the repo (those named in these docs are in git history up to d34f04e).
- **Privacy:** nobody, admins included, can read another user's foci, notes, keeps or texts. User texts go through one visibility scope, and another user gets a 404 everywhere.
- **Notes survive:** loading texts updates in place and never deletes rows notes hang off. Notes whose passage goes away become detached notes, never silently lost.
- **Tone:** a quiet study desk, not a productivity tool. Serif, warm paper, dark mode, no gamification or streaks. Same features on phone and desktop.

## Topics

| Topic | In force | Details |
|---|---|---|
| Foci | One at a time; stands directly over the passage, unlabeled soft italic with a thought bubble and a rule across the column, scrolling with it; with a description, a chevron drops the description alone, without one nothing to click. Edited from its card or its notes page, not the reader. Home (`/` signed in) is the focuses page: an index card per focus, the current one wide with the way back into reading. | [foci-and-notes](docs/decisions/foci-and-notes.md) |
| Notes | One per unit per focus (unique index), plus any number on the focus as a whole (no unit), written in the reread or from the reader sheet's focus tab. Always-open autosaving Lexxy editor docked right / bottom sheet on phones; the sheet's two tabs (`f`), the passage's note and the focus: a list of its notes newest first under a "+ New note" slip (`n`), each opening as an editor in place. Each focus has its own notes page (`/foci/:id/notes`), which is the reread; "Notes on this focus" in the menu, the count on each focus's card; no page across focuses. Notes on the whole focus are numbered on it ("focus 2"), a number never reused. Detached notes follow the run, read-only with Discard; Copy Markdown and Download `.md` in the page head. | [foci-and-notes](docs/decisions/foci-and-notes.md) |
| Users | A few invited people; single-use invitation links, no email; 30-day sessions; sign out everywhere. | [users](docs/decisions/users.md) |
| Landing page | Public `/` for visitors, with its own layout; no contact address anywhere. | [users](docs/decisions/users.md) |
| Reader | Lectio only: one unit at a time, `‹ n of N ›` and a verse grid; left-aligned, ~34em measure, type steps down for long units. Design reference: `prototype/reader/e.html`. | [reader](docs/decisions/reader.md) |
| Clause by clause | Off by default; `;` turns it on until turned off or the reader is left. The current clause highlighted, the rest dimmed; the arrows step by clause. Split in the browser, for reading only: notes stay with the passage. Breaks chosen under the pips. | [reader](docs/decisions/reader.md) |
| Navigation | One icon rail down the left of every signed-in page: ⋯ at the top, labels shown on hover; Go up (the trail) in the reader, Continue reading elsewhere; the way up above each page's title. One ⋯ top right on phones. | [reader](docs/decisions/reader.md) |
| Library | Collection (nesting) > Work > Section > Unit; optional `author`/`author_short`; bundled corpus built by `script/texts/`. | [library](docs/decisions/library.md) |
| Prose by sentence | Prose is read a sentence at a time; split at build time (`sentences.py`), grouped by paragraph, ¶ view with `p`. | [prose-by-sentence](docs/decisions/prose-by-sentence.md) |
| User texts | Private plain-text uploads (prose or poetry/lyrics), reviewed before publishing, revisable with loose matching; lost notes become detached notes. | [user-texts](docs/decisions/user-texts.md) |
| History | Global per user, `visits` capped at 50; clock dropdown, `h`. | [history-and-keep](docs/decisions/history-and-keep.md) |
| Keep | Per-user bookmark with optional remark; ribbon by the reference, `b`, Kept page laid out on a sheet (passages left, remarks and actions on a sheet at right). | [history-and-keep](docs/decisions/history-and-keep.md) |
| Shelves | A user's own private groups of works and whole collections (a collection brings everything under it, nothing twice), to roll Random and search in. Filled from "Put on a shelf…" under a work's or collection's title, or the shelf editor over the library tree. | [shelves](docs/decisions/shelves.md) |
| Random | Scoped (innermost collection by default) and balanced across branches; a shelf is a scope too. | [random](docs/decisions/random.md) |
| Reread | The notes page: a focus's notes one at a time (`/foci/:id/notes`, any focus; `/reread` redirects there): all in one column, the one you're on lit (`j`/`k`), each note's labels as footnotes (a numbered mark per label after its text, its other notes named under it, each shown when pointed at); the scratchpad put away behind a tab at the right edge (`s`). Notes on the whole focus written there (`n`, the "+ New note" slip; or "Make a note of this" from the scratchpad). Labels are the user's own, across focuses, put on notes with + label (`l`), a picker showing them all as a cloud (A–Z or recent; the footer says what Enter does); the labels in use as a cloud or tallies on a panel behind the Labels tab (`c`). A label's name is optional: **Gather** (`g`) holds the lit note on a small card over the column and lists the focus's other notes, each to put in one of its groups (labels, named or not) or a new group of the two; up to three notes held at once under tabs on the card, "Hold this" (Enter) holding another without the list moving; named, renamed (no duplicates, no merging yet) from the card. | [reread](docs/decisions/reread.md) |
| Search | FTS5 over unit text, every word required, reading order, a sentence at a time for prose; titles and notes not searched. Scoped to a work, collection, Your Texts or a shelf. | [search](docs/decisions/search.md) |

**Exploratory, not decided:** [discovery](docs/decisions/discovery.md) holds brainstorm notes on helping new users find something to study (an exploring focus, curated lists, keeps in place of notes). Nothing in it is a rule. [synthesis](docs/decisions/synthesis.md) holds notes on turning notes into writing: the reread and notes on the whole focus are decided (above); essays drawn from one or more focuses are still exploratory.

The original brief (v1 scope, open questions, early design implications) is in [origins](docs/decisions/origins.md).
