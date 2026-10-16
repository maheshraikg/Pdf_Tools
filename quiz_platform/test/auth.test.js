import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { call, loginUser, nextPhone, setup } from './helpers.js';

let env;
const X = { 'x-requested-with': 'quiz-app' };
before(async () => { env = await setup(); });
after(async () => { await env.close(); });

async function requestOtp(phone) {
  return call(env.app, 'POST', '/api/auth/otp/request', { body: { phone }, headers: X });
}
async function verify(challengeId, code) {
  return call(env.app, 'POST', '/api/auth/otp/verify', { body: { challengeId, code }, headers: X });
}

test('OTP registration and login: six digits, session cookie, profile completion', async () => {
  const phone = nextPhone();
  const r = await requestOtp(phone);
  assert.equal(r.status, 200);
  const code = env.sms.lastOtpFor(`91${phone}`);
  assert.match(code, /^\d{6}$/);
  const v = await verify(r.body.challengeId, code);
  assert.equal(v.status, 200);
  assert.equal(v.body.isNew, true);
  assert.equal(v.body.profileComplete, false);
  const cookie = v.raw.cookies.find((c) => c.name === 'qsid');
  assert.ok(cookie.httpOnly);
  assert.equal(cookie.sameSite, 'Strict');
  const me = await call(env.app, 'GET', '/api/me', { cookie: `qsid=${cookie.value}` });
  assert.equal(me.status, 200);
  assert.equal(me.body.user.maskedPhone.endsWith(phone.slice(-4)), true);
  const upd = await call(env.app, 'PATCH', '/api/me', { cookie: `qsid=${cookie.value}`, headers: X, body: { displayName: 'Asha K' } });
  assert.equal(upd.status, 200);
  assert.equal(upd.body.user.displayName, 'Asha K');
});

test('OTP and phone are never stored in plain text', async () => {
  const phone = nextPhone();
  const r = await requestOtp(phone);
  const code = env.sms.lastOtpFor(`91${phone}`);
  const ch = await env.pool.query('SELECT * FROM otp_challenges WHERE id = $1', [r.body.challengeId]);
  const dump = JSON.stringify(ch.rows[0]) + ch.rows[0].code_hash.toString('utf8') + ch.rows[0].phone_enc.toString('utf8');
  assert.ok(!dump.includes(code));
  assert.ok(!dump.includes(phone));
  await verify(r.body.challengeId, code);
  const u = await env.pool.query('SELECT * FROM users');
  for (const row of u.rows) {
    assert.ok(!row.phone_hash.toString('utf8').includes(phone));
    assert.ok(!row.phone_enc.toString('utf8').includes(phone));
  }
});

test('incorrect OTP: attempts are counted and the challenge is locked after the maximum', async () => {
  const phone = nextPhone();
  const r = await requestOtp(phone);
  const code = env.sms.lastOtpFor(`91${phone}`);
  const wrong = code === '000000' ? '111111' : '000000';
  for (let i = 1; i <= 5; i++) {
    const v = await verify(r.body.challengeId, wrong);
    if (i < 5) {
      assert.equal(v.status, 400);
      assert.equal(v.body.error.code, 'otp_incorrect');
      assert.equal(v.body.error.details.attemptsRemaining, 5 - i);
    }
  }
  const final = await verify(r.body.challengeId, code);
  assert.equal(final.status, 400);
  assert.equal(final.body.error.code, 'otp_expired');
});

test('expired OTP is rejected', async () => {
  const phone = nextPhone();
  const r = await requestOtp(phone);
  const code = env.sms.lastOtpFor(`91${phone}`);
  await env.pool.query(`UPDATE otp_challenges SET expires_at = now() - interval '1 second' WHERE id = $1`, [r.body.challengeId]);
  const v = await verify(r.body.challengeId, code);
  assert.equal(v.status, 400);
  assert.equal(v.body.error.code, 'otp_expired');
});

test('OTP is single use, and a new request invalidates the previous OTP', async () => {
  const phone = nextPhone();
  const r = await requestOtp(phone);
  const code = env.sms.lastOtpFor(`91${phone}`);
  assert.equal((await verify(r.body.challengeId, code)).status, 200);
  assert.equal((await verify(r.body.challengeId, code)).status, 400);

  const phone2 = nextPhone();
  const a = await requestOtp(phone2);
  const codeA = env.sms.lastOtpFor(`91${phone2}`);
  await env.pool.query(`UPDATE otp_challenges SET created_at = now() - interval '1 minute' WHERE id = $1`, [a.body.challengeId]);
  const b = await requestOtp(phone2);
  assert.equal(b.status, 200);
  assert.equal((await verify(a.body.challengeId, codeA)).body.error.code, 'otp_expired');
});

test('resend cooldown and per-number hourly send limit', async () => {
  const phone = nextPhone();
  assert.equal((await requestOtp(phone)).status, 200);
  const again = await requestOtp(phone);
  assert.equal(again.status, 429);
  assert.equal(again.body.error.code, 'otp_cooldown');
  assert.ok(again.raw.headers['retry-after']);
  let limited = false;
  for (let i = 0; i < 6; i++) {
    await env.pool.query(`UPDATE otp_challenges SET created_at = created_at - interval '1 minute'`);
    const r = await requestOtp(phone);
    if (r.status === 429 && r.body.error.code === 'rate_limited') { limited = true; break; }
  }
  assert.ok(limited, 'hourly per-number limit must apply');
});

test('concurrent logins for one number never create duplicate accounts', async () => {
  const phone = nextPhone();
  const results = [];
  for (let i = 0; i < 3; i++) {
    await env.pool.query(`UPDATE otp_challenges SET created_at = created_at - interval '1 minute'`);
    const r = await requestOtp(phone);
    results.push({ id: r.body.challengeId, code: env.sms.lastOtpFor(`91${phone}`) });
  }
  // Only the latest challenge is valid; verify it twice concurrently.
  const last = results.at(-1);
  const vs = await Promise.all([verify(last.id, last.code), verify(last.id, last.code)]);
  assert.equal(vs.filter((v) => v.status === 200).length, 1);
  await env.pool.query(`UPDATE otp_challenges SET created_at = created_at - interval '1 minute'`);
  const again = await loginUser(env, { phone, name: null });
  assert.equal(again.user.id, vs.find((v) => v.status === 200).body.user.id);
  const n = await env.pool.query(`SELECT count(*)::int AS n FROM users WHERE phone_last4 = $1`, [phone.slice(-4)]);
  assert.equal(n.rows[0].n, 1);
});

test('invalid mobile numbers are rejected', async () => {
  for (const p of ['12345', 'abcdefghij', '5123456789', '+91 12345 67890']) {
    const r = await requestOtp(p);
    assert.equal(r.status, 400, p);
    assert.equal(r.body.error.code, 'invalid_phone');
  }
});

test('logout revokes the session; protected endpoints require authentication', async () => {
  const { token } = await loginUser(env);
  assert.equal((await call(env.app, 'GET', '/api/me', { token })).status, 200);
  assert.equal((await call(env.app, 'POST', '/api/auth/logout', { token })).status, 200);
  assert.equal((await call(env.app, 'GET', '/api/me', { token })).status, 401);
  assert.equal((await call(env.app, 'GET', '/api/me')).status, 401);
  assert.equal((await call(env.app, 'GET', '/api/me', { token: 'forged-token' })).status, 401);
});

test('expired sessions are refused', async () => {
  const { token, user } = await loginUser(env);
  await env.pool.query(`UPDATE sessions SET expires_at = now() - interval '1 second' WHERE subject_id = $1`, [user.id]);
  env.ctx.sessionCache.clear();
  assert.equal((await call(env.app, 'GET', '/api/me', { token })).status, 401);
});

test('cookie-authenticated mutations require the anti-CSRF header', async () => {
  const { token } = await loginUser(env);
  const r = await call(env.app, 'PATCH', '/api/me', { cookie: `qsid=${token}`, body: { displayName: 'Evil' } });
  assert.equal(r.status, 403);
  assert.equal(r.body.error.code, 'csrf');
});

test('display names are validated (no markup)', async () => {
  const { token } = await loginUser(env);
  const r = await call(env.app, 'PATCH', '/api/me', { token, body: { displayName: '<script>alert(1)</script>' } });
  assert.equal(r.status, 400);
});

test('static app shell and admin dashboard are served with security headers', async () => {
  for (const url of ['/', '/admin', '/js/app.js', '/sw.js', '/c/some/deep/link']) {
    const r = await call(env.app, 'GET', url);
    assert.equal(r.status, 200, url);
    assert.match(r.raw.headers['content-security-policy'], /script-src 'self'/);
    assert.equal(r.raw.headers['x-frame-options'], 'DENY');
  }
  const api404 = await call(env.app, 'GET', '/api/nope');
  assert.equal(api404.status, 404);
});
