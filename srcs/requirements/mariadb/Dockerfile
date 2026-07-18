# Debian 12 "bookworm" is the penultimate stable Debian release (13 "trixie"
# is current stable) -- pinned explicitly, "latest" is forbidden by the subject.
FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends mariadb-server && \
    rm -rf /var/lib/apt/lists/*

# Open up the default 127.0.0.1-only bind-address so the container is
# reachable from wordpress over the docker network.
RUN sed -i 's|bind-address\s*=\s*.*|bind-address = 0.0.0.0|' /etc/mysql/mariadb.conf.d/50-server.cnf

RUN mkdir -p /var/run/mysqld /var/lib/mysql && \
    chown -R mysql:mysql /var/run/mysqld /var/lib/mysql

COPY tools/init_db.sh /usr/local/bin/init_db.sh
RUN chmod +x /usr/local/bin/init_db.sh

VOLUME /var/lib/mysql

EXPOSE 3306

# init_db.sh ends with `exec mysqld ...`, so mysqld itself becomes PID 1 and
# receives signals directly -- no wrapper daemon, no infinite-loop hack.
ENTRYPOINT ["/usr/local/bin/init_db.sh"]
