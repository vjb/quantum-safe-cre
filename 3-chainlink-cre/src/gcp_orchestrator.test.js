"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const bun_test_1 = require("bun:test");
let mockInsert = bun_test_1.jest.fn().mockResolvedValue([{}]); // Natively simulating SDK return limits
// Must be initialized precisely before loading gcp_orchestrator bounds
bun_test_1.mock.module("@google-cloud/compute", () => {
    class MockClient {
        insert = mockInsert;
    }
    return {
        default: { InstancesClient: MockClient },
        InstancesClient: MockClient
    };
});
const gcp_orchestrator_1 = require("./gcp_orchestrator");
(0, bun_test_1.describe)("GCP Orchestrator (Spot Enclave provisioning)", () => {
    (0, bun_test_1.beforeAll)(() => {
        process.env.GCP_PROJECT_ID = 'test-project';
        process.env.GCP_ZONE_POOL = 'us-central1-a,us-east1-b';
        process.env.GCP_INSTANCE_TEMPLATE_URL = 'global/instanceTemplates/test-template';
        process.env.GCS_BUCKET_NAME = 'test-bucket';
        process.env.ADAPTER_WEBHOOK_URL = 'http://test-webhook';
    });
    (0, bun_test_1.test)("successfully calls generic InstancesClient.insert targeting primary zone", async () => {
        await (0, gcp_orchestrator_1.spawnProverInstance)("job_abc", { intent: "test" });
        (0, bun_test_1.expect)(mockInsert).toHaveBeenCalledTimes(1);
        const insertArgs = mockInsert.mock.calls[0][0];
        // Assertion 2: Verify sourceInstanceTemplate matches env exactly
        (0, bun_test_1.expect)(insertArgs.instanceResource.sourceInstanceTemplate).toBe("global/instanceTemplates/test-template");
        // Assertion 3: Verify metadata items map to constraints correctly
        const startupScriptObj = insertArgs.instanceResource.metadata.items.find((i) => i.key === "startup-script");
        (0, bun_test_1.expect)(startupScriptObj).toBeDefined();
        const scriptContent = startupScriptObj.value;
        (0, bun_test_1.expect)(scriptContent).toContain("gsutil cp");
        (0, bun_test_1.expect)(scriptContent).toContain("job_abc");
    });
});
