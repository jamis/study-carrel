# Study App: Plan to v1

Last updated: 2026-10-02
See `DECISIONS.md` for decisions and `prototype/index.html` for the reference design.

## Stack

**Rails + Hotwire + SQLite.** (Rails confirmed by the user.)

- Small, single-user, server-rendered app. Rails 8's built-in auth and PWA support cover most needs.
- Notes editor: try **Lexxy** (current state unverified). Step 9 is a spike. Fallback: Action Text/Trix.
- The whole chapter loads on the page and a small Stimulus controller switches verses, so there is no network round trip per verse.

## Steps

Each step is small, can be checked on its own, and leaves the app working.

### A. Foundation
1. ✅ **Scaffold.** New Rails app with SQLite and Hotwire, an empty home page, and a git repo. Keep the prototype in `prototype/` as the reference.
2. ✅ **Port the look.** Move the prototype's CSS and layout into the Rails layout and a static mock view. It should look identical to the prototype, with no data yet.
3. ✅ **Auth.** One user with a login page, using Rails' built-in generator. Everything else sits behind it.

### B. Texts
4. ✅ **Text models.** Work > Section > Unit (number, text), plus a seed loader that reads plain-text files.
5. ✅ **Load Isaiah 40.** Put the KJV text in a data file and seed it. Verify it against a trusted source (the prototype copy was typed from memory).
6. ✅ **Read a chapter.** The reading view renders real units in lectio mode: focus band, verse, faded neighbors, verse strip. Navigation via a Stimulus controller (buttons, arrow keys, swipe). The URL reflects the verse.

> Check-in after step 6: first point where real text can be read in the real app.

### C. Focus
7. ✅ **Focus model.** One current focus, shown in the sticky band. Minimal create form, plus a first-run state when none exists.
8. ✅ **Focus details.** Dropdown with description and edit, plus archive and a simple past-foci list.

### D. Notes
9. ✅ **Editor spike.** Try Lexxy in an isolated page and confirm it works on a phone. Decide Lexxy or Trix. **Result: Lexxy 1.0.0 passes; use it.** Bold and Markdown lists worked on desktop; typing, bold and the collapsing toolbar worked in a 390px mobile emulation (not a real phone, so recheck at step 20). Theming is via `--lexxy-*` CSS variables.
10. ✅ **Notes, plain.** Create and delete notes attached to the current unit, shown in the side panel, with the mobile bottom sheet. Plain text only, to prove the data flow.
11. ✅ **Rich notes.** Swap in the chosen editor, with the compact field and an expand control.
12. ✅ **Verse-strip markers and counts.** Show which verses have notes.
13. ✅ **All-notes view.** All notes in reading order, with a jump back to the verse.
14. ✅ **Markdown export.** Copy or download as Markdown.

### E. Finish
15. ✅ **Remember position.** Save the current verse per focus, so the app reopens where you left off.
16. **More texts.** Add 2-3 more: one poetry collection and one prose work. Prose will test chunking and long-paragraph sizing. **Choose the texts at this step, not before.** Candidates include the whole KJV Old Testament (see `collections.yml` and the `collection:`/`position:` headers; the loader is non-destructive and uses bulk upserts).
17. **Chapter navigation.** First real browsing UI: collection pages (e.g. an "Old Testament" page listing its books), a book page with a chapter grid, Next/Previous that continues into the next chapter and book, and a compact verse strip for long chapters (Psalm 119 has 176 verses).
18. **PWA basics.** Manifest, icon, installable on a phone.
19. **Deploy.** Put it somewhere reachable from a phone, with backups of the SQLite file. **Hosting is undecided and must not block earlier steps.**
20. **Polish.** Empty states, edit-note, keyboard and accessibility pass, real-device test.

## Notes

- Suggested first batch: steps 1-3 together, then check in after step 6.
- Deferred from v1 (see `DECISIONS.md`): full-chapter reading view, verse ranges, word-level highlights, cross-reference links, "current answer" history, Margin Map / Synthesis, offline support, search.
