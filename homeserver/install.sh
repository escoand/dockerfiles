#!/bin/sh -ex
set -e

DEVICE=${DEVICE:-/dev/sda1}
EXTERNAL=${EXTERNAL:-/media/external}

# remove debian dependencies
sudo apt-get remove -qy docker docker-engine docker.io runc

# install official docker
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" |
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
curl -fsSL https://download.docker.com/linux/debian/gpg |
sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
sudo apt-get update -qy
sudo apt-get install -qy containerd.io docker-ce docker-ce-cli libseccomp2/buster-backports

# add mountpoint
echo "UUID=$(blkid -s UUID -o value $DEVICE) $EXTERNAL $(blkid -s TYPE -o value $DEVICE) defaults,noatime 0 2" |
sudo tee -a /etc/fstab > /dev/null
sudo mkdir -p "$EXTERNAL"
sudo mount -a

# docker data on external
mkdir -p "$EXTERNAL/docker"
sudo sed -i '$aDOCKER_OPTS="$DOCKER_OPTS --data-root=\"'"$EXTERNAL"'/docker\"' /etc/defaults/docker
sudo sed -i 's#^ExecStart=.*\.sock$#& --data-root='"$EXTERNAL"'/docker#' /usr/lib/systemd/system/docker.service
sudo systemctl daemon-reload
sudo systemctl restart docker

# init repo
git clone https://github.com/escoand/dockerfiles.git
cp -n dockerfiles/homeserver/.env.sample /media/external/docker-compose.env
ln -s /media/external/docker-compose.env dockerfiles/homeserver/.env
cd dockerfiles/homeserver
echo "start editing .env file and run 'sudo docker-compose up -d'"
