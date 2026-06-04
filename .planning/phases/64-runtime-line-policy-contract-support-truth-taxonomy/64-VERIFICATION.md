---
phase: 64-runtime-line-policy-contract-support-truth-taxonomy
verified: 2026-06-04T03:00:00Z
status: passed
score: 5/5 must-haves verified
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 4/5
  gaps_closed:
    - "Support truth reports :jvm_hermetic distinctly from :device_verified and NEVER labels CI-only evidence as device-verified — including through the rebuild_matrix surface"
    - "Support-truth honesty posture: unverified hosts produce :error overall doctor status (WR-04 severity regression)"
  gaps_remaining: []
  regressions: []
---

# Phase 64: Runtime-Line Policy Contract & Support-Truth Taxonomy — Verification Report

**Phase Goal:** Lock the runtime-line policy and support-truth taxonomy in Elixir — the OTA-safe vs. rebuild-required change classification, the `:jvm_hermetic` vs. `:device_verified` evidence distinction, the rebuild/compatibility matrix projection, and Android promotion criteria — so no downstream surface can overclaim. Rebuild policy derived from the existing manifest `native_runtime_version` axis with no new manifest schema field.

**Verified:** 2026-06-04T03:00:00Z
**Status:** passed
**Re-verification:** Yes — after gap closure (plan 64-06)

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | For any manifest/capability/shell change, the policy classifies it as OTA-safe or rebuild-required per change class (8 classes) — verifiable via Crosswake.RuntimeLine.RebuildPolicy and hermetic proof | ✓ VERIFIED | `lib/crosswake/runtime_line/rebuild_policy.ex` defines `classify/2`, `rebuild_required?/1`, `diff/2` covering all 8 change-class atoms; proof lane `:rline_01` (3 tests) green — no regression |
| 2 | The rebuild/OTA decision derives entirely from compatibility.native_runtime_version, with no new manifest JSON field and no manifest_schema_version bump (asserted by a proof test) | ✓ VERIFIED | `Compatibility` struct is byte-for-byte unchanged at 5 fields; `manifest_schema_version == "1.0.0"`; proof lane `:rline_02` (3 tests including exact field-set assertion) green — no regression |
| 3 | An operator running `mix crosswake.doctor` and reading SupportMatrix sees a rebuild & compatibility matrix mapping shell/runtime-line version to supported manifest/capability surface | ✓ VERIFIED | Live doctor output confirmed: `rebuild & compatibility matrix:` block present, `1.x: ota_safe=false, rebuild_required=true, evidence_tier=jvm-hermetic (CI only)` row rendered; JSON formatter exposes `rebuild_matrix` at root; proof lane `:rline_03` (4 tests) green — no regression |
| 4 | Support truth reports `:jvm_hermetic` distinctly from `:device_verified` and NEVER labels CI-only evidence as device-verified — including through the rebuild_matrix surface | ✓ VERIFIED | **Gap 1 (CR-01/RLINE-04) CLOSED.** `@rebuild_matrix_rows` now contains only the "1.x" row with `evidence_tier: :jvm_hermetic` — the unbacked "2.x" row with `evidence_tier: :device_verified` was removed. `validate_rebuild_matrix_evidence/2` added and wired into the `validate/1` pipe (line 383) — unconditionally rejects any `:device_verified` rebuild_matrix row. Live doctor output contains `evidence_tier=jvm-hermetic (CI only)` for the 1.x band only; no `evidence_tier=device-verified` appears. Two new `:rline_04` proof tests added: one asserts `rebuild_matrix` carries no `:device_verified` row, one asserts `validate/1` rejects an injected `:device_verified` row. Proof lane now 20 tests, 0 failures. |
| 5 | Android support state carries explicit, documented promotion criteria (required evidence, minimum consecutive passes, demotion trigger) for moving from :verification_required to :supported | ✓ VERIFIED | `promotion_rules()` contains `shell.android.jvm_hermetic` (`minimum_consecutive_passes: 3`, `required_verification_method: :jvm_hermetic`) and `shell.android.device_verified` (gated, demotion_trigger references Phases 67/68 and explicit jvm_hermetic-must-not-be-read-as-device_verified note). Android baseline status stays `:verification_required`. Proof lane `:rline_05` (3 tests) green — no regression. |

**Score:** 5/5 truths verified

---

## Re-verification: Gap Closure Confirmation

### Gap 1 (CR-01 / RLINE-04) — Evidence laundering via rebuild_matrix

**Closure verified against live code:**

- `@rebuild_matrix_rows` at `support_matrix.ex:276-296` contains exactly ONE row: `runtime_line: "1.x"` with `evidence_tier: :jvm_hermetic`. No "2.x" row exists. `grep -c '"2.x"'` in the `@rebuild_matrix_rows` block returns 0.
- `validate_rebuild_matrix_evidence/2` exists at `support_matrix.ex:886-906`. It reduces over `support_matrix.rebuild_matrix`, rejects any row with `evidence_tier == :device_verified`, and returns an error map referencing `evidence laundering (D-10a)` and the offending `runtime_line`. Comment block (lines 879-885) explains the gating rationale.
- `validate/1` pipe at lines 375-384 calls `validate_rebuild_matrix_evidence(support_matrix)` as the last step, after `validate_verification_method_invariant(support_matrix)`. Wiring is confirmed.
- Live doctor output (`MIX_ENV=test mix crosswake.doctor`): `rebuild & compatibility matrix:` block shows only `1.x: ... evidence_tier=jvm-hermetic (CI only)`. No `evidence_tier=device-verified` rendered.
- Proof test `phase64_runtime_line_policy_test.exs:557-572` asserts `rebuild_matrix` carries no `:device_verified` row (stable id `proof.rline_04.rebuild_matrix.no_unbacked_device_verified`, severity `:merge_blocking`). Proof test `phase64_runtime_line_policy_test.exs:575-603` injects a `:device_verified` row and asserts `validate/1` returns non-empty errors. Both tests green.
- WR-05 follow-on: `evidence_posture_snapshot/1` at `doctor.ex:1210-1219` comment now accurately states it is "a fixed Phase-64 posture map" and does NOT claim derivation it does not perform. Comment at line 1213 explicitly states "This is a compile-time constant for Phase 64. It does NOT derive from the rebuild_matrix rows at runtime." The lie is gone.

### Gap 2 (WR-04) — Doctor severity downgrade for unverified hosts

**Closure verified against live code:**

- `finding_policy.ex:26-29` `shell_proof(:verification_required, label, script_path)` returns `{:error, "proof_hook_verification_required", "run #{script_path} through mix crosswake.doctor --native-checks before claiming #{label} shell support"}`. First element is `:error`. Verified by reading the file.
- `finding_policy.ex:38-42` `support_claim(:verification_required)` returns `{:error, "support_claim_verification_required", "...", "..."}`. First element is `:error`. No `:warning` remains on either `:verification_required` clause.
- `doctor_test.exs:85` asserts `report.status == :error` for the `verification_required` state. Comment at lines 81-84 explicitly states the honest posture and warns that changing to `:ok` would confirm the WR-04 regression.
- `doctor_test.exs:141-164` compensating test: `write_proof_hook!(target, "android", 1, "android proof failed")` drives `Doctor.run` with a failing proof hook and asserts `report.status == :error` and `proof_hook_failed` finding present. Locks honest posture for `:failed` shells.
- Live doctor output (`MIX_ENV=test mix crosswake.doctor`): `status: error` at top; `[error] proof_hook_verification_required` and `[error] support_claim_verification_required` findings present; process exits with code 1 (`Mix.raise("Crosswake doctor found blocking issues")`). Confirmed.

---

## Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/crosswake/runtime_line/rebuild_policy.ex` | classify/2, diff/2, rebuild_required?/1 — the rebuild/OTA policy contract | ✓ VERIFIED | Unchanged from initial verification; no regression |
| `lib/crosswake/manifest/types.ex` | RuntimeLineRow struct + verification_method + required_verification_method + rebuild_matrix field | ✓ VERIFIED | Unchanged from initial verification; no regression |
| `lib/crosswake/support_matrix/support_matrix.ex` | @rebuild_matrix_rows with no :device_verified row + validate_rebuild_matrix_evidence/2 in validate/1 pipe | ✓ VERIFIED | 2.x row removed; 1.x row evidence_tier: :jvm_hermetic only; validate_rebuild_matrix_evidence/2 exists and is wired into validate/1 |
| `lib/crosswake/doctor/finding_policy.ex` | :error severity for :verification_required shell_proof and support_claim | ✓ VERIFIED | Both clauses return {:error, ...}; no :warning on :verification_required clauses |
| `lib/crosswake/doctor/doctor.ex` | evidence_posture_snapshot comment does not lie about derivation | ✓ VERIFIED | Comment accurately states fixed Phase-64 posture map, not derived from rebuild_matrix at runtime |
| `lib/crosswake/doctor/formatter.ex` | format_rebuild_matrix/1 + evidence posture line + format_evidence_tier/1 | ✓ VERIFIED | Unchanged from initial verification; no regression |
| `lib/crosswake/doctor/json_formatter.ex` | rebuild_matrix + evidence_posture JSON keys | ✓ VERIFIED | Unchanged from initial verification; no regression |
| `test/crosswake/proof/phase64_runtime_line_policy_test.exs` | :rline_04 assertions cover rebuild_matrix honesty; all doctor-output tests rescue Mix.Error | ✓ VERIFIED | 20 tests, 0 failures; two new :rline_04 tests assert rebuild_matrix honesty; all Mix.Task.run calls wrapped in try/rescue Mix.Error |
| `test/crosswake/doctor/doctor_test.exs` | verification_required asserts :error; :failed shell asserts :error | ✓ VERIFIED | 22 tests, 0 failures; line 85 asserts report.status == :error; compensating test (lines 141-164) asserts :failed shell produces :error |

---

## Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `RebuildPolicy.classify/2` | `Capability.rebuild` | pattern match on capability.rebuild for capability-axis classes | ✓ WIRED | Lines 103-109; unchanged — no regression |
| `validate/1` | `validate_rebuild_matrix_evidence/2` | pipe append after validate_verification_method_invariant | ✓ WIRED | Line 383 — newly wired by plan 64-06 |
| `validate_rebuild_matrix_evidence/2` | `support_matrix.rebuild_matrix` | Enum.reduce over rebuild_matrix rows | ✓ WIRED | Lines 887-890 — iterates rebuild_matrix, not capability_families |
| `finding_policy.ex shell_proof(:verification_required)` | doctor overall status | :error severity drives report.status == :error | ✓ WIRED | Line 27 returns {:error, ...}; Doctor aggregates findings to status via severity |
| `finding_policy.ex support_claim(:verification_required)` | doctor overall status | :error severity drives report.status == :error | ✓ WIRED | Line 39 returns {:error, ...} |
| `@rebuild_matrix_rows` | `Types.new_runtime_line_row/1` | module attribute built from typed constructor | ✓ WIRED | Lines 276-296; one row only |
| `canonical/1` | `rebuild_matrix: @rebuild_matrix_rows` | field assignment in Types.new_support_matrix/1 | ✓ WIRED | Line 370 |

---

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Doctor renders no `evidence_tier=device-verified` for any band | `MIX_ENV=test mix crosswake.doctor` (live run) | Output contains only `evidence_tier=jvm-hermetic (CI only)` for 1.x band; no device-verified rendered | ✓ PASS |
| Doctor reports `status: error` for unverified host | `MIX_ENV=test mix crosswake.doctor` (live run) | `status: error` at top of output; exits with code 1 via Mix.raise | ✓ PASS |
| Doctor raises Mix.Error for unverified host | `MIX_ENV=test mix crosswake.doctor` (live run) | `** (Mix) Crosswake doctor found blocking issues` in stderr; exit=1 | ✓ PASS |
| Phase-64 proof lane | `mix test test/crosswake/proof/phase64_runtime_line_policy_test.exs` | 20 tests, 0 failures | ✓ PASS |
| Doctor test suite | `mix test test/crosswake/doctor/doctor_test.exs` | 22 tests, 0 failures | ✓ PASS |
| Support matrix test suite | `mix test test/crosswake/support_matrix/` | 40 tests, 0 failures | ✓ PASS |
| Full suite regression | `mix test` | 793 tests, 3 failures (all pre-existing MilestoneTransitionResetTest) | ✓ PASS (no new failures) |

---

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| RLINE-01 | 64-01, 64-03 | Classify any manifest/capability/shell change as OTA-safe or rebuild-required per 8 change classes | ✓ SATISFIED | `RebuildPolicy` implements all 8 classes; proof `:rline_01` green; no regression |
| RLINE-02 | 64-01, 64-02, 64-03 | Rebuild/OTA policy derived from `native_runtime_version` with no new manifest field | ✓ SATISFIED | `Compatibility` unchanged at 5 fields; `manifest_schema_version == "1.0.0"`; proof `:rline_02` green; no regression |
| RLINE-03 | 64-01, 64-04, 64-05 | Operators can view rebuild & compatibility matrix via SupportMatrix and mix crosswake.doctor | ✓ SATISFIED | Matrix rendered in human and JSON doctor output (1.x band, honest evidence tier); proof `:rline_03` green; no regression |
| RLINE-04 | 64-01, 64-04, 64-05, 64-06 | Support truth distinguishes `:jvm_hermetic` from `:device_verified` and never reports CI-only as device-verified | ✓ SATISFIED | CR-01 closed: unbacked 2.x row removed; structural validation gate added; proof blind spot closed by two new :rline_04 tests; doctor renders no device-verified for unbacked band |
| RLINE-05 | 64-01, 64-04 | Android support state carries explicit promotion criteria | ✓ SATISFIED | Two gated promotion rows exist; Android stays `:verification_required`; proof `:rline_05` green; no regression |

---

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| None | — | All previously identified BLOCKER anti-patterns resolved by plan 64-06 | — | — |

Previously identified blockers:
- `@rebuild_matrix_rows` "2.x" `:device_verified` row: **RESOLVED** — row removed.
- `finding_policy.ex` `:warning` on `:verification_required`: **RESOLVED** — reverted to `:error`.
- `evidence_posture_snapshot/1` lying comment: **RESOLVED** — comment now accurately describes fixed posture map.

---

## Human Verification Required

None. All behavioral checks verified programmatically.

---

## Gaps Summary

None. Both BLOCKER gaps from the initial verification are fully closed. All 5 phase truths now pass. RLINE-04 moves from BLOCKED to SATISFIED.

---

_Verified: 2026-06-04T03:00:00Z_
_Verifier: Claude (gsd-verifier)_
_Re-verification: Yes — after plan 64-06 gap closure_
