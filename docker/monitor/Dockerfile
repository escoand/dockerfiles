FROM docker.io/library/alpine:3.24.0

# hadolint ignore=DL3018
RUN apt update -y && \
    apt install -y --no-install-recommends curl jq msmtp systemd uuid-runtime && \
    rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /

ENTRYPOINT [ "/entrypoint.sh" ]
