# The library: structure, loading and bundled texts

## Structure

**Collection > Work > Section > Unit** (decided 2026-10-02). A Bible book is a Work, a chapter a Section, a verse a Unit. The unit model is generic, covering verses, poetry stanzas, and prose sentences.

- Collections are a real table (name, slug, position, description, parent) so they can have their own pages, e.g. "Old Testament".
- **Collections nest** to any depth (decided 2026-10-02) via `parent_id`: e.g. Sacred Texts > Book of Mormon > 1 Nephi (a Work). A collection's Random and work count include everything nested under it; the library lists top-level collections only.
- Works have a `position` for canonical order.
- Loading texts updates in place and **never deletes**, so notes survive reloads. The one exception: a sentence left over after prose is re-split, if nothing hangs off it (see [prose-by-sentence.md](prose-by-sentence.md)).

## Texts

The app ships with a **bundled corpus**. No import or external API for bundled texts. (Users can add their own private texts; see [user-texts.md](user-texts.md).) Rebuild with the scripts in `script/texts/`.

## Authors

**Optional `works.author` (full name) and `works.author_short`** (decided 2026-10-04), set by `author:` / `author_short:` in the text files; blank for scripture and anything without a known author. Translators stay in `edition`.

- Library pages show the full name beside the work.
- Lectio shows the short name in the small slot before the edition ("Frost · Collected Poems (1930)"), hidden on phones.
- Nothing is shown when the title already is the author (Emily Dickinson).

## Bundled texts

Single-source texts rely on Gutenberg's proofreading.

- **KJV Old Testament**: Gutenberg base, cross-checked against two other sources; 115 verses taken from the other sources where the base differed.
- **KJV New Testament**: built the same way, 260 chapters.
- **Book of Mormon**: Gutenberg #17, older public-domain text, 6,604 verses. Labelled "Public-domain text", not the Church's current copyrighted edition.
- **World Scripture**: Dhammapada (Müller); Tao Te Ching (Legge); Bhagavad Gita (Arnold's *Song Celestial*); Quran (Rodwell, in the traditional sura order, whose verse numbers can drift by one from the standard in about two dozen suras).
- **Marcus Aurelius: Meditations**: Casaubon's 1634 translation.
- **Robert Frost**: the 1930 Collected Poems, public domain from 2026.
- **Edgar Allan Poe**: 1900 Bell edition.
- **Emily Dickinson**: five works, stanza per unit. *Poems* First, Second and Third Series (442 poems, Gutenberg); *The Single Hound*, 1914 (142 poems) and *Further Poems*, 1929 (181 poems), both from proofread Wikisource transcriptions because Gutenberg lacks them. Rebuilt with `script/texts/build_dickinson_later.py`.
- **Thoreau: Walden**: Gutenberg.
- **Prose batch 2** (2026-10-04, `script/texts/build_prose.py`, all Gutenberg, single-source):
  - **Pascal, *Pensées*** (#18269): 923 numbered thoughts in 14 sections. The file doesn't name the translator, but it is W. F. Trotter's, so the edition reads "Trotter translation" with no year. T. S. Eliot's introduction and the editor's notes are left out.
  - **Emerson, *Essays*, First Series** (#2944, 12 essays) and **Second Series** (#2945, 9 essays), with the epigraph verse left out.
  - **Montaigne, *Essays*** (#3600): Cotton's translation as edited by Hazlitt, 1877; 107 chapters, sections labelled "II.3 …" by book and chapter. The Gutenberg volunteers' bracketed notes signed "D.W." are stripped.

The Prose collection is split into sentences when built; see [prose-by-sentence.md](prose-by-sentence.md).
