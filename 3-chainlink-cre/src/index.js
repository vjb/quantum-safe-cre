"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const oracle_1 = require("./oracle");
const port = process.env.PORT || 8080;
oracle_1.app.listen(port, () => {
    console.log(`[Proxy] Serverless Orchestrator natively active and bound to port ${port}`);
});
