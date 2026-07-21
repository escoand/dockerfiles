FROM docker.io/library/debian:stable-slim

# hadolint ignore=DL3018
RUN apt update -y && \
    apt install -y --no-install-recommends ca-certificates curl jq msmtp systemd uuid-runtime && \
    rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /

ENTRYPOINT [ "/entrypoint.sh" ]
