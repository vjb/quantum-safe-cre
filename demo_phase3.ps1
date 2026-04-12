$jobRunId = "demo-" + -join ((48..57) + (97..122) | Get-Random -Count 6 | % {[char]$_})
$cleanJobId = $jobRunId -replace '[^a-z0-9]', ''
$vmName = "pqc-prover-" + $cleanJobId.Substring(0, [math]::Min(30, $cleanJobId.Length))

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "🚀 Launching Live E2E Serverless Trace: $jobRunId" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "1. Firing Webhook directly into Cloud Run API Proxy..." -ForegroundColor Yellow

$token = (gcloud auth print-identity-token).Trim()
$url = "https://pqc-orchestrator-proxy-ceh7ombilq-uc.a.run.app/prove"

$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type"  = "application/json"
}
$bodyObj = @{
    id = $jobRunId
    data = @{}
}
$bodyJSON = $bodyObj | ConvertTo-Json -Depth 5 -Compress

try {
    $response = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $bodyJSON -ErrorAction Stop
    Write-Host "Proxy Response: " ($response | ConvertTo-Json -Compress) -ForegroundColor Green
} catch {
    Write-Host "❌ FATAL PROXY ERROR: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "2. Actively polling Google Compute Engine to bind against the Ephemeral Instance..." -ForegroundColor Yellow

$vmFound = $false
$retryCount = 0

while (-not $vmFound -and $retryCount -lt 15) {
    Start-Sleep -Seconds 6
    
    # Actively probe the exact zone directly bypassing any global indexing caching delays
    $probe = gcloud compute instances describe $vmName --zone=us-central1-a --project=total-velocity-493022-f0 --format="value(name)" 2>&1
    
    if ($probe -match $vmName) {
        $vmFound = $true
        Write-Host "🟢 Lock established! Hardware instance '$vmName' successfully matched in physical zone." -ForegroundColor Green
    } else {
        $retryCount++
        Write-Host "   [Probe $retryCount/15] Hardware provisioning asynchronously... retrying." -ForegroundColor DarkGray
    }
}

if (-not $vmFound) {
    Write-Host "❌ FATAL GCP ERROR: The VM '$vmName' exhausted the 90-second provisioning limit constraint!" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "3. Tailing Live Execution Logs (Will continuously stream across GCP until VM self-destructs...)" -ForegroundColor Yellow
gcloud compute instances tail-serial-port-output $vmName --zone=us-central1-a --project=total-velocity-493022-f0

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "🟢 OS Terminated securely! Spot Pipeline cleanly decoupled." -ForegroundColor Yellow
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "4. Reading Isolated proof.json blob from Google Cloud Storage..." -ForegroundColor Yellow

$bucketPath = "gs://chainlink-pqc-proofs/$jobRunId/proof.json"
Write-Host "Extraction Target: $bucketPath" -ForegroundColor DarkGray

try {
    $proofOutput = gsutil cat $bucketPath 2>&1
    Write-Host $proofOutput -ForegroundColor Magenta
    
    if ($proofOutput -match "CommandException") {
        Write-Host "❌ FATAL GCS ERROR: Proof blob was not detected natively. Execution failed." -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ FATAL GCS ERROR: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🎉 DEMO SUCCESS! Complete ZK Architecture strictly decoupled without leaking idle compute!" -ForegroundColor Green
