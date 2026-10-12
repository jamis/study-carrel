# Foci and notes

## Foci

One focus at a time. No parallel foci in v1. The focus is the app's current state: no switcher or lenses. Deleting a focus is not supported yet (detaching its notes, as for a deleted text, may be the way; see [user-texts.md](user-texts.md)).

## Home: the focuses page

**Signed in, `/` is the focuses page** (decided 2026-10-12; it used to drop you straight back into reading). Every focus you've had is an index card, so home shows what you've been asking, not only where you stopped. Design reference: `prototype/home/b.html`, chosen over a one-column list (A), a table of contents (C), a list-and-detail split (D) and four other card treatments (B1 to B4).

- The **current** card is double width with a ribbon: its dates, title, description, and a panel, "Continue at Isaiah 40:25 →" with the passage (or "Choose where to begin" before any reading), set apart so it's easy to find. Under it, quieter, "or find something new in the library →" (only once there's a place to continue from).
- **Past** cards show their dates, title and description (three lines at most). The whole card is a button: clicking it makes that focus current (decided 2026-10-12; it was a "Make current" chip). Back on the cards, that card moves into the current slot as the old current card goes back among the rest (a view transition, .3s, the cards crossfading at their own size rather than stretching), then its ribbon unrolls. Prototyped against the card simply rising in place; the prototype was discarded.
- Every card ends with "12 notes in Ruth, Leviticus and Deuteronomy" (or "No notes yet"): the count and the works those notes are in, one line, so the works aren't mistaken for a citation. The count links to that focus's notes page, on past cards too (above the card's button, so reading a past focus's notes doesn't make it current, and pointing at the link doesn't light up the card).
- No note is quoted on the cards (tried 2026-10-12): out of its passage a note lacks context, and the works line under it read as its source.
- A dashed "A new question" card starts a new focus. No totals or tallies across focuses.
- No focuses yet: you go to the new-focus form.
- "Continue reading" (in the rail off the reader, and the current focus's card) is `/continue`, which resumes the current focus where it left off.
- After **starting** a focus you go straight to reading. After **editing** one or **making one current** you come back to the cards, as does Cancel on either form.
- The UI says "focuses", never "foci" (the code keeps `Focus`/`foci`).

## Focus presentation

**The focus stands directly over the passage** (decided 2026-10-12): the first thing your eye lands on for every passage, read together with the text rather than as a header for the screen.

- No label. The focus in soft-ink italic, 19–22px, accent on hover; a statement (a thesis, a metaphor) mustn't pass for the passage's title, and the soft italic reads as an epigraph, not a heading.
- A small thought bubble before it, in the faint ink of the keep ribbon and in the ribbon's slot, so the focus lines up with the reference below; wrapped lines stay clear of it. (The drawing is a stand-in, to be replaced with a better one.)
- A chevron at the end of its last line opens the description as a dropdown.
- A hairline rule across the whole column sets it off from the passage.
- Not sticky: it scrolls away with the top of a long passage, and the reference row sticks to the top instead. On phones it starts level with the ⋯ and keeps clear of it.
- Left-aligned (decided 2026-10-03), flush with the body text.

History: a thin bar felt lost and a large hero banner too big; a filled pill with a 32px accent title read as a shout (2026-10-04); a small label and soft title, sticky at the top of the column (2026-10-05), turned out too faint, especially on phones. Five ways to give it more presence were prototyped on 2026-10-12 (a heading, a paper slip, the focus heading the note, a focus that brightens on each new verse, and the focus over the passage); the last was chosen, then refined (no label, soft ink, the rule across the column, the bubble). The prototypes were discarded.

## Notes

**One note per verse per focus** (decided 2026-10-03), enforced by a unique index on `(focus_id, unit_id)`.

- An always-open Lexxy editor, docked as a full-height page down the right (a bottom sheet on phones, whose handle shows the note's first line).
- **Autosaves** as you type (and on leaving the verse); clearing it deletes the note. There is no add/expand step.
- Toolbar shrunk (icons about 35% smaller) and moved below the text; on desktop it shows only while the editor has focus (decided 2026-10-05).

Trade-off accepted: no per-note timeline of when each thought arrived (only the last-updated time), and last save wins across tabs.

Notes that lose their unit (a revised or deleted user text) become detached notes; see [user-texts.md](user-texts.md).

## Notes pages

**Every focus has its own notes page**, `/foci/:id/notes` (decided 2026-10-12; it was one "All notes" page at `/notes`, which showed only the current focus's notes despite the name). The page is titled with the focus, under "Your focuses", and lists its notes in reading order with their passages, then its detached notes; Copy Markdown and Download `.md` export the same. A past focus's page adds its dates to the line under the title. The rail stays the current focus's.

- The ⋯ menu's item is "Notes on this focus (12)", for the current focus. The cards link each focus's count to its page.
- `/notes` still works: it redirects to the current focus's page.
- No page of every note across focuses: a note makes sense only beside the question it answers, and the focuses page already serves as the index across them.
- Another user's focus is a 404, as everywhere.
