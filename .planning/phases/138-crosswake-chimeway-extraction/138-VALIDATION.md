---
phase: 138
slug: crosswake-chimeway-extraction
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-02
---

# Phase 138 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (mix test) |
| **Config file** | `packages/crosswake_chimeway/mix.exs` (created this phase) + core `mix.exs` |
| **Quick run command** | `mix test <changed proof file>` (from the relevant package root) |
| **Full suite command** | core `mix test` + `packages/crosswake_chimeway` `mix test` + clean-room lane |
| **Estimated runtime** | ~120 seconds |

---

## Sampling Rate

- **After every task commit:** Run the changed proof/test file
- **After every plan wave:** Run the full suite for the touched package(s)
- **Before `/gsd-verify-work`:** Full suite must be green (core + crosswake_chimeway + clean-room lane)
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 138-01-01 | 01 | 1 | CHIME-01 | — | `Crosswake.Companions.Chimeway.*` resolve from new package path | unit | `mix test` (package) | ❌ W0 | ⬜ pending |
| 138-0X-XX | 0X | X | CHIME-02 | — | chimeway mix.exs has no `crosswake_sigra` dep; `auth_context :: map()` | unit | grep + compile | ❌ W0 | ⬜ pending |
| 138-0X-XX | 0X | X | CHIME-03 | — | clean-room lane passes with sigra ABSENT and asserts real notification work (vacuity-safe) | integration | clean-room CI lane | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `packages/crosswake_chimeway/` mix project + moved `Crosswake.Companions.Chimeway.*` modules
- [ ] Moved proof tests (phase71 → chimeway package; phase59 core/package split)
- [ ] Patched `verify_companion_cleanroom.sh` chimeway assertion (`enabled?(%{})` defaults true → `assert`, plus non-empty `forbidden_metadata_keys/0` canary to keep the lane vacuity-safe)

*If none: "Existing infrastructure covers all phase requirements."*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Irreversible `mix hex.publish` of crosswake_chimeway | CHIME-03 | Irreversible external side-effect (human go-gate, mirrors 137 wave 5) | Human runs publish only after dry-run + clean-room lane green |

*If none: "All phase behaviors have automated verification."*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
