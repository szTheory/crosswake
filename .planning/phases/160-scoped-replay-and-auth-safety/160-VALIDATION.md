---
phase: 160
slug: scoped-replay-and-auth-safety
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-02
---

# Phase 160 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit; Playwright 1.60.0 |
| **Config file** | `mix.exs`; `examples/phoenix_host/playwright.config.ts` |
| **Quick run command** | `mix test test/crosswake/offline/journal_test.exs test/crosswake/offline/replay_test.exs test/crosswake/offline/telemetry_test.exs` |
| **Full suite command** | `mix test && (cd examples/phoenix_host && npm test)` |
| **Estimated runtime** | ~300 seconds |

---

## Sampling Rate

- **After every task commit:** Run the focused ExUnit or Playwright command for the modified seam.
- **After every plan wave:** Run `mix test && (cd examples/phoenix_host && npm test)`.
- **Before `$gsd-verify-work`:** Run the full suite plus the Phase 159-compatible generated proof/evidence scan; blocked native/device output is non-passing.
- **Max feedback latency:** 300 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 160-W0-01 | TBD | 0 | SCOPE-01 | T-160-01 | Every envelope requires opaque scope and no query can cross partitions | unit + Playwright | `mix test test/crosswake/offline/journal_test.exs test/crosswake/offline/replay_test.exs && (cd examples/phoenix_host && npm run proof:offline-island)` | ❌ W0 | ⬜ pending |
| 160-W0-02 | TBD | 0 | SCOPE-02 | T-160-02 | Logout/account switch fences replay; stale completions are inert and queued data remains | unit + browser integration | `mix test test/crosswake/offline/replay_test.exs && (cd examples/phoenix_host && npm run proof:offline-island)` | ❌ W0 | ⬜ pending |
| 160-W0-03 | TBD | 0 | SCOPE-03 | T-160-03 | Backend reauthorizes every event and commits idempotency with the host mutation | Phoenix integration + Playwright | `(cd examples/phoenix_host && MIX_ENV=test mix test && npm run proof:offline-island)` | ❌ W0 | ⬜ pending |
| 160-W0-04 | TBD | 0 | SCOPE-04 | T-160-04 | Raw payload, scope, credentials, and identity canaries never reach diagnostics or evidence | unit + artifact inspection | `mix test test/crosswake/offline/telemetry_test.exs && mix crosswake.first_b2c_adopter.check` | ❌ W0 | ⬜ pending |
| 160-W0-05 | TBD | 0 | SCOPE-05 | T-160-05 | Sigra exposes replay-only allow/deny authority and denies missing/incompatible adapters | companion unit + host integration | `(cd packages/crosswake_sigra && mix test) && (cd examples/phoenix_host && MIX_ENV=test mix test)` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Extend core offline contract tests for scope-required maps, blocked outcomes, and safe-observation serialization.
- [ ] Add host controller/context integration tests for exact scope mismatch, per-event gate changes, rollback/lost-response duplicates, and retained outcomes.
- [ ] Extend the host Playwright proof adapter/spec for two scopes, relaunch inactive, switch-before-send, switch-in-flight, and raw-canary exclusion.
- [ ] Extend Sigra tests for replay-only closed projection and missing/incompatible adapter denial.
- [ ] Extend Phase 159 evidence schema/scanner assertions with named Phase 160 closed assertion IDs only.

---

## Manual-Only Verifications

All phase behaviors have automated verification. Host-issued real scope values and adopter route inputs remain external prerequisites and must not be inferred.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 300 seconds
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
