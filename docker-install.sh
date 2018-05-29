#!/bin/bash

if [[ $EUID -ne 0 ]] ; then
    echo "Please run this script as root."
    exit 0
fi

apt-get update
apt-get -y dist-upgrade
apt-get -y autoremove
apt-get -y autoclean

# # https://github.com/docker/docker-install
curl -fsSL get.docker.com -o get-docker.sh
sh get-docker.sh
rm get-docker.sh


# # https://docs.docker.com/compose/install/#install-compose
AVAILABLEVERSION=$(curl -s "https://api.github.com/repos/docker/compose/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")')
curl -L "https://github.com/docker/compose/releases/download/$AVAILABLEVERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose


# # https://docs.docker.com/install/linux/linux-postinstall/
groupadd docker
usermod -aG docker $USER
systemctl enable docker
echo "Don't forget to log out and log back in so that your group membership is re-evaluated"
