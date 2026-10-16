# Security, privacy and anti-cheating

## Authentication

**Participants: mobile number + OTP**
* 6-digit OTP from a CSPRNG (`crypto.randomInt`), delivered by an SMS gateway
  (MSG91 or Twilio). We generate and verify the OTP ourselves on the server.
* Only `HMAC-SHA256(OTP_HMAC_KEY, challengeId : phoneHash : code)` is stored.
  The OTP is never stored or logged in plain text, except by the development-only
  `console` SMS provider, which is refused when `NODE_ENV=production`.
* Expiry: 5 minutes. Maximum 5 verification attempts per OTP, counted atomically
  in the database. A new OTP invalidates the previous one. Each OTP can be used
  once, even under concurrent requests.
* Limits: 30 s resend cooldown, 5 OTPs per number per hour, 30 per IP per hour
  (configurable), and 10 failed verifications per number per hour.
* Responses are identical for new and existing numbers (no account enumeration).

**Administrators: email + password**, scrypt-hashed (N=16384). Logins are
rate-limited and audited. A dummy hash is verified for unknown emails, so
response time does not reveal which accounts exist.

**Sessions** are 256-bit random bearer tokens. Only their SHA-256 is stored.
Browsers receive them as `HttpOnly; SameSite=Strict; Secure` cookies. Sessions
have an absolute expiry (7 days for participants, 8 hours for administrators),
an idle timeout, logout (revocation), and revoke-all on suspension. Each node
caches session lookups for at most 15 s. Revocation applies immediately on the
node that handled it, and within 15 s on the others; suspensions are also
broadcast over Redis.

**CSRF:** cookie-authenticated state-changing requests must carry
`X-Requested-With: quiz-app`. Browsers cannot add this header cross-origin
without a CORS preflight, and the server never grants one. `SameSite=Strict`
adds a second layer.

## Personal data (data minimisation)

We collect only a mobile number, a display name and a language preference.
* Mobile numbers are stored as an HMAC blind index (`phone_hash`, used for
  uniqueness and lookup) plus AES-256-GCM ciphertext (`phone_enc`, used only to
  send SMS). Only the last 4 digits are stored in clear, for masked display.
* Leaderboards show the display name and registration ID, never phone numbers.
* Exports mask mobile numbers. Only a `super_admin` can export full numbers, and
  every export is audited.
* IP addresses are stored only as keyed hashes (for abuse detection).

## Authorisation

Every protected endpoint checks the session and, for administrators, an explicit
permission:

| Role | Permissions |
|---|---|
| super_admin | everything, including managing administrators and full-number exports |
| admin | competitions, questions and **answer keys**, publishing, exports, suspensions, audit log |
| moderator | monitoring, participant search, suspensions, suspicious-activity view, audit log |
| viewer | read-only monitoring and reports; **cannot** see answer keys |

Answer keys are never included in participant payloads; tests assert this.

## Fairness controls

* Server-side deadlines, server-side answer validation and server-side scoring.
* `UNIQUE(participant_id, question_id)` prevents double scoring. Idempotency
  makes retries safe.
* Configuration and question sets are immutable after the start, enforced by
  database triggers. A question-set hash is recorded.
* The audit log is append-only (a trigger blocks UPDATE and DELETE). It records
  logins, registrations, every administrative change, competition start and
  finalisation, publication, exports and suspensions. Each answer is itself an
  audit record, with `opened_at`, `received_at`, node ID and a hashed IP.
* Rejected submissions (late, early, changed answer, competition not live) are
  logged for review.
* Suspicious-activity report: repeated rejected submissions, answers faster than
  400 ms, perfect scores with very fast averages, and many accounts on one
  network. These are **signals for human review only**: schools and mobile
  carriers legitimately share IP addresses.

## Injection and XSS

* All SQL uses parameterised queries. Request bodies are validated with JSON
  schemas (unknown properties rejected).
* The front end renders user and admin text with `textContent` only (never
  `innerHTML`).
* A strict CSP (`script-src 'self'`, no inline script or style elements,
  `frame-ancestors 'none'`), plus `nosniff`, `X-Frame-Options: DENY` and HSTS
  when cookies are secure.
* CSV and Excel exports neutralise spreadsheet formula injection.

## Rate limiting and abuse

Redis-backed fixed-window limits (shared across nodes):
* global per-IP limit,
* per-user answer-submission limit,
* OTP send and verify limits,
* admin login limit,
* access-code attempts.

Raise per-IP limits for venues where everyone shares one NAT address. Slow
WebSocket consumers are disconnected rather than buffered.

## Limitations of browser-based cheating prevention (important)

No web or mobile client can stop a participant from:
* searching the web or asking someone else on a second device,
* sharing questions in real time with other participants,
* running a modified client or scripting the HTTP API.

For that reason the platform does **not** rely on blocking copy-paste, blocking
navigation, full-screen locks or "tab switch" detection as evidence of fairness.
These can be bypassed and they penalise honest users with flaky devices. Fairness
comes from what the server controls:
* the 10-second window is short and enforced by the server,
* everyone gets the same question at the same instant,
* answers cannot be changed or replayed,
* the answer key never reaches the client before a question closes,
* every action is recorded for review.

For high-stakes events, combine the platform with **invigilation** (a
supervised venue), and consider shuffling option order per participant or using
separate question banks per group (not implemented). Treat suspicious-activity
signals as leads for human review, not proof.

## Backups and recovery

* PostgreSQL is the single source of truth. Enable continuous WAL archiving /
  point-in-time recovery (for example pgBackRest, or the managed service's PITR)
  plus daily logical dumps (`pg_dump -Fc`). Test restores regularly.
* Redis holds only rate-limit counters, caches and pub/sub. Losing it loses no
  results.
* App instances are stateless. If an instance crashes mid-question, clients
  reconnect to another instance and resume from `/state`. Deadlines are absolute,
  so nobody gains or loses time, and answers already committed are durable.
* Finalisation is idempotent and runs automatically on any surviving node.

## Secrets

All credentials (SMS gateway keys, encryption and HMAC keys, database password)
are read from environment variables or a secret manager. See `.env.example`.
Nothing is committed to the repository.
