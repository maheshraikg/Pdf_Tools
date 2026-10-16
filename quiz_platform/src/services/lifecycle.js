// Background jobs. Every node runs them; work is either idempotent or guarded
// by row locks / advisory locks, so running on many nodes is safe.
import { clock } from '../lib/clock.js';
import { freezeAndStart } from './competitions.js';
import { drainSmsOutbox, enqueueNotification } from './notifications.js';
import { finalizeCompetition } from './results.js';

const LOCK_NOTIFY = 7_310_001;
const LOCK_CLEANUP = 7_310_002;

export class Lifecycle {
  constructor(ctx) {
    this.ctx = ctx;
    this.timers = [];
    this.running = new Set();
  }

  start() {
    const { jobs } = this.ctx.cfg;
    this.every(jobs.lifecycleIntervalMs, 'transitions', () => this.transitions());
    this.every(30_000, 'starting-soon', () => this.startingSoon());
    this.every(2_000, 'sms-outbox', () => drainSmsOutbox(this.ctx));
    this.every(3600_000, 'cleanup', () => this.cleanup());
  }

  every(ms, name, fn) {
    const t = setInterval(async () => {
      if (this.running.has(name)) return; // never overlap runs of the same job
      this.running.add(name);
      try { await fn(); } catch (err) { this.ctx.log.error({ err: err.message, job: name }, 'job failed'); } finally { this.running.delete(name); }
    }, ms);
    t.unref();
    this.timers.push(t);
  }

  stop() {
    for (const t of this.timers) clearInterval(t);
  }

  /** Starts (freezes) due competitions and finalises ended ones. */
  async transitions() {
    const { pool, cfg } = this.ctx;
    const due = await pool.query(
      `SELECT id FROM competitions WHERE status = 'scheduled' AND start_at <= $1`, [new Date(clock.nowMs())]);
    for (const { id } of due.rows) {
      const c = await freezeAndStart(this.ctx, id);
      if (c) {
        this.ctx.engine.invalidate(id);
        this.ctx.log.info({ competitionId: id }, 'competition started (frozen)');
      }
    }
    const live = await pool.query(
      `SELECT id FROM competitions
        WHERE status = 'live'
          AND start_at + ((question_count * (question_time_ms + transition_ms) - transition_ms) * interval '1 millisecond')
              <= $1::timestamptz - ($2 * interval '1 millisecond')`,
      [new Date(clock.nowMs()), cfg.jobs.finalizeGraceMs]);
    for (const { id } of live.rows) {
      const r = await finalizeCompetition(this.ctx, id);
      if (r) this.ctx.log.info({ competitionId: id, ranked: r.ranked }, 'competition finalised');
    }
  }

  async startingSoon() {
    const { pool, cfg } = this.ctx;
    const client = await pool.connect();
    try {
      const lock = await client.query('SELECT pg_try_advisory_lock($1) AS ok', [LOCK_NOTIFY]);
      if (!lock.rows[0].ok) return;
      try {
        const soon = await client.query(
          `UPDATE competitions SET start_notified_at = now()
            WHERE status = 'scheduled' AND start_notified_at IS NULL
              AND start_at <= now() + ($1 * interval '1 minute') AND start_at > now()
            RETURNING id, title, start_at, notify_sms`, [cfg.notifications.startingSoonMinutes]);
        for (const c of soon.rows) {
          const regs = await client.query(`SELECT user_id FROM competition_participants WHERE competition_id = $1`, [c.id]);
          for (const r of regs.rows) {
            await enqueueNotification(client, {
              userId: r.user_id, competitionId: c.id, kind: 'starting_soon',
              body: `"${c.title}" starts in ${cfg.notifications.startingSoonMinutes} minutes. Open the app and be ready!`,
              sms: c.notify_sms,
            });
          }
        }
      } finally {
        await client.query('SELECT pg_advisory_unlock($1)', [LOCK_NOTIFY]);
      }
    } finally {
      client.release();
    }
  }

  async cleanup() {
    const { pool } = this.ctx;
    const client = await pool.connect();
    try {
      const lock = await client.query('SELECT pg_try_advisory_lock($1) AS ok', [LOCK_CLEANUP]);
      if (!lock.rows[0].ok) return;
      try {
        await client.query(`DELETE FROM otp_challenges WHERE created_at < now() - interval '2 days'`);
        await client.query(`DELETE FROM sessions WHERE expires_at < now() - interval '7 days'`);
      } finally {
        await client.query('SELECT pg_advisory_unlock($1)', [LOCK_CLEANUP]);
      }
    } finally {
      client.release();
    }
  }
}
