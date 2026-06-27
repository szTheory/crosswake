---
phase: 130
slug: extraction-mechanics-footgun-guards
status: planned
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-25
---

# Phase 130 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `130-RESEARCH.md` § Validation Architecture. The planner fills the
> Per-Task Verification Map once PLAN.md task IDs exist.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (built into Elixir 1.19.5 / OTP 28) |
| **Config file** | `test/test_helper.exs` (exists) |
| **Quick run command** | `mix test test/crosswake/proof/phase130_extraction_guards_test.exs test/crosswake/proof/phase130_fail_closed_contract_test.exs` |
| **Full suite command** | `mix test --exclude requires_example_host --exclude advisory_only` |
| **Companion-package command** | `(cd packages/crosswake_rulestead && mix test)` (via root alias `mix companions.test` / folded into `mix verify`) |
| **Estimated runtime** | ~60–120 seconds (core proof lane); package build verify adds ~30s |

---

## Sampling Rate

- **After every task commit:** Run the **Quick run command** (the two new proof files).
- **After every plan wave:** Run the **Full suite command** + `(cd packages/crosswake_rulestead && mix compile --warnings-as-errors && mix test)`.
- **Before `/gsd-verify-work`:** Full suite green AND `script/verify_companion_package.sh` green (`hex.build --unpack` excludes `test/`, `hex.publish --dry-run` exit 0, `--warnings-as-errors` clean in engine-absent state).
- **Max feedback latency:** ~120 seconds.

---

## Per-Task Verification Map

> Populated by the planner once task IDs exist. Anchor each row to a success
> criterion below. Every SC has an automated command — no SC is manual-only.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 130-01 (all) | 01 | 0 | scaffold | T-130-01/02 | red proof targets + CompanionGuard API + package skeleton + verify script exist | scaffold | `mix test test/crosswake/proof/phase130_extraction_guards_test.exs test/crosswake/proof/phase130_fail_closed_contract_test.exs` | ❌→✅ W0 | ⬜ pending |
| 130-02-01 | 02 | 1 | COMPAT-01 | — | `:dependency_missing` is the 13th Denial reason; fixtures regenerated; no exhaustive-case regression | enum + fixture | `mix test test/crosswake/doctor/doctor_test.exs` | ✅ W0 stub | ⬜ pending |
| 130-02-02 | 02 | 1 | COMPAT-01 | T-130-03/04/05 | RouteGate denies gated route `reason: :dependency_missing`, correct `missing_kind`; precedence `dependency_missing → kill_switch → gate_denied`; raise still fails closed (D-08) | behavior test | `mix test test/crosswake/proof/phase130_fail_closed_contract_test.exs` | ✅ W0 stub | ⬜ pending |
| 130-03-01 | 03 | 1 | EXTRACT-04, EXTRACT-03 | T-130-06/07/08 | `Code.ensure_loaded?` inside function bodies only; Rulestead alias detected, Sigra exempt (logic) | AST prune-walk + belt | `mix compile --warnings-as-errors` | ✅ W0 stub | ⬜ pending |
| 130-03-02 | 03 | 1 | EXTRACT-04 | T-130-06 | EXTRACT-04 green vs real lib/; non-vacuity controls green; D-27 runtime:false guard green | AST walk | `mix test test/crosswake/proof/phase130_extraction_guards_test.exs` | ✅ W0 stub | ⬜ pending |
| 130-04-01 | 04 | 2 | EXTRACT-02 | T-130-11 | adapter moved out of core lib/; @compile + config-indirection; core tests still green | move + refactor | `mix test test/crosswake/proof/phase130_extraction_guards_test.exs test/crosswake/proof/phase130_fail_closed_contract_test.exs` | ✅ | ⬜ pending |
| 130-04-02 | 04 | 2 | EXTRACT-01, EXTRACT-02 | T-130-09 | no `MIX_INCLUDE_*` in core mix.exs; test split; engine-present lane stubbed + tagged | source assertion | `mix run -e "no MIX_INCLUDE check"` | ✅ | ⬜ pending |
| 130-04-03 | 04 | 2 | EXTRACT-02 | T-130-10/SC | package tarball excludes `test/`, includes adapter source; `hex.publish --dry-run` exit 0; `--warnings-as-errors` clean engine-absent | shell verify + compile | `script/verify_companion_package.sh crosswake_rulestead` | ✅ | ⬜ pending |
| 130-05-01 | 05 | 3 | EXTRACT-03 | T-130-12/14 | no `Crosswake.Companions.Rulestead` alias AST node in real `lib/**/*.ex` (post-extraction); Sigra/Chimeway stay legal | AST walk | `mix test test/crosswake/proof/phase130_extraction_guards_test.exs` | ✅ | ⬜ pending |
| 130-05-02 | 05 | 3 | EXTRACT-03 | T-130-13 | companion-lane CI: engine-absent blocking + engine-present advisory with `mix clean`; full exit gate green | CI + full suite | `mix test --exclude requires_example_host --exclude advisory_only` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/crosswake/proof/phase130_extraction_guards_test.exs` — stubs for EXTRACT-01/03/04 (SC#1/3/4), one file with `describe` blocks
- [ ] `test/crosswake/proof/phase130_fail_closed_contract_test.exs` — stub for COMPAT-01 (SC#5), core hermetic lane
- [ ] `lib/crosswake/companion_guard.ex` — `Crosswake.CompanionGuard` support module (frozen MapSet + AST walk helpers)
- [ ] `script/verify_companion_package.sh` — parameterized dress-rehearsal verify (SC#2/EXTRACT-02; reusable for rindle in 132)
- [ ] `packages/crosswake_rulestead/` skeleton — `mix.exs`, `lib/`, `test/`, `test/support/`
- [ ] `.github/workflows/phase130-proof.yml` (or fold companion job into existing CI) — companion lane

*Each new proof test must carry a positive-control / synthetic-regression assertion (research § non-vacuity) so it cannot pass vacuously.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| — | — | — | — |

*All phase behaviors have automated verification. (Note: the engine-PRESENT advisory lane (`:engine_present`) is automated but advisory-only — not merge-blocking.)*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
