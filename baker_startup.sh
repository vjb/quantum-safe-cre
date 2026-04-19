#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y docker.io curl gnupg
apt-get install -y nvidia-driver-535 nvidia-utils-535
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
apt-get update
apt-get install -y nvidia-container-toolkit
nvidia-ctk runtime configure --runtime=docker
systemctl restart docker
gcloud auth configure-docker us-east1-docker.pkg.dev --quiet
docker pull us-east1-docker.pkg.dev/strange-radius-493714-j0/quantum-safe-cre-repo/sp1-prover:latest
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh && sudo bash add-google-cloud-ops-agent-repo.sh --also-install
echo "DOCKER_PULL_SUCCESSFUL"
