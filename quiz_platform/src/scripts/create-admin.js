// Usage: node src/scripts/create-admin.js <email> <name> <role>
// The password is read from ADMIN_PASSWORD (never pass secrets as CLI args).
import { loadConfig } from '../config.js';
import { createPool } from '../lib/db.js';
import { createAdmin } from '../services/auth.js';

const [email, name, role = 'super_admin'] = process.argv.slice(2);
const password = process.env.ADMIN_PASSWORD;
if (!email || !name || !password) {
  console.error('Usage: ADMIN_PASSWORD=... node src/scripts/create-admin.js <email> <name> [super_admin|admin|moderator|viewer]');
  process.exit(1);
}
const cfg = loadConfig();
const pool = createPool(cfg);
try {
  const a = await createAdmin({ cfg, pool, log: console }, { email, name, password, role }, null);
  console.log(`created ${a.role} ${a.email}`);
} catch (err) {
  console.error(err.message);
  process.exitCode = 1;
} finally {
  await pool.end();
}
