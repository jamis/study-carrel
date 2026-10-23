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
- A shelf has its own box and scope (`?shelf=`, 2026-10-12), searching every work on it and under its collections (see [shelves.md](shelves.md)).

## Coming back

**Search remembers the last search for the sitting** (decided 2026-10-22). Opening a result to read or note it, then wanting the rest of the results, used to mean the browser's Back, which stops short once the reader has moved on to another chapter, and isn't there at all in a home-screen app. Now the results page you were on, and the result you opened from it (`#r-<unit id>`), are kept in sessionStorage, and the rail's and menu's Search (and `/` off the search page) go back there: the same query and page, scrolled to that result, marked with a rule at its left. A new search replaces it; a new tab starts empty. A "← Back to results" slip in the reader was considered and left out, to keep the reader's column as it is.

Left out for now: matching titles and references, and searching notes.
