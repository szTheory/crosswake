---
phase: 181-core-host-command-seam
plan: 07
subsystem: gate-preflight
tags: [preflight, phase180-gate, regression, android-freeze]
requires: [181-06]
provides:
  - 181-PREFLIGHT.json (schema crosswake.phase181.gate_preflight/1), expected_verdict existing_path_supported
key-files:
  modified:
    - lib/mix/tasks/crosswake.gen.shell.ex
    - test/mix/tasks/crosswake_gen_shell_host_commands_test.exs
status: complete
actuals:
  tokens: 6000
  tasks: 3
  commits: 1
plan_head_before: b9ad8854f2fb9eef4040a917151e2e205c38eac5
plan_head_after: 7aca4bf887cc3340ada12022d5f1f39eedd013ab
candidate: /private/tmp/crosswake-phase181-impl
completed: 2026-10-14
---

# Phase 181 Plan 07: Gate preflight and full regression

The pinned Phase 180 gate, copied unchanged, run against the core head and then deleted, reports what a successful seam should report: every gate fact is refuted, every control passes, every invariant holds. Android, vectors, fixtures and lockfiles are byte-identical to base, and every suite is green. Expected verdict: existing_path_supported. This is a read-only preflight, not the authoritative 180-01 rerun, and it is not TWIN progress.

## Orchestrator-directed fix (not counted against the repair budget)

Commit `7aca4bf` fix(181-07): limit local package reference to declaring routers.

- Problem: 181-04 made every host-config iOS generation in a cwd containing packages/crosswake-shell-core-ios render the local package reference, even for routers with no host commands.
- Fix (inside repair scope): `crosswake.gen.shell` now passes the local reference only when the package exists AND the compiled manifest has at least one route with host commands (read from the rendered manifest bytes). Non-declaring routers render the remote reference exactly as at base. The gate context is unchanged and still only consulted for declaring routers, so it stays coherent with the rendered reference.
- Tests added in crosswake_gen_shell_host_commands_test.exs: non-declaring router in a cwd with the local package renders the remote reference (no local reference, no relativePath); declaring router in the same setup renders the local reference. crosswake_gen_shell_host_test.exs stays green.
- 181-04 verify commands rerun: shell + gen.shell tests 102 tests, 0 failures; doctor + manifest immutability 93 tests, 0 failures; manifest contract script exit 0; full root suite and ownership check in the regression below.
- Not separately demonstrated: I did not run the new non-declaring test against the pre-fix code.

## Preflight outcomes (env PHASE180_BASE_KIND=authorized_seam_rerun, PHASE180_PROBE_ROUTE=offline-study)

Pinned file SHA-256 values matched 180-GATE.json and 181-CANDIDATE.json in the source, and again after copy.

| Fact | Control | Gate |
| --- | --- | --- |
| G1 validator accepts host command | passed | refuted |
| G2 activation carries command | passed | refuted |
| G3 shell session carries command | passed | refuted |
| G4 offline island admitted | passed | refuted |
| G6 route declares host capability (non-gating) | passed | refuted |

Invariants G2_nondeclaring_clean, G2_probe_matches_declaration, G3_no_manufacture, G3_deny_absent: all held. Export run passed.

Tasks 1 and 2 were run in one copy-run-delete cycle (G4 first as the tracer, then the rest) rather than two separate copy cycles; the end state and recorded evidence are the same.

## Regression on candidate head 7aca4bf

- android_freeze (Android, both vector files, example Fixtures): git diff exit 0
- lockfiles: exit 0
- Root suite `mix test --seed 0`: 2208 tests, 0 failures (78 excluded)
- Example host: 150 tests, 0 failures
- Swift: 80 tests, 0 failures
- Example host xcodebuild: BUILD SUCCEEDED
- check_exunit_ownership: exit 0; manifest contract script: exit 0; contract_drift_test: 6 tests, 0 failures

## Repair attempts

None needed from the plan's budget (0 of 2 used).

## Deviations from Plan

- Orchestrator-directed gen.shell fix above (one extra commit, in repair scope).
- Preflight Tasks 1 and 2 merged into one cycle (see above).
- `mix format --check-formatted` pre-existing failure on native_shell_upgrade_test.exs left alone.

## State checks

Candidate tree clean; no pinned copy remains. Phase 180 candidate still HEAD 96e5a63 with no tracked change and its three untracked gate files hash-identical. Recovery checkout: no git mutation, no product edit (only planning files written). Nothing pushed.

## Known Stubs

None.

## Next action

181-08 (docs and guides). 181-10 must re-run this preflight on the final head.

## Self-Check: PASSED
