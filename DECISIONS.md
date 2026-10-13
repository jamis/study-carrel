# Study Carrel: Decisions

Last updated: 2026-10-13

A web app for reading text (scripture, poetry, prose) against a **focus**: a question, metaphor, or thesis ("What does it mean to be holy?" while reading Isaiah 40). The reader sees one passage at a time with the focus pinned above it and writes a note on it.

This is the index. Each line is the rule in force; the linked file has the details, rationale and trade-offs. **Read the topic file before changing that area, and when a decision changes, update both the file and its line here.**

## Always true

- **Stack:** Rails + Hotwire + SQLite; Lexxy 1.0.0 on Action Text for notes. New features are prototyped as plain HTML in `prototype/` first.
- **Privacy:** nobody, admins included, can read another user's foci, notes, keeps or texts. User texts go through one visibility scope, and another user gets a 404 everywhere.
- **Notes survive:** loading texts updates in place and never deletes rows notes hang off. Notes whose passage goes away become detached notes, never silently lost.
- **Tone:** a quiet study desk, not a productivity tool. Serif, warm paper, dark mode, no gamification or streaks. Same features on phone and desktop.

## Topics

| Topic | In force | Details |
|---|---|---|
| Foci | One at a time; stands directly over the passage, unlabeled soft italic with a thought bubble and a rule across the column, scrolling with it. Home (`/` signed in) is the focuses page: an index card per focus, the current one wide with the way back into reading. | [foci-and-notes](docs/decisions/foci-and-notes.md) |
| Notes | One per unit per focus (unique index), always-open autosaving Lexxy editor docked right / bottom sheet on phones. Each focus has its own notes page (`/foci/:id/notes`), "Notes on this focus" in the menu; no page across focuses. It's laid out as in the reader, passages left under the focus and notes on a sheet at right; the passage cell links back into reading. | [foci-and-notes](docs/decisions/foci-and-notes.md) |
| Users | A few invited people; single-use invitation links, no email; 30-day sessions; sign out everywhere. | [users](docs/decisions/users.md) |
| Landing page | Public `/` for visitors, with its own layout; no contact address anywhere. | [users](docs/decisions/users.md) |
| Reader | Lectio only: one unit at a time, `‹ n of N ›` and a verse grid; left-aligned, ~34em measure, type steps down for long units. Design reference: `prototype/reader/e.html`. | [reader](docs/decisions/reader.md) |
| Clause by clause | Off by default; `;` turns it on until turned off or the reader is left. The current clause highlighted, the rest dimmed; the arrows step by clause. Split in the browser, for reading only: notes stay with the passage. Breaks chosen under the pips. | [reader](docs/decisions/reader.md) |
| Navigation | One icon rail down the left of every signed-in page: ⋯ at the top, labels shown on hover; Go up (the trail) in the reader, Continue reading elsewhere; the way up above each page's title. One ⋯ top right on phones. | [reader](docs/decisions/reader.md) |
| Library | Collection (nesting) > Work > Section > Unit; optional `author`/`author_short`; bundled corpus built by `script/texts/`. | [library](docs/decisions/library.md) |
| Prose by sentence | Prose is read a sentence at a time; split at build time (`sentences.py`), grouped by paragraph, ¶ view with `p`. | [prose-by-sentence](docs/decisions/prose-by-sentence.md) |
| User texts | Private plain-text uploads (prose or poetry/lyrics), reviewed before publishing, revisable with loose matching; lost notes become detached notes. | [user-texts](docs/decisions/user-texts.md) |
| History | Global per user, `visits` capped at 50; clock dropdown, `h`. | [history-and-keep](docs/decisions/history-and-keep.md) |
| Keep | Per-user bookmark with optional remark; ribbon by the reference, `b`, Kept page laid out like a notes page (passages left, remarks and actions on a sheet at right). | [history-and-keep](docs/decisions/history-and-keep.md) |
| Shelves | A user's own private groups of works and whole collections (a collection brings everything under it, nothing twice), to roll Random and search in. Filled from "Put on a shelf…" under a work's or collection's title, or the shelf editor over the library tree. | [shelves](docs/decisions/shelves.md) |
| Random | Scoped (innermost collection by default) and balanced across branches; a shelf is a scope too. | [random](docs/decisions/random.md) |
| Search | FTS5 over unit text, every word required, reading order, a sentence at a time for prose; titles and notes not searched. Scoped to a work, collection, Your Texts or a shelf. | [search](docs/decisions/search.md) |

**Exploratory, not decided:** [discovery](docs/decisions/discovery.md) holds brainstorm notes on helping new users find something to study (an exploring focus, curated lists, keeps in place of notes). Nothing in it is a rule. [synthesis](docs/decisions/synthesis.md) holds notes to experiment with on turning notes into writing (a reread with labels and a scratchpad, free notes on the whole focus, essays drawn from one or more focuses). Nothing in it is a rule either.

The original brief (v1 scope, open questions, early design implications) is in [origins](docs/decisions/origins.md).
