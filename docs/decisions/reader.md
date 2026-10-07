# The reader: layout, design and navigation

## Platform and mobile

A web application, usable from laptop and phone, with the same functionality on both: one responsive design, no cut-down phone version. Desktop shows text and notes side by side; a phone shows text with a bottom sheet for notes.

## Design reference

**Committed** (2026-10-02): `prototype/index.html` is the reference for look and feel: lectio-only, compact sticky focus, left-aligned text with length-adaptive sizing.

**Reader revised** (2026-10-05) after five layouts were tried in `prototype/reader/` (A desk, B open book, C single column, D rail and ruler, E rail and steps): **E** was chosen, `prototype/reader/e.html` (D's rail and docked note with A's `‹ 3 of 31 ›`; D's hairline ruler was dropped).

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

**Library, collection, work, search and kept pages** share a top bar (`shared/_header`), with Random scoped to the collection or work and "Continue reading" in the menu:

- Collapsible breadcrumbs (Library › collections › work › chapter, no "Study Carrel" brand) and one ⋯ menu.
- The first and last crumbs always show; middle ones drop out nearest the root first, leaving a "…".
- The work crumb is skipped when the chapter name already starts with it ("Isaiah 40").
- Edition and author appear only as tooltips.

**The reader has no top bar** (decided 2026-10-05; it made the page feel cluttered):

- A thin icon rail down the left (`readings/_rail`) holds *Where you are* (a popover with the library trail, indented a level per step, and the chapters either side), Recent places, Search, Kept, and the ⋯ menu at the bottom (All notes, All focuses, Random, light/dark, Invitations for admins, Sign out).
- On phones the rail collapses to a single ⋯ at the top right whose menu takes in the trail and everything else.

Both menus render `shared/_menu_items`. The library pages keep their top bar for now.
