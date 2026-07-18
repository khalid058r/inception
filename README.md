*This project has been created as part of the 42 curriculum by kabouelf.*

# Inception

## Description

Inception is a system administration project: a small, self-hosted web
infrastructure built entirely from Docker containers that each learner
configures and orchestrates by hand. Instead of pulling ready-made images,
every service is built from its own `Dockerfile`, wired together with
`docker compose`, and run inside a virtual machine.

The stack serves a WordPress site over HTTPS:

- **NGINX** — the single entrypoint, terminating TLS (TLSv1.2/TLSv1.3 only)
  on port 443 and forwarding PHP requests to WordPress over FastCGI.
- **WordPress + php-fpm** — the application itself, with no web server of
  its own.
- **MariaDB** — the database backing WordPress, isolated in its own
  container.

Data that must survive container restarts/rebuilds (the database and the
WordPress files) lives in two Docker named volumes, physically stored on
the host under `/home/kabouelf/data`. All three containers communicate over
a single dedicated bridge network and restart automatically if they crash.

## Instructions

### Prerequisites

- A Linux virtual machine with Docker Engine and the Docker Compose plugin.
- `/etc/hosts` on that VM pointing `kabouelf.42.fr` at `127.0.0.1` (or the
  VM's own IP), so the domain name resolves locally as required by the
  subject.

### Setup

```sh
cp srcs/.env.example srcs/.env    # then fill in every value, especially the passwords
```

See [DEV_DOC.md](DEV_DOC.md) for the full setup/build/teardown walkthrough
and [USER_DOC.md](USER_DOC.md) for day-to-day usage once it's running.

### Build & run

```sh
make        # builds the three images and starts the stack in the background
```

Then visit `https://kabouelf.42.fr` (self-signed certificate — the browser
will warn once).

## Resources

- [Docker documentation](https://docs.docker.com/)
- [Docker Compose file reference](https://docs.docker.com/reference/compose-file/)
- [Docker Compose environment variables](https://docs.docker.com/compose/how-tos/environment-variables/)
- [WP-CLI documentation](https://wp-cli.org/)
- [NGINX + php-fpm FastCGI configuration](https://www.nginx.com/resources/wiki/start/topics/examples/phpfcgi/)
- [MariaDB installation & bootstrap docs](https://mariadb.com/kb/en/mysql_install_db/)
- [About PID 1 and signal handling in containers](https://petermalmgren.com/signal-handling-docker/)
- 42's own Inception subject PDF (`en.subject.pdf`, this repository)

**How AI was used:** An AI assistant (Claude) was used to draft the initial
Dockerfiles, entrypoint scripts, `docker-compose.yml`, `Makefile`, and this
documentation set from the subject's requirements, and to cross-check them
against a public reference implementation for structural conventions. Every
generated file was then read and reasoned about line by line — in
particular the MariaDB init script was corrected to be idempotent (the
reference version it was checked against re-ran `--bootstrap` on every
restart, which is unsafe against a persisted volume), and the NGINX
`try_files` fallback was corrected from a broken `try_files $uri 404;` to
the syntactically valid `try_files $uri =404;`. The design was later
simplified deliberately (single `.env` file instead of Docker secrets,
MariaDB's `depends_on: condition: service_healthy` as the sole start-up
gate instead of a manual polling loop in the WordPress entrypoint) — a
change caught in review is that the MariaDB healthcheck originally called
`mysqladmin ping` with no credentials, which would have reported the
container unhealthy forever after the bootstrap script sets a root
password; it now authenticates with `-uroot -p"$MYSQL_ROOT_PASSWORD"`. AI
was not used to bypass understanding: no service was wired up without being
able to explain why each directive, volume, or variable is there.

## Project description: design choices

### Virtual Machines vs Docker

A VM virtualizes an entire machine — kernel, drivers, init system — which
is heavyweight but gives full OS isolation. Docker containers share the
host kernel and only isolate the process/filesystem/network namespace,
making them far lighter and faster to start, at the cost of weaker
isolation than a VM. This project deliberately combines both: the whole
stack runs *inside* a VM (as the subject requires), and *inside* that VM,
each service is a separate container rather than a separate VM, because
running MariaDB/NGINX/WordPress as three full VMs would be wasteful for
processes that just need filesystem and process isolation from each other,
not full kernel isolation.

### Secrets vs Environment variables

Both end up readable by the process that needs them, but they differ in
where the value lives and who can see it. Environment variables set via
`environment:`/`env_file:` are visible in `docker inspect`, in
`/proc/<pid>/environ` of every process in the container, and are inherited
by child processes — a broad surface for a password to leak through logs,
crash dumps, or a compromised dependency. Docker secrets are mounted as
read-only files under `/run/secrets/<name>`, in an in-memory (tmpfs-backed)
filesystem, visible only to the container(s) that explicitly declare them,
and never appear in `docker inspect` or image layers — meaningfully safer,
which is why the subject calls them out as "strongly recommended" for
confidential values.

That said, the subject only makes the `.env` file itself mandatory; Docker
secrets are a recommendation, not a requirement. This project deliberately
keeps everything — including passwords — in `srcs/.env`, gitignored and
never committed, rather than splitting configuration across two mechanisms.
For a project this size, with three services and a handful of credentials,
one file is easier to audit, easier to document (see `DEV_DOC.md`), and
easier to keep consistent than reasoning about which value lives in which
of two systems. The trade-off accepted in exchange is real: `.env` values
show up in `docker inspect <container>` and in each process's
`/proc/<pid>/environ`, which secrets would have avoided. In a project with
more services, more collaborators, or handling anything beyond a local
learning VM, that trade-off would flip and secrets would be worth the
added complexity.

### Docker network vs Host network

`network: host` drops all network namespace isolation: the container binds
directly to the host's interfaces and can reach (and be reached by)
anything the host can, with no per-container hostname resolution. This
project instead defines a single custom bridge network (`inception`,
`docker-network:` in the compose file). Containers on it resolve each other
by service name (`mariadb`, `wordpress`) through Docker's embedded DNS,
stay isolated from the host's other network traffic, and only NGINX
publishes a port to the host (443). That is both what the subject mandates
(host networking and `--link` are explicitly forbidden) and simply safer:
MariaDB and php-fpm are never reachable from outside the Docker network at
all, only through NGINX.

### Docker volumes vs Bind mounts

A bind mount maps an arbitrary host path straight into a container; Docker
has no knowledge of it as a managed object, permissions and existence are
entirely the caller's problem, and nothing prevents a typo from pointing at
the wrong directory. A named volume is a first-class Docker object
(`docker volume create/ls/inspect/rm`) with lifecycle management, and can
be moved between drivers without changing any container-facing path. The
subject requires named volumes but *also* requires the data to live at a
specific host path (`/home/kabouelf/data`), which named volumes normally
abstract away. This project reconciles both constraints using the `local`
driver with `driver_opts: {type: none, o: bind, device: ...}`: the result
is a real named volume (visible to `docker volume ls`/`inspect`, managed
through the normal volume lifecycle) that happens to be backed by that
exact host directory — not a raw bind mount declared directly in the
service's `volumes:` list.
