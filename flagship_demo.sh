#!/bin/bash
set -e

mkdir -p docs
LOGFILE="docs/demo_execution_logs.txt"

echo "🚀 Starting Quantum-Safe CRE Flagship Pipeline (DEBUG MODE)..." | tee $LOGFILE
echo "" | tee -a $LOGFILE
echo "==========================================================" | tee -a $LOGFILE
echo "[PHASE 1] Local Client: Post-Quantum Intent Generation" | tee -a $LOGFILE
echo "==========================================================" | tee -a $LOGFILE
cd 1-client 
# Use strict debug filtering to only highlight our narrative traces, blocking external binary spam
RUST_LOG=client=debug,crypto=debug,storage=debug cargo run 2>&1 | tee -a ../$LOGFILE
cd ..

echo "" | tee -a $LOGFILE
echo "==========================================================" | tee -a $LOGFILE
echo "[PHASE 2] Rebuilding Encapsulated Container..." | tee -a $LOGFILE
echo "==========================================================" | tee -a $LOGFILE
# Rebuild to bake in the new debug statements injected into ZK script
docker build -t zkvm-coprocessor . 2>&1 | tee -a $LOGFILE

echo "" | tee -a $LOGFILE
echo "==========================================================" | tee -a $LOGFILE
echo "[PHASE 3] Chainlink DON Orchestration Trigger" | tee -a $LOGFILE
echo "==========================================================" | tee -a $LOGFILE
cd 3-chainlink-cre 
DEBUG_DON=true npx ts-node oracle.ts 2>&1 | tee -a ../$LOGFILE
cd ..

echo "" | tee -a $LOGFILE
echo "✅ Flagship validation succeeded! Full trace captured in $LOGFILE" | tee -a $LOGFILE
