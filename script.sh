#!/bin/bash
set -e

echo "==> Listing available drives:"
lsblk

# Prompt user for drive
read -p "Please enter the code for the drive to use for Docker (e.g., sdb): " DOCKER_DRIVE
DOCKER_MOUNT="/mnt/docker"
PORTAINER_DATA="/srv/portainer"

# Confirm choice
echo "Using $DOCKER_DRIVE for Docker root at $DOCKER_MOUNT"
read -p "Continue? (y/n): " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo "Aborting."
    exit 1
fi

# Format the drive (WARNING: will erase everything!)
echo "==> Formatting /dev/$DOCKER_DRIVE..."
sudo mkfs.ext4 -F "/dev/$DOCKER_DRIVE"

# Create mount point
sudo mkdir -p "$DOCKER_MOUNT"

# Mount it
sudo mount "/dev/$DOCKER_DRIVE" "$DOCKER_MOUNT"

# Make permanent in fstab
grep -q "/dev/$DOCKER_DRIVE" /etc/fstab || echo "/dev/$DOCKER_DRIVE $DOCKER_MOUNT ext4 defaults 0 2" | sudo tee -a /etc/fstab

echo "==> Setting Docker root to $DOCKER_MOUNT"
sudo mkdir -p /etc/docker
cat | sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "data-root": "$DOCKER_MOUNT"
}
EOF

# Restart Docker
sudo systemctl restart docker
echo "Docker root is now: $(docker info | grep 'Docker Root Dir')"

# Setup Portainer
echo "==> Setting up Portainer on OS drive at $PORTAINER_DATA"
sudo mkdir -p "$PORTAINER_DATA"

# Stop/remove existing Portainer if present
if docker ps -a --format '{{.Names}}' | grep -q '^portainer$'; then
    docker stop portainer
    docker rm portainer
fi

# Run Portainer
docker run -d -p 9000:9000 --name portainer \
    --restart=always \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "$PORTAINER_DATA":/data \
    portainer/portainer-ce

echo "==> Setup complete!"
echo "Portainer data: $PORTAINER_DATA"
echo "Docker containers/images: $DOCKER_MOUNT"
