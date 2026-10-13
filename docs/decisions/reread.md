# Reread

The first part of synthesis (see [synthesis.md](synthesis.md), still exploratory for what comes after): going back over a focus's notes one at a time, labelling them as you go, with a scratchpad beside them for rough thoughts. Decided 2026-10-13 and built as a page of its own; it may later merge with the notes page if the two turn out to overlap too much.

## The page

**`/foci/:id/reread`, for any focus**, the current one or a past one, without making a past one current. The rail stays the current focus's.

- Every note in reading order down one column, as on the notes page (reference, passage, note), the one you're on lit and the rest dimmed in place, as clause by clause dims the rest of a passage. The passage is clamped to two lines except on the lit note.
- `j`/`k` (or `←`/`→`) move, as does clicking a note. The lit note scrolls to the middle.
- **Where you left off** is kept per focus (`foci.reread_note_id`, cleared if that note goes), so the reread opens there again.
- The way up: Your focuses › Notes. The reference links into the reader, with "Open in the reader →" on the lit note.
- `?label=` rereads only the notes carrying one label, chosen from "Rereading 8 notes ▾" over the run.
- **Editing:** the current focus's lit note gets the reader's editor in place (`e` puts the cursor at its end). A past focus's notes are only read here: the reader's note editor saves to the current focus, and editing a past focus's notes was a nice-to-have left out to keep this simple.

## Labels

**A user's own labels on notes, like sorting index cards into piles** (many to many: a note can carry several).

- They belong to the user, not the focus (`labels`, unique per user ignoring case, up to 40 characters), so one label can gather notes from several focuses. Another user's labels are a 404, as everything else is.
- A label lasts only while some note carries it: taking off its last note (or deleting that note) drops it. Renaming and merging are not built yet.
- On the lit note, chips with ×, and **+ label** (`l`), which opens a picker: your labels filtered as you type (those used only under other focuses say where), Enter or a click to choose, or a new label of what you typed. On the other notes, the labels are quiet names.
- The notes page shows each note's labels quietly under it.
- A note set aside as a detached note keeps its labels' names as text (`detached_notes.label_names`), shown under it on the notes page; they no longer count anywhere.

## The labels in use: cloud and tallies

So you can see the shape of the synthesis forming. **A panel called up over the foot of the scratchpad** ("Labels", or `c`) and put away again (×, `Esc` or `c`), not always on screen.

- **Cloud** (the default): each label a pill, so a label of several words reads as one; set in the reading face, larger the more of this focus's notes it holds; alphabetical, so a label grows in place. The lit note's labels are filled in accent. Labels used only under other focuses trail at the end, faint, dashed and italic, to take up here too.
- **Tallies**: each label with its count and a row of marks, one per note in reading order, filled where the note carries it (the lit note's mark taller), so you see where in the focus a label gathers.
- Pointing at a label lights every note that carries it in the column; tapping one puts the lit note on it, or takes it off.
- The view chosen is remembered in the browser.
- A tag cloud was first ruled out as feeling like a productivity tool; that was Claude's caution, not the user's, and doesn't hold.

## The scratchpad

**One per focus** (`has_rich_text :scratchpad` on Focus): freeform and unlabelled, for half-thoughts, things to compare, sentences being rewritten. An always-open, autosaving Lexxy editor docked at right as the note editor is in the reader (`s` writes in it). On phones it's a bottom sheet whose handle shows its first line; with the sheet shut, the labels panel comes up as its own short sheet resting on the handle, so the notes stay in view.

## Ways in

- The notes page: **Reread** among its actions, `r`.
- Each focus's card: "· Reread" after its notes line (above the card's button, so a past focus stays past).
- The ⋯ menu: "Reread these notes", for the current focus.

None show before a focus has notes. No prompt to reread from the reader: the app doesn't nudge.

## History

Prototyped 2026-10-13 in `prototype/reread/` (since removed): A, the reader one level up (the note where the passage stands, the scratchpad docked); B, index cards with the labels as piles on the desk; C, every note in one spotlit column; D, the scratchpad as the page with notes fed in from the side. B's piles showed the shape of the labels, which the user liked most, but C's way of reading won; variants of C added the labels as a sticky strip (C1), a grid in the margin (C2), tallies under the scratchpad (C3), and a cloud on a panel called up over the scratchpad (C4). **C4** was chosen, its tallies kept as the panel's second view. Its first `L` for the panel clashed with `l` for labelling, so the panel is `c`.
