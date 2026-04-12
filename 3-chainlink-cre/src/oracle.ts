import express from 'express';
import { spawnProverInstance } from './gcp_orchestrator';
import { setupWebhookRoutes } from './webhook';

export const app = express();
app.use(express.json());

// Bind Async Webhook Catchers natively to Express
setupWebhookRoutes(app);

app.post('/prove', (req, res) => {
    const id = req.body.id;
    const data = req.body.data;

    // Call synchronously but do not await. Execute the dynamic Spot provisioning mapping natively!
    spawnProverInstance(id, data).catch((err: any) => {
        console.error(`[Entrypoint] Fatal Orchestrator Spawning Block: ${err.message}`);
    });

    // Immediately return an HTTP 200 response to hold the async adapter pipeline perfectly
    res.status(200).json({ jobRunID: id, data: {}, pending: true });
});
