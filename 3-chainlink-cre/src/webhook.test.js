"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const bun_test_1 = require("bun:test");
const axios_1 = __importDefault(require("axios"));
// 1. Storage SDK Mocks ensuring execution cost limits
const mockDelete = bun_test_1.jest.fn().mockResolvedValue({});
const mockDownload = bun_test_1.jest.fn().mockResolvedValue([
    Buffer.from(JSON.stringify({ proof: "0xREAL", publicValues: "0xVAL" }))
]);
const mockFile = bun_test_1.jest.fn().mockReturnValue({
    download: mockDownload,
    delete: mockDelete
});
const mockBucket = bun_test_1.jest.fn().mockReturnValue({
    file: mockFile
});
bun_test_1.mock.module("@google-cloud/storage", () => {
    return {
        Storage: class {
            bucket = mockBucket;
        }
    };
});
// 2. Axios Network Extradition mock
let postMock = bun_test_1.jest.spyOn(axios_1.default, 'post').mockResolvedValue({});
const express_1 = __importDefault(require("express"));
const webhook_1 = require("./webhook");
const app = (0, express_1.default)();
app.use(express_1.default.json());
(0, webhook_1.setupWebhookRoutes)(app);
(0, bun_test_1.describe)("GCS Webhook Callbacks", () => {
    let server;
    (0, bun_test_1.beforeAll)(() => {
        process.env.GCS_BUCKET_NAME = "test-bucket";
        process.env.CHAINLINK_NODE_URL = "http://fake-node";
        server = app.listen(0);
    });
    (0, bun_test_1.afterAll)(() => {
        server.close();
        bun_test_1.jest.restoreAllMocks();
    });
    (0, bun_test_1.test)("successfully intercepts webhook, extracts from GCS, cleans up, and routes to Chainlink", async () => {
        const port = server.address().port;
        const response = await fetch(`http://localhost:${port}/webhook/gcp-complete`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ jobRunId: "job_xyz" })
        });
        (0, bun_test_1.expect)(response.status).toBe(200);
        // Assertion 1: Verification of GCS extraction bindings targeting proof.json definitively
        (0, bun_test_1.expect)(mockBucket).toHaveBeenCalledWith("test-bucket");
        (0, bun_test_1.expect)(mockFile).toHaveBeenCalledWith("job_xyz/proof.json");
        // Assertion 2 & 3: Webhook propagation target mapping & rigorous parsing validation check
        (0, bun_test_1.expect)(postMock).toHaveBeenCalledTimes(1);
        (0, bun_test_1.expect)(postMock.mock.calls[0][0]).toBe("http://fake-node/v2/resume/job_xyz");
        (0, bun_test_1.expect)(postMock.mock.calls[0][1]).toEqual({
            pending: false,
            data: { proof: "0xREAL", publicValues: "0xVAL" }
        });
        // Assertion 4: Verification of Bucket Cleanup enforcing cost limits natively
        (0, bun_test_1.expect)(mockDelete).toHaveBeenCalledTimes(1);
    });
});
