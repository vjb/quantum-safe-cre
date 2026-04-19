// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/QuantumHomeVault.sol";
import "../src/QuantumSpokeVault.sol";
import "../src/QuantumEigenDAVerifier.sol";

contract DeployHubAndSpoke is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Base Sepolia Deployments

        bytes32 programVKey = 0x0022bde2497e7e25206f6333ced84474e4c05ca2a757d80b902b0f8d2f5faf0b;
        address baseRouter = 0xD3b06cEbF099CE7DA4AcCf578aaebFDBd6e88a93;
        address baseLink = 0xE4aB69C077896252FAFBD49EFD26B5D171A32410;

        // Arbitrum Sepolia Deployments
        address arbRouter = 0x2a9C5afB0d0e4BAb2BCdaE109EC4b0c4Be15a165;

        // Deploy Home Vault to Base Sepolia
        vm.startBroadcast(deployerPrivateKey);
        QuantumEigenDAVerifier eigenVerifier = new QuantumEigenDAVerifier();
        QuantumHomeVault homeVault = new QuantumHomeVault(address(eigenVerifier), programVKey, baseRouter, baseLink);
        vm.stopBroadcast();
        console.log("QuantumHomeVault deployed to Base Sepolia at:", address(homeVault));

        // Deploy Spoke Vault to Arbitrum Sepolia
        // vm.startBroadcast(deployerPrivateKey);
        // QuantumSpokeVault spokeVault = new QuantumSpokeVault(arbRouter);
        // vm.stopBroadcast();
        // console.log("QuantumSpokeVault deployed to Arbitrum Sepolia at:", address(spokeVault));
    }
}
