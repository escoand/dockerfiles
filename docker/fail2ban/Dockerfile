FROM ubuntu

RUN apt -q update && \
    apt install -yq --no-install-recommends \
      fail2ban \
      python3-systemd \
      systemd

COPY fail2ban.local /etc/fail2ban/fail2ban.local
COPY jail.local /etc/fail2ban/jail.local

VOLUME /var/lib/fail2ban

CMD ["/usr/bin/fail2ban-server", "-fx", "start"]