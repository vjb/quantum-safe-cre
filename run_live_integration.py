import os
import sys
import sys
import time
import json
import subprocess

def run_cmd(cmd, cwd=None, capture=False):
    print(f"[EXEC] {' '.join(cmd)}")
    if capture:
        result = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, shell=True)
        if result.returncode != 0:
            print(f"[ERROR] Command failed: {result.stderr}")
            sys.exit(1)
        return result.stdout.strip()
    else:
        result = subprocess.run(cmd, cwd=cwd, shell=True)
        if result.returncode != 0:
            print(f"[ERROR] Command failed with exit code {result.returncode}")
            sys.exit(1)

def submit_gcp_compute_job(project_id, job_id, image_name):
    zones_to_try = [
        "us-central1-a", "us-central1-b", "us-central1-c", "us-central1-f",
        "us-east4-a", "us-east4-b", "us-east4-c",
        "us-east1-b", "us-east1-c", "us-east1-d"
    ]

    success = False
    for z in zones_to_try:
        startup_script = f"""#!/bin/bash
docker run --rm --gpus all us-east1-docker.pkg.dev/{project_id}/quantum-safe-cre-repo/sp1-prover:latest /bin/sh -c 'zkvm-script && gsutil cp /app/2-sp1-coprocessor/script/proof.json gs://quantum-safe-cre-proofs/proof.json'
gcloud compute instances delete {job_id} --zone={z} --quiet
"""
        script_path = f"startup_{job_id}.sh"
        with open(script_path, "w") as f:
            f.write(startup_script)

        print(f"\n[INFO] Attempting to ignite Pre-baked VM in zone {z}...")
        cmd = [
            "gcloud", "compute", "instances", "create", job_id,
            f"--project={project_id}", f"--zone={z}",
            "--machine-type=g2-standard-16",
            f"--image={image_name}",
            "--accelerator=type=nvidia-l4,count=1",
            "--maintenance-policy=TERMINATE",
            f"--metadata-from-file=startup-script={script_path}",
            "--scopes=https://www.googleapis.com/auth/cloud-platform"
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True, shell=True)
        if result.returncode == 0:
            print(f"[SUCCESS] VM successfully ignited in {z}!")
            success = True
            break
        else:
            if "STOCKOUT" in result.stderr:
                print(f"[WARNING] L4 GPU Stockout in {z}. Trying next zone...")
            else:
                print(f"[ERROR] Failed to create VM in {z}: {result.stderr}")
                break

    os.remove(script_path)
    if not success:
        print("[ERROR] Exhausted all zones. Total L4 GPU stockout across US regions.")
        sys.exit(1)

def poll_gcs_for_proof(gcs_bucket):
    print(f"[INFO] Polling gs://{gcs_bucket}/proof.json for STARK execution completion...")
    start_time = time.time()
    
    while True:
        res = subprocess.run(f"gsutil stat gs://{gcs_bucket}/proof.json", shell=True, capture_output=True, text=True)
        if res.returncode == 0:
            elapsed = time.time() - start_time
            print(f"[SUCCESS] Proof materialized in GCS bucket in {elapsed:.2f} seconds!")
            break
        
        time.sleep(10)

def main():
    print("[INFO] Commencing live integration pipeline (Accelerated Machine Image Edition).")

    from dotenv import load_dotenv
    load_dotenv('.env')

    # Dependencies check
    run_cmd(["cmd.exe", "/c", "cast --version"], capture=True)
    
    job_id = f"sp1-prover-{int(time.time())}"
    intent_file = "1-client/intent.json"
    gcp_project = os.environ.get("GCP_PROJECT_ID", "strange-radius-493714-j0")
    gcs_bucket = os.environ.get("GCS_BUCKET_NAME", "quantum-safe-cre-proofs")
    image_name = "sp1-prover-image"

    # Phase 1: Intent
    print("[INFO] Generating ML-DSA post-quantum signature.")
    run_cmd(["cargo", "run", "--release", "--", "--out", f"../{intent_file}"], cwd="1-client")
    
    if not os.path.exists(intent_file):
        print(f"[ERROR] Intent generation failed. Expected output at {intent_file}.")
        sys.exit(1)

    # Phase 2: Compute
    print("[INFO] Uploading intent payload to Cloud Storage buffer.")
    run_cmd(["cmd.exe", "/c", f"gsutil cp {intent_file} gs://{gcs_bucket}/intents/intent_{job_id}.json"])

    # Clean previous proof so polling is accurate
    subprocess.run(f"gsutil rm gs://{gcs_bucket}/proof.json", shell=True, capture_output=True)

    # Ignite the Pre-baked VM
    submit_gcp_compute_job(gcp_project, job_id, image_name)
    
    # Poll for completion
    poll_gcs_for_proof(gcs_bucket)

    # Phase 3: Downstream Smart Contract Integration (CCIP)
    print("\n[INFO] ----------------------------------------------------")
    print("[INFO] Phase 3: Verifying STARK on Base Sepolia and triggering CCIP")
    print("[INFO] ----------------------------------------------------")
    
    # Download the proof payload
    run_cmd(["cmd.exe", "/c", f"gsutil cp gs://{gcs_bucket}/proof.json proof_downloaded.json"])
    
    with open("proof_downloaded.json", "r") as f:
        proof_data = json.load(f)
    
    proof_bytes = proof_data["proofBytes"]
    public_values = proof_data["publicValues"]

    # Extract private key from the vault environment
    private_key = None
    if os.path.exists("4-base-sepolia-vault/.env"):
        with open("4-base-sepolia-vault/.env", "r") as f:
            for line in f:
                if line.startswith("PRIVATE_KEY="):
                    private_key = line.split("=")[1].strip().strip('"\'')
                    break
    
    if not private_key:
        print("[ERROR] PRIVATE_KEY missing from 4-base-sepolia-vault/.env")
        sys.exit(1)

    print(f"[INFO] Delegating to Viem Relayer for L2 Vault Broadcasting...")
    
    # Execute Viem broadcasting script
    run_cmd(["cmd.exe", "/c", "npx", "ts-node", "3-execution-relayer/broadcast_proof.ts"])
    
    print("\n[SUCCESS] POST-QUANTUM SETTLEMENT COMPLETE ON L2!")
    print("[SUCCESS] Transaction successfully verified by SP1 and routed via Chainlink CCIP.")

if __name__ == "__main__":
    main()
