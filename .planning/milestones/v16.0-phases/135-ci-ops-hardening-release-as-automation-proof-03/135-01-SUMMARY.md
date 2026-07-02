---
phase: 135-ci-ops-hardening-release-as-automation-proof-03
plan: 01
subsystem: testing
tags: [proof, ci-ops, release-please, release-as, staleness-guard, ExUnit, bash, python]

requires:
  - phase: 135-ci-ops-hardening-release-as-automation-proof-03
    provides: >
      PROOF-03 production artifacts (SC1–SC5) landed 2026-06-26:
      check_release_as_staleness.sh, strip_release_as.py, release-please.yml release-as-cleanup +
      release-failure-alert jobs, extract_companion.md Step 12f, register/check/list scripts.

provides:
  - "Hermetic ExUnit proof lane (test/crosswake/proof/phase135_ci_ops_proof_test.exs) pinning all 5 PROOF-03 SCs as merge-blocking"
  - "SC1 demonstrated RED→GREEN via GIT_DIR temp-repo injection (not merely asserted)"
  - "SC2 idempotency proven + release-as-cleanup job wiring structurally asserted"
  - "SC3 release-failure-alert if:failure() asserted; if:always() anti-pattern negatively gated"
  - "SC4 extract_companion.md Step 12f CI-automation references asserted"
  - "SC5 live parametric discovery asserted; staleness lane confirmed in output without 20-lane hardcode"
  - "Both previously-deferred core-hermetic tests (milestone_transition_reset, phase52_operator_truth) confirmed green via nested mix test"

affects:
  - future-companion-extractions
  - sigra-extraction
  - chimeway-extraction
  - threadline-extraction
  - release-pipeline

tech-stack:
  added: []
  patterns:
    - "GIT_DIR-env injection into System.cmd for hermetic git-tag proof (no real repo tags touched)"
    - "Audit-then-prove: production artifacts pre-exist; proof test is the deliverable, not a rebuild"
    - "Nested mix test assertion for deferred-failure self-proof (structural read cannot prove green)"

key-files:
  created:
    - "test/crosswake/proof/phase135_ci_ops_proof_test.exs"
  modified: []

key-decisions:
  - "D-01 audit-then-prove: PROOF-03 production code pre-existed (landed 2026-06-26); all 5 SCs audited GREEN with no production-code change"
  - "Q1 resolved: nested mix test (assert exit 0) for deferred files, NOT structural read — git-log shows both were green before Phase 135 window"
  - "SC1 GIT_DIR injection: merge System.get_env() with GIT_DIR override so PATH/env intact; bare git in script inherits GIT_DIR, no script change needed"
  - "SC2 fixture places key AFTER release-as to avoid trailing-comma JSONDecodeError (research Pitfall 1)"
  - "SC3 negative gate: refute if:always() whole-file; no other assertion in this file asserts that literal positively"
  - "SC5 no 20-lane hardcode: assert discovery exits 0 + contains merge-blocking-release-as-staleness only"

patterns-established:
  - "GIT_DIR-injection pattern for bash-script git-tag tests without touching real repo tags"
  - "Audit-then-prove pattern: land production code first, write proof test separately — proof is the permanent CI gate"

requirements-completed:
  - PROOF-03

coverage:
  - id: D1
    description: "SC1 staleness guard demonstrated RED→GREEN via GIT_DIR temp-repo injection — not just asserted"
    requirement: PROOF-03
    verification:
      - kind: unit
        ref: "test/crosswake/proof/phase135_ci_ops_proof_test.exs#SC1: staleness guard turns RED on a stale pin and GREEN after removal"
        status: pass
    human_judgment: false

  - id: D2
    description: "SC2 strip_release_as.py idempotency proven (run1 strips both keys, run2 is no-op)"
    requirement: PROOF-03
    verification:
      - kind: unit
        ref: "test/crosswake/proof/phase135_ci_ops_proof_test.exs#SC2: strip_release_as.py strips both keys then is a no-op"
        status: pass
    human_judgment: false

  - id: D3
    description: "SC2 release-as-cleanup job wiring structurally asserted in release-please.yml"
    requirement: PROOF-03
    verification:
      - kind: unit
        ref: "test/crosswake/proof/phase135_ci_ops_proof_test.exs#SC2: release-as-cleanup job is wired in release-please.yml"
        status: pass
    human_judgment: false

  - id: D4
    description: "SC3 release-failure-alert wired with if:failure() over four companion jobs; if:always() negatively gated"
    requirement: PROOF-03
    verification:
      - kind: unit
        ref: "test/crosswake/proof/phase135_ci_ops_proof_test.exs#SC3: release-failure-alert is wired with if: failure() over the four companion jobs"
        status: pass
    human_judgment: false

  - id: D5
    description: "SC4 extract_companion.md Step 12f references CI automation (PROOF-03, CI-automated, release-as-cleanup, merge-blocking-release-as-staleness)"
    requirement: PROOF-03
    verification:
      - kind: unit
        ref: "test/crosswake/proof/phase135_ci_ops_proof_test.exs#SC4: extract_companion.md Step 12f references the CI automation"
        status: pass
    human_judgment: false

  - id: D6
    description: "SC5 registration tooling dry-run-default/parametric/idempotent + detector fail-closed + live discovery asserts staleness lane"
    requirement: PROOF-03
    verification:
      - kind: unit
        ref: "test/crosswake/proof/phase135_ci_ops_proof_test.exs#SC5: registration tooling is dry-run-default, parametric, idempotent and detector is fail-closed"
        status: pass
    human_judgment: false

  - id: D7
    description: "Both previously-deferred core-hermetic tests (milestone_transition_reset, phase52_operator_truth) confirmed green via nested mix test"
    requirement: PROOF-03
    verification:
      - kind: unit
        ref: "test/crosswake/proof/phase135_ci_ops_proof_test.exs#deferred core-hermetic failures are now green: milestone_transition_reset"
        status: pass
      - kind: unit
        ref: "test/crosswake/proof/phase135_ci_ops_proof_test.exs#deferred core-hermetic failures are now green: phase52_operator_truth"
        status: pass
    human_judgment: false

duration: 3min
completed: 2026-06-28
status: complete
---

# Phase 135 Plan 01: CI-Ops Proof Lane (PROOF-03) Summary

**Hermetic ExUnit proof that pins the 5 PROOF-03 CI-ops artifacts (staleness guard, strip script, alert job, recipe Step 12f, registration tooling) as merge-blocking — SC1 demonstrated RED→GREEN via GIT_DIR injection, no production code changed**

## Performance

- **Duration:** 3 min
- **Started:** 2026-06-28T19:00:36Z
- **Completed:** 2026-06-28T19:03:41Z
- **Tasks:** 2
- **Files created:** 1

## Audit Verdict — Per-SC Status (D-01)

All five PROOF-03 production artifacts pre-existed on local main (landed 2026-06-26). Every SC audited GREEN with no production-code change applied.

| SC | Description | Verdict | Action |
|----|-------------|---------|--------|
| SC1 | check_release_as_staleness.sh: RED on stale pin, GREEN after removal | proven-no-change | GIT_DIR injection — no script edit |
| SC2 | strip_release_as.py: strips both keys, idempotent | proven-no-change | Fixture with key after release-as (Pitfall 1 guard) |
| SC2 wiring | release-as-cleanup job in release-please.yml | proven-no-change | Structural presence assert |
| SC3 | release-failure-alert with if:failure(), not if:always() | proven-no-change | Positive + negative gate |
| SC4 | extract_companion.md Step 12f CI automation references | proven-no-change | Structural presence assert |
| SC5 | dry-run-default / parametric / idempotent + fail-closed detector + live discovery | proven-no-change | Live python3 invocation, no 20-lane hardcode |

## Open-Question Q1 Decision: Deferred-Failure Self-Assertion

**Decision:** Nested `mix test` (assert exit 0), NOT a structural file read.

**Rationale:** `git log` shows `milestone_transition_reset_test.exs` and `phase52_operator_truth_test.exs` were last edited in phases 111 and 124/124-02 respectively — both before the Phase 135 window. The "fix" was upstream STATE/REQUIREMENTS state changes that unblocked the test runner from including those files; no code in the test files themselves changed. A structural read of the test source would only verify the file exists and has valid syntax, not that the tests pass. The faithful, minimum-trust proof is to run them and assert exit 0. Both exited 0 — confirmed green.

## Accomplishments

- Created `test/crosswake/proof/phase135_ci_ops_proof_test.exs` (9 tests, all green)
- SC1 marquee proof: `check_release_as_staleness.sh` demonstrated RED (exit 1, "STALE" in output) against a temp repo with a synthetic `crosswake_rulestead-v0.1.0` tag, then GREEN (exit 0) with the pin removed — via GIT_DIR-env injection, no real repo tags touched
- SC2 idempotency: `strip_release_as.py` strips `release-as` + `_TODO_release_as` on run 1 (prints "stripped"), no-op on run 2 (prints "no change"), non-final-key fixture avoids trailing-comma JSONDecodeError
- SC2–SC5 structural wiring pinned so CI-ops automation cannot silently drift
- Both deferred core-hermetic tests confirmed green via nested `mix test`
- Full hermetic suite: 1182/0 (baseline 1173 + 9 new proof tests)

## Task Commits

1. **Tasks 1 + 2: SC1–SC5 proof lane (complete file)** — `bcf8a66` (test)

## Files Created

- `test/crosswake/proof/phase135_ci_ops_proof_test.exs` — Phase 135 PROOF-03 hermetic proof lane (9 tests: SC1 RED→GREEN, SC2 idempotency, SC2-wiring, SC3, SC4, SC5, deferred×2, no-@moduletag guard)

## Decisions Made

- **D-01 audit-then-prove confirmed:** All 5 SCs GREEN, no production-code change needed or applied
- **Q1 resolved:** Nested `mix test` for deferred files — git-log proves they pre-date Phase 135; structural read cannot prove green
- **GIT_DIR injection:** `System.get_env() |> Map.put("GIT_DIR", git_dir) |> Map.to_list()` preserves PATH while redirecting bare `git rev-parse` to the temp repo
- **SC2 fixture discipline:** Key placed after `release-as` (not last) to avoid trailing-comma JSONDecodeError (research Pitfall 1 confirmed real)
- **SC3 negative gate:** `refute String.contains?(source, "if: always()")` — whole-file check is safe because no other assertion in this file positively asserts that literal

## Deviations from Plan

None — plan executed exactly as written. All 5 SCs audited GREEN; no production-code change was applied.

## Deferred / Out-of-Scope Items NOT Done in This Phase

The following are intentionally deferred and are NOT blockers for this plan's completion:

1. **v16.0 → origin sync:** Local `main` is ~100 commits ahead of `origin/main`. Will sync in one catch-up PR at milestone boundary (documented in MEMORY.md).
2. **`DRY_RUN=0` admin required-check registration:** `register_required_checks.sh` defaults to `DRY_RUN=1` (safe). Actual branch-protection registration requires a maintainer with repo-admin `gh` auth scope. This is the legitimate human gate (D-03) — not recurring toil. Deferred to the next maintenance window.
3. **Live-fire of the real cleanup PR + alert issue (D-03):** The `release-as-cleanup` job will fire automatically on the next companion release. The `release-failure-alert` issue will open only on actual publish failure. Neither can be triggered without a real companion release. SC5 closes on tooling correctness in-phase (dry-run-default, parametric, idempotent, fail-closed detector, live discovery output asserted).

## Issues Encountered

None.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes introduced. The proof test uses `System.tmp_dir!()` + `on_exit` cleanup; `GIT_DIR` isolation prevents touching real tags; real `release-please-config.json` not written. No new threat surface (T-135-01 through T-135-SC confirmed mitigated as designed).

## Next Phase Readiness

- PROOF-03 is now permanently merge-blocking via the hermetic proof lane
- The CI-ops automation (staleness guard, strip script, cleanup job, alert job, registration tooling) cannot silently drift — any regression will turn the proof lane RED before merge
- Future companion extractions (sigra, chimeway, threadline) inherit the 0-human release ops from Step 12f (SC4 asserted); the parametric `list_merge_blocking_checks.py` will automatically include their new merge-blocking lanes in registration with no new wiring (SC5 proven)

## Self-Check: PASSED

- `test/crosswake/proof/phase135_ci_ops_proof_test.exs` exists: FOUND
- Commit `bcf8a66` exists: FOUND (`test(135-01): add Phase 135 CI-ops proof lane (PROOF-03 SC1–SC5)`)
- `git status --porcelain release-please-config.json`: empty (real config untouched)
- Proof lane: 9 tests, 0 failures
- Full suite: 1182 tests, 0 failures

---
*Phase: 135-ci-ops-hardening-release-as-automation-proof-03*
*Completed: 2026-06-28*
