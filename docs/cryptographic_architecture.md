# Quantum-Safe CRE: Cryptographic Architecture & Mathematical Threat Models

This document serves as the technical primer for the hybrid cryptographic architecture governing the quantum-safe-cre network. It details the pipeline of translating Post-Quantum signatures (ML-DSA) into Succinct Zero-Knowledge polynomial proofs (FRI-STARKs) for efficient EVM settlement.

## 1. Local Intent Generation: ML-DSA (Lattice Cryptography)
To achieve post-quantum security against Shor's Algorithm, this architecture utilizes ML-DSA (formerly CRYSTALS-Dilithium), the NIST-standardized algorithm for digital signatures.

Unlike Elliptic Curve Digital Signature Algorithm (ECDSA), which relies on the discrete logarithm problem, ML-DSA relies on the hardness of the Module Learning with Errors (MLWE) and Module Short Integer Solution (MSIS) problems.

### 1.1 The Polynomial Ring
Cryptographic operations occur over the polynomial ring $R_q$:

$$
R_q = \mathbb{Z}_q[X]/(X^n + 1)
$$

Where $n = 256$ and $q = 8380417$. This specific prime is chosen to support the Number Theoretic Transform (NTT), allowing for highly optimized polynomial multiplication.

### 1.2 Signature Generation & Fiat-Shamir with Aborts
When the user generates a transaction intent (e.g., "Transfer 10 USDC"), the Rust client generates a signature utilizing the Fiat-Shamir with Aborts framework.

The signer generates a masking vector $\mathbf{y}$ and computes a challenge polynomial $c \in R_q$. To prevent the signature from leaking information about the private key $\mathbf{s}_1$, the output vector $\mathbf{z}$ is computed as:

$$
\mathbf{z} = \mathbf{y} + c \cdot \mathbf{s}_1
$$

If the coefficients of $\mathbf{z}$ fall outside mathematical boundaries ($||\mathbf{z}||_\infty \ge \gamma_1 - \beta$), the signer aborts the process and retries. This guarantees statistical zero-knowledge of the secret key.

## 2. Off-Chain Execution: SP1 RISC-V Arithmetization (STARKs)
Because ML-DSA signatures are ~2.4KB and unsupported by the Ethereum Virtual Machine (EVM), verifying them directly on-chain would violate block gas limits.

The 2-sp1-coprocessor decouples this computation using SP1, an open-source RISC-V zero-knowledge virtual machine.

### 2.1 Plonkish Arithmetization
SP1 translates the Rust-based Dilithium verification logic into an algebraic execution trace. It utilizes a Plonkish arithmetization architecture, tracking state transitions across $N$ execution steps.

The VM ensures that every computational step (e.g., RISC-V opcodes) is mathematically valid via constraint equations. These constraints are combined into a single polynomial equation that must evaluate to zero at specific points:

$$
P(x) = Z(x) \cdot Q(x)
$$

Where $Z(x)$ is the vanishing polynomial.

### 2.2 The FRI Commitment and STARK Compression
To prove this execution trace is valid without forcing the EVM to re-run the computation, SP1 uses FRI (Fast Reed-Solomon Interactive Oracle Proofs of Proximity).

The execution trace polynomial is extended via a Reed-Solomon code and committed to a Merkle Tree.

The prover iteratively folds the polynomial, compressing its degree by half at each step:

$$
f_i(x) = f_{i-1}(x^2) + \alpha \cdot x \cdot g_{i-1}(x^2)
$$

This recursive folding compresses the RISC-V execution trace down to a deterministic STARK Proof.

### 2.3 Groth16 Final Verification Wrapper
Because Dilithium matrix multiplications naturally span large computational grids, directly submitting the STARK to standard Plonk solidity constraints results in verifier overflows ("algebraic relation does not hold"). 

To settle on Ethereum, the SP1 coprocessor intercepts the core FRI-STARK layer and maps it through a Groth16 SNARK constraint wrapper. Groth16 compresses the structural footprint, safely enveloping the array calculations and achieving a flat gas fee for final Ethereum network acceptance.

### 2.4 Known Limitations & Future Work
While gas-efficient, the Groth16 transpilation introduces a legacy cryptographic limitation back into the pipeline. Because Groth16 relies on Elliptic Curve Cryptography (specifically pairing-friendly curves like BN254), the final verification step theoretically loses its quantum safety.

A sufficiently resourced quantum computer executing Shor's Algorithm could hypothetically break the BN254 curve constraints of the Groth16 wrapper, generating a mathematically forged SNARK proof that the L2 smart contract would accept as valid.

Future architecture iterations must target direct integration with STARK-compatible rollups (such as StarkNet), pushing the pure hash-based FRI-STARK proof directly on-chain without an intermediate SNARK wrapper. This entirely bypasses Elliptic Curve boundaries, guaranteeing 100% end-to-end quantum resistance.

## 3. L2 Settlement & Threat Mitigation
In Phase 4, the Base Sepolia L2 vault strictly enforces mathematical constraints on the submitted STARK proof. You cannot submit an arbitrary proof; it must resolve against the Succinct ISP1Verifier utilizing the exact verification key hash ($\mathcal{K}_{vKey}$) generated by the authorized RISC-V program.

### 3.1 Resolving Replay Attack Vectors
Because blockchains are transparent ledgers, a malicious actor could theoretically observe an authorized Chainlink execution, copy the STARK proof, and continuously resubmit it to drain the smart contract vault.

To mitigate this, Phase 4 incorporates Intent Hashing (Replay Protection) at the smart contract level. The intent journal is hashed:

$$
\mathcal{H}_{req} = \text{keccak256}(\text{PublicValues})
$$

This hash is mapped to a state boolean (`mapping(bytes32 => bool) executedIntents`). A STARK proof is uniquely tied to its underlying instruction. Any secondary transaction attempting to leverage the same proof will immediately evaluate to true in the state mapping, prompting the EVM to revert the transaction and securely lock the vault against double-spends.
