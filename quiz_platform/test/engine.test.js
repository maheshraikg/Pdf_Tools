import { test, before, after, afterEach } from 'node:test';
import assert from 'node:assert/strict';
import {
  adminToken, answerKey, call, clockCtl, createCompetition, loginUser, opensAt, register, setup, submit, wrongOf,
} from './helpers.js';

let env;
let admin;
before(async () => { env = await setup(); admin = await adminToken(env); });
after(async () => { await env.close(); });
afterEach(() => clockCtl.reset());

async function liveCompetition(fields = {}, users = 1) {
  const c = await createCompetition(env, admin, fields);
  const players = [];
  for (let i = 0; i < users; i++) {
    const u = await loginUser(env);
    assert.equal((await register(env, c.id, u.token)).status, 200);
    players.push(u);
  }
  const key = await answerKey(env, c.id);
  return { c, players, key };
}

test('correct answers score the question marks; incorrect answers score zero', async () => {
  const { c, players: [u], key } = await liveCompetition();
  clockCtl.freezeAt(opensAt(c.startAt, 1) + 2345.6);
  const ok = await submit(env, c.id, u.token, key[0].id, key[0].correct_option);
  assert.equal(ok.status, 200, JSON.stringify(ok.body));
  assert.equal(ok.body.accepted, true);
  assert.equal(ok.body.responseMs, 2345);
  assert.equal(ok.body.isCorrect, undefined, 'correctness is not revealed during the competition');

  clockCtl.freezeAt(opensAt(c.startAt, 2) + 100);
  const bad = await submit(env, c.id, u.token, key[1].id, wrongOf(key[1].correct_option));
  assert.equal(bad.status, 200);
  const rows = await env.pool.query(
    'SELECT question_position, is_correct, marks_awarded, response_ms FROM answer_submissions WHERE competition_id = $1 ORDER BY question_position', [c.id]);
  assert.deepEqual(rows.rows, [
    { question_position: 1, is_correct: true, marks_awarded: 1, response_ms: 2345 },
    { question_position: 2, is_correct: false, marks_awarded: 0, response_ms: 100 },
  ]);
});

test('deadline: accepted at exactly 10,000 ms, rejected 1 ms later; no early answers', async () => {
  const { c, players: [u1, u2, u3], key } = await liveCompetition({}, 3);
  const o = opensAt(c.startAt, 1);
  clockCtl.freezeAt(o + 10_000);
  const edge = await submit(env, c.id, u1.token, key[0].id, 'A');
  assert.equal(edge.status, 200);
  assert.equal(edge.body.responseMs, 10_000);

  clockCtl.freezeAt(o + 10_001);
  const late = await submit(env, c.id, u2.token, key[0].id, 'A');
  assert.equal(late.status, 409);
  assert.equal(late.body.error.code, 'deadline_passed');

  clockCtl.freezeAt(o + 5000);
  const early = await submit(env, c.id, u3.token, key[1].id, 'A');
  assert.equal(early.status, 409);
  assert.equal(early.body.error.code, 'question_not_open');

  clockCtl.freezeAt(o - 1);
  const before = await submit(env, c.id, u3.token, key[0].id, 'A');
  assert.equal(before.status, 409);
  assert.equal(before.body.error.code, 'competition_not_live');

  const rej = await env.pool.query('SELECT reason FROM submission_rejections WHERE competition_id = $1 ORDER BY id', [c.id]);
  assert.deepEqual(rej.rows.map((r) => r.reason), ['deadline_passed', 'not_open_yet', 'competition_registration_open']);
});

test('one answer per question: identical replay is idempotent, a changed answer is refused', async () => {
  const { c, players: [u], key } = await liveCompetition();
  clockCtl.freezeAt(opensAt(c.startAt, 1) + 1500);
  const a = await submit(env, c.id, u.token, key[0].id, 'B', { idempotencyKey: 'k1' });
  clockCtl.freezeAt(opensAt(c.startAt, 1) + 4000);
  const replay = await submit(env, c.id, u.token, key[0].id, 'B', { idempotencyKey: 'k1' });
  assert.equal(replay.status, 200);
  assert.equal(replay.body.duplicate, true);
  assert.equal(replay.body.responseMs, a.body.responseMs, 'replay must not change the recorded time');
  const change = await submit(env, c.id, u.token, key[0].id, 'C');
  assert.equal(change.status, 409);
  assert.equal(change.body.error.code, 'already_answered');
  const n = await env.pool.query('SELECT count(*)::int AS n, max(selected_option) AS opt FROM answer_submissions WHERE competition_id = $1', [c.id]);
  assert.deepEqual(n.rows[0], { n: 1, opt: 'B' });
});

test('50 simultaneous submissions from one participant produce exactly one scored answer', async () => {
  const { c, players: [u], key } = await liveCompetition();
  clockCtl.freezeAt(opensAt(c.startAt, 1) + 800);
  const opts = ['A', 'B', 'C', 'D'];
  const results = await Promise.all(Array.from({ length: 50 }, (_, i) => submit(env, c.id, u.token, key[0].id, opts[i % 4])));
  const accepted = results.filter((r) => r.status === 200);
  const stored = await env.pool.query('SELECT selected_option, marks_awarded FROM answer_submissions WHERE competition_id = $1', [c.id]);
  assert.equal(stored.rowCount, 1);
  assert.ok(accepted.every((r) => r.body.selectedOption === stored.rows[0].selected_option));
  assert.ok(results.filter((r) => r.status === 409).every((r) => r.body.error.code === 'already_answered'));
});

test('many participants answering in the same window are all recorded with exact times', async () => {
  const { c, players, key } = await liveCompetition({}, 40);
  // Sequential: each request is received at a distinct, known server time.
  const o = opensAt(c.startAt, 3);
  for (let i = 0; i < players.length; i++) {
    clockCtl.freezeAt(o + 200 + i * 37.3);
    const r = await submit(env, c.id, players[i].token, key[2].id, i % 2 ? key[2].correct_option : wrongOf(key[2].correct_option));
    assert.equal(r.status, 200);
  }
  const rows = await env.pool.query(`SELECT response_ms FROM answer_submissions WHERE competition_id = $1 ORDER BY response_ms`, [c.id]);
  assert.deepEqual(rows.rows.map((r) => r.response_ms), players.map((_, i) => Math.floor(200 + i * 37.3)));

  // Concurrent: all 40 participants submit in the same instant.
  clockCtl.freezeAt(opensAt(c.startAt, 4) + 4321);
  const res = await Promise.all(players.map((p) => submit(env, c.id, p.token, key[3].id, key[3].correct_option)));
  assert.ok(res.every((r) => r.status === 200 && r.body.responseMs === 4321));
  const q4 = await env.pool.query(`SELECT count(*)::int AS n, sum(marks_awarded)::int AS marks FROM answer_submissions WHERE question_id = $1`, [key[3].id]);
  assert.deepEqual(q4.rows[0], { n: 40, marks: 40 });
});

test('refresh / reconnect restores state without resetting the timer or allowing a second answer', async () => {
  const { c, players: [u], key } = await liveCompetition();
  const o = opensAt(c.startAt, 4);
  clockCtl.freezeAt(o + 3000);
  const s1 = await call(env.app, 'GET', `/api/competitions/${c.id}/state`, { token: u.token });
  assert.equal(s1.body.question.position, 4);
  assert.equal(s1.body.question.closesAt, o + 10_000);
  await submit(env, c.id, u.token, key[3].id, 'A');
  clockCtl.freezeAt(o + 7000); // "page refresh" 4 s later
  const s2 = await call(env.app, 'GET', `/api/competitions/${c.id}/state`, { token: u.token });
  assert.equal(s2.body.question.closesAt, o + 10_000, 'deadline is absolute');
  assert.equal(s2.body.serverNow, o + 7000);
  assert.deepEqual(s2.body.myAnswer, { selectedOption: 'A', responseMs: 3000 });
  assert.equal(s2.body.progress.answered, 1);
  assert.equal(s2.body.progress.closed, 3);
  assert.equal(s2.body.progress.remaining, 12);
  // Network drop: reconnect after the deadline gets the next phase, never extra time.
  clockCtl.freezeAt(o + 10_500);
  const s3 = await call(env.app, 'GET', `/api/competitions/${c.id}/state`, { token: u.token });
  assert.equal(s3.body.timeline.phase, 'transition');
  assert.equal(s3.body.question, undefined);
  assert.equal((await submit(env, c.id, u.token, key[3].id, 'B')).body.error.code, 'deadline_passed');
  const n = await env.pool.query('SELECT count(*)::int AS n FROM answer_submissions WHERE question_id = $1', [key[3].id]);
  assert.equal(n.rows[0].n, 1);
});

test('late entry: allowed participants only see current questions; disallowed are refused', async () => {
  const allowed = await liveCompetition({ lateEntryAllowed: true });
  clockCtl.freezeAt(opensAt(allowed.c.startAt, 6) + 500);
  const s = await call(env.app, 'GET', `/api/competitions/${allowed.c.id}/state`, { token: allowed.players[0].token });
  assert.equal(s.body.question.position, 6);
  const past = await submit(env, allowed.c.id, allowed.players[0].token, allowed.key[0].id, 'A');
  assert.equal(past.body.error.code, 'deadline_passed');
  clockCtl.reset();

  const strict = await liveCompetition({ lateEntryAllowed: false });
  clockCtl.freezeAt(opensAt(strict.c.startAt, 2) + 500);
  const s2 = await call(env.app, 'GET', `/api/competitions/${strict.c.id}/state`, { token: strict.players[0].token });
  assert.equal(s2.body.entryError.code, 'late_entry_closed');
  const sub = await submit(env, strict.c.id, strict.players[0].token, strict.key[1].id, 'A');
  assert.equal(sub.status, 403);
});

test('unregistered and unauthenticated users cannot submit', async () => {
  const { c, key } = await liveCompetition();
  const outsider = await loginUser(env);
  clockCtl.freezeAt(opensAt(c.startAt, 1) + 100);
  assert.equal((await submit(env, c.id, outsider.token, key[0].id, 'A')).body.error.code, 'not_registered');
  assert.equal((await call(env.app, 'POST', `/api/competitions/${c.id}/answers`, { body: { questionId: key[0].id, option: 'A' }, headers: { 'x-requested-with': 'quiz-app' } })).status, 401);
  assert.equal((await submit(env, c.id, outsider.token, key[0].id, 'E')).status, 400);
});

test('suspended accounts lose access immediately', async () => {
  const { c, players: [u], key } = await liveCompetition();
  const r = await call(env.app, 'POST', `/api/admin/users/${u.user.id}/suspend`, { token: admin, body: { reason: 'Abusive behaviour' } });
  assert.equal(r.status, 200);
  clockCtl.freezeAt(opensAt(c.startAt, 1) + 100);
  assert.equal((await submit(env, c.id, u.token, key[0].id, 'A')).status, 401);
});

test('cancelling a live competition stops answer acceptance', async () => {
  const { c, players: [u], key } = await liveCompetition();
  clockCtl.freezeAt(opensAt(c.startAt, 1) + 100);
  assert.equal((await submit(env, c.id, u.token, key[0].id, 'A')).status, 200);
  const r = await call(env.app, 'POST', `/api/admin/competitions/${c.id}/cancel`, { token: admin, body: { reason: 'Technical failure' } });
  assert.equal(r.status, 200);
  await new Promise((res) => setImmediate(res));
  env.ctx.engine.invalidate(c.id);
  clockCtl.freezeAt(opensAt(c.startAt, 2) + 100);
  const after = await submit(env, c.id, u.token, key[1].id, 'A');
  assert.equal(after.status, 409);
  assert.equal(after.body.error.code, 'competition_not_live');
});
