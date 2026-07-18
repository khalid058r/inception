# Debian 12 "bookworm" is the penultimate stable Debian release, pinned
# explicitly (its default PHP is 8.2, referenced below).
FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        php-fpm php-mysqli php-curl php-gd php-xml php-mbstring php-zip \
        curl ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Expose php-fpm over TCP on the docker network instead of the default unix
# socket, so nginx can reach it as wordpress:9000.
RUN sed -i 's|^listen = .*|listen = 9000|' /etc/php/8.2/fpm/pool.d/www.conf

RUN curl -fsSL -o /usr/local/bin/wp \
        https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x /usr/local/bin/wp

RUN mkdir -p /run/php /var/www/html
WORKDIR /var/www/html

COPY tools/setup.sh /usr/local/bin/setup.sh
RUN chmod +x /usr/local/bin/setup.sh

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/setup.sh"]
