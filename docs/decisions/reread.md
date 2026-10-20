# Reread

The first part of synthesis (see [synthesis.md](synthesis.md), still exploratory for essays): going back over a focus's notes one at a time, labelling them as you go, with a scratchpad beside them for rough thoughts. Decided 2026-10-13 and built as a page of its own; since 2026-10-19 it is the notes page (see [foci-and-notes.md](foci-and-notes.md)), the two having overlapped too much.

## The page

**`/foci/:id/notes`, for any focus** (it was `/foci/:id/reread`, which now redirects there), the current one or a past one, without making a past one current. The rail stays the current focus's.

- Every note on a passage in reading order down one column, as on the notes page (reference, passage, note), then the notes on the focus as a whole under "On the whole focus", each dated. The one you're on is lit and the rest dimmed in place, as clause by clause dims the rest of a passage. The passage is clamped to two lines except on the lit note.
- `j`/`k` (or `←`/`→`) move, as does clicking a note; a held key moves once, as in the reader. The lit note scrolls to the middle.
- **Where you left off** is kept per focus (`foci.reread_note_id`, cleared if that note goes), so the reread opens there again.
- The way up: Your focuses. Copy Markdown and Download `.md` at the right of that line. A past focus's dates follow the count.
- Detached notes follow the run, out of it, to read or discard (see [foci-and-notes.md](foci-and-notes.md)).
- The reference links into the reader; on the lit note it reads "Isaiah 40:25 Open in the reader →", all one link (the hint was once a separate span that lit up with the reference but did nothing when clicked).
- `?label=` rereads only the notes carrying one label, chosen from "Rereading 8 notes ▾" over the run.
- **Editing:** the current focus's lit note gets the reader's editor in place (`e` puts the cursor at its end). A past focus's notes on passages are only read here: the reader's note editor saves to the current focus, and editing them was a nice-to-have left out to keep this simple. Notes on the whole focus save to their own focus, so they can be edited on any focus.

## Notes on the whole focus

See [foci-and-notes.md](foci-and-notes.md) for what they are. Here is where they're written:

- **New note** (`n`), by the scratchpad beside Labels (on phones, on its sheet's handle, which closes the sheet), and a dashed "+ New note" slip at the end of the run, open a new row at the end with its editor. The first save makes the note (the reply tells the editor where to save from then on), and it can be labelled once it exists. Moving on from a new row left empty removes it. Clearing a note deletes it, as in the reader. (It was "+ Note on the whole focus", a faint link at the end of the run only: hard to find on a long run, and wordy.)
- **Make a note of this:** select some of the scratchpad and a button over the selection turns it into a note on the whole focus at the end of the run (its lines as paragraphs); "Made a note on the whole focus · Go to it" says so. The scratchpad keeps the working, the note the result. The words stay in the scratchpad.

## Labels

**A user's own labels on notes, like sorting index cards into piles** (many to many: a note can carry several).

- They belong to the user, not the focus (`labels`, unique per user ignoring case, up to 40 characters), so one label can gather notes from several focuses. Another user's labels are a 404, as everything else is.
- **A label needn't have a name.** Notes found to go together (below) make an unnamed label: a group before there are words for it, known by one of its notes, its example (`labels.example_note_id`), and shown as "like Isaiah 40:6" and the start of that note. Seen from the example itself, it's shown by its next note instead ("like this note" says nothing). Naming it later makes it an ordinary label. (Decided 2026-10-19: labelling was hard because it asked for the right word up front, and shades of meaning, "accepting" others or God's will, blurred under one word.)
- A label lasts only while some note carries it: taking off its last note (or deleting that note) drops it. Taking off its example moves the example on to its next note.
- **Naming and renaming** from the note's groups in "Find what goes with this"; a blank name leaves it unnamed again. A name you already have for another label is refused, saying so ("You already have a label called “waiting”"): merging isn't built yet, so the way round is to move the notes over by hand.
- On the lit note, chips with ×, **+ label** (`l`), which opens the picker (below), and **Find what goes with this** (`g`). On the other notes, the labels are quiet names. An unnamed label's chip on the lit note has the start of its note too.
- A note set aside as a detached note keeps its named labels' names as text (`detached_notes.label_names`), shown under it after the run; they no longer count anywhere. Unnamed ones aren't kept.

## The label picker

**Every label you have as a cloud, to browse as much as to search.** Decided 2026-10-18, after a prototype (not kept).

- All one size, wrapped to fill a picker about 26em wide; the cloud scrolls when there are more than fit, the box and footer staying put. Nothing is cut off: you often browse for a fitting label, more so as they grow numerous.
- **A–Z · Recent** beside the box, remembered in the browser. Recent is when a label was last put on a note (`Label.last_used`, from `note_labels.created_at`).
- Only named labels: an unnamed one can't be typed, and putting a note in one is what "Find what goes with this" is for.
- One list: labels used only under other focuses take their place in it, faint, dashed and italic as in the cloud panel, saying where on hover. (They were first a separate group after the rest.)
- Typing narrows it to labels holding what you typed, underlined in each.
- **What Enter does is always said** in a footer ("↵ holiness"), as the user couldn't tell whether Enter took the first match or made a new label of the part typed. Enter takes the closest match, lit in accent: starting with what you typed, then a word starting with it, then holding it, the first among equals; `↓`/`↑` or pointing move it. With nothing typed nothing is lit, and Enter does nothing. A new label of what you typed, unless it's one of yours already, waits in the footer ("+ New label “ho”"): a click, or `↑` round from the first label, and Enter takes it on its own when nothing matches.
- **Placed to stay in sight:** under + label unless that leaves room for only a row or two of labels and there's more above (on phones the scratchpad's handle takes the foot of the screen); then over it, the box at its foot nearest the label. The cloud is cut to the room there is. + label scrolled out of sight is brought back to the middle first. (It used to open under + label regardless, often partly below the fold.)
- An early fix showed only the 8 closest labels with "and N more"; dropped, as it stopped the browsing.

## The labels in use: cloud and tallies

So you can see the shape of the synthesis forming. **A panel called up over the foot of the scratchpad** ("Labels", or `c`) and put away again (×, `Esc` or `c`), not always on screen.

- **Cloud** (the default): each label a pill, so a label of several words reads as one; set in the reading face, larger the more of this focus's notes it holds; alphabetical, so a label grows in place. The lit note's labels are filled in accent. Labels used only under other focuses trail at the end, faint, dashed and italic, to take up here too.
- **Tallies**: each label with its count and a row of marks, one per note in reading order, filled where the note carries it (the lit note's mark taller), so you see where in the focus a label gathers.
- Pointing at a label lights every note that carries it in the column; tapping one puts the lit note on it, or takes it off.
- The view chosen is remembered in the browser.
- Unnamed labels are in both, shown "like" their note, after the named ones (in the order they were made). This is to see how it feels, and may be walked back.
- A tag cloud was first ruled out as feeling like a productivity tool; that was Claude's caution, not the user's, and doesn't hold.

## Finding what goes with a note

**Grouping by recognition rather than by naming:** "do these two go together?" instead of "what's the word for this?". Decided 2026-10-19, after prototypes (not kept).

- **A mode of the reread, not a page:** `g`, or **Find what goes with this** on the lit note, turns the column into the comparison; `g`, `Esc` or the card's × turns it back, on whichever note you ended on.
- **The note you're on is held at the top of the column** on a card, sticky, with `‹ 3 of 12 ›` (`J`/`K` step it). Under "Goes with", its groups (its labels, named or not) numbered for the moment, in the order they were made, each shown by its face (its name, or "like" its note) with the notes in it underneath ("with 40:6, 40:8") and **name it / rename** and **take out**.
- **Every other note of this focus under it**, in reading order, each with a button per numbered group (filled where it's in it) and **+** for a new group of the two. `j`/`k` move through them (the row moved to is scrolled clear of the card), `1`–`9` put it in a group or take it out, `+` (or `n`) makes the new group, `Enter` makes it the note you're on. Only this focus's notes; linking across focuses is for later.
- **Always grouped from the held note's side:** you choose among its groups, never the other note's, so a note already in several just gains one more. The question "which of its groups?" doesn't arise.
- **Pointing ties the two together:** a number on a row lights its group in the card; the groups the row at the cursor is already in are ringed, saying so ("40:4 is in it"); a group pointed at in the card lights its notes in the list.
- **The card is kept short, without scrolling** (a scroll bar inside a sticky card confused): the passage cut to a line, the note to five, each face to one. What's cut off opens over what's below, the whole text laid exactly over the cut one, on hover, a tap, or `p` (passage) and `o` (note); one at a time, `Esc` closing it before it leaves the mode.
- **Colours:** each group has its own muted colour (`label.hue`, its id mod 6, `--g0`…`--g5`), on its number and buttons here only.
- Replies redraw the chips of every note on the label (an unnamed label's face can change from each note's side as notes come and go), the cloud and the tallies; the card and buttons are drawn again from them.

## The scratchpad

**One per focus** (`has_rich_text :scratchpad` on Focus): freeform and unlabelled, for half-thoughts, things to compare, sentences being rewritten. An always-open, autosaving Lexxy editor docked at right as the note editor is in the reader (`s` writes in it). On phones it's a bottom sheet whose handle shows its first line; with the sheet shut, the labels panel comes up as its own short sheet resting on the handle, so the notes stay in view.

## Ways in

It's the notes page, so the ways in are the notes page's: "Notes on this focus" in the ⋯ menu and the count on each focus's card. (Until 2026-10-19 there were separate ones: Reread among the notes page's actions, `r`; "· Reread" on the cards; "Reread these notes" in the menu.) No prompt to reread from the reader: the app doesn't nudge.

## History

Prototyped 2026-10-13 in `prototype/reread/` (since removed): A, the reader one level up (the note where the passage stands, the scratchpad docked); B, index cards with the labels as piles on the desk; C, every note in one spotlit column; D, the scratchpad as the page with notes fed in from the side. B's piles showed the shape of the labels, which the user liked most, but C's way of reading won; variants of C added the labels as a sticky strip (C1), a grid in the margin (C2), tallies under the scratchpad (C3), and a cloud on a panel called up over the scratchpad (C4). **C4** was chosen, its tallies kept as the panel's second view. Its first `L` for the panel clashed with `l` for labelling, so the panel is `c`.

"Find what goes with this" was prototyped 2026-10-19 in `prototype/groups/` (not kept), all four on one set of notes: A, two columns (the held note at left, every other note at right); B, a mode of the reread, the held note on a card over the column; C, piles shown by an example note, the held note weighed against the piles rather than each note; D, notes as cards on a table, dragged about and ringed into overlapping groups. D was too busy and awkward to move about, worse on a phone; C struggles past a handful of piles; A took too much room. **B** was chosen as the middle way. Its card first described groups only by their notes ("with 40:6, 40:8"), which didn't say what a group was about, so they gained faces; its card first scrolled inside itself, so its parts were cut short to open over what's below instead.
