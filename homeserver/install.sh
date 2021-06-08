#!/bin/sh -ex

# remove debian dependencies
sudo apt-get remove -qy docker docker-engine docker.io runc

# install official docker
echo "deb [arch=armhf signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" |
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
curl -fsSL https://download.docker.com/linux/debian/gpg |
sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
sudo apt-get update -qy
sudo apt-get install -qy containerd.io docker-ce docker-ce-cli libseccomp2/buster-backports

# add mountpoint
UUID=$(lsblk -pro UUID,NAME | grep /dev/sda1 | cut -d' ' -f1)
[ -z "$UUID" ] && exit 1
echo "UUID=$UUID /media/external btrfs defaults,rw,relatime,space_cache,subvolid=5,subvol=/ 0 1" |
sudo tee -a /etc/fstab > /dev/null
sudo mkdir /media/external
sudo mount -a

# init repo
git clone https://github.com/escoand/dockerfiles.git
cp -n dockerfiles/homeserver/.env.sample /media/external/docker-compose.env
ln -s /media/external/docker-compose.env dockerfiles/homeserver/.env
cd dockerfiles/homeserver
echo "start editing .env file and run 'sudo docker-compose up -d'"
