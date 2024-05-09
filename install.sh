#!/bin/bash

# Définition du mot de passe root
echo "Définition du mot de passe root..."
echo -e "blotch-outsell-gas-recipe\nblotch-outsell-gas-recipe" | sudo passwd root

# Mise à jour de Linux sur Raspberry Pi
echo "Mise à jour de Linux..."
sudo apt update
sudo apt upgrade -y

# Installation de Docker
echo "Installation de Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Installation de Docker Compose
echo "Installation de Docker Compose..."
sudo apt install -y docker-compose

# Configuration du réseau pour éviter les problèmes de permissions
echo "Configuration du réseau pour Docker..."
sudo groupadd docker
sudo gpasswd -a $USER docker
newgrp docker

# Installation des conteneurs NGINX Proxy Manager, RaspAP et Home Assistant via Docker Compose
cat << EOF > docker-compose.yml
version: '3'

services:
  nginx-proxy-manager:
    image: 'jc21/nginx-proxy-manager:latest'
    restart: always
    ports:
      - '80:80'
      - '81:81'
      - '443:443'
    environment:
      DB_MYSQL_HOST: "db"
      DB_MYSQL_PORT: 3306
      DB_MYSQL_USER: "npm"
      DB_MYSQL_PASSWORD: "npm"
      DB_MYSQL_NAME: "npm"
    volumes:
      - ./data:/app/data
      - ./letsencrypt:/app/letsencrypt
      - ./nginx:/etc/nginx

  db:
    image: 'jc21/mariadb-aria:latest'
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: 'npm'
      MYSQL_DATABASE: 'npm'
      MYSQL_USER: 'npm'
      MYSQL_PASSWORD: 'npm'
    volumes:
      - ./data/mysql:/var/lib/mysql

  raspap:
    image: "goldyfruit/raspap-webgui:latest"
    restart: always
    network_mode: "host"
    privileged: true
    volumes:
      - "/etc/raspap:/etc/raspap"
    environment:
      - INSTALL_MYSQL=false
      - INSTALL_AIRCRACK=false

  homeassistant:
    container_name: homeassistant
    image: homeassistant/raspberrypi4-homeassistant:stable
    restart: always
    network_mode: host
    volumes:
      - /PATH_TO_YOUR_CONFIG:/config
    environment:
      - TZ=YOUR_TIMEZONE
EOF

# Démarrage des conteneurs
echo "Démarrage des conteneurs Docker..."
sudo docker-compose up -d
