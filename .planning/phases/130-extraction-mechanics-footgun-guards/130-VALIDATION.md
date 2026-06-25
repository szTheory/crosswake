---
phase: 130
slug: extraction-mechanics-footgun-guards
status: draft
nyquist_compliant: false
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
| {N}-01-01 | 01 | 1 | EXTRACT-01 | — | core `mix.exs` contains no `MIX_INCLUDE_RULESTEAD`/`MIX_INCLUDE_RINDLE` | source assertion | `mix test test/crosswake/proof/phase130_extraction_guards_test.exs` | ❌ W0 | ⬜ pending |
| {N}-02-01 | 0X | — | EXTRACT-03 | — | no `Crosswake.Companions.Rulestead` alias/remote-call AST node in `lib/**/*.ex`; `Companions.Sigra`/`Chimeway` stay legal | AST walk | `mix test test/crosswake/proof/phase130_extraction_guards_test.exs` | ❌ W0 | ⬜ pending |
| {N}-03-01 | 0X | — | EXTRACT-04 | — | every `Code.ensure_loaded?` node inside a `def`/`defp`/`defmacro` body; zero at module-eval | AST prune-walk + belt regex | `mix test test/crosswake/proof/phase130_extraction_guards_test.exs` | ❌ W0 | ⬜ pending |
| {N}-04-01 | 0X | — | EXTRACT-02 | — | package tarball excludes `test/`, includes adapter source; `hex.publish --dry-run` exit 0; `--warnings-as-errors` clean engine-absent | shell verify + compile | `script/verify_companion_package.sh` | ❌ W0 | ⬜ pending |
| {N}-05-01 | 0X | — | COMPAT-01 | — | RouteGate denies gated route with `reason: :dependency_missing`, `missing_kind` correct; precedence `dependency_missing → kill_switch → gate_denied`; raise still fails closed | behavior test | `mix test test/crosswake/proof/phase130_fail_closed_contract_test.exs` | ❌ W0 | ⬜ pending |

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
