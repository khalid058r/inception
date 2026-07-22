FROM debian:bookworm

RUN apt-get update && \
    apt-get install -y mariadb-server && \
    rm -rf /var/lib/apt/lists/*

RUN sed -i 's|bind-address\s*=\s*.*|bind-address = 0.0.0.0|' /etc/mysql/mariadb.conf.d/50-server.cnf

RUN mkdir -p /var/run/mysqld /var/lib/mysql && \
    chown -R mysql:mysql /var/run/mysqld /var/lib/mysql

COPY tools/init_db.sh /usr/local/bin/init_db.sh
RUN chmod +x /usr/local/bin/init_db.sh

ENTRYPOINT ["/usr/local/bin/init_db.sh"]
