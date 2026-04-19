# The Post-Quantum Omni-Chain Architecture

The core challenge of post-quantum cryptography on EVM-compatible networks is the sheer size of the data. Zero-Knowledge STARKs (Scalable Transparent Arguments of Knowledge) derive their security purely from collision-resistant hash functions, making them inherently post-quantum resilient. However, pure FRI-STARK proofs feature massive data footprints (averaging 1.27MB). Submitting and verifying a payload of this size natively on Ethereum L1 or L2 is impossible due to strict block gas limits.

To solve this, legacy systems transpile the STARK into a Groth16 or Plonk SNARK wrapper. This introduces a fatal cryptographic flaw: Groth16 utilizes Elliptic Curve Cryptography (specifically the `BN254` curve) which is fundamentally broken by Shor's Algorithm.

To bypass EVM constraints without destroying our quantum-safe properties, we transitioned to a modern **Data Availability (DA)** and **Chainlink CCIP** architecture.

## 1. Local Intent Generation (ML-DSA)
To achieve post-quantum security against Shor's Algorithm, the client utilizes ML-DSA (formerly CRYSTALS-Dilithium), the NIST-standardized algorithm for digital signatures. The client generates a ~2.4KB cryptographic intent (e.g., "Transfer 10 USDC") and passes it to the cloud.

## 2. L4 GPU Cloud Execution (SP1 STARKs)
Because the EVM cannot natively verify ML-DSA signatures, the cloud orchestrator boots an ephemeral NVIDIA L4 GPU instance. The SP1 Zero-Knowledge Virtual Machine executes the Rust-based ML-DSA verification logic and translates it into an algebraic execution trace.

SP1 compresses this RISC-V execution trace down into a pure FRI-STARK proof. This process entirely bypasses Elliptic Curve boundaries, guaranteeing 100% mathematical quantum resistance. 

## 3. The EigenDA Verification Paradigm
Instead of forcing the 1.27MB STARK proof into an EVM transaction via a Groth16 SNARK, our Viem Relayer submits the full pure STARK proof to **EigenDA** (an Alternate Data Availability Layer). 

EigenDA specializes in cheap, massive data availability. Upon receiving the proof, it generates a mathematical Data Commitment (a `blobRoot` Merkle Root).

## 4. Chainlink CCIP Omni-Chain Settlement
The Relayer submits only the 32-byte `blobRoot` to the `QuantumHomeVault.sol` on Base Sepolia. The Vault utilizes the `QuantumEigenDAVerifier` to assert the mathematical execution trace. 

Because the data footprint is mathematically verified via the DA layer, the Hub successfully dispatches the authorized message to the Chainlink CCIP Router. The Decentralized Oracle Network manages consensus, securely executing the final post-quantum settlement on the replica `QuantumSpokeVault.sol` on Arbitrum Sepolia!
