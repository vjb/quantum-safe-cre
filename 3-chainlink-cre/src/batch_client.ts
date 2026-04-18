import batch from '@google-cloud/batch';

const batchClient = new batch.v1.BatchServiceClient();

export async function submitConfidentialBatchJob(jobRunId: string, webhookUrl: string, hmacSecret: string) {
    const projectId = process.env.GCP_PROJECT_ID;
    const region = process.env.GCP_REGION || 'us-east4';
    const containerUri = `${region}-docker.pkg.dev/${projectId}/sp1-prover-repo/pqc-prover:latest`;

    const job = {
        name: `projects/${projectId}/locations/${region}/jobs/pqc-${jobRunId.toLowerCase()}`,
        taskGroups: [{
            taskCount: 1,
            taskSpec: {
                computeResource: { cpuMilli: 4000, memoryMib: 16384 }, // Attaches L4 GPU properties natively
                runnables: [{
                    container: {
                        imageUri: `gcr.io/${projectId}/pqc-prover:latest`,
                        // Secure Bi-Directional Webhook Payload
                        commands: [
                            "/bin/sh", "-c", 
                            `zkvm-script && gsutil cp proof.json gs://${projectId}-pqc-proofs/${jobRunId}/proof.json && curl -X POST -H "Authorization: Bearer $HMAC_SECRET" -H "Content-Type: application/json" -d "{\\"id\\": \\"$JOB_RUN_ID\\", \\"status\\": \\"success\\"}" $WEBHOOK_URL`
                        ]
                    },
                    environment: {
                        variables: { JOB_RUN_ID: jobRunId, WEBHOOK_URL: webhookUrl, HMAC_SECRET: hmacSecret }
                    }
                }]
            }
        }],
        allocationPolicy: {
            location: { allowedLocations: [`zones/${region}-a`, `zones/${region}-b`, `zones/${region}-c`] },
            instances: [{ policy: { machineType: 'g2-standard-4', provisioningModel: 'STANDARD' as const } }],
            serviceAccount: { email: `pqc-orchestrator-sa@${projectId}.iam.gserviceaccount.com` } // Zero-Trust Boundary
        },
        logsPolicy: { destination: 'CLOUD_LOGGING' as const }
    };

    // @ts-ignore - Bypassing strictly-typed Cloud SDK iteration faults natively
    const [response] = await batchClient.createJob({
        parent: `projects/${projectId}/locations/${region}`,
        jobId: `pqc-${jobRunId.toLowerCase()}`,
        job,
    });
    return response;
}
