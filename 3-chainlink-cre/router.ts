import { ethers } from 'ethers';

const VAULT_ABI = [
    "event PostQuantumIntentLogged(bytes32 indexed intentId, address target, uint256 amount)",
    "function fulfillPQCTransfer(bytes32 intentId, bytes calldata proofBytes, bytes calldata publicValues) external"
];

export async function listenAndRoute(
    rpcUrl: string, 
    privateKey: string,
    vaultAddress: string,
    proofEndpoint: string
) {
    const provider = new ethers.JsonRpcProvider(rpcUrl);
    const wallet = new ethers.Wallet(privateKey, provider);
    const vaultContract = new ethers.Contract(vaultAddress, VAULT_ABI, wallet);

    console.log(`[Router] Initializing Trap-Proof Oracle Listener bound to ${vaultAddress}...`);

    vaultContract.on("PostQuantumIntentLogged", async (intentId, target, amount, event) => {
        console.log(`\n[Router] 🚨 Intercepted Pending Intent: ${intentId}`);
        console.log(`[Router] Bridging off-chain STARK Matrix payload from ${proofEndpoint}...`);
        
        try {
            const response = await fetch(proofEndpoint);
            if (!response.ok) throw new Error("Failed to natively extract proof metric bounds.");
            const proofData = await response.json();

            console.log(`[Router] 🔗 Mathematical consensus downloaded. Re-injecting into EVM pipeline...`);
            
            const tx = await vaultContract.fulfillPQCTransfer(
                intentId, 
                proofData.proofBytes, 
                proofData.publicValues
            );
            
            console.log(`[Router] Transaction Dispatched: ${tx.hash}`);
            const receipt = await tx.wait();
            console.log(`[Router] ✅ EVM Validated Settlement in block ${receipt.blockNumber}`);
        } catch (error) {
            console.error(`[Router] Execution Fault:`, error);
        }
    });

    return vaultContract;
}
