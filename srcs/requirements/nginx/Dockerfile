FROM debian:bookworm-slim

ARG DOMAIN_NAME=localhost

RUN apt-get update && \
    apt-get install -y --no-install-recommends nginx openssl && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/nginx/ssl && \
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/inception.key \
        -out /etc/nginx/ssl/inception.crt \
        -subj "/C=MA/ST=Rabat/L=Rabat/O=42network/CN=${DOMAIN_NAME}"

COPY conf/nginx.conf /etc/nginx/conf.d/wordpress.conf
RUN rm -f /etc/nginx/sites-enabled/default /etc/nginx/conf.d/default.conf

EXPOSE 443

# nginx runs in the foreground as PID 1 (daemon off) so it receives signals
# directly -- no tail -f / sleep infinity wrapper.
CMD ["nginx", "-g", "daemon off;"]
