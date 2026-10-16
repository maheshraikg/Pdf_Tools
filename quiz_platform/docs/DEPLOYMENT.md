# Deployment & operations

## Requirements

* Node.js ≥ 20 (22 LTS recommended)
* PostgreSQL ≥ 14 (16 recommended)
* Redis ≥ 6 (required for more than one app instance)
* An SMS gateway account: MSG91 (India; register DLT templates) or Twilio
* TLS termination (nginx, or a cloud load balancer) and NTP-synchronised hosts

## Option A — Docker Compose (single host or small events)

```bash
cp .env.example .env            # fill in every secret (openssl rand -base64 32 for each key)
docker compose up -d --build
docker compose run --rm app node src/scripts/migrate.js
docker compose run --rm -e ADMIN_PASSWORD='a-long-passphrase' app \
  node src/scripts/create-admin.js admin@school.org "Admin Name" super_admin
docker compose up -d --scale app=3   # more instances behind nginx
```

Then open `https://<host>/` (participants) and `https://<host>/admin` (administrators).

## Option B — Managed cloud (recommended for 10,000+ participants)

* **App:** a container service with autoscaling (ECS/Fargate, Cloud Run with
  min-instances and session affinity *not* required, Kubernetes Deployment), at
  least 3 instances × 1 vCPU / 1 GB across availability zones, with health check
  `/readyz`. Pre-scale **before** the event: autoscalers react too slowly to a
  synchronised start.
* **Load balancer:** must support WebSockets (ALB, GCLB, nginx ingress). Idle
  timeout ≥ 120 s.
* **PostgreSQL:** managed (RDS/Cloud SQL/Azure) with Multi-AZ, PITR backups,
  ≥ 4 vCPU for 10k participants; PgBouncer when instances × `DB_POOL_MAX` > 80% of
  `max_connections`.
* **Redis:** managed (ElastiCache / Memorystore) with replica.
* **Secrets:** cloud secret manager → environment variables.
* **Release step:** `node src/scripts/migrate.js` (advisory-locked, safe to run
  from several places).

## Event-day checklist

1. Load-test the exact infrastructure at ≥ target size within the past week
   (`docs/LOAD_TESTING.md`).
2. Scale app instances to the tested size at least 30 minutes before the start.
3. Verify NTP on all nodes (`chronyc tracking` offset < 5 ms).
4. Confirm the competition is **Scheduled**, has 15 questions, and the
   registration window is correct. Questions freeze automatically at start.
5. If late entry is not allowed, remind participants to join before start.
6. Watch **Admin → Live monitor** (connected, entered, answers/s, rejections) and
   **System health**; Prometheus `/metrics` for latency
   (`quiz_answer_submit_duration_seconds`, `http_request_duration_seconds`,
   `quiz_ws_connections`, event-loop lag).
7. After the last question, results compute automatically (~2 s). Review the
   report and suspicious-activity tab, then **Publish results**.
8. Export CSV / Excel for records.

## Monitoring & alerting (suggested)

| Signal | Alert when |
|---|---|
| `/readyz` | failing on any instance |
| p99 `quiz_answer_submit_duration_seconds` | > 250 ms during a live competition |
| HTTP 5xx rate | > 0.5% |
| event-loop lag (admin health) | > 100 ms |
| DB pool waiting | > 0 for 30 s |
| `quiz_answer_submissions_total{outcome="deadline_passed"}` | sudden spike (network or clock problem) |
| clock offset (node exporter `node_timex_offset_seconds`) | > 10 ms |

Logs are structured JSON (pino) with request IDs; authorisation headers and
cookies are redacted.

## Failure handling

| Failure | Behaviour |
|---|---|
| App instance crash / deploy | Clients reconnect (backoff + jitter) to another instance and resume from `/state`; absolute deadlines mean no time gained or lost; committed answers are durable. Use rolling deploys, never during a live competition. |
| Brief network loss on a phone | Countdown continues locally from the synced clock; answer submission retries with the same idempotency key until the deadline; reconnect restores state. |
| Redis outage | Rate limits degrade to per-node counting, caches miss to the DB, cross-node events (cancellation, suspension) fall back to the 1 s / 15 s cache expiry. Results unaffected. Restore Redis promptly. |
| PostgreSQL failover | Requests fail for the failover duration (typically 20–60 s on managed services); answers not acknowledged were not recorded and clients show an error. If a failover hits a live competition, consider cancelling and re-running it (fairness), which is an administrative decision. |
| Need to stop a competition | Admin → Cancel (live cancellation is allowed and audited; participants are notified). |
| Results audit | Results are derived purely from `answer_submissions` (which keep `opened_at`, `received_at`, `response_ms`), so they can be independently re-derived at any time, e.g. on a restored copy. |

## Backups

* Continuous WAL archiving / PITR (managed service or pgBackRest), retention ≥ 14 days.
* Nightly `pg_dump -Fc` to separate storage; quarterly restore drill.
* Exports (CSV/Excel) of every published competition stored with the event records.
