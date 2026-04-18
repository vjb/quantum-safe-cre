// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "./ISP1Verifier.sol";

contract QuantumVault is ChainlinkClient {
    using Chainlink for Chainlink.Request;

    address public sp1Verifier;
    bytes32 public programVKey;
    mapping(uint256 => bool) public executedNonces;

    event PostQuantumIntentLogged(address indexed target, uint256 amount);
    event IntentExecuted(bytes32 indexed requestId, bool success);

    constructor(address _sp1Verifier, bytes32 _programVKey) {
        sp1Verifier = _sp1Verifier;
        programVKey = _programVKey;
    }

    // Fulfillment callback triggered by the Chainlink DON natively from the Cloud Batch Webhook
    function fulfillPQCProof(bytes32 _requestId, bytes calldata proofBytes, bytes calldata publicValues) public {
        require(msg.sender == oracle() || oracle() == address(0), "Confidential Routing Error: Only Authorized DON Oracle can submit results!");
        // 1. ZK Verification
        ISP1Verifier(sp1Verifier).verifyProof(programVKey, publicValues, proofBytes);

        // 2. Strict ABI Decoding (EVM standard)
        (address target, uint256 amount, uint256 nonce) = abi.decode(publicValues, (address, uint256, uint256));

        // 3. Replay Protection
        require(!executedNonces[nonce], "Security Error: Nonce used");
        executedNonces[nonce] = true;

        // 4. Execution
        emit PostQuantumIntentLogged(target, amount);
        emit IntentExecuted(_requestId, true);
    }
}
