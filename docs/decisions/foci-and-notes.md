# Foci and notes

## Foci

One focus at a time. No parallel foci in v1. The focus is the app's current state: no switcher or lenses. Deleting a focus is not supported yet (detaching its notes, as for a deleted text, may be the way; see [user-texts.md](user-texts.md)).

## Home: the focuses page

**Signed in, `/` is the focuses page** (decided 2026-10-12; it used to drop you straight back into reading). Every focus you've had is an index card, so home shows what you've been asking, not only where you stopped. Design reference: `prototype/home/b.html`, chosen over a one-column list (A), a table of contents (C), a list-and-detail split (D) and four other card treatments (B1 to B4).

- The **current** card is double width with a ribbon: its dates, title, description, and a panel, "Continue at Isaiah 40:25 →" with the passage (or "Choose where to begin" before any reading), set apart so it's easy to find. Under it, quieter, "or find something new in the library →" (only once there's a place to continue from).
- **Past** cards show their dates, title, description (three lines at most) and "Make current".
- Every card ends with "12 notes in Ruth, Leviticus and Deuteronomy" (or "No notes yet"): the count and the works those notes are in, one line, so the works aren't mistaken for a citation. On the current card the count links to its notes; on past cards it's plain text, since a past focus's notes have no page of their own yet.
- No note is quoted on the cards (tried 2026-10-12): out of its passage a note lacks context, and the works line under it read as its source.
- A dashed "A new question" card starts a new focus. No totals or tallies across focuses.
- No focuses yet: you go to the new-focus form.
- "Continue reading" (the ⋯ menu, the "Back to reading" chips) is `/continue`, which resumes the current focus where it left off.
- After **starting** a focus you go straight to reading. After **editing** one or **making one current** you come back to the cards, as does Cancel on either form.
- The UI says "focuses", never "foci" (the code keeps `Focus`/`foci`).

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
