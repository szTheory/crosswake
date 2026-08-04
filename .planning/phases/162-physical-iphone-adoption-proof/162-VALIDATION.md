---
phase: 162
slug: physical-iphone-adoption-proof
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-04
---

# Phase 162 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit/Mix, Playwright, XCTest/XCUITest |
| **Config file** | Existing Phoenix-host proof-lane and generated iOS Xcode targets |
| **Quick run command** | Focused Mix/Playwright/Swift proof-lane slices selected by each task |
| **Full suite command** | Phoenix browser corpus, Mix suite, Swift package tests, generated proof-lane tests, and signed physical-XCUITest invocation when prerequisites are present |
| **Estimated runtime** | ~300 seconds without a physical device; physical run depends on signed-host availability |

---

## Sampling Rate

- **After every task commit:** Run the affected focused Mix, Playwright, or Swift/XCTest slice.
- **After every plan wave:** Run the preserved browser proof corpus plus applicable generated proof-lane tests.
- **Before `$gsd-verify-work`:** Run a fresh signed physical-iPhone driver, evidence promotion verifier, and final privacy scan; missing prerequisites must return the stable blocked outcome.
- **Max feedback latency:** 300 seconds for deterministic local checks.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 162-01-01 | TBD | 1 | DEVICE-01, DEVICE-02 | T-162-01 | Device preflight fails closed before side effects; offline audio and relaunch observations stay device-local. | XCTest/XCUITest | Generated physical driver command | ❌ W0 | ⬜ pending |
| 162-01-02 | TBD | 1 | DEVICE-02, DEVICE-03, DEVICE-04, DEVICE-05 | T-162-02 | Phoenix reauthorizes replay and commits scoped accepted effects once; rejection, conflict, fencing, and disablement retain work. | ExUnit + host integration | Focused Phoenix host proof command | ❌ W0 | ⬜ pending |
| 162-01-03 | TBD | 2 | DEVICE-06 | T-162-03 | Evidence accepts only a physical-iPhone closed assertion set, reparses and rescans canonical bytes, and publishes atomically. | ExUnit | Focused proof-evidence test command | ❌ W0 | ⬜ pending |
| 162-01-04 | TBD | 2 | DEVICE-07 | T-162-04 | Support wording remains one first-adopter flow on one iOS runtime line with explicit exclusions. | Docs contract + ExUnit | Support-truth contract command | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Physical-only preflight and stable blocked outcome.
- [ ] Fixed DEVICE assertion vocabulary and `physical_iphone` evidence verifier tests.
- [ ] Host fixture adapter for rejection, conflict, account fencing, and feature-gate cases.
- [ ] Sequential XCUITest driver that preserves state across terminate/relaunch.
- [ ] Phoenix authority assertion adapter with closed non-sensitive outcomes.
- [ ] Final-directory privacy/atomicity checks and support-truth contract check.

---

## Manual-Only Verifications

All phase behaviors use automated assertion evaluation. Connecting/signing a physical iPhone and making a host backend available are setup prerequisites only; they are not human-verification gates.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies.
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify.
- [ ] Wave 0 covers all DEVICE-01 through DEVICE-07 references.
- [ ] No watch-mode flags.
- [ ] Feedback latency is bounded for deterministic checks.
- [ ] `nyquist_compliant: true` set in frontmatter.

**Approval:** pending
