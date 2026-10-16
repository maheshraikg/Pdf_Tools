import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import ExcelJS from 'exceljs';
import { parseCsv } from '../src/lib/csv.js';
import { finalizeCompetition } from '../src/services/results.js';
import {
  adminToken, answerKey, call, clockCtl, createCompetition, loginUser, opensAt, register, setup, submit, wrongOf,
} from './helpers.js';

let env;
let admin;
let c;
let key;
const P = {};

// Scripted answers: position -> [correct?, responseMs]
const plan = {
  A: Object.fromEntries(Array.from({ length: 15 }, (_, i) => [i + 1, [true, 1000]])), // 15, 15,000 ms
  B: Object.fromEntries(Array.from({ length: 15 }, (_, i) => [i + 1, [true, 1100]])), // 15, 16,500 ms
  C: { ...Object.fromEntries(Array.from({ length: 14 }, (_, i) => [i + 1, [true, 500]])), 15: [false, 500] }, // 14 marks, fastest
  D: Object.fromEntries(Array.from({ length: 10 }, (_, i) => [i + 1, [true, 2000]])),
  E: Object.fromEntries(Array.from({ length: 10 }, (_, i) => [i + 1, [true, 2000]])), // identical to D
  F: { ...Object.fromEntries(Array.from({ length: 10 }, (_, i) => [i + 1, [true, 2000]])), 11: [false, 6000] },
  I: { ...Object.fromEntries(Array.from({ length: 10 }, (_, i) => [i + 1, [true, 2000]])), 14: [false, 1000], 15: [false, 2000] },
  J: { ...Object.fromEntries(Array.from({ length: 10 }, (_, i) => [i + 1, [true, 2000]])), 14: [false, 2000], 15: [false, 1000] },
  H: {}, // enters but never answers
};

before(async () => {
  env = await setup();
  admin = await adminToken(env);
  const created = await createCompetition(env, admin, { showProvisional: false });
  c = created;
  key = await answerKey(env, c.id);
  for (const name of [...Object.keys(plan), 'G']) {
    P[name] = await loginUser(env, { name: `Player ${name}` });
    assert.equal((await register(env, c.id, P[name].token)).status, 200);
  }
  // Competition starts: lifecycle freezes it.
  clockCtl.freezeAt(c.startAt + 1);
  await env.ctx.lifecycle.transitions();
  // H enters (opens the quiz) but never answers. G never enters.
  await call(env.app, 'GET', `/api/competitions/${c.id}/state`, { token: P.H.token });
  for (let p = 1; p <= 15; p++) {
    const entries = Object.entries(plan).filter(([, ans]) => ans[p]).sort((a, b) => a[1][p][1] - b[1][p][1]);
    for (const [name, ans] of entries) {
      const [correct, ms] = ans[p];
      clockCtl.freezeAt(opensAt(c.startAt, p) + ms + 0.25);
      const q = key[p - 1];
      const r = await submit(env, c.id, P[name].token, q.id, correct ? q.correct_option : wrongOf(q.correct_option));
      assert.equal(r.status, 200, `${name} Q${p}: ${JSON.stringify(r.body)}`);
      assert.equal(r.body.responseMs, ms);
    }
  }
});
after(async () => { await env.close(); });

test('leaderboard is hidden from the public while live unless provisional standings are enabled', async () => {
  clockCtl.freezeAt(opensAt(c.startAt, 15) + 5000);
  const pub = await call(env.app, 'GET', `/api/competitions/${c.id}/leaderboard`);
  assert.equal(pub.status, 403);
  const adm = await call(env.app, 'GET', `/api/admin/competitions/${c.id}/leaderboard?limit=3`, { token: admin });
  assert.equal(adm.status, 200);
  assert.equal(adm.body.provisional, true);
  assert.equal(adm.body.rows[0].registrationId, P.A.user.registrationId);
  // My result during the competition never reveals correctness.
  const mine = await call(env.app, 'GET', `/api/competitions/${c.id}/my-result`, { token: P.A.token });
  assert.equal(mine.body.final, false);
  assert.equal(mine.body.questions, undefined);
});

test('finalisation computes official ranks with every tie-breaker', async () => {
  const end = opensAt(c.startAt, 15) + 10_000;
  clockCtl.freezeAt(end - 1);
  assert.equal(await finalizeCompetition(env.ctx, c.id), null, 'cannot finalise before the last deadline');
  clockCtl.freezeAt(end + 2500);
  await env.ctx.lifecycle.transitions();
  assert.equal(await finalizeCompetition(env.ctx, c.id), null, 'finalisation is idempotent');

  const r = await env.pool.query(
    `SELECT u.display_name AS name, r.* FROM competition_results r
       JOIN competition_participants p ON p.id = r.participant_id JOIN users u ON u.id = p.user_id
      WHERE r.competition_id = $1 ORDER BY r.final_rank, u.display_name`, [c.id]);
  const got = r.rows.map((x) => [x.name.replace('Player ', ''), x.final_rank, x.total_marks, Number(x.correct_time_ms), Number(x.total_time_ms)]);
  assert.deepEqual(got, [
    ['A', 1, 15, 15000, 15000],
    ['B', 2, 15, 16500, 16500],
    ['C', 3, 14, 7000, 7500],
    ['D', 4, 10, 20000, 20000],
    ['E', 4, 10, 20000, 20000], // identical on all criteria => shared rank
    ['J', 6, 10, 20000, 23000], // same times as I, but completed Q15 earlier
    ['I', 7, 10, 20000, 23000],
    ['F', 8, 10, 20000, 26000],
    ['H', 9, 0, 0, 0],
  ]);
  const h = r.rows.find((x) => x.name === 'Player H');
  assert.deepEqual([h.correct_count, h.incorrect_count, h.unanswered_count], [0, 0, 15]);
  const cc = r.rows.find((x) => x.name === 'Player C');
  assert.deepEqual([cc.correct_count, cc.incorrect_count, cc.unanswered_count, cc.attempted_count], [14, 1, 0, 15]);

  // Every started participant has exactly 15 answer records (accepted or timeout).
  const per = await env.pool.query(
    `SELECT count(*)::int AS n, count(*) FILTER (WHERE status = 'timeout')::int AS timeouts
       FROM answer_submissions WHERE competition_id = $1 GROUP BY participant_id ORDER BY 1`, [c.id]);
  assert.ok(per.rows.every((x) => x.n === 15));
  const absent = await env.pool.query(
    `SELECT p.status FROM competition_participants p WHERE p.user_id = $1`, [P.G.user.id]);
  assert.equal(absent.rows[0].status, 'absent');
  const status = await env.pool.query('SELECT status FROM competitions WHERE id = $1', [c.id]);
  assert.equal(status.rows[0].status, 'completed');
});

test('ranks are hidden until results are published; then the official leaderboard is public', async () => {
  const before = await call(env.app, 'GET', `/api/competitions/${c.id}/my-result`, { token: P.C.token });
  assert.equal(before.body.final, true);
  assert.equal(before.body.rank, null);
  assert.equal(before.body.totalMarks, 14);
  assert.equal(before.body.questions[14].isCorrect, false);
  assert.equal((await call(env.app, 'GET', `/api/competitions/${c.id}/leaderboard`)).status, 403);

  const pub = await call(env.app, 'POST', `/api/admin/competitions/${c.id}/publish`, { token: admin });
  assert.equal(pub.status, 200);
  assert.equal((await call(env.app, 'POST', `/api/admin/competitions/${c.id}/publish`, { token: admin })).status, 409);

  const top10 = await call(env.app, 'GET', `/api/competitions/${c.id}/leaderboard?limit=10`);
  assert.equal(top10.status, 200);
  assert.equal(top10.body.official, true);
  assert.equal(top10.body.total, 9);
  assert.deepEqual(top10.body.rows.slice(0, 3).map((x) => [x.displayName, x.rank, x.totalMarks, x.correctTimeMs]),
    [['Player A', 1, 15, 15000], ['Player B', 2, 15, 16500], ['Player C', 3, 14, 7000]]);
  assert.equal(top10.body.rows[0].maxMarks, 15);
  assert.ok(!JSON.stringify(top10.body).includes(P.A.phone), 'no phone numbers on the leaderboard');

  const page2 = await call(env.app, 'GET', `/api/competitions/${c.id}/leaderboard?limit=3&page=2`);
  assert.deepEqual(page2.body.rows.map((x) => x.rank), [4, 4, 6]);
  const byName = await call(env.app, 'GET', `/api/competitions/${c.id}/leaderboard?q=player%20j`);
  assert.deepEqual(byName.body.rows.map((x) => x.rank), [6]);
  const byId = await call(env.app, 'GET', `/api/competitions/${c.id}/leaderboard?q=${P.B.user.registrationId.toLowerCase()}`);
  assert.equal(byId.body.rows[0].displayName, 'Player B');

  const card = await call(env.app, 'GET', `/api/competitions/${c.id}/results/${P.C.user.registrationId}`);
  assert.equal(card.body.rank, 3);
  const mine = await call(env.app, 'GET', `/api/competitions/${c.id}/my-result`, { token: P.C.token });
  assert.equal(mine.body.rank, 3);
  assert.equal(mine.body.rankedCount, 9);
  const hist = await call(env.app, 'GET', '/api/me/history', { token: P.A.token });
  assert.equal(hist.body.competitions[0].rank, 1);
  const notes = await call(env.app, 'GET', '/api/me/notifications', { token: P.A.token });
  assert.ok(notes.body.notifications.some((n) => n.kind === 'results_published' && n.body.includes('rank: 1')));
});

test('CSV export contains exact millisecond times and official ranks', async () => {
  const r = await call(env.app, 'GET', `/api/admin/competitions/${c.id}/export?format=csv`, { token: admin });
  assert.equal(r.status, 200);
  assert.match(r.raw.headers['content-disposition'], /attachment; filename="results-QC-.*\.csv"/);
  const rows = parseCsv(r.raw.body);
  const header = rows[0];
  const idx = (h) => header.indexOf(h);
  const byName = Object.fromEntries(rows.slice(1).map((x) => [x[idx('Name')], x]));
  assert.equal(byName['Player A'][idx('Rank')], '1');
  assert.equal(byName['Player B'][idx('Correct-Answer Time (ms)')], '16500');
  assert.equal(byName['Player J'][idx('Rank')], '6');
  assert.equal(byName['Player I'][idx('Total Response Time (ms)')], '23000');
  assert.equal(byName['Player C'][idx('Q15 Answer')].endsWith('✗'), true);
  assert.equal(byName['Player C'][idx('Q1 Time (ms)')], '500');
  assert.match(byName['Player A'][idx('Mobile')], /^\*{6}\d{4}$/, 'phones are masked by default');
  assert.equal(rows.length, 10);
});

test('Excel export round-trips the same data', async () => {
  const r = await call(env.app, 'GET', `/api/admin/competitions/${c.id}/export?format=xlsx`, { token: admin });
  assert.equal(r.status, 200);
  const wb = new ExcelJS.Workbook();
  await wb.xlsx.load(r.raw.rawPayload);
  const ws = wb.getWorksheet('Results');
  assert.equal(ws.rowCount, 10);
  assert.equal(ws.getRow(2).getCell(1).value, 1);
  assert.equal(ws.getRow(2).getCell(10).value, 15000);
});

test('competition report statistics', async () => {
  const r = await call(env.app, 'GET', `/api/admin/competitions/${c.id}/report`, { token: admin });
  assert.equal(r.status, 200);
  assert.deepEqual(
    [r.body.participants.registered, r.body.participants.started, r.body.participants.completed, r.body.participants.absent],
    [10, 9, 9, 1]);
  assert.equal(r.body.scores.max, 15);
  assert.equal(r.body.questions.length, 15);
  assert.equal(r.body.questions[0].correct, 8);
  assert.equal(r.body.questions[0].unanswered, 1);
  assert.equal(r.body.distribution.find((d) => d.marks === 10).count, 5);
  const audit = await call(env.app, 'GET', `/api/admin/audit?entityId=${c.id}`, { token: admin });
  const actions = audit.body.logs.map((l) => l.action);
  for (const a of ['competition.started', 'competition.finalized', 'results.published', 'results.exported']) assert.ok(actions.includes(a), a);
});
