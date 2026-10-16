// Shared test harness: a real PostgreSQL database (DATABASE_URL_TEST), the real
// Fastify app (via inject), the development SMS provider and a controllable clock.
import { performance } from 'node:perf_hooks';
import pg from 'pg';
import { buildApp } from '../src/app.js';
import { loadConfig } from '../src/config.js';
import { setClock } from '../src/lib/clock.js';
import { migrate } from '../src/scripts/migrate.js';
import { createAdmin } from '../src/services/auth.js';
import { sampleQuestions } from '../src/scripts/sample-questions.js';

export const TEST_DB = process.env.DATABASE_URL_TEST ?? 'postgres://postgres@localhost:5432/quiz_test';

let offset = 0;
const fakeNow = () => performance.timeOrigin + performance.now() + offset;
setClock(fakeNow);
export const clockCtl = {
  now: () => performance.timeOrigin + performance.now() + offset,
  advance: (ms) => { offset += ms; },
  /** Sets the fake clock so that now() === t (epoch ms, may be fractional). */
  freezeAt: (t) => { setClock(() => t); },
  unfreeze: () => { setClock(fakeNow); },
  reset: () => { offset = 0; setClock(fakeNow); },
};

export async function setup(overrides = {}) {
  clockCtl.reset();
  const pool = new pg.Pool({ connectionString: TEST_DB, max: 40 });
  await pool.query('DROP SCHEMA public CASCADE; CREATE SCHEMA public;');
  await migrate(pool, { info() {} });
  const base = loadConfig();
  const config = {
    ...base,
    databaseUrl: TEST_DB,
    redisUrl: undefined,
    sms: { ...base.sms, provider: 'console' },
    otp: { ...base.otp, maxSendsPerIpPerHour: 1_000_000 },
    rateLimit: { ...base.rateLimit, globalPerIpPerMinute: 1_000_000, submitPerUserPerMinute: 10_000 },
    ...overrides,
  };
  const app = await buildApp({ config, logger: false, pool });
  await app.ready();
  const ctx = app.ctx;
  return {
    app, ctx, pool, sms: ctx.sms,
    async close() {
      await app.close();
      await pool.end();
      clockCtl.reset();
    },
  };
}

export async function call(app, method, url, { token, body, headers = {}, cookie } = {}) {
  const res = await app.inject({
    method, url,
    headers: {
      ...(token ? { authorization: `Bearer ${token}` } : {}),
      ...(cookie ? { cookie } : {}),
      ...headers,
    },
    ...(body !== undefined ? { payload: body } : {}),
  });
  let json;
  try { json = res.json(); } catch { json = undefined; }
  return { status: res.statusCode, body: json, raw: res };
}

let phoneSeq = 0;
export function nextPhone() {
  phoneSeq += 1;
  return `98${String(10_000_000 + phoneSeq).slice(-8)}`;
}

/** Full OTP login through the public API; returns { token, user }. */
export async function loginUser(env, { phone = nextPhone(), name = `Player ${phoneSeq}` } = {}) {
  const r1 = await call(env.app, 'POST', '/api/auth/otp/request', { body: { phone }, headers: { 'x-requested-with': 'quiz-app' } });
  if (r1.status !== 200) throw new Error(`otp request failed ${JSON.stringify(r1.body)}`);
  const code = env.sms.lastOtpFor(`91${phone}`);
  const r2 = await call(env.app, 'POST', '/api/auth/otp/verify', { body: { challengeId: r1.body.challengeId, code }, headers: { 'x-requested-with': 'quiz-app' } });
  if (r2.status !== 200) throw new Error(`otp verify failed ${JSON.stringify(r2.body)}`);
  const token = r2.body.token;
  if (name) {
    const r3 = await call(env.app, 'PATCH', '/api/me', { token, body: { displayName: name } });
    if (r3.status !== 200) throw new Error(`profile failed ${JSON.stringify(r3.body)}`);
  }
  return { token, user: r2.body.user, phone };
}

let adminSeq = 0;
export async function adminToken(env, role = 'super_admin') {
  adminSeq += 1;
  const email = `admin${adminSeq}-${role}@example.org`;
  const password = 'correct horse battery staple';
  await createAdmin(env.ctx, { email, name: `Admin ${adminSeq}`, password, role }, null);
  const r = await call(env.app, 'POST', '/api/admin/auth/login', { body: { email, password }, headers: { 'x-requested-with': 'quiz-app' } });
  if (r.status !== 200) throw new Error(`admin login failed ${JSON.stringify(r.body)}`);
  const cookie = r.raw.cookies.find((c) => c.name === 'qadm');
  return cookie.value;
}

/**
 * Creates (and by default schedules) a competition with the 15 sample questions.
 * Starts `startInMs` after the current (fake) clock.
 */
export async function createCompetition(env, admin, { startInMs = 120_000, schedule = true, questions = sampleQuestions, ...fields } = {}) {
  const now = clockCtl.now();
  const startAt = new Date(Math.ceil((now + startInMs) / 1000) * 1000);
  const body = {
    title: 'Test Quiz',
    description: 'desc',
    rules: 'rules',
    startAt: startAt.toISOString(),
    registrationOpensAt: new Date(now - 60_000).toISOString(),
    registrationClosesAt: startAt.toISOString(),
    ...fields,
  };
  const r = await call(env.app, 'POST', '/api/admin/competitions', { token: admin, body });
  if (r.status !== 200) throw new Error(`create failed ${JSON.stringify(r.body)}`);
  const id = r.body.competition.id;
  if (questions) {
    const imp = await call(env.app, 'POST', `/api/admin/competitions/${id}/questions/import`, { token: admin, body: { questions } });
    if (imp.status !== 200) throw new Error(`import failed ${JSON.stringify(imp.body)}`);
  }
  if (schedule) {
    const s = await call(env.app, 'POST', `/api/admin/competitions/${id}/schedule`, { token: admin });
    if (s.status !== 200) throw new Error(`schedule failed ${JSON.stringify(s.body)}`);
  }
  return { id, startAt: startAt.getTime(), comp: r.body.competition };
}

export const SLOT = 13_000; // 10 s question + 3 s default transition
export const opensAt = (start, p) => start + (p - 1) * SLOT;

export async function register(env, compId, token, accessCode) {
  return call(env.app, 'POST', `/api/competitions/${compId}/register`, { token, body: accessCode ? { accessCode } : {} });
}

export async function submit(env, compId, token, questionId, option, extra = {}) {
  return call(env.app, 'POST', `/api/competitions/${compId}/answers`, { token, body: { questionId, option, ...extra } });
}

/** Question ids by position (answer key) straight from the DB. */
export async function answerKey(env, compId) {
  const r = await env.pool.query('SELECT id, position, correct_option FROM questions WHERE competition_id = $1 ORDER BY position', [compId]);
  return r.rows;
}

export const wrongOf = (opt) => ({ A: 'B', B: 'C', C: 'D', D: 'A' })[opt];
