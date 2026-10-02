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
