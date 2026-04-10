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
RUST_LOG=client=debug,crypto=debug,storage=debug cargo run 2>&1 | tee -a ../$LOGFILE
cd ..

echo "" | tee -a $LOGFILE
echo "==========================================================" | tee -a $LOGFILE
echo "[PHASE 2] Docker execution bounding" | tee -a $LOGFILE
echo "==========================================================" | tee -a $LOGFILE
if [[ "$(docker images -q zkvm-coprocessor 2> /dev/null)" == "" ]]; then
  echo "Building Encapsulated Container since it does not exist..." | tee -a $LOGFILE
  docker build -t zkvm-coprocessor . 2>&1 | tee -a $LOGFILE
else
  echo "zkvm-coprocessor image already found. Bypassing redundant build logic." | tee -a $LOGFILE
fi

echo "" | tee -a $LOGFILE
echo "==========================================================" | tee -a $LOGFILE
echo "[PHASE 3 & 4] Chainlink DON Orchestration and Live Settlement" | tee -a $LOGFILE
echo "==========================================================" | tee -a $LOGFILE
cd 3-chainlink-cre 
DEBUG_DON=true npx ts-node oracle.ts 2>&1 | tee -a ../$LOGFILE
cd ..

echo "" | tee -a $LOGFILE
echo "✅ Flagship validation succeeded! Full trace captured in $LOGFILE" | tee -a $LOGFILE
