import { buildApp } from './app.js';
import { loadConfig } from './config.js';
import { migrate } from './scripts/migrate.js';

const cfg = loadConfig();
const app = await buildApp({ config: cfg });

if (process.env.MIGRATE_ON_START === 'true') await migrate(app.ctx.pool, app.log);
if (cfg.jobs.enabled) app.ctx.lifecycle.start();

const shutdown = async (signal) => {
  app.log.info({ signal }, 'shutting down');
  // Stop accepting new connections; in-flight requests complete. Answer
  // deadlines are absolute, so clients reconnecting to another node lose no time.
  try {
    await app.close();
    process.exit(0);
  } catch (err) {
    app.log.error({ err }, 'error during shutdown');
    process.exit(1);
  }
};
process.on('SIGTERM', shutdown);
process.on('SIGINT', shutdown);

await app.listen({ host: cfg.host, port: cfg.port });
