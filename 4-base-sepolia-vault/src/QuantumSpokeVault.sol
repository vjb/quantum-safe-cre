// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {CCIPReceiver} from "@chainlink/contracts-ccip/contracts/applications/CCIPReceiver.sol";
import {Client} from "@chainlink/contracts-ccip/contracts/libraries/Client.sol";

contract QuantumSpokeVault is CCIPReceiver {
    // allowlist: mapping of source chain selector => (primary vault address => bool)
    mapping(uint64 => mapping(address => bool)) public allowlist;

    event IntentExecuted(bytes32 indexed messageId, address indexed target, uint256 amount);

    constructor(address _router) CCIPReceiver(_router) {}

    function setAllowlist(uint64 _sourceChainSelector, address _primaryVault, bool _allowed) external {
        // Note: In an institutional deployment, this function should be secured by an owner.
        allowlist[_sourceChainSelector][_primaryVault] = _allowed;
    }

    function _ccipReceive(Client.Any2EVMMessage memory any2EvmMessage) internal override {
        address sender = abi.decode(any2EvmMessage.sender, (address));
        require(allowlist[any2EvmMessage.sourceChainSelector][sender], "Security Error: Unauthorized sender or chain");

        (address target, uint256 amount) = abi.decode(any2EvmMessage.data, (address, uint256));

        // Logic placeholder for target execution
        
        emit IntentExecuted(any2EvmMessage.messageId, target, amount);
    }
}
