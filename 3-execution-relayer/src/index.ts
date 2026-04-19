import { app } from "./oracle";

const port = process.env.PORT || 8080;

app.listen(port, () => {
    console.log(`[Proxy] Serverless Orchestrator natively active and bound to port ${port}`);
});
