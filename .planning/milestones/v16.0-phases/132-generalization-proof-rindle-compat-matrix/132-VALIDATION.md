---
phase: 132
slug: generalization-proof-rindle-compat-matrix
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-26
---

# Phase 132 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from 132-RESEARCH.md §Validation Architecture (Nyquist enabled — key absent from config = ENABLED).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (built-in, no config file — standard Elixir) |
| **Config file** | `test/test_helper.exs` (core); `packages/crosswake_rindle/test/test_helper.exs` (NEW — mirrors rulestead) |
| **Quick run command** | `mix test test/crosswake/proof/phase132_compat_matrix_drift_test.exs` |
| **Full suite command** | `mix verify` (companions.test + hermetic core suite, excluding `:requires_example_host` + `:advisory_only`) |
| **Estimated runtime** | ~drift test <2s; full `mix verify` ~CI-bound |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/crosswake/proof/phase132_compat_matrix_drift_test.exs` (COMPAT-03 gate)
- **After every plan wave:** Run `mix verify` (companions.test + hermetic core suite) + EXTRACT-03 guard (`phase130_extraction_guards_test.exs`)
- **Before `/gsd-verify-work`:** Full `mix verify` green AND EXTRACT-03 guard green
- **Max feedback latency:** ~drift test seconds; full suite CI-bound

---

## Per-Task Verification Map

> Concrete task IDs are assigned by the planner. This map binds each phase requirement to its observable, merge-blocking proof so the planner can attach `<automated>` verify blocks.

| Requirement | Wave | Secure Behavior / Observable | Test Type | Automated Command | File Exists | Status |
|-------------|------|------------------------------|-----------|-------------------|-------------|--------|
| EXTRACT-07 | impl | rindle source + domain types absent from core `lib/`; `packages/crosswake_rindle/` compiles engine-absent | unit (guard + companion lane) | `mix test test/crosswake/proof/phase130_extraction_guards_test.exs`; `mix companions.test` | ✅ guard / ❌ W0 package | ⬜ pending |
| EXTRACT-07 | impl | Hex tarball structure correct (`test/` excluded, `lib/` source present) | integration (script) | `CROSSWAKE_RELEASE=1 bash script/verify_companion_package.sh crosswake_rindle` | ✅ (needs line ~53 fix) | ⬜ pending |
| EXTRACT-07 | publish | published artifact resolves + `mix crosswake.doctor --router` exit 0 + Contracts canary | integration (CI-only clean-room) | `bash script/verify_companion_cleanroom.sh crosswake_rindle <ver> rindle Rindle` | ✅ (needs Contracts canary append) | ⬜ pending |
| SEAM-05 | impl | no static alias to `Crosswake.Companions.Rindle` in core `lib/`; no rindle-specific branch | unit (guard) + inspection | `mix test test/crosswake/proof/phase130_extraction_guards_test.exs` | ✅ (MapSet gains Rindle) | ⬜ pending |
| COMPAT-02 | W0/impl | `guides/companion_compatibility.md` exists with package-keyed table + pinned column-contract comment | manual + drift test | `mix test test/crosswake/proof/phase132_compat_matrix_drift_test.exs` | ❌ W0 — doc NEW | ⬜ pending |
| COMPAT-03 | W0/impl | drift test fails on version mismatch, missing package row, or phantom row; non-vacuity ≥2 packages | unit (proof lane, async) | `mix test test/crosswake/proof/phase132_compat_matrix_drift_test.exs` | ❌ W0 — test NEW | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `packages/crosswake_rindle/` — entire package directory scaffolded from `crosswake_rulestead` template
- [ ] `packages/crosswake_rindle/mix.exs` — required before drift test can assert ≥2 packages (env-conditional `crosswake_dep/0`)
- [ ] `packages/crosswake_rindle/test/test_helper.exs` — companion-lane test entry point
- [ ] `test/crosswake/proof/phase132_compat_matrix_drift_test.exs` — NEW (COMPAT-02 + COMPAT-03)
- [ ] `guides/companion_compatibility.md` — NEW (COMPAT-02) with pinned column-contract HTML comment
- [ ] `test/support/stub_companion.ex` — add `StubRindleAbsentCompanion` (alongside `StubRulesteadAbsentCompanion`)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| No rindle-specific branch/special-case anywhere in core `lib/` | SEAM-05 | Reviewer-facing structural claim; EXTRACT-03 guard catches static aliases but not all prose/branch shapes | Reviewer greps `lib/` for `Rindle` and confirms only the frozen seam (behaviour + registry) references remain |
| Clean-room publish is irreversible + CI-only | EXTRACT-07 | Cannot run locally before the first `crosswake_rindle` Hex release is cut | Verify via the post-publish `clean-room-proof-rindle` CI job after the Release PR merges |

---

## Validation Sign-Off

- [ ] All requirements have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (package, drift test, matrix doc, stub)
- [ ] No watch-mode flags
- [ ] Feedback latency acceptable (drift test < a few seconds)
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
