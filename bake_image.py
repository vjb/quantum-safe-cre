import time
import subprocess

PROJECT = "strange-radius-493714-j0"
ZONE = "us-east1-d"
BAKER_VM = "sp1-baker"
IMAGE_NAME = "sp1-prover-image"

def run(cmd):
    print(f"Executing: {cmd}")
    subprocess.run(cmd, shell=True, check=True)

startup_script = """#!/bin/bash
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
"""
with open("baker_startup.sh", "w") as f:
    f.write(startup_script)

run(f"gcloud compute instances create {BAKER_VM} --project={PROJECT} --zone={ZONE} --machine-type=e2-standard-4 --image-project=ubuntu-os-cloud --image-family=ubuntu-2204-lts --boot-disk-size=100GB --metadata-from-file=startup-script=baker_startup.sh --scopes=https://www.googleapis.com/auth/cloud-platform")

print("[2/5] Waiting for Docker Pull...")
while True:
    res = subprocess.run(f"gcloud compute instances get-serial-port-output {BAKER_VM} --project={PROJECT} --zone={ZONE}", shell=True, capture_output=True, text=True)
    if "DOCKER_PULL_SUCCESSFUL" in res.stdout:
        print("Docker pull complete!")
        break
    time.sleep(30)

print("[3/5] Stopping VM...")
run(f"gcloud compute instances stop {BAKER_VM} --project={PROJECT} --zone={ZONE}")

print("[4/5] Creating Machine Image...")
subprocess.run(f"gcloud compute images delete {IMAGE_NAME} --project={PROJECT} --quiet", shell=True)
run(f"gcloud compute images create {IMAGE_NAME} --project={PROJECT} --source-disk={BAKER_VM} --source-disk-zone={ZONE}")

print("[5/5] Cleaning up...")
run(f"gcloud compute instances delete {BAKER_VM} --project={PROJECT} --zone={ZONE} --quiet")
print("Baking Complete!")
