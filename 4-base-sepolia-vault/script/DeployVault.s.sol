// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/QuantumVault.sol";

contract DeployVault is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Base Sepolia Official SP1 Verifier Address
        address sp1Verifier = 0x397A5f7f3dBd538f23DE225B51f532c34448dA9B; 
        
        // Validated SP1 Program VKey (Generated dynamically during Phase 2 Compilation)
        bytes32 programVKey = 0x003c02d11d2290288d2d9f89eda3dc5d65a1732a7f9502aa9e7e70c6bcd60dd0;

        vm.startBroadcast(deployerPrivateKey);

        QuantumVault vault = new QuantumVault(sp1Verifier, programVKey);
        
        vm.stopBroadcast();
        
        console.log("QuantumVault deployed to:", address(vault));
    }
}
