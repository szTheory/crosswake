---
phase: 195-pipeline-repair-and-hygiene
plan: 14
subsystem: infra
tags: [ci, secret-masking, node-test, gap-closure]
requires:
  - phase: 195-04
    provides: maskSecretShapes and the first secret-masking tests
provides:
  - "maskSecretShapes rewritten: quoted/multi-word/escaped/unterminated values, mid-line Cookie/Set-Cookie and any Authorization header to end of line, URL userinfo, JWT, AWS access key ID; prose without a separator untouched; linear time"
  - "test/js/ci_secret_masking.test.mjs: GAP_SHAPES (24 seeds), PROSE_LINES, LINEAR_INPUTS, byte-window test, WR-03 fixtures, stricter isMaskLine"
affects: [195-15]
requirements-completed: [REL-03]
actuals:
  tokens: 26000
  tasks: 3
  commits: 6
  plan_head_before: ff63e5d84f459cb89f65e28a0bea7a87eb81d042
  plan_head_after: 7db34f20345d61370ca975e3d7222dfa94c61b4e
completed: 2026-10-26
status: complete
---

# Phase 195 Plan 14: Secret-mask gap closure Summary

**The root-proof failure tail now masks quoted, multi-word, mid-line header, Digest, URL-userinfo, JWT and access-key-ID shapes in linear time without masking plain prose, each proven by a test that was red first and by a mask-removed control (24 of 24 seeds leak) and a pre-fix-masker control (25 failures).**

Branch `fix/secret-mask-quoted-shapes` (local only, not pushed; three `test(ci):` red commits then three `fix(ci):` commits, branched from origin/main ff63e5d). Evidence is committed on `docs/195-closeout` (6274372).

## Commits

Fix branch: b568bb0 (red task 1), 4bcf7c2 (fix task 1), 99ce22d (red task 2), 22a786e (fix task 2), 49a3280 (red task 3), 7db34f2 (fix task 3). Closeout branch: 6274372 (evidence).

## Results

- Task 1 red: rc 1, 3 failures (both access-key rows, spawned-child gap test), 0 seed hits in the log. Green: 15 pass. Mask-removed control: rc 1, `leaked: 2 of 2`.
- Task 2 red: rc 1, 23 failures (13 gap rows, spawned-child test, 7 prose over-masking rows, blank_lines at about 17.6 s and whitespace_lines at about 14.5 s). Green: 46 pass; every linear input now takes 0-5 ms (budget 1500 ms). `repository_verification` rc 0 (41 pass).
- Task 3 red: both WR-03 fixtures failed. Green: 49 pass. Final mask-removed control: `leaked: 24 of 24`. Pre-fix masker: rc 1, 25 failures. Full JS suite: rc 0, 186 pass, 0 fail.
- Every red, control and pre-fix log: 0 seed-prefix hits. Privacy scan on the two sources and the two evidence files: clean.

## Deviations from Plan

**1. [Rule 3 - Blocking] Privacy scan invocation.** The scan has to run under `bash`; under the harness's zsh it exits 2 on `BASH_SOURCE`. Ran it with `bash`, as the plan text says.

**2. [Rule 3 - Blocking] Plan commit ledger not created.** The sequential dispatch skipped the 0c ledger; `plan_head_before` is origin/main at branch creation (ff63e5d), `plan_head_after` the fix-branch tip. The `commits: 6` counts the fix branch; the evidence commit on the closeout branch is a seventh.

**3. [Rule 1 - Design] Unrolled quote loop.** The quoted-value pattern uses an unrolled loop (`[^"\\\n]*(?:\\[^\n]?[^"\\\n]*)*`) rather than a nested alternation star, so a 300,000-character backslash run masks in 2 ms.

No package installs were needed.

## Known Stubs

None.

## Threat Flags

None. No new endpoint, auth path or trust-boundary surface.

## Notes

- The byte-window test (mask before truncate) passes against the unfixed masker too; it is a regression pin and not in the red failing list.
- Assertions that can see a seed are `assert.ok` on a computed boolean with a shape-and-count message, so a red CI log cannot print a seed.
- Plan 195-15 ships the branch.

## Self-Check: PASSED
