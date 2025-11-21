#!/bin/bash
set -e

echo "==> Installing Docker"
sudo apt update
sudo apt install docker.io -y
echo "==> Listing available drives:"
lsblk

# Prompt user for drive
read -p "Please enter the code for the drive to use for Docker (e.g., sdb): " DOCKER_DRIVE
DOCKER_MOUNT="/mnt/docker"


# Confirm choice
echo "Using /dev/$DOCKER_DRIVE for Docker root at $DOCKER_MOUNT"
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
sudo systemctl daemon-reload

echo "==> Setting up Portainer"
docker volume create portainer_data
docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:lts

echo "==> Setting Docker root to $DOCKER_MOUNT"
sudo sh -c "echo '{
  \"data-root\": \"$DOCKER_MOUNT\"
}' > /etc/docker/daemon.json"


# Restart Docker
sudo systemctl restart docker
echo "Docker root is now: $(docker info | grep 'Docker Root Dir')"

echo "==> Setting up Portainer"
docker volume create portainer_data
docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:lts

echo "==> Setup complete!"
echo "Portainer data: $PORTAINER_DATA"
echo "Docker containers/images: $DOCKER_MOUNT"
echo "Visit https://$(hostname -I | awk '{print $1}'):9443 to configure the web ui"
