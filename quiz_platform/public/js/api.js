// API client + server clock synchronisation.
export class ApiError extends Error {
  constructor(status, code, message, details) {
    super(message);
    this.status = status;
    this.code = code;
    this.details = details;
  }
}

export async function api(method, url, body, { timeoutMs = 10_000 } = {}) {
  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), timeoutMs);
  let res;
  try {
    res = await fetch(url, {
      method,
      credentials: 'same-origin',
      headers: {
        ...(body !== undefined ? { 'Content-Type': 'application/json' } : {}),
        'X-Requested-With': 'quiz-app',
      },
      body: body !== undefined ? JSON.stringify(body) : undefined,
      signal: ctrl.signal,
    });
  } catch (err) {
    throw new ApiError(0, 'network', navigator.onLine === false ? 'You are offline' : 'Network error. Check your connection.');
  } finally {
    clearTimeout(timer);
  }
  let data = null;
  try { data = await res.json(); } catch { /* empty body */ }
  if (!res.ok) {
    const e = data?.error ?? {};
    throw new ApiError(res.status, e.code ?? 'error', e.message ?? `Request failed (${res.status})`, e.details);
  }
  return data;
}

// ---- Server clock ----------------------------------------------------------
// The client never decides deadlines; it only needs a smooth estimate of the
// server clock to render the countdown. We use NTP-style sampling (keeping
// the lowest round-trip sample) and a monotonic local clock (performance.now)
// so that changing the phone's time has no effect.
const mono = () => performance.timeOrigin + performance.now();
let offset = 0; // serverNow ≈ mono() + offset
let bestRtt = Infinity;
let synced = false;

export function serverNow() { return mono() + offset; }
export function isSynced() { return synced; }

export function addTimeSample(t0, serverTime, t1) {
  const rtt = t1 - t0;
  // Prefer low-latency samples; accept newer samples if they are close to the best.
  if (rtt <= bestRtt * 1.5 || !synced) {
    offset = serverTime - (t0 + t1) / 2;
    bestRtt = Math.min(bestRtt, rtt);
    synced = true;
  }
}

export async function syncClock(samples = 4) {
  for (let i = 0; i < samples; i++) {
    const t0 = mono();
    try {
      const r = await api('GET', '/api/time', undefined, { timeoutMs: 4000 });
      addTimeSample(t0, r.serverNow, mono());
    } catch { /* keep previous estimate */ }
  }
  bestRtt *= 1.2; // let the estimate adapt slowly to changing networks
}

export const monoNow = mono;
