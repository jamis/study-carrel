# Search

**Library search** (decided 2026-10-05) over unit text with SQLite FTS5. Code: `LibrarySearch`.

## Index

`unit_search`, porter stemming, accents ignored: a copy of each unit's body keyed by unit id, refreshed by the loader per section. `bin/rails study_carrel:reindex` rebuilds it.

## Query syntax

Every word must appear. `"quotes"` make a phrase and a trailing `*` matches a word's beginning. Everything else is plain text, never FTS syntax.

Prose is matched **a sentence at a time** (decided 2026-10-06): every word must be in one sentence, so a result never opens on a sentence that doesn't match, even if words spread across a paragraph go unfound.

## Results

Results come in **reading order, not relevance**, 50 to a page, with highlighted excerpts and a per-work count list (folded away above 12 works) whose entries narrow the search to that work.

## Scope and entry points

- `/search`, whole library by default (`?work=` / `?collection=` to narrow). The search page offers the enclosing scopes as chips.
- The library, collection and work pages each have a search box scoped to themselves. The boxes read "Find words in Poetry" (not "Search Poetry", which suggested finding a work by title), and the search page's hint says titles aren't searched (2026-10-05).
- The ⋯ menu has Search, and `/` opens it (or focuses the box).
- User texts are included for their owner (see [user-texts.md](user-texts.md)).

Left out for now: matching titles and references, and searching notes.
