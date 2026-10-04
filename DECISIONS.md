# Study Carrel: Decisions

Last updated: 2026-10-04

## Concept

A web app for associating text (scripture, poetry, prose) with a **focus**: a question, metaphor, or thesis. The reader sees the passage with the focus pinned prominently, highlights the verse they're pondering, and annotates it as thoughts come.

Example: read Isaiah 40 while pondering "What does it mean to be holy?"

## Decisions made

| Topic | Decision |
|---|---|
| Foci | One focus at a time. No parallel foci in v1. |
| Notes | **One note per verse per focus** (decided 2026-10-03), in an always-open Lexxy editor in the side panel / bottom sheet that **autosaves** as you type (and on leaving the verse); clearing it deletes the note. Enforced by a unique index on `(focus_id, unit_id)`. Trade-off accepted: no per-note timeline of when each thought arrived (only the last-updated time), and last save wins across tabs. Toolbar shrunk (icons about 35% smaller). |
| Users | **A few invited people** (decided 2026-10-02). Foci and notes belong to a user, and nobody (admins included) can read another user's notes; the library is shared. Sign-up is by **invitation only**: an admin creates a single-use link (stored as a digest, shown once, expires in 7 days, open to whoever holds it) and sends it themselves; no email delivery. `users.admin` is set with `bin/rails study_carrel:make_admin EMAIL=...`. No password reset yet. Possible later: encrypting notes. Sharing notes is still manual (copy/paste). |
| Texts | The app ships with a **bundled corpus**. No import or external API in v1. |
| Mobile | Same functionality as desktop. One responsive design, no cut-down phone version. |
| Platform | Web application, usable from laptop and phone. |
| Stack / editor | No preference from the user; Claude decides. **Rails + Hotwire + SQLite** (user OK'd Rails). **Lexxy 1.0.0** for notes (step 9 spike passed), on Action Text. |
| Reading model | **Lectio mode only** for v1 (one verse at a time, neighbors faded, verse strip for jumping). Full-chapter reading view deferred as a possible future option. |
| Focus presentation | The focus is the hero of the screen: compact, accent-colored band under the nav, sticky so it stays visible while scrolling, and left-aligned (decided 2026-10-03) so a short focus doesn't get lost in the middle; it lines up with the nav and body text. Prototype feedback: a thin bar felt lost; a large hero banner was too big. Description opens as a dropdown. |
| Text alignment | Left-aligned (ragged right), not centered, and flush with the focus band and nav. The ~34em measure applies below 900px; on wider screens the text fills its column beside the notes panel (decided 2026-10-03). Type size steps down for longer units (prose paragraphs); neighbors clamp to 2 lines. Demo of long prose: open `prototype/index.html?text=prose`. |
| Design | **Committed** (2026-10-02): `prototype/index.html` is the reference for look and feel: lectio-only, compact sticky focus band, left-aligned text with length-adaptive sizing, verse strip, side panel / mobile bottom sheet for notes. |
| Bundled texts | **KJV Old Testament and New Testament** (the NT built the same way, 260 chapters), **Book of Mormon** (Gutenberg #17, older public-domain text, 6,604 verses; labelled "Public-domain text", not the Church's current copyrighted edition), **World Scripture** (Dhammapada, Müller; Tao Te Ching, Legge; Bhagavad Gita, Arnold's *Song Celestial*; Quran, Rodwell in the traditional sura order, whose verse numbers can drift by one from the standard in about two dozen suras), **Marcus Aurelius: Meditations** (Casaubon's 1634 translation), **Robert Frost** (the 1930 Collected Poems, public domain from 2026) and **Edgar Allan Poe** (1900 Bell edition), all from Gutenberg, **KJV Old Testament** (Gutenberg base, cross-checked against two other sources; 115 verses taken from the other sources where the base differed), **Emily Dickinson** (five works, stanza per unit: *Poems* First, Second and Third Series, 442 poems from Gutenberg; *The Single Hound*, 1914, 142 poems, and *Further Poems*, 1929, 181 poems, both from proofread Wikisource transcriptions because Gutenberg lacks them; rebuilt with `script/texts/build_dickinson_later.py`), **Thoreau: Walden** (Gutenberg, paragraph per unit). **Prose batch 2** (2026-10-04, `script/texts/build_prose.py`, all Gutenberg, single-source): **Pascal, *Pensées*** (#18269, 923 numbered thoughts in 14 sections, a thought per unit; the file doesn't name the translator, but it is W. F. Trotter's, so the edition reads "Trotter translation" with no year; T. S. Eliot's introduction and the editor's notes are left out), **Emerson, *Essays*, First Series** (#2944, 12 essays) and **Second Series** (#2945, 9 essays), a paragraph per unit with the epigraph verse left out, and **Montaigne, *Essays*** (#3600, Cotton's translation as edited by Hazlitt, 1877; 107 chapters, sections labelled "II.3 …" by book and chapter; the Gutenberg volunteers' bracketed notes signed "D.W." are stripped). Single-source texts rely on Gutenberg's proofreading. Rebuild with the scripts in `script/texts/`. |
| Library structure | **Collection > Work > Section > Unit** (decided 2026-10-02). Collections are a real table (name, slug, position, description, parent) so they can have their own pages, e.g. "Old Testament". **Collections nest** to any depth (decided 2026-10-02) via `parent_id`: e.g. Sacred Texts > Book of Mormon > 1 Nephi (a Work). A collection's Random and work count include everything nested under it; the library lists top-level collections only. Works have a `position` for canonical order. Loading texts updates in place and never deletes, so notes survive reloads. A Bible book is a Work, a chapter a Section, a verse a Unit. |
| Authors | **Optional `works.author` (full name) and `works.author_short`** (decided 2026-10-04), set by `author:` / `author_short:` in the text files; blank for scripture and anything without a known author. Translators stay in `edition`. Library pages show the full name beside the work; lectio shows the short name in the small slot before the edition ("Frost · Collected Poems (1930)"), hidden on phones. Nothing is shown when the title already is the author (Emily Dickinson). |
| Landing page | **Public landing page at `/`** (decided 2026-10-04) for signed-out visitors, using its own layout (`layouts/landing`, CSS inline) so it can't leak into app styles; signed-in users still go straight to reading. Prototype: `prototype/landing.html`. No contact address or email link anywhere, because signups are by invitation only and the author doesn't want to be reachable by strangers. |
| History | **Global per user, not per focus** (decided 2026-10-04), so a trail survives starting a new focus. `visits` table, one row per `(user, unit)`, newest first, capped at 50, written by `PositionsController#update`. Stepping to a neighboring verse moves the latest entry along instead of adding one, so the list holds places, not every verse read. UI: a clock icon in the reading nav opens a dropdown of the last 8 places before the current one (reference, snippet, age, a dot if the verse has a note in the current focus); `h` opens it, Up/Down move, Enter goes. |
| Keep | **Keep** (decided 2026-10-04) is the bookmark: a per-user mark on a passage, independent of any focus, for something profound you stumble on and want to return to. `keeps` table, one row per `(user, unit)`, with an optional plain-text remark (200 characters). UI: a bookmark ribbon just left of the reference line above the passage (revised the same day from a ribbon hanging off the focus band, which felt disconnected from the text); the whole reference row sticks below the header while a long passage scrolls. Quiet outline when idle; filled accent when kept. Tap to keep (a brief "Kept · Add a remark · Undo" line follows); tap a kept ribbon for a popover with the remark, Release and "See all kept"; `b` does the same as a tap. Kept verses are marked on the verse strip and in the history list. The **Kept page** (`/kept`, from the ⋯ menu and the library) lists passages newest first or in reading order, with the remark, and "Start a focus from this" opens the new-focus form with the passage shown and begins reading there. Not yet: a Random scope over kept passages. |
| Process | Build a plain-HTML prototype first (`prototype/index.html`) to iterate on look and feel before committing to a stack. |

## Design implications

- The focus is the app's current state: no switcher or lenses. Home is "continue where you left off". Past foci live in a simple archive list.
- Layout is adaptive. Desktop shows text and notes side by side. Phone shows text with a bottom sheet for notes.
- Lectio Mode (one verse at a time, large type) is a reading option on all screen sizes, and a candidate default on phones.
- Notes are a perpetually open editor for the current verse that autosaves; there is no add/expand step.
- Texts need a generic addressable-unit model (work > section > numbered unit) covering verses, poetry lines/stanzas, and prose paragraphs.

## Proposed v1 scope

**In**
1. Bundled texts (2-3 to start), browsable by work and chapter
2. Create a focus (title, optional description) and mark it current
3. Read a passage with the focus pinned on top
4. Set the current verse, which highlights it
5. Write a note on a verse (always-open rich editor, autosaved; one note per verse per focus)
6. See notes in the margin/side panel, and in the mobile bottom sheet
7. Focus view: all notes in reading order
8. Markdown export
9. Responsive layout that works well on a phone

**Later**
- Word-level highlights within a verse
- Cross-reference links (`@Psalm 23:1`) with previews
- "Current answer" document with version history
- Margin Map (minimap of where notes cluster) and Synthesis view
- Offline support / PWA
- Search

## Open questions

1. ~~Stack~~ Settled: Rails + Hotwire + SQLite + Lexxy.
2. **First texts.** Suggested: KJV Bible (Isaiah 40 is the motivating example), plus one poetry collection and one prose work.
3. **Offline.** Online-only for v1, or must it work without signal?
4. **Next step.** Clickable HTML wireframes first, or scaffold the app and iterate on the real thing?

## Visual tone (ideas, not decisions)

Quiet study desk, not a productivity tool: serif reading face, warm paper tones, dark mode for night reading, a calm but prominent focus line, and no gamification or streaks.
