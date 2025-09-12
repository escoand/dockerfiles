#!/bin/sh

set -eu

# handler script
cp fail2ban-fw.sh /usr/local/bin/
chmod 0755 /usr/local/bin/fail2ban-fw.sh

# socket and service
cp -- *.service *.socket /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now fail2ban-fw.socket
