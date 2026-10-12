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

## Text alignment

Left-aligned (ragged right), not centered, and flush with the focus. The text keeps a ~34em measure at every width (revised 2026-10-05). Type size steps down for longer units (long sentences of prose). Demo of long prose: open `prototype/index.html?text=prose`.

## Navigation

**Minimal** (decided 2026-10-04).

**One rail on every signed-in page** (decided 2026-10-12, replacing the library pages' top bar and the "← Back to reading" chips on Kept, All notes and Invitations). Before, there were three kinds of chrome: a top bar on library pages, the reader's rail with its ⋯ at the bottom left (hard to find), and pages with only a back chip. Prototyped in `prototype/nav/` (since removed): A, the rail everywhere; A2, A with labels; B, one top bar everywhere, faded in the reader. **A2** was chosen. B's bar put two lines of chrome over the passage again; a fourth option, keeping the split and fixing its seams, was held in reserve.

- The rail (`shared/_rail`) runs down the left: the ⋯ menu at the **top**, then Your focuses (home), Library, Recent places, Search, Kept; off the reader, **Continue reading** sits below the rest, so the icons above keep their places on every page.
- **Labels on hover**: pointing at the rail (or tabbing into it) widens it over the page at once, each icon's name and key beside it, so the icons can be learned without tooltips (there are none). Its 52px column stays put, so nothing beneath moves; an open popover folds the labels away so it sits beside its icon.
- The labels alone set the open rail's width (~180px). Continue reading names where it goes on a second line that adds no width, shortened like the note panel's reference: the work title goes first, then the section name ellipsizes; the number always stays.
- **In the reader**, Library's slot is **Go up** (a call to action; "Where you are" was the wrong name): a popover with the library trail, indented a level per step, and the chapters either side. The work crumb is skipped when the chapter name already starts with it ("Isaiah 40"). Elsewhere the slot is a plain link to the library.
- **Above a page's title**, quietly, the way up (`page_head`): its crumbs but the last (the title names the page), e.g. Library › Sacred Texts › Old Testament over "Isaiah". Edition and author appear only as tooltips. A page's actions sit at the right of that line (Kept's order, All notes' export).
- The ⋯ menu (`shared/_menu_items`) holds the rest: All notes, Random (scoped to the collection or work), Your Texts, light/dark, Invitations for admins, Sign out.
- **On phones** the rail collapses to a single ⋯ at the top right on every page, whose menu takes in everything (and, in the reader, the trail at its top).

Not given the rail: the focus form (new, edit), sign-in and sign-up, which are single-purpose pages with their own way out.
