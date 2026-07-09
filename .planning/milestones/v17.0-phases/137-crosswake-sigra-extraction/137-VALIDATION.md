---
phase: 137
slug: crosswake-sigra-extraction
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-07-01
---

# Phase 137 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `137-RESEARCH.md` § Validation Architecture (drift-verified against live code).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (built-in Elixir) |
| **Config file** | `packages/crosswake_sigra/test/test_helper.exs` (created in Wave 0) |
| **Quick run command** | `cd packages/crosswake_sigra && mix test` |
| **Full suite command** | `mix test --exclude requires_example_host && (cd packages/crosswake_sigra && mix test)` |
| **Estimated runtime** | ~90 seconds (core suite) + ~10 seconds (package lane) |

---

## Sampling Rate

- **After every task commit:** `cd packages/crosswake_sigra && mix test && mix compile --warnings-as-errors` (package tasks); `mix test <touched core test>` for core-side refactor tasks
- **After every plan wave:** Full core suite + companion lane: `mix test --exclude requires_example_host && (cd packages/crosswake_sigra && mix test)`
- **Before `/gsd-verify-work`:** Full suite green + clean-room proof green
- **Max feedback latency:** ~100 seconds

---

## Per-Requirement Verification Map

| Req ID | Behavior | Test Type | Automated Command | File Exists |
|--------|----------|-----------|-------------------|-------------|
| SIGRA-01 | All `Crosswake.Companions.Sigra.*` sub-modules compile in package context | unit | `cd packages/crosswake_sigra && mix compile --warnings-as-errors` | ❌ W0 |
| SIGRA-01 | Moved sigra tests pass in package lane | unit | `cd packages/crosswake_sigra && mix test` | ❌ W0 |
| SIGRA-01 | No `Crosswake.Companions.Sigra` refs remain in core `lib/` | structural | `grep -rq "Crosswake.Companions.Sigra" lib/ && echo FAIL || echo CLEAN` | inline |
| SIGRA-02 | No `Crosswake.Shell.Denial` ref inside `packages/crosswake_sigra/lib/` | structural | `grep -rq "Crosswake.Shell.Denial" packages/crosswake_sigra/lib/ && echo FAIL || echo CLEAN` | inline |
| SIGRA-02 | `finding_to_denial/2` `:auth` axis → `:step_up_required` with unmerged details | unit | `mix test test/crosswake/compatibility/compatibility_test.exs` | ✅ (extend) |
| SIGRA-02 | Clean-room: sigra registered → `:step_up_required` NOT `:dependency_missing` | integration | `cd packages/crosswake_sigra && mix test test/crosswake/proof/phase137_sigra_cleanroom_test.exs` | ❌ W0 |
| SIGRA-02 | `max_auth_age_seconds` guard preserved through StepUpCeremony | unit | `cd packages/crosswake_sigra && mix test test/crosswake/companions/sigra/step_up_test.exs` | ❌ W0 (moved) |
| SIGRA-02 | New `Finding` `:code`/`:details` fields additive-non-breaking | structural | `mix compile --warnings-as-errors` (core + rulestead + rindle) | inline |
| SIGRA-03 | path-dep dress rehearsal passes `mix test` | integration | core `mix test` with `crosswake_sigra` as `path:` dep | ❌ W0 |
| SIGRA-03 | `hex.publish --dry-run` succeeds | CI | `cd packages/crosswake_sigra && mix hex.publish --dry-run --yes` | CI-only |
| SIGRA-03 | `crosswake_sigra` registered as independent `elixir` release-please component | structural | assert present in `release-please-config.json`, absent from `linked-versions` group | manual/CI |

*The planner refines this into a per-task map (Task ID · Wave · Automated Command) in the PLAN.md `<verify>` blocks. Row set above is the requirement-level contract those tasks must collectively satisfy.*

---

## Backstop Tests (Required by D-137-D — must exist before phase gate)

1. **Non-vacuous clean-room proof** — `packages/crosswake_sigra/test/crosswake/proof/phase137_sigra_cleanroom_test.exs`
   - `Application.put_env(:crosswake, :companions, [Crosswake.Companions.Sigra])` in setup → `RouteGate.evaluate/4` on an auth-predicated route → assert `decision.denial.reason == :step_up_required`.
   - **Non-vacuity guard:** explicitly assert `decision.denial.reason != :dependency_missing` (without the `put_env`, fail-closed yields `:dependency_missing` and the proof would be vacuously red).

2. **step-up max-age guard** — inside `step_up_test.exs` (moved to package)
   - Assert `issue_attrs/4` populates `max_auth_age_seconds` from `finding.details["max_auth_age_seconds"]`.
   - **Security regression guard:** dropping this lookup silently removes the step-up max-age constraint.

3. **Finding-field-additive non-breaking guard** — `phase46_sigra_auth_contract_test.exs` (STAYS in core)
   - The existing "weaker mfa and stale auth age deny with minimal typed details" test (~L175-203) drives `Finding.t()` fields through `finding_to_denial/2` and checks denial details — catches field-additive regressions. No new test needed; keep it green post-refactor.

4. **No `Denial` reference inside `packages/crosswake_sigra/`** — structural grep
   - `grep -rq "Crosswake.Shell.Denial" packages/crosswake_sigra/lib/ && echo FAIL || echo CLEAN` — run as a Wave-1 commit gate and (ideally) folded into the companion AST/grep guard.

---

## Wave 0 Requirements

**No separate stub-first Wave 0 exists for this phase.** The package does not exist yet, so all
test infrastructure is created *inside* the plan waves (not pre-seeded ahead of them). Each item
below is folded into a concrete plan task rather than a pre-execution stub:

- [x] `StubSigraAbsentCompanion` in core `test/support/stub_companion.ex` → **Plan 137-01 Task 3** (Wave 1; lands before any package move, beside the existing Rulestead/Rindle stubs)
- [x] `packages/crosswake_sigra/` skeleton — `mix.exs` (`@version 0.1.0` one-shot), `README.md`, `CHANGELOG.md`, `LICENSE`, `test/test_helper.exs`, `test/support/` → **Plan 137-03 Task 1** (Wave 3; clone the rindle block, no engine dep)
- [x] `packages/crosswake_sigra/test/crosswake/proof/phase137_sigra_cleanroom_test.exs` non-vacuous proof (backstop #1) → **Plan 137-03 Task 3** (Wave 3; can only land after the skeleton in Task 1)
- [x] `cd packages/crosswake_sigra && mix deps.get` → **Plan 137-03 Task 1** (after `mix.exs` is written)

*Every plan `<verify>` block carries an `<automated>` command (confirmed by plan-checker Dimension 8);
no reference depends on a missing pre-execution stub.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Register `merge-blocking-*` required checks (carried admin ship-gate + new `clean-room-proof-sigra` lane) | SIGRA-03 / D-137-C | Branch-protection mutation — deliberate human admin action, harness-blocked | After `clean-room-proof-sigra` is green **once on main**, run `DRY_RUN=0 script/register_required_checks.sh` (green-first preflight dodges the "expected — waiting for status" deadlock) |
| Merge the sigra Release PR | SIGRA-03 / D-137-C | The auditable human go/no-go before the irreversible Hex publish | Merge only after dress-rehearsal + `hex.publish --dry-run` + clean-room lane are green |
| Merge the `release-as` cleanup PR | SIGRA-03 / D-137-C | Human confirmation the one-shot `release-as: "0.1.0"` strip is correct | Merge the auto-generated `release-as-cleanup` PR after the first sigra Release PR merges |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (folded into plan tasks — see above)
- [x] No watch-mode flags
- [x] Feedback latency < 100s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** passed 2026-07-01 (plan-checker confirmed Dimension 8 sampling; sign-off gaps resolved by orchestrator)
