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
sudo firewall-cmd --permanent --new-policy local-forward
sudo firewall-cmd --permanent --policy local-forward --add-ingress-zone HOST
sudo firewall-cmd --permanent --policy local-forward --add-egress-zone ANY
sudo firewall-cmd --permanent --policy local-forward \
  --add-rich-rule "rule family=ipv4 forward-port port=80 protocol=tcp to-port=8080 to-addr=127.0.0.1" \
  --add-rich-rule "rule family=ipv6 forward-port port=80 protocol=tcp to-port=8080 to-addr=::1" \
  --add-rich-rule "rule family=ipv4 forward-port port=443 protocol=tcp to-port=8443 to-addr=127.0.0.1" \
  --add-rich-rule "rule family=ipv6 forward-port port=443 protocol=tcp to-port=8443 to-addr=::1" \
  --add-rich-rule "rule family=ipv4 forward-port port=443 protocol=udp to-port=8443 to-addr=127.0.0.1" \
  --add-rich-rule "rule family=ipv6 forward-port port=443 protocol=udp to-port=8443 to-addr=::1"
  
sudo firewall-cmd --reload
