// Central configuration. Every secret comes from environment variables;
// nothing sensitive is hard-coded. See .env.example for documentation.
import crypto from 'node:crypto';

function env(name, fallback) {
  const v = process.env[name];
  return v === undefined || v === '' ? fallback : v;
}

function int(name, fallback) {
  const v = env(name);
  if (v === undefined) return fallback;
  const n = Number.parseInt(v, 10);
  if (!Number.isFinite(n)) throw new Error(`${name} must be an integer`);
  return n;
}

function bool(name, fallback) {
  const v = env(name);
  if (v === undefined) return fallback;
  return ['1', 'true', 'yes', 'on'].includes(v.toLowerCase());
}

function key(name, { devFallback }) {
  const v = env(name);
  if (v) {
    const buf = Buffer.from(v, 'base64');
    if (buf.length !== 32) throw new Error(`${name} must be 32 bytes, base64 encoded`);
    return buf;
  }
  if (!devFallback) throw new Error(`${name} is required in production`);
  // Deterministic development key derived from the variable name. Never used in production.
  return crypto.createHash('sha256').update(`dev-only:${name}`).digest();
}

export function loadConfig(overrides = {}) {
  const nodeEnv = env('NODE_ENV', 'development');
  const isProd = nodeEnv === 'production';
  const devFallback = !isProd;

  const cfg = {
    nodeEnv,
    isProd,
    nodeId: env('NODE_ID', `${process.pid}`),
    host: env('HOST', '0.0.0.0'),
    port: int('PORT', 3000),
    trustProxy: bool('TRUST_PROXY', false),
    publicOrigin: env('PUBLIC_ORIGIN', 'http://localhost:3000'),
    logLevel: env('LOG_LEVEL', isProd ? 'info' : 'debug'),

    databaseUrl: env('DATABASE_URL', 'postgres://postgres@localhost:5432/quiz'),
    dbPoolMax: int('DB_POOL_MAX', 30),
    redisUrl: env('REDIS_URL'),

    keys: {
      phoneHash: key('PHONE_HASH_KEY', { devFallback }),
      phoneEnc: key('PHONE_ENC_KEY', { devFallback }),
      otp: key('OTP_HMAC_KEY', { devFallback }),
      ip: key('IP_HASH_KEY', { devFallback }),
      accessCode: key('ACCESS_CODE_KEY', { devFallback }),
    },

    defaultCountryCode: env('DEFAULT_COUNTRY_CODE', '91'),

    otp: {
      length: 6,
      ttlMs: int('OTP_TTL_SECONDS', 300) * 1000,
      maxVerifyAttempts: int('OTP_MAX_VERIFY_ATTEMPTS', 5),
      resendCooldownMs: int('OTP_RESEND_COOLDOWN_SECONDS', 30) * 1000,
      maxSendsPerPhonePerHour: int('OTP_MAX_SENDS_PER_PHONE_PER_HOUR', 5),
      maxSendsPerIpPerHour: int('OTP_MAX_SENDS_PER_IP_PER_HOUR', 30),
      maxVerifyFailuresPerPhonePerHour: int('OTP_MAX_VERIFY_FAILURES_PER_PHONE_PER_HOUR', 10),
    },

    sms: {
      provider: env('SMS_PROVIDER', isProd ? undefined : 'console'),
      senderId: env('SMS_SENDER_ID', 'QUIZAP'),
      twilio: {
        accountSid: env('TWILIO_ACCOUNT_SID'),
        authToken: env('TWILIO_AUTH_TOKEN'),
        from: env('TWILIO_FROM'),
        messagingServiceSid: env('TWILIO_MESSAGING_SERVICE_SID'),
      },
      msg91: {
        authKey: env('MSG91_AUTH_KEY'),
        otpTemplateId: env('MSG91_OTP_TEMPLATE_ID'),
        notifyTemplateId: env('MSG91_NOTIFY_TEMPLATE_ID'),
      },
    },

    session: {
      userTtlMs: int('USER_SESSION_TTL_HOURS', 24 * 7) * 3600 * 1000,
      adminTtlMs: int('ADMIN_SESSION_TTL_HOURS', 8) * 3600 * 1000,
      idleTimeoutMs: int('SESSION_IDLE_TIMEOUT_HOURS', 72) * 3600 * 1000,
      cookieSecure: bool('COOKIE_SECURE', isProd),
    },

    rateLimit: {
      globalPerIpPerMinute: int('RATE_LIMIT_GLOBAL_PER_IP_PER_MINUTE', 600),
      submitPerUserPerMinute: int('RATE_LIMIT_SUBMIT_PER_USER_PER_MINUTE', 40),
      adminLoginPerIpPer15Min: int('RATE_LIMIT_ADMIN_LOGIN_PER_IP_PER_15MIN', 10),
    },

    notifications: {
      smsEnabled: bool('NOTIFICATIONS_SMS_ENABLED', false),
      startingSoonMinutes: int('NOTIFY_STARTING_SOON_MINUTES', 15),
      smsBatchSize: int('NOTIFY_SMS_BATCH_SIZE', 50),
    },

    jobs: {
      enabled: bool('JOBS_ENABLED', true),
      lifecycleIntervalMs: int('LIFECYCLE_INTERVAL_MS', 500),
      finalizeGraceMs: int('FINALIZE_GRACE_MS', 2000),
      provisionalIntervalMs: int('PROVISIONAL_LEADERBOARD_INTERVAL_MS', 3000),
    },

    // Only for automated load tests: lets the load generator create sessions
    // without SMS. Requires an explicit secret and is refused in production.
    loadTestSecret: isProd ? undefined : env('LOAD_TEST_SECRET'),

    ...overrides,
  };

  if (isProd) {
    if (!cfg.sms.provider || cfg.sms.provider === 'console') {
      throw new Error('SMS_PROVIDER must be twilio or msg91 in production');
    }
    if (!cfg.session.cookieSecure) throw new Error('COOKIE_SECURE must be true in production');
  }
  return cfg;
}
