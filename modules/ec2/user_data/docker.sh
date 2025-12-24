#!/bin/bash
set -e

# Update system
apt-get update -y
apt-get install -y ca-certificates curl gnupg lsb-release

# Create keyrings directory
install -m 0755 -d /etc/apt/keyrings

# Add Docker GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  -o /etc/apt/keyrings/docker.asc

chmod a+r /etc/apt/keyrings/docker.asc

# Add Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" \
  > /etc/apt/sources.list.d/docker.list

# Install Docker
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start & enable Docker
systemctl enable docker
systemctl start docker

# Allow ubuntu user to run docker
usermod -aG docker ubuntu

# allow docker without sudo
chmod 666 /var/run/docker.sock
