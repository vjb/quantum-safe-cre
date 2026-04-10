// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ISP1Verifier.sol";

contract QuantumVault {
    address public sp1Verifier;
    bytes32 public programVKey;

    // ADDED: State mapping to track executed intents to prevent Replay Attacks
    mapping(bytes32 => bool) public executedIntents;

    event IntentExecuted(string message, bool success);

    constructor(address _sp1Verifier, bytes32 _programVKey) {
        sp1Verifier = _sp1Verifier;
        programVKey = _programVKey;
    }

    /// @notice Executes a post-quantum intent only if the STARK proof is valid
    function executeIntent(bytes calldata proof, bytes calldata publicValues) external {
        
        // 1. REPLAY PROTECTION
        // Hash the public values to ensure this exact intent hasn't been routed before.
        bytes32 intentHash = keccak256(publicValues);
        require(!executedIntents[intentHash], "Security Error: Intent already executed");
        executedIntents[intentHash] = true;

        // 2. VERIFY THE STARK PROOF
        // If the off-chain Dilithium math was tampered with, this will revert.
        ISP1Verifier(sp1Verifier).verifyProof(programVKey, publicValues, proof);

        // 3. EXTRACT THE INTENT
        // SP1 public values encode strings with a 4-byte length prefix in ABI encoding
        string memory intentMessage = abi.decode(publicValues, (string));

        // 4. EXECUTE
        emit IntentExecuted(intentMessage, true);
    }
}
