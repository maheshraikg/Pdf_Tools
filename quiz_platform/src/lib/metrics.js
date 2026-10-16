import client from 'prom-client';

export function createMetrics() {
  const registry = new client.Registry();
  client.collectDefaultMetrics({ register: registry });
  const m = {
    registry,
    httpDuration: new client.Histogram({
      name: 'http_request_duration_seconds',
      help: 'HTTP request latency',
      labelNames: ['method', 'route', 'status'],
      buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5],
      registers: [registry],
    }),
    submissions: new client.Counter({
      name: 'quiz_answer_submissions_total',
      help: 'Answer submissions by outcome',
      labelNames: ['outcome'],
      registers: [registry],
    }),
    submitDuration: new client.Histogram({
      name: 'quiz_answer_submit_duration_seconds',
      help: 'Server-side processing time of an answer submission',
      buckets: [0.001, 0.0025, 0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1],
      registers: [registry],
    }),
    wsConnections: new client.Gauge({
      name: 'quiz_ws_connections',
      help: 'Open WebSocket connections on this node',
      registers: [registry],
    }),
    otpSent: new client.Counter({
      name: 'quiz_otp_sent_total',
      help: 'OTP messages sent',
      labelNames: ['result'],
      registers: [registry],
    }),
  };
  return m;
}
