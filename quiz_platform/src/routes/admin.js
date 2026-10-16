// Administrator API. Every route requires an authenticated admin session and
// an explicit permission (role-based access control).
import { forbidden, unauthorized, badRequest } from '../lib/errors.js';
import { parseCsv } from '../lib/csv.js';
import { adminLogin, authenticate, createAdmin, hasPermission, publicAdmin, revokeSession } from '../services/auth.js';
import {
  adminCompetition, adminQuestion, cancelCompetition, createCompetition, deleteCompetition, deleteQuestion,
  getCompetition, importQuestions, listQuestions, rowsFromCsv, scheduleCompetition, unscheduleCompetition,
  updateCompetition, upsertQuestion,
} from '../services/competitions.js';
import {
  auditLogs, competitionReport, exportResults, listParticipants, liveStats, searchUsers, setUserSuspended,
  suspiciousActivity, systemHealth,
} from '../services/reports.js';
import { leaderboard, publishResults } from '../services/results.js';
import { audit } from '../services/audit.js';

const COOKIE = 'qadm';
const uuid = { type: 'string', pattern: '^[0-9a-fA-F-]{36}$' };
const idParam = { type: 'object', required: ['id'], properties: { id: uuid } };

function tokenFrom(req) {
  const h = req.headers.authorization;
  if (h && h.startsWith('Bearer ')) return h.slice(7).trim();
  return req.cookies?.[COOKIE];
}

const competitionBody = {
  type: 'object',
  additionalProperties: false,
  properties: {
    title: { type: 'string', maxLength: 200 },
    description: { type: 'string', maxLength: 10000 },
    rules: { type: 'string', maxLength: 10000 },
    startAt: { type: 'string', maxLength: 40 },
    registrationOpensAt: { type: 'string', maxLength: 40 },
    registrationClosesAt: { type: 'string', maxLength: 40 },
    questionCount: { type: 'integer' },
    questionTimeMs: { type: 'integer' },
    transitionMs: { type: 'integer' },
    defaultMarks: { type: 'integer' },
    visibility: { type: 'string', enum: ['public', 'restricted'] },
    accessCode: { type: 'string', maxLength: 64 },
    lateEntryAllowed: { type: 'boolean' },
    revealAnswers: { type: 'boolean' },
    showProvisional: { type: 'boolean' },
    notifySms: { type: 'boolean' },
    branding: { type: 'object' },
  },
};

const questionBody = {
  type: 'object',
  additionalProperties: false,
  required: ['text', 'optionA', 'optionB', 'optionC', 'optionD', 'correctOption'],
  properties: {
    position: { type: 'integer', minimum: 1, maximum: 15 },
    text: { type: 'string', maxLength: 2000 },
    optionA: { type: 'string', maxLength: 500 },
    optionB: { type: 'string', maxLength: 500 },
    optionC: { type: 'string', maxLength: 500 },
    optionD: { type: 'string', maxLength: 500 },
    correctOption: { type: 'string', enum: ['A', 'B', 'C', 'D', 'a', 'b', 'c', 'd'] },
    marks: { type: 'integer', minimum: 0, maximum: 100 },
    imageUrl: { type: ['string', 'null'], maxLength: 500 },
    category: { type: ['string', 'null'], maxLength: 100 },
  },
};

export async function adminRoutes(app) {
  const { ctx } = app;
  const { cfg } = ctx;

  const requireAdmin = (perm) => async (req) => {
    const s = await authenticate(ctx, tokenFrom(req), 'admin');
    if (!s) throw unauthorized('unauthorized', 'Administrator login required');
    req.admin = s.subject;
    if (perm && !hasPermission(req.admin.role, perm)) throw forbidden('forbidden', 'Your role does not allow this action');
  };

  // ---- auth --------------------------------------------------------------------
  app.post('/auth/login', {
    schema: {
      body: {
        type: 'object', required: ['email', 'password'], additionalProperties: false,
        properties: { email: { type: 'string', maxLength: 200 }, password: { type: 'string', maxLength: 200 } },
      },
    },
  }, async (req, reply) => {
    const r = await adminLogin(ctx, { ...req.body, ip: req.ip, userAgent: req.headers['user-agent'] });
    reply.setCookie(COOKIE, r.token, { httpOnly: true, sameSite: 'strict', secure: cfg.session.cookieSecure, path: '/api/admin', expires: r.expiresAt });
    return { admin: r.admin, expiresAt: r.expiresAt };
  });

  app.post('/auth/logout', async (req, reply) => {
    await revokeSession(ctx, tokenFrom(req));
    reply.clearCookie(COOKIE, { path: '/api/admin' });
    return { ok: true };
  });

  app.get('/me', { preHandler: requireAdmin() }, async (req) => ({ admin: publicAdmin(req.admin) }));

  // ---- administrators ------------------------------------------------------------
  app.get('/admins', { preHandler: requireAdmin('admins.manage') }, async () => {
    const r = await ctx.pool.query(`SELECT * FROM admin_users ORDER BY created_at`);
    return { admins: r.rows.map(publicAdmin) };
  });
  app.post('/admins', {
    preHandler: requireAdmin('admins.manage'),
    schema: {
      body: {
        type: 'object', required: ['email', 'name', 'password', 'role'], additionalProperties: false,
        properties: { email: { type: 'string', maxLength: 200 }, name: { type: 'string', maxLength: 100 }, password: { type: 'string', maxLength: 200 }, role: { type: 'string' } },
      },
    },
  }, async (req) => ({ admin: await createAdmin(ctx, req.body, req.admin) }));
  app.post('/admins/:id/status', {
    preHandler: requireAdmin('admins.manage'),
    schema: { params: idParam, body: { type: 'object', required: ['status'], properties: { status: { type: 'string', enum: ['active', 'disabled'] } } } },
  }, async (req) => {
    if (req.params.id === req.admin.id) throw badRequest('self', 'You cannot change your own status');
    await ctx.pool.query(`UPDATE admin_users SET status = $2 WHERE id = $1`, [req.params.id, req.body.status]);
    if (req.body.status === 'disabled') {
      await ctx.pool.query(`UPDATE sessions SET revoked_at = now() WHERE subject_type = 'admin' AND subject_id = $1 AND revoked_at IS NULL`, [req.params.id]);
    }
    await audit(ctx.pool, { actorType: 'admin', actorId: req.admin.id, action: `admin.${req.body.status}`, entityType: 'admin', entityId: req.params.id });
    return { ok: true };
  });

  // ---- competitions --------------------------------------------------------------
  app.get('/competitions', { preHandler: requireAdmin('view') }, async () => {
    const r = await ctx.pool.query(
      `SELECT c.*,
              (SELECT count(*) FROM competition_participants p WHERE p.competition_id = c.id) AS participant_count,
              (SELECT count(*) FROM questions q WHERE q.competition_id = c.id) AS question_total
         FROM competitions c ORDER BY c.start_at DESC LIMIT 500`);
    return { competitions: r.rows.map(adminCompetition) };
  });

  app.post('/competitions', { preHandler: requireAdmin('competitions.write'), schema: { body: competitionBody } },
    async (req) => ({ competition: adminCompetition(await createCompetition(ctx, req.body, req.admin)) }));

  app.get('/competitions/:id', { preHandler: requireAdmin('view'), schema: { params: idParam } }, async (req) => {
    const c = await getCompetition(ctx.pool, req.params.id);
    const n = await ctx.pool.query(`SELECT count(*) AS n FROM competition_participants WHERE competition_id = $1`, [c.id]);
    const qs = await listQuestions(ctx.pool, c.id);
    const canSeeKey = hasPermission(req.admin.role, 'questions.read');
    return {
      competition: adminCompetition({ ...c, participant_count: n.rows[0].n, question_total: qs.length }),
      questions: qs.map((q) => {
        const out = adminQuestion(q);
        if (!canSeeKey) delete out.correctOption;
        return out;
      }),
    };
  });

  app.patch('/competitions/:id', { preHandler: requireAdmin('competitions.write'), schema: { params: idParam, body: competitionBody } },
    async (req) => ({ competition: adminCompetition(await updateCompetition(ctx, req.params.id, req.body, req.admin)) }));

  app.delete('/competitions/:id', { preHandler: requireAdmin('competitions.write'), schema: { params: idParam } }, async (req) => {
    await deleteCompetition(ctx, req.params.id, req.admin);
    return { ok: true };
  });

  app.post('/competitions/:id/schedule', { preHandler: requireAdmin('competitions.write'), schema: { params: idParam } }, async (req) => {
    const c = await scheduleCompetition(ctx, req.params.id, req.admin);
    await ctx.cache.invalidate('public-competitions');
    return { competition: adminCompetition(c) };
  });
  app.post('/competitions/:id/unschedule', { preHandler: requireAdmin('competitions.write'), schema: { params: idParam } }, async (req) => {
    const c = await unscheduleCompetition(ctx, req.params.id, req.admin);
    await ctx.cache.invalidate('public-competitions');
    return { competition: adminCompetition(c) };
  });
  app.post('/competitions/:id/cancel', {
    preHandler: requireAdmin('competitions.write'),
    schema: { params: idParam, body: { type: 'object', required: ['reason'], properties: { reason: { type: 'string', maxLength: 500 } } } },
  }, async (req) => {
    const c = await cancelCompetition(ctx, req.params.id, req.body.reason, req.admin);
    await ctx.cache.invalidate('public-competitions');
    return { competition: adminCompetition(c) };
  });
  app.post('/competitions/:id/publish', { preHandler: requireAdmin('results.publish'), schema: { params: idParam } }, async (req) => {
    const c = await publishResults(ctx, req.params.id, req.admin);
    await ctx.cache.invalidate('public-competitions');
    return { competition: adminCompetition(c) };
  });

  // ---- questions -----------------------------------------------------------------
  app.put('/competitions/:id/questions/:position', {
    preHandler: requireAdmin('competitions.write'),
    schema: {
      params: { type: 'object', properties: { id: uuid, position: { type: 'integer', minimum: 1, maximum: 15 } } },
      body: questionBody,
    },
  }, async (req) => ({ question: adminQuestion(await upsertQuestion(ctx, req.params.id, { ...req.body, position: req.params.position }, req.admin)) }));

  app.delete('/competitions/:id/questions/:position', {
    preHandler: requireAdmin('competitions.write'),
    schema: { params: { type: 'object', properties: { id: uuid, position: { type: 'integer', minimum: 1, maximum: 15 } } } },
  }, async (req) => {
    await deleteQuestion(ctx, req.params.id, req.params.position, req.admin);
    return { ok: true };
  });

  app.post('/competitions/:id/questions/import', {
    preHandler: requireAdmin('competitions.write'),
    schema: {
      params: idParam,
      body: {
        type: 'object', additionalProperties: false,
        properties: { questions: { type: 'array', maxItems: 15, items: { type: 'object' } }, csv: { type: 'string', maxLength: 200000 } },
      },
    },
  }, async (req) => {
    const items = req.body.csv ? rowsFromCsv(parseCsv(req.body.csv)) : req.body.questions;
    const qs = await importQuestions(ctx, req.params.id, items, req.admin);
    return { questions: qs.map(adminQuestion) };
  });

  // ---- participants, monitoring, results ----------------------------------------------
  app.get('/competitions/:id/participants', {
    preHandler: requireAdmin('view'),
    schema: { params: idParam, querystring: { type: 'object', properties: { q: { type: 'string', maxLength: 60 }, page: { type: 'integer', minimum: 1 }, pageSize: { type: 'integer', minimum: 1, maximum: 200 } } } },
  }, async (req) => listParticipants(ctx, req.params.id, req.query));

  app.get('/competitions/:id/live', { preHandler: requireAdmin('view'), schema: { params: idParam } }, async (req) => liveStats(ctx, req.params.id));
  app.get('/competitions/:id/report', { preHandler: requireAdmin('view'), schema: { params: idParam } }, async (req) => competitionReport(ctx, req.params.id));
  app.get('/competitions/:id/suspicious', { preHandler: requireAdmin('users.suspend'), schema: { params: idParam } }, async (req) => suspiciousActivity(ctx, req.params.id));
  app.get('/competitions/:id/leaderboard', {
    preHandler: requireAdmin('view'),
    schema: { params: idParam, querystring: { type: 'object', properties: { limit: { type: 'integer', minimum: 1, maximum: 100 }, page: { type: 'integer', minimum: 1 }, q: { type: 'string', maxLength: 60 } } } },
  }, async (req) => leaderboard(ctx, req.params.id, req.query, { admin: true }));

  app.get('/competitions/:id/export', {
    preHandler: requireAdmin('export'),
    schema: { params: idParam, querystring: { type: 'object', properties: { format: { type: 'string', enum: ['csv', 'xlsx'] }, includePhone: { type: 'boolean' } } } },
  }, async (req, reply) => {
    const includePhone = Boolean(req.query.includePhone) && req.admin.role === 'super_admin';
    const f = await exportResults(ctx, req.params.id, req.query.format ?? 'csv', req.admin, { includePhone });
    reply.header('Content-Type', f.contentType);
    reply.header('Content-Disposition', `attachment; filename="${f.filename}"`);
    return reply.send(f.body);
  });

  // ---- users --------------------------------------------------------------------
  app.get('/users', {
    preHandler: requireAdmin('view'),
    schema: { querystring: { type: 'object', properties: { q: { type: 'string', maxLength: 60 }, page: { type: 'integer', minimum: 1 } } } },
  }, async (req) => searchUsers(ctx, req.query));

  app.post('/users/:id/suspend', {
    preHandler: requireAdmin('users.suspend'),
    schema: { params: idParam, body: { type: 'object', required: ['reason'], properties: { reason: { type: 'string', maxLength: 500 } } } },
  }, async (req) => setUserSuspended(ctx, req.params.id, true, req.body.reason, req.admin));

  app.post('/users/:id/reinstate', { preHandler: requireAdmin('users.suspend'), schema: { params: idParam } },
    async (req) => setUserSuspended(ctx, req.params.id, false, null, req.admin));

  // ---- audit + health -------------------------------------------------------------
  app.get('/audit', {
    preHandler: requireAdmin('audit.read'),
    schema: { querystring: { type: 'object', properties: { entityType: { type: 'string', maxLength: 40 }, entityId: { type: 'string', maxLength: 64 }, action: { type: 'string', maxLength: 60 }, page: { type: 'integer', minimum: 1 } } } },
  }, async (req) => ({ logs: await auditLogs(ctx, req.query) }));

  app.get('/health', { preHandler: requireAdmin('view') }, async () => systemHealth(ctx));
}
