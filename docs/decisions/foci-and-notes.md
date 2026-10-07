# Foci and notes

## Foci

One focus at a time. No parallel foci in v1. The focus is the app's current state: no switcher or lenses. Home is "continue where you left off". Past foci live in a simple archive list. Deleting a focus is not supported yet (detaching its notes, as for a deleted text, may be the way; see [user-texts.md](user-texts.md)).

## Focus presentation

The focus is the hero of the screen, but compact and quiet:

- A small muted label and a ~20px italic title in soft ink, accent only on hover (revised 2026-10-04: the filled pill and 32px accent title read as a shout).
- At the top of the reading column (since 2026-10-05; it was a band under the nav), sticky so it stays visible while scrolling.
- Left-aligned (decided 2026-10-03) so a short focus doesn't get lost in the middle; it lines up with the body text.
- The description opens as a dropdown.

Prototype feedback: a thin bar felt lost; a large hero banner was too big.

## Notes

**One note per verse per focus** (decided 2026-10-03), enforced by a unique index on `(focus_id, unit_id)`.

- An always-open Lexxy editor, docked as a full-height page down the right (a bottom sheet on phones, whose handle shows the note's first line).
- **Autosaves** as you type (and on leaving the verse); clearing it deletes the note. There is no add/expand step.
- Toolbar shrunk (icons about 35% smaller) and moved below the text; on desktop it shows only while the editor has focus (decided 2026-10-05).

Trade-off accepted: no per-note timeline of when each thought arrived (only the last-updated time), and last save wins across tabs.

Notes that lose their unit (a revised or deleted user text) become detached notes; see [user-texts.md](user-texts.md).
