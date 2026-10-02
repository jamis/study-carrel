# Study Carrel: Decisions

Last updated: 2026-10-02

## Concept

A web app for associating text (scripture, poetry, prose) with a **focus**: a question, metaphor, or thesis. The reader sees the passage with the focus pinned prominently, highlights the verse they're pondering, and annotates it as thoughts come.

Example: read Isaiah 40 while pondering "What does it mean to be holy?"

## Decisions made

| Topic | Decision |
|---|---|
| Foci | One focus at a time. No parallel foci in v1. |
| Notes | Mostly short, but a full rich-text editor should be available. 37signals' **Lexxy** editor is worth trying. |
| Users | Just the owner, initially. Sharing is manual (copy/paste). |
| Texts | The app ships with a **bundled corpus**. No import or external API in v1. |
| Mobile | Same functionality as desktop. One responsive design, no cut-down phone version. |
| Platform | Web application, usable from laptop and phone. |
| Stack / editor | No preference from the user; Claude decides. **Rails + Hotwire + SQLite** (user OK'd Rails). **Lexxy 1.0.0** for notes (step 9 spike passed), on Action Text. |
| Reading model | **Lectio mode only** for v1 (one verse at a time, neighbors faded, verse strip for jumping). Full-chapter reading view deferred as a possible future option. |
| Focus presentation | The focus is the hero of the screen: compact, accent-colored band under the nav, sticky so it stays visible while scrolling. Prototype feedback: a thin bar felt lost; a large hero banner was too big. Description opens as a dropdown. |
| Text alignment | Left-aligned (ragged right), not centered, with a ~34em measure. Type size steps down for longer units (prose paragraphs); neighbors clamp to 2 lines. Demo of long prose: open `prototype/index.html?text=prose`. |
| Design | **Committed** (2026-10-02): `prototype/index.html` is the reference for look and feel: lectio-only, compact sticky focus band, left-aligned text with length-adaptive sizing, verse strip, side panel / mobile bottom sheet for notes. |
| Bundled texts | **KJV Old Testament** (Gutenberg base, cross-checked against two other sources; 115 verses taken from the other sources where the base differed), **Emily Dickinson: Poems** (Gutenberg, three series, 442 poems, stanza per unit), **Thoreau: Walden** (Gutenberg, paragraph per unit). Single-source texts rely on Gutenberg's proofreading. Rebuild with the scripts in `script/texts/`. |
| Library structure | **Collection > Work > Section > Unit** (decided 2026-10-02). Collections are a real table (name, slug, position, description) so they can have their own pages, e.g. "Old Testament"; no nesting for now. Works have a `position` for canonical order. Loading texts updates in place and never deletes, so notes survive reloads. A Bible book is a Work, a chapter a Section, a verse a Unit. |
| Process | Build a plain-HTML prototype first (`prototype/index.html`) to iterate on look and feel before committing to a stack. |

## Design implications

- The focus is the app's current state: no switcher or lenses. Home is "continue where you left off". Past foci live in a simple archive list.
- Layout is adaptive. Desktop shows text and notes side by side. Phone shows text with a bottom sheet for notes.
- Lectio Mode (one verse at a time, large type) is a reading option on all screen sizes, and a candidate default on phones.
- Notes start as a compact inline field and expand to the full editor.
- Texts need a generic addressable-unit model (work > section > numbered unit) covering verses, poetry lines/stanzas, and prose paragraphs.

## Proposed v1 scope

**In**
1. Bundled texts (2-3 to start), browsable by work and chapter
2. Create a focus (title, optional description) and mark it current
3. Read a passage with the focus pinned on top
4. Set the current verse, which highlights it
5. Add notes to a verse or verse range (quick capture and rich editor)
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
