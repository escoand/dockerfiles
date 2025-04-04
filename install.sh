#!/bin/sh

set -euo pipefail
export XDG_RUNTIME_DIR="/run/user/$(id -u)"

# dependencies
sudo dnf install -y firewalld podman
sudo loginctl enable-linger "$(id -nu)"

# allow privileged ports
sudo sysctl net.ipv4.ip_unprivileged_port_start=80
