import pg from 'pg';

// Return bigint (int8) columns as JS numbers: all our bigints (summed
// millisecond durations, microsecond epochs) are well within 2^53.
pg.types.setTypeParser(20, (v) => Number(v));

export function createPool(cfg) {
  const pool = new pg.Pool({
    connectionString: cfg.databaseUrl,
    max: cfg.dbPoolMax,
    idleTimeoutMillis: 30_000,
    connectionTimeoutMillis: 5_000,
    statement_timeout: 15_000,
    application_name: `quiz-${cfg.nodeId}`,
  });
  pool.on('error', (err) => {
    // Idle client errors (e.g. DB restart) must not crash the process.
    console.error('pg pool error', err.message);
  });
  return pool;
}

/** Runs fn(client) in a transaction, retrying on serialization failures/deadlocks. */
export async function tx(pool, fn, { retries = 3, isolation } = {}) {
  for (let attempt = 0; ; attempt++) {
    const client = await pool.connect();
    try {
      await client.query(isolation ? `BEGIN ISOLATION LEVEL ${isolation}` : 'BEGIN');
      const result = await fn(client);
      await client.query('COMMIT');
      return result;
    } catch (err) {
      await client.query('ROLLBACK').catch(() => {});
      if (attempt < retries && (err.code === '40001' || err.code === '40P01')) continue;
      throw err;
    } finally {
      client.release();
    }
  }
}
