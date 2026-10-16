// Finalisation, official results, leaderboards (official + provisional).
import { clock } from '../lib/clock.js';
import { tx } from '../lib/db.js';
import { conflict, forbidden, notFound } from '../lib/errors.js';
import { audit } from './audit.js';
import { effectiveStatus, getCompetition } from './competitions.js';
import { rankStandings } from './ranking.js';
import { timeline } from './schedule.js';

// Aggregates per started participant from verified submission records.
const AGG_SQL = `
  SELECT p.id AS participant_id, p.status AS participant_status, u.registration_id, u.display_name,
         COALESCE(SUM(a.marks_awarded), 0)::int                                         AS total_marks,
         COUNT(a.id) FILTER (WHERE a.status = 'accepted')::int                           AS attempted,
         COUNT(a.id) FILTER (WHERE a.is_correct)::int                                    AS correct,
         COUNT(a.id) FILTER (WHERE a.status = 'accepted' AND NOT a.is_correct)::int      AS incorrect,
         COALESCE(SUM(a.response_ms) FILTER (WHERE a.is_correct), 0)::bigint             AS correct_time_ms,
         COALESCE(SUM(a.response_ms) FILTER (WHERE a.status = 'accepted'), 0)::bigint    AS total_time_ms,
         (EXTRACT(EPOCH FROM MAX(a.received_at)) * 1000000)::bigint                      AS last_answer_us,
         (EXTRACT(EPOCH FROM MAX(a.received_at) FILTER (WHERE a.question_position = $2 AND a.status = 'accepted')) * 1000000)::bigint AS final_answer_us
    FROM competition_participants p
    JOIN users u ON u.id = p.user_id
    LEFT JOIN answer_submissions a ON a.participant_id = p.id
   WHERE p.competition_id = $1 AND p.started_at IS NOT NULL
   GROUP BY p.id, u.id`;

function toStanding(row, count) {
  return {
    participantId: row.participant_id,
    registrationId: row.registration_id,
    displayName: row.display_name,
    participantStatus: row.participant_status,
    totalMarks: row.total_marks,
    attempted: row.attempted,
    correct: row.correct,
    incorrect: row.incorrect,
    unanswered: count - row.attempted,
    correctTimeMs: row.correct_time_ms,
    totalTimeMs: row.total_time_ms,
  };
}

/**
 * Computes official results once the last question has closed. Idempotent and
 * safe to call concurrently from several nodes (row lock + status check).
 */
export async function finalizeCompetition(ctx, competitionId) {
  const result = await tx(ctx.pool, async (db) => {
    const c = await getCompetition(db, competitionId, { forUpdate: true });
    const t = timeline(c);
    if (c.status !== 'live' || clock.now() < t.endsAt) return null;

    // 1. Record every unanswered question of every started participant as a timeout.
    await db.query(
      `INSERT INTO answer_submissions (competition_id, participant_id, question_id, question_position, opened_at, status)
       SELECT c.id, p.id, q.id, q.position,
              c.start_at + ((q.position - 1) * (c.question_time_ms + c.transition_ms)) * interval '1 millisecond',
              'timeout'
         FROM competitions c
         JOIN competition_participants p ON p.competition_id = c.id AND p.started_at IS NOT NULL
         JOIN questions q ON q.competition_id = c.id
        WHERE c.id = $1
       ON CONFLICT (participant_id, question_id) DO NOTHING`,
      [competitionId],
    );
    // 2. Registered participants who never entered are "absent" (not ranked).
    await db.query(
      `UPDATE competition_participants SET status = 'absent' WHERE competition_id = $1 AND started_at IS NULL AND status = 'registered'`,
      [competitionId]);

    // 3. Aggregate + rank with the official comparator.
    const agg = await db.query(AGG_SQL, [competitionId, c.question_count]);
    const endsAtUs = t.endsAt * 1000;
    const standings = agg.rows
      .filter((r) => r.participant_status !== 'disqualified')
      .map((r) => ({
        ...toStanding(r, c.question_count),
        // Completion = server time the participant's final question was resolved:
        // receipt of their answer to Q15, otherwise Q15's deadline.
        completedAtUs: r.final_answer_us ?? endsAtUs,
      }));
    const ranked = rankStandings(standings);

    await db.query(`DELETE FROM competition_results WHERE competition_id = $1`, [competitionId]);
    if (ranked.length) {
      await db.query(
        `INSERT INTO competition_results
           (competition_id, participant_id, total_marks, attempted_count, correct_count, incorrect_count,
            unanswered_count, correct_time_ms, total_time_ms, completed_at, final_rank)
         SELECT $1, * FROM unnest($2::uuid[], $3::int[], $4::int[], $5::int[], $6::int[], $7::int[], $8::bigint[], $9::bigint[],
                                  $10::timestamptz[], $11::int[])`,
        [
          competitionId,
          ranked.map((r) => r.participantId), ranked.map((r) => r.totalMarks), ranked.map((r) => r.attempted),
          ranked.map((r) => r.correct), ranked.map((r) => r.incorrect), ranked.map((r) => r.unanswered),
          ranked.map((r) => r.correctTimeMs), ranked.map((r) => r.totalTimeMs),
          ranked.map((r) => usToIso(r.completedAtUs)), ranked.map((r) => r.rank),
        ],
      );
      await db.query(
        `UPDATE competition_participants p SET status = 'completed', completed_at = r.completed_at
           FROM competition_results r WHERE r.participant_id = p.id AND p.competition_id = $1`,
        [competitionId]);
    }
    await db.query(`UPDATE competitions SET status = 'completed', results_computed_at = now() WHERE id = $1`, [competitionId]);
    await audit(db, {
      actorType: 'system', action: 'competition.finalized', entityType: 'competition', entityId: competitionId,
      metadata: { ranked: ranked.length, topScore: ranked[0]?.totalMarks ?? null },
    });
    return { ranked: ranked.length };
  });
  if (result) {
    await ctx.bus.publish({ type: 'competition_completed', competitionId });
    ctx.engine?.invalidate(competitionId);
  }
  return result;
}

function usToIso(us) {
  const ms = Math.floor(us / 1000);
  const rest = String(Math.floor(us % 1000)).padStart(3, '0');
  return `${new Date(ms).toISOString().slice(0, 23)}${rest}Z`;
}

export async function publishResults(ctx, competitionId, admin) {
  const c2 = await tx(ctx.pool, async (db) => {
    const c = await getCompetition(db, competitionId, { forUpdate: true });
    if (c.status !== 'completed' || !c.results_computed_at) throw conflict('results_not_ready', 'Results can be published after the competition has completed');
    if (c.results_published_at) throw conflict('already_published', 'Results are already published');
    const r = await db.query(`UPDATE competitions SET results_published_at = now() WHERE id = $1 RETURNING *`, [competitionId]);
    await db.query(`UPDATE competition_results SET published_at = now() WHERE competition_id = $1`, [competitionId]);
    await db.query(
      `INSERT INTO notifications (user_id, competition_id, kind, channel, body, dedupe_key)
       SELECT p.user_id, $1::uuid, 'results_published', ch.channel,
              'Results for "' || $2::text || '" are published. Your rank: ' || r.final_rank || ', score: ' || r.total_marks || '.',
              $1::text || ':results:' || ch.channel || ':' || p.user_id::text
         FROM competition_results r
         JOIN competition_participants p ON p.id = r.participant_id
         CROSS JOIN (SELECT 'in_app' AS channel UNION ALL SELECT 'sms' WHERE $3::boolean) ch
        WHERE r.competition_id = $1::uuid
       ON CONFLICT (dedupe_key) DO NOTHING`,
      [competitionId, c.title, Boolean(c.notify_sms)]);
    await audit(db, { actorType: 'admin', actorId: admin.id, action: 'results.published', entityType: 'competition', entityId: competitionId });
    return r.rows[0];
  });
  ctx.engine?.invalidate(competitionId);
  await ctx.cache.invalidate(`official:${competitionId}`);
  await ctx.bus.publish({ type: 'results_published', competitionId });
  return c2;
}

// ---------------------------------------------------------------------------
// Leaderboards
// ---------------------------------------------------------------------------

async function maxMarks(db, competitionId) {
  const r = await db.query(`SELECT COALESCE(SUM(marks), 0)::int AS m FROM questions WHERE competition_id = $1`, [competitionId]);
  return r.rows[0].m;
}

function leaderboardRow(r, max) {
  return {
    rank: r.rank,
    registrationId: r.registrationId,
    displayName: r.displayName ?? 'Participant',
    totalMarks: r.totalMarks,
    maxMarks: max,
    correct: r.correct,
    incorrect: r.incorrect,
    unanswered: r.unanswered,
    correctTimeMs: r.correctTimeMs,
    totalTimeMs: r.totalTimeMs,
    completionStatus: r.completionStatus,
  };
}

/** Official standings from competition_results (cached; immutable after finalisation). */
async function officialStandings(ctx, competitionId) {
  return ctx.cache.get(`official:${competitionId}`, 30_000, async () => {
    const r = await ctx.pool.query(
      `SELECT r.final_rank, r.total_marks, r.correct_count, r.incorrect_count, r.unanswered_count,
              r.correct_time_ms, r.total_time_ms, p.status, u.registration_id, u.display_name
         FROM competition_results r
         JOIN competition_participants p ON p.id = r.participant_id
         JOIN users u ON u.id = p.user_id
        WHERE r.competition_id = $1
        ORDER BY r.final_rank, u.registration_id`,
      [competitionId]);
    return {
      maxMarks: await maxMarks(ctx.pool, competitionId),
      rows: r.rows.map((x) => ({
        rank: x.final_rank, registrationId: x.registration_id, displayName: x.display_name,
        totalMarks: x.total_marks, correct: x.correct_count, incorrect: x.incorrect_count, unanswered: x.unanswered_count,
        correctTimeMs: x.correct_time_ms, totalTimeMs: x.total_time_ms,
        completionStatus: x.unanswered_count === 15 ? 'no_answers' : 'completed',
      })),
    };
  });
}

/**
 * Provisional standings while live: one aggregate query per node per interval
 * (single-flight cached), shared by every connected participant.
 */
export async function provisionalStandings(ctx, comp) {
  return ctx.provisionalCache.get(`prov:${comp.id}`, ctx.cfg.jobs.provisionalIntervalMs, async () => {
    const agg = await ctx.pool.query(AGG_SQL, [comp.id, comp.question_count]);
    const ranked = rankStandings(agg.rows.filter((r) => r.participant_status !== 'disqualified').map((r) => ({
      ...toStanding(r, comp.question_count),
      completedAtUs: r.last_answer_us ?? Number.MAX_SAFE_INTEGER,
      completionStatus: 'in_progress',
    })));
    return { maxMarks: await maxMarks(ctx.pool, comp.id), rows: ranked, computedAt: clock.nowMs() };
  });
}

export async function leaderboard(ctx, competitionId, { limit = 10, page = 1, q } = {}, { admin = false } = {}) {
  const c = await getCompetition(ctx.pool, competitionId);
  const status = effectiveStatus(c);
  let data;
  let provisional = false;
  if (c.results_published_at || (admin && c.results_computed_at)) {
    data = await officialStandings(ctx, competitionId);
  } else if (status === 'live' && (c.show_provisional || admin)) {
    data = await provisionalStandings(ctx, c);
    provisional = true;
  } else if (status === 'completed' && !c.results_computed_at && admin) {
    data = await provisionalStandings(ctx, c);
    provisional = true;
  } else {
    throw forbidden('leaderboard_unavailable', c.status === 'completed'
      ? 'Results have not been published yet'
      : 'The leaderboard is not available for this competition yet');
  }
  let rows = data.rows;
  if (q && String(q).trim()) {
    const needle = String(q).trim().toLowerCase().slice(0, 60);
    rows = rows.filter((r) => r.registrationId.toLowerCase() === needle || (r.displayName ?? '').toLowerCase().includes(needle));
  }
  const size = Math.min(Math.max(Number(limit) || 10, 1), 100);
  const pg = Math.max(Number(page) || 1, 1);
  const slice = rows.slice((pg - 1) * size, pg * size);
  return {
    competitionId,
    title: c.title,
    provisional,
    official: !provisional && Boolean(c.results_published_at),
    publishedAt: c.results_published_at,
    total: rows.length,
    page: pg,
    pageSize: size,
    maxMarks: data.maxMarks,
    rows: slice.map((r) => leaderboardRow(r, data.maxMarks)),
  };
}

/** Public result card for one participant (only once results are published). */
export async function publicParticipantResult(ctx, competitionId, registrationId) {
  const c = await getCompetition(ctx.pool, competitionId);
  if (!c.results_published_at) throw forbidden('results_not_published', 'Results have not been published yet');
  const data = await officialStandings(ctx, competitionId);
  const row = data.rows.find((r) => r.registrationId === String(registrationId).toUpperCase());
  if (!row) throw notFound('result_not_found', 'No result for this registration ID');
  return { competitionId, title: c.title, total: data.rows.length, ...leaderboardRow(row, data.maxMarks) };
}

/** The signed-in participant's own result, with per-question breakdown after the competition. */
export async function myResult(ctx, user, competitionId) {
  const c = await getCompetition(ctx.pool, competitionId);
  const p = await ctx.pool.query(`SELECT * FROM competition_participants WHERE competition_id = $1 AND user_id = $2`, [competitionId, user.id]);
  if (!p.rowCount) throw notFound('not_registered', 'You did not register for this competition');
  const part = p.rows[0];
  const status = effectiveStatus(c);
  const ended = status === 'completed';
  const subs = await ctx.pool.query(
    `SELECT a.question_position, a.selected_option, a.is_correct, a.marks_awarded, a.response_ms, a.status,
            q.text, q.option_a, q.option_b, q.option_c, q.option_d, q.correct_option
       FROM answer_submissions a JOIN questions q ON q.id = a.question_id
      WHERE a.participant_id = $1 ORDER BY a.question_position`, [part.id]);
  const accepted = subs.rows.filter((s) => s.status === 'accepted');
  const summary = {
    totalMarks: accepted.reduce((s, a) => s + a.marks_awarded, 0),
    maxMarks: await maxMarks(ctx.pool, competitionId),
    attempted: accepted.length,
    correct: accepted.filter((a) => a.is_correct).length,
    incorrect: accepted.filter((a) => !a.is_correct).length,
    unanswered: c.question_count - accepted.length,
    correctTimeMs: accepted.filter((a) => a.is_correct).reduce((s, a) => s + a.response_ms, 0),
    totalTimeMs: accepted.reduce((s, a) => s + a.response_ms, 0),
  };
  if (!ended) {
    // Never reveal correctness while the competition is running.
    return { competitionId, title: c.title, status, participantStatus: part.status, final: false,
      answered: accepted.length, answeredPositions: accepted.map((a) => a.question_position) };
  }
  let rank = null;
  let rankedCount = null;
  if (c.results_published_at) {
    const r = await ctx.pool.query(`SELECT final_rank FROM competition_results WHERE participant_id = $1`, [part.id]);
    rank = r.rows[0]?.final_rank ?? null;
    const n = await ctx.pool.query(`SELECT count(*)::int AS n FROM competition_results WHERE competition_id = $1`, [competitionId]);
    rankedCount = n.rows[0].n;
  }
  return {
    competitionId, title: c.title, status, participantStatus: part.status, final: Boolean(c.results_computed_at),
    resultsPublished: Boolean(c.results_published_at), rank, rankedCount, ...summary,
    questions: subs.rows.map((s) => ({
      position: s.question_position, text: s.text,
      options: { A: s.option_a, B: s.option_b, C: s.option_c, D: s.option_d },
      selectedOption: s.selected_option, correctOption: s.correct_option,
      isCorrect: s.is_correct, marks: s.marks_awarded, responseMs: s.response_ms, status: s.status,
    })),
  };
}

export async function competitionHistory(ctx, userId) {
  const r = await ctx.pool.query(
    `SELECT c.*, p.status AS participant_status, p.registered_at, r.total_marks, r.final_rank, r.correct_time_ms,
            (SELECT count(*) FROM competition_results x WHERE x.competition_id = c.id) AS ranked_count
       FROM competition_participants p
       JOIN competitions c ON c.id = p.competition_id
       LEFT JOIN competition_results r ON r.participant_id = p.id
      WHERE p.user_id = $1
      ORDER BY c.start_at DESC LIMIT 100`, [userId]);
  return r.rows.map((x) => ({
    competitionId: x.id, code: x.code, title: x.title, startAt: x.start_at, status: effectiveStatus(x),
    participantStatus: x.participant_status, registeredAt: x.registered_at,
    totalMarks: x.results_published_at ? x.total_marks : null,
    rank: x.results_published_at ? x.final_rank : null,
    rankedCount: x.results_published_at ? Number(x.ranked_count) : null,
    correctTimeMs: x.results_published_at ? x.correct_time_ms : null,
  }));
}
