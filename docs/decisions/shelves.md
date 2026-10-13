# Shelves

**A user can group works and collections into shelves of their own** (decided and built 2026-10-12), to roll Random and search in: "Poets I love" (Frost, Dickinson, *Walden*), or "Latter-day Saint scripture" (the Bible and the Book of Mormon). Prototype: `prototype/shelves.html`. Code: `Shelf`, `ShelfItem`, `ShelvesController`, `ShelfItemsController`.

## What a shelf is

- A name, an optional line about it, and **works and whole collections**. A shelf holds works, not passages; the curated lists in [discovery](discovery.md) are choices of passages, and stay a separate idea.
- **A collection brings everything nested under it, now and later**, so a shelf never needs tending as the corpus grows.
- **Nothing is on a shelf twice.** Something under a collection on the shelf is on it already, "through" that collection. Putting a collection on takes in anything already there from under it (the picker warns: "Would take in Emily Dickinson and Robert Frost, already on it"), and the editor's save leaves such things out.
- Members are listed in library order, collections first; there's no manual ordering.
- Shelves don't nest, and they aren't part of the library's `Collection` tree, which stays shared and admin-built.
- Called a **shelf**, after the carrel metaphor, so it doesn't collide with collections.

## Privacy

Like user texts, **private to their owner**: found only through `user.shelves`, with a 404 for anyone else (show, edit, Random, search, adding). Slugs get a random suffix (`poets-i-love-k3f9`). A shelf's works are always resolved through `Work.visible_to(owner)`, so a shelf can never reach another user's text. A user's own texts can go on their shelves one by one; Your Texts as a whole can't.

## Two ways to fill one

The prototype's options 1 and 2, together:

1. **Put on a shelf…**, a plain link at the end of the line under a work's or collection's title (where Revise sits on a user's text). It opens a checklist of the user's shelves, ticked when the thing is on it, ticked and greyed when it's on it through a collection; ticking saves at once. "New shelf…" makes one with the thing on it. On phones it's a bottom sheet.
2. **The shelf editor** (New shelf, Edit shelf): the name and a line, "On this shelf" as removable chips, then the library tree with a box beside every collection and work. Ticking a collection greys everything under it ("through Poetry"); a collection with something ticked under it shows partly ticked. A find box narrows the tree by work, collection or author. Saved with Save / Make the shelf.

Deleting a shelf (from the editor, with a confirmation) takes nothing else: works stay in the library, and nothing a note or keep hangs off is touched. A user text deleted from the library comes off every shelf (the foreign key cascades).

## Where shelves appear

- **Library:** a "Your shelves" row under Your Texts, each shelf with what's on it, and New shelf.
- **The shelf page** (`/shelves/:slug`): like a collection page, with "Your shelf · 12 works in all · only you can see it · Edit shelf", its own search box, and its members.
- **Random:** a shelf is a scope of its own (`/shelves/:slug/random`), balanced evenly among what's on it, then inside a collection as everywhere else (see [random](random.md)). The ⋯ menu's ▾ lists, under "Your shelves", the shelves holding the page's work or collection (every shelf, from the library).
- **Search:** `?shelf=slug` searches every work on the shelf; the search page offers the shelf and the whole library as chips (see [search](search.md)).

## Open

- Whether the reader's Random should keep a shelf's scope after rolling from it (today it falls back to the innermost collection, with the shelf a step away under ▾).
- "Put on a shelf…" in the reader's ⋯ menu.
- Starter shelves an admin defines and a user copies (a link to discovery's curated lists).
