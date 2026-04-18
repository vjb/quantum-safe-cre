import batch from '@google-cloud/batch';
import dotenv from 'dotenv';
dotenv.config();

const batchClient = new batch.v1.BatchServiceClient();

async function listJobs() {
    const projectId = process.env.GCP_PROJECT_ID || 'total-velocity-493022-f0';
    const region = 'us-east4';
    
    console.log(`[Telemetry] Searching natively for GCP Cloud Batch operations in ${projectId}/${region}...`);
    try {
        const [jobs] = await batchClient.listJobs({
            parent: `projects/${projectId}/locations/${region}`
        });
        if (!jobs || jobs.length === 0) {
            console.log("!!! SYSTEM ASSERTION PROVED: NO BATCH JOBS EXIST IN GCP !!!");
            console.log("This proves the Node Orchestrator proxy is silently crashing without reaching Google's servers.");
        } else {
            console.log(`\n[GCP Telemetry Response] Detected ${jobs.length} native Batch jobs:`);
            console.log("-------------------------------------------------------------------");
            jobs.forEach(j => {
                console.log(`Job Name: ${j.name}`);
                console.log(`Current Status: ${j.status?.state}`);
                if (j.status?.state === 'FAILED' && j.status?.statusEvents) {
                    console.log(`Fatal Events:`, JSON.stringify(j.status.statusEvents, null, 2));
                }
                console.log("-------------------------------------------------------------------");
            });
        }
    } catch (e) {
         console.error("FATAL BATCH CLIENT SDK ERROR THROWN:", e);
    }
}
listJobs();
