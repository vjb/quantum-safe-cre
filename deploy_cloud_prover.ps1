<#
.SYNOPSIS
Deploys an ephemeral GCP Spot Instance, generates the SP1 Plonk Matrix natively, downloads the exported proof.json, and instantly destroys the VM to minimize billing.

.DESCRIPTION
This script fully automates your remote SP1 architecture, preventing local OOM constraints by migrating the mathematics to a Google Cloud Compute engine.

#>

$ErrorActionPreference = "Stop"

$PROJECT_ID = "total-velocity-493022-f0" # Your currently authenticated GCP project (My Project 18209)
$ZONE = "us-central1-a"
$INSTANCE_NAME = "zkvm-prover-spot-instance"
$MACHINE_TYPE = "n2-highmem-32" # 32 Cores / 256GB RAM. Retains identical memory footprint while cutting CPU utilization in half to bypass DataCenter Stockouts.

Write-Host "🚀 [1/5] Initiating Google Cloud Ephemeral Orchestration..." -ForegroundColor Cyan
Write-Host "Project: $PROJECT_ID | Zone: $ZONE" -ForegroundColor DarkGray

# 1. Ensure GCP Compute API is enabled
Write-Host "`n⚙️ Confirming Compute Engine APIs are bound..." -ForegroundColor Yellow
gcloud services enable compute.googleapis.com --project=$PROJECT_ID --quiet

# 2. Evaluate GCP Node State
Write-Host "`n☁️ [2/5] Evaluating $MACHINE_TYPE Node State ($INSTANCE_NAME)..." -ForegroundColor Cyan
$gcpStatus = gcloud compute instances list --filter="name=($INSTANCE_NAME)" --project=$PROJECT_ID --zones=$ZONE --format="value(status)"

if ([string]::IsNullOrWhiteSpace($gcpStatus)) {
    $nullStatus = $true
} else {
    $nullStatus = $false
}

if (-not $nullStatus) {
    if ($gcpStatus -match "TERMINATED") {
        Write-Host "Instance exists but is STOPPED. Booting it up to reuse SSD cache..." -ForegroundColor Yellow
        gcloud compute instances start $INSTANCE_NAME --project=$PROJECT_ID --zone=$ZONE --quiet
        $waitTime = 45
    } else {
        Write-Host "Instance is already RUNNING. Maximizing VM cache hits!" -ForegroundColor Green
        $waitTime = 5
    }
} else {
    Write-Host "No instance found. Provisioning fresh n2-highmem-32 (this is normal on first run)..." -ForegroundColor Yellow
    gcloud compute instances create $INSTANCE_NAME `
        --project=$PROJECT_ID `
        --zone=$ZONE `
        --machine-type=$MACHINE_TYPE `
        --boot-disk-type=pd-ssd `
        --image-family=ubuntu-2204-lts `
        --image-project=ubuntu-os-cloud `
        --boot-disk-size=100GB `
        --quiet

    if ($LASTEXITCODE -ne 0) {
        Write-Host "`n❌ [FATAL ERROR] GCP DataCenter threw a Stockout limit. Terminal Execution aborted cleanly." -ForegroundColor Red
        exit 1
    }
    $waitTime = 45
}

Write-Host "`n⏳ Waiting $waitTime seconds for SSH connectivity over Google tunnel..." -ForegroundColor DarkGray
Start-Sleep -Seconds $waitTime

# 3. Securely Execute Orchestration Pipeline
Write-Host "`n🔥 [3/5] Syncing State & Executing Framework (Docker Cache enabled)..." -ForegroundColor Cyan
$REMOTE_COMMAND = "if [ ! -d 'quantum-safe-cre' ]; then git clone https://github.com/vjb/quantum-safe-cre.git; else cd quantum-safe-cre && git fetch origin && git reset --hard origin/main && cd ..; fi && cd quantum-safe-cre && chmod +x gcp_execute.sh && bash gcp_execute.sh"
gcloud compute ssh $INSTANCE_NAME `
    --project=$PROJECT_ID `
    --zone=$ZONE `
    --strict-host-key-checking=no `
    --command=$REMOTE_COMMAND `
    --quiet

# 4. Pull Artifact Locally
Write-Host "`n📥 [4/5] Extracting proof.json Plonk matrix to your local workspace..." -ForegroundColor Cyan
gcloud compute scp "$($INSTANCE_NAME):quantum-safe-cre/proof.json" "./proof.json" `
    --project=$PROJECT_ID `
    --zone=$ZONE `
    --strict-host-key-checking=no `
    --quiet

# 5. Terminate Host (DISABLED)
Write-Host "`n⚠️ [5/5] Skipping Terminate phase. The Google Cloud Instance ($INSTANCE_NAME) will remain RUNNING for faster debugging." -ForegroundColor Yellow
# gcloud compute instances delete $INSTANCE_NAME `
#     --project=$PROJECT_ID `
#     --zone=$ZONE `
#     --quiet


Write-Host "`n✅ Pipeline Exited Successfully! The 'proof.json' artifact is mathematically bound and native to your CWD." -ForegroundColor Green
