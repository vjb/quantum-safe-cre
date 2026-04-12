"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
const ethers_1 = require("ethers");
const router_1 = require("./router");
const child_process = __importStar(require("child_process"));
const http = __importStar(require("http"));
const fs = __importStar(require("fs"));
const path = __importStar(require("path"));
// Parse Compiled Smart Contract Payload natively
const vaultArtifactPath = path.join(__dirname, '../4-base-sepolia-vault/out/QuantumVault.sol/QuantumVault.json');
const vaultArtifact = JSON.parse(fs.readFileSync(vaultArtifactPath, 'utf8'));
describe('Trap-Proof Router Integration', () => {
    let anvilProcess;
    let httpServer;
    let provider;
    let wallet;
    let vaultContract;
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
            }
            else {
                res.writeHead(404);
                res.end();
            }
        });
        await new Promise((resolve) => httpServer.listen(8080, '127.0.0.1', resolve));
        // [B] Spin up Live EVM Fork Native Environment
        anvilProcess = child_process.spawn('anvil', ['--fork-url', 'https://sepolia.base.org'], { stdio: 'pipe' });
        await new Promise((resolve, reject) => {
            const timeout = setTimeout(() => reject('Anvil spawn timeout'), 15000);
            anvilProcess.stdout?.on('data', (data) => {
                if (data.toString().includes('Listening on 127.0.0.1:8545')) {
                    clearTimeout(timeout);
                    resolve();
                }
            });
        });
        // [C] Contract Deployment
        provider = new ethers_1.ethers.JsonRpcProvider(RPC_URL);
        wallet = new ethers_1.ethers.Wallet('0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80', provider);
        const factory = new ethers_1.ethers.ContractFactory(vaultArtifact.abi, vaultArtifact.bytecode.object, wallet);
        // Official Universal SP1 Verifier dynamically serving Base Sepolia
        const realVerifier = '0x397A5f7f3dBd538f23DE225B51f532c34448dA9B';
        const proofJson = JSON.parse(fs.readFileSync(PROOF_PATH, 'utf8'));
        const vKey = proofJson.vkey;
        const contractDeployment = await factory.deploy(realVerifier, vKey);
        vaultContract = await contractDeployment.waitForDeployment();
    }, 60000);
    afterAll(async () => {
        if (anvilProcess)
            anvilProcess.kill();
        if (httpServer)
            httpServer.close();
        // Let the daemon process cool down effectively
        await new Promise(r => setTimeout(r, 1000));
    });
    it('test_E2E_Oracle_Routing', async () => {
        const vaultAddress = await vaultContract.getAddress();
        // 1. Hook the Daemon Router
        const activeRouter = await (0, router_1.listenAndRoute)(RPC_URL, wallet.privateKey, vaultAddress, PROOF_URL);
        // 2. Transmit Async Constraint Payload Natively
        const target = '0x111122223333444455556666777788889999aAaa';
        const amount = 1000;
        console.log(`[Test] Requesting Transfer Intent...`);
        const tx = await vaultContract.requestPQCTransfer(target, amount);
        const receipt = await tx.wait();
        const log = receipt.logs.find((l) => l.topics[0] === vaultContract.interface.getEvent('PostQuantumIntentLogged')?.topicHash);
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
