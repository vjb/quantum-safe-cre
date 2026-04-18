$ErrorActionPreference = "Stop"

Write-Host "Fetching most recent Warning and Error logs from GCP Cloud Logging natively..." -ForegroundColor Cyan

# Fetches the last 20 WARNING or ERROR severity items from your default GCP project organically
try {
    $oneHourAgo = (Get-Date).AddHours(-1).ToString("yyyy-MM-ddTHH:mm:ssZ")
    gcloud.cmd logging read "severity>=WARNING AND timestamp>=\`"$oneHourAgo\`"" --limit=20 --format="table(timestamp,severity,protoPayload.status.message,textPayload)"
} catch {
    Write-Host "No severe logs detected recently or gcloud logging read natively restricted." -ForegroundColor Green
}
