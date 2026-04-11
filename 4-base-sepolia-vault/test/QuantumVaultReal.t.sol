// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/QuantumVault.sol";

contract QuantumVaultRealTest is Test {
    QuantumVault public vault;
    
    struct ProofData {
        bytes proofBytes;
        bytes publicValues;
        bytes32 vkey;
    }
    
    ProofData proofData;

    event PostQuantumIntentLogged(bytes32 indexed intentId, address target, uint256 amount);
    event IntentExecuted(string message, bool success);

    function setUp() public {
        string memory rpcUrl = vm.envString("BASE_SEPOLIA_RPC_URL");
        vm.createSelectFork(rpcUrl);

        // Inject the authentic Groth16 JSON payload natively from the VM root
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/../proof.json");
        string memory json = vm.readFile(path);
        
        proofData.proofBytes = vm.parseJsonBytes(json, ".proofBytes");
        proofData.publicValues = vm.parseJsonBytes(json, ".publicValues");
        proofData.vkey = vm.parseJsonBytes32(json, ".vkey");

        // Lock onto the exact physical SP1 Gateway verifying live on Base Sepolia
        // The Gateway natively translates both Plonk and Groth16 proofs dynamically.
        address realVerifier = 0x397A5f7f3dBd538f23DE225B51f532c34448dA9B;

        // Spin up an ephemeral execution environment strictly binding the SP1 infrastructure
        vault = new QuantumVault(realVerifier, proofData.vkey);
    }

    function test_LiveVerification_Success() public {
        // [A] Trigger Async Routing Queue
        address target = address(0x111122223333444455556666777788889999aAaa);
        uint256 amount = 1000;
        
        vm.recordLogs();
        vault.requestPQCTransfer(target, amount);
        
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 intentId = entries[0].topics[1]; // Pull out the deterministic intentId

        // [B] Satisfy Intent via Valid Cryptography bounds
        vault.fulfillPQCTransfer(intentId, proofData.proofBytes, proofData.publicValues);

        // [C] Assert Execution
        (,, bool exists) = vault.pendingIntents(intentId);
        assertFalse(exists, "Intent array mapping failed to destroy entry completely!");
    }

    function test_LiveVerification_RevertsOnFakeProof() public {
        address target = address(0x111122223333444455556666777788889999aAaa);
        uint256 amount = 1000;

        vm.recordLogs();
        vault.requestPQCTransfer(target, amount);
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 intentId = entries[0].topics[1];

        // 🚨 NEGATIVE ASSERTION: Synthesize a cryptographic corruption vector
        bytes memory fakeProof = proofData.proofBytes;
        fakeProof[fakeProof.length - 1] = 0x00;

        // Expect extreme network rejection mapping from SP1 BN254 constraints
        vm.expectRevert();
        vault.fulfillPQCTransfer(intentId, fakeProof, proofData.publicValues);
    }
}
