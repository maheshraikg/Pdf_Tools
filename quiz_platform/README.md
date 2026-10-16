# Quiz Competition Platform

A real-time quiz competition platform for schools, institutions and large public
quizzes. It includes a mobile-first participant PWA (English and ಕನ್ನಡ), an
administrator dashboard, and a backend with mobile-number OTP login,
server-authoritative 10-second timing, millisecond response measurement,
automatic scoring and deterministic tie-breaking.

* **Format:** every competition has exactly 15 multiple-choice questions, with
  exactly 10,000 ms per question.
* **Fairness:** the server clock decides everything. One answer per question is
  guaranteed by the database. The question set freezes at the start (enforced by
  database triggers). The answer key is never sent to participants.
* **Ranking:** marks, then correct-answer time, then total answer time, then
  completion time. Full ties share a rank. See
  [docs/TIMING_AND_SCORING.md](docs/TIMING_AND_SCORING.md).
* **Scale:** stateless Node.js nodes, PostgreSQL, Redis and WebSockets. See the
  measured results in [docs/LOAD_TESTING.md](docs/LOAD_TESTING.md).

## Quick start (development)

```bash
cd quiz_platform
npm install
createdb quiz                                   # PostgreSQL 14+
export DATABASE_URL=postgres://postgres@localhost:5432/quiz
npm run migrate
ADMIN_PASSWORD='choose-a-long-password' npm run create-admin -- admin@example.org "Admin" super_admin
START_IN_MINUTES=3 npm run seed:demo            # optional: demo competition with 15 questions
npm start                                       # http://localhost:3000  (admin: /admin)
```

In development, `SMS_PROVIDER=console` prints OTPs to the server log instead of
sending SMS. Production refuses to start with it. Redis is optional for a single
node; set `REDIS_URL` when running more than one.

## Tests

```bash
createdb quiz_test
DATABASE_URL_TEST=postgres://postgres@localhost:5432/quiz_test npm test
```

There are 51 automated tests against a real PostgreSQL database and the real
HTTP and WebSocket stack. They cover:

* OTP flow: expiry, attempt limits, single use, cooldown and rate limits, no plaintext storage
* sessions, logout and CSRF
* exactly 15 questions and exactly 10 s per question
* the inclusive deadline (10,000 ms accepted, 10,001 ms rejected), early and late answers
* correct and incorrect scoring and configurable marks
* duplicate answers and idempotent replays; 50 concurrent submissions → one record
* simultaneous answers from 40 participants
* refresh and reconnect without timer reset; late-entry policy
* suspension and live cancellation
* question freeze enforced by both the API and the database
* role-based access control and answer-key secrecy
* every tie-breaker, end-to-end finalisation and publication
* leaderboard views, search and pagination
* CSV and Excel export accuracy, and reports
* WebSocket push timing and clock sync

## Documentation

| Document | Contents |
|---|---|
| [docs/TIMING_AND_SCORING.md](docs/TIMING_AND_SCORING.md) | official timing policy, scoring, ranking and tie-breaking |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | components, data flow, data model, scaling strategy |
| [docs/SECURITY.md](docs/SECURITY.md) | authentication, privacy, RBAC, anti-cheating (and its limits), backups |
| [docs/API.md](docs/API.md) | REST and WebSocket API reference |
| [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) | Docker Compose / cloud deployment, event-day checklist, monitoring, failure handling |
| [docs/LOAD_TESTING.md](docs/LOAD_TESTING.md) | load-test method and measured results |
| [.env.example](.env.example) | every configuration variable |

## Project layout

```
quiz_platform/
├── migrations/          SQL schema, constraints, fairness triggers
├── src/
│   ├── app.js / server.js
│   ├── routes/          participant + admin HTTP/WebSocket endpoints
│   ├── services/        schedule, engine, ranking, results, realtime, lifecycle, reports, auth …
│   ├── lib/             clock, crypto, rate limiting, cache, CSV, metrics
│   ├── sms/             MSG91 / Twilio / dev-console adapters
│   └── scripts/         migrate, create-admin, seed-demo
├── public/              participant PWA + /admin dashboard (no build step)
├── test/                automated tests (node:test)
├── loadtest/            multi-worker load generator
└── deploy/, Dockerfile, docker-compose.yml
```

## What is deliberately *not* included

* **Push notifications (FCM/Web Push).** Notifications are in-app, plus SMS when
  enabled per competition and per deployment. Web Push can be added on top of
  the notification outbox.
* **Proctoring / lockdown browser.** See *Limitations of browser-based cheating
  prevention* in [docs/SECURITY.md](docs/SECURITY.md).
* **Real SMS delivery was not exercised in this repository's tests.** The
  MSG91 and Twilio adapters follow the providers' documented HTTP APIs, but must
  be verified with real credentials (and DLT-approved templates in India)
  before going live.
