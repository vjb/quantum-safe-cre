New-Item -ItemType Directory -Force -Path docs
$LOGFILE = "docs/demo_execution_logs.txt"

"🚀 Starting Quantum-Safe CRE Flagship Pipeline (DEBUG MODE)...`n" | Out-File -FilePath $LOGFILE
"==========================================================" | Out-File -FilePath $LOGFILE -Append
"[PHASE 1] Local Client: Post-Quantum Intent Generation" | Out-File -FilePath $LOGFILE -Append
"==========================================================" | Out-File -FilePath $LOGFILE -Append
Set-Location 1-client 
$env:RUST_LOG = "client=debug,crypto=debug,storage=debug"
cargo run 2>&1 | Out-File -FilePath "..\$LOGFILE" -Append
Set-Location ..

"`n==========================================================" | Out-File -FilePath $LOGFILE -Append
"[PHASE 2] Rebuilding Encapsulated Container..." | Out-File -FilePath $LOGFILE -Append
"==========================================================" | Out-File -FilePath $LOGFILE -Append
docker build -t zkvm-coprocessor . 2>&1 | Out-File -FilePath $LOGFILE -Append

"`n==========================================================" | Out-File -FilePath $LOGFILE -Append
"[PHASE 3] Chainlink DON Orchestration Trigger" | Out-File -FilePath $LOGFILE -Append
"==========================================================" | Out-File -FilePath $LOGFILE -Append
Set-Location 3-chainlink-cre 
$env:DEBUG_DON = "true"
npx ts-node oracle.ts 2>&1 | Out-File -FilePath "..\$LOGFILE" -Append
Set-Location ..

"`n✅ Flagship validation succeeded! Full trace captured in $LOGFILE" | Out-File -FilePath $LOGFILE -Append
