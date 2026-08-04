---
phase: 162
slug: physical-iphone-adoption-proof
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-04
---

# Phase 162 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution. A simulator can exercise regressions but can never promote the physical-iPhone proof.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit/Mix, Playwright, XCTest, and XCUITest |
| **Config file** | `mix.exs`, `package.json`, and generated iOS proof target configuration |
| **Quick run command** | Focused Mix, Playwright, and iOS target tests selected by the task |
| **Full suite command** | Phoenix host browser corpus, Mix suite, package tests, then the signed physical-iPhone XCUITest driver |
| **Estimated runtime** | Under 10 minutes without device setup; physical proof duration is host/device dependent |

---

## Sampling Rate

- **After every task commit:** Run the affected ExUnit, Playwright, or XCTest/XCUITest slice.
- **After every plan wave:** Run the existing fast suite plus the generated proof-lane check.
- **Before `$gsd-verify-work`:** A fresh signed physical-iPhone run must pass every fixed assertion, promotion verification must succeed, and the final retained artifact scan must be clean.
- **Max feedback latency:** 10 minutes, excluding bounded signing/device-connection prerequisites.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 162-01-01 | TBD | 1 | DEVICE-01–05 | T-162-01 | Physical-only preflight blocks before side effects when TODO-002, device, signing, or host authority is absent. | ExUnit + XCUITest | Generated physical proof driver preflight | ❌ W0 | ⬜ pending |
| 162-01-02 | TBD | 1 | DEVICE-01–05 | T-162-02 | One sequential iPhone driver proves offline audio, local persistence, replay outcomes, scope fences, and route/feature denial through host authority. | XCUITest + Phoenix integration | Generated physical proof driver | ❌ W0 | ⬜ pending |
| 162-02-01 | TBD | 2 | DEVICE-06 | T-162-03 | Promotion accepts only `physical_iphone`, complete closed assertion outcomes, and the approved redacted evidence fields. | ExUnit | Evidence verifier test | ❌ W0 | ⬜ pending |
| 162-02-02 | TBD | 2 | DEVICE-07 | T-162-04 | Support wording remains one first-adopter iOS flow and does not claim Android, background sync, generic storage, or multiple islands. | Docs contract + ExUnit | Support-matrix contract check | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Physical-only preflight with a stable blocked result before side effects.
- [ ] Fixed DEVICE assertion enum/outcome manifest and `physical_iphone` evidence verifier tests.
- [ ] Host fixture adapter for reject, conflict, logout/switch, and feature-gate cases.
- [ ] Sequential XCUITest driver that preserves state across terminate/relaunch.
- [ ] Phoenix authority adapter returning closed, non-sensitive outcomes.
- [ ] Evidence final-directory/privacy/atomicity tests and support-matrix contract update.

---

## Manual-Only Verifications

All behavior evaluation is automated. A human may only perform unavoidable physical-device connection, signing, or external host-credential setup; the generated driver and verifier determine outcomes.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies.
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify.
- [ ] Wave 0 covers all missing DEVICE references.
- [ ] No watch-mode flags.
- [ ] Feedback latency is bounded by the generated driver and device prerequisites.
- [ ] `nyquist_compliant: true` set in frontmatter after validation.

**Approval:** pending
