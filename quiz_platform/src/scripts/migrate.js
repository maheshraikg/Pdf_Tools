// Applies SQL migrations in order. Each migration runs in its own transaction
// and is recorded in schema_migrations; an advisory lock prevents concurrent runs.
import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import pg from 'pg';

const dir = path.join(path.dirname(fileURLToPath(import.meta.url)), '..', '..', 'migrations');

export async function migrate(pool, log = console) {
  const client = await pool.connect();
  try {
    await client.query('SELECT pg_advisory_lock(7310000)');
    await client.query(`CREATE TABLE IF NOT EXISTS schema_migrations (name text PRIMARY KEY, applied_at timestamptz NOT NULL DEFAULT now())`);
    const done = new Set((await client.query('SELECT name FROM schema_migrations')).rows.map((r) => r.name));
    const files = (await fs.readdir(dir)).filter((f) => f.endsWith('.sql')).sort();
    for (const f of files) {
      if (done.has(f)) continue;
      const sql = await fs.readFile(path.join(dir, f), 'utf8');
      await client.query('BEGIN');
      try {
        await client.query(sql);
        await client.query('INSERT INTO schema_migrations (name) VALUES ($1)', [f]);
        await client.query('COMMIT');
        log.info?.(`applied migration ${f}`);
      } catch (err) {
        await client.query('ROLLBACK');
        throw new Error(`migration ${f} failed: ${err.message}`);
      }
    }
  } finally {
    await client.query('SELECT pg_advisory_unlock(7310000)').catch(() => {});
    client.release();
  }
}

if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  const pool = new pg.Pool({ connectionString: process.env.DATABASE_URL ?? 'postgres://postgres@localhost:5432/quiz' });
  migrate(pool).then(() => pool.end()).catch((err) => { console.error(err.message); process.exit(1); });
}
