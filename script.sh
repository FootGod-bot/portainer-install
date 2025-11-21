#!/bin/bash
set -e

# Ask for the drive to use for Docker containers
read -p "Enter the device for Docker containers (e.g., /dev/sdb): " DOCKER_DRIVE
DOCKER_ROOT="/mnt/docker"
PORTAINER_DATA="/srv/portainer_data"

# Format drive (WARNING: wipes the drive!)
echo "Formatting $DOCKER_DRIVE..."
sudo mkfs.ext4 -F "$DOCKER_DRIVE"

# Create mount point
sudo mkdir -p "$DOCKER_ROOT"

# Mount it
sudo mount "$DOCKER_DRIVE" "$DOCKER_ROOT"

# Add to fstab for persistent mount
grep -q "$DOCKER_DRIVE" /etc/fstab || echo "$DOCKER_DRIVE $DOCKER_ROOT ext4 defaults 0 2" | sudo tee -a /etc/fstab

# Install Docker if missing
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    sudo apt update
    sudo apt install -y docker.io
fi

# Configure Docker data root
sudo mkdir -p /etc/docker
echo "{\"data-root\":\"$DOCKER_ROOT\"}" | sudo tee /etc/docker/daemon.json

# Ensure tmp folder exists for Docker
sudo mkdir -p "$DOCKER_ROOT/tmp"
sudo chown -R root:docker "$DOCKER_ROOT"
sudo chmod 711 "$DOCKER_ROOT/tmp"

# Restart Docker
sudo systemctl enable --now docker

# Prepare Portainer data folder on OS drive
sudo mkdir -p "$PORTAINER_DATA"

# Remove old container if exists
docker rm -f portainer 2>/dev/null || true

# Run Portainer with bind mount to OS drive
docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v "$PORTAINER_DATA":/data \
  portainer/portainer-ce:lts

echo "Portainer installed and running! Access it at https://<your-ip>:9443 or http://<your-ip>:8000"
