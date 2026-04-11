import { ethers } from 'ethers';
import { listenAndRoute } from './router';
import * as child_process from 'child_process';
import * as http from 'http';
import * as fs from 'fs';
import * as path from 'path';

// Parse Compiled Smart Contract Payload natively
const vaultArtifactPath = path.join(__dirname, '../4-base-sepolia-vault/out/QuantumVault.sol/QuantumVault.json');
const vaultArtifact = JSON.parse(fs.readFileSync(vaultArtifactPath, 'utf8'));

describe('Trap-Proof Router Integration', () => {
    let anvilProcess: child_process.ChildProcess;
    let httpServer: http.Server;
    let provider: ethers.JsonRpcProvider;
    let wallet: ethers.Wallet;
    let vaultContract: ethers.Contract;

    const RPC_URL = 'http://127.0.0.1:8545';
    const PROOF_PATH = path.join(__dirname, '../proof.json');
    const PROOF_URL = 'http://127.0.0.1:8080/proof.json';

    beforeAll(async () => {
        // [A] Ephemeral File Bridge Generation
        httpServer = http.createServer((req, res) => {
            if (req.url === '/proof.json') {
                const proofData = fs.readFileSync(PROOF_PATH, 'utf8');
                res.writeHead(200, { 'Content-Type': 'application/json' });
                res.end(proofData);
            } else {
                res.writeHead(404);
                res.end();
            }
        });
        await new Promise<void>((resolve) => httpServer.listen(8080, '127.0.0.1', resolve));

        // [B] Spin up Live EVM Fork Native Environment
        anvilProcess = child_process.spawn('anvil', ['--fork-url', 'https://sepolia.base.org'], { stdio: 'pipe' });

        await new Promise<void>((resolve, reject) => {
            const timeout = setTimeout(() => reject('Anvil spawn timeout'), 15000);
            anvilProcess.stdout?.on('data', (data: Buffer) => {
                if (data.toString().includes('Listening on 127.0.0.1:8545')) {
                    clearTimeout(timeout);
                    resolve();
                }
            });
        });

        // [C] Contract Deployment
        provider = new ethers.JsonRpcProvider(RPC_URL);
        wallet = new ethers.Wallet('0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80', provider);

        const factory = new ethers.ContractFactory(vaultArtifact.abi, vaultArtifact.bytecode.object, wallet);
        
        // Official Universal SP1 Verifier dynamically serving Base Sepolia
        const realVerifier = '0x397A5f7f3dBd538f23DE225B51f532c34448dA9B';
        const proofJson = JSON.parse(fs.readFileSync(PROOF_PATH, 'utf8'));
        const vKey = proofJson.vkey;

        const contractDeployment = await factory.deploy(realVerifier, vKey);
        vaultContract = await contractDeployment.waitForDeployment();
    }, 60000); 

    afterAll(async () => {
        if (anvilProcess) anvilProcess.kill();
        if (httpServer) httpServer.close();
        
        // Let the daemon process cool down effectively
        await new Promise(r => setTimeout(r, 1000));
    });

    it('test_E2E_Oracle_Routing', async () => {
        const vaultAddress = await vaultContract.getAddress();
        
        // 1. Hook the Daemon Router
        const activeRouter = await listenAndRoute(RPC_URL, wallet.privateKey, vaultAddress, PROOF_URL);

        // 2. Transmit Async Constraint Payload Natively
        const target = '0x111122223333444455556666777788889999aAaa';
        const amount = 1000;
        
        console.log(`[Test] Requesting Transfer Intent...`);
        const tx = await vaultContract.requestPQCTransfer(target, amount);
        const receipt = await tx.wait();

        const log = receipt.logs.find((l: any) => l.topics[0] === vaultContract.interface.getEvent('PostQuantumIntentLogged')?.topicHash);
        const intentId = log.topics[1];

        // 3. Await Asynchronous Intercept Loop
        console.log(`[Test] Asserting Execution Loop...`);
        let fulfilled = false;
        for (let i = 0; i < 20; i++) {
            await new Promise(r => setTimeout(r, 1000));
            const intentObj = await vaultContract.pendingIntents(intentId);
            if (intentObj.exists === false) {
                fulfilled = true;
                break;
            }
        }
        
        expect(fulfilled).toBe(true);

        activeRouter.removeAllListeners();
    }, 60000); 
});
