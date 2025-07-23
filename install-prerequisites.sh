#!/usr/bin/bash

# Classic update/upgrade
sudo apt update  && sudo apt upgrade -y

# Install:
#   - docker.io, docker-compose
#   - xrdp
sudo apt install -y docker.io docker-compose xrdp

# XRDP configuration
sudo adduser xrdp ssl-cert
sudo systemctl restart xrdp