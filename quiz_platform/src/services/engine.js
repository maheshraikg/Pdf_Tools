// Live quiz engine: competition state, question delivery and answer submission.
//
// Fairness invariants (enforced here AND by database constraints):
//   * the server clock decides which question is open; clients only render it
//   * an answer is accepted only if received within [opensAt, opensAt + 10,000 ms]
//   * response time = server receipt − scheduled opening, integer milliseconds
//   * one answer per participant per question (UNIQUE(participant_id, question_id))
//   * replays with the same option are idempotent; a different option is rejected
//   * the correct option never leaves the server while a question is open
import { clock, toPgTimestamp } from '../lib/clock.js';
import { conflict, forbidden, notFound, AppError } from '../lib/errors.js';
import { ipHash } from './audit.js';
import { getCompetition, effectiveStatus, publicCompetition } from './competitions.js';
import { responseMs, timeline } from './schedule.js';

const COMP_TTL_MS = 1000;

export class Engine {
  constructor(ctx) {
    this.ctx = ctx;
    this.comps = new Map(); // id -> { comp, loadedAt }
    this.questionSets = new Map(); // id:hash -> questions[] (immutable once frozen)
    this.participants = new Map(); // compId:userId -> participant row (small, per live comp)
  }

  /** Competition row, cached for ~1 s per node (status changes such as cancellation propagate quickly). */
  async competition(id) {
    const hit = this.comps.get(id);
    const now = Date.now();
    if (hit && now - hit.loadedAt < COMP_TTL_MS) return hit.comp;
    const comp = await getCompetition(this.ctx.pool, id);
    this.comps.set(id, { comp, loadedAt: now });
    return comp;
  }

  invalidate(id) {
    this.comps.delete(id);
    for (const k of this.participants.keys()) if (k.startsWith(`${id}:`)) this.participants.delete(k);
  }

  /** Questions incl. answer key. Cached only once the competition has started (set is frozen). */
  async questions(comp) {
    const started = clock.now() >= comp.start_at.getTime() && comp.status !== 'draft';
    const key = `${comp.id}:${comp.question_set_hash ?? 'started'}`;
    if (started && this.questionSets.has(key)) return this.questionSets.get(key);
    const r = await this.ctx.pool.query(`SELECT * FROM questions WHERE competition_id = $1 ORDER BY position`, [comp.id]);
    if (started) this.questionSets.set(key, r.rows);
    return r.rows;
  }

  async participant(comp, userId) {
    const key = `${comp.id}:${userId}`;
    const hit = this.participants.get(key);
    if (hit) return hit;
    const r = await this.ctx.pool.query(
      `SELECT * FROM competition_participants WHERE competition_id = $1 AND user_id = $2`, [comp.id, userId]);
    if (!r.rowCount) return null;
    if (r.rows[0].started_at) this.participants.set(key, r.rows[0]);
    return r.rows[0];
  }

  /**
   * Marks the participant as entered (started) if the late-entry policy allows.
   * Returns the participant row or throws.
   */
  async enter(comp, user, now) {
    const p = await this.participant(comp, user.id);
    if (!p) throw forbidden('not_registered', 'You are not registered for this competition');
    if (p.status === 'disqualified') throw forbidden('disqualified', 'You have been disqualified from this competition');
    if (p.started_at) return p;
    const t = timeline(comp);
    if (now < t.start) return p;
    if (now > t.endsAt) throw conflict('competition_ended', 'The competition has ended');
    if (!comp.late_entry_allowed && now > t.closesAt(1)) {
      throw forbidden('late_entry_closed', 'Late entry is not allowed for this competition');
    }
    const r = await this.ctx.pool.query(
      `UPDATE competition_participants SET started_at = COALESCE(started_at, $3), status = 'in_progress'
        WHERE competition_id = $1 AND user_id = $2 RETURNING *`,
      [comp.id, user.id, toPgTimestamp(now)],
    );
    this.participants.set(`${comp.id}:${user.id}`, r.rows[0]);
    return r.rows[0];
  }

  /** Public payload for a question: never contains the correct option. */
  static publicQuestion(q, comp, t) {
    return {
      id: q.id,
      position: q.position,
      total: comp.question_count,
      text: q.text,
      options: { A: q.option_a, B: q.option_b, C: q.option_c, D: q.option_d },
      imageUrl: q.image_url,
      category: q.category,
      marks: q.marks,
      opensAt: t.opensAt(q.position),
      closesAt: t.closesAt(q.position),
      durationMs: t.questionTimeMs,
    };
  }

  /**
   * Full state for (re)connecting clients. Never resets timers: everything is
   * derived from the server clock and the frozen schedule.
   */
  async state(user, competitionId) {
    const now = clock.now();
    const comp = await this.competition(competitionId);
    const status = effectiveStatus(comp, now);
    const t = timeline(comp);
    const base = {
      serverNow: now,
      competition: publicCompetition(comp),
      phase: status,
      schedule: { startAt: t.start, endsAt: t.endsAt, questionTimeMs: t.questionTimeMs, transitionMs: t.transitionMs },
    };
    let p = await this.participant(comp, user.id);
    base.registered = Boolean(p);
    if (!p) return base;

    if (status === 'live') {
      try {
        p = await this.enter(comp, user, now);
      } catch (err) {
        if (err instanceof AppError) return { ...base, entryError: { code: err.code, message: err.message } };
        throw err;
      }
    }
    base.participant = { status: p.status, startedAt: p.started_at };
    const answers = await this.ctx.pool.query(
      `SELECT question_position, selected_option, response_ms, status FROM answer_submissions
        WHERE participant_id = $1 ORDER BY question_position`, [p.id]);
    const answered = answers.rows.filter((a) => a.status === 'accepted');
    base.progress = {
      answered: answered.length,
      answeredPositions: answered.map((a) => a.question_position),
    };
    if (status !== 'live') return base;

    const at = t.at(now);
    base.timeline = at;
    const qs = await this.questions(comp);
    if (at.phase === 'question') {
      const q = qs[at.position - 1];
      base.question = Engine.publicQuestion(q, comp, t);
      const mine = answers.rows.find((a) => a.question_position === at.position);
      base.myAnswer = mine ? { selectedOption: mine.selected_option, responseMs: mine.response_ms } : null;
    }
    base.progress.closed = at.phase === 'question' ? at.position - 1 : at.phase === 'transition' ? at.lastPosition : 0;
    base.progress.remaining = comp.question_count - base.progress.closed;
    if (comp.reveal_answers && base.progress.closed > 0) {
      base.revealed = qs.slice(0, base.progress.closed).map((q) => ({ position: q.position, correctOption: q.correct_option }));
    }
    return base;
  }

  /**
   * Submit an answer. The receipt timestamp is taken before any I/O so that
   * database latency never counts against the participant.
   */
  async submit(user, competitionId, { questionId, option, idempotencyKey }, ip) {
    const receivedAt = clock.now();
    const started = process.hrtime.bigint();
    const { ctx } = this;
    try {
      await ctx.limiter.enforce(`submit:${user.id}`, ctx.cfg.rateLimit.submitPerUserPerMinute, 60_000);
      const comp = await this.competition(competitionId);
      const status = effectiveStatus(comp, receivedAt);
      if (status !== 'live') {
        await this.reject(comp.id, user.id, null, `competition_${status}`, ip);
        throw conflict('competition_not_live', status === 'cancelled' ? 'This competition has been cancelled' : 'The competition is not live');
      }
      const opt = String(option ?? '').toUpperCase();
      if (!['A', 'B', 'C', 'D'].includes(opt)) throw new AppError(400, 'invalid_option', 'Choose A, B, C or D');

      const t = timeline(comp);
      const qs = await this.questions(comp);
      const q = qs.find((x) => x.id === questionId);
      if (!q) throw notFound('question_not_found', 'Question not found');
      const opensAt = t.opensAt(q.position);
      const closesAt = t.closesAt(q.position);
      if (receivedAt < opensAt) {
        await this.reject(comp.id, user.id, q.position, 'not_open_yet', ip);
        throw conflict('question_not_open', 'This question is not open yet');
      }
      if (receivedAt > closesAt) {
        await this.reject(comp.id, user.id, q.position, 'deadline_passed', ip);
        throw new AppError(409, 'deadline_passed', 'Time is up for this question; the answer was not accepted', {
          lateByMs: Math.floor(receivedAt - closesAt),
        });
      }

      const p = await this.enter(comp, user, receivedAt);
      if (!p.started_at) throw conflict('competition_not_live', 'The competition is not live');

      const isCorrect = opt === q.correct_option;
      const marks = isCorrect ? q.marks : 0;
      const ms = responseMs(opensAt, receivedAt, t.questionTimeMs);
      const ins = await ctx.pool.query(
        `INSERT INTO answer_submissions
           (competition_id, participant_id, question_id, question_position, selected_option, is_correct,
            marks_awarded, opened_at, received_at, response_ms, status, idempotency_key, client_ip_hash, node_id)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, 'accepted', $11, $12, $13)
         ON CONFLICT (participant_id, question_id) DO NOTHING
         RETURNING id, received_at, response_ms`,
        [comp.id, p.id, q.id, q.position, opt, isCorrect, marks, toPgTimestamp(opensAt), toPgTimestamp(receivedAt), ms,
          typeof idempotencyKey === 'string' ? idempotencyKey.slice(0, 100) : null, ipHash(ctx, ip), ctx.cfg.nodeId],
      );
      if (ins.rowCount) {
        ctx.metrics?.submissions.inc({ outcome: 'accepted' });
        return { accepted: true, duplicate: false, questionId: q.id, position: q.position, selectedOption: opt, responseMs: ms, receivedAt };
      }
      // Already answered: idempotent replay if identical, otherwise rejected.
      const prev = await ctx.pool.query(
        `SELECT selected_option, response_ms, received_at FROM answer_submissions WHERE participant_id = $1 AND question_id = $2`,
        [p.id, q.id]);
      const a = prev.rows[0];
      if (a.selected_option === opt) {
        ctx.metrics?.submissions.inc({ outcome: 'duplicate' });
        return { accepted: true, duplicate: true, questionId: q.id, position: q.position, selectedOption: opt, responseMs: a.response_ms, receivedAt: a.received_at.getTime() };
      }
      await this.reject(comp.id, user.id, q.position, 'already_answered', ip);
      throw conflict('already_answered', 'You have already answered this question', { selectedOption: a.selected_option });
    } catch (err) {
      if (err instanceof AppError) ctx.metrics?.submissions.inc({ outcome: err.code });
      throw err;
    } finally {
      ctx.metrics?.submitDuration.observe(Number(process.hrtime.bigint() - started) / 1e9);
    }
  }

  async reject(competitionId, userId, position, reason, ip) {
    await this.ctx.pool.query(
      `INSERT INTO submission_rejections (competition_id, user_id, question_position, reason, client_ip_hash)
       VALUES ($1, $2, $3, $4, $5)`,
      [competitionId, userId, position, reason, ipHash(this.ctx, ip)],
    ).catch((e) => this.ctx.log.warn({ err: e.message }, 'could not record rejection'));
  }
}
