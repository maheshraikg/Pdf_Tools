# Architecture

```
 Phones / browsers (PWA, admin dashboard)
        │  HTTPS + WebSocket (wss)
        ▼
 ┌──────────────┐   least-connections, WebSocket upgrade
 │ nginx / LB   │
 └──────┬───────┘
        ▼
 ┌──────────────┐ ┌──────────────┐ ┌──────────────┐   stateless Node.js instances
 │  app node 1  │ │  app node 2  │ │  app node N  │   (Fastify + ws), scale horizontally
 └──┬───────┬───┘ └──┬───────┬───┘ └──┬───────┬───┘
    │       │        │       │        │       │
    │       └────────┴───┬───┴────────┘       │
    │                    ▼                    │
    │            ┌──────────────┐             │
    │            │    Redis     │  rate limits, shared cache,
    │            └──────────────┘  pub/sub events, presence counts
    ▼                                         ▼
 ┌─────────────────────────────────────────────────┐
 │ PostgreSQL 16 — single source of truth           │  (+ PgBouncer and a read
 │ constraints + triggers enforce fairness rules    │   replica for reports at
 └─────────────────────────────────────────────────┘   large scale)
```

## Components

| Path | Responsibility |
|---|---|
| `src/app.js` | Fastify app: security headers, CSRF, global rate limit, error mapping, metrics, static PWA |
| `src/routes/participant.js` | auth (OTP), profile, competitions, state, answers, leaderboards, WebSocket |
| `src/routes/admin.js` | RBAC-protected admin API |
| `src/services/schedule.js` | **pure deterministic timeline** (question open/close instants) |
| `src/services/engine.js` | live state + answer submission (deadline check, scoring, idempotency) |
| `src/services/ranking.js` | **pure official ranking comparator** |
| `src/services/results.js` | finalisation, publication, official + provisional leaderboards |
| `src/services/realtime.js` | WebSocket hub with per-competition precise timers; Redis event bus |
| `src/services/lifecycle.js` | background jobs: start/freeze, finalise, "starting soon", SMS outbox, cleanup |
| `src/services/competitions.js` | competition and question management, registration |
| `src/services/reports.js` | reports, CSV/Excel export, live monitoring, suspicious activity, moderation |
| `src/services/auth.js` | OTP, sessions, admin auth, RBAC |
| `src/sms/index.js` | SMS gateway adapters (MSG91, Twilio, dev console) |
| `migrations/` | SQL schema, constraints and fairness triggers |
| `public/` | participant PWA (vanilla JS, ~40 KB, no build step) and admin dashboard |

## Why it scales

**No coordination on the hot path.** The question timeline is a pure function of
frozen data. Every node pushes "question opened" at the same instant using its
own `setTimeout`, accurate to a few milliseconds, with no leader election and no
cross-node messages per question.

**One write per answer.** A submission is one `INSERT … ON CONFLICT DO NOTHING`
on a table with a unique index. The answer key, the competition row,
participant rows and session lookups are cached in memory per node. The question
set is immutable once frozen, so caching it is safe. At 10,000 participants the
peak is about 1,000 answers/s spread over a 10-second window, which PostgreSQL
handles comfortably on one primary.

**Broadcasts are serialised once.** A question push to 10,000 sockets costs one
`JSON.stringify`, then a write to each socket. Slow consumers are dropped.

**Leaderboards are computed once, not per viewer.** Provisional standings come
from a single aggregate query per node per interval (3 s, single-flight cache),
ranked in memory and sliced per request. Official standings are immutable after
finalisation and cached across nodes in Redis. Viewing the leaderboard never
triggers a query per connected participant.

**Reconnect storms are cheap.** `/state` is a handful of indexed lookups. Clients
reconnect with exponential backoff and jitter. If the WebSocket is down,
clients fetch state just after each boundary, with jitter.

**Background jobs are safe on every node.** They use row locks (`FOR UPDATE`),
status guards and advisory locks, so running them on N nodes is idempotent.

## Timing data flow

1. Lifecycle job (≤ 500 ms after start): `scheduled → live`, freezes the
   question set (`frozen_at`, `question_set_hash`). The database also refuses
   question edits after `start_at` even before the job runs.
2. At `opensAt(p)`, every node broadcasts the public question payload
   (`opensAt`, `closesAt`, options; no answer key) to its subscribers.
3. A client tap sends `POST /answers {questionId, option, idempotencyKey}`. The
   node stamps `receivedAt`, validates the window, scores against the cached key,
   and inserts.
4. At `closesAt(p)+1 ms`, nodes broadcast `question_closed` (with the correct
   option only if "reveal answers" is enabled).
5. At `endsAt + 2 s`, one node finalises: writes timeout rows, aggregates, ranks
   and stores `competition_results` in one transaction. An admin then publishes.

## Data model

See `migrations/001_init.sql`. Main tables: `users`, `admin_users`,
`otp_challenges`, `sessions`, `competitions`, `questions`,
`competition_participants`, `answer_submissions`, `submission_rejections`,
`competition_results`, `audit_logs`, `notifications`. Key constraints:

* `UNIQUE(users.phone_hash)`: one account per mobile number
* `UNIQUE(competition_participants.competition_id, user_id)`: one registration
* `UNIQUE(answer_submissions.participant_id, question_id)`: one answer per question
* `CHECK(question_count = 15)`, `CHECK(question_time_ms = 10000)`, `position BETWEEN 1 AND 15`
* triggers: frozen competitions are immutable; the audit log is append-only.

## Scaling beyond the tested target

* Add app nodes behind the load balancer. Each node holds about 10–20k idle
  WebSockets comfortably; CPU is the limit during broadcasts.
* Put **PgBouncer** (transaction pooling) between nodes and PostgreSQL once
  `nodes × DB_POOL_MAX` approaches `max_connections`.
* Move reports and exports to a **read replica**.
* If answer bursts exceed what a single primary can absorb (well beyond 50k
  concurrent participants), batch inserts per node (multi-row `INSERT` every
  5–10 ms) or partition `answer_submissions` by competition.
* Use Redis Cluster or a managed Redis with replication. Losing Redis
  temporarily degrades rate limiting and caching but not correctness.
* Run regular load tests (`loadtest/run.js`) at your target size on
  production-like infrastructure before each large event.
