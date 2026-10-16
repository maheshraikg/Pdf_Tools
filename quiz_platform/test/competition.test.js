import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import {
  adminToken, call, clockCtl, createCompetition, loginUser, register, setup,
} from './helpers.js';
import { sampleQuestions } from '../src/scripts/sample-questions.js';

let env;
let admin;
before(async () => { env = await setup(); admin = await adminToken(env); });
after(async () => { await env.close(); });

test('exactly 15 questions are required to schedule; question count and time are fixed', async () => {
  const { id } = await createCompetition(env, admin, { schedule: false, questions: null });
  for (let p = 1; p <= 14; p++) {
    const q = sampleQuestions[p - 1];
    const r = await call(env.app, 'PUT', `/api/admin/competitions/${id}/questions/${p}`, { token: admin, body: q });
    assert.equal(r.status, 200);
  }
  const s = await call(env.app, 'POST', `/api/admin/competitions/${id}/schedule`, { token: admin });
  assert.equal(s.status, 400);
  assert.equal(s.body.error.code, 'incomplete_questions');
  assert.equal((await call(env.app, 'PUT', `/api/admin/competitions/${id}/questions/16`, { token: admin, body: sampleQuestions[0] })).status, 400);
  assert.equal((await call(env.app, 'PUT', `/api/admin/competitions/${id}/questions/15`, { token: admin, body: sampleQuestions[14] })).status, 200);
  assert.equal((await call(env.app, 'POST', `/api/admin/competitions/${id}/schedule`, { token: admin })).status, 200);

  const bad = await call(env.app, 'POST', '/api/admin/competitions', {
    token: admin,
    body: { title: 'Bad', startAt: new Date(Date.now() + 3600e3).toISOString(), registrationOpensAt: new Date().toISOString(), registrationClosesAt: new Date(Date.now() + 1800e3).toISOString(), questionCount: 20 },
  });
  assert.equal(bad.status, 400);
  const bad2 = await call(env.app, 'PATCH', `/api/admin/competitions/${id}`, { token: admin, body: { questionTimeMs: 15000 } });
  assert.equal(bad2.status, 400);
  const imp = await call(env.app, 'POST', `/api/admin/competitions/${id}/questions/import`, { token: admin, body: { questions: sampleQuestions.slice(0, 10) } });
  assert.equal(imp.status, 400);
});

test('CSV import with formula-safe parsing', async () => {
  const { id } = await createCompetition(env, admin, { schedule: false, questions: null });
  const lines = ['position,text,optionA,optionB,optionC,optionD,correctOption,marks,category'];
  sampleQuestions.forEach((q, i) => lines.push([i + 1, `"${q.text.replace(/"/g, '""')}"`, q.optionA, q.optionB, q.optionC, q.optionD, q.correctOption, 2, q.category].join(',')));
  const r = await call(env.app, 'POST', `/api/admin/competitions/${id}/questions/import`, { token: admin, body: { csv: lines.join('\n') } });
  assert.equal(r.status, 200, JSON.stringify(r.body));
  assert.equal(r.body.questions.length, 15);
  assert.equal(r.body.questions[0].marks, 2);
});

test('registration window: not before opening, not after closing, once per user', async () => {
  const future = await createCompetition(env, admin, {
    startInMs: 3600_000,
    registrationOpensAt: new Date(Date.now() + 600_000).toISOString(),
    registrationClosesAt: new Date(Date.now() + 1800_000).toISOString(),
  });
  const u = await loginUser(env);
  const r1 = await register(env, future.id, u.token);
  assert.equal(r1.status, 409);
  assert.equal(r1.body.error.code, 'registration_not_open');

  const open = await createCompetition(env, admin, { startInMs: 180_000 });
  assert.equal((await register(env, open.id, u.token)).status, 200);
  const dup = await register(env, open.id, u.token);
  assert.equal(dup.status, 200);
  assert.equal(dup.body.alreadyRegistered, true);
  const n = await env.pool.query('SELECT count(*)::int AS n FROM competition_participants WHERE competition_id = $1', [open.id]);
  assert.equal(n.rows[0].n, 1);

  clockCtl.advance(open.startAt - clockCtl.now() + 1); // past registration close (= start)
  const late = await loginUser(env);
  const r3 = await register(env, open.id, late.token);
  assert.equal(r3.status, 409);
  assert.equal(r3.body.error.code, 'registration_closed');
  clockCtl.reset();
});

test('profile must be complete before registering', async () => {
  const c = await createCompetition(env, admin);
  const u = await loginUser(env, { name: null });
  const r = await register(env, c.id, u.token);
  assert.equal(r.status, 400);
  assert.equal(r.body.error.code, 'profile_incomplete');
});

test('restricted competitions require the access code', async () => {
  const c = await createCompetition(env, admin, { visibility: 'restricted', accessCode: 'SCHOOL42' });
  const u = await loginUser(env);
  assert.equal((await register(env, c.id, u.token)).status, 403);
  assert.equal((await register(env, c.id, u.token, 'wrong')).status, 403);
  assert.equal((await register(env, c.id, u.token, 'school42')).status, 200);
});

test('public payloads never expose the answer key', async () => {
  const c = await createCompetition(env, admin);
  const u = await loginUser(env);
  await register(env, c.id, u.token);
  const pub = await call(env.app, 'GET', `/api/competitions/${c.id}`);
  const list = await call(env.app, 'GET', '/api/competitions');
  clockCtl.advance(c.startAt - clockCtl.now() + 100);
  const st = await call(env.app, 'GET', `/api/competitions/${c.id}/state`, { token: u.token });
  assert.equal(st.body.phase, 'live');
  assert.equal(st.body.question.position, 1);
  for (const body of [pub.body, list.body, st.body]) {
    const s = JSON.stringify(body);
    assert.ok(!/correct_?option/i.test(s), s.slice(0, 200));
  }
  clockCtl.reset();
});

test('question set and scoring rules are frozen once the competition starts (API and database)', async () => {
  const c = await createCompetition(env, admin);
  clockCtl.advance(c.startAt - clockCtl.now() + 10);
  await env.ctx.lifecycle.transitions();
  const row = await env.pool.query('SELECT status, frozen_at, question_set_hash FROM competitions WHERE id = $1', [c.id]);
  assert.equal(row.rows[0].status, 'live');
  assert.ok(row.rows[0].frozen_at);
  assert.match(row.rows[0].question_set_hash, /^[0-9a-f]{64}$/);

  const e1 = await call(env.app, 'PUT', `/api/admin/competitions/${c.id}/questions/1`, { token: admin, body: { ...sampleQuestions[0], correctOption: 'D' } });
  assert.equal(e1.status, 409);
  const e2 = await call(env.app, 'PATCH', `/api/admin/competitions/${c.id}`, { token: admin, body: { defaultMarks: 5 } });
  assert.equal(e2.status, 409);
  // Even direct SQL cannot alter a frozen competition.
  await assert.rejects(env.pool.query(`UPDATE questions SET correct_option = 'D' WHERE competition_id = $1`, [c.id]), /frozen/);
  await assert.rejects(env.pool.query(`UPDATE competitions SET default_marks = 9 WHERE id = $1`, [c.id]), /frozen/);
  await assert.rejects(env.pool.query(`DELETE FROM questions WHERE competition_id = $1`, [c.id]), /frozen/);
  clockCtl.reset();
});

test('administrator role-based access control', async () => {
  const viewer = await adminToken(env, 'viewer');
  const moderator = await adminToken(env, 'moderator');
  const c = await createCompetition(env, admin);
  const v = await call(env.app, 'GET', `/api/admin/competitions/${c.id}`, { token: viewer });
  assert.equal(v.status, 200);
  assert.equal(v.body.questions[0].correctOption, undefined, 'viewers must not see the answer key');
  const a = await call(env.app, 'GET', `/api/admin/competitions/${c.id}`, { token: admin });
  assert.ok(a.body.questions[0].correctOption);
  assert.equal((await call(env.app, 'POST', '/api/admin/competitions', { token: viewer, body: { title: 'x' } })).status, 403);
  assert.equal((await call(env.app, 'POST', `/api/admin/competitions/${c.id}/publish`, { token: moderator })).status, 403);
  assert.equal((await call(env.app, 'GET', `/api/admin/competitions/${c.id}/export?format=csv`, { token: moderator })).status, 403);
  assert.equal((await call(env.app, 'GET', '/api/admin/admins', { token: admin })).status, 200);
  assert.equal((await call(env.app, 'GET', '/api/admin/admins', { token: moderator })).status, 403);
  // Participants cannot use admin endpoints.
  const u = await loginUser(env);
  assert.equal((await call(env.app, 'GET', '/api/admin/competitions', { token: u.token })).status, 401);
  assert.equal((await call(env.app, 'GET', '/api/admin/competitions')).status, 401);
});

test('admin login is rate limited and failures are audited', async () => {
  let last;
  for (let i = 0; i < 12; i++) {
    last = await call(env.app, 'POST', '/api/admin/auth/login', { body: { email: 'nobody@example.org', password: 'x' }, headers: { 'x-requested-with': 'quiz-app' } });
  }
  assert.equal(last.status, 429);
  const logs = await env.pool.query(`SELECT count(*)::int AS n FROM audit_logs WHERE action = 'admin.login_failed'`);
  assert.ok(logs.rows[0].n >= 5);
});

test('cancellation before start notifies registrants and blocks registration', async () => {
  const c = await createCompetition(env, admin);
  const u = await loginUser(env);
  await register(env, c.id, u.token);
  const r = await call(env.app, 'POST', `/api/admin/competitions/${c.id}/cancel`, { token: admin, body: { reason: 'Venue unavailable' } });
  assert.equal(r.status, 200);
  assert.equal(r.body.competition.status, 'cancelled');
  const u2 = await loginUser(env);
  assert.equal((await register(env, c.id, u2.token)).body.error.code, 'competition_cancelled');
  const n = await call(env.app, 'GET', '/api/me/notifications', { token: u.token });
  assert.ok(n.body.notifications.some((x) => x.kind === 'cancelled'));
  const audit = await call(env.app, 'GET', `/api/admin/audit?entityType=competition&entityId=${c.id}`, { token: admin });
  assert.ok(audit.body.logs.some((l) => l.action === 'competition.cancelled'));
});
