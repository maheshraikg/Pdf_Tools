import Redis from 'ioredis';

/**
 * Optional Redis. When REDIS_URL is not configured the platform runs in
 * single-node mode with in-memory equivalents (fine for development and
 * small events; production deployments with >1 node must configure Redis).
 */
export function createRedis(cfg, log) {
  if (!cfg.redisUrl) return null;
  const opts = { maxRetriesPerRequest: 2, enableOfflineQueue: true, lazyConnect: false };
  const client = new Redis(cfg.redisUrl, opts);
  const sub = new Redis(cfg.redisUrl, opts);
  for (const c of [client, sub]) c.on('error', (e) => log?.warn({ err: e.message }, 'redis error'));
  return { client, sub };
}
