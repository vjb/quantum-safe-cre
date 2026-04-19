import pino from 'pino';
import client from 'prom-client';

export const logger = pino({
    level: process.env.LOG_LEVEL || 'info',
    transport: {
        target: 'pino-pretty',
        options: { colorize: true, translateTime: "SYS:standard" }
    }
});

const register = new client.Registry();
client.collectDefaultMetrics({ register });

export const batchQueueTime = new client.Histogram({
    name: 'batch_queue_time_seconds',
    help: 'Time spent in GCP Batch queue',
    buckets: [10, 30, 60, 120, 300, 600, 1200]
});
register.registerMetric(batchQueueTime);

export const starkGenerationLatency = new client.Histogram({
    name: 'stark_generation_latency_seconds',
    help: 'Time taken for SP1 to generate the pure FRI-STARK proof',
    buckets: [30, 60, 120, 300, 600]
});
register.registerMetric(starkGenerationLatency);

export const evmSettlementLatency = new client.Histogram({
    name: 'evm_settlement_latency_seconds',
    help: 'Latency of EVM transaction confirmation',
    buckets: [2, 5, 10, 20, 40]
});
register.registerMetric(evmSettlementLatency);

export const metricsRegister = register;
