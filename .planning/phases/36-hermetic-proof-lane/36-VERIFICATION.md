---
phase: 36-hermetic-proof-lane
verified: 2026-05-29T00:00:00Z
status: passed
score: 9/9 must-haves verified
overrides_applied: 2
overrides:
  - must_have: "D-08: The proof file uses ExUnit.Case async: false, is untagged (no @moduletag :requires_example_host) so it runs in the merge-blocking lane, the moduledoc states the hermeticity contract explicitly, and a self-scan guard structurally enforces no runtime-path require_file and no process/server tokens"
    reason: "D-02 (USER-CONFIRMED in CONTEXT): SC#4 literal 'no Code.require_file on example-host paths' is reinterpreted as no require_file on runtime/server paths. The four pure commerce module require_file lines are the intentional hermetic idiom (phase21/34 precedent), not a violation. The self-scan guard allowlist enforces the distinction structurally."
    accepted_by: "szTheory"
    accepted_at: "2026-05-29T00:00:00Z"
  - must_have: "Crosswake.Commerce.Reconciliation.authority_mutation_allowed_from_evidence?/1 == false for mock-produced evidence"
    reason: "D-06 (USER-CONFIRMED in CONTEXT): SC#3 literal 'project_snapshot rejects any non-:projection_refreshed state' is factually wrong against shipped code. The fence is asserted as the three real D-06 truths instead of the literal-but-false SC#3 wording. All three truths are verified in the test."
    accepted_by: "szTheory"
    accepted_at: "2026-05-29T00:00:00Z"
---

# Phase 36: Hermetic Proof Lane — Verification Report

**Phase Goal:** `test/crosswake/proof/phase34_paywall_corridor_proof_test.exs` is the merge-blocking proof for the full mock corridor — it drives all four `derived_state/1` states (`:stale`, `:pending`, `:denied`, `:granted`), asserts the `:pending` → `:granted` transition, and fences `authority_mutation_allowed_from_evidence?/1` returning `false`, all without any network call, process start, or example-host runtime dependency.
**Verified:** 2026-05-29T00:00:00Z
**Status:** PASSED
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `derived_state/1` returns `:stale` for a fresh-overridden stale snapshot | VERIFIED | Line 47-48: `phase34_snapshot(%{freshness: phase34_freshness_lane(:stale)})` → `assert == :stale` |
| 2 | `derived_state/1` returns `:pending` for a fresh + `:awaiting_verification` reconciliation snapshot | VERIFIED | Line 52-53: `phase34_snapshot(%{reconciliation: phase34_reconciliation_lane(:awaiting_verification)})` → `assert == :pending` |
| 3 | `derived_state/1` returns `:denied` for a fresh + verified + non-granting snapshot (access `:denied`) | VERIFIED | Line 59-61: `phase34_snapshot()` base defaults (access `:denied`, reconciliation `:projection_refreshed`) → `assert == :denied` |
| 4 | `derived_state/1` returns `:granted` for a snapshot produced by `MockBackend.build_verified_snapshot/2` + `project_snapshot/2` | VERIFIED | Lines 65-67: `MockBackend.build_verified_snapshot(phase34_mock_evidence(), @group_id)` → `project_snapshot(nil, verified)` → `assert == :granted` |
| 5 | `ReconciliationInbox.ingest_evidence/2` on inline mock purchase evidence returns `{:ok, map}` with `status == :awaiting_verification` | VERIFIED | Lines 77-79: `{:ok, result} = ReconciliationInbox.ingest_evidence(evidence)`; `assert result.status == :awaiting_verification` |
| 6 | `MockBackend.build_verified_snapshot/2` → `project_snapshot(nil, verified)` → `{:ok, projected}` → `derived_state == :granted` | VERIFIED | Lines 89-91: full three-step pipeline asserted in `:pending -> :granted transition` describe block |
| 7 | `Crosswake.Commerce.Reconciliation.authority_mutation_allowed_from_evidence?/1 == false` for mock-produced evidence | VERIFIED (override) | Lines 102-104: fully-qualified lib call; override applied per D-06 (USER-CONFIRMED); assertion verifies the fence anchor unconditionally |
| 8 | `EntitlementProjection.project_snapshot(nil, unverified)` returns `{:error, :unverified_reconciliation_outcome}` for `:awaiting_verification` reconciliation | VERIFIED | Lines 108-112: D-06.2 asserted |
| 9 | A verified-but-not-refreshed snapshot (`:verification_failed`) projects but does NOT derive `:granted` | VERIFIED | Lines 119-130: D-06.3 — `{:ok, projected}` asserted then `refute derived_state(projected) == :granted` |

**Score:** 9/9 truths verified (2 with pre-confirmed overrides applied per USER-CONFIRMED CONTEXT decisions D-02 and D-06)

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `test/crosswake/proof/phase34_paywall_corridor_proof_test.exs` | Hermetic merge-blocking proof of the mock paywall corridor | VERIFIED | 286 lines, 14 tests, `use ExUnit.Case, async: false`, untagged, commit `9aebfcb` |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `phase34_paywall_corridor_proof_test.exs` | `examples/phoenix_host/lib/crosswake_example/commerce/entitlement_projection.ex` | `Code.require_file` at line 3 | WIRED | Line 3: `Code.require_file("../../../examples/phoenix_host/lib/crosswake_example/commerce/entitlement_projection.ex", __DIR__)` |
| `phase34_paywall_corridor_proof_test.exs` | `examples/phoenix_host/lib/crosswake_example/commerce/mock_backend.ex` | `Code.require_file` at line 4; `build_verified_snapshot/2` at lines 65, 89 | WIRED | Both links present; `build_verified_snapshot/2` called in two distinct test scenarios |
| `phase34_paywall_corridor_proof_test.exs` | `lib/crosswake/commerce/reconciliation.ex` | Fully-qualified `Crosswake.Commerce.Reconciliation.authority_mutation_allowed_from_evidence?/1` at line 103 | WIRED | Compilation-path call confirmed; no require_file needed |

---

### Data-Flow Trace (Level 4)

Not applicable — the deliverable is a test file exercising pure functions with inline fixtures, not a UI component or API route. The "data source" is the inline fixture builders (`phase34_snapshot/1`, `phase34_mock_evidence/0`) and the shipped commerce modules under test. All function calls return real computed values; no stubs or static returns.

---

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| `mix compile --warnings-as-errors` clean | `mix compile --warnings-as-errors 2>&1; echo "EXIT:$?"` | exit 0, no output | PASS |
| 14 tests, 0 failures on the proof file | `mix test test/crosswake/proof/phase34_paywall_corridor_proof_test.exs` | `14 tests, 0 failures` (exit 0) | PASS |
| Full hermetic lane green with new file auto-discovered | `mix test --exclude requires_example_host` | `308 tests, 0 failures (38 excluded)` (exit 0) | PASS |

---

### Probe Execution

No `scripts/*/tests/probe-*.sh` probes declared for this phase. The test suite IS the proof artifact; all verification is via `mix test` above.

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|---------|
| PROOF-01 | 36-01-PLAN.md | Merge-blocking hermetic ExUnit proof drives the full lane (mock purchase → `ingest_evidence/2` → `project_snapshot/2` → `derived_state/1`) with no network or native SDK, asserting all four states and the `:pending` → `:granted` transition | SATISFIED | All four states asserted distinctly (SC#1 truths 1-4 above); `:pending` → `:granted` transition asserted via `ingest_evidence/2` → `build_verified_snapshot/2` → `project_snapshot(nil, _)` → `derived_state == :granted` (SC#2 truths 5-6 above); test file is untagged and `async: false`; `mix test --exclude requires_example_host` passes with file auto-discovered |
| PROOF-03 | 36-01-PLAN.md | Proof asserts mock evidence routed through `ingest_evidence/2` can never grant entitlement authority directly — mock-boundary fence anchored on `authority_mutation_allowed_from_evidence?/1` returning `false` | SATISFIED | Three D-06 truths asserted (truths 7-9 above): fence returns `false` unconditionally (D-06.1); unverified evidence rejected by `project_snapshot/2` (D-06.2); verified-but-not-refreshed snapshot does not derive `:granted` (D-06.3). Together: mock evidence can never directly grant authority. |

No orphaned requirements. REQUIREMENTS.md traceability table maps PROOF-01 and PROOF-03 exclusively to Phase 36 (complete). PROOF-02 was delivered in Phase 33. DOCS-01/DOCS-02 are Phase 37 (pending — not in scope here).

---

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| None | — | No debt markers (TBD/FIXME/XXX), no placeholder returns, no hardcoded empty values, no `return null`, no process start tokens | — | — |

Grep confirmed: no `TBD`, `FIXME`, `XXX`, `TODO`, `HACK`, `PLACEHOLDER`, `return nil`, `return []`, `return {}` anywhere in the proof file. No PubSub, no `start_supervised`, no `GenServer.start`, no `LiveViewTest` tokens. No changes to `lib/crosswake/commerce/*` or any example-host module confirmed by `git diff HEAD~4..HEAD -- lib/crosswake/commerce/ examples/phoenix_host/lib/` (zero diff).

---

### Code-Review Advisory Warnings (from 36-REVIEW.md — not blockers)

These are the three advisory assertion-strength findings from the code review. They are noted here for follow-up consideration; none are goal-blocking and the tests pass correctly against real regressions.

**WR-01 (advisory):** Self-scan guard reads only the proof file's own source — it cannot detect PubSub calls introduced inside required modules (e.g. if a future edit swapped `build_verified_snapshot/2` for `verify_and_broadcast/2`). The assertion message overstates the scope of the guard. Suggested fix: add `"verify_and" <> "_broadcast"` to the forbidden-token list in the self-scan, or tighten the assertion message.

**WR-02 (advisory):** The `:denied` base snapshot has BOTH `authority: :none` AND `access: :denied` failing simultaneously. The stated intent is to prove "verified reconciliation + access :denied" is the sole non-granting condition, but the over-determination means a regression that dropped the `access.decision` check would still pass. Suggested fix: set authority to `:active` so `access.decision :denied` is the sole non-granting field.

**WR-03 (advisory):** SC#1 and SC#2 duplicate the `:pending` and `:granted` assertions through the same code path. The `:pending → :granted` transition does not thread the same evidence instance through both steps, so a regression breaking the `group_id`/reference linkage between ingested evidence and the verified snapshot would not be caught. Suggested fix: assert `verified.group_id == @group_id` in the SC#2 transition test.

These are improvements to assertion strength, not correctness failures — all 14 tests are non-vacuous against the shipped corridor code.

---

### Human Verification Required

None. This phase delivers a test file verified entirely by running the test suite. All observable truths are programmatically confirmed. No visual, real-time, or external-service behavior requires human judgment.

---

## Gaps Summary

No gaps. All nine must-have truths are verified against the actual codebase. The two overrides (D-02 and D-06 reinterpretations) were USER-CONFIRMED in `36-CONTEXT.md` before implementation and are pre-authorized deviations from ambiguous ROADMAP SC#3/SC#4 wording, not gaps. The three code-review advisory warnings (WR-01/WR-02/WR-03) identify assertion-strength improvement opportunities but do not make the proof incorrect or incomplete — all tests pass and assert the right final values.

---

_Verified: 2026-05-29T00:00:00Z_
_Verifier: Claude (gsd-verifier)_
