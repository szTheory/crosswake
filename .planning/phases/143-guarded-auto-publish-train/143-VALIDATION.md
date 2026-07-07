---
phase: 143
slug: guarded-auto-publish-train
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-07
---

# Phase 143 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit on Elixir 1.19.5 |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `elixir script/check_release_workflow_integrity.exs && mix test test/crosswake/proof/phase142_release_integrity_test.exs` |
| **Full suite command** | `mix verify` |
| **Estimated runtime** | ~60-180 seconds for focused proof; full verify depends on native/proof lanes |

---

## Sampling Rate

- **After every task commit:** Run `elixir script/check_release_workflow_integrity.exs` plus the focused ExUnit assertion for the touched invariant.
- **After every plan wave:** Run `mix test test/crosswake/proof/phase142_release_integrity_test.exs`.
- **Before `/gsd:verify-work`:** Run `mix verify` and the focused release integrity proof.
- **Max feedback latency:** 180 seconds for the focused release proof.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 143-01-01 | 01 | 1 | AUTO-01 | T-143-01 | Automatic Hex publish preflights exact package/version before irreversible publish and never uses `--replace`. | semantic scanner + ExUnit fixture | `mix test test/crosswake/proof/phase142_release_integrity_test.exs --only phase143_auto_publish` | Existing file; assertions pending | pending |
| 143-02-01 | 02 | 1 | AUTO-03 | T-143-02 | Manual recovery rejects branch-shaped refs, prints checked-out SHA, and uses the guarded publish path. | semantic scanner + ExUnit fixture | `mix test test/crosswake/proof/phase142_release_integrity_test.exs --only phase143_recovery` | Existing file; assertions pending | pending |
| 143-03-01 | 03 | 2 | AUTO-02 | T-143-03 | Release Please keeps root Hex/iOS/Android in the lockstep group while companions remain independent with honest floors. | config assertion + docs/status source assertion | `mix test test/crosswake/proof/phase142_release_integrity_test.exs --only phase143_version_graph` | Existing file; assertions pending | pending |

---

## Wave 0 Requirements

- [ ] `script/check_release_workflow_integrity.exs` has stable Phase 143 check IDs for guarded Hex publish and recovery invariants.
- [ ] `test/crosswake/proof/phase142_release_integrity_test.exs` has positive and negative fixtures for Phase 143 invariants.
- [ ] Registry-state ambiguity for `crosswake_rulestead` and `crosswake_rindle` is rechecked before execution relies on current live-package assumptions.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Live Hex state for `crosswake_rulestead` and `crosswake_rindle` | AUTO-01, AUTO-03 | Live registries are not mandatory in normal CI; research saw 404s for manifest `0.1.0` and this may require maintainer judgment before a first-publish-like run. | Probe `https://hex.pm/api/packages/crosswake_rulestead/releases/0.1.0` and `https://hex.pm/api/packages/crosswake_rindle/releases/0.1.0`; record whether Phase 143 treats absence as normal publish or escalates. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies.
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify.
- [ ] Wave 0 covers all MISSING references.
- [ ] No watch-mode flags.
- [ ] Feedback latency < 180s for focused release proof.
- [ ] `nyquist_compliant: true` set in frontmatter.

**Approval:** pending
