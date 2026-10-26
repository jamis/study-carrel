# Synthesis (exploratory)

> **Mostly tentative.** These are notes from a brainstorm (2026-10-13) to experiment with. The reread (labels, the scratchpad, the cloud) and free notes (notes on the focus as a whole) have since been decided and built: see [reread.md](reread.md) and [foci-and-notes.md](foci-and-notes.md), which are the rule for them. The rest (essays) isn't decided; don't build from it, or treat it as a rule, until it has been settled and moved into the index.

## The problem

Study Carrel serves three purposes: **discovery** (finding something to study; see [discovery.md](discovery.md)), **study** (the reader, which works well) and **synthesis** (distilling what the notes taught you), which barely exists. Today a focus's notes page lets you see your notes, but nothing helps you turn them into something.

Synthesis should work in a loop with discovery and study, under one focus or across several, and it should never be finished: you come back to it again and again and add to what you made before.

## The end goal: essays

The end of synthesis is **a piece of writing**, called an **essay**. Montaigne (in the corpus) named the form *essais*, "attempts": an essay doesn't claim to be finished. It's one attempt at a question, made on a particular day, which suits a phase that is never one-and-done. The word covers a talk or lesson for church, a blog post, or a private entry in a contemplation journal that nobody else reads. "Journal" might name the place where essays collect, in date order.

## The flow

1. **Study.** Notes on passages as now, plus **free notes** on the focus as a whole.
2. **Reread.** Notes one at a time, labelling them, with a scratchpad open beside them. No mode switch: "Reread these notes" on a focus's notes page or its card.
3. **Write.** Start an essay, with your notes, the scratchpad and the passages beside it as sources.
4. **Return.** The essay is dated and kept. Later you write another, perhaps on the same focus, perhaps with the earlier essay among its sources. Loose ends in an essay start new focuses.

Step 2 is optional: sometimes you'll go straight from notes to writing. The reread is for when you don't yet know what you think.

> **discovery** (keeps, random) → **focus** → **study** (notes) → **reread** (labels, scratchpad, free notes) → **essay** → loose ends → new **focus**

Every phase leaves something behind (keeps, notes, labels, essays) for the next round to draw on.

## Free notes

> Built 2026-10-13 as "notes on the focus as a whole"; [foci-and-notes.md](foci-and-notes.md) and [reread.md](reread.md) have the rules. They stay separate from detached notes (one has no passage, the other lost its passage), and they're written only in the reread for now, not from the reader. The notes below are the brainstorm.

A note that belongs to the focus but to no passage: what you noticed *across* passages ("Isaiah keeps pairing holiness with the poor") rather than what one passage said to you.

- Notes stay the one unit of writing. Free notes are labelled, listed and exported like passage notes.
- Written during the reread, or from the reader when an idea arrives mid-reading and isn't about the verse in front of you ("Note on the whole focus").
- Maybe they can cite a few passages, to stay grounded and give the reader backlinks. Allowed, not required.
- On the notes page they might head the page at full width (no passage at left), or be their own section: "Notes on the whole", then "Notes on passages".
- Schema: `notes.unit_id` becomes nullable. SQLite treats NULLs as distinct in a unique index, so `(focus_id, unit_id)` still holds one note per passage while a focus can have many free notes. `detached_notes` is already a focus note without a unit; worth deciding whether free notes stay separate from it or the two fold together.

## The reread

The reader's rhythm one level up: in the reader you read passages under the focus and write a note beside each; in the reread you read your notes (each with its passage) under the focus, one at a time (`‹ 3 of 12 ›`), and write beside them.

- **Left:** the note being reread, with its passage and its label chips.
- **Right:** the focus's scratchpad, docked where the note editor sits in the reader.
- New free notes can be written here.

## Labels

Labels on notes, like sorting index cards into piles as you reread, but many-to-many: a note can touch more than one theme. (Exclusive piles were considered; they force a useful "what is this mainly about?", but real notes touch several themes.)

- **Labels belong to the user, not the focus.** "attention" on a note under *What does it mean to be holy?* and on another under *What is Sabbath for?* is the same label, so a label connects focuses without any new concept.
- A label's page groups its notes **under their focus**, laid out like a notes page (focus, passage, note), so no note is seen without the question it answers.
- During the reread a quiet row of chips under the note, offering existing labels first. Renaming and merging easy. No "unlabelled" nagging: labels are for thinking, not filing.
- **A label's name is optional** (built 2026-10-19): finding the right word up front was the hard part, so notes can be grouped by recognising that they go together, and the group named later, if ever. An unnamed label goes by a letter ("group D"; until 2026-10-26 it was shown "like" one of its notes). See "Gathering what goes with a note" in [reread.md](reread.md).
- **The labels in use should be visible as you go**, so you see the shape of the synthesis forming: which labels hold the most notes and where in the focus they gather. Pointing at a label lights its notes. Built as a cloud and tallies on a panel over the scratchpad; see [reread.md](reread.md).
- The same labels on keeps, perhaps (IDEAS.md asks for tags on kept passages), rather than building them twice.
- A written statement per label ("what this pile says") was considered and dropped: the scratchpad holds that kind of nuance.

## The scratchpad

One per focus: freeform, unlabelled, always there, picked up where you left off. It's for what isn't a note yet: half-thoughts, "compare with Amos 5?", a sentence being rewritten. When something in it hardens into a claim, select it and turn it into a free note, then label it: the scratchpad keeps the working, the free note the result. A legal pad beside the pile of cards.

## Essays

- **Belong to the user, not a focus.** An essay draws on one or more focuses (a lesson on Sabbath from *What is rest?* and *What does it mean to be holy?*), or on a label across all of them. Synthesis across focuses happens here, through the writing, rather than through some organizing feature. (Earlier ideas, a "focus about focuses" whose texts are your answers, threads across focuses, a single rule-of-life page, become unnecessary or much later.)
- A title, a date, and its **sources** (the focuses or labels it drew on), so each essay records where its thinking came from.
- **Citations:** a quoted passage goes in as a block quote with its citation, linked back to its place in the reader; the reader quietly marks a passage quoted in an essay.
- **Export** as Markdown, copy and download, as notes pages do now. That's how a post leaves the app or a talk gets printed. Publishing from inside the app would be a large step away from the privacy rule, so export is the only way out for now.
- **Each attempt dated.** Old essays can be edited, but coming back usually means a new essay rather than version history: the series of essays is the history of your thinking.
- An earlier idea, one living "answer so far" per focus with dated revisions, gave way to free notes (a focus's answer can be a free note) and essays.

## Not wanted

- **No AI summaries of notes.** The synthesis is the thinking; a generated summary skips it. At most a prompt that asks rather than tells ("Three notes mention *fear*"), and even that may be off-tone.
- **No completion.** No closing a focus, no "synthesized ✓", no scheduled nudges to review.

## Open questions

1. **Where essays live:** a Journal page in the rail, apart from the focuses page; and perhaps "2 essays" on a focus's card.
2. **Kinds of essay** (talk, lesson, post, private): probably not; the title says enough, and a kind is filing.
3. **The writing layout:** the essay in the main column with sources on a sheet at right inverts the reader (text left, your writing right). Which side the essay belongs on wants prototyping.
4. **The scratchpad in a multi-focus essay:** several scratchpads among the sources, or a scratch area per essay as well.
5. **Labels across focuses from the start?** It's the main thing labels offer, but a label page mixing focuses needs care.
6. ~~**Free notes and detached notes:** one table or two.~~ Two: free notes are notes with no unit; detached notes stay as they are.
7. **Phones:** writing an essay on a phone, with the sources as a bottom sheet, under the same-features rule.
