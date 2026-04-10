import * as child_process from 'child_process';
import * as fs from 'fs';
import * as path from 'path';

export function validateJournal(output: string, expectedMessage: string): boolean {
    const lines = output.split('\n');
    const journalMatch = lines.find(line => line.includes('Successfully verified and committed message:'));

    if (!journalMatch) {
        throw new Error('Verification failed: Journal commit missing from node output');
    }

    if (!journalMatch.includes(expectedMessage)) {
        throw new Error(`DON Consensus Failed: Journal Mismatch Detected`);
    }

    return true;
}

function runOracle() {
    const parentIntentPath = path.resolve(__dirname, '../1-client/intent.json');
    if (!fs.existsSync(parentIntentPath)) {
        console.error("intent.json not found! Run the 1-client phase first.");
        process.exit(1);
    }

    const intentData = JSON.parse(fs.readFileSync(parentIntentPath, 'utf8'));
    const expectedMessage = intentData.message;

    console.log(`[DON ORCHESTRATOR] Initializing verification sequence for intent: ${expectedMessage}`);

    try {
        console.log(`[DON ORCHESTRATOR] Executing SP1 STARK Proof generation via zkvm-coprocessor...`);
        // Trigger the ZK-Coprocessor process block
        const isDebug = process.env.DEBUG_DON === 'true';
        if (isDebug) console.log(`[DON DEBUG] Triggering Proof generation with RUST_LOG=script=debug,sp1_sdk=info`);
        
        const dockerVerbosity = isDebug ? '-e RUST_LOG=script=debug,sp1_sdk=info' : '';
        const output = child_process.execSync(`docker run ${dockerVerbosity} zkvm-coprocessor`, { encoding: 'utf8' });
        
        console.log("------------------- DOCKER STARK OUTPUT -------------------");
        console.log(output);
        console.log("-----------------------------------------------------------");

        if (validateJournal(output, expectedMessage)) {
            console.log(`[DON CONSENSUS ACHIEVED] ZK-STARK Proof Verified for payload: ${expectedMessage}`);
        }
    } catch (e) {
        console.error(`[DON MALICIOUS PROVER DETECTED] Invalid proof generation or tamper event caught: ${e}`);
        process.exit(1);
    }
}

// Ensure execution triggers
if (require.main === module) {
    runOracle();
}
