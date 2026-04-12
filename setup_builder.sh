#!/bin/bash
set -ex

# 1. Update and install prerequisites
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y git curl wget build-essential python3-pip ubuntu-drivers-common

# 2. Install NVIDIA Driver cleanly
echo "Installing Nvidia Drivers..."
sudo DEBIAN_FRONTEND=noninteractive ubuntu-drivers install --gpgpu

# 3. Install Docker
echo "Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# 4. Install NVIDIA Container Toolkit
echo "Installing Nvidia Container Toolkit..."
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

# 5. Clone Repo and Build Base Image
echo "Cloning Quantum-Safe-CRE Protocol..."
cd /opt
# Clean any previous attempts
sudo rm -rf /opt/repo
sudo git clone https://github.com/vjb/quantum-safe-cre.git repo
cd repo
sudo git checkout feat/gcp-live-compute

echo "Building zkvm-coprocessor Docker Image..."
# We pre-build the Docker natively into the VM so the Cloud Function starts instantaneously!
sudo docker build -t zkvm-coprocessor .

echo "=========================================================================="
echo "✅ HOST SETUP COMPLETE!"
echo "The Nvidia drivers and Docker dependencies are fully injected."
echo "The final `zkvm-coprocessor` container is cached into the local daemon."
echo "You may now safely stop this instance and rip the disk into an image."
echo "=========================================================================="
