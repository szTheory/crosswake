---
phase: 60
slug: example-host-registry-and-phoenix-wiring
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-02
---

# Phase 60 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test test/crosswake/proof/phase60_chimeway_registry_test.exs` |
| **Full suite command** | `mix test test/crosswake/companions/chimeway test/crosswake/proof/phase59_chimeway_contract_test.exs test/crosswake/proof/phase60_chimeway_registry_test.exs` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/crosswake/proof/phase60_chimeway_registry_test.exs`
- **After every plan wave:** Run `mix test test/crosswake/companions/chimeway test/crosswake/proof/phase59_chimeway_contract_test.exs test/crosswake/proof/phase60_chimeway_registry_test.exs`
- **Before `$gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 60-01-01 | 01 | 1 | TOKN-03 | T-60-01 | Schema stores token refs/fingerprints only and defines active uniqueness without raw token columns. | proof | `mix test test/crosswake/proof/phase60_chimeway_registry_test.exs` | ✅ W0 | ✅ green |
| 60-01-02 | 01 | 1 | TOKN-03 | T-60-02 | Changesets use closed vocabularies, named constraints, scope/session validation, and metadata sanitization. | proof | `mix test test/crosswake/proof/phase60_chimeway_registry_test.exs` | ✅ W0 | ✅ green |
| 60-02-01 | 02 | 2 | TOKN-03 | T-60-03 | Initial bind and same-token refresh require backend context and preserve lifecycle history. | proof | `mix test test/crosswake/proof/phase60_chimeway_registry_test.exs` | ✅ W0 | ✅ green |
| 60-02-02 | 02 | 2 | TOKN-03 | T-60-04 | Rotation, logout/session revocation, permission loss, provider invalidation, and stale pruning write explicit backend lifecycle states. | proof | `mix test test/crosswake/proof/phase60_chimeway_registry_test.exs` | ✅ W0 | ✅ green |
| 60-02-03 | 02 | 2 | TOKN-03 | T-60-05 | Audit rows are written transactionally and telemetry emits only after commit with sanitized metadata. | proof | `mix test test/crosswake/proof/phase60_chimeway_registry_test.exs` | ✅ W0 | ✅ green |
| 60-03-01 | 03 | 3 | TOKN-03 | T-60-06 | Phase proof covers all lifecycle paths, raw-token absence, telemetry rollback behavior, and no worker dependencies. | proof | `mix test test/crosswake/proof/phase60_chimeway_registry_test.exs` | ✅ W0 | ✅ green |
| 60-03-02 | 03 | 3 | TOKN-03 | T-60-07 | Optional worker guidance remains non-compiled and host-owned; no Oban/Quantum/Broadway dependency is introduced. | proof | `mix test test/crosswake/proof/phase60_chimeway_registry_test.exs` | ✅ W0 | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. The phase should create `test/crosswake/proof/phase60_chimeway_registry_test.exs` during implementation and use it as the merge-blocking TOKN-03 proof lane.

---

## Manual-Only Verifications

All Phase 60 behaviors have automated verification.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-06-02

---

## Validation Audit 2026-06-02

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

All 7 tasks (TOKN-03, T-60-01 … T-60-07) verify through the single merge-blocking proof `test/crosswake/proof/phase60_chimeway_registry_test.exs`. Audit re-ran the proof (`18 tests, 0 failures`) and the full phase suite (`mix test test/crosswake/companions/chimeway test/crosswake/proof/phase59_chimeway_contract_test.exs test/crosswake/proof/phase60_chimeway_registry_test.exs` → `42 tests, 0 failures`). Per-Task Map statuses advanced ⬜ pending → ✅ green. No MISSING or PARTIAL requirements; no auditor agent or new tests required. Phase 60 is Nyquist-compliant.
