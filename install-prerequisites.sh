#!/usr/bin/bash

# Classic update/upgrade
sudo apt update  && sudo apt upgrade -y

# Install:
#   - docker.io, docker-compose
#   - xrdp
sudo apt install -y docker.io docker-compose xrdp x11vnc net-tools

# Docker configuration
sudo usermod -aG docker $USER

# XRDP configuration
sudo adduser xrdp ssl-cert
sudo systemctl restart xrdp

# VNC configuration
VNCPASS="mypassword"

# Create VNC directory if it doesn't exist
mkdir -p ~/.vnc

# Set VNC password non-interactively
echo "$VNCPASS" | x11vnc -storepasswd -

# Create systemd service
sudo tee /etc/systemd/system/x11vnc.service > /dev/null <<EOF
[Unit]
Description=x11vnc remote desktop server
After=multi-user.target

[Service]
Type=simple
ExecStart=/usr/bin/x11vnc -auth guess -forever -loop -noxdamage -repeat -rfbauth /home/$USER/.vnc/passwd -rfbport 5900 -shared -display :0
ExecStop=/bin/kill -TERM \$MAINPID
ExecReload=/bin/kill -HUP \$MAINPID
KillMode=control-group
Restart=on-failure
User=$USER

[Install]
WantedBy=multi-user.target
EOF

# Enable and start VNC service
sudo systemctl daemon-reload
sudo systemctl enable x11vnc.service
sudo systemctl start x11vnc.service

# Show service status
sudo systemctl status x11vnc.service
