#!/bin/bash
set -e
echo "🚀 Starting Quantum-Safe CRE E2E Pipeline..."

echo -e "\n[1/3] Generating User Intent..."
cd 1-client && cargo run && cd ..

echo -e "\n[2/3] Building ZKVM Docker Coprocessor..."
docker build -t zkvm-coprocessor .

echo -e "\n[3/3] Simulating Chainlink DON Consensus..."
cd 3-chainlink-cre && npx ts-node oracle.ts

echo -e "\n✅ E2E PIPELINE SUCCESSFUL. STARK PROOF VERIFIED."
