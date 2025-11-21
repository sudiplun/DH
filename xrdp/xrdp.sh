#!/bin/bash

# Update and upgrade system
sudo apt update && sudo apt upgrade -y

# Install GNOME core packages
sudo apt install gnome-core -y

# Start and enable gdm3 service
sudo systemctl start gdm3
sudo systemctl set-default graphical.target

# Install xrdp for RDP
sudo apt install xrdp -y

# Configure gdm3 to use X11 instead of Wayland
sudo sed -i '/#WaylandEnable=false/s/^#//g' /etc/gdm3/custom.conf || echo "WaylandEnable=false" | sudo tee -a /etc/gdm3/custom.conf

# Configure xrdp to use GNOME desktop
echo -e "export GNOME_SHELL_SESSION_MODE=ubuntu\nexport XDG_CURRENT_DESKTOP=ubuntu:GNOME" | sudo tee -a /etc/xrdp/startwm.sh

# Restart xrdp service
sudo systemctl restart xrdp

echo "GUI and RDP setup complete!"
