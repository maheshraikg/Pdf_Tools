# Official timing, scoring and ranking policy

This document is the published fairness policy. The code that implements each
rule is linked so it can be audited.

## 1. Competition format (fixed)

* Exactly **15** multiple-choice questions (A–D, one correct option).
  Enforced by `CHECK (question_count = 15)`, by `scheduleCompetition()`, and by
  the import validator.
* Exactly **10,000 ms** per question. Enforced by `CHECK (question_time_ms = 10000)`.
* A configurable pause between questions (default 3 s, 1–30 s) is used to show
  "answer locked" and, if enabled, the correct answer. It never affects the 10 s.

## 2. The server-controlled timeline

Every question opens at an instant derived **only** from frozen competition data
(`src/services/schedule.js`):

```
opensAt(p)  = start + (p − 1) × (10,000 ms + pause)
closesAt(p) = opensAt(p) + 10,000 ms
```

All server nodes compute the same timeline, so there is no per-participant
"timer" that could be reset, paused, or extended:

* Refreshing the page, reopening the app, or reconnecting returns the **same**
  `closesAt`. (Test: *refresh / reconnect restores state without resetting the timer*.)
* A network outage does not extend the deadline. Questions that close while a
  participant is offline are recorded as unanswered.
* Participants who join late (if the competition allows late entry) receive only
  the current and later questions; earlier questions are unanswered.
  If late entry is disabled, nobody may enter after question 1 closes.

The question content is only sent to clients once the question is open (pushed
over WebSocket at `opensAt`, or returned by `/state` while open). The correct
option is never part of any participant payload while the competition runs.

## 3. Measuring response time

**Official measurement:** response time = *server receipt time of a valid answer*
− *the question's scheduled opening time* (`opensAt`), floored to integer
milliseconds and stored in `answer_submissions.response_ms`.

* The receipt timestamp is taken **first thing** in the request handler
  (`Engine.submit`), before any database work, so server-side processing never
  counts against the participant.
* The server clock is a monotonic high-resolution clock (`performance.now()`)
  anchored to UTC and slewed gently when NTP adjusts the system clock
  (`src/lib/clock.js`). It never runs backwards within a process.
* Timestamps are stored as `timestamptz` (microsecond precision, UTC). Both
  `opened_at` and `received_at` are kept for audit.
* The participant's device clock is **never** used for scoring or deadlines. The
  client only estimates the server clock (NTP-style sync) to draw a smooth
  countdown.

**Acceptance window:** an answer is accepted if and only if
`opensAt ≤ receivedAt ≤ closesAt` (the 10,000 ms boundary is inclusive;
10,000.001 ms is late). Late or early answers are rejected and logged in
`submission_rejections`.

**Known, documented limitation.** Network latency between the participant and
the server is included in the measured time, in both directions: the question
reaches a participant a few tens of milliseconds after `opensAt`, and their
answer takes a few tens of milliseconds to arrive. Measuring on the device would
remove this but would let a modified client report any time it likes, so the
server measurement is used. For in-venue events, participants on the same
network experience near-identical latency. In the load test, the median delay
between the scheduled opening and the push arriving at a client is reported
(see `docs/LOAD_TESTING.md`).

**Multiple nodes.** All nodes must keep their clocks synchronised with NTP
(chrony/systemd-timesyncd; cloud VMs do this by default, typically < 1 ms skew).
Monitor clock offset in production.

## 4. One answer per question

* `UNIQUE (participant_id, question_id)` in the database makes a second scored
  answer impossible, even under concurrent requests on different nodes.
* Re-sending the **same** option (for example after a network retry) is an
  idempotent replay: the original record and its original time are returned.
* Sending a **different** option is rejected (`409 already_answered`).
* Selecting an option locks the question in the interface immediately.

## 5. Scoring

| Outcome | Marks |
|---|---|
| Correct answer | the question's marks (default **+1**, configurable per question / competition before start) |
| Incorrect answer | 0 |
| Unanswered / timeout | 0 |

Maximum score with default marks: **15**. Marks, schedule and the answer key are
**frozen** when the competition starts: the API refuses edits and database
triggers (`guard_questions_frozen`, `guard_competition_frozen`) reject any change,
including manual SQL. A SHA-256 hash of the frozen question set is stored in
`competitions.question_set_hash` for audit.

Stored per participant (`competition_results`): attempted, correct, incorrect,
unanswered counts, total marks, **correct-answer time** (sum of `response_ms` of
correct answers), **total response time** (sum over all answered questions),
completion time and final rank. Per-question `response_ms` is kept in
`answer_submissions`.

## 6. Ranking (applied in this exact order)

1. Highest **total marks**.
2. Lowest **cumulative response time of correctly answered questions** (ms).
3. Lowest **cumulative response time of all answered questions** (ms).
4. Earliest **server-recorded completion time** — the server receipt time of the
   participant's answer to question 15, or question 15's deadline if they did not
   answer it.

Participants identical on all four criteria **share the same rank** (standard
competition ranking: 1, 1, 3). There is no random tie-breaking and no use of
client timestamps. Implementation: `src/services/ranking.js`; tests:
`test/ranking.test.js`, `test/results.test.js`.

Worked example (from the specification):

| Participant | Marks | Correct time | Rank |
|---|---|---|---|
| A | 15 | 18,450 ms | 1 |
| B | 15 | 19,120 ms | 2 |
| C | 14 | 12,800 ms | 3 |

C answered faster but has fewer marks, and marks are the primary criterion.

**Eligibility.** Every registered participant who entered the competition
(opened the live quiz at least once) is ranked, including those who answered
nothing (0 marks). Registered participants who never entered are marked
`absent` and are not ranked. Disqualified participants are not ranked.

## 7. Provisional vs official results

* During the competition, standings are shown only if the organiser enabled
  "provisional standings", and they are always labelled **provisional**.
* Official results are computed automatically from verified database records when
  the last question closes (`finalizeCompetition`), and become visible to
  participants only after an administrator **publishes** them.
