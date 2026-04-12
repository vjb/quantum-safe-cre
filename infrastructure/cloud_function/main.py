import functions_framework
import os
import uuid
from google.cloud import compute_v1

@functions_framework.http
def orchestrate(request):
    request_json = request.get_json(silent=True)
    if not request_json or 'id' not in request_json:
        return {"error": "Missing id"}, 400
        
    job_id = request_json['id']
    project_id = os.environ.get('PROJECT_ID')
    zone = os.environ.get('ZONE')
    target_bucket = os.environ.get('TARGET_BUCKET')
    
    # Deterministic instance name prefix to ensure we dont spin up duplicates for same job
    safe_id = "".join([c for c in job_id.lower() if c.isalnum() or c == '-'])[:30]
    instance_name = f"pqc-prover-{safe_id}"
    
    startup_script = f"""#!/bin/bash
set -e
exec > >(tee -a /var/log/sp1-startup.log) 2>&1

BUCKET_PATH="gs://{target_bucket}/{job_id}"

echo "Starting Orchestration..."
# Fetch dynamic intent
gsutil cp $BUCKET_PATH/intent.json /opt/repo/1-client/intent.json || echo "No custom intent passed."

# Boot docker process natively using the baked image
cd /opt/repo

# Start the ZK VM natively
sudo docker run --rm --gpus all \\
    -v /var/run/docker.sock:/var/run/docker.sock \\
    -v /tmp:/tmp \\
    -v "$(pwd):/app/output" \\
    -v "$(pwd)/1-client/intent.json:/app/1-client/intent.json" \\
    zkvm-coprocessor

# Upload output to bucket
gsutil cp proof.json $BUCKET_PATH/proof.json
gsutil cp /var/log/sp1-startup.log $BUCKET_PATH/sp1-node.log

echo "Terminating Node securely..."
sleep 5
gcloud compute instances delete {instance_name} --zone {zone} --quiet
"""

    client = compute_v1.InstancesClient()
    
    zones_to_try = [zone, "us-central1-a", "us-east1-c", "us-east1-d", "us-west1-b", "us-east4-b", "us-east4-c"]
    
    for z in zones_to_try:
        try:
            instance = compute_v1.Instance(
                name=instance_name,
                machine_type=f"zones/{z}/machineTypes/g2-standard-4",
                scheduling=compute_v1.Scheduling(
                    provisioning_model="SPOT",
                    instance_termination_action="DELETE"
                ),
                disks=[
                    compute_v1.AttachedDisk(
                        boot=True,
                        auto_delete=True,
                        initialize_params=compute_v1.AttachedDiskInitializeParams(
                            source_image=f"projects/{project_id}/global/images/pqc-sp1-base",
                            disk_size_gb=200,
                            disk_type=f"zones/{z}/diskTypes/pd-ssd"
                        )
                    )
                ],
                guest_accelerators=[
                    compute_v1.AcceleratorConfig(
                        accelerator_type=f"zones/{z}/acceleratorTypes/nvidia-l4",
                        accelerator_count=1
                    )
                ],
                network_interfaces=[
                    compute_v1.NetworkInterface(
                        access_configs=[compute_v1.AccessConfig(
                            name="External NAT",
                            type_="ONE_TO_ONE_NAT"
                        )]
                    )
                ],
                service_accounts=[
                    compute_v1.ServiceAccount(
                        email="default",
                        scopes=["https://www.googleapis.com/auth/cloud-platform"]
                    )
                ],
                metadata=compute_v1.Metadata(
                    items=[compute_v1.Items(
                        key="startup-script",
                        value=startup_script.replace("{zone}", z).replace("{instance_name}", instance_name)
                    )]
                )
            )
            
            operation = client.insert(project=project_id, zone=z, instance_resource=instance)
            return {"jobRunID": job_id, "instance_name": instance_name, "status": "provisioning", "zone": z}, 200
            
        except Exception as e:
            err_msg = str(e).lower()
            if "already exists" in err_msg:
                return {"jobRunID": job_id, "instance_name": instance_name, "status": "already running or artifact exists"}, 200
            elif "zone_resource_pool_exhausted" in err_msg or "does not have enough resources" in err_msg or "not found" in err_msg:
                print(f"Warning: Zone {z} failed ({err_msg[:40]}). Trying next zone...")
                continue
            else:
                print(f"Error provisioning spot instance in {z}: {e}")
                return {"error": str(e)}, 500

    return {"error": "ZONE_RESOURCE_POOL_EXHAUSTED across all configured regions. No Spot G2 availability."}, 500
