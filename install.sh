#!/bin/sh

set -euo pipefail
export XDG_RUNTIME_DIR="/run/user/$(id -u)"

# dependencies
sudo dnf install -y firewalld podman
sudo loginctl enable-linger "$(id -nu)"

# firewall
sudo sysctl net.ipv4.ip_unprivileged_port_start=80
#sudo systemctl --now enable firewalld
#sudo firewall-cmd --permanent \
#  --add-rich-rule "rule family=ipv4 forward-port port=80 protocol=tcp to-port=8080" \
#  --add-rich-rule "rule family=ipv6 forward-port port=80 protocol=tcp to-port=8080" \
#  --add-rich-rule "rule family=ipv4 forward-port port=443 protocol=tcp to-port=8443" \
#  --add-rich-rule "rule family=ipv6 forward-port port=443 protocol=tcp to-port=8443" \
#  --add-rich-rule "rule family=ipv4 forward-port port=443 protocol=udp to-port=8443" \
#  --add-rich-rule "rule family=ipv6 forward-port port=443 protocol=udp to-port=8443"
#sudo firewall-cmd --reload

# applications
mkdir -p ~/.config/systemd/user ~/.fetchit
curl -sS \
  -o ~/.config/systemd/user/fetchit.service https://raw.githubusercontent.com/containers/fetchit/main/systemd/fetchit-user.service \
  -o ~/.fetchit/config.yaml https://raw.githubusercontent.com/escoand/dockerfiles/master/fetchit.yaml
systemctl --user --now enable podman.socket fetchit
