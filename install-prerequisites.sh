#!/usr/bin/bash

# Detect the distribution
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
else
    echo "Cannot detect distribution. Exiting."
    exit 1
fi

echo "Detected distribution: $DISTRO"

# Update system and install packages based on distribution
case $DISTRO in
    ubuntu|debian)
        echo "Installing packages for Ubuntu/Debian..."
        # Classic update/upgrade
        sudo apt update && sudo apt upgrade -y

        # Install:
        #   - docker.io, docker-compose
        #   - xrdp, x11vnc, net-tools
        sudo apt install -y docker.io docker-compose xrdp x11vnc net-tools

        # XRDP configuration (Ubuntu/Debian specific)
        sudo adduser xrdp ssl-cert
        ;;

    fedora|rhel|centos|rocky|almalinux)
        echo "Installing packages for Fedora/RHEL-based systems..."
        # Update system
        sudo dnf update -y

        # Install packages:
        #   - docker, docker-compose (from plugin)
        #   - xrdp, x11vnc, net-tools
        sudo dnf install -y docker docker-compose xrdp x11vnc net-tools

        # XRDP configuration (Fedora/RHEL specific)
        # On RHEL-based systems, the ssl-cert group doesn't exist
        # xrdp has the necessary permissions through its own group
        ;;

    *)
        echo "Unsupported distribution: $DISTRO"
        echo "Supported distributions: Ubuntu, Debian, Fedora, RHEL, CentOS, Rocky Linux, AlmaLinux"
        exit 1
        ;;
esac

# Docker configuration (common for all distributions)
sudo usermod -aG docker $USER

# Start and enable Docker service
sudo systemctl start docker
sudo systemctl enable docker

# XRDP service
sudo systemctl restart xrdp
sudo systemctl enable xrdp

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
