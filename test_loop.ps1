docker stop test-container 2>$null
docker rm test-container 2>$null

Write-Host "Running SP1 ZK-Coprocessor without --rm to capture Exit Code..."
docker run --name test-container -v "${PWD}:/app/output" -v "${PWD}/1-client/intent.json:/app/1-client/intent.json" zkvm-coprocessor
$exitCode = $LASTEXITCODE

Write-Host "Exit Code: $exitCode"
$oomKilled = docker inspect test-container --format '{{.State.OOMKilled}}'
Write-Host "OOM Killed: $oomKilled"
$errorState = docker inspect test-container --format '{{.State.Error}}'
Write-Host "Docker Engine Error: $errorState"

if ($exitCode -eq 137 -or $oomKilled -eq 'true') {
    Write-Host "CONFIRMED: The process ran out of memory and was killed by the Kernel."
}
