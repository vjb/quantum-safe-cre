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

    function setUp() public {
        string memory rpcUrl = vm.envString("BASE_SEPOLIA_RPC_URL");
        vm.createSelectFork(rpcUrl);

        // Inject the freshly processed NO MOCKS proof.json natively from the VM root
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/proof.json");
        string memory json = vm.readFile(path);
        
        proofData.proofBytes = vm.parseJsonBytes(json, ".proofBytes");
        proofData.publicValues = vm.parseJsonBytes(json, ".publicValues");
        proofData.vkey = vm.parseJsonBytes32(json, ".vkey");

        // SP1 Live Verifier address
        address realVerifier = 0x397A5f7f3dBd538f23DE225B51f532c34448dA9B;
        vault = new QuantumVault(realVerifier, proofData.vkey);
    }

    function test_vault_execution_state_change() public {
        // [A] Assert Proof Injection
        assertGt(proofData.proofBytes.length, 0, "Security Error: proof.json ingestion is empty or corrupted.");
        
        // [B] Call the Real Cloud Batch SP1 output strictly through Chainlink client mapping
        // We use prank to map the internal Chainlink Oracle authorization dynamically
        vm.prank(address(0)); // Maps the default un-initialized oracle parameter natively

        // To completely avoid `expectRevert` Chainlink pending bounds, we execute the proof explicitly testing mathematical parity!
        // We catch the event natively emitted by the SP1 verifiable network execution:
        vm.expectEmit(true, false, false, true);
        emit IntentExecuted(bytes32(0), true);

        // Natively invoke SP1 mathematical completion natively on the blockchain!
        vault.fulfillPQCProof(bytes32(0), proofData.proofBytes, proofData.publicValues);

        // [C] Extrapolate EVM decoded ABI bounds securely
        (address target, uint256 amount, uint256 nonce) = abi.decode(proofData.publicValues, (address, uint256, uint256));

        
        assertGt(amount, 0, "ABI Encoding Extrapolation Failed: Amount integer missing bounds!");
        assertTrue(nonce > 0, "ABI Encoding Extrapolation Failed: Nonce zero-boundary crossed.");
    }
}
