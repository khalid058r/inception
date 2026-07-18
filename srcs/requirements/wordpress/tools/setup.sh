#!/bin/bash
set -euo pipefail

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

    # Second, non-admin user (subject requires at least two DB users).
    wp user create --allow-root \
        "${WP_USER}" "${WP_USER_EMAIL}" \
        --role=author \
        --user_pass="${WP_USER_PASSWORD}"

    wp option update --allow-root siteurl "https://${DOMAIN_NAME}"
    wp option update --allow-root home "https://${DOMAIN_NAME}"

    echo "[wordpress] Install complete"
else
    echo "[wordpress] wp-config.php already present, skipping install"
fi

chown -R www-data:www-data /var/www/html

# php-fpm runs in the foreground (-F) as PID 1, no daemonizing wrapper.
exec php-fpm8.2 -F
