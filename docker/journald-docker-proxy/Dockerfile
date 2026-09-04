FROM docker.io/library/debian:13.3-slim

# hadolint ignore=DL3008
RUN apt-get -q update && \
    apt-get install -yq --no-install-recommends python3 python3-aiohttp python3-systemd systemd && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

COPY --chmod=0755 server.py /

ENV JOURNAL_ID=_journal

EXPOSE 2375

CMD ["python3", "/server.py"]
