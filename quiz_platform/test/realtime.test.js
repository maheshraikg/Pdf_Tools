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

test('question is pushed at the server-scheduled instant, without the answer key; clock sync works', async () => {
  const admin = await adminToken(env);
  const c = await createCompetition(env, admin);
  const u = await loginUser(env);
  await register(env, c.id, u.token);
  // Shift the server clock so the competition starts ~1.2 s from now (real time).
  clockCtl.advance(c.startAt - clockCtl.now() - 1200);

  const { ws, next } = connect(u.token);
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
  ws.close();
});
