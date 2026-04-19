// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/QuantumSpokeVault.sol";

contract DeploySpoke is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address arbRouter = 0x2a9C5afB0d0e4BAb2BCdaE109EC4b0c4Be15a165;

        vm.startBroadcast(deployerPrivateKey);
        QuantumSpokeVault spokeVault = new QuantumSpokeVault(arbRouter);
        vm.stopBroadcast();
        console.log("QuantumSpokeVault deployed at:", address(spokeVault));
    }
}
