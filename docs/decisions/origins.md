# Origins: the early brief

Kept for the record. These were written before the app was built; the topic files beside this one say what is current.

## Process

Build a plain-HTML prototype first (`prototype/index.html`) to iterate on look and feel before committing to a stack. (Still the habit: new features are prototyped in `prototype/` first.)

## Stack

No preference from the user; Claude decides. **Rails + Hotwire + SQLite** (user OK'd Rails). **Lexxy 1.0.0** for notes (step 9 spike passed), on Action Text.

## Design implications (original)

- The focus is the app's current state: no switcher or lenses. Home is "continue where you left off". Past foci live in a simple archive list.
- Layout is adaptive. Desktop shows text and notes side by side. Phone shows text with a bottom sheet for notes.
- Lectio Mode (one verse at a time, large type) is a reading option on all screen sizes, and a candidate default on phones. (It became the only mode.)
- Notes are a perpetually open editor for the current verse that autosaves; there is no add/expand step.
- Texts need a generic addressable-unit model (work > section > numbered unit) covering verses, poetry lines/stanzas, and prose paragraphs.

## Proposed v1 scope (original)

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
- Search (since built)
- Encrypting notes and user texts at rest (user texts make this more pressing)

## Open questions (original)

1. ~~Stack~~ Settled: Rails + Hotwire + SQLite + Lexxy.
2. **First texts.** Suggested: KJV Bible (Isaiah 40 is the motivating example), plus one poetry collection and one prose work. (Settled; see [library.md](library.md).)
3. **Offline.** Online-only for v1, or must it work without signal? (Still open; online-only so far.)
4. **Next step.** Clickable HTML wireframes first, or scaffold the app and iterate on the real thing? (Settled: prototype, then scaffold.)
