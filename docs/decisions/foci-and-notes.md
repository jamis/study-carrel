# Foci and notes

## Foci

One focus at a time. No parallel foci in v1. The focus is the app's current state: no switcher or lenses. You read under one focus, but a passage's note can be written under any of your other focuses from the reader without making it current (decided 2026-10-21; see [Notes under another focus](#notes-under-another-focus)). Archiving one puts it away (see [Archiving](#archiving)); deleting one throws it away, with everything written under it (see [Deleting](#deleting)).

**Every focus not archived is in use; one is just current** (decided 2026-10-21). Choosing another doesn't retire the old one. Each focus stores when it was last made current (`foci.made_current_at`), and the latest is the current one; making one current stamps it and touches nothing else. Until then `archived_at` had meant "not current", stamped on the old focus whenever another was started or chosen, so every focus but one read as finished.

## Home: the focuses page

**Signed in, `/` is the focuses page** (decided 2026-10-12; it used to drop you straight back into reading). Every focus you've had is an index card, so home shows what you've been asking, not only where you stopped. Design reference: `prototype/home/b.html`, chosen over a one-column list (A), a table of contents (C), a list-and-detail split (D) and four other card treatments (B1 to B4).

- The **current** card is double width with a ribbon: its dates, title, description, and a panel, "Continue at Isaiah 40:25 →" with the passage (or "Choose where to begin" before any reading), set apart so it's easy to find. Under it, quieter, "or find something new in the library →" (only once there's a place to continue from).
- **Past** cards (the other focuses in use; the code says "others") show when they were begun ("since October 2, 2026"), title and description (three lines at most). They used to show a span ("Jun – Sep 2026"), ending when another focus was made current, which made them look finished. The whole card is a button: clicking it makes that focus current (decided 2026-10-12; it was a "Make current" chip). Back on the cards, that card moves into the current slot as the old current card goes back among the rest (a view transition, .3s, the cards crossfading at their own size rather than stretching), then its ribbon unrolls. Prototyped against the card simply rising in place; the prototype was discarded.
- Every card ends with "12 notes in Ruth, Leviticus and Deuteronomy" (or "No notes yet"): the count and the works those notes are in, one line, so the works aren't mistaken for a citation. Past three works, it names the three with the most notes (in library order) and counts the rest: "49 notes in Isaiah, Psalms, Romans and 9 other works" (decided 2026-10-25; a focus across a dozen books had a list that swamped the card and said little). The same goes for the card laid flat on the delete page and the works under it. Rolling the works up into their collection ("14 books of the Bible") was considered and left: it reads badly across collections, and user texts have none. The count links to that focus's notes page, on past cards too (above the card's button, so reading a past focus's notes doesn't make it current, and pointing at the link doesn't light up the card).
- No note is quoted on the cards (tried 2026-10-12): out of its passage a note lacks context, and the works line under it read as its source.
- A dashed "A new question" card starts a new focus. No totals or tallies across focuses.
- No focuses yet: you go to the new-focus form. With every focus archived, the page shows only "A new question" and the way to the archive.
- "Continue reading" (in the rail off the reader, and the current focus's card) is `/continue`, which resumes the current focus where it left off.
- Every card has an **Edit** (decided 2026-10-20; editing used to be a chip in the reader's description dropdown), an **Archive** and a **Delete** (both decided 2026-10-21), faint at the foot until pointed at, above a past card's button like its notes link. Editing is from the card only: the notes page had "Edit focus" in its head until 2026-10-27, taken off as the wrong place for it.
- Under the cards, a quiet "Archived focuses 3 →", only when something is archived.
- **No focus current** (the current one was archived): the wide slot says "No focus is current. Choose one of your focuses to read under, or start a new question." Pages that need a current focus (the reader, Continue reading) bring you here, or to the new-focus form if every focus is archived.
- After **starting** a focus you go straight to reading. After **editing** one or **making one current** you come back to the cards, as does Cancel on either form; editing from the notes page comes back to the notes page (`?back=notes`).
- The UI says "focuses", never "foci" (the code keeps `Focus`/`foci`).

## Archiving

**A focus can be archived** (decided 2026-10-21): put away when a timeboxed study is done, so the focuses page stays the ones you're using. Long-lived focuses stay as they are; archiving is for the short ones. Prototype: `prototype/home/archive.html` (transient). If accounts are ever limited to a number of active focuses (a subscription), archiving is how you'd stay under it; for now there's no limit.

- **Archive** is at the foot of every card, the current one included. No confirmation, as it's easily undone: the card goes, and a word at the foot of the page says "Archived "…" · Undo" (fading after eight seconds, held while pointed at).
- **Archiving the current focus** leaves none current until you choose one on the cards (rather than quietly making the most recent other one current). Undone straight away, it's current again. In general an unarchived focus is current again only if no other was made current since; otherwise it goes back among the others.
- **The archive** (`/foci/archived`, "Archived focuses →" under the cards): the archived focuses newest first, as flatter cards (no shadow, the title in soft ink) showing their span, begun to archived ("Feb – Apr 2026"), the notes line linking to the notes page, and **Unarchive** (with Undo). The cards aren't buttons: an archived focus can't be made current without unarchiving it.
- **Read-only:** nothing is written, labelled or grouped under an archived focus, enforced on the server (403): no notes on passages or on the whole focus, new or changed; no labels put on or taken off, no Gather, no naming groups from its page; no scratchpad changes; no Discard for its detached notes; no Edit, and it can't be made current. Where its reread is up to still moves, and Copy Markdown / Download `.md` still work.
- **Its notes page** keeps the run, `j`/`k`, the labels as pills (without ×), the labels panel to point at (tapping a label does nothing) and the scratchpad's text behind its tab; it drops "+ New note", taking labels off, + label and Gather. "Unarchive" in the line under the title brings it back, staying on the page.
- **Elsewhere:** archived focuses aren't offered to note a passage under; "Also noted under" still names them (read-only). Labels used under them still count in the label picker and "also under …".
- The UI's word is "archive"; the code's `archived_at` means only that.

## Deleting

**A focus can be deleted** (decided 2026-10-21): for one made as a test, or a question you've changed your mind about studying. Archiving is for one you're done with; deleting is for one you don't want at all. Prototype: `prototype/home/delete.html` (transient).

- **Delete** is at the foot of every card, after Archive (after Unarchive on an archived card), faint like them, rose when pointed at. It's a link, not a button: it only asks.
- **It asks on a page of its own** (`/foci/:id/delete`), not a browser dialog, so it can show exactly which focus and what goes with it: "Delete this focus?", the focus as its card laid flat (dates, title, whole description, notes line), then "**12 notes** go with it:" listing the notes on passages (and the works they're in), those on the whole focus, any detached notes ("3 more set aside earlier, from passages that changed") and its scratchpad, each only if there is any; with none, "It has no notes." Then "This can't be undone.", and for the current focus, which will be current instead.
- **With notes**, a quiet box offers the ways to keep them: "To put it away and keep its notes, archive it instead" (not for an archived focus, already put away), and "download its notes (.md) first". Then **Delete this focus** (rose, the only button) and Cancel.
- From the archive, the trail, Cancel and the delete all go back to the archive (`?back=archived`); otherwise to the cards. After deleting, "Deleted "…"" at the foot of the page, **no Undo**.
- **Everything written under it goes:** its notes (on passages and on the whole focus), its detached notes and its scratchpad. Labels go with their last note, as always (a label lasts only while some note carries it); those also on another focus's notes stay.
- **Its notes aren't set aside as detached notes**, as a deleted text's are: detached notes are shown under their focus, and with it gone they'd have nowhere to be. "Notes survive" is about loading texts losing notes unasked; this is asked for, after being told what goes.
- **Deleting the current focus makes the next most recent current**, as if it had never been (unlike archiving it, which leaves none current). The page names the one that will be: "It's your current focus, so "…" will be current instead." With no other focus in use, none is.
- An archived focus can be deleted: read-only stops writing under it, not throwing it away. Another user's focus is a 404.

## Focus presentation

**The focus stands directly over the passage** (decided 2026-10-12): the first thing your eye lands on for every passage, read together with the text rather than as a header for the screen.

- No label. The focus in soft-ink italic, 19–22px, accent on hover; a statement (a thesis, a metaphor) mustn't pass for the passage's title, and the soft italic reads as an epigraph, not a heading.
- A small thought bubble before it, in the faint ink of the keep ribbon and in the ribbon's slot, so the focus lines up with the reference below; wrapped lines stay clear of it. (The drawing is a stand-in, to be replaced with a better one.)
- A chevron at the end of its last line drops the description, and under it **your other focuses**, to note this passage under one of them (decided 2026-10-21; see [Notes under another focus](#notes-under-another-focus)). Nothing else: "Edit focus", "New focus" and "All focuses" went on 2026-10-20 (editing is done from the cards, a new focus is the dashed card, and All focuses is the rail's "Your focuses"). It closes on a second click, a click outside, or Esc, and never touches the note sheet.
- **With neither a description nor another focus**, no chevron and nothing to click: the focus isn't a button, takes no hover colour and has no title. (It used to drop "No description yet. Add one.") Without a description but with other focuses, it drops the list alone.
- A hairline rule across the whole column sets it off from the passage.
- Not sticky: it scrolls away with the top of a long passage, and the reference row sticks to the top instead. On phones it starts level with the ⋯ and keeps clear of it.
- Left-aligned (decided 2026-10-03), flush with the body text.

History: a thin bar felt lost and a large hero banner too big; a filled pill with a 32px accent title read as a shout (2026-10-04); a small label and soft title, sticky at the top of the column (2026-10-05), turned out too faint, especially on phones. Five ways to give it more presence were prototyped on 2026-10-12 (a heading, a paper slip, the focus heading the note, a focus that brightens on each new verse, and the focus over the passage); the last was chosen, then refined (no label, soft ink, the rule across the column, the bubble). The prototypes were discarded.

## Notes

**One note per verse per focus** (decided 2026-10-03), enforced by a unique index on `(focus_id, unit_id)`.

**Notes on the focus as a whole** (decided 2026-10-13): what you notice across passages rather than on one. They have no unit (`notes.unit_id` is empty; the index still holds one note per passage, as SQLite treats each NULL as distinct), any number per focus, labelled like any note. They're written on the notes page, the reread (see [reread.md](reread.md)), and in the reader from the note sheet's focus tab (decided 2026-10-20; see [reader.md](reader.md)), always by an explicit "+ New note", never an open editor that would number a stray thought. They're saved to their own focus, so a past focus's can be written and changed too (not an archived one's). They follow the notes on passages under "On the whole focus", each headed by its number and date ("Focus 2 · October 14") where a passage would be; in the export, a "## On the whole focus" section. They count on the focus's card but name no work.

- **Numbered on their focus** (decided 2026-10-20): "focus 2" is how one is referred to wherever a passage's note would be "40:12" (a group's notes, the held notes' tabs, "like focus 2"). A scripture reference says little about what's in the note either, and a pop-up shows the note itself. "whole, Oct 14" was tried first: "whole" read badly, and two notes written the same day couldn't be told apart. The number is stored (`notes.number`) and never reused: the focus counts what it has handed out (`foci.free_notes_numbered`), so a deleted note leaves a gap, as a missing verse would, rather than a reference quietly coming to mean another note. A note cleared and written again is a new note, with the next number.

- An always-open Lexxy editor, docked as a full-height page down the right (a bottom sheet on phones, whose handle shows the note's first line).
- **Autosaves** as you type (and on leaving the verse); clearing it deletes the note. There is no add/expand step.
- Toolbar shrunk (icons about 35% smaller) and moved below the text; on desktop it shows only while the editor has focus (decided 2026-10-05).

Trade-off accepted: no per-note timeline of when each thought arrived (only the last-updated time), and last save wins across tabs.

Notes that lose their unit (a revised or deleted user text) become detached notes; see [user-texts.md](user-texts.md).

### Notes under another focus

**A passage's note can be written under another of your focuses from the reader** (decided 2026-10-21), without making that focus current. Reading under one question you often see that a passage answers another; before, that meant going to the cards, making the other current, finding the passage again in the history, writing, and going back the same way. Prototype: `prototype/reader/other-focus.html` (transient).

- **Where:** the focus over the passage drops your other focuses under its description (`o` opens it). One line each, as a focus stands over the passage (the bubble, soft italic, cut short with an ellipsis; its dates as a tooltip). Those with a note on this passage come first, marked "noted", then the rest, most recently current first. Five show (more if more are noted) until "All 12 focuses…". Past seven, a "Find a focus…" field: typing narrows the list, Enter takes the first. 1–9 and ↑/↓ choose.
- **Writing:** choosing one opens its note on this passage in the sheet's editor (the passage tab, opened on phones), on a tinted slip headed by that focus, with "← Back to *the current focus*" (Esc). A dot on the passage's tab, and on phones the reference in the handle in the accent colour, say the note is going elsewhere. It autosaves and clears like any passage's note, to that focus (`/foci/:id/units/:unit_id/note`); the current focus, your place and your history are untouched, and the verse grid's dots stay the current focus's.
- **Back:** "Back to…", Esc, or moving to another passage: a new verse always opens under the current focus.
- **Also noted under:** under the current focus's note, a faint line names your other focuses with a note on this passage, each opening that note in place. It's how you find what you wrote elsewhere, without leaving the reader.
- Any of your focuses not archived can be written under; archived ones aren't in the list. Another user's focus is a 404.
- An archived focus's note on the passage is still named under "Also noted under", and opens read-only: its text, no editor, the slip saying "Archived, so only to read".
- Considered: a picker in the sheet itself, at the foot of the passage's note ("Note this under another focus…"), the prototype's A. The list under the focus was preferred: it sits with the focus it's an alternative to. A switcher that kept your place was rejected: you'd still have to switch back, and could forget.

## Notes pages

**Every focus has its own notes page**, `/foci/:id/notes` (decided 2026-10-12; it was one "All notes" page at `/notes`, which showed only the current focus's notes despite the name). The rail stays the current focus's.

**The notes page is the reread** (decided 2026-10-19): the notes one at a time down one column with the scratchpad beside them, as described in [reread.md](reread.md). The reread began as a page of its own beside the notes page, which then felt redundant: everything it showed, the reread showed too.

- Under "Your focuses", titled with the focus (Your focuses › Archived for an archived one, with "Archived October 21, 2026 · Unarchive" after "Rereading 8 notes ▾").
- **Copy as Markdown · Download `.md`** at the right of the page head, as quiet words in the trail's small type, faint until pointed at (chips until 2026-10-27, which drew the eye too much), exporting the notes, those on the whole focus and the detached notes.
- **Detached notes** follow the run under "From passages that changed or were removed": the reference grey and not a link (there's nothing to open), why it was set aside, the passage, the note, its named labels' names kept as text, and Discard. They're out of the run (no `j`/`k`, labels or grouping), being no longer notes, and faint until pointed at. Not shown under `?label=`. Turning one back into a note on the whole focus was considered, to bring it into the run, and left for later: they should be rare.
- The rail's "Notes on this focus", with its count (12), is for the current focus; the count is kept up to date as notes are written (`.focus-notes-count`). The cards link each focus's count to its page. There is no separate "Reread" link any more.
- `/notes` still works: it redirects to the current focus's page. `/foci/:id/reread` redirects to the focus's notes page, keeping `?label=`.
- No page of every note across focuses: a note makes sense only beside the question it answers, and the focuses page already serves as the index across them.
- Another user's focus is a 404, as everywhere.

### Before the reread

From 2026-10-12 to 2026-10-19 the notes page was laid out beside the text, as in the reader: the passages down the left under the focus, the notes on a sheet of paper down the right, each level with its passage (one column on phones, the note on a slip under its passage). The whole passage cell linked back into reading, long passages clamped to four lines with "Show full passage". The Kept page kept that layout until 2026-10-25 (see [history-and-keep.md](history-and-keep.md)). It was prototyped against the old single column with the passage stepped back (an epigraph), notes as index cards, and a commonplace book with each passage folded to its first words in the margin; the prototypes were discarded.
