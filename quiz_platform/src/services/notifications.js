// Notification outbox. In-app notifications are always recorded; SMS copies
// are only sent when both the deployment (NOTIFICATIONS_SMS_ENABLED) and the
// competition (notify_sms) allow it. A background worker drains the outbox in
// small batches so notification bursts never compete with live quiz traffic.
import { decrypt } from '../lib/security.js';

export async function enqueueNotification(db, { userId, competitionId = null, kind, body, sms = false, dedupe }) {
  const base = dedupe ?? `${competitionId ?? 'none'}:${kind}:${userId}`;
  await db.query(
    `INSERT INTO notifications (user_id, competition_id, kind, channel, body, dedupe_key)
     VALUES ($1, $2, $3, 'in_app', $4, $5)
     ON CONFLICT (dedupe_key) DO NOTHING`,
    [userId, competitionId, kind, body, `${base}:in_app`],
  );
  if (sms) {
    await db.query(
      `INSERT INTO notifications (user_id, competition_id, kind, channel, body, dedupe_key)
       VALUES ($1, $2, $3, 'sms', $4, $5)
       ON CONFLICT (dedupe_key) DO NOTHING`,
      [userId, competitionId, kind, body, `${base}:sms`],
    );
  }
}

export async function listNotifications(db, userId, limit = 30) {
  const r = await db.query(
    `SELECT id, competition_id, kind, body, created_at, read_at FROM notifications
      WHERE user_id = $1 AND channel = 'in_app' ORDER BY created_at DESC LIMIT $2`,
    [userId, limit],
  );
  return r.rows.map((n) => ({ id: n.id, competitionId: n.competition_id, kind: n.kind, body: n.body, createdAt: n.created_at, read: Boolean(n.read_at) }));
}

export async function markNotificationsRead(db, userId) {
  await db.query(`UPDATE notifications SET read_at = now() WHERE user_id = $1 AND channel = 'in_app' AND read_at IS NULL`, [userId]);
}

/** Sends one batch of pending SMS notifications. Returns the number processed. */
export async function drainSmsOutbox(ctx) {
  const { pool, cfg } = ctx;
  const batch = await pool.query(
    `UPDATE notifications n SET attempts = attempts + 1
      WHERE n.id IN (
        SELECT id FROM notifications WHERE status = 'pending' AND channel = 'sms'
         ORDER BY created_at LIMIT $1 FOR UPDATE SKIP LOCKED)
      RETURNING n.id, n.user_id, n.body, n.attempts`,
    [cfg.notifications.smsBatchSize],
  );
  for (const n of batch.rows) {
    if (!cfg.notifications.smsEnabled) {
      await pool.query(`UPDATE notifications SET status = 'skipped' WHERE id = $1`, [n.id]);
      continue;
    }
    try {
      const u = await pool.query(`SELECT phone_enc, status FROM users WHERE id = $1`, [n.user_id]);
      if (!u.rowCount || u.rows[0].status !== 'active') {
        await pool.query(`UPDATE notifications SET status = 'skipped' WHERE id = $1`, [n.id]);
        continue;
      }
      await ctx.sms.sendText(decrypt(cfg.keys.phoneEnc, u.rows[0].phone_enc), n.body);
      await pool.query(`UPDATE notifications SET status = 'sent', sent_at = now() WHERE id = $1`, [n.id]);
    } catch (err) {
      ctx.log.warn({ err: err.message, id: n.id }, 'sms notification failed');
      await pool.query(`UPDATE notifications SET status = CASE WHEN attempts >= 3 THEN 'failed' ELSE 'pending' END WHERE id = $1`, [n.id]);
    }
  }
  return batch.rowCount;
}
