import express from 'express';
import { submitConfidentialBatchJob } from './batch_client';
import { setupWebhookRoutes } from './webhook';

export const app = express();
app.use(express.json());

// Bind Async Webhook Catchers natively to Express
setupWebhookRoutes(app);

app.post('/prove', (req, res) => {
    // 1. Authorize via DON Confidential HTTP (Bearer HMAC)
    const authHeader = req.headers.authorization;
    if (!authHeader || authHeader !== `Bearer ${process.env.HMAC_SECRET}`) {
        return res.status(401).json({ error: "Unauthorized: Invalid Confidential Header." });
    }

    const id = req.body.id;
    const webhookUrl = process.env.WEBHOOK_URL || "http://localhost:8080/webhook";
    const hmacSecret = process.env.HMAC_SECRET || "secure-mock-key";

    // Call synchronously but do not await. Execute the dynamic Batch mapping natively!
    submitConfidentialBatchJob(id, webhookUrl, hmacSecret).catch((err: any) => {
        console.error(`[Entrypoint] Fatal Orchestrator Spawning Block: ${err.message}`);
    });

    // Immediately return an HTTP 200 response to hold the async adapter pipeline perfectly
    res.status(200).json({ jobRunID: id, data: {}, pending: true });
});
