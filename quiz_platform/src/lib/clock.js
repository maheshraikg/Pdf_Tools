// Server clock used for every fairness-relevant timestamp.
//
// now() returns epoch milliseconds with sub-millisecond resolution. It is
// derived from the process's monotonic high-resolution clock
// (performance.now()) anchored to the wall clock, so it never jumps backwards
// within a process even if the system clock is stepped. The anchor is
// re-synchronised slowly (slewed) when NTP adjusts the system clock, so all
// nodes stay aligned with UTC to within NTP accuracy.
//
// Tests can replace the clock with setClock() to simulate time precisely.
import { performance } from 'node:perf_hooks';

const MAX_SLEW_PER_SYNC_MS = 0.5;

class MonotonicClock {
  constructor() {
    this.anchor = Date.now() - performance.now();
    this.last = 0;
    this.timer = setInterval(() => this.resync(), 1000);
    this.timer.unref();
  }

  resync() {
    const target = Date.now() - performance.now();
    const drift = target - this.anchor;
    if (Math.abs(drift) > 1000) {
      // Large step (e.g. VM resume): adopt it but never let time go backwards.
      this.anchor = target;
    } else if (Math.abs(drift) > 0.05) {
      this.anchor += Math.sign(drift) * Math.min(Math.abs(drift), MAX_SLEW_PER_SYNC_MS);
    }
  }

  now() {
    const t = this.anchor + performance.now();
    if (t < this.last) return this.last;
    this.last = t;
    return t;
  }
}

let impl = new MonotonicClock();

export const clock = {
  now: () => impl.now(),
  nowMs: () => Math.floor(impl.now()),
  date: () => new Date(Math.floor(impl.now())),
};

/** Replace the clock (tests only). `fn` returns epoch ms. */
export function setClock(fn) {
  impl = { now: fn };
}

export function resetClock() {
  impl = new MonotonicClock();
}

/** Converts fractional epoch ms to an ISO string with microsecond precision (for timestamptz). */
export function toPgTimestamp(ms) {
  const whole = Math.floor(ms);
  const micros = Math.min(999, Math.round((ms - whole) * 1000));
  const iso = new Date(whole).toISOString(); // 2026-01-01T00:00:00.123Z
  return `${iso.slice(0, 23)}${String(micros).padStart(3, '0').slice(0, 3)}Z`;
}
