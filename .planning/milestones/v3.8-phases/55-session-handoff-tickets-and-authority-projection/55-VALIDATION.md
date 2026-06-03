---
phase: 55
slug: session-handoff-tickets-and-authority-projection
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-02
---

# Phase 55 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit |
| **Config file** | `mix.exs` |
| **Quick run command** | `mix test test/crosswake/companions/sigra/handoff_test.exs test/crosswake/proof/phase55_session_handoff_tickets_test.exs` |
| **Full suite command** | `mix test --exclude requires_example_host` |
| **Estimated runtime** | ~30-90 seconds scoped; full suite depends on existing planning-transition parity caveat |

---

## Sampling Rate

- **After every task commit:** Run the scoped Phase 55 ExUnit command for the touched surface.
- **After every plan wave:** Run `mix test --exclude requires_example_host`.
- **Before `$gsd-verify-work`:** Full suite should be green or any pre-existing failures must be isolated to the known planning-transition parity failures already tracked in `.planning/STATE.md`.
- **Max feedback latency:** 90 seconds for scoped checks.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 55-01-01 | 01 | 1 | HAND-01 | T-55-01 | Handoff envelope rejects authority-bearing and sensitive fields | unit | `mix test test/crosswake/companions/sigra/handoff_test.exs` | ✅ W0 | ✅ green |
| 55-01-02 | 01 | 1 | HAND-03 | T-55-02 | `auth.handoff.*` codes preserve public `:step_up_required` and sanitize shell details | unit | `mix test test/crosswake/companions/sigra/handoff_test.exs test/crosswake/proof/phase55_session_handoff_tickets_test.exs` | ✅ W0 | ✅ green |
| 55-02-01 | 02 | 1 | HAND-01 | T-55-03 | Example host issues signed envelopes backed by one-time server records | integration | `mix test test/crosswake/proof/phase55_session_handoff_tickets_test.exs` | ✅ W0 | ✅ green |
| 55-02-02 | 02 | 1 | HAND-02 | T-55-04 | Redemption atomically consumes one ticket, appends audit evidence, renews host session instructions, and projects `SessionAuthorityLane` | integration | `mix test test/crosswake/proof/phase55_session_handoff_tickets_test.exs` | ✅ W0 | ✅ green |
| 55-02-03 | 02 | 1 | HAND-03 | T-55-05 | Expired, replayed, revoked, binding-mismatched, intent-mismatched, and route-mismatched tickets deny with stable sanitized codes | integration | `mix test test/crosswake/proof/phase55_session_handoff_tickets_test.exs` | ✅ W0 | ✅ green |
| 55-03-01 | 03 | 2 | HAND-01, HAND-02, HAND-03 | T-55-06 | Doctor/support/operator/docs truth claims shipped handoff contracts without claiming ceremony, OAuth/passkey returns, provider proof, or refresh-token helpers | docs-contract | `mix test test/crosswake/guides/companions_test.exs test/crosswake/support_matrix/support_matrix_test.exs test/crosswake/operator_inspection/operator_inspection_test.exs test/crosswake/doctor/doctor_test.exs` | ✅ W0 | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `test/crosswake/companions/sigra/handoff_test.exs` — core Sigra handoff contract, denial-code, and sanitizer proof stubs.
- [x] `test/crosswake/proof/phase55_session_handoff_tickets_test.exs` — hermetic phase proof covering issue, redeem, expire, replay, revoke, mismatch, audit metadata, and no-claim assertions.
- [x] Example-host migration/test fixtures for `sigra_handoff_tickets` and `sigra_handoff_audit_events` — Ecto-backed example proof confirmed in place.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None | HAND-01, HAND-02, HAND-03 | Phase 55 is contract/example-host proof and should be hermetic | All phase behaviors must be covered by ExUnit or docs-contract tests |

---

## Validation Sign-Off

- [x] All tasks have automated verification or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency < 90s for scoped checks
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-06-03

---

## Validation Audit 2026-06-03

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

All 6 tasks (HAND-01, HAND-02, HAND-03; T-55-01 … T-55-06) verify through the merge-blocking proof `test/crosswake/proof/phase55_session_handoff_tickets_test.exs` and the `test/crosswake/companions/sigra/handoff_test.exs` unit suite. Audit re-ran the proof (`10 tests, 0 failures`) and the layered Phase 54-58 proof lane (`40 tests, 0 failures`). Per-Task Map statuses advanced from `passed` → `✅ green`, `File Exists` column updated from `no` → `✅ W0`, Wave 0 checkboxes checked. Frontmatter advanced from `status: passed` / `wave_0_complete: false` to `status: validated` / `wave_0_complete: true`. Sign-Off checkboxes fully checked. No MISSING or PARTIAL requirements remain. Phase 55 is Nyquist-compliant.
