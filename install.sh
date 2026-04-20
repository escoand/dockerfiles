#!/bin/bash
# shellcheck disable=SC2155

set -euo pipefail
export XDG_RUNTIME_DIR="/run/user/$(id -u)"

# dependencies
sudo dnf install -y firewalld jq podman
sudo loginctl enable-linger "$(id -nu)"

# allow privileged ports
sudo sysctl net.ipv4.ip_unprivileged_port_start=80

# fail2ban handler script
cp fail2ban-fw/*.sh /usr/local/bin/
chmod 0755 /usr/local/bin/fail2ban-fw.sh

# notify-fail script and service (not deployable via Quadit - plain systemd, not quadlet)
mkdir -p ~/.config/systemd/user/service.d
cp notify-fail/notify-fail@.service ~/.config/systemd/user/
cp notify-fail/service.d/notify-fail.conf ~/.config/systemd/user/service.d/
systemctl --user daemon-reload
# credentials required in ~/.config/notify-fail.env
# (MATRIX_HOST, MATRIX_ACCESS_TOKEN, MATRIX_ROOM_ID)

# fail2ban socket and service
cp -- fail2ban-fw/*.service fail2ban-fw/*.socket /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now fail2ban-fw.socket
