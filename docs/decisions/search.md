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

- `/search`, whole library by default (`?work=` / `?collection=` to narrow). The search page always offers the enclosing scopes as chips (the whole library alone when that's where it is), then a dashed **Somewhere else…** (see below).
- The library, collection and work pages each have a search box scoped to themselves. The boxes read "Find words in Poetry" (not "Search Poetry", which suggested finding a work by title), and the search page's hint says titles aren't searched (2026-10-05).
- The rail has Search, and `/` opens it (or focuses the box). **It opens on a place, not the whole library** (decided 2026-10-25): the whole library was never what was wanted, so searching meant going to the library and down to the collection or work first. Now, on a page of a place of its own (the reader, a work, collection, shelf or Your Texts), Search opens there: in the reader, the *work* being read (not the innermost collection Random rolls in; searching is mostly "where in this book…", and widening is a chip away). Anywhere else it opens on the last place searched, then the work of the latest of Recent places, and the whole library only with neither. Its label names where on a second line, like Random's ("in Isaiah", "in the library"); the phone menu's Search names it at the right. Taking the icon off the rail was weighed, leaning on the pages' own boxes, but that left no way to search from the reader without going up. Only these links choose a place: `/search` with none is still the whole library, so a link always says where it searches.
- **The places searched lately** (the last three a search was run in, newest first) are kept in the session cookie, so per device; one gone since, or no longer the user's, drops out.
- **Somewhere else…** opens a picker over the chips: a filter by title, and before anything is typed the user's shelves, Your Texts, the places searched lately and the whole library, leaving out any already a chip. Typing lists the collections and then the works whose titles hold it (accents ignored), each with its trail ("Sacred Texts › Bible"), and the edition; ↑↓ and Enter pick one, Escape closes. Choosing one runs the same words there. The titles are all in the page (there are ~120), filtered in the browser (`scope_picker_controller.js`). A place picker in the box's own row ("in Isaiah ▾", no chips) was prototyped too (`prototype/search/scope.html`) and liked, but didn't fit a phone's width beside the box and the button.
- User texts are included for their owner (see [user-texts.md](user-texts.md)).
- A shelf has its own box and scope (`?shelf=`, 2026-10-12), searching every work on it and under its collections (see [shelves.md](shelves.md)).

## Coming back

**Search remembers the last search for the sitting** (decided 2026-10-22). Opening a result to read or note it, then wanting the rest of the results, used to mean the browser's Back, which stops short once the reader has moved on to another chapter, and isn't there at all in a home-screen app. Now the results page you were on, and the result you opened from it (`#r-<unit id>`), are kept in sessionStorage; going back lands on the same query and page, scrolled to that result, set on a card tinted like the reader's band back to it (edge to edge on phones). A new search replaces it; a new tab starts empty. At first it was marked with a faint rule at its left, which was easily missed; an accent rule, a wash that faded to it, and a "Last opened" tag by the reference were tried with the card (`prototype/search/returned.html`), and the card was kept for matching the band (2026-10-24).

**The way back is a band in the reader, not the Search button** (2026-10-24). At first the rail's and menu's Search went back to the last search, but nothing said so, and wanting a fresh search meant clearing it. Now Search (rail, menu, `/`) always opens an empty search page, which offers the last one in a line under the box ("Your last search, *light*: back to the results"). Opening a result puts up a tinted band over the focus, "← Back to results for *light*", with × to put it away. It stays while you read on, across verses and chapters, and goes when you leave the reader (any other page, the search page included) or by ×; opening a result again puts it back. The band takes room of its own, pushing the focus down; put away, it closes up and the focus rises to its usual place (at first the focus kept its place under it, which left a gap when it went). A quiet text line, an accent link and a chip were tried (`prototype/search/back.html`); the quiet ones were missed, and the band reads as a way back without crowding the column. The magnifier tried with it was dropped for the arrow.

- **Both name the query in quotation marks, unless it has some of its own** (2026-10-28): a phrase search, `"search query"`, read `""search query""`, so a query with a `"` in it is shown as typed (`lastSearch.name`).

Left out for now: matching titles and references, and searching notes.
