#!/bin/bash
set -euo pipefail

DATADIR=/var/lib/mysql

# The named volume persists /var/lib/mysql across restarts and rebuilds, so
# only initialize the data directory the very first time it is empty.
# Re-running --bootstrap on an already-initialized datadir would fail/corrupt
# state, which is why this check matters for a container that must restart
# on crash without wiping the WordPress database.
if [ ! -d "$DATADIR/mysql" ]; then
    echo "[mariadb] Initializing data directory (first run)"
    mariadb-install-db --user=mysql --datadir="$DATADIR" --skip-test-db --auth-root-authentication-method=normal >/dev/null

    mysqld --user=mysql --datadir="$DATADIR" --bootstrap <<SQL
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
SQL

    echo "[mariadb] Database '${MYSQL_DATABASE}' and user '${MYSQL_USER}' created"
else
    echo "[mariadb] Existing data directory found, skipping initialization"
fi

exec mysqld --user=mysql --datadir="$DATADIR"
