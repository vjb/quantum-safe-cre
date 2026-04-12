import { Storage } from '@google-cloud/storage';
import axios from 'axios';
import { Express } from 'express';

export function setupWebhookRoutes(app: Express) {
    app.post('/webhook/gcp-complete', async (req, res) => {
        const { jobRunId } = req.body;
        
        if (!jobRunId) {
            return res.status(400).json({ error: "Missing jobRunId in payload boundaries." });
        }

        console.log(`[Webhook] Intercepted Execution Complete trigger mapping from GCP VM for ${jobRunId}`);
        
        try {
            const bucketName = process.env.GCS_BUCKET_NAME || '';
            const nodeUrl = process.env.CHAINLINK_NODE_URL || '';

            const storage = new Storage();
            const gcsFile = storage.bucket(bucketName).file(`${jobRunId}/proof.json`);

            console.log(`[Webhook] Pulling mapped cryptographic proof matrix cleanly from GCS Bucket isolation: ${bucketName}...`);
            const [fileContent] = await gcsFile.download();
            const parsedProof = JSON.parse(fileContent.toString('utf8'));

            console.log(`[Webhook] Mathematical trace securely isolated. Re-injecting into Chainlink DON Core...`);
            await axios.post(`${nodeUrl}/v2/resume/${jobRunId}`, {
                pending: false,
                data: parsedProof
            });

            console.log(`[Webhook] Consensus fully routed natively! Executing strict GCS Cleanup Protocol deletion bound.`);
            await gcsFile.delete();

            res.status(200).json({ status: "ACK", message: `STARK boundary bridged perfectly for limit target: ${jobRunId}` });
        } catch (error: any) {
            console.error(`[Webhook] FATAL GCS Extraction Error disrupting chain bounds: ${error.message}`);
            // Provide explicit 500 error boundary isolation to prevent ghost locks on the local adapter hook execution.
            res.status(500).json({ error: "Internal Adapter Webhook Failure" });
        }
    });
}
