// Pure, deterministic timing model shared by every node.
//
// A live competition follows one server-controlled timeline that is derived
// only from frozen competition fields, so every node (and every reconnecting
// client) computes exactly the same schedule without coordination:
//
//   question p (1..15) opens at   start + (p-1) * (questionTime + transition)
//   question p closes at          opensAt(p) + questionTime          (10,000 ms)
//   competition ends at           closesAt(15)
//
// Official response time = server receipt time − opensAt(p), in integer ms.
// An answer is accepted iff opensAt(p) <= receivedAt <= closesAt(p).

export const QUESTION_COUNT = 15;
export const QUESTION_TIME_MS = 10_000;

export function timeline(comp) {
  const start = toMs(comp.start_at ?? comp.startAt);
  const q = comp.question_time_ms ?? comp.questionTimeMs ?? QUESTION_TIME_MS;
  const gap = comp.transition_ms ?? comp.transitionMs ?? 3000;
  const count = comp.question_count ?? comp.questionCount ?? QUESTION_COUNT;
  const slot = q + gap;
  const opensAt = (p) => start + (p - 1) * slot;
  const closesAt = (p) => opensAt(p) + q;
  return {
    start,
    questionTimeMs: q,
    transitionMs: gap,
    count,
    opensAt,
    closesAt,
    endsAt: closesAt(count),
    /**
     * Phase at time t:
     *   { phase: 'before' }
     *   { phase: 'question', position, opensAt, closesAt }
     *   { phase: 'transition', nextPosition, nextOpensAt, lastPosition }
     *   { phase: 'ended' }
     */
    at(t) {
      if (t < start) return { phase: 'before', nextPosition: 1, nextOpensAt: start };
      const idx = Math.floor((t - start) / slot); // 0-based
      if (idx >= count) return { phase: 'ended' };
      const p = idx + 1;
      const o = opensAt(p);
      if (t <= o + q) return { phase: 'question', position: p, opensAt: o, closesAt: o + q };
      if (p >= count) return { phase: 'ended' };
      return { phase: 'transition', lastPosition: p, nextPosition: p + 1, nextOpensAt: opensAt(p + 1) };
    },
  };
}

/** Elapsed response time in integer milliseconds (floor), clamped to [0, questionTime]. */
export function responseMs(opensAt, receivedAt, questionTimeMs = QUESTION_TIME_MS) {
  return Math.min(questionTimeMs, Math.max(0, Math.floor(receivedAt - opensAt)));
}

function toMs(v) {
  if (typeof v === 'number') return v;
  if (v instanceof Date) return v.getTime();
  return Date.parse(v);
}
