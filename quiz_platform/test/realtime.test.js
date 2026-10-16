import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import WebSocket from 'ws';
import { adminToken, clockCtl, createCompetition, loginUser, register, setup } from './helpers.js';

let env;
let base;
before(async () => {
  env = await setup();
  await env.app.listen({ port: 0, host: '127.0.0.1' });
  base = `ws://127.0.0.1:${env.app.server.address().port}/api/ws`;
});
after(async () => { await env.close(); });

function connect(token) {
  const ws = new WebSocket(base, { headers: token ? { authorization: `Bearer ${token}` } : {} });
  const messages = [];
  const waiters = [];
  ws.on('message', (raw) => {
    const m = JSON.parse(raw.toString());
    messages.push(m);
    for (const w of [...waiters]) if (w.pred(m)) { waiters.splice(waiters.indexOf(w), 1); w.resolve(m); }
  });
  const next = (pred, ms = 5000) => {
    const found = messages.find(pred);
    if (found) return Promise.resolve(found);
    return new Promise((resolve, reject) => {
      waiters.push({ pred, resolve });
      setTimeout(() => reject(new Error('timeout waiting for message')), ms).unref();
    });
  };
  return { ws, messages, next };
}

test('unauthenticated sockets are closed', async () => {
  const ws = new WebSocket(base);
  const code = await new Promise((res) => ws.on('close', (c) => res(c)));
  assert.equal(code, 4001);
});

test('questions are pushed at the server-scheduled instant, without the answer key; clock sync works', async () => {
  const admin = await adminToken(env);
  const c = await createCompetition(env, admin);
  const u = await loginUser(env);
  await register(env, c.id, u.token);
  // Shift the server clock so the competition starts ~1.2 s from now (real time).
  clockCtl.advance(c.startAt - clockCtl.now() - 1200);

  const { ws, next, messages } = connect(u.token);
  await next((m) => m.type === 'hello');
  const t0 = Date.now();
  ws.send(JSON.stringify({ type: 'time', t0 }));
  const sync = await next((m) => m.type === 'time');
  assert.equal(sync.t0, t0);
  assert.ok(Math.abs(sync.serverNow - clockCtl.now()) < 1000);

  ws.send(JSON.stringify({ type: 'subscribe', competitionId: c.id }));
  await next((m) => m.type === 'subscribed');
  const q = await next((m) => m.type === 'question', 4000);
  assert.equal(q.question.position, 1);
  assert.equal(q.question.opensAt, c.startAt);
  assert.equal(q.question.closesAt, c.startAt + 10_000);
  assert.ok(q.serverNow >= c.startAt && q.serverNow - c.startAt < 200, `pushed ${q.serverNow - c.startAt} ms after opening`);
  assert.ok(!JSON.stringify(q).toLowerCase().includes('correct'));

  // Through a full boundary sequence every event is delivered exactly once,
  // even though Node timers may wake slightly before their target.
  const closed = await next((m) => m.type === 'question_closed', 13_000);
  assert.equal(closed.position, 1);
  assert.ok(closed.serverNow > c.startAt + 10_000, 'closed only after the inclusive deadline');
  assert.equal(closed.nextOpensAt, c.startAt + 13_000);
  const q2 = await next((m) => m.type === 'question' && m.question.position === 2, 6000);
  assert.ok(q2.serverNow >= c.startAt + 13_000);
  await new Promise((r) => setTimeout(r, 300));
  const count = (pred) => messages.filter(pred).length;
  assert.equal(count((m) => m.type === 'question' && m.question.position === 1), 1);
  assert.equal(count((m) => m.type === 'question_closed' && m.position === 1), 1);
  assert.equal(count((m) => m.type === 'question' && m.question.position === 2), 1);
  ws.close();
});

test('a boundary timer that wakes early (busy event loop) emits the intended event exactly once', async () => {
  const admin = await adminToken(env);
  const c = await createCompetition(env, admin);
  const hub = env.ctx.hub;
  const sock = { readyState: 1, bufferedAmount: 0, sent: [], send(d) { this.sent.push(JSON.parse(d)); }, terminate() {} };
  hub.rooms.set(c.id, new Set([sock]));
  try {
    // Wake-ups 4 ms before question 1's deadline: it must not re-send question 1,
    // and it must send "closed" only for the intended boundary.
    clockCtl.freezeAt(c.startAt + 10_000 - 4);
    const closeTarget = { kind: 'close', position: 1, at: c.startAt + 10_001 };
    await hub.onBoundary(c.id, closeTarget);
    await hub.onBoundary(c.id, closeTarget); // duplicate wake-up
    // Wake-up 3 ms before question 2 opens.
    clockCtl.freezeAt(c.startAt + 13_000 - 3);
    await hub.onBoundary(c.id, { kind: 'open', position: 2, at: c.startAt + 13_000 });
    assert.deepEqual(sock.sent.map((m) => [m.type, m.position ?? m.question?.position]), [['question_closed', 1], ['question', 2]]);
    // A question whose window has already passed is never delivered.
    sock.sent.length = 0;
    clockCtl.freezeAt(c.startAt + 26_000 + 10_500);
    await hub.onBoundary(c.id, { kind: 'open', position: 3, at: c.startAt + 26_000 });
    assert.equal(sock.sent.filter((m) => m.type === 'question').length, 0);
  } finally {
    clearTimeout(hub.timers.get(c.id));
    hub.timers.delete(c.id);
    hub.rooms.delete(c.id);
    clockCtl.reset();
  }
});
