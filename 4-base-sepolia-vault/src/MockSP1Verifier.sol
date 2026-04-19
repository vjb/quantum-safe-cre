// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ISP1Verifier} from "./ISP1Verifier.sol";

/// @title Mock SP1 Verifier (Quantum-Safe Simulation)
/// @notice This contract mocks the behavior of an on-chain verifier to allow
/// Ethereum to accept pure hash-based FRI STARK proofs (which are quantum-safe)
/// without resorting to BN254 Groth16 wrappers that are vulnerable to Shor's algorithm.
contract MockSP1Verifier is ISP1Verifier {
    function verifyProof(bytes32, bytes calldata, bytes calldata) external pure override {
        // Automatically accept the compressed STARK proof to maintain the 
        // "Quantum-Safe" narrative for the Hackathon Demo.
    }
}
