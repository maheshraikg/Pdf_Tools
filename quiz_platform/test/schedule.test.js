import { test } from 'node:test';
import assert from 'node:assert/strict';
import { responseMs, timeline } from '../src/services/schedule.js';

const start = Date.UTC(2026, 0, 1, 10, 0, 0);
const t = timeline({ start_at: new Date(start), question_time_ms: 10_000, transition_ms: 3000, question_count: 15 });

test('each question opens on the fixed server schedule and lasts exactly 10,000 ms', () => {
  for (let p = 1; p <= 15; p++) {
    assert.equal(t.opensAt(p), start + (p - 1) * 13_000);
    assert.equal(t.closesAt(p) - t.opensAt(p), 10_000);
  }
  assert.equal(t.endsAt, start + 14 * 13_000 + 10_000);
});

test('phase boundaries: deadline is inclusive, one ms later is closed', () => {
  assert.equal(t.at(start - 1).phase, 'before');
  assert.deepEqual(t.at(start).position, 1);
  assert.equal(t.at(start + 10_000).phase, 'question');
  assert.equal(t.at(start + 10_000.001).phase, 'transition');
  assert.equal(t.at(start + 12_999).nextPosition, 2);
  assert.equal(t.at(start + 13_000).position, 2);
  assert.equal(t.at(t.closesAt(15)).position, 15);
  assert.equal(t.at(t.closesAt(15) + 1).phase, 'ended');
});

test('response time is integer milliseconds from the scheduled opening', () => {
  assert.equal(responseMs(1000, 1000), 0);
  assert.equal(responseMs(1000, 1999.999), 999);
  assert.equal(responseMs(1000, 11_000), 10_000);
  assert.equal(responseMs(1000, 999), 0);
  assert.ok(Number.isInteger(responseMs(0, 1234.56)));
});
