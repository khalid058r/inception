# Developer documentation

## Setting up the environment from scratch

### Prerequisites

- A virtual machine (the subject requires the whole project to run inside
  one), Linux, with:
  - Docker Engine
  - the Docker Compose plugin (`docker compose version` should work)
- `sudo` access on that VM (only used by `make fclean` to remove
  `/home/kabouelf/data`, and for the one-time `/etc/hosts` edit below).

### Domain name

The subject requires `<login>.42.fr` to resolve to the machine's own
address. On the VM:

```sh
echo "127.0.0.1 kabouelf.42.fr" | sudo tee -a /etc/hosts
```

(Use the VM's LAN IP instead of `127.0.0.1` if you want to reach it from
another machine.)

### Configuration files

Nothing confidential is tracked in git — only `srcs/.env.example` is.
Create the real file once, locally:

```sh
cp srcs/.env.example srcs/.env
```

Then edit it — every value the stack needs lives in this one file, consumed
by `docker-compose.yml` via `env_file:` (and, for `DOMAIN_NAME`, also as a
build arg for the nginx image's self-signed cert CN):

- `DOMAIN_NAME`
- `MYSQL_DATABASE`, `MYSQL_USER`, `MYSQL_PASSWORD`, `MYSQL_ROOT_PASSWORD`
- `WP_TITLE`, `WP_ADMIN_USER`, `WP_ADMIN_EMAIL`, `WP_ADMIN_PASSWORD`,
  `WP_USER`, `WP_USER_EMAIL`, `WP_USER_PASSWORD`

`WP_ADMIN_USER` must not contain `admin`/`Admin`/`administrator`/
`Administrator` — this is a subject requirement, and it is **not**
re-validated at container start (kept out of the entrypoint deliberately to
keep it simple), so double-check the value yourself before running `make`.

The subject treats Docker secrets as "strongly recommended" for
confidential values, not mandatory — this project keeps everything in the
single `.env` file instead, gitignored like any other local secret. See the
README's "Secrets vs Environment variables" section for the trade-off.

## Building and launching with the Makefile / Docker Compose

```sh
make               # = make check-config build up
```

`check-config` verifies the files above exist (fails fast with a clear
message if not) and creates `/home/kabouelf/data/{wordpress,mariadb}` on
the host before compose runs, since the named volumes are bind-backed by
those exact paths.

Under the hood this runs:

```sh
docker compose --env-file srcs/.env -f srcs/docker-compose.yml build
docker compose --env-file srcs/.env -f srcs/docker-compose.yml up -d
```

(`--env-file` is passed explicitly because, run from the repo root, Docker
Compose would otherwise look for `.env` next to the current directory, not
next to `srcs/docker-compose.yml`.)

Other targets:

| Target        | Effect                                                          |
|---------------|------------------------------------------------------------------|
| `make build`  | Build (or rebuild) the three images only.                       |
| `make up`     | Start containers in the background.                             |
| `make down`   | Stop and remove containers + network (volumes/data kept).       |
| `make stop`   | Pause containers without removing them.                         |
| `make start`  | Resume paused containers.                                       |
| `make logs`   | Follow logs for every service.                                  |
| `make ps`     | Show container status.                                          |
| `make clean`  | Alias for `down`.                                                |
| `make fclean` | `down -v --rmi all` + `sudo rm -rf /home/kabouelf/data` (destructive). |
| `make re`     | `fclean` then `all` — full rebuild from a clean slate.           |

## Managing containers and volumes directly

```sh
docker compose -f srcs/docker-compose.yml ps
docker exec -it mariadb bash
docker exec -it wordpress bash
docker exec -it nginx bash

docker volume ls                       # wordpress_data, mariadb_data
docker volume inspect wordpress_data   # shows Mountpoint = /home/kabouelf/data/wordpress
```

Rebuilding a single service after editing its Dockerfile:

```sh
docker compose -f srcs/docker-compose.yml build wordpress
docker compose -f srcs/docker-compose.yml up -d wordpress
```

## Where data lives and how it persists

- **MariaDB data** (`/var/lib/mysql` inside the container) → named volume
  `mariadb_data` → `/home/kabouelf/data/mariadb` on the host.
- **WordPress files** (`/var/www/html` inside the container, shared
  read-write with `wordpress` and read-only with `nginx`) → named volume
  `wordpress_data` → `/home/kabouelf/data/wordpress` on the host.

Both are declared with the `local` driver and `driver_opts: {type: none,
o: bind, device: ...}` in `srcs/docker-compose.yml`, which makes them real
Docker named volumes (`docker volume inspect` works, lifecycle is managed
by Docker) that are nonetheless backed by that specific host path, as the
subject requires. Because the data lives outside the containers' writable
layers, `make down` / `make up` / `make re` (without `fclean`) never lose
data — the MariaDB init script (`srcs/requirements/mariadb/tools/init_db.sh`)
explicitly detects an already-initialized data directory and skips
re-bootstrapping, and the WordPress entrypoint
(`srcs/requirements/wordpress/tools/setup.sh`) skips `wp core install` if
`wp-config.php` already exists. Only `make fclean` (or manually deleting
`/home/kabouelf/data`) actually removes this data.
