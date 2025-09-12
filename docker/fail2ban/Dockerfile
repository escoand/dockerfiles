FROM docker.io/library/debian:13.1-slim

RUN apt -q update && \
    apt install -yq --no-install-recommends fail2ban firewalld python3-systemd && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

COPY files/ /etc/fail2ban/

VOLUME /var/lib/fail2ban

CMD ["/usr/bin/fail2ban-server", "-fx", "start"]