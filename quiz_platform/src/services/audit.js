import { hmac } from '../lib/security.js';

export function ipHash(ctx, ip) {
  return ip ? hmac(ctx.cfg.keys.ip, ip) : null;
}

/** Appends an audit record. `db` may be a pool or a transaction client. */
export async function audit(db, { actorType, actorId = null, action, entityType = null, entityId = null, metadata = {}, ipHash = null }) {
  await db.query(
    `INSERT INTO audit_logs (actor_type, actor_id, action, entity_type, entity_id, metadata, ip_hash)
     VALUES ($1, $2, $3, $4, $5, $6, $7)`,
    [actorType, actorId, action, entityType, entityId == null ? null : String(entityId), metadata, ipHash],
  );
}
