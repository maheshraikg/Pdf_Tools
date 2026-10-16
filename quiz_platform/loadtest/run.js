// End-to-end load test: simulates N participants taking a real competition.
//
// Every simulated participant:
//   1. obtains a session (load-test endpoint; bypasses SMS only),
//   2. registers for the competition,
//   3. keeps a WebSocket open and waits for the server to push each question,
//   4. answers each question after a random "thinking" delay (0.3–9.5 s),
//      ~10% deliberately skip questions,
//   5. occasionally requests the leaderboard.
// Clients are spread across worker threads and across the server nodes given
// in TARGETS (simulating a load balancer).
//
// Usage:
//   ADMIN_EMAIL=… ADMIN_PASSWORD=… LOAD_TEST_SECRET=… \
//   TARGETS=http://localhost:3001,http://localhost:3002 PARTICIPANTS=10000 WORKERS=3 node loadtest/run.js
//
// Server nodes must run with LOAD_TEST_SECRET set (never in production) and a
// raised RATE_LIMIT_GLOBAL_PER_IP_PER_MINUTE, because all simulated clients share one IP.
import { Worker, isMainThread, parentPort, workerData } from 'node:worker_threads';
import { fileURLToPath } from 'node:url';
import os from 'node:os';
import WebSocket from 'ws';
import { Agent, setGlobalDispatcher } from 'undici';

const env = (k, d) => process.env[k] ?? d;

function pct(sorted, p) {
  if (!sorted.length) return null;
  return sorted[Math.min(sorted.length - 1, Math.floor((p / 100) * sorted.length))];
}
function summary(values) {
  const s = Float64Array.from(values).sort();
  const n = s.length;
  return n ? { n, p50: +pct(s, 50).toFixed(1), p95: +pct(s, 95).toFixed(1), p99: +pct(s, 99).toFixed(1), max: +s[n - 1].toFixed(1), mean: +(s.reduce((a, b) => a + b, 0) / n).toFixed(1) } : { n: 0 };
}

async function pool(items, concurrency, fn) {
  let i = 0;
  const run = async () => { while (i < items.length) { const k = i++; await fn(items[k], k); } };
  await Promise.all(Array.from({ length: concurrency }, run));
}

// ---------------------------------------------------------------------------
// Worker: owns a slice of simulated participants
// ---------------------------------------------------------------------------
async function workerMain() {
  setGlobalDispatcher(new Agent({ connections: 256, pipelining: 1, keepAliveTimeout: 60_000 }));
  const { targets, from, to, secret, competitionId } = workerData;
  const stats = { setupErrors: 0, submitLatency: [], pushDelay: [], submitOk: 0, submitErr: {}, wsDrops: 0, lbLatency: [], lbErr: 0, stateLatency: [] };
  const post = async (base, path, body, token, extra = {}) => {
    const r = await fetch(base + path, {
      method: 'POST',
      headers: { 'content-type': 'application/json', 'x-requested-with': 'quiz-app', ...(token ? { authorization: `Bearer ${token}` } : {}), ...extra },
      body: JSON.stringify(body ?? {}),
    });
    const j = await r.json().catch(() => ({}));
    return { status: r.status, body: j };
  };

  const clients = [];
  for (let n = from; n < to; n++) clients.push({ n, base: targets[n % targets.length] });

  // Phase 1: sessions + registration
  await pool(clients, 64, async (c) => {
    try {
      const s = await post(c.base, '/api/loadtest/session', { n: c.n }, null, { 'x-load-test-secret': secret });
      if (s.status !== 200) throw new Error(`session ${s.status}`);
      c.token = s.body.token;
      const r = await post(c.base, `/api/competitions/${competitionId}/register`, {}, c.token);
      if (r.status !== 200) throw new Error(`register ${r.status} ${JSON.stringify(r.body)}`);
    } catch (e) {
      stats.setupErrors++;
      c.failed = true;
      if (stats.setupErrors < 5) console.error('setup', e.message);
    }
  });
  parentPort.postMessage({ type: 'ready', count: clients.filter((c) => !c.failed).length });

  // Phase 2: sockets
  const active = clients.filter((c) => !c.failed);
  await pool(active, 100, (c) => new Promise((resolve) => {
    const ws = new WebSocket(`${c.base.replace('http', 'ws')}/api/ws`, { headers: { authorization: `Bearer ${c.token}` }, perMessageDeflate: false });
    c.ws = ws;
    ws.on('open', () => { ws.send(JSON.stringify({ type: 'subscribe', competitionId })); resolve(); });
    ws.on('error', () => resolve());
    ws.on('close', () => { if (!c.done) stats.wsDrops++; });
    ws.on('message', (raw) => {
      const m = JSON.parse(raw.toString());
      if (m.type === 'question') onQuestion(c, m.question);
      if (m.type === 'competition_ended') { c.done = true; }
    });
  }));
  parentPort.postMessage({ type: 'connected', count: active.filter((c) => c.ws?.readyState === 1).length });

  // A small share of clients "refresh" by polling state each question.
  async function onQuestion(c, q) {
    stats.pushDelay.push(Date.now() - q.opensAt);
    if (c.n % 50 === 0) {
      const t0 = performance.now();
      const r = await fetch(`${c.base}/api/competitions/${competitionId}/state`, { headers: { authorization: `Bearer ${c.token}` } }).catch(() => null);
      if (r?.ok) stats.stateLatency.push(performance.now() - t0);
      await r?.arrayBuffer().catch(() => {});
    }
    if (Math.random() < 0.1) return; // skip ~10%
    const delay = 300 + Math.random() * 9200;
    setTimeout(async () => {
      const t0 = performance.now();
      try {
        const r = await post(c.base, `/api/competitions/${competitionId}/answers`, { questionId: q.id, option: 'ABCD'[Math.floor(Math.random() * 4)], idempotencyKey: `${c.n}-${q.position}` }, c.token);
        stats.submitLatency.push(performance.now() - t0);
        if (r.status === 200) stats.submitOk++;
        else stats.submitErr[r.body?.error?.code ?? r.status] = (stats.submitErr[r.body?.error?.code ?? r.status] ?? 0) + 1;
      } catch (e) {
        stats.submitErr[e.cause?.code ?? e.message] = (stats.submitErr[e.cause?.code ?? e.message] ?? 0) + 1;
      }
      // ~2% of answers are followed by a leaderboard request (provisional view).
      if (Math.random() < 0.02) {
        const t1 = performance.now();
        const r = await fetch(`${c.base}/api/competitions/${competitionId}/leaderboard?limit=10`).catch(() => null);
        if (r?.ok) stats.lbLatency.push(performance.now() - t1); else stats.lbErr++;
        await r?.arrayBuffer().catch(() => {});
      }
    }, delay);
  }

  parentPort.on('message', (m) => {
    if (m === 'report') {
      for (const c of active) { c.done = true; c.ws?.close(); }
      parentPort.postMessage({ type: 'report', stats });
    }
  });
}

// ---------------------------------------------------------------------------
// Main: create the competition, start workers, collect results
// ---------------------------------------------------------------------------
async function main() {
  const targets = env('TARGETS', 'http://localhost:3000').split(',');
  const participants = Number(env('PARTICIPANTS', 1000));
  const workers = Number(env('WORKERS', Math.max(1, Math.min(4, os.cpus().length - 1))));
  const secret = env('LOAD_TEST_SECRET');
  const startInSec = Math.max(65, Number(env('START_IN_SECONDS', 90)));
  if (!secret) throw new Error('LOAD_TEST_SECRET is required');
  const X = { 'content-type': 'application/json', 'x-requested-with': 'quiz-app' };

  const login = await fetch(`${targets[0]}/api/admin/auth/login`, { method: 'POST', headers: X, body: JSON.stringify({ email: env('ADMIN_EMAIL'), password: env('ADMIN_PASSWORD') }) });
  if (!login.ok) throw new Error(`admin login failed ${login.status}`);
  const cookie = login.headers.getSetCookie().find((c) => c.startsWith('qadm=')).split(';')[0];
  const A = { ...X, cookie };
  const adm = async (method, path, body) => {
    const r = await fetch(`${targets[0]}/api/admin${path}`, { method, headers: A, body: body ? JSON.stringify(body) : undefined });
    const j = await r.json().catch(() => ({}));
    if (!r.ok) throw new Error(`${path}: ${JSON.stringify(j)}`);
    return j;
  };
  const start = new Date(Math.ceil((Date.now() + startInSec * 1000) / 1000) * 1000);
  const { competition } = await adm('POST', '/competitions', {
    title: `Load test ${participants} participants`, startAt: start.toISOString(),
    registrationOpensAt: new Date(Date.now() - 1000).toISOString(), registrationClosesAt: start.toISOString(),
    showProvisional: true, transitionMs: 3000,
  });
  const qs = Array.from({ length: 15 }, (_, i) => ({ text: `Load question ${i + 1}?`, optionA: 'Alpha', optionB: 'Bravo', optionC: 'Charlie', optionD: 'Delta', correctOption: 'ABCD'[i % 4] }));
  await adm('POST', `/competitions/${competition.id}/questions/import`, { questions: qs });
  await adm('POST', `/competitions/${competition.id}/schedule`, {});
  console.log(`competition ${competition.code} starts ${start.toISOString()} — ${participants} participants, ${workers} workers, ${targets.length} server node(s)`);

  const t0 = Date.now();
  const per = Math.ceil(participants / workers);
  const ws = [];
  let ready = 0;
  let readyWorkers = 0;
  let connected = 0;
  for (let w = 0; w < workers; w++) {
    const worker = new Worker(fileURLToPath(import.meta.url), {
      workerData: { targets, from: w * per, to: Math.min(participants, (w + 1) * per), secret, competitionId: competition.id },
    });
    worker.on('message', (m) => {
      if (m.type === 'ready') {
        ready += m.count;
        readyWorkers += 1;
        if (readyWorkers === workers) {
          console.log(`${ready}/${participants} sessions + registrations ready in ${((Date.now() - t0) / 1000).toFixed(1)} s`);
          if (ready === 0) { console.error('setup failed for every participant; aborting'); process.exit(1); }
        }
      }
      if (m.type === 'connected') { connected += m.count; }
    });
    worker.on('error', (e) => console.error('worker error', e));
    ws.push(worker);
  }

  const endsAt = start.getTime() + 14 * 13_000 + 10_000;
  const iv = setInterval(async () => {
    const s = await adm('GET', `/competitions/${competition.id}/live`).catch(() => null);
    if (s) console.log(`[${new Date().toISOString().slice(11, 19)}] registered=${s.registered} connected=${s.connected} entered=${s.started} answers/s=${s.submissions.perSecondLast10s} total=${s.submissions.total}`);
  }, 10_000);
  await new Promise((r) => setTimeout(r, Math.max(0, endsAt - Date.now() + 3000)));
  clearInterval(iv);

  const reports = await Promise.all(ws.map((w) => new Promise((resolve) => {
    w.once('message', function handler(m) { if (m.type === 'report') resolve(m.stats); else w.once('message', handler); });
    w.postMessage('report');
  })));
  for (const w of ws) await w.terminate();

  const agg = { setupErrors: 0, submitOk: 0, submitErr: {}, wsDrops: 0, lbErr: 0, submitLatency: [], pushDelay: [], lbLatency: [], stateLatency: [] };
  for (const r of reports) {
    agg.setupErrors += r.setupErrors; agg.submitOk += r.submitOk; agg.wsDrops += r.wsDrops; agg.lbErr += r.lbErr;
    for (const [k, v] of Object.entries(r.submitErr)) agg.submitErr[k] = (agg.submitErr[k] ?? 0) + v;
    for (const k of ['submitLatency', 'pushDelay', 'lbLatency', 'stateLatency']) for (const v of r[k]) agg[k].push(v);
  }
  // Wait for finalisation, then verify integrity against the database via the API.
  await new Promise((r) => setTimeout(r, 4000));
  const report = await adm('GET', `/competitions/${competition.id}/report`).catch((e) => ({ error: e.message }));
  const totalErr = Object.values(agg.submitErr).reduce((a, b) => a + b, 0);
  const attempts = agg.submitOk + totalErr;
  const result = {
    participants, workers, serverNodes: targets.length, connectedSockets: connected,
    setupErrors: agg.setupErrors, wsDrops: agg.wsDrops,
    answers: { attempted: attempts, accepted: agg.submitOk, errors: agg.submitErr, errorRate: attempts ? +(totalErr / attempts * 100).toFixed(3) : 0 },
    peakWindowAnswersPerSecond: +(attempts / 15 / 9.2).toFixed(0),
    latencyMs: { submit: summary(agg.submitLatency), questionPushDelay: summary(agg.pushDelay), leaderboard: summary(agg.lbLatency), state: summary(agg.stateLatency) },
    leaderboardErrors: agg.lbErr,
    integrity: report.error ? report : {
      participantsCompleted: report.participants?.completed,
      acceptedAnswersInDb: report.questions?.reduce((s, q) => s + q.correct + q.incorrect, 0),
      matchesClientAccepted: report.questions?.reduce((s, q) => s + q.correct + q.incorrect, 0) === agg.submitOk,
    },
  };
  console.log(JSON.stringify(result, null, 2));
  process.exit(0);
}

if (isMainThread) main().catch((e) => { console.error(e); process.exit(1); });
else workerMain();
