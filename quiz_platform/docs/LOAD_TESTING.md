# Load testing

## Method

`loadtest/run.js` drives a **real competition end to end**. It creates and
schedules a competition through the admin API. Then each simulated participant:

1. obtains a session through the load-test endpoint. This skips SMS only; the
   endpoint is disabled unless `LOAD_TEST_SECRET` is set, and always disabled
   when `NODE_ENV=production`.
2. registers for the competition through the normal API;
3. opens a WebSocket, subscribes, and waits for the server to push each question;
4. answers each question after a random "thinking" delay of 0.3–9.5 s, using a
   random option (about 10% of questions are deliberately skipped);
5. in about 2% of answers, also requests the leaderboard; 2% of participants also
   fetch `/state` on every question, to simulate refreshes.

Clients are spread across worker threads and round-robined across server nodes
to simulate a load balancer. At the end, the tool checks integrity: the number of
answers the server stored must equal the number of answers clients saw accepted.

```bash
# server nodes (example: 2 nodes + Redis), NOT production
LOAD_TEST_SECRET=… RATE_LIMIT_GLOBAL_PER_IP_PER_MINUTE=100000000 REDIS_URL=redis://… PORT=3001 node src/server.js
# load generator
ADMIN_EMAIL=… ADMIN_PASSWORD=… LOAD_TEST_SECRET=… \
TARGETS=http://host:3001,http://host:3002 PARTICIPANTS=10000 WORKERS=3 node loadtest/run.js
```

## Results — 2026-10-16

**Environment.** Everything ran on **one 4-vCPU / 15 GB Linux VM**:
* 2 app nodes (Node 22, `DB_POOL_MAX=40` each),
* PostgreSQL 16 (default config, `max_connections=300`),
* Redis 7,
* the load generator (3 worker threads) sharing the same CPUs.

All traffic was local, so **network latency is not represented** (see the notes below).

### 10,000 concurrent participants (target)

| Metric | Result |
|---|---|
| Participants registered / WebSockets connected | **10,000 / 10,000** |
| Setup errors, WebSocket drops | 0, 0 |
| Clients that received all 15 questions | **10,000** (0 duplicate pushes) |
| Answers attempted / accepted | 135,027 / **135,025** |
| Rejected | 2 × `deadline_passed`: answers sent at ≈9.5 s that arrived after 10 s, which is correct behaviour |
| Error rate (excluding correct deadline rejections) | **0%** |
| Integrity: answers in DB vs answers acknowledged to clients | **135,025 = 135,025** ✔ |
| Participants finalised and ranked | 10,000 (results computed automatically) |
| Answer throughput | ≈ 600–900 answers/s sustained over 3 minutes |
| Answer submit latency (client round trip) | p50 **3.1 ms**, p95 35 ms, p99 **107 ms**, max 436 ms |
| Server-side submit processing (Prometheus, both nodes, all runs) | 90% ≤ 5 ms, 98.4% ≤ 25 ms, 99.9% ≤ 100 ms |
| Question push delay (scheduled opening → received by client) | p50 **43 ms**, p95 100 ms, p99 **218 ms**, max 262 ms |
| Leaderboard request latency | p50 1.5 ms, p95 85 ms, p99 207 ms, 0 errors |
| `/state` (refresh) latency | p50 74 ms, p95 221 ms, p99 660 ms |
| CPU (whole VM, during question windows) | 45–83% busy; bursts to ~92% while 10,000 sessions were created |
| App node memory (RSS, 2 nodes + load generator) | ≈ 1.4 GB total |

### 1,000 concurrent participants

| Metric | Result |
|---|---|
| Clients that received all 15 questions | 1,000 (0 duplicates) |
| Answers accepted / errors | 13,444 / 0; DB count matches exactly |
| Submit latency | p50 3.3 ms, p99 9.3 ms |
| Question push delay | p50 7 ms, p99 41 ms |

## Defect found by load testing (fixed)

The first 1,000-participant run showed about 13% rejected answers and some
question pushes arriving about 10 s late.

**Root cause:** Node/libuv timers can fire *before* their high-resolution target.
When the event loop is busy, a timer can fire several milliseconds early. The
WebSocket hub re-evaluated the competition phase on wake-up, so an early "close"
wake-up re-broadcast the still-open question at its deadline.

**Fix:** boundary timers are now target-based. An early wake-up waits out the
remainder, each event is emitted exactly once per node, and a question whose
window has passed is never delivered. A deterministic regression test covers this
(`test/realtime.test.js`). After the fix: 0 duplicates and 0 missed questions at
both 1,000 and 10,000 participants.

## Interpretation and caveats (read before relying on these numbers)

* **The 10,000 target was met on a single small VM**, with the load generator
  competing for the same 4 CPUs, so production hardware should have more
  headroom. The numbers are still **not a guarantee** for your deployment. Repeat
  the test on the real infrastructure (load balancer, TLS, managed database,
  real network) before each large event.
* **Network latency was ~0** because everything was local. On mobile networks,
  expect push delay and submit round trip to grow by the participants' RTT
  (typically 30–150 ms on 4G). This affects every participant similarly and is
  included in official response times, as documented in
  `docs/TIMING_AND_SCORING.md`.
* Push-delay tail (p99 ≈ 218 ms) is dominated by CPU contention on the shared VM
  while serialising writes to 5,000 sockets per node. Adding app nodes reduces it
  roughly linearly. Keep it low, since it is time participants lose.
* The heaviest synthetic burst was ≈ 1,000 answers/s. A real competition where
  everyone answers within the first 2–3 seconds would peak at roughly
  3,000–5,000 answers/s for 10,000 participants. That has **not** been tested
  here. Test it on target hardware, for example by narrowing the thinking-delay
  range in `loadtest/run.js`.
* PostgreSQL RSS figures from `ps` include shared buffers counted per backend and
  overstate real memory use.
* SMS/OTP throughput was not load-tested (the test bypasses SMS). Check your SMS
  provider's rate limits for mass logins before an event, and open registration
  well in advance.
