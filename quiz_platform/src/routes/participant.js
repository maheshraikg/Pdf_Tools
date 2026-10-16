// Participant-facing API + WebSocket endpoint.
import { clock } from '../lib/clock.js';
import { forbidden, unauthorized, notFound } from '../lib/errors.js';
import { encrypt, friendlyId, hmac } from '../lib/security.js';
import {
  authenticate, createSession, publicUser, requestOtp, revokeSession, updateProfile, verifyOtp,
} from '../services/auth.js';
import { getCompetition, publicCompetition, registerForCompetition } from '../services/competitions.js';
import { listNotifications, markNotificationsRead } from '../services/notifications.js';
import { competitionHistory, leaderboard, myResult, publicParticipantResult } from '../services/results.js';

const COOKIE = 'qsid';

function tokenFrom(req, cookieName) {
  const h = req.headers.authorization;
  if (h && h.startsWith('Bearer ')) return h.slice(7).trim();
  return req.cookies?.[cookieName];
}

const idParam = {
  type: 'object',
  required: ['id'],
  properties: { id: { type: 'string', pattern: '^[0-9a-fA-F-]{36}$' } },
};

export async function participantRoutes(app) {
  const { ctx } = app;
  const { cfg } = ctx;

  async function requireUser(req) {
    const s = await authenticate(ctx, tokenFrom(req, COOKIE), 'user');
    if (!s) throw unauthorized('unauthorized', 'Please log in');
    req.user = s.subject;
  }
  async function optionalUser(req) {
    const s = await authenticate(ctx, tokenFrom(req, COOKIE), 'user');
    req.user = s?.subject ?? null;
  }

  const setSessionCookie = (reply, token, expiresAt) => reply.setCookie(COOKIE, token, {
    httpOnly: true, sameSite: 'strict', secure: cfg.session.cookieSecure, path: '/', expires: expiresAt,
  });

  app.get('/time', async () => ({ serverNow: clock.now() }));

  // ---- authentication ------------------------------------------------------------
  app.post('/auth/otp/request', {
    schema: { body: { type: 'object', required: ['phone'], additionalProperties: false, properties: { phone: { type: 'string', maxLength: 25 } } } },
  }, async (req) => requestOtp(ctx, { phone: req.body.phone, ip: req.ip }));

  app.post('/auth/otp/verify', {
    schema: {
      body: {
        type: 'object', required: ['challengeId', 'code'], additionalProperties: false,
        properties: { challengeId: { type: 'string', maxLength: 64 }, code: { type: 'string', maxLength: 10 } },
      },
    },
  }, async (req, reply) => {
    const r = await verifyOtp(ctx, { ...req.body, ip: req.ip, userAgent: req.headers['user-agent'] });
    setSessionCookie(reply, r.token, r.expiresAt);
    // The token is also returned for native/non-browser clients; browsers rely on the HttpOnly cookie.
    return { user: r.user, isNew: r.isNew, profileComplete: r.profileComplete, token: r.token, expiresAt: r.expiresAt };
  });

  app.post('/auth/logout', async (req, reply) => {
    await revokeSession(ctx, tokenFrom(req, COOKIE));
    reply.clearCookie(COOKIE, { path: '/' });
    return { ok: true };
  });

  // Load-test helper: issues a session without SMS. Disabled unless
  // LOAD_TEST_SECRET is set, and always disabled when NODE_ENV=production.
  app.post('/loadtest/session', async (req) => {
    if (!cfg.loadTestSecret || cfg.isProd || req.headers['x-load-test-secret'] !== cfg.loadTestSecret) throw notFound();
    const n = String(req.body?.n ?? Math.floor(Math.random() * 1e9));
    const phone = `9199${n.padStart(8, '0').slice(-8)}`;
    const ph = hmac(cfg.keys.phoneHash, phone);
    const u = await ctx.pool.query(
      `INSERT INTO users (registration_id, phone_hash, phone_enc, phone_last4, display_name)
       VALUES ($1, $2, $3, $4, $5)
       ON CONFLICT (phone_hash) DO UPDATE SET updated_at = now() RETURNING *`,
      [friendlyId('LT', 8), ph, encrypt(cfg.keys.phoneEnc, phone), phone.slice(-4), `Load Tester ${n}`]);
    const s = await createSession(ctx, 'user', u.rows[0].id, cfg.session.userTtlMs, 'loadtest');
    return { token: s.token, user: publicUser(u.rows[0]) };
  });

  // ---- profile ---------------------------------------------------------------
  app.get('/me', { preHandler: requireUser }, async (req) => ({ user: publicUser(req.user), profileComplete: Boolean(req.user.display_name) }));

  app.patch('/me', {
    preHandler: requireUser,
    schema: {
      body: {
        type: 'object', additionalProperties: false,
        properties: { displayName: { type: 'string', maxLength: 80 }, preferredLang: { type: 'string', enum: ['en', 'kn'] } },
      },
    },
  }, async (req) => ({ user: await updateProfile(ctx, req.user.id, req.body ?? {}) }));

  app.get('/me/history', { preHandler: requireUser }, async (req) => ({ competitions: await competitionHistory(ctx, req.user.id) }));
  app.get('/me/notifications', { preHandler: requireUser }, async (req) => ({ notifications: await listNotifications(ctx.pool, req.user.id) }));
  app.post('/me/notifications/read', { preHandler: requireUser }, async (req) => {
    await markNotificationsRead(ctx.pool, req.user.id);
    return { ok: true };
  });

  // ---- competitions ---------------------------------------------------------------
  app.get('/competitions', { preHandler: optionalUser }, async (req) => {
    const list = await ctx.cache.get('public-competitions', 5000, async () => {
      const r = await ctx.pool.query(
        `SELECT c.*, (SELECT count(*) FROM competition_participants p WHERE p.competition_id = c.id) AS participant_count
           FROM competitions c
          WHERE c.status IN ('scheduled', 'live', 'completed', 'cancelled')
            AND (c.status <> 'completed' OR c.start_at > now() - interval '60 days')
            AND (c.status <> 'cancelled' OR c.start_at > now() - interval '7 days')
          ORDER BY c.start_at DESC LIMIT 100`);
      return r.rows.map((c) => publicCompetition(c));
    });
    let mine = new Set();
    if (req.user) {
      const r = await ctx.pool.query(`SELECT competition_id FROM competition_participants WHERE user_id = $1`, [req.user.id]);
      mine = new Set(r.rows.map((x) => x.competition_id));
    }
    return { competitions: list.map((c) => ({ ...c, registered: mine.has(c.id) })) };
  });

  app.get('/competitions/:id', { schema: { params: idParam }, preHandler: optionalUser }, async (req) => {
    const c = await getCompetition(ctx.pool, req.params.id);
    if (c.status === 'draft') throw notFound('competition_not_found', 'Competition not found');
    const n = await ctx.pool.query(`SELECT count(*) AS n FROM competition_participants WHERE competition_id = $1`, [c.id]);
    let registered = false;
    if (req.user) {
      const r = await ctx.pool.query(`SELECT 1 FROM competition_participants WHERE competition_id = $1 AND user_id = $2`, [c.id, req.user.id]);
      registered = r.rowCount > 0;
    }
    return { competition: publicCompetition({ ...c, participant_count: n.rows[0].n }, { registered }), serverNow: clock.now() };
  });

  app.post('/competitions/:id/register', {
    schema: { params: idParam, body: { type: ['object', 'null'], additionalProperties: false, properties: { accessCode: { type: 'string', maxLength: 64 } } } },
    preHandler: requireUser,
  }, async (req) => {
    const r = await registerForCompetition(ctx, req.user, req.params.id, req.body?.accessCode);
    await ctx.cache.invalidate('public-competitions');
    return { registered: true, alreadyRegistered: r.alreadyRegistered, registeredAt: r.participant.registered_at };
  });

  app.get('/competitions/:id/state', { schema: { params: idParam }, preHandler: requireUser }, async (req) => {
    const c = await ctx.engine.competition(req.params.id);
    if (c.status === 'draft') throw notFound('competition_not_found', 'Competition not found');
    return ctx.engine.state(req.user, req.params.id);
  });

  app.post('/competitions/:id/answers', {
    schema: {
      params: idParam,
      body: {
        type: 'object', required: ['questionId', 'option'], additionalProperties: false,
        properties: {
          questionId: { type: 'string', pattern: '^[0-9a-fA-F-]{36}$' },
          option: { type: 'string', enum: ['A', 'B', 'C', 'D'] },
          idempotencyKey: { type: 'string', maxLength: 100 },
        },
      },
    },
    preHandler: requireUser,
  }, async (req) => ctx.engine.submit(req.user, req.params.id, req.body, req.ip));

  const lbQuery = {
    type: 'object',
    properties: {
      limit: { type: 'integer', minimum: 1, maximum: 100 },
      page: { type: 'integer', minimum: 1, maximum: 100000 },
      q: { type: 'string', maxLength: 60 },
    },
  };
  app.get('/competitions/:id/leaderboard', { schema: { params: idParam, querystring: lbQuery } },
    async (req) => leaderboard(ctx, req.params.id, req.query));

  app.get('/competitions/:id/results/:registrationId', {
    schema: { params: { type: 'object', properties: { id: idParam.properties.id, registrationId: { type: 'string', maxLength: 20 } } } },
  }, async (req) => publicParticipantResult(ctx, req.params.id, req.params.registrationId));

  app.get('/competitions/:id/my-result', { schema: { params: idParam }, preHandler: requireUser },
    async (req) => myResult(ctx, req.user, req.params.id));

  // ---- WebSocket ------------------------------------------------------------------
  app.get('/ws', { websocket: true }, async (socket, req) => {
    const s = await authenticate(ctx, tokenFrom(req, COOKIE), 'user').catch(() => null);
    if (!s) {
      socket.close(4001, 'unauthorized');
      return;
    }
    if (s.subject.status !== 'active') throw forbidden();
    ctx.hub.attach(socket, s.subject);
  });
}
