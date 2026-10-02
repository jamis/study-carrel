# Study Carrel

A quiet, single-user web app for reading texts (scripture, poetry, prose) one unit at a
time, lectio-style, with a question or thesis (the *focus*) pinned above the text and
notes attached to each verse, stanza or paragraph. It works the same on a laptop and a
phone, and installs as a PWA.

Built with Rails 8, Hotwire, SQLite and the Lexxy editor. A personal project, developed
in the open.

## Running it

```
bin/setup          # installs gems, prepares the database, loads the bundled texts
bin/dev
```

In development, `db/seeds.rb` creates a throwaway login (`dev@example.com` /
`password`). In production, create your user from a Rails console (see `SERVER.md`).

`bin/rails test` runs the tests.

## Texts

Bundled in `db/texts/`, all in the public domain: the King James Old Testament, Emily
Dickinson's poems and Thoreau's *Walden*, from Project Gutenberg (the KJV is
cross-checked against two other sources). `script/texts/` rebuilds them. See
`DECISIONS.md` for the reasoning behind these choices and `PLAN.md` for the build plan.

## Deploying

A small droplet, no Docker: Capistrano, Puma under systemd, Caddy for HTTPS. The one-time
server setup is in `SERVER.md`; after that, `bundle exec cap production deploy`.

## License

MIT, see `LICENSE`. The texts are public domain.
