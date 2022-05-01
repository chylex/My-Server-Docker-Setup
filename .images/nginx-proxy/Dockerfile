FROM nginx:alpine

ENV SERVER_NAME=localhost
ENV SERVER_PORT=80
ENV TZ=UTC

RUN apk update && apk add tzdata

RUN addgroup --gid 901 --system app_ssl_certs

COPY conf/nginx.conf /etc/nginx/nginx.conf
RUN rm /etc/nginx/conf.d/default.conf

COPY ["entrypoint.sh", "conf/*", "/app/"]

RUN chown -R root:app_ssl_certs /app       \
                                /etc/nginx \
                                /var/cache/nginx

RUN chmod -R g+w /etc/nginx \
                 /var/cache/nginx

RUN chmod 644 /etc/nginx/nginx.conf
RUN chmod +x /app/entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"]
