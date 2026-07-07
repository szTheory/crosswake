---
phase: 144
slug: published-core-compatibility-clean-room-proof
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-07-07
---

# Phase 144 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit bundled with Elixir/Mix 1.19.5 |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `elixir script/check_release_workflow_integrity.exs && mix test test/crosswake/proof/phase142_release_integrity_test.exs` |
| **Full suite command** | `mix verify` |
| **Estimated runtime** | ~180 seconds targeted, full suite project-dependent |

---

## Sampling Rate

- **After every task commit:** Run the focused command named in the task's `<verify>` block.
- **After every plan wave:** Run `elixir script/check_release_workflow_integrity.exs && mix test test/crosswake/proof/phase142_release_integrity_test.exs && mix test test/mix/tasks/crosswake_doctor_router_test.exs`.
- **Before `/gsd:verify-work`:** Run `mix verify` plus the targeted release/doctor commands above.
- **Max feedback latency:** ~180 seconds for targeted release/doctor feedback.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 144-01-01 | 01 | 1 | PREF-01 | T-144-01 | Package/version input is allowlisted and semver-validated before registry or file interpolation | script unit/fixture | `mix test test/crosswake/proof/phase142_release_integrity_test.exs --only phase144_cleanroom` | ❌ W0 | ⬜ pending |
| 144-01-02 | 01 | 1 | PREF-01 | T-144-02 | Hex metadata owns `requirements.crosswake.requirement`; lockfile selected versions are postconditions | script unit/fixture | `mix test test/crosswake/proof/phase142_release_integrity_test.exs --only phase144_cleanroom` | ❌ W0 | ⬜ pending |
| 144-02-01 | 02 | 2 | PREF-02 | T-144-03 | Doctor loads a freshly compiled Phoenix router without starting the host app | Mix task integration | `mix test test/mix/tasks/crosswake_doctor_router_test.exs` | ❌ W0 | ⬜ pending |
| 144-02-02 | 02 | 2 | PREF-02 | T-144-04 | Router unavailable and non-router failures produce distinct diagnostics | Mix task integration | `mix test test/mix/tasks/crosswake_doctor_router_test.exs` | ❌ W0 | ⬜ pending |
| 144-03-01 | 03 | 3 | PREF-03 | T-144-05 | Static scanner fails release-graph, proof-order, dependency-floor, and mirror-preflight regressions | scanner + ExUnit negative fixtures | `elixir script/check_release_workflow_integrity.exs && mix test test/crosswake/proof/phase142_release_integrity_test.exs` | ✅ partial | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/crosswake/proof/phase142_release_integrity_test.exs` — Phase 144 scanner IDs and negative fixtures for local-floor use, missing exact pin, missing lockfile assertion, missing package family member, and doctor pre-load masking.
- [ ] `test/mix/tasks/crosswake_doctor_router_test.exs` — fresh router, unavailable module, and non-router module tests.
- [ ] `script/check_release_workflow_integrity.exs` — stable PREF-03 check IDs for clean-room exactness and doctor-owned fresh-router proof.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Live Hex proof for packages that currently return 404 | PREF-01 | `crosswake_rulestead` and `crosswake_rindle` returned 404 in research; real release proof must fail closed until registry truth exists | Run `script/verify_companion_cleanroom.sh PACKAGE VERSION ...` for an exact live release after publish and confirm `[crosswake]` logs name package, version, derived floor, selected core version, and failure state |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 180s for targeted checks
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-07-07
