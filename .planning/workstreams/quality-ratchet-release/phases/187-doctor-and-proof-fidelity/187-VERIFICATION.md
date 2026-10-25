---
phase: 187-doctor-and-proof-fidelity
verified: 2026-10-16T20:00:00Z
status: passed
score: 4/4 must-haves verified
covered_files:
  - ".planning/seeds/SEED-014-proof-lane-and-doctor-fidelity.md"
  - ".planning/workstreams/quality-ratchet-release/phases/187-doctor-and-proof-fidelity/187-01-PLAN.md"
  - ".planning/workstreams/quality-ratchet-release/phases/187-doctor-and-proof-fidelity/187-01-SUMMARY.md"
  - ".planning/workstreams/quality-ratchet-release/phases/187-doctor-and-proof-fidelity/187-02-PLAN.md"
  - ".planning/workstreams/quality-ratchet-release/phases/187-doctor-and-proof-fidelity/187-02-SUMMARY.md"
  - ".planning/workstreams/quality-ratchet-release/phases/187-doctor-and-proof-fidelity/187-03-PLAN.md"
  - ".planning/workstreams/quality-ratchet-release/phases/187-doctor-and-proof-fidelity/187-03-SUMMARY.md"
  - ".planning/workstreams/quality-ratchet-release/phases/187-doctor-and-proof-fidelity/187-04-PLAN.md"
  - ".planning/workstreams/quality-ratchet-release/phases/187-doctor-and-proof-fidelity/187-04-SUMMARY.md"
  - ".planning/workstreams/quality-ratchet-release/phases/187-doctor-and-proof-fidelity/187-05-PLAN.md"
  - ".planning/workstreams/quality-ratchet-release/phases/187-doctor-and-proof-fidelity/187-05-SUMMARY.md"
  - ".planning/workstreams/quality-ratchet-release/phases/187-doctor-and-proof-fidelity/187-06-PLAN.md"
  - ".planning/workstreams/quality-ratchet-release/phases/187-doctor-and-proof-fidelity/187-06-SUMMARY.md"
  - ".planning/workstreams/quality-ratchet-release/phases/187-doctor-and-proof-fidelity/187-07-PLAN.md"
  - ".planning/workstreams/quality-ratchet-release/phases/187-doctor-and-proof-fidelity/187-07-SUMMARY.md"
  - ".planning/workstreams/quality-ratchet-release/phases/187-doctor-and-proof-fidelity/187-DEFERRALS.md"
covered_digest: "v3:sha256:5f7ca8c55e4ddd6a7a36476fc85950f8fbdd6776611c1bbb45b31234cedfa8f9"
behavior_unverified: 0
overrides_applied: 0
---

# Phase 187: Doctor and proof fidelity Verification Report

**Phase Goal:** Doctor and proof evidence tell a maintainer exactly what is wrong and where it came from, and the deferred adopter requests are recorded so they are not re-argued.
**Status:** passed
**Re-verification:** No (initial)

Product code is the candidate commit `fix(187)` a53fbef7 over bd294007 in the candidate checkout (not in the recovery checkout). Evidence directory: RUNS = /private/tmp/crosswake-phase180-run.

## Observable Truths

| # | Truth (ROADMAP SC) | Status | Evidence |
|---|---|---|---|
| 1 | `doctor --format json` emits unmanaged route paths and router as structured `details` on `unmanaged_routes` (DOCTOR-01) | VERIFIED | `doctor.ex` diff adds `%{unmanaged_paths: sorted uniq, router: warning.module && inspect(...)}` to the finding. Tests "unmanaged_routes details carry the sorted paths and the router name" and "mix crosswake.doctor --format json carries unmanaged route paths and router in details" pass; mutation controls 1-4 each fail the named tests. |
| 2 | Every `:offline_island` + `:local_first` route without `island_contract` is flagged (computed before the filter); "not claimed" reported when no route claims offline; compile-time rule recorded as deferred with trigger (DOCTOR-02) | VERIFIED | `incoherent_ids` computed over all manifest routes before the contract filter; precedence incomplete > not_claimed > supported; `offline_posture_incomplete` error lists `incoherent_routes`; `offline_posture_not_claimed` advisory. Tests pass; controls 5-9 bite. Deferral in 187-DEFERRALS.md with three reopen triggers, mirrored in REQUIREMENTS.md line 105. |
| 3 | Provenance header carries real crosswake version, template version, `git rev-parse HEAD`, device class, with explicit sentinels; validator rejects all-zero commit with negative fixture (DOCTOR-03) | VERIFIED | New `Provenance.read/1` replaces the hardcoded `0.1.0`/`161`/`git-000...` literals in `verify_navigation_shell`. Exact sentinels `unknown` / `git-unknown`. `Evidence.git_ref/1` rejects `git-0{40}`/`0{64}` with PL-EVIDENCE-COMMIT (also on stored-evidence decode). Sentinel evidence cannot be physical proof or promoted to `physical_iphone` (`provenance_known?/1`). Negative fixture test and "task source carries no placeholder provenance literal" test pass; controls 10-22 bite. Device class remains the existing `:unknown` field (pre-existing, accepted sentinel). |
| 4 | CW-REQ-A and CW-REQ-D deferrals recorded with evidence and reopen triggers; CW-REQ-A records both readings of pipeline trigger (DOCTOR-04) | VERIFIED | 187-DEFERRALS.md has CW-REQ-A with a two-row reading table (Reading 1 met; Reading 2 only qualifiedly met, REL-10 breach), verdict defer under either reading, trigger list; CW-REQ-D with view lines and triggers; pointers present in SEED-014 (lines 92, 157, 194) and REQUIREMENTS.md (lines 103-105). RUNS/deferrals-187.check all PASS. |

**Score:** 4/4 truths verified (0 behavior-unverified)

## Requirements Coverage

| Requirement | Status | Evidence |
|---|---|---|
| DOCTOR-01 | SATISFIED | Truth 1 |
| DOCTOR-02 | SATISFIED | Truth 2 |
| DOCTOR-03 | SATISFIED | Truth 3 |
| DOCTOR-04 | SATISFIED | Truth 4 |

All four IDs appear in plan frontmatter and REQUIREMENTS.md (lines 71-76, traceability 140-143); no orphaned requirements. The REQUIREMENTS.md checkboxes and traceability rows still read Pending/unchecked; updating them is orchestrator close-out bookkeeping, not a code gap.

## Behavioral Spot-Checks and Gate Evidence

| Check | Result | Status |
|---|---|---|
| Fresh-build re-run in this verification (MIX_BUILD_PATH=RUNS/_build_187_verify_test): doctor_fidelity, evidence, provenance, loopback_origin_harness, crosswake_doctor, verify_navigation_shell tests (verify-187.out/.exit) | exit 0, 85 tests, 0 failures | PASS |
| 25 mutation controls (mutation-187.log), control 0 unmutated green | all 24 mutants failed as expected in named tests | PASS |
| Full-suite failure set vs Phase 186 (diff fix-186.failures fix-187.failures) | identical: only `phase180_twin_feasibility_test.exs:30` (full exit 2 is that one baseline failure) | PASS |
| Compile, format, docsync, guides, ledger, bash -n, checker, post-commit (*.exit) | all 0 | PASS |
| green-187-02 initial run exit 2 (87 failures, stale shared build) | Reconciled: orch-fresh-187-02 on fresh build exit 0, 295 tests 0 failures; accepted deviation in 187-02 SUMMARY | PASS (accepted) |
| Adoption scan | exit 1 with five `routing.unclassified_path` findings under examples/phoenix_host/native/ios/crosswake_shell; set equals the 186 carried set | PASS (carried, pre-existing) |
| Home-path scan of phase/evidence files | 0 home path, 0 username | PASS |

## Anti-Patterns / Review

187-REVIEW: 0 critical. WR-01 accepted by design (D-01); WR-03 deferred (D-09, recorded in DEFERRALS known gaps); WR-02 (`commit_ref` scrubs only three `GIT_*` vars; nested host without own `.git` could report enclosing HEAD) and WR-04 (`provenance_known?/1` public, trusts validated input) open advisory. Neither blocks a DOCTOR requirement: every caller validates first, and nested-host provenance is only advisory evidence. Recommended to fix WR-02 before Phase 188 relies on provenance from a nested host. 187-05 (loopback harness `--evidence` refusal) is an accepted D-19 deviation outside DOCTOR scope; its tests pass and controls 23-24 bite.

## Gaps Summary

None. Phase goal achieved against the candidate commit.

---

_Verified: 2026-10-16_
_Verifier: Claude (gsd-verifier)_
