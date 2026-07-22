#!/bin/bash
set -e

if [ ! -f wp-config.php ]; then
    echo "[wordpress] Downloading WordPress core"
    wp core download --allow-root

    wp config create --allow-root \
        --dbname="${MYSQL_DATABASE}" \
        --dbuser="${MYSQL_USER}" \
        --dbpass="${MYSQL_PASSWORD}" \
        --dbhost=mariadb

    wp core install --allow-root \
        --url="https://${DOMAIN_NAME}" \
        --title="${WP_TITLE}" \
        --admin_user="${WP_ADMIN_USER}" \
        --admin_password="${WP_ADMIN_PASSWORD}" \
        --admin_email="${WP_ADMIN_EMAIL}"

    wp user create --allow-root \
        "${WP_USER}" "${WP_USER_EMAIL}" \
        --role=author \
        --user_pass="${WP_USER_PASSWORD}"

    echo "[wordpress] Install complete"
else
    echo "[wordpress] wp-config.php already present, skipping install"
fi

chown -R www-data:www-data /var/www/html

exec php-fpm8.2 -F
