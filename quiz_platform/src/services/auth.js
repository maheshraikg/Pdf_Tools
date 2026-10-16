// Participant OTP authentication and session management (participants + admins).
import crypto from 'node:crypto';
import { clock } from '../lib/clock.js';
import { AppError, badRequest, forbidden, tooMany, unauthorized } from '../lib/errors.js';
import { normalizePhone } from '../lib/phone.js';
import {
  decrypt, encrypt, friendlyId, hashPassword, hmac, randomDigits, randomToken, sha256,
  timingSafeEqualBuf, verifyPassword,
} from '../lib/security.js';
import { audit, ipHash } from './audit.js';

const HOUR = 3600_000;

export function phoneHash(ctx, phone) {
  return hmac(ctx.cfg.keys.phoneHash, phone);
}

function otpHash(ctx, challengeId, phoneHashBuf, code) {
  return hmac(ctx.cfg.keys.otp, `${challengeId}:${phoneHashBuf.toString('hex')}:${code}`);
}

// ---------------------------------------------------------------------------
// OTP
// ---------------------------------------------------------------------------

export async function requestOtp(ctx, { phone: rawPhone, ip }) {
  const { cfg, pool, limiter } = ctx;
  const phone = normalizePhone(rawPhone, cfg.defaultCountryCode);
  const ph = phoneHash(ctx, phone);
  const phKey = ph.toString('hex');

  await limiter.enforce(`otp:send:ip:${ip}`, cfg.otp.maxSendsPerIpPerHour, HOUR,
    'Too many OTP requests from this network. Please try again later.');

  const latest = await pool.query(
    `SELECT (extract(epoch FROM now() - created_at) * 1000)::float8 AS since_ms
       FROM otp_challenges WHERE phone_hash = $1 ORDER BY created_at DESC LIMIT 1`, [ph]);
  if (latest.rowCount) {
    const since = latest.rows[0].since_ms;
    if (since < cfg.otp.resendCooldownMs) {
      throw tooMany('otp_cooldown', 'Please wait before requesting another OTP.', Math.ceil(cfg.otp.resendCooldownMs - since));
    }
  }
  await limiter.enforce(`otp:send:phone:${phKey}`, cfg.otp.maxSendsPerPhonePerHour, HOUR,
    'OTP request limit reached for this number. Please try again later.');

  const code = randomDigits(cfg.otp.length);
  const challengeId = crypto.randomUUID();
  await pool.query(
    `WITH expire_old AS (
       UPDATE otp_challenges SET consumed_at = now()
        WHERE phone_hash = $2 AND consumed_at IS NULL
     )
     INSERT INTO otp_challenges (id, phone_hash, phone_enc, code_hash, max_attempts, expires_at, ip_hash)
     VALUES ($1, $2, $3, $4, $5, now() + make_interval(secs => $6::double precision / 1000), $7)`,
    [challengeId, ph, encrypt(cfg.keys.phoneEnc, phone), otpHash(ctx, challengeId, ph, code),
      cfg.otp.maxVerifyAttempts, cfg.otp.ttlMs, ipHash(ctx, ip)],
  );

  try {
    await ctx.sms.sendOtp(phone, code);
    ctx.metrics?.otpSent.inc({ result: 'ok' });
  } catch (err) {
    ctx.metrics?.otpSent.inc({ result: 'error' });
    ctx.log.error({ err: err.message }, 'OTP delivery failed');
    await pool.query(`UPDATE otp_challenges SET consumed_at = now() WHERE id = $1`, [challengeId]);
    throw new AppError(502, 'sms_failed', 'Could not send the OTP right now. Please try again.');
  }

  // The response is identical whether or not the number is already registered
  // (no account enumeration).
  return {
    challengeId,
    expiresInMs: cfg.otp.ttlMs,
    resendAfterMs: cfg.otp.resendCooldownMs,
    maskedPhone: `••••••${phone.slice(-4)}`,
  };
}

export async function verifyOtp(ctx, { challengeId, code, ip, userAgent }) {
  const { cfg, pool, limiter } = ctx;
  if (!/^[0-9a-f-]{36}$/i.test(String(challengeId))) throw badRequest('invalid_challenge', 'OTP request not found. Please request a new OTP.');
  if (!new RegExp(`^\\d{${cfg.otp.length}}$`).test(String(code))) throw badRequest('invalid_otp_format', `Enter the ${cfg.otp.length}-digit OTP`);

  await limiter.enforce(`otp:verify:ip:${ip}`, 100, HOUR, 'Too many verification attempts. Please try again later.');

  // Atomically count the attempt; refuses consumed/expired/exhausted challenges.
  const r = await pool.query(
    `UPDATE otp_challenges SET attempts = attempts + 1
      WHERE id = $1 AND consumed_at IS NULL AND expires_at > now() AND attempts < max_attempts
      RETURNING phone_hash, phone_enc, code_hash, attempts, max_attempts`,
    [challengeId],
  );
  if (!r.rowCount) {
    throw badRequest('otp_expired', 'This OTP has expired or is no longer valid. Please request a new OTP.');
  }
  const ch = r.rows[0];
  const phKey = ch.phone_hash.toString('hex');

  const failures = await limiter.peek(`otp:verifyfail:phone:${phKey}`, HOUR);
  if (failures >= cfg.otp.maxVerifyFailuresPerPhonePerHour) {
    throw tooMany('otp_locked', 'Too many incorrect OTP attempts. Please try again later.');
  }

  if (!timingSafeEqualBuf(otpHash(ctx, challengeId, ch.phone_hash, String(code)), ch.code_hash)) {
    await limiter.hit(`otp:verifyfail:phone:${phKey}`, cfg.otp.maxVerifyFailuresPerPhonePerHour, HOUR);
    const remaining = ch.max_attempts - ch.attempts;
    if (remaining <= 0) await pool.query(`UPDATE otp_challenges SET consumed_at = now() WHERE id = $1`, [challengeId]);
    throw badRequest('otp_incorrect', remaining > 0 ? 'Incorrect OTP.' : 'Incorrect OTP. Please request a new OTP.', { attemptsRemaining: remaining });
  }

  // Single use: only one concurrent verifier can consume the challenge.
  const consumed = await pool.query(
    `UPDATE otp_challenges SET consumed_at = now() WHERE id = $1 AND consumed_at IS NULL RETURNING id`, [challengeId]);
  if (!consumed.rowCount) throw badRequest('otp_expired', 'This OTP has already been used. Please request a new OTP.');

  const phone = decrypt(cfg.keys.phoneEnc, ch.phone_enc);
  const { user, isNew } = await findOrCreateUser(ctx, ch.phone_hash, phone);
  if (user.status !== 'active') {
    await audit(pool, { actorType: 'user', actorId: user.id, action: 'user.login_blocked_suspended', entityType: 'user', entityId: user.id, ipHash: ipHash(ctx, ip) });
    throw forbidden('account_suspended', 'This account has been suspended. Contact the organiser.');
  }
  const session = await createSession(ctx, 'user', user.id, cfg.session.userTtlMs, userAgent);
  await audit(pool, {
    actorType: 'user', actorId: user.id, action: isNew ? 'user.registered' : 'user.login',
    entityType: 'user', entityId: user.id, ipHash: ipHash(ctx, ip),
  });
  return { ...session, user: publicUser(user), isNew, profileComplete: Boolean(user.display_name) };
}

async function findOrCreateUser(ctx, ph, phone) {
  const { pool, cfg } = ctx;
  const existing = await pool.query(`SELECT * FROM users WHERE phone_hash = $1`, [ph]);
  if (existing.rowCount) return { user: existing.rows[0], isNew: false };
  for (let i = 0; i < 5; i++) {
    const ins = await pool.query(
      `INSERT INTO users (registration_id, phone_hash, phone_enc, phone_last4)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT DO NOTHING RETURNING *`,
      [friendlyId('QZ'), ph, encrypt(cfg.keys.phoneEnc, phone), phone.slice(-4)],
    );
    if (ins.rowCount) return { user: ins.rows[0], isNew: true };
    // Either a concurrent verify created the same phone (unique phone_hash)
    // or the random registration id collided: re-check and retry.
    const again = await pool.query(`SELECT * FROM users WHERE phone_hash = $1`, [ph]);
    if (again.rowCount) return { user: again.rows[0], isNew: false };
  }
  throw new Error('could not allocate registration id');
}

export function publicUser(u) {
  return {
    id: u.id,
    registrationId: u.registration_id,
    displayName: u.display_name,
    maskedPhone: `••••••${u.phone_last4}`,
    preferredLang: u.preferred_lang,
    status: u.status,
    registeredAt: u.created_at,
  };
}

// ---------------------------------------------------------------------------
// Sessions (opaque random tokens; only SHA-256(token) is stored)
// ---------------------------------------------------------------------------

const SESSION_CACHE_MS = 15_000;
const LAST_SEEN_WRITE_MS = 5 * 60_000;

export async function createSession(ctx, subjectType, subjectId, ttlMs, userAgent) {
  const token = randomToken(32);
  const expiresAt = new Date(clock.nowMs() + ttlMs);
  await ctx.pool.query(
    `INSERT INTO sessions (subject_type, subject_id, token_hash, user_agent, expires_at) VALUES ($1, $2, $3, $4, $5)`,
    [subjectType, subjectId, sha256(token), userAgent?.slice(0, 300) ?? null, expiresAt],
  );
  return { token, expiresAt };
}

/**
 * Resolves a bearer token to its subject. Results are cached per node for a
 * few seconds so that thousands of answer submissions do not each hit the
 * sessions table. Revocations propagate to other nodes within SESSION_CACHE_MS
 * (immediately on the node that handled the logout / suspension).
 */
export async function authenticate(ctx, token, subjectType) {
  if (!token || typeof token !== 'string' || token.length > 100) return null;
  const th = sha256(token);
  const key = th.toString('base64');
  const now = clock.nowMs();
  const cached = ctx.sessionCache.get(key);
  if (cached && cached.until > now) {
    return cached.value && cached.value.subjectType === subjectType ? cached.value : null;
  }
  const table = subjectType === 'admin' ? 'admin_users' : 'users';
  const r = await ctx.pool.query(
    `SELECT s.id AS session_id, s.subject_type, s.expires_at, s.last_seen_at, s.revoked_at, u.*
       FROM sessions s JOIN ${table} u ON u.id = s.subject_id
      WHERE s.token_hash = $1 AND s.subject_type = $2`,
    [th, subjectType],
  );
  let value = null;
  if (r.rowCount) {
    const row = r.rows[0];
    const idle = now - row.last_seen_at.getTime();
    const active = subjectType === 'admin' ? row.status === 'active' : row.status === 'active';
    if (!row.revoked_at && row.expires_at.getTime() > now && idle < ctx.cfg.session.idleTimeoutMs && active) {
      value = { subjectType, sessionId: row.session_id, subject: row };
      if (idle > LAST_SEEN_WRITE_MS) {
        ctx.pool.query(`UPDATE sessions SET last_seen_at = now() WHERE id = $1`, [row.session_id]).catch(() => {});
      }
    }
  }
  ctx.sessionCache.set(key, { value, until: now + SESSION_CACHE_MS });
  if (ctx.sessionCache.size > 50_000) ctx.sessionCache.delete(ctx.sessionCache.keys().next().value);
  return value;
}

export async function revokeSession(ctx, token) {
  if (!token) return;
  const th = sha256(token);
  ctx.sessionCache.delete(th.toString('base64'));
  await ctx.pool.query(`UPDATE sessions SET revoked_at = now() WHERE token_hash = $1 AND revoked_at IS NULL`, [th]);
}

export async function revokeAllSessions(ctx, subjectType, subjectId) {
  await ctx.pool.query(
    `UPDATE sessions SET revoked_at = now() WHERE subject_type = $1 AND subject_id = $2 AND revoked_at IS NULL`,
    [subjectType, subjectId],
  );
  for (const [k, v] of ctx.sessionCache) if (v.value?.subject?.id === subjectId) ctx.sessionCache.delete(k);
}

// ---------------------------------------------------------------------------
// Participant profile
// ---------------------------------------------------------------------------

export async function updateProfile(ctx, userId, { displayName, preferredLang }) {
  const sets = [];
  const vals = [userId];
  if (displayName !== undefined) {
    const name = String(displayName).normalize('NFC').replace(/\s+/g, ' ').trim();
    if (name.length < 2 || name.length > 60) throw badRequest('invalid_name', 'Name must be 2–60 characters');
    if (/[<>{}\\\u0000-\u001f]/.test(name)) throw badRequest('invalid_name', 'Name contains invalid characters');
    vals.push(name);
    sets.push(`display_name = $${vals.length}`);
  }
  if (preferredLang !== undefined) {
    if (!['en', 'kn'].includes(preferredLang)) throw badRequest('invalid_lang', 'Unsupported language');
    vals.push(preferredLang);
    sets.push(`preferred_lang = $${vals.length}`);
  }
  if (!sets.length) throw badRequest('nothing_to_update', 'Nothing to update');
  const r = await ctx.pool.query(
    `UPDATE users SET ${sets.join(', ')}, updated_at = now() WHERE id = $1 RETURNING *`, vals);
  for (const [, v] of ctx.sessionCache) if (v.value?.subject?.id === userId) v.until = 0;
  return publicUser(r.rows[0]);
}

// ---------------------------------------------------------------------------
// Administrators
// ---------------------------------------------------------------------------

export const ROLE_PERMISSIONS = {
  super_admin: ['view', 'questions.read', 'competitions.write', 'results.publish', 'export', 'users.suspend', 'audit.read', 'admins.manage'],
  admin: ['view', 'questions.read', 'competitions.write', 'results.publish', 'export', 'users.suspend', 'audit.read'],
  moderator: ['view', 'users.suspend', 'audit.read'],
  viewer: ['view'],
};

export const hasPermission = (role, perm) => (ROLE_PERMISSIONS[role] ?? []).includes(perm);

const DUMMY_HASH = 'scrypt$16384$8$1$AAAAAAAAAAAAAAAAAAAAAA==$' + Buffer.alloc(64).toString('base64');

export async function adminLogin(ctx, { email, password, ip, userAgent }) {
  const { pool, cfg, limiter } = ctx;
  await limiter.enforce(`admin:login:ip:${ip}`, cfg.rateLimit.adminLoginPerIpPer15Min, 15 * 60_000,
    'Too many login attempts. Please wait 15 minutes.');
  if (typeof email !== 'string' || typeof password !== 'string' || password.length > 200) {
    throw unauthorized('invalid_credentials', 'Invalid email or password');
  }
  const r = await pool.query(`SELECT * FROM admin_users WHERE lower(email) = lower($1)`, [email.trim()]);
  const admin = r.rows[0];
  // Always run scrypt so response time does not reveal whether the email exists.
  const ok = await verifyPassword(password, admin?.password_hash ?? DUMMY_HASH);
  if (!admin || !ok || admin.status !== 'active') {
    await audit(pool, { actorType: 'system', action: 'admin.login_failed', entityType: 'admin', entityId: admin?.id ?? null, metadata: { email: email.slice(0, 200) }, ipHash: ipHash(ctx, ip) });
    throw unauthorized('invalid_credentials', 'Invalid email or password');
  }
  await pool.query(`UPDATE admin_users SET last_login_at = now() WHERE id = $1`, [admin.id]);
  const session = await createSession(ctx, 'admin', admin.id, cfg.session.adminTtlMs, userAgent);
  await audit(pool, { actorType: 'admin', actorId: admin.id, action: 'admin.login', entityType: 'admin', entityId: admin.id, ipHash: ipHash(ctx, ip) });
  return { ...session, admin: publicAdmin(admin) };
}

export function publicAdmin(a) {
  return { id: a.id, email: a.email, name: a.name, role: a.role, status: a.status, permissions: ROLE_PERMISSIONS[a.role] ?? [], lastLoginAt: a.last_login_at };
}

export async function createAdmin(ctx, { email, name, password, role }, actor) {
  if (!ROLE_PERMISSIONS[role]) throw badRequest('invalid_role', 'Invalid role');
  if (typeof password !== 'string' || password.length < 12) throw badRequest('weak_password', 'Password must be at least 12 characters');
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(String(email))) throw badRequest('invalid_email', 'Invalid email');
  const r = await ctx.pool.query(
    `INSERT INTO admin_users (email, name, password_hash, role) VALUES ($1, $2, $3, $4)
     ON CONFLICT DO NOTHING RETURNING *`,
    [email.trim(), String(name).trim().slice(0, 100), await hashPassword(password), role],
  );
  if (!r.rowCount) throw new AppError(409, 'admin_exists', 'An administrator with this email already exists');
  await audit(ctx.pool, { actorType: actor ? 'admin' : 'system', actorId: actor?.id ?? null, action: 'admin.created', entityType: 'admin', entityId: r.rows[0].id, metadata: { role } });
  return publicAdmin(r.rows[0]);
}
