---
phase: 146
slug: release-status-dx-docs-truth
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-07-08
---

# Phase 146 - Validation Strategy

Per-phase validation contract for `mix crosswake.release.status`, JSON automation output, optional live probes, and docs truth.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit through Mix 1.19.x |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test test/mix/tasks/crosswake_release_status_test.exs` |
| **Full suite command** | `elixir script/check_release_workflow_integrity.exs && mix test test/crosswake/proof/phase142_release_integrity_test.exs test/mix/tasks/crosswake_release_status_test.exs` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/mix/tasks/crosswake_release_status_test.exs`
- **After every plan wave:** Run `elixir script/check_release_workflow_integrity.exs && mix test test/crosswake/proof/phase142_release_integrity_test.exs test/mix/tasks/crosswake_release_status_test.exs`
- **Before `/gsd:verify-work`:** Run the full suite plus `mix test test/crosswake/proof/phase145_ios_backfill_script_test.exs`
- **Max feedback latency:** 60 seconds for focused release-status tests

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 146-01-01 | 01 | 1 | STAT-01 | T-146-01 | Status task is read-only and reports local graph truth without stale phase caveats | unit + scanner | `elixir script/check_release_workflow_integrity.exs && mix test test/mix/tasks/crosswake_release_status_test.exs` | yes | pending |
| 146-02-01 | 02 | 2 | STAT-02 | T-146-02 | JSON mode emits stable machine fields only and exits 0 for ok/warning | unit | `mix test test/mix/tasks/crosswake_release_status_test.exs` | yes | pending |
| 146-03-01 | 03 | 3 | STAT-03 | T-146-03 | Live probes are opt-in, bounded, advisory, and distinguish ok/missing/unavailable | unit with injected probes | `mix test test/mix/tasks/crosswake_release_status_test.exs` | yes | pending |
| 146-03-02 | 03 | 3 | STAT-01, STAT-02, STAT-03 | T-146-04 | Docs separate status, compatibility-floor, and mutation authorities | docs contract | `rg -n "Phase 146|future status|not yet published|PREF validation remains" docs guides CHANGELOG.md README.md lib test` | yes | pending |

*Status: pending, green, red, flaky*

---

## Wave 0 Requirements

- [ ] `test/mix/tasks/crosswake_release_status_test.exs` asserts local status truth, scanner-backed evidence, JSON schema fields, exit behavior, and live taxonomy.
- [ ] `script/check_release_workflow_integrity.exs` remains green and is used as authoritative release-integrity evidence.
- [ ] Docs grep checks identify stale future-phase or already-published package wording before closeout.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Public registry availability during real `--live` run | STAT-03 | Network and registry state are intentionally optional and not deterministic in normal CI | Run `mix crosswake.release.status --live` locally when network is available; confirm registry misses/unavailable states are warnings with next actions, not local errors. |

---

## Validation Sign-Off

- [x] All tasks have automated verify commands or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency under 60 seconds for focused tests
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
