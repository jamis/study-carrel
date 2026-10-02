# Server setup (one time)

Study Carrel runs directly on an Ubuntu 24.04 droplet, deployed with Capistrano.
Puma runs under systemd as the `deploy` user; Caddy terminates HTTPS and proxies to
it. Every later deploy is `cap production deploy`.

Host: `studycarrel.jamisbuck.org` (DNS-only A record, not proxied). Replace it below
if the name changes. Unless noted, commands run as root on the droplet
(`ssh root@studycarrel.jamisbuck.org`).

## 1. Basics

```
# 1 GB swap (the droplet has ~450 MB of RAM)
fallocate -l 1G /swapfile && chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile
echo "/swapfile none swap sw 0 0" >> /etc/fstab

# Firewall: SSH, HTTP, HTTPS only
ufw allow 22/tcp && ufw allow 80/tcp && ufw allow 443/tcp && ufw --force enable

apt update && apt upgrade -y
apt install -y build-essential git curl pkg-config libyaml-dev libssl-dev zlib1g-dev libffi-dev libvips sqlite3
```

## 2. The deploy user and Ruby

```
adduser --disabled-password --gecos "" deploy
mkdir -p ~deploy/.ssh && cp ~/.ssh/authorized_keys ~deploy/.ssh/ && chown -R deploy:deploy ~deploy/.ssh && chmod 700 ~deploy/.ssh

su - deploy
curl https://mise.run | sh
~/.local/bin/mise use -g ruby@4.0.7     # matches .ruby-version
exit
```

## 3. Shared files

```
su - deploy -c 'mkdir -p ~/study_carrel/shared/config'
```

From your laptop, copy the Rails master key (never committed):

```
scp config/master.key deploy@studycarrel.jamisbuck.org:study_carrel/shared/config/master.key
```

## 4. systemd, sudo and Caddy

From your laptop, in the project directory:

```
scp config/server/study_carrel.service config/server/Caddyfile config/server/sudoers-deploy root@studycarrel.jamisbuck.org:/tmp/
```

On the droplet:

```
# Caddy (official repo)
apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list
apt update && apt install -y caddy

install -m 644 /tmp/Caddyfile /etc/caddy/Caddyfile
systemctl reload caddy

install -m 644 /tmp/study_carrel.service /etc/systemd/system/study_carrel.service
systemctl daemon-reload && systemctl enable study_carrel   # starts on first deploy

visudo -cf /tmp/sudoers-deploy && install -m 440 /tmp/sudoers-deploy /etc/sudoers.d/deploy
```

## 5. First deploy

From your laptop (the code must be pushed to the repo in `config/deploy.rb`):

```
bundle exec cap production deploy:check
bundle exec cap production deploy
bundle exec cap production study_carrel:load_texts
```

Create your user interactively, so the password never lands in a command line or log:

```
ssh -t deploy@studycarrel.jamisbuck.org 'cd study_carrel/current && RAILS_ENV=production ~/.local/bin/mise exec -- bin/rails console'
> User.create!(email_address: "you@example.com", password: "...")
```

## Everyday

- Deploy: `bundle exec cap production deploy`
- Roll back: `bundle exec cap production deploy:rollback`
- Logs: `ssh root@studycarrel.jamisbuck.org journalctl -u study_carrel -f`
- Reload texts after changing `db/texts`: `cap production study_carrel:load_texts`

## Backups (Litestream to Backblaze B2)

Litestream streams the primary database (`production.sqlite3`, where the notes live) to a
private B2 bucket, continuously. The other three databases are disposable.

**In the B2 console (once):**

1. Buckets → *Create a Bucket*: a unique name (e.g. `studycarrel-backups-<something>`),
   **Private**, default encryption on. Note its **Endpoint** (like
   `s3.us-west-004.backblazeb2.com`); the region is the middle part (`us-west-004`).
2. On the bucket, *Lifecycle Settings* → *Use custom lifecycle rules*: keep prior versions
   for **30 days**. (B2 keeps deleted/replaced files as hidden versions; Litestream prunes
   its own files constantly, so without this the bucket only grows. Thirty days also gives
   you time to recover from a bad write.)
3. App Keys → *Add a New Application Key*: restrict it to **this bucket only**, read and
   write. Copy the **keyID** and **applicationKey** now: B2 shows the secret once.

**On the droplet (as root):**

```
curl -fsSLO https://github.com/benbjohnson/litestream/releases/download/v0.5.17/litestream-0.5.17-linux-x86_64.deb
dpkg -i litestream-0.5.17-linux-x86_64.deb && rm litestream-0.5.17-linux-x86_64.deb
```

Write the credentials with a prompt (the secret is hidden as you type it; the exact variable
names matter, since systemd silently ignores a misspelled one and logs its value):

```
read -p "keyID: " K; read -sp "applicationKey: " S; echo; umask 077
printf "LITESTREAM_ACCESS_KEY_ID=%s\nLITESTREAM_SECRET_ACCESS_KEY=%s\n" "$K" "$S" > /etc/litestream.env
```

`config/server/litestream.yml` already has this bucket, endpoint and region (change them
if you use another bucket). From the laptop:

```
scp config/server/litestream.yml root@studycarrel.jamisbuck.org:/etc/litestream.yml
scp config/server/litestream.service root@studycarrel.jamisbuck.org:/etc/systemd/system/litestream.service
```

and on the droplet:

```
systemctl daemon-reload && systemctl enable --now litestream
journalctl -u litestream -n 20 --no-pager
```

**Restore test (do this once, now, and again after big changes).** Restore into a scratch
file and open it; never over the live database:

```
set -a; . /etc/litestream.env; set +a      # as root: load the B2 credentials
litestream restore -o /tmp/restore-test.sqlite3 /home/deploy/study_carrel/shared/storage/production.sqlite3
sqlite3 /tmp/restore-test.sqlite3 'select count(*) from units; select count(*) from notes;'
rm /tmp/restore-test.sqlite3*
```

**Disaster recovery** (the droplet is gone): rebuild the server from sections 1-5, create
`/etc/litestream.env` and `/etc/litestream.yml`, deploy, stop the app, then
`litestream restore -o <storage>/production.sqlite3 <that db path>` (load the credentials as above, then `chown deploy:deploy` the result), start the
app, and enable `litestream`.
