<#
.SYNOPSIS
Deploys an ephemeral GCP Spot Instance, generates the SP1 Plonk Matrix natively, downloads the exported proof.json, and instantly destroys the VM to minimize billing.

.DESCRIPTION
This script fully automates your remote SP1 architecture, preventing local OOM constraints by migrating the mathematics to a Google Cloud Compute engine.

#>

$ErrorActionPreference = "Stop"

$PROJECT_ID = "centering-helix-493023-f7" # Your currently authenticated GCP project
$ZONE = "us-central1-c"
$INSTANCE_NAME = "zkvm-prover-spot-instance"
$MACHINE_TYPE = "n2-highmem-32" # 32 Cores / 256GB RAM. Retains identical memory footprint while cutting CPU utilization in half to bypass DataCenter Stockouts.

Write-Host "🚀 [1/5] Initiating Google Cloud Ephemeral Orchestration..." -ForegroundColor Cyan
Write-Host "Project: $PROJECT_ID | Zone: $ZONE" -ForegroundColor DarkGray

# 1. Ensure GCP Compute API is enabled
Write-Host "`n⚙️ Confirming Compute Engine APIs are bound..." -ForegroundColor Yellow
gcloud services enable compute.googleapis.com --project=$PROJECT_ID --quiet

# 2. Spin up Spot Instance
Write-Host "`n☁️ [2/5] Provisioning $MACHINE_TYPE Instance ($INSTANCE_NAME)..." -ForegroundColor Cyan
gcloud compute instances create $INSTANCE_NAME `
    --project=$PROJECT_ID `
    --zone=$ZONE `
    --machine-type=$MACHINE_TYPE `
    --preemptible `
    --image-family=ubuntu-2204-lts `
    --image-project=ubuntu-os-cloud `
    --boot-disk-size=100GB `
    --quiet

if ($LASTEXITCODE -ne 0) {
    Write-Host "`n❌ [FATAL ERROR] GCP DataCenter threw a Stockout limit. Terminal Execution aborted cleanly." -ForegroundColor Red
    exit 1
}

Write-Host "`n⏳ Waiting 45 seconds for Ubuntu SSH Daemon to boot successfully..." -ForegroundColor DarkGray
Start-Sleep -Seconds 45

# 3. Securely Execute Orchestration Pipeline
Write-Host "`n🔥 [3/5] Compacting Framework and Bounding ZK Proof (This may take 4-8 minutes)..." -ForegroundColor Cyan
$REMOTE_COMMAND = "git clone https://github.com/vjb/quantum-safe-cre.git && cd quantum-safe-cre && chmod +x gcp_execute.sh && bash gcp_execute.sh"
gcloud compute ssh $INSTANCE_NAME `
    --project=$PROJECT_ID `
    --zone=$ZONE `
    --strict-host-key-checking=no `
    --command=$REMOTE_COMMAND `
    --quiet

# 4. Pull Artifact Locally
Write-Host "`n📥 [4/5] Extracting proof.json Plonk matrix to your local workspace..." -ForegroundColor Cyan
gcloud compute scp "$($INSTANCE_NAME):~/quantum-safe-cre/proof.json" "./proof.json" `
    --project=$PROJECT_ID `
    --zone=$ZONE `
    --strict-host-key-checking=no `
    --quiet

# 5. Terminate Host
Write-Host "`n💥 [5/5] Terminating Google Cloud instance securely to freeze billing..." -ForegroundColor Red
gcloud compute instances delete $INSTANCE_NAME `
    --project=$PROJECT_ID `
    --zone=$ZONE `
    --quiet


Write-Host "`n✅ Pipeline Exited Successfully! The 'proof.json' artifact is mathematically bound and native to your CWD." -ForegroundColor Green
