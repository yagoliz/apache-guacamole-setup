#!/usr/bin/bash

# Classic update/upgrade
sudo apt update  && sudo apt upgrade -y

# Install:
#   - docker.io, docker-compose
#   - xrdp
sudo apt install -y docker.io docker-compose xrdp

# Docker configuration
sudo usermod -aG docker $USER

# XRDP configuration
sudo adduser xrdp ssl-cert
sudo systemctl restart xrdp
