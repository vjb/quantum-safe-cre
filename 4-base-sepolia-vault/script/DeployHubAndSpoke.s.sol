// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/QuantumHomeVault.sol";
import "../src/QuantumSpokeVault.sol";
import "../src/MockSP1Verifier.sol";

contract DeployHubAndSpoke is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Base Sepolia Deployments
        address sp1Verifier = 0x397A5f7f3dBd538f23DE225B51f532c34448dA9B; 
        bytes32 programVKey = 0x00e7689ca01eede8fff671e32a9fd4b0b94424ce81b5ccd573f2a30139f32013;
        address baseRouter = 0xD3b06cEbF099CE7DA4AcCf578aaebFDBd6e88a93;
        address baseLink = 0xE4aB69C077896252FAFBD49EFD26B5D171A32410;

        // Arbitrum Sepolia Deployments
        address arbRouter = 0x2a9C5afB0d0e4BAb2BCdaE109EC4b0c4Be15a165;

        // Deploy Home Vault to Base Sepolia
        vm.startBroadcast(deployerPrivateKey);
        MockSP1Verifier mockVerifier = new MockSP1Verifier();
        QuantumHomeVault homeVault = new QuantumHomeVault(address(mockVerifier), programVKey, baseRouter, baseLink);
        vm.stopBroadcast();
        console.log("QuantumHomeVault deployed to Base Sepolia at:", address(homeVault));

        // Deploy Spoke Vault to Arbitrum Sepolia
        vm.startBroadcast(deployerPrivateKey);
        QuantumSpokeVault spokeVault = new QuantumSpokeVault(arbRouter);
        vm.stopBroadcast();
        console.log("QuantumSpokeVault deployed to Arbitrum Sepolia at:", address(spokeVault));
    }
}
