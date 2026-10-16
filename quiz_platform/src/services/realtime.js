// Real-time delivery over WebSockets.
//
// Each node runs its own precise timers for the live competitions its clients
// are subscribed to. Because the schedule is deterministic (schedule.js), all
// nodes push "question open" / "question closed" events at the same instants
// without needing to coordinate. Cross-node events (cancellation, results
// published, suspensions) travel over Redis pub/sub (EventBus).
//
// Messages are serialised once per broadcast and the same string is written to
// every socket, so a broadcast to 10,000 clients costs one JSON.stringify.
import { EventEmitter } from 'node:events';
import { clock } from '../lib/clock.js';
import { effectiveStatus } from './competitions.js';
import { Engine } from './engine.js';
import { provisionalStandings } from './results.js';
import { timeline } from './schedule.js';

const CHANNEL = 'quiz:events';

export class EventBus extends EventEmitter {
  constructor(redis, log) {
    super();
    this.redis = redis;
    this.log = log;
    if (redis) {
      redis.sub.subscribe(CHANNEL).catch((e) => log.error({ err: e.message }, 'redis subscribe failed'));
      redis.sub.on('message', (ch, msg) => {
        if (ch !== CHANNEL) return;
        try { this.emit('event', JSON.parse(msg)); } catch { /* ignore malformed */ }
      });
    }
  }

  async publish(event) {
    if (this.redis) await this.redis.client.publish(CHANNEL, JSON.stringify(event));
    else setImmediate(() => this.emit('event', event));
  }
}

export class Hub {
  constructor(ctx) {
    this.ctx = ctx;
    this.rooms = new Map(); // competitionId -> Set<socket>
    this.timers = new Map(); // competitionId -> timeout
    this.provTimers = new Map();
    this.sockets = new Set();
    ctx.bus.on('event', (e) => this.onBusEvent(e).catch((err) => ctx.log.error({ err: err.message }, 'bus event failed')));
    this.presenceTimer = setInterval(() => this.publishPresence(), 5000);
    this.presenceTimer.unref();
  }

  localCount() {
    return this.sockets.size;
  }

  async connectedCount(competitionId) {
    const local = this.rooms.get(competitionId)?.size ?? 0;
    if (!this.ctx.redis) return local;
    const all = await this.ctx.redis.client.hgetall(`quiz:presence:${competitionId}`);
    let total = 0;
    const now = Date.now();
    for (const v of Object.values(all)) {
      const [n, at] = v.split(':').map(Number);
      if (now - at < 15_000) total += n;
    }
    return total;
  }

  async publishPresence() {
    if (!this.ctx.redis) return;
    const now = Date.now();
    for (const [id, room] of this.rooms) {
      const key = `quiz:presence:${id}`;
      await this.ctx.redis.client.multi().hset(key, this.ctx.cfg.nodeId, `${room.size}:${now}`).pexpire(key, 60_000).exec().catch(() => {});
    }
  }

  /** Called for every authenticated socket. */
  attach(socket, user) {
    this.sockets.add(socket);
    this.ctx.metrics?.wsConnections.set(this.sockets.size);
    socket.user = user;
    socket.rooms = new Set();
    socket.isAlive = true;
    socket.on('pong', () => { socket.isAlive = true; });
    socket.on('message', (raw) => this.onMessage(socket, raw).catch((err) => {
      this.send(socket, { type: 'error', code: err.code ?? 'error', message: err.message });
    }));
    socket.on('close', () => {
      this.sockets.delete(socket);
      this.ctx.metrics?.wsConnections.set(this.sockets.size);
      for (const id of socket.rooms) this.leave(socket, id);
    });
    this.send(socket, { type: 'hello', serverNow: clock.now() });
  }

  send(socket, msg) {
    if (socket.readyState === 1) socket.send(typeof msg === 'string' ? msg : JSON.stringify(msg));
  }

  broadcast(competitionId, msg) {
    const room = this.rooms.get(competitionId);
    if (!room?.size) return;
    const data = JSON.stringify(msg);
    for (const s of room) {
      // Drop slow consumers instead of buffering unboundedly.
      if (s.bufferedAmount > 1_000_000) { s.terminate(); continue; }
      this.send(s, data);
    }
  }

  async onMessage(socket, raw) {
    if (raw.length > 2048) return;
    let msg;
    try { msg = JSON.parse(raw.toString()); } catch { return; }
    if (msg.type === 'time') {
      // NTP-style clock sync: client computes offset = serverNow - (t0 + t1) / 2.
      this.send(socket, { type: 'time', t0: msg.t0, serverNow: clock.now() });
    } else if (msg.type === 'subscribe' && typeof msg.competitionId === 'string') {
      if (socket.rooms.size >= 3) return;
      const comp = await this.ctx.engine.competition(msg.competitionId);
      socket.rooms.add(comp.id);
      if (!this.rooms.has(comp.id)) this.rooms.set(comp.id, new Set());
      this.rooms.get(comp.id).add(socket);
      this.ensureTimer(comp);
      this.send(socket, { type: 'subscribed', competitionId: comp.id, serverNow: clock.now() });
    } else if (msg.type === 'unsubscribe' && typeof msg.competitionId === 'string') {
      this.leave(socket, msg.competitionId);
    }
  }

  leave(socket, competitionId) {
    socket.rooms.delete(competitionId);
    const room = this.rooms.get(competitionId);
    if (!room) return;
    room.delete(socket);
    if (!room.size) {
      this.rooms.delete(competitionId);
      clearTimeout(this.timers.get(competitionId));
      this.timers.delete(competitionId);
      clearInterval(this.provTimers.get(competitionId));
      this.provTimers.delete(competitionId);
    }
  }

  /** Arms a precise timer for the next schedule boundary of a competition. */
  ensureTimer(comp) {
    if (this.timers.has(comp.id)) return;
    const status = effectiveStatus(comp);
    if (!['scheduled', 'registration_open', 'live'].includes(status)) return;
    const t = timeline(comp);
    const now = clock.now();
    const at = t.at(now);
    let next;
    if (at.phase === 'before' || at.phase === 'transition') next = at.nextOpensAt;
    else if (at.phase === 'question') next = at.closesAt + 1; // just after the inclusive deadline
    else return;
    const delay = next - now;
    if (delay > 2 ** 31 - 1) return; // >24 days away; re-armed on a later subscribe
    const timer = setTimeout(() => {
      this.timers.delete(comp.id);
      this.onBoundary(comp.id).catch((err) => this.ctx.log.error({ err: err.message }, 'boundary failed'));
    }, Math.max(0, delay));
    this.timers.set(comp.id, timer);

    if (comp.show_provisional && !this.provTimers.has(comp.id) && status === 'live') {
      const iv = setInterval(() => this.pushProvisional(comp.id).catch(() => {}), this.ctx.cfg.jobs.provisionalIntervalMs);
      iv.unref();
      this.provTimers.set(comp.id, iv);
    }
  }

  async onBoundary(competitionId) {
    if (!this.rooms.get(competitionId)?.size) return;
    const comp = await this.ctx.engine.competition(competitionId);
    const status = effectiveStatus(comp);
    const now = clock.now();
    const t = timeline(comp);
    const at = t.at(now);
    if (status === 'cancelled') {
      this.broadcast(competitionId, { type: 'competition_cancelled', competitionId, reason: comp.cancelled_reason });
      return;
    }
    if (at.phase === 'question') {
      const qs = await this.ctx.engine.questions(comp);
      const q = qs[at.position - 1];
      this.broadcast(competitionId, { type: 'question', serverNow: clock.now(), question: Engine.publicQuestion(q, comp, t) });
    } else if (at.phase === 'transition' || at.phase === 'ended') {
      const position = at.phase === 'ended' ? comp.question_count : at.lastPosition;
      const msg = { type: 'question_closed', serverNow: clock.now(), position, nextOpensAt: at.nextOpensAt ?? null };
      if (comp.reveal_answers) {
        const qs = await this.ctx.engine.questions(comp);
        msg.correctOption = qs[position - 1].correct_option;
      }
      this.broadcast(competitionId, msg);
      if (at.phase === 'ended') {
        this.broadcast(competitionId, { type: 'competition_ended', competitionId, serverNow: clock.now() });
        clearInterval(this.provTimers.get(competitionId));
        this.provTimers.delete(competitionId);
        return;
      }
    } else if (at.phase === 'before') {
      // woke slightly early (timer jitter) — fall through to re-arm
    }
    this.ensureTimer(comp);
  }

  async pushProvisional(competitionId) {
    if (!this.rooms.get(competitionId)?.size) return;
    const comp = await this.ctx.engine.competition(competitionId);
    if (effectiveStatus(comp) !== 'live') return;
    const data = await provisionalStandings(this.ctx, comp);
    this.broadcast(competitionId, {
      type: 'leaderboard', provisional: true, computedAt: data.computedAt, maxMarks: data.maxMarks, total: data.rows.length,
      top: data.rows.slice(0, 10).map((r) => ({ rank: r.rank, registrationId: r.registrationId, displayName: r.displayName, totalMarks: r.totalMarks, correctTimeMs: r.correctTimeMs })),
    });
  }

  async onBusEvent(e) {
    if (e.competitionId) this.ctx.engine.invalidate(e.competitionId);
    switch (e.type) {
      case 'competition_cancelled':
        clearTimeout(this.timers.get(e.competitionId));
        this.timers.delete(e.competitionId);
        this.broadcast(e.competitionId, { type: 'competition_cancelled', competitionId: e.competitionId, reason: e.reason });
        break;
      case 'competition_completed':
        this.broadcast(e.competitionId, { type: 'results_computed', competitionId: e.competitionId });
        break;
      case 'results_published':
        this.ctx.cache.invalidate(`official:${e.competitionId}`).catch(() => {});
        this.broadcast(e.competitionId, { type: 'results_published', competitionId: e.competitionId });
        break;
      case 'user_suspended':
        for (const [k, v] of this.ctx.sessionCache) if (v.value?.subject?.id === e.userId) this.ctx.sessionCache.delete(k);
        for (const s of this.sockets) if (s.user?.id === e.userId) s.close(4003, 'suspended');
        break;
      default:
        break;
    }
  }

  /** Heartbeat: terminates dead connections (mobile networks drop silently). */
  startHeartbeat() {
    this.heartbeat = setInterval(() => {
      for (const s of this.sockets) {
        if (!s.isAlive) { s.terminate(); continue; }
        s.isAlive = false;
        try { s.ping(); } catch { /* closed */ }
      }
    }, 25_000);
    this.heartbeat.unref();
  }

  close() {
    clearInterval(this.heartbeat);
    clearInterval(this.presenceTimer);
    for (const t of this.timers.values()) clearTimeout(t);
    for (const t of this.provTimers.values()) clearInterval(t);
    for (const s of this.sockets) s.terminate();
  }
}
