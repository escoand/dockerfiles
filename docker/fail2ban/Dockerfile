FROM ubuntu
RUN apt -q update && \
    apt install -yq --no-install-recommends \
      fail2ban \
      python3-systemd \
      systemd
COPY jail.local /etc/fail2ban/jail.local
CMD ["/usr/bin/fail2ban-server", "-fvx", "start"]