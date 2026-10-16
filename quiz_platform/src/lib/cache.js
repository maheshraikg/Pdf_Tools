/**
 * Tiny TTL cache with single-flight: concurrent callers for the same key share
 * one in-flight computation, so N connected clients asking for the leaderboard
 * at once cause at most one database query per TTL window per node.
 * When Redis is configured, values are also shared across nodes.
 */
export class SharedCache {
  constructor(redis, prefix = 'cache') {
    this.redis = redis;
    this.prefix = prefix;
    this.mem = new Map();
    this.inflight = new Map();
  }

  async get(key, ttlMs, compute) {
    const now = Date.now();
    const hit = this.mem.get(key);
    if (hit && hit.expires > now) return hit.value;
    if (this.inflight.has(key)) return this.inflight.get(key);
    const p = (async () => {
      try {
        if (this.redis) {
          const raw = await this.redis.get(`${this.prefix}:${key}`).catch(() => null);
          if (raw) {
            const value = JSON.parse(raw);
            this.mem.set(key, { value, expires: Date.now() + Math.min(ttlMs, 1000) });
            return value;
          }
        }
        const value = await compute();
        this.mem.set(key, { value, expires: Date.now() + ttlMs });
        if (this.redis) {
          await this.redis.set(`${this.prefix}:${key}`, JSON.stringify(value), 'PX', ttlMs).catch(() => {});
        }
        return value;
      } finally {
        this.inflight.delete(key);
      }
    })();
    this.inflight.set(key, p);
    return p;
  }

  async invalidate(key) {
    this.mem.delete(key);
    if (this.redis) await this.redis.del(`${this.prefix}:${key}`).catch(() => {});
  }
}
