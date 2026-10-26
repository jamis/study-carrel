# History and Keep

## History

**Global per user, not per focus** (decided 2026-10-04), so a trail survives starting a new focus.

- `visits` table, one row per `(user, unit)`, newest first, capped at 50, written by `PositionsController#update`.
- Stepping to a neighboring verse moves the latest entry along instead of adding one, so the list holds places, not every verse read.
- UI: a clock icon in the rail opens a dropdown of the last 8 places, newest first, including the one on screen, in the reader and off it alike (decided 2026-10-25): reference, snippet, age, a dot if the verse has a note in the current focus.
- On phones it folds into the ⋯ menu as "Recent places" to save room: below 720px on library pages, below 900px on the reader.
- `h` opens it, Up/Down move, Enter goes.

## Keep

**Keep** (decided 2026-10-04) is the bookmark: a per-user mark on a passage, independent of any focus, for something profound you stumble on and want to return to.

**A keep needn't have a passage** (decided 2026-10-25): an **idea** is a keep with only its remark, for something you'd like to study someday that came from outside the corpus, a question heard in a sermon or a book read elsewhere ("What am I doing that I should stop doing?", "Holiness"). There is no real difference between the two except that a kept passage is linked to one in the library, so they are one kind of thing, in one table, on one page. Ideas were weighed for the focuses page (as focuses not yet begun) and turned down: that page is for what you're studying or might return to, and a pile of maybes would litter it.

- `keeps` table, one row per `(user, unit)`, with an optional plain-text remark (200 characters). An idea has no unit (`unit_id` null, any number per user) and must have a remark; 200 characters is plenty for the question or topic and a line of where to begin. Everything that looks keeps up by passage (the ribbon, the verse grid, history, loading and revising texts) passes ideas by without a change; anything new about kept passages must leave them out on purpose (e.g. Random over kept passages).
- UI: a bookmark ribbon just left of the reference line above the passage (revised the same day from a ribbon hanging off the focus band, which felt disconnected from the text). The whole reference row sticks below the focus while a long passage scrolls.
- Quiet outline when idle; filled accent when kept.
- Tap to keep (a brief "Kept · Add a remark · Undo" line follows); tap a kept ribbon for a popover with the remark, Remove and "See all kept"; `b` does the same as a tap.
- The remark is saved with Save, Enter or a tap elsewhere, and the toast comes back with it in italics ("Kept "…" Edit"), so you can see what was kept (decided 2026-10-25, after a remark that saved on blur with nothing to show for it felt as if it hadn't saved). Esc puts the popover away and leaves the remark as it was. In the popover, Save is the one filled button; Remove and See all kept are quiet links beside it, so the way out isn't the way to lose the keep. Pointing at a kept ribbon shows its remark. Not a persistent remark by the reference, which would crowd the passage; a mark inside the ribbon for "has a remark" was tried in the prototype and left out.
- Kept verses are marked in the verse grid and in the history list.
- The **Kept page** (`/kept`, from the rail) is **one column, one stream, newest first** (decided 2026-10-25, variant A of three prototyped), like a commonplace book, where copied-out passages and your own thoughts run together in the order they came. The same on phone and desktop.
  - "Kept" with the ribbon heads it, and one quiet line under it says what it holds: passages kept with the ribbon (and `b`), and ideas you'd like to study someday, any of which can start a focus.
  - A **"+ Jot an idea" slip** (`n`) heads the stream and opens to a plain field in place: Enter or a tap away keeps it, Shift+Enter is a new line, Esc leaves it; the characters left show only in the last 40.
  - Quiet month heads ("October 2026") mark time down the stream, and each entry its day.
  - **A kept passage**: its reference (linked into reading) and the passage in the text's type, clamped with "Show full passage" when long, then its remark under it in italics.
  - **An idea**: only your words, a little larger, upright, in full ink, told apart by having no passage; after a line break the rest is set smaller in italics (where to begin, where you heard it). Clicking it edits it in place, with the slip's keys.
  - **A remark set aside** when its passage changed or went (see [user-texts.md](user-texts.md)) takes its place in the stream by when it was kept (`noted_at`), as a kept passage would show, from its frozen citation and passage (not linked, since the passage is gone), with why it was set aside, and Discard (which asks, as it can't be undone).
  - No reading order: it meant little once ideas, which have no place in the text, run among the passages.
  - It replaced a sheet laid out as a focus's notes page was before the reread (decided 2026-10-12 to 2026-10-25): passages down the left, each remark level with it on a sheet at right, Newest and Reading order chips above. An idea there would have been a remark beside an empty cell. Also prototyped: ideas as slips of paper tucked into the stream (B), and ideas gathered at the head with passages below (C, two lists again).
- Every entry's actions are quiet links at its foot, "Start a focus · Remove", in the faint small sans of a focus card's Edit · Archive · Delete, and they show only when you point at the entry (or tab into it; always on touch) (decided 2026-10-25, the fourth of four ways prototyped). They were two bordered chips on every row, "Start a focus from this" and "Release", heavier than things done this rarely; "Release" was the wrong verb, and it is "Remove" in the reader's popover too. Remove doesn't ask: the entry goes and a toast says "Removed Isaiah 40:3 from Kept · Undo" (or the idea's first line), which puts it back with its remark and its place in the stream; the page keeps its scroll through both.
- "Start a focus" on a passage opens the new-focus form with the passage shown and begins reading there; on an idea, it fills the form with its first line as the title and the rest as the description, and the idea goes once the focus is made, so it isn't in two places. No Undo: its words are in the focus now, and the form says beforehand that it will leave Kept. It stays though it hasn't been tried in practice yet; as a quiet link it costs little, and it can go if it goes unused.
- Not yet: a Random scope over kept passages.
- Keeps on a revised or deleted user text: see Detached notes in [user-texts.md](user-texts.md).
