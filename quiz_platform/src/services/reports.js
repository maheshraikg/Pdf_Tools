// Reporting, exports, monitoring and moderation queries for administrators.
import ExcelJS from 'exceljs';
import { tx } from '../lib/db.js';
import { badRequest, notFound } from '../lib/errors.js';
import { toCsv } from '../lib/csv.js';
import { decrypt } from '../lib/security.js';
import { audit } from './audit.js';
import { revokeAllSessions } from './auth.js';
import { getCompetition } from './competitions.js';
import { timeline } from './schedule.js';

export async function competitionReport(ctx, competitionId) {
  const c = await getCompetition(ctx.pool, competitionId);
  const db = ctx.pool;
  const [counts, scores, dist, perQ, times] = await Promise.all([
    db.query(
      `SELECT count(*)::int AS registered,
              count(*) FILTER (WHERE started_at IS NOT NULL)::int AS started,
              count(*) FILTER (WHERE status = 'completed')::int AS completed,
              count(*) FILTER (WHERE status = 'absent')::int AS absent,
              count(*) FILTER (WHERE status = 'disqualified')::int AS disqualified
         FROM competition_participants WHERE competition_id = $1`, [competitionId]),
    db.query(
      `SELECT avg(total_marks)::float8 AS avg, max(total_marks)::int AS max, min(total_marks)::int AS min,
              percentile_cont(0.5) WITHIN GROUP (ORDER BY total_marks)::float8 AS median,
              count(*) FILTER (WHERE unanswered_count = 15)::int AS no_answers
         FROM competition_results WHERE competition_id = $1`, [competitionId]),
    db.query(
      `SELECT total_marks, count(*)::int AS n FROM competition_results WHERE competition_id = $1
        GROUP BY total_marks ORDER BY total_marks DESC`, [competitionId]),
    db.query(
      `SELECT q.position, q.text, q.correct_option,
              count(a.id) FILTER (WHERE a.is_correct)::int AS correct,
              count(a.id) FILTER (WHERE a.status = 'accepted' AND NOT a.is_correct)::int AS incorrect,
              count(a.id) FILTER (WHERE a.status = 'timeout')::int AS unanswered,
              count(a.id) FILTER (WHERE a.selected_option = 'A')::int AS picked_a,
              count(a.id) FILTER (WHERE a.selected_option = 'B')::int AS picked_b,
              count(a.id) FILTER (WHERE a.selected_option = 'C')::int AS picked_c,
              count(a.id) FILTER (WHERE a.selected_option = 'D')::int AS picked_d,
              avg(a.response_ms)::float8 AS avg_ms,
              percentile_cont(0.5) WITHIN GROUP (ORDER BY a.response_ms)::float8 AS median_ms
         FROM questions q LEFT JOIN answer_submissions a ON a.question_id = q.id
        WHERE q.competition_id = $1 GROUP BY q.id ORDER BY q.position`, [competitionId]),
    db.query(
      `SELECT avg(response_ms)::float8 AS avg_ms, min(response_ms)::int AS min_ms, max(response_ms)::int AS max_ms,
              percentile_cont(ARRAY[0.5, 0.9, 0.99]) WITHIN GROUP (ORDER BY response_ms) AS pct
         FROM answer_submissions WHERE competition_id = $1 AND status = 'accepted'`, [competitionId]),
  ]);
  const cnt = counts.rows[0];
  return {
    competition: { id: c.id, code: c.code, title: c.title, status: c.status, startAt: c.start_at, resultsPublishedAt: c.results_published_at },
    participants: { ...cnt, didNotFinish: cnt.started - cnt.completed },
    scores: scores.rows[0],
    distribution: dist.rows.map((r) => ({ marks: r.total_marks, count: r.n })),
    questions: perQ.rows.map((r) => ({
      position: r.position, text: r.text, correctOption: r.correct_option, correct: r.correct, incorrect: r.incorrect,
      unanswered: r.unanswered, picks: { A: r.picked_a, B: r.picked_b, C: r.picked_c, D: r.picked_d },
      avgResponseMs: r.avg_ms === null ? null : Math.round(r.avg_ms), medianResponseMs: r.median_ms,
    })),
    responseTimes: {
      avgMs: times.rows[0].avg_ms === null ? null : Math.round(times.rows[0].avg_ms),
      minMs: times.rows[0].min_ms, maxMs: times.rows[0].max_ms,
      p50Ms: times.rows[0].pct?.[0] ?? null, p90Ms: times.rows[0].pct?.[1] ?? null, p99Ms: times.rows[0].pct?.[2] ?? null,
    },
  };
}

const EXPORT_HEADERS = [
  'Rank', 'Registration ID', 'Name', 'Mobile', 'Total Marks', 'Attempted', 'Correct', 'Incorrect', 'Unanswered',
  'Correct-Answer Time (ms)', 'Total Response Time (ms)', 'Completed At (UTC)',
  ...Array.from({ length: 15 }, (_, i) => `Q${i + 1} Answer`),
  ...Array.from({ length: 15 }, (_, i) => `Q${i + 1} Time (ms)`),
];

async function exportRows(ctx, competitionId, { includePhone }) {
  const r = await ctx.pool.query(
    `SELECT r.final_rank, u.registration_id, u.display_name, u.phone_enc, u.phone_last4, r.total_marks, r.attempted_count,
            r.correct_count, r.incorrect_count, r.unanswered_count, r.correct_time_ms, r.total_time_ms,
            r.completed_at,
            to_char(r.completed_at AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"') AS completed_iso,
            ARRAY(SELECT COALESCE(a.selected_option || CASE WHEN a.is_correct THEN '✓' ELSE '✗' END, '-')
                    FROM answer_submissions a WHERE a.participant_id = r.participant_id ORDER BY a.question_position) AS answers,
            ARRAY(SELECT a.response_ms FROM answer_submissions a WHERE a.participant_id = r.participant_id ORDER BY a.question_position) AS times
       FROM competition_results r
       JOIN competition_participants p ON p.id = r.participant_id
       JOIN users u ON u.id = p.user_id
      WHERE r.competition_id = $1
      ORDER BY r.final_rank, u.registration_id`, [competitionId]);
  return r.rows.map((x) => [
    x.final_rank, x.registration_id, x.display_name ?? '',
    includePhone ? `+${decrypt(ctx.cfg.keys.phoneEnc, x.phone_enc)}` : `******${x.phone_last4}`,
    x.total_marks, x.attempted_count, x.correct_count, x.incorrect_count, x.unanswered_count,
    x.correct_time_ms, x.total_time_ms, x.completed_iso,
    ...pad(x.answers, '-'), ...pad(x.times, ''),
  ]);
}

const pad = (arr, filler) => Array.from({ length: 15 }, (_, i) => (arr[i] ?? filler));

export async function exportResults(ctx, competitionId, format, admin, { includePhone = false } = {}) {
  const c = await getCompetition(ctx.pool, competitionId);
  if (!c.results_computed_at) throw badRequest('results_not_ready', 'Results are available after the competition completes');
  const rows = await exportRows(ctx, competitionId, { includePhone });
  await audit(ctx.pool, { actorType: 'admin', actorId: admin.id, action: 'results.exported', entityType: 'competition', entityId: competitionId, metadata: { format, includePhone, rows: rows.length } });
  const base = `results-${c.code}`;
  if (format === 'csv') {
    return { filename: `${base}.csv`, contentType: 'text/csv; charset=utf-8', body: toCsv(EXPORT_HEADERS, rows) };
  }
  const wb = new ExcelJS.Workbook();
  wb.creator = 'Quiz Competition Platform';
  const ws = wb.addWorksheet('Results', { views: [{ state: 'frozen', ySplit: 1 }] });
  ws.addRow(EXPORT_HEADERS).font = { bold: true };
  for (const row of rows) ws.addRow(row.map((v) => (typeof v === 'string' && /^[=+\-@]/.test(v) ? `'${v}` : v)));
  ws.columns.forEach((col, i) => { col.width = i < 12 ? [6, 14, 24, 16, 10, 10, 9, 9, 11, 22, 22, 28][i] : 10; });
  const info = wb.addWorksheet('Competition');
  info.addRows([
    ['Title', c.title], ['Code', c.code], ['Start (UTC)', c.start_at.toISOString()],
    ['Results computed (UTC)', c.results_computed_at?.toISOString() ?? ''],
    ['Results published (UTC)', c.results_published_at?.toISOString() ?? 'not published'],
    ['Question set hash', c.question_set_hash ?? ''],
    ['Ranking rules', '1) total marks desc 2) correct-answer time asc 3) total answer time asc 4) completion time asc; full ties share a rank'],
  ]);
  return {
    filename: `${base}.xlsx`,
    contentType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    body: Buffer.from(await wb.xlsx.writeBuffer()),
  };
}

// ---------------------------------------------------------------------------
// Live monitoring
// ---------------------------------------------------------------------------

export async function liveStats(ctx, competitionId) {
  const c = await getCompetition(ctx.pool, competitionId);
  const t = timeline(c);
  const [parts, rate, rej] = await Promise.all([
    ctx.pool.query(
      `SELECT count(*)::int AS registered, count(*) FILTER (WHERE started_at IS NOT NULL)::int AS started
         FROM competition_participants WHERE competition_id = $1`, [competitionId]),
    ctx.pool.query(
      `SELECT count(*) FILTER (WHERE received_at > now() - interval '10 seconds')::int AS last10s,
              count(*) FILTER (WHERE received_at > now() - interval '60 seconds')::int AS last60s,
              count(DISTINCT participant_id) FILTER (WHERE received_at > now() - interval '30 seconds')::int AS active30s,
              count(*) FILTER (WHERE status = 'accepted')::int AS total
         FROM answer_submissions WHERE competition_id = $1`, [competitionId]),
    ctx.pool.query(
      `SELECT reason, count(*)::int AS n FROM submission_rejections WHERE competition_id = $1 GROUP BY reason`, [competitionId]),
  ]);
  return {
    competitionId,
    phase: t.at(Date.now()),
    ...parts.rows[0],
    connected: await ctx.hub.connectedCount(competitionId),
    submissions: { perSecondLast10s: rate.rows[0].last10s / 10, perMinute: rate.rows[0].last60s, total: rate.rows[0].total },
    activeLast30s: rate.rows[0].active30s,
    rejections: Object.fromEntries(rej.rows.map((r) => [r.reason, r.n])),
  };
}

export async function systemHealth(ctx) {
  const t0 = process.hrtime.bigint();
  let dbOk = true;
  try { await ctx.pool.query('SELECT 1'); } catch { dbOk = false; }
  const dbLatencyMs = Number(process.hrtime.bigint() - t0) / 1e6;
  let redisOk = null;
  if (ctx.redis) {
    try { redisOk = (await ctx.redis.client.ping()) === 'PONG'; } catch { redisOk = false; }
  }
  const mem = process.memoryUsage();
  return {
    node: ctx.cfg.nodeId,
    uptimeSec: Math.round(process.uptime()),
    db: { ok: dbOk, latencyMs: Math.round(dbLatencyMs * 100) / 100, pool: { total: ctx.pool.totalCount, idle: ctx.pool.idleCount, waiting: ctx.pool.waitingCount } },
    redis: redisOk === null ? 'not configured (single-node mode)' : { ok: redisOk },
    memoryMb: { rss: Math.round(mem.rss / 1e6), heapUsed: Math.round(mem.heapUsed / 1e6) },
    wsConnectionsThisNode: ctx.hub.localCount(),
    eventLoopLagMs: ctx.loopLag?.() ?? null,
  };
}

// ---------------------------------------------------------------------------
// Suspicious activity detection (signals for human review, never automatic bans)
// ---------------------------------------------------------------------------

export async function suspiciousActivity(ctx, competitionId) {
  const [rejections, fast, sharedIp, perfectFast] = await Promise.all([
    ctx.pool.query(
      `SELECT u.registration_id, u.display_name, count(*)::int AS rejections,
              jsonb_object_agg(reason, n) AS by_reason
         FROM (SELECT user_id, reason, count(*)::int AS n FROM submission_rejections
                WHERE competition_id = $1 GROUP BY user_id, reason) s
         JOIN users u ON u.id = s.user_id
        GROUP BY u.id HAVING sum(n) >= 5 ORDER BY sum(n) DESC LIMIT 100`, [competitionId]),
    ctx.pool.query(
      `SELECT u.registration_id, u.display_name, count(*)::int AS fast_answers,
              count(*) FILTER (WHERE a.is_correct)::int AS fast_correct
         FROM answer_submissions a
         JOIN competition_participants p ON p.id = a.participant_id
         JOIN users u ON u.id = p.user_id
        WHERE a.competition_id = $1 AND a.status = 'accepted' AND a.response_ms < 400
        GROUP BY u.id HAVING count(*) >= 3 ORDER BY count(*) FILTER (WHERE a.is_correct) DESC LIMIT 100`, [competitionId]),
    ctx.pool.query(
      `SELECT encode(a.client_ip_hash, 'hex') AS ip_fingerprint, count(DISTINCT a.participant_id)::int AS participants
         FROM answer_submissions a
        WHERE a.competition_id = $1 AND a.client_ip_hash IS NOT NULL
        GROUP BY a.client_ip_hash HAVING count(DISTINCT a.participant_id) >= 5
        ORDER BY 2 DESC LIMIT 50`, [competitionId]),
    ctx.pool.query(
      `SELECT u.registration_id, u.display_name, r.total_marks, r.correct_time_ms
         FROM competition_results r
         JOIN competition_participants p ON p.id = r.participant_id
         JOIN users u ON u.id = p.user_id
        WHERE r.competition_id = $1 AND r.incorrect_count = 0 AND r.unanswered_count = 0 AND r.correct_time_ms < 15 * 800
        ORDER BY r.correct_time_ms LIMIT 50`, [competitionId]),
  ]);
  return {
    notes: 'Signals only. Shared networks (schools, mobile carrier NAT) legitimately produce shared IP fingerprints. Review before acting.',
    repeatedRejections: rejections.rows,
    abnormallyFastAnswers: fast.rows,
    sharedNetworkFingerprints: sharedIp.rows,
    perfectAndVeryFast: perfectFast.rows,
  };
}

// ---------------------------------------------------------------------------
// Participants & users
// ---------------------------------------------------------------------------

export async function listParticipants(ctx, competitionId, { q, page = 1, pageSize = 50 }) {
  const size = Math.min(Math.max(Number(pageSize) || 50, 1), 200);
  const offset = (Math.max(Number(page) || 1, 1) - 1) * size;
  const needle = q ? String(q).trim().slice(0, 60) : '';
  const r = await ctx.pool.query(
    `SELECT u.id AS user_id, u.registration_id, u.display_name, u.phone_last4, u.status AS account_status,
            p.status, p.registered_at, p.started_at, p.completed_at, r.total_marks, r.final_rank,
            count(*) OVER () AS total
       FROM competition_participants p
       JOIN users u ON u.id = p.user_id
       LEFT JOIN competition_results r ON r.participant_id = p.id
      WHERE p.competition_id = $1
        AND ($2 = '' OR u.registration_id = upper($2) OR lower(u.display_name) LIKE '%' || lower(replace(replace(replace($2, '\\', '\\\\'), '%', '\\%'), '_', '\\_')) || '%')
      ORDER BY p.registered_at LIMIT $3 OFFSET $4`,
    [competitionId, needle, size, offset]);
  return {
    total: Number(r.rows[0]?.total ?? 0),
    rows: r.rows.map((x) => ({
      userId: x.user_id, registrationId: x.registration_id, displayName: x.display_name, maskedPhone: `••••••${x.phone_last4}`,
      accountStatus: x.account_status, status: x.status, registeredAt: x.registered_at, startedAt: x.started_at,
      completedAt: x.completed_at, totalMarks: x.total_marks, rank: x.final_rank,
    })),
  };
}

export async function searchUsers(ctx, { q, page = 1 }) {
  const needle = q ? String(q).trim().slice(0, 60) : '';
  const size = 50;
  const offset = (Math.max(Number(page) || 1, 1) - 1) * size;
  const r = await ctx.pool.query(
    `SELECT u.*, (SELECT count(*) FROM competition_participants p WHERE p.user_id = u.id)::int AS competitions,
            count(*) OVER () AS total
       FROM users u
      WHERE ($1 = '' OR u.registration_id = upper($1) OR u.phone_last4 = $1
             OR lower(u.display_name) LIKE '%' || lower(replace(replace(replace($1, '\\', '\\\\'), '%', '\\%'), '_', '\\_')) || '%')
      ORDER BY u.created_at DESC LIMIT $2 OFFSET $3`, [needle, size, offset]);
  return {
    total: Number(r.rows[0]?.total ?? 0),
    rows: r.rows.map((u) => ({
      id: u.id, registrationId: u.registration_id, displayName: u.display_name, maskedPhone: `••••••${u.phone_last4}`,
      status: u.status, suspendedReason: u.suspended_reason, registeredAt: u.created_at, competitions: u.competitions,
    })),
  };
}

export async function setUserSuspended(ctx, userId, suspended, reason, admin) {
  if (suspended && String(reason ?? '').trim().length < 3) throw badRequest('reason_required', 'A reason is required to suspend an account');
  const r = await tx(ctx.pool, async (db) => {
    const u = await db.query(
      `UPDATE users SET status = $2, suspended_reason = $3, suspended_at = CASE WHEN $2 = 'suspended' THEN now() END, updated_at = now()
        WHERE id = $1 RETURNING *`,
      [userId, suspended ? 'suspended' : 'active', suspended ? String(reason).trim().slice(0, 500) : null]);
    if (!u.rowCount) throw notFound('user_not_found', 'User not found');
    await audit(db, { actorType: 'admin', actorId: admin.id, action: suspended ? 'user.suspended' : 'user.reinstated', entityType: 'user', entityId: userId, metadata: { reason: reason ?? null } });
    return u.rows[0];
  });
  if (suspended) {
    await revokeAllSessions(ctx, 'user', userId);
    await ctx.bus.publish({ type: 'user_suspended', userId });
  }
  return { id: r.id, status: r.status };
}

export async function auditLogs(ctx, { entityType, entityId, action, page = 1 }) {
  const size = 100;
  const offset = (Math.max(Number(page) || 1, 1) - 1) * size;
  const r = await ctx.pool.query(
    `SELECT l.id, l.actor_type, l.actor_id, a.email AS actor_email, l.action, l.entity_type, l.entity_id, l.metadata, l.created_at
       FROM audit_logs l LEFT JOIN admin_users a ON a.id = l.actor_id AND l.actor_type = 'admin'
      WHERE ($1::text IS NULL OR l.entity_type = $1) AND ($2::text IS NULL OR l.entity_id = $2) AND ($3::text IS NULL OR l.action LIKE $3 || '%')
      ORDER BY l.id DESC LIMIT $4 OFFSET $5`,
    [entityType || null, entityId || null, action || null, size, offset]);
  return r.rows;
}
