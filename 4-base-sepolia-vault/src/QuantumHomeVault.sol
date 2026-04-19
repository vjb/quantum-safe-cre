// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IRouterClient} from "@chainlink/contracts-ccip/contracts/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/contracts/libraries/Client.sol";
import {ISP1Verifier} from "./ISP1Verifier.sol";

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract QuantumHomeVault {
    address public sp1Verifier;
    bytes32 public programVKey;
    mapping(uint256 => bool) public executedNonces;

    IRouterClient public router;
    IERC20 public linkToken;

    event PostQuantumIntentLogged(address indexed target, uint256 amount);
    event MessageSent(bytes32 indexed messageId, uint64 indexed destinationChainSelector, address receiver, bytes data);

    constructor(address _sp1Verifier, bytes32 _programVKey, address _router, address _linkToken) {
        sp1Verifier = _sp1Verifier;
        programVKey = _programVKey;
        router = IRouterClient(_router);
        linkToken = IERC20(_linkToken);
    }

    function processPQCProof(bytes calldata proofBytes, bytes calldata publicValues) external {
        // 1. Logic Test: ZK Verification
        ISP1Verifier(sp1Verifier).verifyProof(programVKey, publicValues, proofBytes);

        // 2. Strict ABI Decoding (EVM standard)
        (address target, uint256 amount, uint256 nonce, uint64 destinationChainSelector) = abi.decode(publicValues, (address, uint256, uint256, uint64));

        // 3. Replay Protection
        require(!executedNonces[nonce], "Security Error: Nonce used");
        executedNonces[nonce] = true;

        // 4. Execution Data preparation
        bytes memory executionData = abi.encode(target, amount);

        // 5. Cross-Chain Routing
        Client.EVM2AnyMessage memory evm2AnyMessage = Client.EVM2AnyMessage({
            receiver: abi.encode(target),
            data: executionData,
            tokenAmounts: new Client.EVMTokenAmount[](0),
            extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: 300_000})),
            feeToken: address(linkToken)
        });

        uint256 fees = router.getFee(destinationChainSelector, evm2AnyMessage);
        require(linkToken.balanceOf(address(this)) >= fees, "Insufficient LINK balance for fees");
        
        linkToken.approve(address(router), fees);
        bytes32 messageId = router.ccipSend(destinationChainSelector, evm2AnyMessage);

        emit PostQuantumIntentLogged(target, amount);
        emit MessageSent(messageId, destinationChainSelector, target, executionData);
    }
}
