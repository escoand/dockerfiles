FROM docker.io/library/debian:13.1-slim

RUN apt -q update && \
    apt install -yq --no-install-recommends gawk jq socat systemd && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

COPY --chmod=0755 *.sh /

EXPOSE 2375

CMD ["/entrypoint.sh"]