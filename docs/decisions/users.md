# Users, sign-in and the landing page

## Users

**A few invited people** (decided 2026-10-02).

- Foci and notes belong to a user, and nobody (admins included) can read another user's notes. The library is shared (user texts are the exception: always private; see [user-texts.md](user-texts.md)).
- Sign-up is by **invitation only**: an admin creates a single-use link (stored as a digest, shown once, expires in 7 days, open to whoever holds it) and sends it themselves. No email delivery.
- `users.admin` is set with `bin/rails study_carrel:make_admin EMAIL=...`.
- No password reset yet.
- **Sessions last 30 days** from sign-in, then you sign in again (decided 2026-10-04; expired rows are cleared daily). **Sign out signs you out on every device**.
- Possible later: encrypting notes. Sharing notes is still manual (copy/paste).

## Landing page

**Public landing page at `/`** (decided 2026-10-04) for signed-out visitors, using its own layout (`layouts/landing`, CSS inline) so it can't leak into app styles. Signed-in users go to the focuses page (see [foci-and-notes.md](foci-and-notes.md)). Prototype: `prototype/landing.html`.

No contact address or email link anywhere, because signups are by invitation only and the author doesn't want to be reachable by strangers.
