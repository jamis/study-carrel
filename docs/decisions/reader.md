# The reader: layout, design and navigation

## Platform and mobile

A web application, usable from laptop and phone, with the same functionality on both: one responsive design, no cut-down phone version. Desktop shows text and notes side by side; a phone shows text with a bottom sheet for notes.

## Design reference

**Committed** (2026-10-02): `prototype/index.html` is the reference for look and feel: lectio-only, compact sticky focus, left-aligned text with length-adaptive sizing.

**Reader revised** (2026-10-05) after five layouts were tried in `prototype/reader/` (A desk, B open book, C single column, D rail and ruler, E rail and steps): **E** was chosen, `prototype/reader/e.html` (D's rail and docked note with A's `‹ 3 of 31 ›`; D's hairline ruler was dropped). Its focus is out of date: since 2026-10-12 the focus stands over the passage, not sticky at the top (see [foci-and-notes.md](foci-and-notes.md)).

Visual tone (ideas, not decisions): quiet study desk, not a productivity tool. Serif reading face, warm paper tones, dark mode for night reading, a calm but prominent focus line, and no gamification or streaks.

## Reading model

**Lectio mode only** for v1: one verse at a time, large, with nothing else from the chapter on screen.

- Revised 2026-10-05 (the reader felt cluttered): the faded neighbors, the numbered-circle verse strip and the bevelled band behind the verse are gone.
- Below the passage, `‹ 25 of 31 ›`: the arrows step (naming where they go as a tooltip, and carrying on into the next chapter at an edge), and the number opens a plain grid of every verse (a dot = has a note, a small ribbon = kept).
- Prose is read a sentence at a time; see [prose-by-sentence.md](prose-by-sentence.md).
- Full-chapter reading view deferred as a possible future option.

### The note sheet

**The note sheet has two tabs** (decided 2026-10-20; prototype `prototype/reader/focus-sheet.html`, transient): "Note · Isaiah 40:25", the passage's note as before, and "The focus (3)", with the thought bubble and the count of notes on the whole focus. Before, the sheet held only the passage's note, and the reader had no way to write what you notice across passages.

- **The tab stays where you put it**: changing verse doesn't switch back, and it's kept for the sitting (sessionStorage), so the next chapter opens on it too. A new tab or window starts on the passage. The passage tab's label follows the verse you're on.
- `f` turns between the tabs; `n` on the focus tab starts a note (both ignored while typing).
- **The focus tab is a list, not an open editor** (an open editor read as a scratchpad, and would quietly number a stray thought): a dashed "+ New note" slip at the top, then the notes on the whole focus newest first ("Focus 3 · Oct 18", up to three lines), and "All 12 notes on this focus →" at the foot, to the notes page. None yet: one faint line under the slip, "What you notice across passages rather than in one. Each is numbered on the focus: Focus 1, Focus 2…"
- **+ New note** turns the slip into an editor headed "Focus 4 · Oct 20 · new"; the number is handed out at the first save. Esc, or leaving it while still empty, puts the slip back.
- **Clicking a note** opens it as an editor in place, the caret at the end. One open at a time: opening another closes it. A note with text stays open when you click away, until Esc or another is opened (revisit if it bothers). Cleared, it's deleted, its number not reused; writing again makes a new note with the next number.
- No labels here: labelling is the reread's business.
- **The passage's note under another focus** (decided 2026-10-21): chosen from the list under the focus (`o`), it opens on the passage tab under a tinted slip naming that focus, with "← Back to…" (Esc); a new verse goes back. Under the current focus's note, "Also noted under …" names your other focuses with a note on the passage, each opening it there. See [foci-and-notes.md](foci-and-notes.md#notes-under-another-focus).
- **Phones**: the bottom sheet's handle shows the tab it's on: the reference and the note's first line, or "Focus" and the open note's first line, "3 notes on the whole focus", or "No notes on the focus yet". No `n` hint on the slip.

### Clause by clause

**A long passage can be read a clause at a time** (decided 2026-10-12, in every text, not only prose). Prototype: `prototype/reader/clauses.html`. Of its four looks (Spotlight dimming the rest, Lines setting a clause to a line, Magnify shrinking the rest, Marker highlighting) **Marker with Spotlight's dimming** was chosen: the current clause on a soft highlight, the rest of the passage dimmed in place, nothing reflowed.

- Splitting is done in the browser (`lib/clauses.js`) and only for reading: notes, keeps, history, the reference and `n of N` stay with the whole passage.
- **Off by default.** `;` (or the ; button after ¶) turns it on, and only that turns it on: clicking the text does not, since that surprised. It then stays on from passage to passage and chapter to chapter until turned off or the reader is left (sessionStorage, cleared by any page that isn't the reader).
- While on, the arrows (and `j`/`k`, swipe) step a clause at a time and carry on into the next passage; stepping back lands on the previous passage's last clause. `J`/`K` skip a whole passage. Clicking a clause moves there. A held key steps once (auto-repeat ignored), since a quick keyboard repeat skipped clauses on a single press; holding shouldn't speed through the reading.
- Breaks at `.` `?` `!` (a verse can hold several sentences, as Jonah 4:2 does; not after an abbreviation or an initial, though "I." still ends one), at `,` `;` `:` (each needing a space after, so 1,000 and 3:16 hold), after `—`, and around `( )` (off by default). A lone word joins the next clause; two words stand alone ("no invention, no hope"), since splitting too often beats too seldom.
- A pip per clause after the ; shows where you are and opens **Break at**, where each mark can be turned off. That choice is kept in the browser (localStorage), not on the server.

## Text alignment

Left-aligned (ragged right), not centered, and flush with the focus. The text keeps a ~34em measure at every width (revised 2026-10-05). Type size steps down for longer units (long sentences of prose). Demo of long prose: open `prototype/index.html?text=prose`.

## Navigation

**Minimal** (decided 2026-10-04).

**One rail on every signed-in page** (decided 2026-10-12, replacing the library pages' top bar and the "← Back to reading" chips on Kept, the notes page and Invitations). Before, there were three kinds of chrome: a top bar on library pages, the reader's rail with its ⋯ at the bottom left (hard to find), and pages with only a back chip. Prototyped in `prototype/nav/` (since removed): A, the rail everywhere; A2, A with labels; B, one top bar everywhere, faded in the reader. **A2** was chosen. B's bar put two lines of chrome over the passage again; a fourth option, keeping the split and fixing its seams, was held in reserve.

- The rail (`shared/_rail`) runs down the left: Your focuses (home) and **Notes on this focus** (with its count; marked current on the current focus's notes page), then Library, Recent places, Search, **Random**, Kept; off the reader, **Continue reading** sits below the rest, so the icons above keep their places on every page. With no current focus, Notes on this focus leaves its slot empty for the same reason.
- **Labels on hover**: pointing at one of its icons (or tabbing into it) widens it over the page at once, each icon's name and key beside it, so the icons can be learned without tooltips (there are none). Its 52px column stays put, so nothing beneath moves; an open popover folds the labels away so it sits beside its icon. Once open they stay while the pointer is anywhere on the rail, so crossing the gaps between icons doesn't close them. Only an icon opens them (decided 2026-10-27; before, the whole rail did): on a tablet a swipe that began on the rail's blank stretch or near the screen's left edge counted as pointing at it and widened it mid-scroll. On touch they close when the finger lifts.
- The labels alone set the open rail's width (~180px). Continue reading names where it goes on a second line that adds no width, shortened like the note panel's reference: the work title goes first, then the section name ellipsizes; the number always stays. Random's second line names its default ("in Old Testament"), which may widen the rail a little, up to 150px before it ellipsizes.
- **Search** opens on a place, named on its second line like Random's: the work, in the reader; the page's own place on a work, collection or shelf page; elsewhere the place last searched (see [search](search.md#scope-and-entry-points)).
- **Random** (`shared/_random_pop`) opens a popover headed "Pick randomly from": the places alone, the default first and in bold, then the other enclosing scopes and, under "Your shelves", the shelves holding the page's work or collection (see [random](random.md)). The heading isn't "Roll in": it fits the die icon, but you don't "roll in" Isaiah.
- **You, at the foot of the rail**: your initial in a ring and, as its label, your name (the email address up to the @; users have no name of their own). Its popover, opening upward, holds light/dark, Invitations for admins, and Sign out (`shared/_me_items`).
- **In the reader**, Library's slot is **Go up** (a call to action; "Where you are" was the wrong name): a popover with the library trail, indented a level per step, and the chapters either side. The work crumb is skipped when the chapter name already starts with it ("Isaiah 40"). Elsewhere the slot is a plain link to the library.
- **Above a page's title**, quietly, the way up (`page_head`): its crumbs but the last (the title names the page), e.g. Library › Sacred Texts › Old Testament over "Isaiah". Edition and author appear only as tooltips. A page's actions sit at the right of that line (Kept's order, the notes page's export).
- **No ⋯ on the desktop rail** (decided 2026-10-25). Until then it sat at the top and held Notes on this focus, Random, Your Texts, light/dark, Invitations and Sign out: a junk drawer, and its label, "Menu", read as the title of the rail rather than something to click, hiding the rest behind it. Each found a home instead: Notes and Random got icons, the account items went to the foot, and Your Texts is left to its row in the Library. Prototyped as `prototype/nav/rail.html` (not kept).
- **On phones** the rail collapses to a single ⋯ at the top right on every page, whose menu (`shared/_menu_items`) takes in everything (and, in the reader, the trail at its top), under two quiet headings: *Study* (the rail's tools, and Your Texts) and your name (the account's). Random there keeps its ▾ for the other places, listed by name alone, since a popover over the menu doesn't work on a phone.

Not given the rail: the focus form (new, edit), sign-in and sign-up, which are single-purpose pages with their own way out.
