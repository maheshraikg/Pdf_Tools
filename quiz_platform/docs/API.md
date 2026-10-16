# HTTP / WebSocket API

All responses are JSON. Errors have the form
`{"error": {"code": "...", "message": "...", "details": {...}}}`.
Timestamps in responses are ISO-8601 UTC, or epoch milliseconds for
timing-critical fields (`serverNow`, `opensAt`, `closesAt`).

Authentication: an `HttpOnly` session cookie (browsers) or
`Authorization: Bearer <token>` (native and test clients). Cookie-authenticated
`POST`, `PATCH`, `PUT` and `DELETE` requests must send `X-Requested-With: quiz-app`.

## Participant API (`/api`)

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/time` | – | `{serverNow}` for clock sync |
| POST | `/auth/otp/request` | – | `{phone}` → `{challengeId, expiresInMs, resendAfterMs, maskedPhone}` |
| POST | `/auth/otp/verify` | – | `{challengeId, code}` → session cookie + `{user, isNew, profileComplete, token, expiresAt}` |
| POST | `/auth/logout` | user | revoke the session |
| GET / PATCH | `/me` | user | profile (`displayName`, `preferredLang` en/kn) |
| GET | `/me/history` | user | competition history with published ranks |
| GET | `/me/notifications`, POST `/me/notifications/read` | user | in-app notifications |
| GET | `/competitions` | optional | upcoming, live and recent competitions (+ `registered` flag) |
| GET | `/competitions/:id` | optional | competition details, participant count |
| POST | `/competitions/:id/register` | user | `{accessCode?}`; idempotent |
| GET | `/competitions/:id/state` | user | authoritative live state: phase, current question (no answer key), my answer, progress |
| POST | `/competitions/:id/answers` | user | `{questionId, option: A-D, idempotencyKey}` → `{accepted, duplicate, responseMs, receivedAt}` |
| GET | `/competitions/:id/leaderboard?limit=10\|50\|100&page=&q=` | – | official (after publication) or provisional (if enabled) |
| GET | `/competitions/:id/results/:registrationId` | – | public result card (after publication) |
| GET | `/competitions/:id/my-result` | user | own summary + per-question breakdown after completion |

Answer errors: `deadline_passed` (409, includes `lateByMs`), `question_not_open`,
`already_answered` (includes the recorded option), `competition_not_live`,
`not_registered`, `late_entry_closed`, `rate_limited` (429).

### WebSocket `/api/ws`

The connection is authenticated with the session cookie or a Bearer header.

Client → server:
* `{"type":"subscribe","competitionId":"…"}`
* `{"type":"time","t0":<client ms>}`

Server → client:
* `hello`, `subscribed`
* `time` (`{t0, serverNow}`)
* `question` (`{serverNow, question:{id, position, total, text, options, imageUrl, opensAt, closesAt, durationMs}}`)
* `question_closed` (`{position, nextOpensAt, correctOption?}`)
* `competition_ended`
* `results_computed`
* `results_published`
* `competition_cancelled`
* `leaderboard` (provisional top 10, only if enabled)

## Admin API (`/api/admin`, admin session required)

| Method | Path | Permission |
|---|---|---|
| POST | `/auth/login`, `/auth/logout`; GET `/me` | – |
| GET/POST | `/admins`, POST `/admins/:id/status` | admins.manage |
| GET | `/competitions`, `/competitions/:id` | view (answer key requires questions.read) |
| POST/PATCH/DELETE | `/competitions`, `/competitions/:id` | competitions.write |
| POST | `/competitions/:id/schedule` \| `unschedule` \| `cancel {reason}` | competitions.write |
| POST | `/competitions/:id/publish` | results.publish |
| PUT/DELETE | `/competitions/:id/questions/:position` | competitions.write |
| POST | `/competitions/:id/questions/import` `{questions:[…15]}` or `{csv}` | competitions.write |
| GET | `/competitions/:id/participants?q=&page=` | view |
| GET | `/competitions/:id/live` | view: registered, entered, connected sockets, answers/s, rejections |
| GET | `/competitions/:id/report` | view: counts, score stats and distribution, per-question analysis, response-time percentiles |
| GET | `/competitions/:id/leaderboard` | view (provisional while live, final before publication) |
| GET | `/competitions/:id/export?format=csv\|xlsx[&includePhone=true]` | export (full phone: super_admin only) |
| GET | `/competitions/:id/suspicious` | users.suspend |
| GET | `/users?q=`; POST `/users/:id/suspend {reason}`, `/users/:id/reinstate` | view / users.suspend |
| GET | `/audit?entityType=&entityId=&action=` | audit.read |
| GET | `/health` | view |

CSV import header:
`position,text,optionA,optionB,optionC,optionD,correctOption,marks,category,imageUrl`.

## Operations

`GET /healthz` (liveness), `GET /readyz` (database reachable), `GET /metrics`
(Prometheus; set `METRICS_TOKEN` in production).
