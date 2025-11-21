#!/bin/bash
set -e

# Ask for the drive
read -p "Enter the device for Docker containers (e.g., /dev/sdb): " DOCKER_DRIVE
DOCKER_ROOT="/mnt/docker"
PORTAINER_DEFAULT="/srv"

echo "Formatting $DOCKER_DRIVE..."
sudo mkfs.ext4 -F "$DOCKER_DRIVE"

echo "Creating mount point $DOCKER_ROOT..."
sudo mkdir -p "$DOCKER_ROOT"

echo "Mounting $DOCKER_DRIVE at $DOCKER_ROOT..."
sudo mount "$DOCKER_DRIVE" "$DOCKER_ROOT"

# Add to fstab for persistent mount
echo "$DOCKER_DRIVE $DOCKER_ROOT ext4 defaults 0 2" | sudo tee -a /etc/fstab

echo "Installing Docker..."
sudo apt update
sudo apt install -y docker.io

# Configure Docker data root
sudo mkdir -p /etc/docker
echo "{\"data-root\":\"$DOCKER_ROOT\"}" | sudo tee /etc/docker/daemon.json

# Ensure tmp exists
sudo mkdir -p "$DOCKER_ROOT/tmp"
sudo chown -R root:docker "$DOCKER_ROOT"
sudo chmod 711 "$DOCKER_ROOT/tmp"

# Restart Docker
sudo systemctl enable --now docker

# Prepare Portainer default folder
sudo mkdir -p "$PORTAINER_DEFAULT/portainer_data"

# Create Docker volume and run Portainer
docker volume create portainer_data
docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:lts

echo "Done! Docker root is $DOCKER_ROOT, Portainer is running on ports 8000/9443."
