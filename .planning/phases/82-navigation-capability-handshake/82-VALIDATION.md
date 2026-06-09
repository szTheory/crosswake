---
phase: 82
slug: navigation-capability-handshake
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-08
---

# Phase 82 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Backend) / XCTest (iOS) / JUnit (Android) |
| **Config file** | mix.exs / .pbxproj / build.gradle |
| **Quick run command** | `mix test test/crosswake/` |
| **Full suite command** | `mix test && ./script/verify_*.sh` |
| **Estimated runtime** | ~10 seconds |

---

## Sampling Rate

- **After every task commit:** Run quick test command
- **After every plan wave:** Run full test suite
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| Pending | TBD  | TBD  | NAV-01      | —          | N/A             | unit      | `TBD`             | ❌ W0       | ⬜ pending |
| Pending | TBD  | TBD  | NAV-02      | —          | N/A             | unit      | `TBD`             | ❌ W0       | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] iOS and Android routing delegates and shell config unit tests.
- [ ] ExUnit tests for capability parsing during mount.

*If none: "Existing infrastructure covers all phase requirements."*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Native Escape Hatch transition | NAV-01 | Requires UI/Simulator interaction | Run Demo App, click route that triggers native escape hatch. |
| Capability Handshake | NAV-02 | Requires end-to-end integration | Run Demo App, observe backend console for "Registered Capabilities: [...]". |

*If none: "All phase behaviors have automated verification."*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
