// Competition and question management (admin) + registration (participants).
import { clock } from '../lib/clock.js';
import { tx } from '../lib/db.js';
import { badRequest, conflict, forbidden, notFound } from '../lib/errors.js';
import { friendlyId, hmac, sha256, timingSafeEqualBuf } from '../lib/security.js';
import { audit } from './audit.js';
import { enqueueNotification } from './notifications.js';
import { QUESTION_COUNT, timeline } from './schedule.js';

const OPTIONS = ['A', 'B', 'C', 'D'];

// ---------------------------------------------------------------------------
// Status
// ---------------------------------------------------------------------------

/**
 * Effective status shown to users. The stored status is authoritative for
 * draft/cancelled/completed; for scheduled/live competitions the clock decides
 * (the lifecycle job persists the transition within ~0.5 s).
 *   draft | scheduled | registration_open | live | completed | cancelled
 */
export function effectiveStatus(c, now = clock.now()) {
  if (c.status === 'draft' || c.status === 'cancelled' || c.status === 'completed') return c.status;
  const t = timeline(c);
  if (now >= t.endsAt) return 'completed';
  if (now >= t.start) return 'live';
  if (now >= c.registration_opens_at.getTime() && now < c.registration_closes_at.getTime()) return 'registration_open';
  return 'scheduled';
}

export function registrationOpen(c, now = clock.now()) {
  if (c.status !== 'scheduled' && c.status !== 'live') return false;
  const t = timeline(c);
  return now >= c.registration_opens_at.getTime() && now < c.registration_closes_at.getTime() && now < t.endsAt;
}

export function publicCompetition(c, extra = {}) {
  const t = timeline(c);
  return {
    id: c.id,
    code: c.code,
    title: c.title,
    description: c.description,
    rules: c.rules,
    status: effectiveStatus(c),
    startAt: c.start_at,
    endsAt: new Date(t.endsAt),
    registrationOpensAt: c.registration_opens_at,
    registrationClosesAt: c.registration_closes_at,
    registrationOpen: registrationOpen(c),
    questionCount: c.question_count,
    questionTimeMs: c.question_time_ms,
    transitionMs: c.transition_ms,
    defaultMarks: c.default_marks,
    visibility: c.visibility,
    lateEntryAllowed: c.late_entry_allowed,
    revealAnswers: c.reveal_answers,
    showProvisional: c.show_provisional,
    branding: c.branding,
    resultsPublished: Boolean(c.results_published_at),
    resultsPublishedAt: c.results_published_at,
    cancelledReason: c.status === 'cancelled' ? c.cancelled_reason : undefined,
    participantCount: c.participant_count !== undefined ? Number(c.participant_count) : undefined,
    ...extra,
  };
}

export function adminCompetition(c) {
  return {
    ...publicCompetition(c),
    storedStatus: c.status,
    notifySms: c.notify_sms,
    frozenAt: c.frozen_at,
    questionSetHash: c.question_set_hash,
    resultsComputedAt: c.results_computed_at,
    hasAccessCode: Boolean(c.access_code_hash),
    createdAt: c.created_at,
    updatedAt: c.updated_at,
    questionsReady: c.question_total !== undefined ? Number(c.question_total) : undefined,
  };
}

const isEditable = (c) => c.status === 'draft' || (c.status === 'scheduled' && clock.now() < c.start_at.getTime() && !c.frozen_at);

export async function getCompetition(db, id, { forUpdate = false } = {}) {
  if (!/^[0-9a-f-]{36}$/i.test(String(id))) throw notFound('competition_not_found', 'Competition not found');
  const r = await db.query(`SELECT * FROM competitions WHERE id = $1 ${forUpdate ? 'FOR UPDATE' : ''}`, [id]);
  if (!r.rowCount) throw notFound('competition_not_found', 'Competition not found');
  return r.rows[0];
}

// ---------------------------------------------------------------------------
// Admin: create / update
// ---------------------------------------------------------------------------

const EDITABLE_FIELDS = {
  title: 'title', description: 'description', rules: 'rules', startAt: 'start_at',
  registrationOpensAt: 'registration_opens_at', registrationClosesAt: 'registration_closes_at',
  transitionMs: 'transition_ms', defaultMarks: 'default_marks', visibility: 'visibility',
  lateEntryAllowed: 'late_entry_allowed', revealAnswers: 'reveal_answers',
  showProvisional: 'show_provisional', notifySms: 'notify_sms', branding: 'branding',
};

function validateCompetitionInput(input, { partial }) {
  const out = {};
  for (const [k, col] of Object.entries(EDITABLE_FIELDS)) {
    if (input[k] === undefined) continue;
    out[col] = input[k];
  }
  if (input.questionCount !== undefined && input.questionCount !== QUESTION_COUNT) {
    throw badRequest('invalid_question_count', 'Every competition has exactly 15 questions');
  }
  if (input.questionTimeMs !== undefined && input.questionTimeMs !== 10_000) {
    throw badRequest('invalid_question_time', 'Every question allows exactly 10 seconds');
  }
  if (!partial) {
    for (const k of ['title', 'startAt', 'registrationOpensAt', 'registrationClosesAt']) {
      if (input[k] === undefined) throw badRequest('missing_field', `${k} is required`);
    }
  }
  if (out.title !== undefined && (typeof out.title !== 'string' || out.title.trim().length < 3 || out.title.length > 200)) {
    throw badRequest('invalid_title', 'Title must be 3–200 characters');
  }
  for (const col of ['description', 'rules']) {
    if (out[col] !== undefined && (typeof out[col] !== 'string' || out[col].length > 10_000)) throw badRequest(`invalid_${col}`, `${col} too long`);
  }
  for (const col of ['start_at', 'registration_opens_at', 'registration_closes_at']) {
    if (out[col] === undefined) continue;
    const d = new Date(out[col]);
    if (Number.isNaN(d.getTime())) throw badRequest('invalid_date', `${col} must be an ISO-8601 timestamp`);
    out[col] = d;
  }
  if (out.transition_ms !== undefined && !(Number.isInteger(out.transition_ms) && out.transition_ms >= 1000 && out.transition_ms <= 30000)) {
    throw badRequest('invalid_transition', 'Transition between questions must be 1–30 seconds');
  }
  if (out.default_marks !== undefined && !(Number.isInteger(out.default_marks) && out.default_marks >= 1 && out.default_marks <= 100)) {
    throw badRequest('invalid_marks', 'Marks must be an integer from 1 to 100');
  }
  if (out.visibility !== undefined && !['public', 'restricted'].includes(out.visibility)) throw badRequest('invalid_visibility', 'Invalid visibility');
  for (const col of ['late_entry_allowed', 'reveal_answers', 'show_provisional', 'notify_sms']) {
    if (out[col] !== undefined && typeof out[col] !== 'boolean') throw badRequest('invalid_flag', `${col} must be boolean`);
  }
  if (out.branding !== undefined) out.branding = sanitizeBranding(out.branding);
  return out;
}

function sanitizeBranding(b) {
  if (b === null || typeof b !== 'object') return {};
  const out = {};
  if (typeof b.organization === 'string') out.organization = b.organization.slice(0, 120);
  if (typeof b.primaryColor === 'string' && /^#[0-9a-fA-F]{6}$/.test(b.primaryColor)) out.primaryColor = b.primaryColor;
  if (typeof b.logoUrl === 'string' && /^https:\/\/[^\s"'<>]+$/.test(b.logoUrl) && b.logoUrl.length < 500) out.logoUrl = b.logoUrl;
  return out;
}

function validateWindow(c) {
  const t = timeline(c);
  if (c.registration_opens_at >= c.registration_closes_at) throw badRequest('invalid_registration_window', 'Registration must open before it closes');
  if (c.registration_opens_at > c.start_at) throw badRequest('invalid_registration_window', 'Registration must open before the competition starts');
  if (c.registration_closes_at.getTime() > t.endsAt) throw badRequest('invalid_registration_window', 'Registration must close before the competition ends');
  if (!c.late_entry_allowed && c.registration_closes_at > c.start_at) {
    throw badRequest('invalid_registration_window', 'Without late entry, registration must close at or before the start time');
  }
}

function accessCodeHash(ctx, code) {
  return hmac(ctx.cfg.keys.accessCode, String(code).trim().toUpperCase());
}

export async function createCompetition(ctx, input, admin) {
  const fields = validateCompetitionInput(input, { partial: false });
  const row = {
    late_entry_allowed: true, transition_ms: 3000, default_marks: 1, visibility: 'public', ...fields,
    question_count: QUESTION_COUNT, question_time_ms: 10_000,
  };
  validateWindow(row);
  if (row.visibility === 'restricted') {
    if (!input.accessCode || String(input.accessCode).trim().length < 4) throw badRequest('access_code_required', 'Restricted competitions need an access code (min 4 characters)');
    row.access_code_hash = accessCodeHash(ctx, input.accessCode);
  }
  row.code = friendlyId('QC', 6);
  row.created_by = admin.id;
  const cols = Object.keys(row);
  const r = await ctx.pool.query(
    `INSERT INTO competitions (${cols.join(', ')}) VALUES (${cols.map((_, i) => `$${i + 1}`).join(', ')}) RETURNING *`,
    cols.map((k) => row[k]),
  );
  await audit(ctx.pool, { actorType: 'admin', actorId: admin.id, action: 'competition.created', entityType: 'competition', entityId: r.rows[0].id, metadata: { title: row.title } });
  return r.rows[0];
}

export async function updateCompetition(ctx, id, input, admin) {
  return tx(ctx.pool, async (db) => {
    const c = await getCompetition(db, id, { forUpdate: true });
    if (!isEditable(c)) throw conflict('competition_locked', 'This competition has started or finished and can no longer be edited');
    const fields = validateCompetitionInput(input, { partial: true });
    if (input.visibility === 'restricted' || (c.visibility === 'restricted' && input.accessCode)) {
      if (input.accessCode) fields.access_code_hash = accessCodeHash(ctx, input.accessCode);
      else if (!c.access_code_hash) throw badRequest('access_code_required', 'Restricted competitions need an access code');
    }
    if (input.visibility === 'public') fields.access_code_hash = null;
    const merged = { ...c, ...fields };
    validateWindow(merged);
    if (c.status === 'scheduled' && merged.start_at.getTime() <= clock.now() + 60_000) {
      throw badRequest('start_too_soon', 'A scheduled competition must start at least 1 minute in the future');
    }
    const cols = Object.keys(fields);
    if (!cols.length) return c;
    const r = await db.query(
      `UPDATE competitions SET ${cols.map((k, i) => `${k} = $${i + 2}`).join(', ')} WHERE id = $1 RETURNING *`,
      [id, ...cols.map((k) => fields[k])],
    );
    await audit(db, { actorType: 'admin', actorId: admin.id, action: 'competition.updated', entityType: 'competition', entityId: id, metadata: { fields: cols.filter((k) => k !== 'access_code_hash') } });
    const scheduleChanged = ['start_at', 'registration_closes_at'].some((k) => fields[k] && fields[k].getTime() !== c[k].getTime());
    if (c.status === 'scheduled' && scheduleChanged) {
      await notifyRegistrants(db, r.rows[0], 'schedule_changed',
        `Schedule update: "${c.title}" now starts at ${r.rows[0].start_at.toISOString().replace('T', ' ').slice(0, 16)} UTC.`);
    }
    return r.rows[0];
  });
}

export async function deleteCompetition(ctx, id, admin) {
  await tx(ctx.pool, async (db) => {
    const c = await getCompetition(db, id, { forUpdate: true });
    if (c.status !== 'draft') throw conflict('not_draft', 'Only draft competitions can be deleted; cancel scheduled ones instead');
    await db.query(`DELETE FROM competitions WHERE id = $1`, [id]);
    await audit(db, { actorType: 'admin', actorId: admin.id, action: 'competition.deleted', entityType: 'competition', entityId: id, metadata: { title: c.title } });
  });
}

// ---------------------------------------------------------------------------
// Questions
// ---------------------------------------------------------------------------

function validateQuestion(q, defaultMarks) {
  const position = Number(q.position);
  if (!Number.isInteger(position) || position < 1 || position > QUESTION_COUNT) throw badRequest('invalid_position', 'Question number must be 1–15');
  const str = (v, name, max) => {
    if (typeof v !== 'string' || !v.trim() || v.length > max) throw badRequest('invalid_question', `Q${position}: ${name} is required (max ${max} chars)`);
    return v.trim();
  };
  const correct = String(q.correctOption ?? '').trim().toUpperCase();
  if (!OPTIONS.includes(correct)) throw badRequest('invalid_question', `Q${position}: correct option must be A, B, C or D`);
  const out = {
    position,
    text: str(q.text, 'question text', 2000),
    option_a: str(q.optionA, 'option A', 500),
    option_b: str(q.optionB, 'option B', 500),
    option_c: str(q.optionC, 'option C', 500),
    option_d: str(q.optionD, 'option D', 500),
    correct_option: correct,
    marks: q.marks === undefined || q.marks === null || q.marks === '' ? defaultMarks : Number(q.marks),
    image_url: q.imageUrl ? String(q.imageUrl).trim() : null,
    category: q.category ? String(q.category).trim().slice(0, 100) : null,
  };
  if (!Number.isInteger(out.marks) || out.marks < 0 || out.marks > 100) throw badRequest('invalid_question', `Q${position}: marks must be an integer 0–100`);
  if (out.image_url && !/^https:\/\/[^\s"'<>]+$/.test(out.image_url)) throw badRequest('invalid_question', `Q${position}: image URL must be https://`);
  const opts = [out.option_a, out.option_b, out.option_c, out.option_d].map((o) => o.toLowerCase());
  if (new Set(opts).size !== 4) throw badRequest('invalid_question', `Q${position}: the four options must be different`);
  return out;
}

export function adminQuestion(q) {
  return {
    id: q.id, position: q.position, text: q.text,
    optionA: q.option_a, optionB: q.option_b, optionC: q.option_c, optionD: q.option_d,
    correctOption: q.correct_option, marks: q.marks, imageUrl: q.image_url, category: q.category,
    updatedAt: q.updated_at,
  };
}

export async function listQuestions(db, competitionId) {
  const r = await db.query(`SELECT * FROM questions WHERE competition_id = $1 ORDER BY position`, [competitionId]);
  return r.rows;
}

export async function upsertQuestion(ctx, competitionId, input, admin) {
  return tx(ctx.pool, async (db) => {
    const c = await getCompetition(db, competitionId, { forUpdate: true });
    if (!isEditable(c)) throw conflict('competition_locked', 'Questions are frozen once the competition starts');
    const q = validateQuestion(input, c.default_marks);
    const r = await db.query(
      `INSERT INTO questions (competition_id, position, text, option_a, option_b, option_c, option_d, correct_option, marks, image_url, category)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
       ON CONFLICT (competition_id, position) DO UPDATE SET
         text = EXCLUDED.text, option_a = EXCLUDED.option_a, option_b = EXCLUDED.option_b,
         option_c = EXCLUDED.option_c, option_d = EXCLUDED.option_d, correct_option = EXCLUDED.correct_option,
         marks = EXCLUDED.marks, image_url = EXCLUDED.image_url, category = EXCLUDED.category, updated_at = now()
       RETURNING *`,
      [competitionId, q.position, q.text, q.option_a, q.option_b, q.option_c, q.option_d, q.correct_option, q.marks, q.image_url, q.category],
    );
    await audit(db, { actorType: 'admin', actorId: admin.id, action: 'question.saved', entityType: 'competition', entityId: competitionId, metadata: { position: q.position } });
    return r.rows[0];
  });
}

export async function deleteQuestion(ctx, competitionId, position, admin) {
  await tx(ctx.pool, async (db) => {
    const c = await getCompetition(db, competitionId, { forUpdate: true });
    if (c.status !== 'draft') throw conflict('competition_locked', 'Questions can only be removed while the competition is a draft');
    await db.query(`DELETE FROM questions WHERE competition_id = $1 AND position = $2`, [competitionId, Number(position)]);
    await audit(db, { actorType: 'admin', actorId: admin.id, action: 'question.deleted', entityType: 'competition', entityId: competitionId, metadata: { position: Number(position) } });
  });
}

/**
 * Replace the full question set from an import (JSON array or CSV rows with
 * header: position,text,optionA,optionB,optionC,optionD,correctOption,marks,category,imageUrl).
 * The import is atomic: either all 15 questions are valid and saved, or none.
 */
export async function importQuestions(ctx, competitionId, items, admin) {
  if (!Array.isArray(items) || items.length !== QUESTION_COUNT) {
    throw badRequest('invalid_import', `Import must contain exactly ${QUESTION_COUNT} questions (got ${Array.isArray(items) ? items.length : 0})`);
  }
  return tx(ctx.pool, async (db) => {
    const c = await getCompetition(db, competitionId, { forUpdate: true });
    if (c.status !== 'draft') throw conflict('competition_locked', 'Questions can only be imported while the competition is a draft');
    const qs = items.map((it, i) => validateQuestion({ position: i + 1, ...it }, c.default_marks));
    const positions = new Set(qs.map((q) => q.position));
    if (positions.size !== QUESTION_COUNT) throw badRequest('invalid_import', 'Question numbers must be unique 1–15');
    await db.query(`DELETE FROM questions WHERE competition_id = $1`, [competitionId]);
    for (const q of qs) {
      await db.query(
        `INSERT INTO questions (competition_id, position, text, option_a, option_b, option_c, option_d, correct_option, marks, image_url, category)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)`,
        [competitionId, q.position, q.text, q.option_a, q.option_b, q.option_c, q.option_d, q.correct_option, q.marks, q.image_url, q.category],
      );
    }
    await audit(db, { actorType: 'admin', actorId: admin.id, action: 'question.imported', entityType: 'competition', entityId: competitionId, metadata: { count: qs.length } });
    return listQuestions(db, competitionId);
  });
}

export function rowsFromCsv(rows) {
  if (!rows.length) return [];
  const header = rows[0].map((h) => h.trim().toLowerCase().replace(/[^a-z]/g, ''));
  const idx = (name) => header.indexOf(name);
  const need = ['text', 'optiona', 'optionb', 'optionc', 'optiond', 'correctoption'];
  for (const n of need) if (idx(n) < 0) throw badRequest('invalid_import', `CSV header must include: position,text,optionA,optionB,optionC,optionD,correctOption,marks,category,imageUrl`);
  const get = (r, n) => (idx(n) >= 0 ? r[idx(n)] : undefined);
  return rows.slice(1).map((r, i) => ({
    position: get(r, 'position') ? Number(get(r, 'position')) : i + 1,
    text: get(r, 'text'), optionA: get(r, 'optiona'), optionB: get(r, 'optionb'),
    optionC: get(r, 'optionc'), optionD: get(r, 'optiond'), correctOption: get(r, 'correctoption'),
    marks: get(r, 'marks') ? Number(get(r, 'marks')) : undefined,
    category: get(r, 'category'), imageUrl: get(r, 'imageurl'),
  })).sort((a, b) => a.position - b.position);
}

// ---------------------------------------------------------------------------
// Lifecycle transitions
// ---------------------------------------------------------------------------

export async function scheduleCompetition(ctx, id, admin) {
  return tx(ctx.pool, async (db) => {
    const c = await getCompetition(db, id, { forUpdate: true });
    if (c.status !== 'draft') throw conflict('not_draft', 'Only draft competitions can be scheduled');
    const qs = await listQuestions(db, id);
    if (qs.length !== QUESTION_COUNT || qs.some((q, i) => q.position !== i + 1)) {
      throw badRequest('incomplete_questions', `Exactly ${QUESTION_COUNT} questions (numbered 1–15) are required before scheduling (currently ${qs.length})`);
    }
    if (c.start_at.getTime() <= clock.now() + 60_000) throw badRequest('start_too_soon', 'Start time must be at least 1 minute in the future');
    validateWindow(c);
    const r = await db.query(`UPDATE competitions SET status = 'scheduled' WHERE id = $1 RETURNING *`, [id]);
    await audit(db, { actorType: 'admin', actorId: admin.id, action: 'competition.scheduled', entityType: 'competition', entityId: id, metadata: { startAt: c.start_at } });
    return r.rows[0];
  });
}

export async function unscheduleCompetition(ctx, id, admin) {
  return tx(ctx.pool, async (db) => {
    const c = await getCompetition(db, id, { forUpdate: true });
    if (!isEditable(c) || c.status !== 'scheduled') throw conflict('not_scheduled', 'Only scheduled competitions that have not started can return to draft');
    const regs = await db.query(`SELECT count(*)::int AS n FROM competition_participants WHERE competition_id = $1`, [id]);
    if (regs.rows[0].n > 0) throw conflict('has_registrations', 'Participants have registered; edit the schedule or cancel instead');
    const r = await db.query(`UPDATE competitions SET status = 'draft' WHERE id = $1 RETURNING *`, [id]);
    await audit(db, { actorType: 'admin', actorId: admin.id, action: 'competition.unscheduled', entityType: 'competition', entityId: id });
    return r.rows[0];
  });
}

export async function cancelCompetition(ctx, id, reason, admin) {
  const c2 = await tx(ctx.pool, async (db) => {
    const c = await getCompetition(db, id, { forUpdate: true });
    if (!['draft', 'scheduled', 'live'].includes(c.status)) throw conflict('cannot_cancel', `A ${c.status} competition cannot be cancelled`);
    const why = String(reason ?? '').trim().slice(0, 500);
    if (why.length < 3) throw badRequest('reason_required', 'Give a reason for the cancellation');
    const r = await db.query(`UPDATE competitions SET status = 'cancelled', cancelled_reason = $2 WHERE id = $1 RETURNING *`, [id, why]);
    await audit(db, { actorType: 'admin', actorId: admin.id, action: 'competition.cancelled', entityType: 'competition', entityId: id, metadata: { reason: why, previousStatus: c.status } });
    await notifyRegistrants(db, r.rows[0], 'cancelled', `"${c.title}" has been cancelled. Reason: ${why}`);
    return r.rows[0];
  });
  await ctx.bus.publish({ type: 'competition_cancelled', competitionId: id, reason: c2.cancelled_reason });
  return c2;
}

/** Called by the lifecycle job at start time: freeze the question set and go live. */
export async function freezeAndStart(ctx, id) {
  return tx(ctx.pool, async (db) => {
    const c = await getCompetition(db, id, { forUpdate: true });
    if (c.status !== 'scheduled' || c.start_at.getTime() > clock.now()) return null;
    const qs = await listQuestions(db, id);
    const canonical = JSON.stringify({
      startAt: c.start_at.toISOString(), questionTimeMs: c.question_time_ms, transitionMs: c.transition_ms,
      questions: qs.map((q) => [q.position, q.text, q.option_a, q.option_b, q.option_c, q.option_d, q.correct_option, q.marks]),
    });
    const hash = sha256(canonical).toString('hex');
    const r = await db.query(
      `UPDATE competitions SET status = 'live', frozen_at = now(), question_set_hash = $2 WHERE id = $1 RETURNING *`, [id, hash]);
    await audit(db, { actorType: 'system', action: 'competition.started', entityType: 'competition', entityId: id, metadata: { questionSetHash: hash, questionCount: qs.length } });
    return r.rows[0];
  });
}

// ---------------------------------------------------------------------------
// Participant registration
// ---------------------------------------------------------------------------

export async function registerForCompetition(ctx, user, competitionId, accessCode) {
  if (!user.display_name) throw badRequest('profile_incomplete', 'Complete your profile before joining a competition');
  const c = await getCompetition(ctx.pool, competitionId);
  const existing = await ctx.pool.query(
    `SELECT * FROM competition_participants WHERE competition_id = $1 AND user_id = $2`, [competitionId, user.id]);
  if (existing.rowCount) return { participant: existing.rows[0], alreadyRegistered: true };
  if (!registrationOpen(c)) {
    const now = clock.now();
    if (c.status === 'cancelled') throw conflict('competition_cancelled', 'This competition has been cancelled');
    if (now < c.registration_opens_at.getTime()) throw conflict('registration_not_open', 'Registration has not opened yet');
    throw conflict('registration_closed', 'Registration for this competition is closed');
  }
  if (c.visibility === 'restricted') {
    await ctx.limiter.enforce(`access:${user.id}:${competitionId}`, 10, 3600_000, 'Too many incorrect access code attempts');
    if (!accessCode || !timingSafeEqualBuf(accessCodeHash(ctx, accessCode), c.access_code_hash)) {
      throw forbidden('invalid_access_code', 'This competition is restricted. Enter the correct access code.');
    }
  }
  const r = await ctx.pool.query(
    `INSERT INTO competition_participants (competition_id, user_id) VALUES ($1, $2)
     ON CONFLICT (competition_id, user_id) DO NOTHING RETURNING *`,
    [competitionId, user.id],
  );
  if (!r.rowCount) {
    const again = await ctx.pool.query(`SELECT * FROM competition_participants WHERE competition_id = $1 AND user_id = $2`, [competitionId, user.id]);
    return { participant: again.rows[0], alreadyRegistered: true };
  }
  await audit(ctx.pool, { actorType: 'user', actorId: user.id, action: 'competition.registered', entityType: 'competition', entityId: competitionId });
  await enqueueNotification(ctx.pool, {
    userId: user.id, competitionId, kind: 'registration_confirmed',
    body: `You are registered for "${c.title}". Starts ${c.start_at.toISOString().replace('T', ' ').slice(0, 16)} UTC. Registration ID: ${user.registration_id}`,
    sms: c.notify_sms,
  });
  return { participant: r.rows[0], alreadyRegistered: false };
}

export async function notifyRegistrants(db, c, kind, body) {
  await db.query(
    `INSERT INTO notifications (user_id, competition_id, kind, channel, body, dedupe_key)
     SELECT p.user_id, $1::uuid, $2::text, ch.channel, $3::text,
            $1::text || ':' || $2::text || ':' || ch.channel || ':' || p.user_id::text || ':' || $4::text
       FROM competition_participants p
       CROSS JOIN (SELECT 'in_app' AS channel UNION ALL SELECT 'sms' WHERE $5::boolean) ch
      WHERE p.competition_id = $1::uuid
     ON CONFLICT (dedupe_key) DO NOTHING`,
    [c.id, kind, body, String(c.updated_at.getTime()), Boolean(c.notify_sms)],
  );
}
