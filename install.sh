#!/bin/sh

set -euo pipefail
export XDG_RUNTIME_DIR="/run/user/$(id -u)"

# dependencies
sudo dnf install -y firewalld podman
sudo loginctl enable-linger "$(id -nu)"
sudo systemctl --now enable firewalld

# firewall external
sudo firewall-cmd --permanent \
  --add-rich-rule "rule family=ipv4 forward-port port=80 protocol=tcp to-port=8080" \
  --add-rich-rule "rule family=ipv6 forward-port port=80 protocol=tcp to-port=8080" \
  --add-rich-rule "rule family=ipv4 forward-port port=443 protocol=tcp to-port=8443" \
  --add-rich-rule "rule family=ipv6 forward-port port=443 protocol=tcp to-port=8443" \
  --add-rich-rule "rule family=ipv4 forward-port port=443 protocol=udp to-port=8443" \
  --add-rich-rule "rule family=ipv6 forward-port port=443 protocol=udp to-port=8443"

# firewall local
sudo firewall-cmd --permanent --direct --add-rule ipv4 nat OUTPUT 0 -o lo -p tcp --dport 80 -j REDIRECT --to-port=8080
sudo firewall-cmd --permanent --direct --add-rule ipv6 nat OUTPUT 0 -o lo -p tcp --dport 80 -j REDIRECT --to-port=8080
sudo firewall-cmd --permanent --direct --add-rule ipv4 nat OUTPUT 0 -o lo -p tcp --dport 443 -j REDIRECT --to-port=8443
sudo firewall-cmd --permanent --direct --add-rule ipv6 nat OUTPUT 0 -o lo -p tcp --dport 443 -j REDIRECT --to-port=8443
sudo firewall-cmd --permanent --direct --add-rule ipv4 nat OUTPUT 0 -o lo -p udp --dport 443 -j REDIRECT --to-port=8443
sudo firewall-cmd --permanent --direct --add-rule ipv6 nat OUTPUT 0 -o lo -p udp --dport 443 -j REDIRECT --to-port=8443

sudo firewall-cmd --reload
