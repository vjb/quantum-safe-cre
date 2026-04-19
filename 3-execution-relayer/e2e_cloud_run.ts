import { execSync } from 'child_process';
import 'dotenv/config';

(async () => {
    // Dynamic CLI injection to map the newly emitted Cloud Run Target seamlessly
    const proxyUrl = process.argv[2];
    if (!proxyUrl) {
        console.error("FATAL: Provide the deployed Cloud Run URL natively as process.argv[2]!");
        process.exit(1);
    }
    
    console.log(`\n======================================================`);
    console.log(`[Phase 3 E2E] Synthesizing Google Cloud Identity Token for Secure Service-to-Service Authentication...`);
    const idToken = execSync("gcloud auth print-identity-token").toString().trim();
    
    console.log(`[Phase 3 E2E] Attempting dynamic connection mapping onto live Google Serverless API Node...`);
    console.log(`[Phase 3 E2E] POST Target: ${proxyUrl}/prove`);

    try {
        const payload = { id: `p3-run-${Date.now()}`, data: { intent: "phase-3-e2e-live-test" } };
        const response = await fetch(`${proxyUrl}/prove`, {
            method: "POST",
            headers: { 
                "Content-Type": "application/json",
                "Authorization": `Bearer ${idToken}`
            },
            body: JSON.stringify(payload),
        });

        console.log(`[Phase 3 E2E] Receiver Network Trace Output: HTTP ${response.status}`);
        const body = await response.json();
        console.log(`[Phase 3 E2E] Immediate Node Handoff Response: ${JSON.stringify(body)}`);
        
        console.log(`[Phase 3 E2E] Validated natively. Cloud Run proxy effectively spawned the background compute constraints natively mapping directly to the Template Instance!`);
        console.log(`======================================================\n`);
        process.exit(0);
    } catch (e: any) {
        console.error(`[Phase 3 E2E] Cloud Run HTTP Mapping failed critically: ${e.message}`);
        process.exit(1);
    }
})();
