import { tooMany } from './errors.js';

/**
 * Fixed-window rate limiter. Uses Redis (shared across nodes) when available,
 * otherwise an in-process map. hit() returns { allowed, count, retryAfterMs }.
 */
export class RateLimiter {
  constructor(redis, clockNow = Date.now) {
    this.redis = redis;
    this.now = clockNow;
    this.mem = new Map();
    this.sweeper = setInterval(() => this.sweep(), 60_000);
    this.sweeper.unref();
  }

  sweep() {
    const t = this.now();
    for (const [k, v] of this.mem) if (v.resetAt <= t) this.mem.delete(k);
  }

  async hit(key, limit, windowMs, cost = 1) {
    const t = this.now();
    const windowStart = Math.floor(t / windowMs) * windowMs;
    const resetAt = windowStart + windowMs;
    const k = `rl:${key}:${windowStart}`;
    let count;
    if (this.redis) {
      try {
        const res = await this.redis.multi().incrby(k, cost).pexpire(k, windowMs + 1000).exec();
        count = Number(res[0][1]);
      } catch {
        // Redis unavailable: degrade to per-node counting rather than failing requests.
        return this.memHit(k, limit, resetAt, t, cost);
      }
    } else {
      const e = this.mem.get(k) ?? { count: 0, resetAt };
      e.count += cost;
      this.mem.set(k, e);
      count = e.count;
    }
    return { allowed: count <= limit, count, retryAfterMs: Math.max(0, Math.ceil(resetAt - t)) };
  }

  memHit(k, limit, resetAt, t, cost) {
    const e = this.mem.get(k) ?? { count: 0, resetAt };
    e.count += cost;
    this.mem.set(k, e);
    return { allowed: e.count <= limit, count: e.count, retryAfterMs: Math.max(0, Math.ceil(resetAt - t)) };
  }

  async peek(key, windowMs) {
    const t = this.now();
    const windowStart = Math.floor(t / windowMs) * windowMs;
    const k = `rl:${key}:${windowStart}`;
    if (this.redis) {
      try { return Number((await this.redis.get(k)) ?? 0); } catch { /* fall through to memory */ }
    }
    return this.mem.get(k)?.count ?? 0;
  }

  async enforce(key, limit, windowMs, message) {
    const r = await this.hit(key, limit, windowMs);
    if (!r.allowed) throw tooMany('rate_limited', message ?? 'Too many requests. Please try again later.', r.retryAfterMs);
    return r;
  }

  close() {
    clearInterval(this.sweeper);
  }
}
