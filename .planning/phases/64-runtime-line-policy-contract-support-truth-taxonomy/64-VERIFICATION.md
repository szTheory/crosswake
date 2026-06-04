---
phase: 64-runtime-line-policy-contract-support-truth-taxonomy
verified: 2026-06-03T00:00:00Z
status: gaps_found
score: 4/5 must-haves verified
overrides_applied: 0
gaps:
  - truth: "Support truth reports :jvm_hermetic distinctly from :device_verified and NEVER labels CI-only evidence as device-verified"
    status: failed
    reason: "The @rebuild_matrix_rows module attribute hardcodes a '2.x' row with evidence_tier: :device_verified. No 2.x runtime-line band exists (native_runtime_version is '1.0.0', the 1.x band only), and device-verified proof is explicitly gated until Phases 67/68 per the shell.android.device_verified promotion rule. validate/1 does not inspect rebuild_matrix rows — only capability_families entries pass through validate_verification_method_invariant/2. Both the human formatter (format_rebuild_matrix/1) and the JSON formatter (format_runtime_line_row/1) render this row verbatim, so mix crosswake.doctor publicly outputs 'evidence_tier=device-verified' for a band that has zero backing proof. This is the evidence-laundering route that D-10a exists to prevent, but it is bypassed by routing through the unvalidated rebuild_matrix surface."
    artifacts:
      - path: "lib/crosswake/support_matrix/support_matrix.ex"
        issue: "@rebuild_matrix_rows lines 296-314: '2.x' row hardcodes evidence_tier: :device_verified with no validation gate and no real device proof corpus"
      - path: "lib/crosswake/support_matrix/support_matrix.ex"
        issue: "validate/1 pipe (lines 394-402) calls validate_verification_method_invariant/2 but that function only iterates support_matrix.capability_families — rebuild_matrix rows are never validated"
    missing:
      - "Remove the speculative '2.x' row from @rebuild_matrix_rows until a real 2.x band with device proof exists, OR"
      - "Extend validate/1 with a validate_rebuild_matrix_evidence/2 clause that rejects any rebuild_matrix row whose evidence_tier is :device_verified when no corresponding device-verified promotion evidence has passed (mirroring validate_verification_method_invariant/2 for capability_families)"
      - "Update test/crosswake/proof/phase64_runtime_line_policy_test.exs rline_04 to assert that the rebuild_matrix carries no :device_verified row with zero proof backing — the current green tests do not assert this property"
  - truth: "Support-truth honesty posture: unverified hosts produce :error overall doctor status (WR-04 severity regression)"
    status: failed
    reason: "Four findings were downgraded from :error to :warning in finding_policy.ex and doctor.ex as an unplanned deviation auto-fixed for hermetic test compatibility. This flips mix crosswake.doctor from status: :error to status: :ok for a host whose shell proofs are unverified (verification_required). doctor_test.exs was updated to assert report.status == :ok for the verification_required state. The phase goal is to lock the honesty taxonomy so no downstream surface can overclaim — but CI or tooling gating on doctor status: :error will now silently pass for an unverified host. This is a support-truth posture regression with no phase-64 mandate (no D-number or design decision documents this policy change as intentional)."
    artifacts:
      - path: "lib/crosswake/doctor/finding_policy.ex"
        issue: "Line 27: shell_proof(:verification_required) returns :warning (was :error). Line 39: support_claim(:verification_required) returns :warning (was :error). Both changes flip the overall doctor report status for unverified hosts."
      - path: "test/crosswake/doctor/doctor_test.exs"
        issue: "Line 84: assert report.status == :ok changed from :error — test now confirms the posture regression rather than catching it"
    missing:
      - "Revert shell_proof(:verification_required) in finding_policy.ex to :error, OR document with an explicit D-number decision and rationale that advisory-mode verification is intentionally non-blocking, and update any CI gate that relied on status: :error for unverified hosts"
      - "If revert, fix the phase64 proof test pattern: instead of capture_io wrapping Mix.Task.run, rescue Mix.Error around the call (as the test comment in 64-01-PLAN.md already acknowledges the Phase 52 capture_io pattern), so the hermetic proof lane can run without requiring severity relaxation"
      - "If the severity change is kept intentionally, add an explicit note to STATE.md / DECISIONS.md with the rationale, and add a proof assertion that doctor reports status: :error when a shell is :failed (not just :verification_required)"
---

# Phase 64: Runtime-Line Policy Contract & Support-Truth Taxonomy — Verification Report

**Phase Goal:** Lock the runtime-line policy and support-truth taxonomy in Elixir — the OTA-safe vs. rebuild-required change classification, the `:jvm_hermetic` vs. `:device_verified` evidence distinction, the rebuild/compatibility matrix projection, and Android promotion criteria — so no downstream surface can overclaim. Rebuild policy derived from the existing manifest `native_runtime_version` axis with no new manifest schema field.

**Verified:** 2026-06-03T00:00:00Z
**Status:** gaps_found
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | For any manifest/capability/shell change, the policy classifies it as OTA-safe or rebuild-required per change class (8 classes) — verifiable via Crosswake.RuntimeLine.RebuildPolicy and hermetic proof | ✓ VERIFIED | `lib/crosswake/runtime_line/rebuild_policy.ex` defines `classify/2`, `rebuild_required?/1`, `diff/2` covering all 8 change-class atoms; proof lane `:rline_01` (3 tests) green |
| 2 | The rebuild/OTA decision derives entirely from compatibility.native_runtime_version, with no new manifest JSON field and no manifest_schema_version bump (asserted by a proof test) | ✓ VERIFIED | `Compatibility` struct is byte-for-byte unchanged at 5 fields; `manifest_schema_version == "1.0.0"`; proof lane `:rline_02` (3 tests including exact field-set assertion) green; `@rebuild_matrix_rows` correctly reuses existing `native_runtime_version` axis |
| 3 | An operator running `mix crosswake.doctor` and reading SupportMatrix sees a rebuild & compatibility matrix mapping shell/runtime-line version to supported manifest/capability surface | ✓ VERIFIED | Human output confirmed live: "rebuild & compatibility matrix:" block + "1.x" and "2.x" rows; JSON formatter exposes `rebuild_matrix` at root; proof lane `:rline_03` (4 tests) green. Note: the 2.x row contains a honesty violation (see SC-4 gap). |
| 4 | Support truth reports `:jvm_hermetic` distinctly from `:device_verified` and NEVER labels CI-only evidence as device-verified | ✗ FAILED | **CR-01 confirmed.** `@rebuild_matrix_rows` at `support_matrix.ex:296-314` hardcodes `evidence_tier: :device_verified` for a "2.x" band that does not exist and has no backing proof. `validate/1` does not cover rebuild_matrix rows. `mix crosswake.doctor` (confirmed live) outputs `evidence_tier=device-verified` for this row. The `:rline_04` proof tests pass only because they assert against `capability_families` entries, not rebuild_matrix rows — the gap is not covered by the existing proof assertions. |
| 5 | Android support state carries explicit, documented promotion criteria (required evidence, minimum consecutive passes, demotion trigger) for moving from :verification_required to :supported | ✓ VERIFIED | `promotion_rules()` contains `shell.android.jvm_hermetic` (minimum_consecutive_passes: 3, required_verification_method: :jvm_hermetic) and `shell.android.device_verified` (GATED, demotion_trigger referencing Phases 67/68 and explicit jvm_hermetic-must-not-be-read-as-device_verified note). Android baseline `SupportEntry.status` stays `:verification_required`. Proof lane `:rline_05` (3 tests) green. |

**Score:** 4/5 truths verified (excluding WR-04 posture regression — assessed separately as a second gap)

---

## Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `test/crosswake/proof/phase64_runtime_line_policy_test.exs` | Wave-0 hermetic proof lane with all RLINE-01..05 tags | ✓ VERIFIED | Exists; 18 tests, 0 failures; hermetic (no `@moduletag :requires_example_host`); aliases all required modules |
| `lib/crosswake/manifest/types.ex` | RuntimeLineRow struct + verification_method + required_verification_method + rebuild_matrix field | ✓ VERIFIED | `defmodule RuntimeLineRow` with `@derive Jason.Encoder` and 6-key `@enforce_keys`; `CapabilitySupportEntry.verification_method: :none`; `PromotionRuleEntry.required_verification_method: :none`; `SupportMatrix.rebuild_matrix: []`; `Compatibility` unchanged |
| `lib/crosswake/runtime_line/rebuild_policy.ex` | classify/2, diff/2, rebuild_required?/1 — the rebuild/OTA policy contract | ✓ VERIFIED | Module exists; `@system_rebuild_classes [:sdk_floor_bump, :privacy_manifest_entry]`; all 3 public functions implemented; capability-axis classes derive from `Capability.rebuild`; raises ArgumentError for nil capability on capability-axis class |
| `lib/crosswake/support_matrix/support_matrix.ex` | @rebuild_matrix_rows + rebuild_matrix/1 + validation + 2 Android promotion rows | ✗ PARTIAL | Accessor, promotion rows, and validate_verification_method_invariant exist and are correct. BLOCKER: `@rebuild_matrix_rows` "2.x" row hardcodes `:device_verified` with no validation gate — evidence laundering via unvalidated surface (CR-01). |
| `lib/crosswake/doctor/formatter.ex` | format_rebuild_matrix/1 + evidence posture line + format_evidence_tier/1 | ✓ VERIFIED | All three helpers exist; `format_evidence_tier(:jvm_hermetic)` returns `"jvm-hermetic (CI only)"`; `format_evidence_tier(:device_verified)` returns `"device-verified"`; full `format_release_policy/1` clause renders both lines; minimal clause unchanged |
| `lib/crosswake/doctor/json_formatter.ex` | rebuild_matrix + evidence_posture JSON keys | ✓ VERIFIED | `rebuild_matrix` exposed at JSON root and in `release_policy`; `format_runtime_line_row/1` serializes evidence_tier via `Atom.to_string/1` |
| `lib/crosswake/doctor/finding_policy.ex` | Honest finding severity for unverified hosts | ✗ FAILED | `shell_proof(:verification_required)` and `support_claim(:verification_required)` return `:warning` (were `:error`). Unplanned deviation; flips doctor overall status to `:ok` for unverified hosts (WR-04). |

---

## Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `RebuildPolicy.classify/2` | `Capability.rebuild` | pattern match on `capability.rebuild` for capability-axis classes | ✓ WIRED | Lines 103-109; raises `ArgumentError` on nil capability for capability-axis classes |
| `RebuildPolicy` | `@system_rebuild_classes` | closed-set guard | ✓ WIRED | Line 44 + line 92 |
| `@rebuild_matrix_rows` | `Types.new_runtime_line_row/1` | module attribute built from typed constructor | ✓ WIRED | Lines 276-315; 2 rows built at compile time |
| `canonical/1` | `rebuild_matrix:` field | `rebuild_matrix: @rebuild_matrix_rows` | ✓ WIRED | Line 389 |
| `validate/1` | `validate_verification_method_invariant/2` | pipe | ✓ WIRED | Line 401 — but this function only validates `capability_families`, not `rebuild_matrix` rows |
| `release_policy_snapshot/1` | `SupportMatrix.rebuild_matrix/1` | accessor call | ✓ WIRED | Line 1205 |
| `formatter.ex` + `json_formatter.ex` | same `[RuntimeLineRow.t()]` list | `release_policy.rebuild_matrix` | ✓ WIRED | Shared traversal via `release_policy` map key in both formatters |
| `finding_policy.ex` | doctor overall status | severity determines `status: :error` vs `:ok` | ✗ BROKEN | `:verification_required` now returns `:warning`, so a host with unverified proofs reports `status: :ok` |

---

## Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|--------------|--------|--------------------|--------|
| `formatter.ex` `format_rebuild_matrix/1` | `rebuild_matrix` (list of RuntimeLineRow) | `@rebuild_matrix_rows` module attribute via `canonical/1` → `release_policy_snapshot/1` | Yes — typed rows are produced at compile time | ✓ FLOWING |
| `formatter.ex` `format_evidence_posture/1` | `evidence_posture` (`%{ios:, android:}`) | `evidence_posture_snapshot/1` in doctor.ex — hardcoded literal `%{ios: :device_verified, android: :jvm_hermetic}` | Partially real — comment says "derived from rebuild_matrix" but function discards argument and returns hardcoded value (WR-05) | ⚠️ STATIC |
| `rebuild_matrix "2.x"` row | `evidence_tier: :device_verified` | `@rebuild_matrix_rows` compile-time attribute | Claims real-device proof but no proof corpus exists | ✗ HOLLOW — evidence claim has no backing proof |

---

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Doctor human output contains "rebuild & compatibility matrix:" | `MIX_ENV=test mix crosswake.doctor --router ...ManagedRouter` | Output confirmed present | ✓ PASS |
| Doctor human output contains "evidence posture: ios=device-verified android=jvm-hermetic (CI only)" | same | Output confirmed present | ✓ PASS |
| Doctor human output contains "2.x: ... evidence_tier=device-verified" | same | Output confirmed present — this is the CR-01 violation | ✗ FAIL (intended blocker) |
| Full phase-64 proof lane green | `mix test test/crosswake/proof/phase64_runtime_line_policy_test.exs` | 18 tests, 0 failures | ✓ PASS |
| Doctor overall status for unverified host | `MIX_ENV=test mix crosswake.doctor --router ...ManagedRouter` | `status: ok` (was `:error` pre-phase 64) | ✗ FAIL (WR-04 posture regression) |

---

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| RLINE-01 | 64-01, 64-03 | Classify any manifest/capability/shell change as OTA-safe or rebuild-required per 8 change classes | ✓ SATISFIED | `RebuildPolicy` implements all 8 classes; proof `:rline_01` green |
| RLINE-02 | 64-01, 64-02, 64-03 | Rebuild/OTA policy derived from `native_runtime_version` with no new manifest field | ✓ SATISFIED | `Compatibility` unchanged at 5 fields; `manifest_schema_version == "1.0.0"`; proof `:rline_02` green |
| RLINE-03 | 64-01, 64-04, 64-05 | Operators can view rebuild & compatibility matrix via SupportMatrix and mix crosswake.doctor | ✓ SATISFIED | Matrix rendered in human and JSON doctor output; proof `:rline_03` green. The 2.x/device-verified content is a honesty flaw, not an absence of the feature. |
| RLINE-04 | 64-01, 64-04, 64-05 | Support truth distinguishes `:jvm_hermetic` from `:device_verified` and never reports CI-only as device-verified | ✗ BLOCKED | CR-01: `@rebuild_matrix_rows` "2.x" row claims `:device_verified` with no backing proof, bypassing `validate_verification_method_invariant/2`. The honesty invariant is enforced only on `capability_families`, not `rebuild_matrix`. |
| RLINE-05 | 64-01, 64-04 | Android support state carries explicit promotion criteria | ✓ SATISFIED | Two gated promotion rows exist; Android stays `:verification_required`; proof `:rline_05` green |

---

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `lib/crosswake/support_matrix/support_matrix.ex` | 296-314 | `evidence_tier: :device_verified` on a "2.x" row that does not exist and has no device proof backing | BLOCKER | Doctor renders `evidence_tier=device-verified` publicly with zero backing — evidence laundering via unvalidated rebuild_matrix surface (CR-01) |
| `lib/crosswake/doctor/finding_policy.ex` | 27, 39 | `:warning` severity for `proof_hook_verification_required` and `support_claim_verification_required` (were `:error`) | BLOCKER | Doctor reports `status: ok` for unverified hosts; CI gates on `:error` silently pass (WR-04) |
| `lib/crosswake/doctor/doctor.ex` | 1213 | `evidence_posture_snapshot/1` discards `_support_matrix` argument and returns hardcoded `%{ios: :device_verified, android: :jvm_hermetic}` while comment says "derived from the rebuild_matrix" | WARNING | Comment is false; if rebuild_matrix evidence tiers change, this summary silently disagrees (WR-05) |
| `lib/crosswake/runtime_line/rebuild_policy.ex` | 46 | Comment "All 8 change classes in the taxonomy" on a 6-element list | WARNING | Misleads future maintainers auditing coverage; the 2 system classes are in `@system_rebuild_classes`, not this list (WR-03) |

---

## Gaps Summary

Two gaps block the phase goal. Both stem from work done in plan 04.

**Gap 1 — CR-01 (BLOCKER): Evidence laundering via unvalidated rebuild_matrix (RLINE-04 violated)**

The phase's core honesty invariant — `:jvm_hermetic` (CI-only) must never be rendered or promoted as `:device_verified` — is enforced only for `capability_families` entries via `validate_verification_method_invariant/2`. The `@rebuild_matrix_rows` module attribute is never validated. The "2.x" row hardcodes `evidence_tier: :device_verified` despite: (a) no 2.x runtime-line band existing, (b) device-verified proof being explicitly gated until Phases 67/68, and (c) the `shell.android.device_verified` promotion rule documenting that this evidence is unavailable. Both doctor formatters render this row verbatim, so `mix crosswake.doctor` publicly asserts device-verified evidence that does not exist. The proof lane's `:rline_04` tests pass because they assert only against `capability_families` entries — the rebuild_matrix surface is a blind spot in the test coverage.

Remediation (either): Remove the "2.x" row from `@rebuild_matrix_rows` until Phase 67/68 produces real device proof; OR add a `validate_rebuild_matrix_evidence/2` clause to the `validate/1` pipe that rejects `:device_verified` evidence_tier on any row whose runtime-line has no corresponding passed device-verified promotion evidence.

**Gap 2 — WR-04 (BLOCKER): Doctor severity downgrade flips overall status to :ok for unverified hosts**

`finding_policy.ex` downgraded `shell_proof(:verification_required)` and `support_claim(:verification_required)` from `:error` to `:warning` as an unplanned auto-fix to make hermetic proof tests pass without a `rescue Mix.Error` pattern. There is no D-number, no DECISIONS.md entry, and no REQUIREMENTS.md mandate for this policy change. The effect: `mix crosswake.doctor` reports `status: ok` for a host with unverified shell proofs. Any CI gate or tooling that relied on `status: :error` as a signal that support claims are unverified will now silently pass. The phase goal is "so no downstream surface can overclaim" — a `:ok` overall status for an unverified host is an overclaim vector.

Remediation: Revert the severity changes and fix the test infrastructure by rescuing `Mix.Error` in the capture_io block, OR explicitly document with a D-number that advisory-mode unverified state is intentionally non-blocking and add a compensating proof assertion that a `:failed` shell still produces `status: :error`.

---

## Human Verification Required

None identified. All behavioral checks are programmatically verifiable.

---

_Verified: 2026-06-03T00:00:00Z_
_Verifier: Claude (gsd-verifier)_
