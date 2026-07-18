# User documentation

This document is for anyone who just wants to run the stack and use the
WordPress site — no Docker knowledge required beyond the commands below.

## What services are provided

| Service   | What it does                                              |
|-----------|------------------------------------------------------------|
| NGINX     | The only door in: serves the site over HTTPS on port 443.  |
| WordPress | The blog/CMS itself (runs behind NGINX, not reachable directly). |
| MariaDB   | Stores the WordPress content (posts, users, settings).     |

## Starting and stopping the project

Run these from the repository root.

```sh
make          # build the images (first time) and start everything
make stop     # pause all containers without removing them
make start    # resume paused containers
make down     # stop and remove the containers (data is kept)
make re       # full reset: wipe everything, including stored data, and rebuild
```

`make` (or `make all`) is idempotent — running it again just makes sure
everything is built and running, it won't re-download or reinstall
WordPress if it's already set up.

## Accessing the website and the administration panel

1. Make sure `kabouelf.42.fr` resolves to the machine running the stack.
   On that machine, `/etc/hosts` should contain:
   ```
   127.0.0.1 kabouelf.42.fr
   ```
2. Open `https://kabouelf.42.fr` in a browser — this is the public site.
3. Open `https://kabouelf.42.fr/wp-admin` — this is the administration
   panel (login screen).

The certificate is self-signed (there is no public certificate authority
involved), so the browser will show a security warning the first time —
that is expected, not a sign of a broken setup. Accept/continue past it.

## Locating and managing credentials

Nothing is hardcoded or guessable from the repository itself: every
username, email, and password (WordPress admin, WordPress author, MariaDB
application user, MariaDB root) lives in `srcs/.env`
(`WP_ADMIN_USER`/`WP_ADMIN_PASSWORD`, `WP_USER`/`WP_USER_PASSWORD`,
`MYSQL_USER`/`MYSQL_PASSWORD`, `MYSQL_ROOT_PASSWORD`, etc.).

That file is not committed to git (only `srcs/.env.example` is) — ask
whoever set up the deployment for the actual values, or see `DEV_DOC.md`
if you're setting up your own instance.

To change a password after the site already exists, don't just edit
`srcs/.env` — it's only read on first install. Use WP-CLI or the
`wp-admin` "Users" screen instead, and update `srcs/.env` to match for your
own records.

## Checking that the services are running correctly

```sh
make ps
```

All three services (`mariadb`, `wordpress`, `nginx`) should show as
`running (healthy)` or `running`. If one is missing or restarting in a
loop:

```sh
make logs                       # follow logs for every service
docker logs mariadb              # or target a single container
docker logs wordpress
docker logs nginx
```

A quick end-to-end check without a browser:

```sh
curl -kI https://kabouelf.42.fr
```

`-k` accepts the self-signed certificate; a `200 OK` (or `301/302`)
response means NGINX, WordPress, and MariaDB are all working together
correctly.
