#!/bin/bash

# # https://github.com/docker/docker-install
curl -fsSL get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo rm get-docker.sh


# # https://docs.docker.com/compose/install/#install-compose
AVAILABLEVERSION=$(curl -s "https://api.github.com/repos/docker/compose/releases/latest" | grep -Po '"tag_name": "\K.*?(?=")')
sudo curl -L "https://github.com/docker/compose/releases/download/$AVAILABLEVERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose


# # https://docs.docker.com/install/linux/linux-postinstall/
sudo groupadd docker
sudo usermod -aG docker $USER
sudo systemctl enable docker
echo "Don't forget to log out and log back in so that your group membership is re-evaluated"
