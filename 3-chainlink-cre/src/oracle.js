"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.app = void 0;
const express_1 = __importDefault(require("express"));
const gcp_orchestrator_1 = require("./gcp_orchestrator");
const webhook_1 = require("./webhook");
exports.app = (0, express_1.default)();
exports.app.use(express_1.default.json());
// Bind Async Webhook Catchers natively to Express
(0, webhook_1.setupWebhookRoutes)(exports.app);
exports.app.post('/prove', (req, res) => {
    const id = req.body.id;
    const data = req.body.data;
    // Call synchronously but do not await. Execute the dynamic Spot provisioning mapping natively!
    (0, gcp_orchestrator_1.spawnProverInstance)(id, data).catch((err) => {
        console.error(`[Entrypoint] Fatal Orchestrator Spawning Block: ${err.message}`);
    });
    // Immediately return an HTTP 200 response to hold the async adapter pipeline perfectly
    res.status(200).json({ jobRunID: id, data: {}, pending: true });
});
