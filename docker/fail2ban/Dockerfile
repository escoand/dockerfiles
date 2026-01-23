FROM docker.io/library/debian:13.3-slim

RUN apt-get -q update && \
    apt-get install -yq --no-install-recommends curl fail2ban python3-systemd && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

COPY files/ /etc/fail2ban/

VOLUME /var/lib/fail2ban

CMD ["/usr/bin/fail2ban-server", "-fx", "start"]
