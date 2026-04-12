"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const bun_test_1 = require("bun:test");
// The Mock: Spy on the native GCP Orchestrator wrapper correctly isolating module properties
bun_test_1.mock.module("./gcp_orchestrator", () => ({
    spawnProverInstance: (0, bun_test_1.mock)(async () => { })
}));
const oracle_1 = require("./oracle");
const gcp_orchestrator_1 = require("./gcp_orchestrator");
(0, bun_test_1.describe)("Oracle Async Endpoint", () => {
    let server;
    (0, bun_test_1.beforeAll)(() => {
        server = oracle_1.app.listen(0);
    });
    (0, bun_test_1.afterAll)(() => {
        server.close();
    });
    (0, bun_test_1.test)("POST /prove triggers async hold and immediately bypasses HTTP connection targeting GCP SDK array", async () => {
        const port = server.address().port;
        // The Action
        const response = await fetch(`http://localhost:${port}/prove`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ id: "job_12345", data: { intent: "test" } }),
        });
        // The Bulletproof Assertions
        (0, bun_test_1.expect)(response.status).toBe(200);
        const body = await response.json();
        (0, bun_test_1.expect)(body).toEqual({ jobRunID: "job_12345", data: {}, pending: true });
        (0, bun_test_1.expect)(gcp_orchestrator_1.spawnProverInstance).toHaveBeenCalledWith("job_12345", { intent: "test" });
    });
});
