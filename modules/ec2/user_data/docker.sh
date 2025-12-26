#!/bin/bash
set -e

########################################
# LOG EVERYTHING (VERY IMPORTANT)
########################################
exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

echo "===== USER DATA STARTED ====="

########################################
# SYSTEM UPDATE & BASE PACKAGES
########################################
apt-get update -y
apt-get install -y \
  ca-certificates \
  curl \
  gnupg \
  lsb-release \
  unzip

########################################
# INSTALL DOCKER
########################################
echo "Installing Docker..."

install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" \
  > /etc/apt/sources.list.d/docker.list

apt-get update -y
apt-get install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

systemctl enable docker
systemctl start docker

usermod -aG docker ubuntu
chmod 666 /var/run/docker.sock

echo "Docker installed successfully"

########################################
# IMDSv2 – FETCH IAM INFO (SAFE WAY)
########################################
echo "Fetching IMDSv2 token..."

TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

echo "IAM Info:"
curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/iam/info || true

########################################
# INSTALL CODEDEPLOY AGENT (ap-south-1)
########################################
apt-get install -y ruby
echo "Installing CodeDeploy agent..."

cd /tmp
wget -q https://aws-codedeploy-ap-south-1.s3.ap-south-1.amazonaws.com/latest/install \
  -O codedeploy-install

chmod +x codedeploy-install
./codedeploy-install auto

systemctl daemon-reload
systemctl enable codedeploy-agent
systemctl start codedeploy-agent

########################################
# INSTALL AWS CLI v2
########################################
echo "Installing AWS CLI v2..."

cd /tmp
curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o awscliv2.zip
unzip -q awscliv2.zip
./aws/install

########################################
# VERIFY INSTALLATIONS
########################################
docker --version
aws --version
systemctl status codedeploy-agent --no-pager || true

echo "===== USER DATA COMPLETED SUCCESSFULLY ====="
