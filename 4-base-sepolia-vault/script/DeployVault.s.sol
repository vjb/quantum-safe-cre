// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/QuantumVault.sol";

contract DeployVault is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Base Sepolia Official SP1 Verifier Address
        address sp1Verifier = 0x3B6041173B80E77f038f3F2C0f9744f04837185e; 
        
        // Placeholder for your actual SP1 Program VKey (Generated in Phase 2)
        bytes32 programVKey = 0x0000000000000000000000000000000000000000000000000000000000000000;

        vm.startBroadcast(deployerPrivateKey);

        QuantumVault vault = new QuantumVault(sp1Verifier, programVKey);
        
        vm.stopBroadcast();
        
        console.log("QuantumVault deployed to:", address(vault));
    }
}
