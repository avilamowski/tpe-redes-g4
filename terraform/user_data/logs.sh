#!/bin/bash
# Add Docker's official GPG key:
touch /progress.txt
echo "start" >> /progress.txt

sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

#Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$${UBUNTU_CODENAME:-$$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "installed docker" >> /progress.txt

sudo groupadd -f docker
sudo usermod -aG docker $$USER
newgrp docker

echo "changed permissions for docker" >> /progress.txt

git clone https://github.com/Ian-Arnott/TPE-Redes
cd TPE-Redes
git reset --hard a849892

echo "pulled repo" >> /progress.txt

sudo ./generate-certs.sh

echo "generate certificates" >> /progress.txt

cd elk-stack
# docker compose up --build
# echo "compose up" >> /progress.txt