# ARCHITECTURE GUARDRAILS & STRICT RULES

This document serves as the absolute boundary for the development of the Post-Quantum Chainlink DON Integration. Any pull request violating these rules must be rejected immediately.

## 1. Cryptographic Strictness (The "No Raw Strings" Rule)
* **RULE:** The SP1 Prover (`main.rs`) is strictly forbidden from committing raw string arrays. 
* **ENFORCEMENT:** All ZK commitments must be strictly typed EVM bytes utilizing the `alloy-sol-types` crate. The Smart Contract (`QuantumVault.sol`) must natively use `abi.decode` to extract the tuple `(address, uint256, uint256)`.

## 2. Secrets Management & Confidentiality (The "No Leakage" Rule)
* **RULE:** No GCP API keys, Service Account JSONs, or Webhook HMAC secrets may be hardcoded, stored in the GitHub repository, or emitted in on-chain transaction data.
* **ENFORCEMENT:** The architecture relies on the Chainlink Confidential Routing Environment (CRE). The DON holds the `GOOGLE_APPLICATION_CREDENTIALS` and `HMAC_SECRET` in its secure off-chain encrypted keystore (Confidential HTTP pattern). These are injected into the Ext-Adapter exclusively at runtime.

## 3. Infrastructure Immutability (The "No Bash Hacks" Rule)
* **RULE:** The `Actor-4: SP1-Prover` cannot download source code or compile dynamically at runtime.
* **ENFORCEMENT:** The GCP compute environment (`Actor-3: Cloud Batch`) must boot from a pre-compiled, immutable multi-stage Docker image hosted in Google Artifact Registry. `git`, `rustc`, and `npm` are banned from the final container image.

## 4. Execution Determinism (The "No Hanging Node" Rule)
* **RULE:** The Chainlink DON must never block or hang while waiting for the L4 GPU to calculate the proof.
* **ENFORCEMENT:** The `Ext-Adapter/CRE` must return an HTTP 200 `{"pending": true}` immediately upon Cloud Batch submission. The execution flow strictly relies on a bi-directional asynchronous webhook pattern for fulfillment.
