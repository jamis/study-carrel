# History and Keep

## History

**Global per user, not per focus** (decided 2026-10-04), so a trail survives starting a new focus.

- `visits` table, one row per `(user, unit)`, newest first, capped at 50, written by `PositionsController#update`.
- Stepping to a neighboring verse moves the latest entry along instead of adding one, so the list holds places, not every verse read.
- UI: a clock icon in the rail opens a dropdown of the last 8 places before the current one (reference, snippet, age, a dot if the verse has a note in the current focus).
- On phones it folds into the ⋯ menu as "Recent places" to save room: below 720px on library pages, below 900px on the reader.
- `h` opens it, Up/Down move, Enter goes.

## Keep

**Keep** (decided 2026-10-04) is the bookmark: a per-user mark on a passage, independent of any focus, for something profound you stumble on and want to return to.

- `keeps` table, one row per `(user, unit)`, with an optional plain-text remark (200 characters).
- UI: a bookmark ribbon just left of the reference line above the passage (revised the same day from a ribbon hanging off the focus band, which felt disconnected from the text). The whole reference row sticks below the focus while a long passage scrolls.
- Quiet outline when idle; filled accent when kept.
- Tap to keep (a brief "Kept · Add a remark · Undo" line follows); tap a kept ribbon for a popover with the remark, Release and "See all kept"; `b` does the same as a tap.
- Kept verses are marked in the verse grid and in the history list.
- The **Kept page** (`/kept`, from the rail) lists passages newest first or in reading order, with the remark, and "Start a focus from this" opens the new-focus form with the passage shown and begins reading there.
- The Kept page is laid out like a focus's notes page (decided 2026-10-12): "Kept" with the ribbon stands where the focus would, the passages run down the left, and each one's remark and its actions (Start a focus, Release) sit level with it on a sheet at right. The whole passage cell links into reading. A keep with no remark shows only its actions. On phones the remark and actions are a slip under the passage.
- Not yet: a Random scope over kept passages.
- Keeps on a revised or deleted user text: see Detached notes in [user-texts.md](user-texts.md).
