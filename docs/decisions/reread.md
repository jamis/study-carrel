# Reread

The first part of synthesis (see [synthesis.md](synthesis.md), still exploratory for essays): going back over a focus's notes one at a time, labelling them as you go, with a scratchpad beside them for rough thoughts. Decided 2026-10-13 and built as a page of its own; since 2026-10-19 it is the notes page (see [foci-and-notes.md](foci-and-notes.md)), the two having overlapped too much.

## The page

**`/foci/:id/notes`, for any focus** (it was `/foci/:id/reread`, which now redirects there), the current one, a past one or an archived one, without making it current. An archived focus's is read-only (see [Archiving](foci-and-notes.md#archiving)). The rail stays the current focus's.

- Every note on a passage in reading order down one column, as on the notes page (reference, passage, note), then the notes on the focus as a whole under "On the whole focus", each by its number and date ("Focus 2 · October 14"). Each note's labels are pills under it (below). The one you're on is lit and the rest dimmed in place, as clause by clause dims the rest of a passage. The passage is clamped to two lines except on the lit note.
- **The passage is set as a quotation** (decided 2026-10-25): indented, with a hairline in the rule colour down its left, the note under it at full width. Only size and a softer ink had told them apart, and at a glance a passage read as the note's first paragraph. Prototyped (not kept) against the passage in italic, which tires over a long passage of prose; on a tinted slip, the clearest but busy down a run of them, even on the lit note only; and a short rule marking where the note begins, which left the passage looking the same. The Gather card and its pop-ups keep their passages plain, being short of room.
- **The column is about 48em wide** on a wide screen (decided 2026-10-20), wider than the reader's 34em measure: with the scratchpad put away there's nothing beside it, and comparing notes wants the room (the card's tabs were crowded at 36em, the width it had beside the docked scratchpad). Keeping the notes' text to about 40em inside a wider row was the alternative, if the full width reads too long.
- `j`/`k` (or `←`/`→`) move, as does clicking a note; a held key moves once, as in the reader. The lit note scrolls to the middle.
- **Where you left off** is kept per focus (`foci.reread_note_id`, cleared if that note goes), so the reread opens there again.
- The way up: Your focuses (› Archived, for an archived focus). Copy Markdown and Download `.md` at the right of that line. An archived focus's "Archived October 21, 2026 · Unarchive" follows the count.
- Detached notes follow the run, out of it, to read or discard (see [foci-and-notes.md](foci-and-notes.md)).
- The reference links into the reader; on the lit note it reads "Isaiah 40:25 Open in the reader →", all one link (the hint was once a separate span that lit up with the reference but did nothing when clicked).
- `?label=` rereads only the notes carrying one label, chosen from "Rereading 8 notes ▾" over the run.
- **Editing:** the current focus's lit note gets the reader's editor in place (`e` puts the cursor at its end). A past focus's notes on passages are only read here: the reader's note editor saves to the current focus, and editing them was a nice-to-have left out to keep this simple. Notes on the whole focus save to their own focus, so they can be edited on any focus.

## Notes on the whole focus

See [foci-and-notes.md](foci-and-notes.md) for what they are. Here is where they're written:

- **New note** (`n`), the dashed "+ New note" slip at the end of the run, and on phones New note on the scratchpad's handle (which closes the sheet), open a new row at the end with its editor. (A New note button by the scratchpad went when the scratchpad was put away behind its tab.) The first save makes the note (the reply tells the editor where to save from then on), and it can be labelled once it exists. Moving on from a new row left empty removes it. Clearing a note deletes it, as in the reader. (It was "+ Note on the whole focus", a faint link at the end of the run only: hard to find on a long run, and wordy.)
- **Make a note of this:** select some of the scratchpad and a button over the selection turns it into a note on the whole focus at the end of the run (its lines as paragraphs); "Made a note on the whole focus · Go to it" says so. The scratchpad keeps the working, the note the result. The words stay in the scratchpad.

## Labels

**A user's own labels on notes, like sorting index cards into piles** (many to many: a note can carry several).

- They belong to the user, not the focus (`labels`, unique per user ignoring case, up to 40 characters), so one label can gather notes from several focuses. Another user's labels are a 404, as everything else is.
- **A label needn't have a name.** Notes found to go together (below) make an unnamed label: a group before there are words for it. Naming it later makes it an ordinary label. (Decided 2026-10-19: labelling was hard because it asked for the right word up front, and shades of meaning, "accepting" others or God's will, blurred under one word.)
- **An unnamed label goes by a letter: "group D"** (decided 2026-10-26), the same on every note in it, "group" quiet and the letter a little heavier. Letters are the user's, across focuses, handed out in turn and never reused (`labels.number`, counted by `users.labels_lettered`; A–Z, then AA), so a focus's groups may run D, F, H. A label named later keeps its letter, and has it back if its name is taken away; one named first takes the next when its name goes. It's described by one of its notes, its example (`labels.example_note_id`): the hover title ("group D (like Isaiah 40:6: All flesh is grass…)") and the start of that note on Gather's card. A name is never refused for looking like a letter: "group D" as a name is set as a name, and the letter's setting tells them apart.
- **It was shown "like" one of its notes, 2026-10-19 to 2026-10-26:** "like Isaiah 40:6" and the start of that note, except on the example itself, where it was shown by its next note ("like this note" says nothing). So a group read "like 40:6" on all its notes but one, which read "like 40:8", and the list couldn't be scanned by eye for a group's notes. A number was considered, as the footnotes had (below), but Gather's card numbers groups 1–9 for the moment as keys, and "2 group 7" would have been two numbers for one group.
- A label lasts only while some note carries it: taking off its last note (or deleting that note) drops it. Taking off its example moves the example on to its next note.
- **Naming and renaming** from the note's groups in **Gather**; a blank name leaves it unnamed again. A name you already have for another label is refused, saying so ("You already have a label called “waiting”"): merging isn't built yet, so the way round is to move the notes over by hand.
- Every note shows its labels as **pills** under it (below). The lit note's have ×, with **+ label** (`l`), which opens the picker (below), and **Gather** (`g`): the lit note's pills are where labels are taken off.
- A note set aside as a detached note keeps its named labels' names as text (`detached_notes.label_names`), shown under it after the run; they no longer count anywhere. Unnamed ones aren't kept.

## Labels as pills

**A note's labels as pills under its text** (decided 2026-10-25): named ones A–Z, then unnamed ones ("group **D**"), outlined and quiet in faint ink, without the label colours, which stay in Gather. The lit note's are a little larger, with ×. An archived focus's notes have them without ×.

- **They were footnotes, 2026-10-20 to 2026-10-25:** a numbered mark per label after the note's text, in the label's colour, and under the note a line giving each label's name and its other notes by reference, each shown when pointed at. The list of other notes didn't help and made the page wordier, so the pills came back. The numbers had matched the held note's group numbers in Gather; the buttons on each row already show which groups it's in.
- **Pages for each label are planned** (not decided): each would show every note carrying a label, perhaps across focuses. That's where a label's other notes would be seen.
- **A long reference is cut short in the middle, never at its end** (decided 2026-10-20): where room is short (the card's groups and tabs; until 2026-10-26, a face "like" a note and the cloud) the title or name is cut off with "…" and the last part ("1:6") kept whole, since that's what tells it from its neighbours: "Quick to Help, Slow to Judge… 1:6". The whole reference is the hover title and heads the pop-up; a note's own heading keeps it whole. A user's text with a long title had broken the footnotes' line, wrapping the title centred in its button with the verse alone under it.
- Replies to labelling redraw the pills of every note on the label, since an unnamed label's description (its hover title) moves on with its example.

## The label picker

**Every label you have as a cloud, to browse as much as to search.** Decided 2026-10-18, after a prototype (not kept).

- All one size, wrapped to fill a picker about 26em wide; the cloud scrolls when there are more than fit, the box and footer staying put. Nothing is cut off: you often browse for a fitting label, more so as they grow numerous.
- **A–Z · Recent** beside the box, remembered in the browser. Recent is when a label was last put on a note (`Label.last_used`, from `note_labels.created_at`).
- Only named labels: an unnamed one can't be typed, and putting a note in one is what **Gather** is for.
- One list: labels used only under other focuses take their place in it, faint, dashed and italic as in the cloud panel, saying where on hover. (They were first a separate group after the rest.)
- Typing narrows it to labels holding what you typed, underlined in each.
- **What Enter does is always said** in a footer ("↵ holiness"), as the user couldn't tell whether Enter took the first match or made a new label of the part typed. Enter takes the closest match, lit in accent: starting with what you typed, then a word starting with it, then holding it, the first among equals; `↓`/`↑` or pointing move it. With nothing typed nothing is lit, and Enter does nothing. A new label of what you typed, unless it's one of yours already, waits in the footer ("+ New label “ho”"): a click, or `↑` round from the first label, and Enter takes it on its own when nothing matches.
- **Placed to stay in sight:** under + label unless that leaves room for only a row or two of labels and there's more above (on phones the scratchpad's handle takes the foot of the screen); then over it, the box at its foot nearest the label. The cloud is cut to the room there is. + label scrolled out of sight is brought back to the middle first. (It used to open under + label regardless, often partly below the fold.)
- An early fix showed only the 8 closest labels with "and N more"; dropped, as it stopped the browsing.

## The labels in use: cloud and tallies

So you can see the shape of the synthesis forming. **A panel called up over the foot of the scratchpad** ("Labels" at the right edge, or `c`) and put away again (×, `Esc` or `c`), not always on screen. With the scratchpad put away, it comes up on its own, over the foot of the screen at right.

- **Cloud** (the default): each label a pill, so a label of several words reads as one; set in the reading face, larger the more of this focus's notes it holds; alphabetical, so a label grows in place. The lit note's labels are filled in accent. Labels used only under other focuses trail at the end, faint, dashed and italic, to take up here too.
- **Tallies**: each label with its count and a row of marks, one per note in reading order, filled where the note carries it (the lit note's mark taller), so you see where in the focus a label gathers.
- Pointing at a label lights every note that carries it in the column; tapping one puts the lit note on it, or takes it off.
- The view chosen is remembered in the browser.
- Unnamed labels are in both, by their letters, after the named ones (in the order they were made). This is to see how it feels, and may be walked back.
- A tag cloud was first ruled out as feeling like a productivity tool; that was Claude's caution, not the user's, and doesn't hold.

## Gathering what goes with a note

**Grouping by recognition rather than by naming:** "do these two go together?" instead of "what's the word for this?". Decided 2026-10-19, after prototypes (not kept). Its button, first "Find what goes with this", was renamed **Gather** on 2026-10-20 as too long and awkward; one word, keeping `g`.

- **A mode of the reread, not a page:** `g`, or **Gather** on the lit note, turns the column into the comparison; `g`, `Esc` or the card's × turns it back, on whichever note you ended on. `Esc` puts away the scratchpad or the labels first, if they're out.
- **The note you're on is held at the top of the column** on a card, sticky. Its groups (its labels, named or not) numbered for the moment, in the order they were made, a line each: its face (its name, or "GROUP D" and the start of the note it's described by), the notes in it ("with 40:6, 40:8", each showing its note when pointed at, with **Hold it**; on a touch screen a tap shows it and a second puts it away; Esc puts it away; a reference to a note not shown under `?label=` says so), and on hover **name it / rename** and **take out**.
- **Up to three notes held at once, under tabs along the card's top** (decided 2026-10-20): each tab its reference and first words, the one you're on open onto the card and the last to give up its words when they're crowded, × at the right; `‹ 3 of 12 ›` at the right of the note's reference on the card (it was in the tab row, crowding it). **Hold this** on a row (or `Enter` on the row at the cursor, or **Hold it** from a note shown on the card) holds that note under a tab of its own, at the end; with three, the one used longest ago, never the one you're on, gives way. A held note's row says "Held · go to its tab". A tab (or `[`/`]`) goes back to its note, and the list to where it was when that note was last the one you were on, the cursor too. `x` or a tab's × lets one go; letting go of the last leaves. `J`/`K` step the note under the tab, past those held under the others. Leaving and coming back keeps the tabs (for the page's visit, not stored).
- **Holding a note doesn't move the list:** the row that becomes the note you're on leaves the list and its neighbour takes its place on screen; the note you left comes back to its place. (It used to scroll to the top, so linking two notes seen while on a third meant leaving, finding the one, coming back and finding the other.)
- **Every other note of this focus under it**, in reading order, each with its labels, a button per numbered group (filled where it's in it) and **+** for a new group of the two. `j`/`k` move through them (the row moved to is scrolled clear of the card), `1`–`9` put it in a group or take it out, `+` (or `n`) makes the new group. Only this focus's notes; linking across focuses is for later.
- **Always grouped from the held note's side:** you choose among its groups, never the other note's, so a note already in several just gains one more. The question "which of its groups?" doesn't arise.
- **Pointing ties the two together:** a number on a row lights its group in the card; the groups the row at the cursor is already in are ringed, and its reference picked out (in the group's colour) among each one's notes; a group pointed at in the card lights its notes in the list. ("40:4 is in it" said so in words at first, which distracted more than it helped.)
- **The card is kept as short as it can be, without scrolling** (a scroll bar inside a sticky card confused): the passage cut to a line, the note to three, each group to a line. What's cut off opens over what's below, the whole text laid exactly over the cut one, on hover, a tap, or `p` (passage) and `o` (note); one at a time, `Esc` closing it before it leaves the mode.
- **Colours:** each group has its own muted colour (`label.hue`, its id mod 6, `--g0`…`--g5`), on its number and buttons here only.
- Replies redraw the chips of every note on the label (an unnamed label's description moves on with its example as notes come and go), the cloud and the tallies; the card and buttons are drawn again from them.

## The scratchpad

**One per focus** (`has_rich_text :scratchpad` on Focus): freeform and unlabelled, for half-thoughts, things to compare, sentences being rewritten. An autosaving Lexxy editor.

- **Put away by default, behind a tab at the right edge** (decided 2026-10-20), with the Labels tab under it: "Scratchpad" (or `s`, which also puts you in it) slides it in over the right of the page, full height; × or `Esc` puts it away. Room is the constraint while grouping, and in practice notes on the whole focus did the work the scratchpad was meant for (written so they can be grouped with other notes); the scratchpad matters more later, when starting to write something whole. It was docked at right, always open, until then.
- On phones it's still a bottom sheet whose handle shows its first line, with New note and Labels on the handle; with the sheet shut, the labels panel comes up as its own short sheet resting on the handle, so the notes stay in view.

## Ways in

It's the notes page, so the ways in are the notes page's: "Notes on this focus" in the rail and the count on each focus's card. (Until 2026-10-19 there were separate ones: Reread among the notes page's actions, `r`; "· Reread" on the cards; "Reread these notes" in the menu.) No prompt to reread from the reader: the app doesn't nudge.

## History

Prototyped 2026-10-13 in `prototype/reread/` (since removed): A, the reader one level up (the note where the passage stands, the scratchpad docked); B, index cards with the labels as piles on the desk; C, every note in one spotlit column; D, the scratchpad as the page with notes fed in from the side. B's piles showed the shape of the labels, which the user liked most, but C's way of reading won; variants of C added the labels as a sticky strip (C1), a grid in the margin (C2), tallies under the scratchpad (C3), and a cloud on a panel called up over the scratchpad (C4). **C4** was chosen, its tallies kept as the panel's second view. Its first `L` for the panel clashed with `l` for labelling, so the panel is `c`.

"Find what goes with this" (now Gather) was prototyped 2026-10-19 in `prototype/groups/` (not kept), all four on one set of notes: A, two columns (the held note at left, every other note at right); B, a mode of the reread, the held note on a card over the column; C, piles shown by an example note, the held note weighed against the piles rather than each note; D, notes as cards on a table, dragged about and ringed into overlapping groups. D was too busy and awkward to move about, worse on a phone; C struggles past a handful of piles; A took too much room. **B** was chosen as the middle way. Its card first described groups only by their notes ("with 40:6, 40:8"), which didn't say what a group was about, so they gained faces; its card first scrolled inside itself, so its parts were cut short to open over what's below instead.

Linking two notes seen while on a third was prototyped 2026-10-20 in `prototype/groups/` (not kept): E, any row made the held note without the list moving, with a way back; F, a row picked up into a tray at the foot, the rows grouping with it while the held note stayed; G, E's holding with three held notes under tabs, the scratchpad put away, and labels as footnotes. **G** was chosen, after the user proposed its tabs, footnotes and hidden scratchpad (the footnotes went back to pills on 2026-10-25): F put a second note's groups on screen, and room was the constraint.
