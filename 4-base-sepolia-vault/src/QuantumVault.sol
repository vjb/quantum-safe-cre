// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ISP1Verifier.sol";

contract QuantumVault {
    address public sp1Verifier;
    bytes32 public programVKey;

    event IntentExecuted(string message, bool success);

    constructor(address _sp1Verifier, bytes32 _programVKey) {
        sp1Verifier = _sp1Verifier;
        programVKey = _programVKey;
    }

    /// @notice Executes a post-quantum intent only if the STARK proof is valid
    function executeIntent(bytes calldata proof, bytes calldata publicValues) external {
        // 1. Verify the STARK proof via the SP1 Verifier Contract
        // If the off-chain Dilithium math was tampered with, this will revert.
        ISP1Verifier(sp1Verifier).verifyProof(programVKey, publicValues, proof);

        // 2. Extract the intent from the verified public journal
        // SP1 public values encode strings with a 4-byte length prefix in ABI encoding
        string memory intentMessage = abi.decode(publicValues, (string));

        // 3. Execute the Intent (In a production wallet, this would route the transaction)
        emit IntentExecuted(intentMessage, true);
    }
}
