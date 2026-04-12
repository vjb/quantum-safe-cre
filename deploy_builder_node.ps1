$ErrorActionPreference = "Stop"

$PROJECT_ID = "total-velocity-493022-f0"
$ZONE = "us-east4-a"
$INSTANCE_NAME = "pqc-image-builder-node"
$MACHINE_TYPE = "g2-standard-4"

Write-Host "[INFO] Provisioning a dedicated STANDARD (non-spot) G2 instance for stable image baking..." -ForegroundColor Cyan

gcloud compute instances create $INSTANCE_NAME `
    --project=$PROJECT_ID `
    --zone=$ZONE `
    --machine-type=$MACHINE_TYPE `
    --boot-disk-type=pd-ssd `
    --image-family=ubuntu-2204-lts `
    --image-project=ubuntu-os-cloud `
    --boot-disk-size=200GB `
    --maintenance-policy=TERMINATE `
    --quiet

if ($LASTEXITCODE -ne 0) {
    Write-Host "`n[ERROR] Failed to provision dedicated builder node (Check quota or zone availability)." -ForegroundColor Red
    exit 1
}

Write-Host "`n[SUCCESS] Dedicated Builder Node ($INSTANCE_NAME) is definitively online and stable." -ForegroundColor Green
Write-Host "`n[ACTION REQUIRED] SSH into the instance to install CUDA, Docker, and the SP1 dependencies:" -ForegroundColor Yellow
Write-Host "    gcloud compute ssh $INSTANCE_NAME --zone=$ZONE --project=$PROJECT_ID"

Write-Host "`n[ACTION REQUIRED] Once your environment is fully configured, explicitly stop the node and RIP THE IMAGE:" -ForegroundColor Yellow
Write-Host "    gcloud compute instances stop $INSTANCE_NAME --zone=$ZONE --project=$PROJECT_ID"
Write-Host "    gcloud compute images create pqc-sp1-base-v2 --source-disk=$INSTANCE_NAME --source-disk-zone=$ZONE --family=pqc-sp1 --project=$PROJECT_ID"

Write-Host "`n[INFO] Don't forget to delete the builder node post-rip to save on billing!"
Write-Host "    gcloud compute instances delete $INSTANCE_NAME --zone=$ZONE --project=$PROJECT_ID"
