---
quick_id: 260603-nzr
slug: tighten-validation-ledger-closeout-gate
status: complete
date: 2026-06-03
commits:
  - 80cf43b
  - a866761
  - f366f61
---

# Quick Task 260603-nzr Summary: Tighten the validation-ledger closeout gate

## One-liner

Added dual-location phase-path discovery, strict missing-ledger detection, and a new
`closeout.validation.prior_debt` backstop check with stale-deferral surfacing; `mix
closeout.verify` now fails on v3.6 unresolved prior debt as intended.

## What Changed Per Task

### Task 1 — Un-brittle archived-path globs + strict validation_ledger_check
**Commit:** `80cf43b`

- Added `milestone/1` — extracts `milestone:` value from frontmatter via regex.
- Added `expected_phases/1` — parses the `phase_verification_coverage.expected_phases` array;
  falls back to `@v39_phases` when absent (preserving mix-task fixture behavior).
- Added `phase_paths/4` — globs both `.planning/milestones/<milestone>-phases/<phase>-*/<suffix>`
  (archived) and `.planning/phases/<phase>-*/<suffix>` (live), concatenating results.
- Rewrote `validation_ledger_check/2`: now iterates expected phases; a phase with NO VALIDATION.md
  files lands in `problematic` (missing ledger is now blocking, not silently skipped).
- Rewrote `phase_verification_check/2` and `summary_frontmatter_check/2` to use the same
  `expected_phases/1` + `phase_paths/4` helpers instead of hardcoded brace-glob patterns.

### Task 2 — Add prior_validation_debt_check (Option B) + deferral staleness
**Commit:** `a866761`

- Factored `deferred_entries/1` from `malformed_deferred_entries/1`; refactored the latter to
  delegate to the former. Behavior of `deferred_shape_check` is unchanged.
- Added `entry_field/2` — extracts a named YAML field from a raw deferral entry string via regex.
- Added `stale_deferral?/2` — returns true when the entry's `revisit_phase` has a matching
  archived dir under `.planning/milestones/*-phases/<revisit>-*`.
- Added `prior_validation_debt_check/2` with stable id `closeout.validation.prior_debt`:
  - Finds all `v*-CLOSEOUT.md` files except the current one.
  - For each prior closeout, identifies `validation-ledger-finalization` entries whose `status`
    is not `resolved` or `closed`.
  - An entry is satisfied only if all expected phases have a compliant VALIDATION.md; otherwise
    it is an unsatisfied (blocking) finding.
  - Stale entries (revisit_phase has shipped) are annotated with `(stale)` in the observed text.
- Wired `prior_validation_debt_check` into `run/1` after `validation_ledger_check`.

### Task 3 — Extend tests + prove gate goes RED on real repo
**Commit:** `f366f61`

- Added `closeout.validation.prior_debt` to the stable-ids assertion.
- Added 5 new test cases:
  1. Prior debt from another milestone blocks closeout (no compliant ledgers, status: routed).
  2. Prior debt satisfied by compliant archived VALIDATION.md files passes.
  3. Prior debt satisfied by `status: resolved` entry passes.
  4. Stale deferral is surfaced as blocking and annotated `(stale)` in observed.
  5. `closeout.validation.ledger` blocks when an expected phase ledger is missing and no deferral.
- Added `write_prior_closeout!/4` fixture helper.

## Test Suites Run — All Green

```
mix test test/crosswake/planning/closeout_verifier_test.exs \
         test/mix/tasks/closeout_verify_test.exs \
         test/crosswake/planning/closeout_ci_parity_test.exs \
         test/crosswake/planning/milestone_arc_closeout_parity_test.exs

26 tests, 0 failures
```

## `mix closeout.verify` RED Output (Teeth Proof)

```
closeout.verify failed (2 blocking)
[PASS] closeout.ledger.frontmatter subject=closeout ledger frontmatter source=.planning/milestones/v3.9-CLOSEOUT.md observed=ok hint=Preserve the v3.9-CLOSEOUT.md frontmatter contract before closeout. posture=merge-blocking
[PASS] closeout.exceptions.deferred_shape subject=deferred_with_reason exception shape source=.planning/milestones/v3.9-CLOSEOUT.md observed=ok hint=Every deferred exception needs owner, scope, reason, revisit_phase, evidence, and status. posture=merge-blocking
[PASS] closeout.release.changelog_continuity subject=published versus unreleased release truth source=CHANGELOG.md observed=ok hint=Keep [Unreleased] split from published Hex 0.1.0 and label deferred support as non-shipped. posture=merge-blocking
[BLOCK] closeout.requirements.state subject=requirements closeout state source=.planning/REQUIREMENTS.md observed=REL-01 or closeout requirements_state is still pending hint=Mark REL-01 validated or archive/reset requirements with explicit closeout evidence. posture=merge-blocking
[PASS] closeout.roadmap.parity subject=roadmap closeout parity source=.planning/ROADMAP.md observed=ok hint=Archive v3.9 roadmap evidence and complete Phase 63 alignment. posture=merge-blocking
[PASS] closeout.verification.coverage subject=phase verification evidence source=.planning/phases observed=ok hint=Add phase verification files or record a shaped deferred_with_reason exception. posture=merge-blocking
[PASS] closeout.summaries.frontmatter subject=summary requirements-completed frontmatter source=.planning/phases observed=ok hint=Ensure every v3.9 SUMMARY.md has requirements-completed frontmatter. posture=merge-blocking
[PASS] closeout.validation.ledger subject=validation ledger status source=.planning/phases observed=ok hint=Mark validation ledgers Nyquist-compliant or defer them with owner/scope/reason evidence. posture=merge-blocking
[BLOCK] closeout.validation.prior_debt subject=prior milestone validation-ledger debt source=.planning/milestones/*-CLOSEOUT.md observed=v3.6: Draft Nyquist ledgers for phases 48, 49, 52, and 53 remain bookkeeping gaps; merge-blocking ExUnit proof and closeout.verify cover shipped public support truth. (stale) hint=Resolve prior validation-ledger deferrals (make named ledgers nyquist_compliant: true or mark the deferral status: resolved with evidence) before closing a new milestone. posture=merge-blocking
[PASS] closeout.handoff.thread_seed_disposition subject=thread and seed disposition source=.planning/threads,.planning/seeds observed=ok hint=Route open threads/seeds to future milestone ownership or mark shipped signals closed. posture=merge-blocking
** (Mix) closeout verification found blocking issues
```

**Interpretation:** `closeout.validation.prior_debt` blocks on the v3.6 `validation-ledger-finalization`
deferral (`status: routed`, `revisit_phase: 48`). Phase 48 is archived under `v3.7-phases/48-*`,
so the deferral is correctly surfaced as `(stale)`. No compliant VALIDATION.md files exist for
the expected v3.6 phases (48, 49, 52, 53) under any archived milestone dir. This is the intended
RED state. Step 2 (backlog cleanup) is a separate follow-up task.

Note: `closeout.requirements.state` also blocks due to an existing pre-task issue unrelated to
this change (REQUIREMENTS.md state for the active v3.9 milestone). This is out of scope for this
quick task.

## Deviations from Plan

None — plan executed exactly as specified. All critical invariants were preserved:
- `expected_phases/1` falls back to `@v39_phases` when array absent (mix-task fixtures).
- `prior_validation_debt_check` no-ops when no other milestone closeouts exist (fixture isolation).
- The current closeout is excluded from the prior scan.
- All existing check ids, subjects, hints, and pass/fail semantics preserved.
