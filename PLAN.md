# Study Carrel: Plan

Last updated: 2026-10-07

The proof of concept is complete and deployed (https://studycarrel.jamisbuck.org; Capistrano, see `SERVER.md`). The original build steps are in `docs/plan-history.md`. Decisions are indexed in `DECISIONS.md`.

## Done since the proof of concept

History, Keep, Random extended, Library search, Prose by sentence, User texts (prose, then poetry and lyrics). Deploy notes still worth knowing: after deploying prose-by-sentence changes, run `study_carrel:load_texts`; after schema changes, `bin/rails db:migrate`.

## Later (wanted, not scheduled)

- **Accounts.** Invitations are done. Not yet: password reset, removing users or revoking access, emailing invitations.
- **More works.** Religious texts, as well as more classics and poetry. Candidates: Upanishads, Analects, Zhuangzi, Apocrypha, Augustine, Thomas à Kempis, Whitman, Blake, Shakespeare's sonnets.
- **Doctrine and Covenants and Pearl of Great Price.** Deferred: no clean public-domain text exists online. The Wikisource D&C is the modern copyrighted text. Options are OCR of the 1908 Deseret News D&C (archive.org `thedoctrineandco00smituoft`) cross-checked against two other pre-1923 scans, and the 1913 Pearl of Great Price on Wikisource. Label both as older public-domain editions; D&C 138 and the Official Declarations would be missing.
- **A limit on active focuses**, if accounts move to a subscription. Archiving (done) is how one would stay under it.
- **Deleting foci.** Not supported yet. Detaching its notes (as for a deleted text) may be the way to do it, so nothing written is lost by accident.
- **Random over kept passages.**
- **Search, extended.** Matching work/section titles and references ("Psalm 23"); searching your own notes.
- **Backups, extended.** A scheduled restore check, and a resize to 1 GB if the 512 MB droplet feels tight.
- **Encryption at rest** for notes, foci and user texts.

## Deferred from v1

Full-chapter reading view, verse ranges, word-level highlights, cross-reference links (`@Psalm 23:1`) with previews, a "current answer" document with version history, Margin Map / Synthesis, offline support.
