// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/QuantumVault.sol";

contract QuantumVaultTest is Test {
    QuantumVault public vault;
    address public mockVerifier = address(0x123);
    bytes32 public mockVKey = bytes32(uint256(1));

    event IntentExecuted(string message, bool success);

    function setUp() public {
        vault = new QuantumVault(mockVerifier, mockVKey);
    }

    function test_executeIntent_ValidProof() public {
        string memory expectedMessage = "Transfer 10 USDC";
        bytes memory mockPublicValues = abi.encode(expectedMessage);
        bytes memory mockProof = "0xmockproof";

        // Mock the SP1 verifier to return successfully (no revert)
        vm.mockCall(
            mockVerifier,
            abi.encodeWithSignature("verifyProof(bytes32,bytes,bytes)", mockVKey, mockPublicValues, mockProof),
            abi.encode()
        );

        // Expect the event to be emitted
        vm.expectEmit(false, false, false, true);
        emit IntentExecuted(expectedMessage, true);

        // Execute
        vault.executeIntent(mockProof, mockPublicValues);
    }
}
