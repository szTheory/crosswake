---
id: SEED-024
title: Phase 190 review residue
status: dormant
severity: medium
trigger_when: >-
  Surface before the next twin run (the residual proof-lane and gate-script items), and
  again before the physical-iPhone run resumes (the git-version and layout items).
  NOT blocking today: the findings that could pass while checking nothing were fixed in
  Phase 191; what remains is hardening and documentation.
created: 2026-10-19
related: [SEED-023]
---

# SEED-024: Phase 190 review residue

Phase 191 fixed or closed eleven of the fifteen Phase 190 review findings. The items below were
deliberately deferred, each with a trigger, so they are not forgotten.

## Before the next twin run

- WR-02: the main claim was refuted, because the exit handler (mark_exited) already catches a
  registry exit after start. Only the exit during spawn-time registration remains. Done looks like
  that one call being guarded so it reaches the verdict instead of crashing, with a test.
- WR-08: two gate checks in the run-once gate script can pass while checking nothing. Done looks
  like each check failing on an empty or missing input, proven by a failing control.
- IN-01: the twin producers re-implement the shared git environment builder instead of calling it.
  Done looks like one builder with one caller path.
- IN-03: the gate deadline is checked only after every step finishes. Done looks like the deadline
  being checked between steps so an overrun stops early.
- The temporary-folder path comparison: text comparisons treat the short and the resolved forms of
  the system temporary folder as different. Done looks like comparing resolved paths.

## Before the physical-iPhone run resumes

- WR-03: provenance needs a recent git, with no version guard, and one new test passes vacuously on
  older git. The test half was fixed in Phase 191. Done looks like a version guard or a distinct
  failure cause, and documenting git 2.41 as the proof-lane floor.
- WR-04: a nested host looks the same as "no git". Done looks like a distinct cause for the nested
  case and a short doc stating the supported layout.
- IN-04: confirm the origin check fails closed when the generated shell folder is missing. Done
  looks like a test that proves a missing folder is a failure, not a pass.

## Accepted as designed

- WR-04: a nested host cannot carry a commit, by design (Phase 190 D-07). Only the doc and the
  distinct cause above are open.
- IN-04, the hard-coded counts in self-tests: they fail loudly when the set changes, so they stay.

## Source

- 190-REVIEW.md and its disposition file.
- 191-CONTEXT.md, decision D-17c.
