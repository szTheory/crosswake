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
| 160-01-01 | 160-01 | 1 | SCOPE-01, SCOPE-03, SCOPE-05 | T-160-01, T-160-03, T-160-05 | The first Study event requires scoped storage, the complete current host admission chain including feature and Sigra checks, and one atomic idempotency+effect transaction | core unit + Phoenix integration + Playwright tracer | `mix test test/crosswake/offline/journal_test.exs test/crosswake/offline/replay_test.exs && (cd examples/phoenix_host && MIX_ENV=test mix test test/crosswake_example/local_first/replay_admission_test.exs test/crosswake_example/local_first/study_test.exs && npm run proof:offline-island -- --grep "fully authorized scoped Study event")` | ❌ task creates/extends | ⬜ pending |
| 160-01-02 | 160-01 | 1 | SCOPE-01, SCOPE-02 | T-160-01, T-160-02, T-160-06 | Relaunch is inert, logout/switch fences first, stale completions are inert, and blocked drains retain every unaccepted entry | core unit + browser integration | `mix test test/crosswake/offline/runtime_test.exs && (cd examples/phoenix_host && npm run proof:offline-island -- --grep "inactive relaunch|switch before send|switch in flight|ordered blocked drain")` | ❌ task creates/extends | ⬜ pending |
| 160-01-03 | 160-01 | 1 | SCOPE-03, SCOPE-05 | T-160-03, T-160-05, T-160-06 | Every admission denial fails closed; rollback, duplicate, and lost-response retry never repeat or silently drop the effect | Phoenix integration | `cd examples/phoenix_host && MIX_ENV=test mix test test/crosswake_example/local_first/replay_admission_test.exs test/crosswake_example/local_first/sync_controller_test.exs test/crosswake_example/local_first/study_test.exs` | ❌ task creates | ⬜ pending |
| 160-02-01 | 160-02 | 2 | SCOPE-04 | T-160-04 | Raw payload, scope, credentials, identity, reference, endpoint, flag, media, and stable-hash canaries never reach any operational egress | unit/property-style + captured bytes | `mix test test/crosswake/offline/safe_observation_test.exs test/crosswake/offline/telemetry_test.exs test/crosswake/doctor/doctor_test.exs test/crosswake/operator_inspection/json_formatter_test.exs test/crosswake/proof/phase160_scoped_replay_privacy_test.exs` | ❌ task creates/extends | ⬜ pending |
| 160-02-02 | 160-02 | 2 | SCOPE-01, SCOPE-02, SCOPE-03, SCOPE-04, SCOPE-05 | T-160-01..T-160-06 | Closed assertions are content-bound to real host/browser/privacy results; final retained bytes stay canary-free and missing native adapters remain non-passing | artifact inspection + existing generated proof | `mix test test/crosswake/proof_lane/evidence_test.exs test/crosswake/proof/phase160_scoped_replay_privacy_test.exs && bash script/verify_phoenix_host_proof_lane.sh && bash script/verify_generated_ios_shell.sh` | ❌ task extends | ⬜ pending |
| 160-02-03 | 160-02 | 2 | SCOPE-01, SCOPE-02, SCOPE-03, SCOPE-04, SCOPE-05 | T-160-01..T-160-06 | One fresh current-tree gate records all requirement, ASVS L1, and threat evidence without promoting external unknowns | full phase gate | `mix test test/crosswake/offline test/crosswake/proof/phase160_scoped_replay_privacy_test.exs test/crosswake/proof_lane/evidence_test.exs test/crosswake/doctor/doctor_test.exs test/crosswake/operator_inspection/json_formatter_test.exs && (cd examples/phoenix_host && MIX_ENV=test mix test test/crosswake_example/local_first && npm run proof:offline-island) && bash script/verify_phoenix_host_proof_lane.sh && bash script/verify_generated_ios_shell.sh && mix crosswake.first_b2c_adopter.check && mix format --check-formatted` | ✅ command exists; task adds cases | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Plan 160-01 creates the complete tracer tests before implementation, including scope-required contracts, per-event feature/Sigra/domain admission, and atomic idempotency+effect.
- [ ] Plan 160-01 adds lifecycle/race/retention browser cases and every host denial/rollback/lost-response edge.
- [ ] Plan 160-02 creates the SafeObservation and every-egress property/canary matrix.
- [ ] Plan 160-02 extends the existing Phase 159 evidence vocabulary with named closed assertion IDs while preserving the exact schema and native non-passing boundary.

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
