# The Path to 100% Post-Quantum Cryptography (PQC)

## 1. Introduction: The SNARK Transpilation Bottleneck
The core of the current architectural compromise lies in the bridging between off-chain execution and Ethereum Virtual Machine (EVM) settlement. 

Zero-Knowledge STARKs (Scalable Transparent Arguments of Knowledge) derive their security purely from collision-resistant hash functions. They do not rely on the hidden subgroup problems or discrete logarithms, making them inherently post-quantum resilient. 

However, pure FRI-STARK proofs feature large data footprints (often exceeding 100KB). Submitting and verifying a payload of this size natively on Ethereum L1 is economically inviable due to strict block limits. To solve for `calldata` constraints, major ZK-VM infrastructures (such as SP1 and RISC Zero) default to transpiling the STARK into a Groth16 or Plonk SNARK wrapper. 

**The Cryptographic Flaw:** Groth16 and standard Plonk circuits utilize Elliptic Curve Pairings (specifically the `BN254` curve). Because elliptic curve cryptography is fundamentally broken by Shor's Algorithm running on a sufficiently powerful quantum computer, this transpilation step completely invalidates the underlying post-quantum security of the ML-DSA lattice signature. 

---

## 2. Options Available Today (Immediate Implementations)

Achieving absolute 100% post-quantum security today requires eliminating the Elliptic Curve dependency from the verification pipeline entirely. 

### Option A: Native FRI-STARK Verification on L2 (Ethereum Ecosystem)
Instead of forcing the proof through a Groth16 SNARK, developers can verify the raw FRI-STARK directly in Solidity using L2 gas economics.
- **Mechanics:** Develop or utilize a raw STARK verifier smart contract. Deploy this contract on a high-throughput, low-cost Layer 2 (e.g., Base, Arbitrum, Optimism).
- **Economic Profile:** This will cost roughly 2,000,000 to 5,000,000 Gas per transaction. While impossible on Ethereum L1, L2 block space is currently cheap enough to absorb this multi-million gas execution cost.
- **Trade-offs:** High dependency on L2 sequencer uptime and evolving gas target ceilings. The L2 itself must inherently post data back to L1, and the security of those bridge mechanisms currently relies on ECDSA/BLS.

### Option B: Migration to STARK-Native Rollups (StarkNet Ecosystem)
The most robust solution available right now is abandoning the EVM entirely and deploying on a STARK-native OS.
- **Mechanics:** StarkNet's native operating architecture (Cairo) is explicitly built to verify FRI-STARKs natively, without EVM precompile translations or SNARK wrappers.
- **Security Profile:** By migrating intent settlement to StarkNet, the entire lifecycle (ML-DSA signature -> Off-chain STARK generation -> On-chain settlement) utilizes zero elliptic curves. This architecture provides 100% post-quantum security.
- **Trade-offs:** Requires rebuilding smart contract logic in Cairo instead of Solidity.

---

## 3. Future Roadmap & Standards Pipeline

### 3.1 Relevant EIPs and Ethereum Data Scaling
The primary barrier to raw STARK verification on Ethereum is data availability (costs for storing massive proofs on-chain).
- **EIP-4844 / Proto-Danksharding (Live):** Introduced Type 3 "Blob" transactions, drastically reducing the cost of publishing L2 state roots back to L1.
- **EIP-7594 / PeerDAS (Projected late 2026/2027):** Expands data availability sampling capabilities, allowing network nodes to verify data blobs without downloading them entirely. As data bandwidth scales logarithmically, publishing pure 100KB STARKs directly to L1 will become economically viable, removing the requirement for Groth16 transpilation.

### 3.2 Post-Quantum Account Abstraction (ERC-4337 / EIP-7702)
Account Abstraction enables the network to process programmable signature logic instead of relying on enshrined `ecrecover` mechanisms. While ERC-4337 is live, EIP-7702 (Projected inclusion in subsequent hard forks) will allow standard EOAs (Externally Owned Accounts) to temporarily adopt smart contract execution rules. This structurally enables legacy wallets to easily migrate into STARK-verified ML-DSA logic seamlessly.

### 3.3 The NIST Standardization Timeline
- **August 2024:** The US National Institute of Standards and Technology (NIST) officially finalized **FIPS 204**, standardizing ML-DSA (Module-Lattice-Based Digital Signature Algorithm). 
- **CNSA Suite 2.0 Mandate (2030 Limit):** The US National Security Agency dictates that all national security systems must complete migration to PQC by 2030 (preferably by 2027 for critical infrastructure). This regulatory framework will force institutional adoption of architectures mirroring this repository.

---

## 4. Chainlink & Decentralized Oracle Network Preparation

Integrating Chainlink Oracles securely into a 100% PQC network requires evaluating the cryptographic primitives utilized by the DON itself.

### Chainlink OCR (Off-Chain Reporting) Vulnerabilities
Chainlink's current OCR protocol relies heavily on **BLS (Boneh-Lynn-Shacham) Threshold Signatures**. BLS allows individual Oracle nodes to securely aggregate their signatures into a single, compact group signature for on-chain verification. 
**The Threat:** BLS relies entirely on elliptic curve pairings. A quantum computer will easily break OCR and generate fraudulent oracle consensus payloads.

### Chainlink PQC Migration Path
To prepare for quantum adversaries, Chainlink and equivalent oracle providers must migrate network security parameters:
1. **Lattice-Based Threshold Protocols:** Utilizing lattice variants of multi-party computation (e.g., transitioning to quantum-safe variants of FROST).
2. **Hash-Based Signatures (XMSS / SPHINCS+):** While ML-DSA is optimal for general use, highly critical network updates might utilize stateful hash-based signatures, which are mathematically immune to Shor's Algorithm but lack threshold aggregation capabilities.

If an institution deploys a 100% post-quantum pipeline today, the Chainlink DON remains the weakest link unless the specific enclave nodes are strictly mapped to execute SP1 STARK verification mechanisms rather than relying on native OCR aggregate BLS bridges.

---

## 5. Strategic Preparation: Necessary Questions for Architects

When auditing a system for 100% quantum-safety, zero-knowledge engineers must ask:

1. **Does the terminal verification layer mandate an Elliptic Curve (BN254/BLS12-381) compilation constraint?** 
   - If yes, the system is fundamentally broken down to ECDSA security profiles regardless of off-chain mechanics.
2. **Is the Layer 2 Sequencer quantum-safe?**
   - The majority of modern rollups utilize ECDSA to attest their state roots to the Layer 1 bridge. If the L2 Sequencer's signature is forged by a quantum computer, L1 assets are vulnerable, irrespective of the smart contracts running inside the L2.
3. **What is the structural L1 fallback?**
   - Does the architecture rely on a multi-sig or governance layer mapped to standard Web3 hardware wallets (Ledger/Trezor)? Hardware wallets default almost exclusively to ECDSA (secp256k1).
4. **Is the STARK polynomial commitment scheme strictly FRI?**
   - Alternate zero-knowledge commitments (like KZG) rely on cryptographic pairings and are mathematically vulnerable to quantum extraction. The pipeline must explicitly mandate Fast Reed-Solomon Interactive Oracle Proofs of Proximity.
