# Implementation Plan: Institutional Omni-Chain Custody Protocol

This document outlines the systematic refactoring of the repository to meet production-grade institutional standards.

## User Review Required

> [!WARNING]
> Renaming the folder `3-chainlink-cre` to `3-execution-relayer` will result in path breaks for any external integrations holding historical reference to this directory.

## Proposed Changes

### Configuration

#### [MODIFY] .env
- Inject Google Cloud Project variables. Set Project ID placeholder to `strange-radius-493714-j0`.

---

### Phase 1: Distributed Off-Chain Compute (GCP Batch)

#### [NEW] batch_job_template.json
- Define GCP Batch job configuration.
- Set `provisioningModel: SPOT`.
- Set `allowedLocations: ["regions/us-central1", "regions/us-east4", "regions/us-west1", "regions/europe-west4"]`.
- Set `machineType: g2-standard-4`.
- Configure tmpfs volume mount to `/app/trace_cache`.
- Configure output routing to highly available Cloud Storage bucket.

#### [MODIFY] 2-sp1-coprocessor/program/src/main.rs
- Configure SP1 STARK trace generation to write intermediate files to `/app/trace_cache`, optimizing disk I/O.

---

### Phase 2: Smart Contract Architecture (Hub and Spoke)

#### [MODIFY] 4-base-sepolia-vault/src/QuantumHomeVault.sol (Renamed from QuantumVault.sol)
- Implement `QuantumHomeVault.sol` as the Primary Vault.
- Integrate `ISP1Verifier` for STARK validation.
- Integrate Chainlink CCIP `IRouterClient`.
- Implement logic to receive transaction payload, execute logic test via SP1 Verifier, extract `destinationChainSelector` and `executionData`.
- Construct `Client.EVM2AnyMessage` and execute `ccipSend()`.

#### [NEW] 4-base-sepolia-vault/src/QuantumSpokeVault.sol
- Implement `QuantumSpokeVault.sol` as the Replica Vault.
- Implement `CCIPReceiver` logic.
- Maintain an allowlist mapping of approved `QuantumHomeVault` addresses and source chains. Drops any unauthorized messages.

---

### Phase 3: The Execution Relayer

#### [MODIFY] 3-execution-relayer (Renamed from 3-chainlink-cre)
- Rename directory `3-chainlink-cre` to `3-execution-relayer`.
- Strip all Decentralized Oracle Network consensus and redundant Chainlink script files.

#### [NEW] 3-execution-relayer/src/server.ts
- Expose REST endpoint to receive `intent.json`.
- Initialize GCP Batch Job utilizing `batch_job_template.json`.
- Implement Cloud Storage polling mechanism with exponential backoff to retrieve proof completion.
- Construct EVM transaction using viem (or ethers) and submit to `QuantumHomeVault`.

#### [NEW] 3-execution-relayer/src/telemetry.ts
- Implement Pino (or Winston) for structured JSON logging.
- Set up standard trace outputs for logging.
- Expose `/metrics` Prometheus endpoint to track Batch queue times, STARK generation latency, and EVM settlement latency.

---

### Phase 4: Test-Driven End-to-End Simulation

#### [NEW] 4-base-sepolia-vault/test/HubAndSpokeSim.t.sol
- Implement rigorous Smart Contract Simulator using Chainlink Foundry `CCIPLocalSimulator.sol`.
- Ensure robust local Hub-and-Spoke routing logic testing.

#### [MODIFY] flagship_demo.sh
- Refactor script to output precise timestamps according to the requested execution model format.
- Enforce deterministic pipelines that execute mechanically with JSON logs instead of standard outputs.
- Remove dramatic console output and verify idempotency.

---

### Phase 5: Institutional Documentation Refactor

#### [MODIFY] README.md
- Remove all hackathon-oriented language.
- Enforce "Step 0: Environment Configuration" specifying instructions to duplicate `.env.example` into a local `.env` file.
- Add an Architecture Specifications section outlining path routing and cost-benefit analysis of FRI-STARK L2 verification versus Groth16/BN254 wrappers.
- Add a mandatory Known Limitations & Future Work section containing details on CCIP Latency (15 to 30 mins), Spot Instance Exhaustion (NVIDIA L4 queueing), and Gas Constraints (2.5 million gas blocking Mainnet deployments).

#### [NEW] .env.example (Added to all component folders)
- Create and populate placeholder variables and explicit inline documentation targeting GCP authentication, RPC URLs, and Chainlink routing.

---

### Phase 6: Python Live Integration Testing Suite

#### [NEW] tests/test_e2e_infrastructure.py
- Implement an end-to-end integration testing suite using `pytest`, `web3.py`, and the Google Cloud SDKs to actively test the live deployments and data flows.
- **Wallet & RPC Readiness Tests**: 
  - Connect to Base Sepolia and Arbitrum Sepolia RPC endpoints.
  - Assert that the operational wallets have sufficient testnet ETH and LINK balances to process transactions and cover CCIP fees.
- **GCP SP1 Deployment Tests**: 
  - Authenticate with Google Cloud using the Service Account.
  - Dynamically trigger the Execution Relayer's GCP Batch provisioning pipeline.
  - Monitor the GCP Batch API to verify the `SPOT` (or `STANDARD` fallback) job successfully spins up, computes the SP1 trace, and drops the generated proof into the configured Cloud Storage bucket.
- **Smart Contract & Chainlink Tests**: 
  - Use `web3.py` to fetch the proof from Cloud Storage and dynamically call `processPQCProof` on the `QuantumHomeVault` (Base Sepolia).
  - Listen for the `MessageSent` event to guarantee the transaction successfully hit the Chainlink CCIP Router.
  - Assert the Chainlink CCIP delivery by monitoring the `QuantumSpokeVault` (Arbitrum Sepolia) for the `IntentExecuted` event, ensuring the Hub-and-Spoke bridge fully functioned.
- **Dependencies**: Generate a `requirements.txt` containing `pytest`, `web3`, `google-cloud-batch`, `google-cloud-storage`, and `python-dotenv`.

---

### Phase 7: Live E2E Integration Pipeline Execution

#### [NEW] run_live_integration.py (Cross-platform adapter)
- Since the local Windows/WSL `bash` interpreter is throwing execution policy and pathing errors, I will transcribe the `run_live_integration.sh` into a native Python script (`run_live_integration.py`) to bypass PowerShell execution restrictions and cleanly execute the end-to-end process utilizing `subprocess` and the native Google SDKs.

#### [UPDATE] Infrastructure Deployments
Before we can run the live integration, the pipeline requires actual live entities on the networks. I will:
1. **Smart Contracts**: Deploy `QuantumHomeVault.sol` to Base Sepolia and `QuantumSpokeVault.sol` to Arbitrum Sepolia using `cast` (via CMD). I will capture their deployed addresses and inject them into `.env` as `PRIMARY_VAULT_ADDRESS` and `REPLICA_VAULT_ADDRESS`.
2. **Docker Image Resolution**: The `batch_job_template.json` currently targets `"placeholder_image_uri"`. I will attempt to locate your pre-built SP1 Docker image in the GCP Artifact Registry, or prompt you for the specific URI so GCP Batch doesn't immediately crash.

## Open Questions

> [!IMPORTANT]
> - Do you have a pre-built SP1 Docker Image pushed to Google Artifact Registry that I should insert into `batch_job_template.json`? If not, do you want me to write a Docker build/push script first?
> - Do you want me to automatically deploy the Hub and Spoke vaults to the testnets and fund them with LINK, or do you already have deployed addresses that I should just paste into `.env`?

## Verification Plan

### Automated Tests
- Run `forge test` against the Foundry Smart Contract simulator integrating `CCIPLocalSimulator.sol` to validate Hub-to-Spoke cross-chain messaging mechanics.
- Deploy testing API and execute `/metrics` scraping to validate Prometheus trace outputs.

### Manual Verification
- Execute `flagship_demo.sh` to ensure timestamps perfectly match the format constraint and successfully log end-to-end execution.
- Review README and output variables to guarantee "Zero Fluff," "No Em Dashes," and adherence to the "Neutral Language" constrains.
