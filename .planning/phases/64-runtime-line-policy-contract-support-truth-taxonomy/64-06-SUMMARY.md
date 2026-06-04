---
phase: 64-runtime-line-policy-contract-support-truth-taxonomy
plan: "06"
requirements-completed: []
subsystem: support-matrix / doctor / evidence-taxonomy
tags: [gap-closure, honesty, rline-04, wr-04, evidence-taxonomy, rebuild-matrix, finding-policy]
dependency_graph:
  requires: [64-01, 64-04, 64-05]
  provides: [rline-04-satisfied, honest-doctor-status, rebuild-matrix-evidence-gate]
  affects: [support_matrix.ex, doctor.ex, finding_policy.ex, phase64_runtime_line_policy_test.exs, doctor_test.exs]
tech_stack:
  added: []
  patterns: [tdd-red-green, validate-pipe-guard, rescue-mix-error-hermetic-pattern]
key_files:
  created: []
  modified:
    - lib/crosswake/support_matrix/support_matrix.ex
    - lib/crosswake/doctor/doctor.ex
    - lib/crosswake/doctor/finding_policy.ex
    - test/crosswake/proof/phase64_runtime_line_policy_test.exs
    - test/crosswake/doctor/doctor_test.exs
    - test/crosswake/support_matrix/support_matrix_test.exs
decisions:
  - "Removed 2.x @rebuild_matrix_rows entry (evidence_tier: :device_verified) unconditionally — the 2.x band does not exist in Phase 64; re-introduction requires passing the new validate_rebuild_matrix_evidence/2 gate"
  - "Structural gate rejects :device_verified rebuild_matrix rows unconditionally in Phase 64 since device-verified promotion evidence is gated until Phases 67/68 per D-19"
  - "Fixed WR-05 lying comment: evidence_posture_snapshot/1 comment now accurately states it is a fixed Phase-64 posture map, not derived from rebuild_matrix at runtime"
  - "Reverted finding_policy.ex :verification_required severity to :error (honest blocking posture) per RLINE-04 goal"
  - "Used rescue Mix.Error inside capture_io blocks (Phase 52 precedent) rather than relaxing severity"
metrics:
  duration: "406s (~6m)"
  completed: "2026-06-04"
  tasks_completed: 3
  files_changed: 6
requirements_completed: [RLINE-04]
---

# Phase 64 Plan 06: Gap Closure (RLINE-04 / WR-04) Summary

Gap closure plan that closes two BLOCKER honesty violations found by the Phase 64 verifier (status: gaps_found, 4/5 must-haves): removed the unbacked 2.x rebuild_matrix row, added a structural evidence gate, rescued Mix.Error in hermetic proof tests, and restored :error severity for unverified-host doctor findings.

## Objective

Close the two BLOCKER gaps found by the Phase 64 verifier:

- **Gap 1 (CR-01 / RLINE-04):** Evidence laundering via unvalidated rebuild_matrix surface — the `@rebuild_matrix_rows` "2.x" row hardcoded `evidence_tier: :device_verified` with no backing proof and no validate/1 coverage.
- **Gap 2 (WR-04):** `finding_policy.ex` downgraded `:verification_required` findings from `:error` to `:warning`, flipping `mix crosswake.doctor` to `status: :ok` for unverified hosts.

## Tasks Completed

| Task | Name | Commit | Key Files |
|------|------|--------|-----------|
| 1 | Remove unbacked 2.x row + add structural rebuild_matrix evidence gate | 74e8e7c | support_matrix.ex, doctor.ex, support_matrix_test.exs |
| 2 | Close rebuild_matrix proof blind spot + rescue Mix.Error in doctor proof tests | f48020a | phase64_runtime_line_policy_test.exs |
| 3 | Revert finding severities to :error + lock honest doctor posture in unit tests | bfbc6ec | finding_policy.ex, doctor_test.exs |

## What Was Built

### Task 1: Structural Evidence Gate (Gap 1, RLINE-04)

**`lib/crosswake/support_matrix/support_matrix.ex`:**
- Removed the entire "2.x" `Types.new_runtime_line_row(...)` entry from `@rebuild_matrix_rows` (the one with `evidence_tier: :device_verified`). Only the "1.x" row (`evidence_tier: :jvm_hermetic`) remains.
- Added `validate_rebuild_matrix_evidence/2` private function mirroring `validate_verification_method_invariant/2`: reduces over `support_matrix.rebuild_matrix`, rejects any row with `evidence_tier == :device_verified`, returns error map with `%{key: :rebuild_matrix, message: "..evidence laundering (D-10a)...", hint: ":device_verified requires real-device proof gated until Phases 67/68"}`.
- Appended `|> validate_rebuild_matrix_evidence(support_matrix)` to the `validate/1` pipe after `validate_verification_method_invariant(support_matrix)`.

**`lib/crosswake/doctor/doctor.ex`:**
- Fixed WR-05 lying comment in `evidence_posture_snapshot/1`: the old comment said "derived from the rebuild_matrix evidence_tier values" but the function discards its argument. New comment honestly states it is a fixed Phase-64 posture map and documents when/how it should be derived dynamically (Phases 67/68).

**`test/crosswake/support_matrix/support_matrix_test.exs`:**
- Added 5 unit tests (RED→GREEN TDD): canonical has only 1.x row; no :device_verified row; validate/1 returns [] for canonical; validate/1 rejects :device_verified injection; validate/1 accepts :jvm_hermetic/:none rows without false positive.

### Task 2: Proof Blind Spot Closure (Gap 1 test coverage)

**`test/crosswake/proof/phase64_runtime_line_policy_test.exs`:**
- Added `:rline_04` tagged test asserting `SupportMatrix.rebuild_matrix(SupportMatrix.canonical())` has no `:device_verified` row (stable id: `proof.rline_04.rebuild_matrix.no_unbacked_device_verified`). Closes the blind spot where existing tests only asserted against `capability_families`.
- Added `:rline_04` tagged test injecting a `:device_verified` row into canonical's rebuild_matrix and asserting `validate/1` returns non-empty errors (stable id: `proof.rline_04.validate.rebuild_matrix_rejects_device_verified`). Locks the structural gate.
- Wrapped all 7 `Mix.Task.run` calls against `ManagedRouter` in `try/rescue Mix.Error` inside the `capture_io` fn, using the Phase 52 hermetic pattern. This allows the proof lane to run green regardless of whether severity is `:error` or `:warning` — the rescue is the fix, not severity relaxation.

Phase64 proof lane: 18 → 20 tests, all passing.

### Task 3: Honest Doctor Posture (Gap 2, WR-04)

**`lib/crosswake/doctor/finding_policy.ex`:**
- Reverted `shell_proof(:verification_required, ...)` first tuple element from `:warning` to `:error`.
- Reverted `support_claim(:verification_required)` first tuple element from `:warning` to `:error`.
- Key and message strings unchanged (`"proof_hook_verification_required"`, `"support_claim_verification_required"`).

**`test/crosswake/doctor/doctor_test.exs`:**
- Reverted `assert report.status == :ok` to `assert report.status == :error` in the verification_required test.
- Replaced misleading Phase-64 comment (which normalized the WR-04 regression) with honest posture description.
- Added compensating test: `write_proof_hook!(target, "android", 1, "android proof failed")` → `Doctor.run` → asserts `report.status == :error` and `proof_hook_failed` finding present. Locks the honest posture.

doctor_test.exs: 21 → 22 tests, all passing.

## Verification Results

| Check | Result |
|-------|--------|
| `mix test test/crosswake/proof/phase64_runtime_line_policy_test.exs` | 20 tests, 0 failures |
| `mix test test/crosswake/support_matrix/ test/crosswake/doctor/doctor_test.exs` | 62 tests, 0 failures |
| `mix compile --warnings-as-errors` | exits 0 |
| `grep -c 'evidence_tier=device-verified' doctor output` | 0 (no device-verified rendered for unbacked band) |
| `mix crosswake.doctor` exit code for unverified host | non-zero (Mix.Error on status: :error) |
| Full suite regression | 793 tests; 3 pre-existing failures in MilestoneTransitionResetTest (unrelated to this plan — confirmed pre-existing at commit 8baf8bd) |

## Deviations from Plan

None - plan executed exactly as written.

All three tasks followed TDD (RED → GREEN):
- Task 1: 5 unit tests added; compiled and 3 failed (RED) → implementation → 0 failures (GREEN)
- Task 2: 2 new :rline_04 tests; rescue pattern added to 7 capture_io blocks → all passing
- Task 3: doctor_test.exs reverted to :error (1 failure RED) → finding_policy.ex reverted → 0 failures (GREEN)

## Known Stubs

None. All behavioral gaps are fully closed.

## Threat Flags

No new security-relevant surface introduced. This plan only removes an overclaim vector (T-64-01, T-64-02, T-64-03, T-64-04 from threat register) and restores the correct blocking posture.

## Self-Check: PASSED

- `lib/crosswake/support_matrix/support_matrix.ex` — modified (validates rebuild_matrix, 2.x row removed)
- `lib/crosswake/doctor/doctor.ex` — modified (honest comment)
- `lib/crosswake/doctor/finding_policy.ex` — modified (:error severity restored)
- `test/crosswake/proof/phase64_runtime_line_policy_test.exs` — modified (2 new tests, 7 rescues)
- `test/crosswake/doctor/doctor_test.exs` — modified (:error assertion, compensating test)
- `test/crosswake/support_matrix/support_matrix_test.exs` — modified (5 new unit tests)
- All commits verified: 74e8e7c, f48020a, bfbc6ec
