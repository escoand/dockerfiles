FROM docker.io/library/debian:13.2-slim

RUN apt -q update && \
    apt install -yq --no-install-recommends gawk jq socat systemd && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

COPY --chmod=0755 *.sh /

ENV SHOW_SYSTEMD_UNITS=

EXPOSE 2375

CMD ["/entrypoint.sh"]