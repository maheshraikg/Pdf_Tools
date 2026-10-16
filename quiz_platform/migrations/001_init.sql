-- Quiz Competition Platform: initial schema.
-- All timestamps are timestamptz (stored in UTC, microsecond precision).
-- Response durations are stored as integer milliseconds.

-- ---------------------------------------------------------------------------
-- Participants (users)
-- ---------------------------------------------------------------------------
-- Mobile numbers are never stored in plain text:
--   phone_hash : HMAC-SHA256(PHONE_HASH_KEY, E.164 number) -> uniqueness + lookup
--   phone_enc  : AES-256-GCM(PHONE_ENC_KEY, E.164 number)  -> admin display / SMS
CREATE TABLE users (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  registration_id  text NOT NULL UNIQUE,
  phone_hash       bytea NOT NULL UNIQUE,
  phone_enc        bytea NOT NULL,
  phone_last4      text NOT NULL,
  display_name     text CHECK (display_name IS NULL OR char_length(display_name) BETWEEN 2 AND 60),
  preferred_lang   text NOT NULL DEFAULT 'en' CHECK (preferred_lang IN ('en', 'kn')),
  status           text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'suspended')),
  suspended_reason text,
  suspended_at     timestamptz,
  created_at       timestamptz NOT NULL DEFAULT now(),
  updated_at       timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX users_display_name_idx ON users (lower(display_name) text_pattern_ops);

-- ---------------------------------------------------------------------------
-- Administrators (separate identity space from participants)
-- ---------------------------------------------------------------------------
CREATE TABLE admin_users (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email         text NOT NULL,
  name          text NOT NULL,
  password_hash text NOT NULL,
  role          text NOT NULL CHECK (role IN ('super_admin', 'admin', 'moderator', 'viewer')),
  status        text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'disabled')),
  last_login_at timestamptz,
  created_at    timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX admin_users_email_uq ON admin_users (lower(email));

-- ---------------------------------------------------------------------------
-- OTP challenges. The OTP itself is never stored: only an HMAC of it.
-- ---------------------------------------------------------------------------
CREATE TABLE otp_challenges (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  phone_hash   bytea NOT NULL,
  phone_enc    bytea NOT NULL,
  code_hash    bytea NOT NULL,
  attempts     integer NOT NULL DEFAULT 0,
  max_attempts integer NOT NULL,
  expires_at   timestamptz NOT NULL,
  consumed_at  timestamptz,
  ip_hash      bytea,
  created_at   timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX otp_challenges_phone_idx ON otp_challenges (phone_hash, created_at DESC);

-- ---------------------------------------------------------------------------
-- Sessions (participant + admin). Only a SHA-256 of the bearer token is stored.
-- ---------------------------------------------------------------------------
CREATE TABLE sessions (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  subject_type text NOT NULL CHECK (subject_type IN ('user', 'admin')),
  subject_id   uuid NOT NULL,
  token_hash   bytea NOT NULL UNIQUE,
  user_agent   text,
  created_at   timestamptz NOT NULL DEFAULT now(),
  last_seen_at timestamptz NOT NULL DEFAULT now(),
  expires_at   timestamptz NOT NULL,
  revoked_at   timestamptz
);
CREATE INDEX sessions_subject_idx ON sessions (subject_type, subject_id);

-- ---------------------------------------------------------------------------
-- Competitions
-- ---------------------------------------------------------------------------
-- Stored status: draft | scheduled | live | completed | cancelled.
-- "Registration Open" is derived from the registration window while scheduled
-- (see src/services/competitions.js#effectiveStatus).
CREATE TABLE competitions (
  id                      uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code                    text NOT NULL UNIQUE,
  title                   text NOT NULL CHECK (char_length(title) BETWEEN 3 AND 200),
  description             text NOT NULL DEFAULT '',
  rules                   text NOT NULL DEFAULT '',
  status                  text NOT NULL DEFAULT 'draft'
                            CHECK (status IN ('draft', 'scheduled', 'live', 'completed', 'cancelled')),
  start_at                timestamptz NOT NULL,
  registration_opens_at   timestamptz NOT NULL,
  registration_closes_at  timestamptz NOT NULL,
  question_count          integer NOT NULL DEFAULT 15 CHECK (question_count = 15),
  question_time_ms        integer NOT NULL DEFAULT 10000 CHECK (question_time_ms = 10000),
  transition_ms           integer NOT NULL DEFAULT 3000 CHECK (transition_ms BETWEEN 1000 AND 30000),
  default_marks           integer NOT NULL DEFAULT 1 CHECK (default_marks BETWEEN 1 AND 100),
  visibility              text NOT NULL DEFAULT 'public' CHECK (visibility IN ('public', 'restricted')),
  access_code_hash        bytea,
  late_entry_allowed      boolean NOT NULL DEFAULT true,
  reveal_answers          boolean NOT NULL DEFAULT false,
  show_provisional        boolean NOT NULL DEFAULT false,
  notify_sms              boolean NOT NULL DEFAULT false,
  branding                jsonb NOT NULL DEFAULT '{}'::jsonb,
  frozen_at               timestamptz,
  question_set_hash       text,
  results_computed_at     timestamptz,
  results_published_at    timestamptz,
  cancelled_reason        text,
  start_notified_at       timestamptz,
  created_by              uuid REFERENCES admin_users(id),
  created_at              timestamptz NOT NULL DEFAULT now(),
  updated_at              timestamptz NOT NULL DEFAULT now(),
  CHECK (registration_opens_at < registration_closes_at),
  CHECK (registration_opens_at <= start_at),
  CHECK (visibility = 'public' OR access_code_hash IS NOT NULL)
);
CREATE INDEX competitions_status_start_idx ON competitions (status, start_at);

-- ---------------------------------------------------------------------------
-- Questions (exactly 15 per competition, positions 1..15)
-- ---------------------------------------------------------------------------
CREATE TABLE questions (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  competition_id uuid NOT NULL REFERENCES competitions(id) ON DELETE CASCADE,
  position       integer NOT NULL CHECK (position BETWEEN 1 AND 15),
  text           text NOT NULL CHECK (char_length(text) BETWEEN 1 AND 2000),
  option_a       text NOT NULL CHECK (char_length(option_a) BETWEEN 1 AND 500),
  option_b       text NOT NULL CHECK (char_length(option_b) BETWEEN 1 AND 500),
  option_c       text NOT NULL CHECK (char_length(option_c) BETWEEN 1 AND 500),
  option_d       text NOT NULL CHECK (char_length(option_d) BETWEEN 1 AND 500),
  correct_option char(1) NOT NULL CHECK (correct_option IN ('A', 'B', 'C', 'D')),
  marks          integer NOT NULL DEFAULT 1 CHECK (marks BETWEEN 0 AND 100),
  image_url      text CHECK (image_url IS NULL OR image_url ~ '^https://'),
  category       text,
  created_at     timestamptz NOT NULL DEFAULT now(),
  updated_at     timestamptz NOT NULL DEFAULT now(),
  UNIQUE (competition_id, position)
);

-- ---------------------------------------------------------------------------
-- Competition participants (one registration per user per competition)
-- ---------------------------------------------------------------------------
CREATE TABLE competition_participants (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  competition_id uuid NOT NULL REFERENCES competitions(id) ON DELETE CASCADE,
  user_id        uuid NOT NULL REFERENCES users(id),
  registered_at  timestamptz NOT NULL DEFAULT now(),
  started_at     timestamptz,
  completed_at   timestamptz,
  status         text NOT NULL DEFAULT 'registered'
                   CHECK (status IN ('registered', 'in_progress', 'completed', 'absent', 'disqualified')),
  UNIQUE (competition_id, user_id)
);
CREATE INDEX competition_participants_user_idx ON competition_participants (user_id, registered_at DESC);

-- ---------------------------------------------------------------------------
-- Answer submissions: one row per participant per question (UNIQUE).
-- status = 'accepted' (answer received before deadline) or 'timeout'
-- (written at finalisation for questions the participant did not answer).
-- ---------------------------------------------------------------------------
CREATE TABLE answer_submissions (
  id                bigserial PRIMARY KEY,
  competition_id    uuid NOT NULL REFERENCES competitions(id) ON DELETE CASCADE,
  participant_id    uuid NOT NULL REFERENCES competition_participants(id) ON DELETE CASCADE,
  question_id       uuid NOT NULL REFERENCES questions(id),
  question_position integer NOT NULL,
  selected_option   char(1) CHECK (selected_option IN ('A', 'B', 'C', 'D')),
  is_correct        boolean NOT NULL DEFAULT false,
  marks_awarded     integer NOT NULL DEFAULT 0,
  opened_at         timestamptz NOT NULL,
  received_at       timestamptz,
  response_ms       integer CHECK (response_ms IS NULL OR response_ms BETWEEN 0 AND 10000),
  status            text NOT NULL CHECK (status IN ('accepted', 'timeout')),
  idempotency_key   text,
  client_ip_hash    bytea,
  node_id           text,
  created_at        timestamptz NOT NULL DEFAULT now(),
  UNIQUE (participant_id, question_id),
  CHECK ((status = 'accepted' AND selected_option IS NOT NULL AND received_at IS NOT NULL AND response_ms IS NOT NULL)
      OR (status = 'timeout' AND selected_option IS NULL AND response_ms IS NULL AND NOT is_correct AND marks_awarded = 0))
);
CREATE INDEX answer_submissions_comp_idx ON answer_submissions (competition_id, participant_id);
CREATE INDEX answer_submissions_comp_received_idx ON answer_submissions (competition_id, received_at);

-- Rejected submission attempts (late, duplicate with different option, not open, ...).
-- Used for auditing and suspicious-activity detection.
CREATE TABLE submission_rejections (
  id                bigserial PRIMARY KEY,
  competition_id    uuid NOT NULL REFERENCES competitions(id) ON DELETE CASCADE,
  user_id           uuid NOT NULL REFERENCES users(id),
  question_position integer,
  reason            text NOT NULL,
  received_at       timestamptz NOT NULL DEFAULT now(),
  client_ip_hash    bytea
);
CREATE INDEX submission_rejections_comp_idx ON submission_rejections (competition_id, user_id);

-- ---------------------------------------------------------------------------
-- Competition results (computed at finalisation; ranks are official).
-- ---------------------------------------------------------------------------
CREATE TABLE competition_results (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  competition_id   uuid NOT NULL REFERENCES competitions(id) ON DELETE CASCADE,
  participant_id   uuid NOT NULL UNIQUE REFERENCES competition_participants(id) ON DELETE CASCADE,
  total_marks      integer NOT NULL,
  attempted_count  integer NOT NULL,
  correct_count    integer NOT NULL,
  incorrect_count  integer NOT NULL,
  unanswered_count integer NOT NULL,
  correct_time_ms  bigint NOT NULL,
  total_time_ms    bigint NOT NULL,
  completed_at     timestamptz NOT NULL,
  final_rank       integer NOT NULL CHECK (final_rank >= 1),
  computed_at      timestamptz NOT NULL DEFAULT now(),
  published_at     timestamptz,
  CHECK (correct_count + incorrect_count + unanswered_count = 15)
);
CREATE INDEX competition_results_rank_idx ON competition_results (competition_id, final_rank);

-- ---------------------------------------------------------------------------
-- Audit log (append-only)
-- ---------------------------------------------------------------------------
CREATE TABLE audit_logs (
  id          bigserial PRIMARY KEY,
  actor_type  text NOT NULL CHECK (actor_type IN ('admin', 'user', 'system')),
  actor_id    uuid,
  action      text NOT NULL,
  entity_type text,
  entity_id   text,
  metadata    jsonb NOT NULL DEFAULT '{}'::jsonb,
  ip_hash     bytea,
  created_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX audit_logs_created_idx ON audit_logs (created_at DESC);
CREATE INDEX audit_logs_entity_idx ON audit_logs (entity_type, entity_id);

CREATE FUNCTION audit_logs_append_only() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION 'audit_logs is append-only';
END $$;
CREATE TRIGGER audit_logs_no_update BEFORE UPDATE OR DELETE ON audit_logs
  FOR EACH ROW EXECUTE FUNCTION audit_logs_append_only();

-- ---------------------------------------------------------------------------
-- Notifications (outbox: in-app always, SMS when configured + authorised)
-- ---------------------------------------------------------------------------
CREATE TABLE notifications (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id        uuid NOT NULL REFERENCES users(id),
  competition_id uuid REFERENCES competitions(id) ON DELETE CASCADE,
  kind           text NOT NULL,
  channel        text NOT NULL CHECK (channel IN ('in_app', 'sms')),
  body           text NOT NULL,
  status         text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'failed', 'skipped')),
  attempts       integer NOT NULL DEFAULT 0,
  dedupe_key     text NOT NULL UNIQUE,
  created_at     timestamptz NOT NULL DEFAULT now(),
  sent_at        timestamptz,
  read_at        timestamptz
);
CREATE INDEX notifications_user_idx ON notifications (user_id, created_at DESC);
CREATE INDEX notifications_pending_idx ON notifications (status, channel) WHERE status = 'pending';

-- ---------------------------------------------------------------------------
-- Fairness guard: the question set and scoring rules are immutable once a
-- competition has started (or has been frozen). Enforced in the database so
-- that no code path (or manual SQL) can alter a running competition.
-- ---------------------------------------------------------------------------
CREATE FUNCTION competition_is_locked(c competitions) RETURNS boolean LANGUAGE sql IMMUTABLE AS $$
  SELECT c.frozen_at IS NOT NULL
      OR c.status IN ('live', 'completed', 'cancelled')
$$;

CREATE FUNCTION guard_questions_frozen() RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
  c competitions;
BEGIN
  SELECT * INTO c FROM competitions WHERE id = COALESCE(NEW.competition_id, OLD.competition_id);
  IF FOUND AND (competition_is_locked(c) OR (c.status = 'scheduled' AND c.start_at <= now())) THEN
    RAISE EXCEPTION 'competition % is frozen; questions cannot be modified', c.id
      USING ERRCODE = 'check_violation';
  END IF;
  RETURN COALESCE(NEW, OLD);
END $$;
CREATE TRIGGER questions_frozen_guard BEFORE INSERT OR UPDATE OR DELETE ON questions
  FOR EACH ROW EXECUTE FUNCTION guard_questions_frozen();

CREATE FUNCTION guard_competition_frozen() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF competition_is_locked(OLD) AND (
       NEW.start_at          IS DISTINCT FROM OLD.start_at
    OR NEW.question_time_ms  IS DISTINCT FROM OLD.question_time_ms
    OR NEW.transition_ms     IS DISTINCT FROM OLD.transition_ms
    OR NEW.default_marks     IS DISTINCT FROM OLD.default_marks
    OR NEW.question_count    IS DISTINCT FROM OLD.question_count
    OR NEW.late_entry_allowed IS DISTINCT FROM OLD.late_entry_allowed
    OR NEW.question_set_hash IS DISTINCT FROM OLD.question_set_hash AND OLD.question_set_hash IS NOT NULL
  ) THEN
    RAISE EXCEPTION 'competition % is frozen; schedule and scoring rules cannot change', OLD.id
      USING ERRCODE = 'check_violation';
  END IF;
  IF OLD.status IN ('completed', 'cancelled') AND NEW.status IS DISTINCT FROM OLD.status THEN
    RAISE EXCEPTION 'competition % is %, status is final', OLD.id, OLD.status
      USING ERRCODE = 'check_violation';
  END IF;
  NEW.updated_at := now();
  RETURN NEW;
END $$;
CREATE TRIGGER competitions_frozen_guard BEFORE UPDATE ON competitions
  FOR EACH ROW EXECUTE FUNCTION guard_competition_frozen();
