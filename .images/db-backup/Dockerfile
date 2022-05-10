FROM alpine AS cron

ENV SUPERCRONIC_VERSION="v0.1.12"
ENV SUPERCRONIC_PACKAGE="supercronic-linux-amd64"
ENV SUPERCRONIC_SHA1SUM="048b95b48b708983effb2e5c935a1ef8483d9e3e"

ENV SUPERCRONIC_URL="https://github.com/aptible/supercronic/releases/download/$SUPERCRONIC_VERSION/$SUPERCRONIC_PACKAGE"

RUN apk add --update --no-cache ca-certificates curl                                        && \
    curl --fail --silent --show-error --location --output /supercronic "${SUPERCRONIC_URL}" && \
    echo "${SUPERCRONIC_SHA1SUM}  /supercronic" | sha1sum -c -                              && \
    chmod +x /supercronic


FROM alpine

ENV CONTAINER_LOG_LEVEL=NOTICE

COPY --from=cron /supercronic /bin/supercronic

RUN apk --update --no-cache add \
    bash                        \
    postgresql14-client         \
    tzdata                      \
    zstd

COPY ["scripts/*", "/scripts/"]

RUN touch /crontab
RUN mkdir /tmp/backups
RUN chmod 755 /scripts/*
RUN chmod 777 /tmp/backups
RUN chmod 666 /crontab

ENTRYPOINT ["/scripts/entrypoint.sh"]
