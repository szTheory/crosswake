---
phase: 195-pipeline-repair-and-hygiene
plan: 11
subsystem: release-verification
tags: [cleanroom, hex, maven, swiftpm, seed-003, fail-closed]
requires:
  - phase: 195-10
    provides: root allowlist guard, branch chore/root-hygiene-and-cleanroom
provides:
  - "script/verify_published_cleanroom.sh <X.Y.Z>: fail-closed three-leg published clean-room command, no clone needed"
  - "test/crosswake/release/published_cleanroom_test.exs: 12 hermetic tests"
  - "retained real 0.2.11 run, two negative controls, SEED-003 mirror-tag evidence"
affects: [195-12, 197, 199]
requirements-completed: [REL-06]
actuals:
  tokens: 45000
  tasks: 3
  commits: 3
  plan_head_before: 48da84f7afe90ebddc3fddca4eb141e28d235b9f
  plan_head_after: cb1b3871caba3df9cd57332616d16054a8302e9a
completed: 2026-10-26
status: complete
---

# Phase 195 Plan 11: Published clean-room command Summary

**One command, `script/verify_published_cleanroom.sh <version>`, resolves and verifies the Hex, Maven and iOS mirror artifacts from a throwaway directory; the real 0.2.11 run passes all three legs, and a missing or tampered artifact exits 1.**

Branch `chore/root-hygiene-and-cleanroom` (local only, nothing pushed). Commits: 3a747b38 (command skeleton, Maven leg, tests), 63556321 (Hex and iOS legs, retained runs), cb1b3871 (SEED-003 closure). `commits: 3` measured from 48da84f7.

## Results

- Real run (from a copy of the script in a scratch directory outside the checkout, toolchain passed via CLEANROOM_* env read from `.tool-versions` on the caller side): `leg hex PASS 0.2.11 checksum 2f25d0270963`, `leg maven PASS 0.2.11 aar ce617279241c`, `leg ios PASS 0.2.11 tag_commit 424ab96ede1b`, `result PASS legs hex,maven,ios version 0.2.11`, `cleanroom: rc 0`. Retained verbatim in 195-EVIDENCE/cleanroom-0.2.11-195.txt.
- Negative controls (cleanroom-negative-195.txt): `missing` (9.9.9) printed `FAIL hex|maven|ios not_published`, result FAIL, rc 1; `wrong_artifact` (real 0.2.11 Maven files with one byte appended to the .aar, selftest base) printed `FAIL maven checksum_mismatch`, rc 1. No PASS result line in either.
- Tracer step: real Maven-only run with selftest flags printed `leg maven PASS 0.2.11 aar ce617279241c` and `result SELFTEST`; no-argument run exited 2.
- Tests: `mix test test/crosswake/release/published_cleanroom_test.exs` rc 0 (11 tests at task 1, 12 at task 2). Full `mix test` rc 0 (2788 tests, 0 failures, 75 excluded). `elixir script/inventory_collection_assertions.exs --check` rc 0 (243 sites, no re-emit needed). Tracked tree clean after the run.
- RED/GREEN: the Hex selftest test was RED against the task 1 stub (`FAIL hex not_implemented`, 1 failure of 12), then moved to the task 2 test file edit per the plan and GREEN once the leg landed. Task 2 verify one-liner rc 0. Stub count (`not_implemented`) is 0.
- SEED-003: mirror tag `v0.2.11` at 424ab96ede1b92f2b751b54bce04c6e607f0f3c8; mirror tree equals monorepo `ios-core-v0.2.11:packages/crosswake-shell-core-ios` tree (b80f3bf00ef6...); push auth MIRROR_DEPLOY_KEY (release-please.yml lines 998-1011); `check_ios_mirror_parity.sh` rc 0. SEED-003 is `status: harvested` with resolved_on, resolved_by and a `## Resolution` section; diff changes the status line, adds two frontmatter lines and appends the section.
- Privacy: privacy-193.sh rc 0 on the script, test, all three evidence files and the seed. No `/Users` or `/home` string in the evidence.

## Deviations from Plan

**1. [Rule 2 - Missing critical] Added reason `fetch_failed`.** Non-404 HTTP errors and network errors during a Maven artifact fetch are reported as `FAIL maven fetch_failed` instead of being misreported as `not_published`. Fail-closed either way. Files: script/verify_published_cleanroom.sh.

**2. [Scope] Hex selftest test placed in task 2.** Per the plan; it was written in the task 1 test run, observed failing against the stub, then held back from the task 1 commit so task 1's verify is green.

**3. Test addition.** Extra hermetic tests beyond the listed behaviors: pom_mismatch, tool_unavailable (PATH without curl), and a source-scan test that the script has no checkout-relative lookups.

## Known Stubs

None.

## Threat Flags

None. The script performs only anonymous reads of public registries; hex and swift legs execute fetched code in a throwaway directory (T-195-31, accepted).

## Self-Check: PASSED

Files present: script/verify_published_cleanroom.sh (mode 100755), test/crosswake/release/published_cleanroom_test.exs, three 195-EVIDENCE files. Commits 3a747b38, 63556321, cb1b3871 are ancestors of HEAD.
