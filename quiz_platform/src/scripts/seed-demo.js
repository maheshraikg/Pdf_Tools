// Creates a demo competition with 15 sample questions, scheduled to start in
// START_IN_MINUTES (default 3) with registration open now. Development only.
import { loadConfig } from '../config.js';
import { createPool } from '../lib/db.js';
import { createCompetition, importQuestions, scheduleCompetition } from '../services/competitions.js';
import { sampleQuestions } from './sample-questions.js';

const cfg = loadConfig();
if (cfg.isProd) { console.error('seed-demo is for development only'); process.exit(1); }
const pool = createPool(cfg);
const ctx = { cfg, pool, log: console, bus: { publish: async () => {} } };
try {
  let admin = (await pool.query(`SELECT * FROM admin_users ORDER BY created_at LIMIT 1`)).rows[0];
  if (!admin) throw new Error('create an admin first (npm run create-admin)');
  const startIn = Number(process.env.START_IN_MINUTES ?? 3);
  const start = new Date(Date.now() + startIn * 60_000);
  start.setSeconds(0, 0);
  if (start.getTime() < Date.now() + 70_000) start.setTime(start.getTime() + 60_000);
  const c = await createCompetition(ctx, {
    title: 'Demo General Knowledge Quiz',
    description: 'A 15-question demo competition. 10 seconds per question.',
    rules: '15 questions, 10 seconds each. +1 for a correct answer, 0 otherwise. Ties are broken by faster correct answers.',
    startAt: start.toISOString(),
    registrationOpensAt: new Date(Date.now() - 60_000).toISOString(),
    registrationClosesAt: start.toISOString(),
    showProvisional: true,
    revealAnswers: false,
    branding: { organization: 'Demo School' },
  }, admin);
  await importQuestions(ctx, c.id, sampleQuestions, admin);
  await scheduleCompetition(ctx, c.id, admin);
  console.log(`demo competition ${c.code} (${c.id}) starts at ${start.toISOString()}`);
} catch (err) {
  console.error(err.message);
  process.exitCode = 1;
} finally {
  await pool.end();
}
