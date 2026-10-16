import { test } from 'node:test';
import assert from 'node:assert/strict';
import { rankStandings } from '../src/services/ranking.js';

const row = (id, totalMarks, correctTimeMs, totalTimeMs = correctTimeMs, completedAtUs = 1_000_000) =>
  ({ registrationId: id, totalMarks, correctTimeMs, totalTimeMs, completedAtUs });

test('specification example: score first, then correct-answer time', () => {
  const ranked = rankStandings([
    row('C', 14, 12_800),
    row('B', 15, 19_120),
    row('A', 15, 18_450),
  ]);
  assert.deepEqual(ranked.map((r) => [r.registrationId, r.rank]), [['A', 1], ['B', 2], ['C', 3]]);
});

test('first tie-breaker: lower cumulative correct-answer time wins', () => {
  const ranked = rankStandings([row('slow', 10, 30_001, 30_001), row('fast', 10, 30_000, 90_000)]);
  assert.deepEqual(ranked.map((r) => r.registrationId), ['fast', 'slow']);
  assert.deepEqual(ranked.map((r) => r.rank), [1, 2]);
});

test('second tie-breaker: lower total answered time when correct time ties', () => {
  const ranked = rankStandings([row('X', 10, 30_000, 45_000), row('Y', 10, 30_000, 44_999)]);
  assert.deepEqual(ranked.map((r) => r.registrationId), ['Y', 'X']);
});

test('third tie-breaker: earliest server completion time', () => {
  const ranked = rankStandings([row('late', 10, 30_000, 40_000, 2_000_001), row('early', 10, 30_000, 40_000, 2_000_000)]);
  assert.deepEqual(ranked.map((r) => [r.registrationId, r.rank]), [['early', 1], ['late', 2]]);
});

test('identical on every criterion => same rank, next rank skips (1,1,3)', () => {
  const ranked = rankStandings([
    row('P', 12, 20_000, 25_000, 5),
    row('Q', 12, 20_000, 25_000, 5),
    row('R', 11, 1_000, 1_000, 1),
    row('S', 15, 50_000, 50_000, 9),
  ]);
  assert.deepEqual(ranked.map((r) => [r.registrationId, r.rank]), [['S', 1], ['P', 2], ['Q', 2], ['R', 4]]);
});

test('ranking is deterministic regardless of input order and never random', () => {
  const rows = [];
  for (let i = 0; i < 500; i++) rows.push(row(`U${String(i).padStart(3, '0')}`, i % 16, (i * 7919) % 50_000, 60_000, i % 3));
  const a = rankStandings(rows);
  const b = rankStandings([...rows].reverse());
  const c = rankStandings([...rows].sort(() => 0.5 - Math.random()));
  assert.deepEqual(a, b);
  assert.deepEqual(a, c);
  for (let i = 1; i < a.length; i++) {
    assert.ok(a[i - 1].totalMarks >= a[i].totalMarks);
    assert.ok(a[i - 1].rank <= a[i].rank);
  }
});

test('zero-score participants are still ranked by the same rules', () => {
  const ranked = rankStandings([row('none', 0, 0, 0, 10), row('wrong', 0, 0, 8_000, 5)]);
  assert.deepEqual(ranked.map((r) => r.registrationId), ['none', 'wrong']);
});
