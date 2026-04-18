# MASTER EXECUTION PLAN: Post-Quantum Chainlink CRE Integration

## 1. System Actors & Operational Boundaries

| Actor ID | System Environment | Primary Responsibility | Authorized Tooling / State |
| :--- | :--- | :--- | :--- |
| **Actor-1: Chainlink DON** | Off-chain (Web3) | Initiates oracle job via Confidential HTTP, securely holds GCP/HMAC secrets, handles OCR2 consensus. | Chainlink Node, Encrypted Secrets |
| **Actor-2: Chainlink CRE** | Off-chain (Node.js) | Acts as the gateway (`oracle.ts`). Authenticates with GCP via injected DON secrets, submits Batch job, manages async cache. | Node.js, `@google-cloud/batch` |
| **Actor-3: Cloud Batch** | GCP (Control Plane) | Provisions ephemeral `g2-standard-4` hardware natively, mounts the immutable SP1 container. | Native GCP API (L4 GPU) |
| **Actor-4: SP1-Prover** | GCP (Data Plane) | Executes the PLONK calculation, writes to GCS, and fires the secure Webhook callback to Actor-2. | Docker (GAR), `gsutil`, `curl` |
| **Actor-5: QuantumVault** | Base Sepolia | Verifies the ZK Proof via the SP1 Verifier, ABI-decodes the payload, and alters EVM state. | Solidity, SP1 Verifier, Chainlink Client |

---

## 2. Phased Execution & Testing Protocol

### Phase 1: Cryptographic EVM Binding (The Foundation)
**Objective:** Establish the deterministic, mathematically proven link between the L4 GPU and the EVM.
* **Requirement 1.A:** `Actor-4: SP1-Prover` constructs its payload using strict ABI encoding (`alloy-sol-types`), structured as `(address target, uint256 amount, uint256 nonce)`.
* **Requirement 1.B:** `Actor-5: QuantumVault` verifies the proof and natively utilizes `abi.decode(publicValues, (address, uint256, uint256))`.
* **Test 1.A.1 (Byte Parity):** `test_abi_encoding_perfect_match`: Rust unit test asserting SP1 byte output exactly matches Solidity `abi.encode` output.
* **Test 1.B.1 (Vault State):** `test_vault_execution_state_change`: Foundry test passing mock proof; asserting target balance increases and `nonce` is permanently burned.

### Phase 2: Chainlink CRE & Immutable Infrastructure
**Objective:** Deploy the zero-trust cloud boundaries and the Confidential Routing pipeline.
* **Requirement 2.A:** GCP resources (GAR, GCS, IAM) deployed via Terraform. Two isolated Service Accounts: `sa-chainlink-cre` (Submitter) and `sa-batch-runner` (Executor).
* **Requirement 2.B:** `Actor-2: Chainlink CRE` must accept requests containing authorization headers injected by `Actor-1: Chainlink DON`'s confidential secrets. 
* **Requirement 2.C:** `Actor-4: SP1-Prover` must be an immutable Docker image (under 300MB, no dev dependencies).
* **Test 2.B.1 (Confidential Auth):** `test_cre_auth_rejection_401`: Attempt to trigger `Actor-2` without the DON's confidential injected secrets. Must fail safely with HTTP 401.
* **Test 2.C.1 (Container Purity):** `test_container_size_and_deps`: Audit the compiled Docker image confirming absence of `rustc`.

### Phase 3: Secure Asynchronous Orchestration
**Objective:** Close the "Air Gap" securely without hanging the DON.
* **Requirement 3.A:** `Actor-2: Chainlink CRE` caches the `jobRunID` and returns `{"pending": true}`.
* **Requirement 3.B:** `Actor-4: SP1-Prover` executes two commands post-proof: Upload to GCS -> Execute authenticated POST to `Actor-2`'s webhook.
* **Requirement 3.C:** Webhook payload must be signed using the `HMAC_SECRET` injected natively through Cloud Batch environment variables.
* **Test 3.C.1 (Webhook Spoofing):** `test_webhook_hmac_invalid`: Send POST to webhook signed with invalid key. `Actor-2` must reject and drop the payload.
* **Test 3.A.1 (CRE Timeout Cleanup):** `test_cre_memory_leak_prevention`: Submit a Batch job that intentionally stalls. Assert `Actor-2` purges the job from memory after TTL (e.g., 10m) and flags an error to `Actor-1`.

### Phase 4: Executive E2E Simulation
**Objective:** The singular script proving the entire architecture to stakeholders.
* **Requirement 4.A:** `run_executive_simulation.sh` tracing intent from DON to Base Sepolia.
* **Test 4.A.1 (Gold Standard Artifacts):** Must yield:
    1. GCP Logging URL for the `Actor-3` Batch Job.
    2. `Actor-1` OCR2 node log showing successful async callback.
    3. Base Sepolia TxHash showing `Actor-5` emitting `IntentExecuted`.
