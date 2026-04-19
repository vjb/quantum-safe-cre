import { submitConfidentialBatchJob } from './batch_client';
import dotenv from 'dotenv';
dotenv.config();

console.log("Testing Batch Submission...");

submitConfidentialBatchJob("demo-12345", "http://localhost", "secret")
    .then(r => console.log("Batch Submit Success!", r))
    .catch(e => console.error("Batch Submit FAILED:", e));
