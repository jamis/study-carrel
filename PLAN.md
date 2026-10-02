# Study Carrel: Plan to v1

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
16. ✅ **More texts.** Add 2-3 more: one poetry collection and one prose work. Prose will test chunking and long-paragraph sizing. **Choose the texts at this step, not before.** **Done:** the whole KJV Old Testament (39 books, cross-checked against two other sources), Emily Dickinson's poems (442, a stanza per unit) and Thoreau's *Walden* (18 chapters, a paragraph per unit). Build scripts are in `script/texts/`. Left as candidates: (see `collections.yml` and the `collection:`/`position:` headers; the loader is non-destructive and uses bulk upserts).
17. ✅ **Chapter navigation.** First real browsing UI: collection pages (e.g. an "Old Testament" page listing its books), a book page with a chapter grid, Next/Previous that continues into the next chapter and book, and a compact verse strip for long chapters (Psalm 119 has 176 verses).
18. ✅ **PWA basics.** Manifest, icon, installable on a phone.
19. ✅ **Deploy.** Live at https://studycarrel.jamisbuck.org on a DigitalOcean droplet (Ubuntu 24.04, 512 MB), no Docker: Capistrano deploys to a `deploy` user (`bundle exec cap production deploy`, rollback with `deploy:rollback`), Puma runs under systemd, Caddy does HTTPS. Setup is in `SERVER.md`; config in `config/deploy.rb` and `config/server/`. Backups: Litestream streams the primary database to a private Backblaze B2 bucket, with a 30-day lifecycle rule (restore tested). The repo is public (`jamis/study-carrel`, MIT). Gotchas on this small droplet: bundle with one job, and 1 GB of swap.
19b. ✅ **Random.** "Random" on the library, each collection and each work (and in the reader's menu) drops you into a random unit in lectio mode: uniform within a work or collection; the library picks a collection first. It moves your position like normal reading.
20. ✅ **Polish.** An accessibility pass (lang, focus rings, live verse, aria state), feedback when a note fails to save, diagonal swipes ignored, a phone pass (two-row nav with a ⋯ menu, no zoomed-out page on long chapters, strip drags no longer turn the page), empty states (no texts loaded, empty library, "Add one" link on a focus with no description), edit-note (inline Lexxy form in a Turbo Frame; no "edited" marker), and a keyboard pass (Esc closes the focus dropdown and notes sheet, the verse strip is a single tab stop, a closed phone sheet is out of the tab order). Checked on a real iPhone: installs to the home screen and looks right.

**v1 is complete.**

## Later (wanted, not scheduled)

- **History.** Show where you've been recently (random hops make this matter) and jump straight back to any of those places. Likely a per-focus list of recently visited units, written when the position is saved.
- **New user signups.** Allow new users to sign up. Probably via a protected link (e.g. invitation only) at first, to prevent spam.
- **More works**. Religious texts, as well as more classics and poetry. Done: KJV New Testament, Book of Mormon. Candidates: Poe, Frost, Dhammapada, Tao Te Ching, Bhagavad Gita, Quran (Rodwell, traditional sura order restored), Marcus Aurelius.
- **Doctrine and Covenants and Pearl of Great Price.** Deferred: no clean public-domain text exists online. The Wikisource D&C is the modern copyrighted text. Options are OCR of the 1908 Deseret News D&C (archive.org `thedoctrineandco00smituoft`) cross-checked against two other pre-1923 scans, and the 1913 Pearl of Great Price on Wikisource. Label both as older public-domain editions; D&C 138 and the Official Declarations would be missing.
- **Random, extended.** An "Another" button inside the reader to roll again in the same scope; configurable weighting (uniform today).
- **Backups, extended.** A scheduled restore check, and a resize to 1 GB if the 512 MB droplet feels tight.

## Notes

- Suggested first batch: steps 1-3 together, then check in after step 6.
- Deferred from v1 (see `DECISIONS.md`): full-chapter reading view, verse ranges, word-level highlights, cross-reference links, "current answer" history, Margin Map / Synthesis, offline support, search.
