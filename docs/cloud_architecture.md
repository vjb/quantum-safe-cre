# Post-Quantum Confidential Routing Architecture

This document describes the tier-1 institutional infrastructure mapping the SP1 Prover orchestration. It definitively eradicates serverless proxy intermediaries in favor of immutable L4 GPU allocations.

## Structural Boundaries

### 1. The Immutable Proving Layer (`sp1-prover-repo`)
The execution strictly isolates the SP1 Risk-VM (`Actor-4`) inside an immutable Docker image staged on Google Artifact Registry (`pqc-prover:latest`).
* **Hardware Profile:** Ephemeral `g2-standard-4` dynamically mounted L4 GPUs.
* **Cryptography:** Dilithium ML-DSA validation strictly packaged with NO dependencies on Github, NPM, or Rustup during runtime.

### 2. The Chainlink Confidential Routing Environment (CRE)
To guarantee the GCP Service Account credentials (`GOOGLE_APPLICATION_CREDENTIALS`) and Job identifiers never touch the open blockchain or disk natively, the `batch_client.ts` gateway manages execution natively.
* **Security Vector:** Evaluates all HTTP intercepts against a secure `Bearer $HMAC_SECRET` injected implicitly inside the DON hardware enclave.
* **Bi-Directional State:** Once GCP Batch completes the mathematical PLONK operations on the GPU natively, the local container pushes a secure JSON Post hook back exactly targeting the Webhook Listener.

### 3. EVM Contract Inheritances
The execution boundary securely passes verified payloads matching native byte structures matching `abi.decode` variables precisely.
* Legacy parsing is physically omitted. `QuantumVault.sol` exclusively routes `fulfillPQCProof()` bounded under standard `recordChainlinkFulfillment()` overrides, destroying the chance of external wallet spoof attacks completely.

---

### End-To-End Latency
A fully built deployment traces execution paths successfully under ~1 minute assuming `sp1-prover-repo` images are completely cached in the regional CDN.
