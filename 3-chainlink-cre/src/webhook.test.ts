import { test, expect, describe, beforeAll, afterAll, mock, jest } from "bun:test";
import axios from 'axios';

// 1. Storage SDK Mocks ensuring execution cost limits
const mockDelete = jest.fn().mockResolvedValue({});
const mockDownload = jest.fn().mockResolvedValue([
    Buffer.from(JSON.stringify({ proof: "0xREAL", publicValues: "0xVAL" }))
]);
const mockFile = jest.fn().mockReturnValue({
    download: mockDownload,
    delete: mockDelete
});
const mockBucket = jest.fn().mockReturnValue({
    file: mockFile
});

mock.module("@google-cloud/storage", () => {
    return {
        Storage: class {
            bucket = mockBucket;
        }
    };
});

// 2. Axios Network Extradition mock
let postMock = jest.spyOn(axios, 'post').mockResolvedValue({});

import express from 'express';
import { setupWebhookRoutes } from './webhook';
const app = express();
app.use(express.json());
setupWebhookRoutes(app);

describe("GCS Webhook Callbacks", () => {
    let server: any;

    beforeAll(() => {
        process.env.GCS_BUCKET_NAME = "test-bucket";
        process.env.CHAINLINK_NODE_URL = "http://fake-node";
        server = app.listen(0);
    });

    afterAll(() => {
        server.close();
        jest.restoreAllMocks();
    });

    test("successfully intercepts webhook, extracts from GCS, cleans up, and routes to Chainlink", async () => {
        const port = server.address().port;
        const response = await fetch(`http://localhost:${port}/webhook/gcp-complete`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ jobRunId: "job_xyz" })
        });

        expect(response.status).toBe(200);

        // Assertion 1: Verification of GCS extraction bindings targeting proof.json definitively
        expect(mockBucket).toHaveBeenCalledWith("test-bucket");
        expect(mockFile).toHaveBeenCalledWith("job_xyz/proof.json");

        // Assertion 2 & 3: Webhook propagation target mapping & rigorous parsing validation check
        expect(postMock).toHaveBeenCalledTimes(1);
        expect(postMock.mock.calls[0][0]).toBe("http://fake-node/v2/resume/job_xyz");
        expect(postMock.mock.calls[0][1]).toEqual({
            pending: false,
            data: { proof: "0xREAL", publicValues: "0xVAL" }
        });

        // Assertion 4: Verification of Bucket Cleanup enforcing cost limits natively
        expect(mockDelete).toHaveBeenCalledTimes(1);
    });
});
