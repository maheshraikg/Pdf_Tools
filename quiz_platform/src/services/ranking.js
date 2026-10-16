// Official ranking rules (applied in this exact order, deterministic):
//   1. Highest total marks
//   2. Lowest cumulative response time of CORRECT answers (ms)
//   3. Lowest cumulative response time of ALL ANSWERED questions (ms)
//   4. Earliest server-recorded completion time
// Participants equal on every criterion share the same rank (standard
// competition ranking "1, 1, 3"). No randomness, no client timestamps.

export function compareStandings(a, b) {
  return (
    b.totalMarks - a.totalMarks ||
    a.correctTimeMs - b.correctTimeMs ||
    a.totalTimeMs - b.totalTimeMs ||
    a.completedAtUs - b.completedAtUs
  );
}

/**
 * @param {Array<{totalMarks:number, correctTimeMs:number, totalTimeMs:number, completedAtUs:number}>} rows
 * @returns rows sorted with `rank` assigned (new objects).
 */
export function rankStandings(rows) {
  const sorted = rows.map((r) => ({ ...r })).sort((a, b) => compareStandings(a, b) || tieBreakStable(a, b));
  let rank = 0;
  for (let i = 0; i < sorted.length; i++) {
    if (i === 0 || compareStandings(sorted[i - 1], sorted[i]) !== 0) rank = i + 1;
    sorted[i].rank = rank;
  }
  return sorted;
}

// Display order only (never affects rank): registration id, then participant id.
function tieBreakStable(a, b) {
  const ka = `${a.registrationId ?? ''}|${a.participantId ?? ''}`;
  const kb = `${b.registrationId ?? ''}|${b.participantId ?? ''}`;
  return ka < kb ? -1 : ka > kb ? 1 : 0;
}
