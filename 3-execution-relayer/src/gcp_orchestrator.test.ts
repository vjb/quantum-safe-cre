import { test, expect, describe, beforeAll, afterAll, mock, jest } from "bun:test";

let mockInsert = jest.fn().mockResolvedValue([{}]); // Natively simulating SDK return limits

// Must be initialized precisely before loading gcp_orchestrator bounds
mock.module("@google-cloud/compute", () => {
    class MockClient {
        insert = mockInsert;
    }
    return {
        default: { InstancesClient: MockClient },
        InstancesClient: MockClient
    };
});

import { spawnProverInstance } from "./gcp_orchestrator";

describe("GCP Orchestrator (Spot Enclave provisioning)", () => {
    beforeAll(() => {
        process.env.GCP_PROJECT_ID = 'test-project';
        process.env.GCP_ZONE_POOL = 'us-central1-a,us-east1-b';
        process.env.GCP_INSTANCE_TEMPLATE_URL = 'global/instanceTemplates/test-template';
        process.env.GCS_BUCKET_NAME = 'test-bucket';
        process.env.ADAPTER_WEBHOOK_URL = 'http://test-webhook';
    });

    test("successfully calls generic InstancesClient.insert targeting primary zone", async () => {
        await spawnProverInstance("job_abc", { intent: "test" });

        expect(mockInsert).toHaveBeenCalledTimes(1);
        
        const insertArgs = mockInsert.mock.calls[0][0];

        // Assertion 2: Verify sourceInstanceTemplate matches env exactly
        expect(insertArgs.instanceResource.sourceInstanceTemplate).toBe("global/instanceTemplates/test-template");

        // Assertion 3: Verify metadata items map to constraints correctly
        const startupScriptObj = insertArgs.instanceResource.metadata.items.find(
            (i: any) => i.key === "startup-script"
        );
        expect(startupScriptObj).toBeDefined();

        const scriptContent = startupScriptObj.value;
        expect(scriptContent).toContain("gsutil cp");
        expect(scriptContent).toContain("job_abc");
    });
});
