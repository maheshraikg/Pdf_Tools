// Builds the Fastify application and the shared service context.
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { monitorEventLoopDelay } from 'node:perf_hooks';
import Fastify from 'fastify';
import cookie from '@fastify/cookie';
import fastifyStatic from '@fastify/static';
import websocket from '@fastify/websocket';
import { loadConfig } from './config.js';
import { createPool } from './lib/db.js';
import { createRedis } from './lib/redis.js';
import { RateLimiter } from './lib/ratelimit.js';
import { SharedCache } from './lib/cache.js';
import { createMetrics } from './lib/metrics.js';
import { AppError } from './lib/errors.js';
import { createSmsProvider } from './sms/index.js';
import { Engine } from './services/engine.js';
import { EventBus, Hub } from './services/realtime.js';
import { Lifecycle } from './services/lifecycle.js';
import { participantRoutes } from './routes/participant.js';
import { adminRoutes } from './routes/admin.js';

const here = path.dirname(fileURLToPath(import.meta.url));

export async function buildApp({ config, logger = true, pool, sms } = {}) {
  const cfg = config ?? loadConfig();
  const app = Fastify({
    logger: logger === false ? false : {
      level: cfg.logLevel,
      redact: ['req.headers.authorization', 'req.headers.cookie', 'res.headers["set-cookie"]'],
    },
    trustProxy: cfg.trustProxy,
    bodyLimit: 512 * 1024,
  });

  const loop = monitorEventLoopDelay({ resolution: 20 });
  loop.enable();

  const redis = createRedis(cfg, app.log);
  const ctx = {
    cfg,
    log: app.log,
    pool: pool ?? createPool(cfg),
    redis,
    metrics: createMetrics(),
    sessionCache: new Map(),
    loopLag: () => Math.round(loop.mean / 1e4) / 100,
  };
  ctx.limiter = new RateLimiter(redis?.client ?? null);
  ctx.cache = new SharedCache(redis?.client ?? null, 'quiz:cache');
  ctx.provisionalCache = new SharedCache(null);
  ctx.sms = sms ?? createSmsProvider(cfg, app.log);
  ctx.bus = new EventBus(redis, app.log);
  ctx.engine = new Engine(ctx);
  ctx.hub = new Hub(ctx);
  ctx.hub.startHeartbeat();
  ctx.lifecycle = new Lifecycle(ctx);
  app.decorate('ctx', ctx);

  await app.register(cookie);
  await app.register(websocket, { options: { maxPayload: 4096 } });

  // ---- security headers ----------------------------------------------------
  app.addHook('onSend', async (req, reply, payload) => {
    reply.header('X-Content-Type-Options', 'nosniff');
    reply.header('X-Frame-Options', 'DENY');
    reply.header('Referrer-Policy', 'no-referrer');
    reply.header('Permissions-Policy', 'camera=(), microphone=(), geolocation=()');
    reply.header('Cross-Origin-Opener-Policy', 'same-origin');
    reply.header('Content-Security-Policy',
      "default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self' https: data:; connect-src 'self' ws: wss:; " +
      "font-src 'self'; object-src 'none'; base-uri 'none'; frame-ancestors 'none'; form-action 'self'");
    if (cfg.session.cookieSecure) reply.header('Strict-Transport-Security', 'max-age=31536000; includeSubDomains');
    if (req.url.startsWith('/api/')) reply.header('Cache-Control', 'no-store');
    return payload;
  });

  // ---- global abuse protection + CSRF ------------------------------------------
  app.addHook('onRequest', async (req, reply) => {
    req.startTime = process.hrtime.bigint();
    if (!req.url.startsWith('/api/') && !req.url.startsWith('/ws')) return;
    const r = await ctx.limiter.hit(`global:${req.ip}`, cfg.rateLimit.globalPerIpPerMinute, 60_000);
    if (!r.allowed) {
      reply.header('Retry-After', Math.ceil(r.retryAfterMs / 1000));
      throw new AppError(429, 'rate_limited', 'Too many requests. Please slow down.');
    }
    // Cookie-authenticated state changes must carry a custom header. Browsers
    // cannot add it cross-origin without a CORS preflight (which we never
    // grant), which blocks CSRF. Bearer-token clients are not affected.
    if (!['GET', 'HEAD', 'OPTIONS'].includes(req.method) && !req.headers.authorization) {
      if (req.headers['x-requested-with'] !== 'quiz-app') {
        throw new AppError(403, 'csrf', 'Missing anti-CSRF header');
      }
    }
  });

  app.addHook('onResponse', async (req, reply) => {
    if (!req.startTime) return;
    const route = req.routeOptions?.url ?? 'unmatched';
    ctx.metrics.httpDuration.observe(
      { method: req.method, route, status: reply.statusCode },
      Number(process.hrtime.bigint() - req.startTime) / 1e9,
    );
  });

  app.setErrorHandler((err, req, reply) => {
    if (err instanceof AppError) {
      if (err.details?.retryAfterMs) reply.header('Retry-After', Math.ceil(err.details.retryAfterMs / 1000));
      return reply.status(err.status).send({ error: { code: err.code, message: err.message, ...(err.details ? { details: err.details } : {}) } });
    }
    if (err.validation) {
      return reply.status(400).send({ error: { code: 'invalid_request', message: err.message } });
    }
    if (err.code === '23514' || err.code === '23505') {
      // Constraint / trigger violations: the database refused an unfair or duplicate change.
      req.log.warn({ err: err.message }, 'constraint violation');
      return reply.status(409).send({ error: { code: 'constraint_violation', message: 'The change was rejected because it would break competition rules' } });
    }
    if (err.statusCode && err.statusCode < 500) {
      return reply.status(err.statusCode).send({ error: { code: err.code ?? 'bad_request', message: err.message } });
    }
    req.log.error({ err }, 'unhandled error');
    return reply.status(500).send({ error: { code: 'internal', message: 'Something went wrong. Please try again.' } });
  });

  // ---- operational endpoints ---------------------------------------------------
  app.get('/healthz', async () => ({ ok: true }));
  app.get('/readyz', async (req, reply) => {
    try {
      await ctx.pool.query('SELECT 1');
      return { ok: true };
    } catch {
      return reply.status(503).send({ ok: false });
    }
  });
  app.get('/metrics', async (req, reply) => {
    if (cfg.isProd && process.env.METRICS_TOKEN && req.headers.authorization !== `Bearer ${process.env.METRICS_TOKEN}`) {
      return reply.status(401).send();
    }
    reply.header('Content-Type', ctx.metrics.registry.contentType);
    return ctx.metrics.registry.metrics();
  });

  await app.register(participantRoutes, { prefix: '/api' });
  await app.register(adminRoutes, { prefix: '/api/admin' });

  // ---- static PWA + admin dashboard -------------------------------------------
  await app.register(fastifyStatic, {
    root: path.join(here, '..', 'public'),
    prefix: '/',
    index: ['index.html'],
    // @fastify/static v10 passes the Fastify reply (not the raw response).
    setHeaders(reply, filePath) {
      if (filePath.endsWith('sw.js') || filePath.endsWith('.html')) reply.header('Cache-Control', 'no-cache');
      else reply.header('Cache-Control', 'public, max-age=3600');
    },
  });
  app.setNotFoundHandler((req, reply) => {
    if (req.url.startsWith('/api/')) return reply.status(404).send({ error: { code: 'not_found', message: 'Not found' } });
    if (req.url.startsWith('/admin')) return reply.sendFile('admin/index.html');
    return reply.sendFile('index.html');
  });

  app.addHook('onClose', async () => {
    ctx.lifecycle.stop();
    ctx.hub.close();
    ctx.limiter.close();
    loop.disable();
    if (redis) { redis.client.disconnect(); redis.sub.disconnect(); }
    if (!pool) await ctx.pool.end();
  });

  return app;
}
