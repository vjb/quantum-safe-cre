import { test, expect, describe, beforeAll, afterAll, mock } from "bun:test";

// The Mock: Spy on the native GCP Orchestrator wrapper correctly isolating module properties
mock.module("./gcp_orchestrator", () => ({
    spawnProverInstance: mock(async () => {})
}));

import { app } from "./oracle";
import { spawnProverInstance } from "./gcp_orchestrator";

describe("Oracle Async Endpoint", () => {
    let server: any;

    beforeAll(() => {
        server = app.listen(0);
    });

    afterAll(() => {
        server.close();
    });

    test("POST /prove triggers async hold and immediately bypasses HTTP connection targeting GCP SDK array", async () => {
        const port = server.address().port;
        // The Action
        const response = await fetch(`http://localhost:${port}/prove`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ id: "job_12345", data: { intent: "test" } }),
        });

        // The Bulletproof Assertions
        expect(response.status).toBe(200);

        const body = await response.json();
        expect(body).toEqual({ jobRunID: "job_12345", data: {}, pending: true });

        expect(spawnProverInstance).toHaveBeenCalledWith("job_12345", { intent: "test" });
    });
});
