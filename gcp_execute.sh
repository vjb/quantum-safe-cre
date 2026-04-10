#!/bin/bash
set -e

echo "🚀 Booting Quantum-Safe CRE GCP STARK Generator..."

# 1. System Dependencies (Assuming Ubuntu/Debian)
echo "Installing prerequisites (Rust, Docker, Build Tools)..."
while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
    echo "Waiting for Ubuntu background security updates to release dpkg lock..."
    sleep 5
done
sudo apt-get update -y
sudo apt-get install -y curl pkg-config libssl-dev protobuf-compiler build-essential docker.io

# 2. Install Rust Toolchain
if ! command -v cargo &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
fi

# 3. Generate the Quantum-Safe Intent (Phase 1)
echo "Generating Dilithium cryptographic intent via 1-client..."
cd 1-client
cargo run --release
cd ..

# 4. Compile the Docker Architecture (Phase 2)
echo "Building the SP1 ZK-Coprocessor Image..."
sudo docker build -t zkvm-coprocessor .

# 5. Execute the Core SNARK Generation (Phase 3)
echo "Executing Plonk Proof Generation. This will max out CPU cores and consumes >64GB RAM..."
# Notice: We explicitly REMOVED the `SP1_PROVER=mock` override to force a mathematically legitimate Plonk Proof blob!
sudo docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v "$(pwd):/app/output" -v "$(pwd)/1-client/intent.json:/app/1-client/intent.json" zkvm-coprocessor

echo "✅ SUCCESS! Your authentic STARK payload has been serialized to:"
ls -la proof.json
