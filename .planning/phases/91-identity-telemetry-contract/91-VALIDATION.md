---
phase: 91
slug: identity-telemetry-contract
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-09
validated: 2026-06-09
---

# Phase 91 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Phase 91 ships **zero runtime emission** — all signals are pure struct construction,
> map serialization, module-attribute accessors, and hermetic telemetry-rejection.
> Nothing here requires Ecto, network, or a device.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (project standard) |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/crosswake/threadline/ test/crosswake/bridge/contract_test.exs test/crosswake/shell/activation_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~quick: <5s · full: project-standard |

---

## Sampling Rate

- **After every task commit:** Run the quick command above
- **After every plan wave:** Run `mix test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** < 10 seconds (quick subset)

---

## Per-Task Verification Map

| Task | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| `Threadline.Telemetry.event_names/0` returns exactly 3 span names | 0 | PROP-02 | — | N/A | unit | `mix test test/crosswake/threadline/telemetry_test.exs` | ✅ created | ✅ green |
| `metadata_keys/0` == `[:thread_id, :correlation_id, :route_id, :source]` | 0 | PROP-02 | — | low-cardinality allowlist | unit | `mix test test/crosswake/threadline/telemetry_test.exs` | ✅ created | ✅ green |
| `forbidden_metadata_keys/0` contains PII keys, disjoint from allowlist | 0 | PROP-02 | T-91-PII | PII denylist enforced | unit | `mix test test/crosswake/threadline/telemetry_test.exs` | ✅ created | ✅ green |
| `metadata/1` drops forbidden keys silently (no raise) | 0 | PROP-02 | T-91-PII | fail-silent, no leak | unit | `mix test test/crosswake/threadline/telemetry_test.exs` | ✅ created | ✅ green |
| `safe_value?/1` rejects >128-char binary, nil, non-allowed types | 0 | PROP-02 | T-91-CARD | cardinality bound | unit | `mix test test/crosswake/threadline/telemetry_test.exs` | ✅ created | ✅ green |
| `execute/3` with forbidden metadata does not raise | 0 | PROP-02 | T-91-PII | fail-silent | unit | `mix test test/crosswake/threadline/telemetry_test.exs` | ✅ created | ✅ green |
| Published-allowlist proof: exact list equality | 0 | PROP-02 | — | contract is published | proof | `mix test test/crosswake/proof/phase91_threadline_contract_closeout_test.exs` | ✅ created | ✅ green |
| `Bridge.Contract.Request` has `thread_id`, default nil, NOT enforced | 0 | PROP-04 | — | N/A | unit | `mix test test/crosswake/bridge/contract_test.exs` | ✅ modified | ✅ green |
| `Bridge.Contract.Reply` has `thread_id` field | 0 | PROP-04 | — | N/A | unit | `mix test test/crosswake/bridge/contract_test.exs` | ✅ modified | ✅ green |
| `Bridge.Denial` has `thread_id` field | 0 | PROP-04 | — | N/A | unit | `mix test test/crosswake/bridge/contract_test.exs` | ✅ modified | ✅ green |
| `Shell.Activation.Request` has `thread_id`, default nil | 0 | PROP-04 | — | N/A | unit | `mix test test/crosswake/shell/activation_test.exs` | ✅ modified | ✅ green |
| `Request.to_map` nil-filters `thread_id` when nil (D-05 footgun) | 0 | PROP-04 | — | no wire-key drift | unit | `mix test test/crosswake/bridge/contract_test.exs` | ✅ modified | ✅ green |
| `Denial.to_map` nil-filters `thread_id` when nil (Types.to_map does NOT) | 0 | PROP-04 | — | no wire-key drift | unit | `mix test test/crosswake/bridge/contract_test.exs` | ✅ modified | ✅ green |
| `ok_reply` / `deny_reply` propagate `thread_id` from request (D-03) | 0 | PROP-04 | — | N/A | unit | `mix test test/crosswake/bridge/contract_test.exs` | ✅ modified | ✅ green |
| `Denial.from_request/2` propagates `thread_id` | 0 | PROP-04 | — | N/A | unit | `mix test test/crosswake/bridge/contract_test.exs` | ✅ modified | ✅ green |
| `Contract.@version` is `"1.1.0"` (informational, not gate-wired, D-04) | 0 | PROP-04 | — | N/A | proof | `mix test test/crosswake/proof/phase91_threadline_contract_closeout_test.exs` | ✅ created | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `test/crosswake/threadline/telemetry_test.exs` — covers PROP-02 (unit; mirrors `test/crosswake/companions/sigra/telemetry_test.exs`)
- [x] `test/crosswake/proof/phase91_threadline_contract_closeout_test.exs` — published-allowlist proof for PROP-02 + `@version "1.1.0"` assertion for PROP-04 (mirrors the phase-58 auth-diagnostics closeout test pattern)

*Existing `contract_test.exs` and `activation_test.exs` are modified in place to cover the new `thread_id` field and propagation; no new file needed for those.*

---

## Manual-Only Verifications

*All phase behaviors have automated verification.* Phase 91 emits no runtime telemetry and touches no UI, network, or DB, so there is nothing requiring manual observation.

---

## Validation Sign-Off

- [x] All tasks have automated verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers both MISSING test files
- [x] No watch-mode flags
- [x] Feedback latency < 10s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated 2026-06-09 — retroactive audit, all 16 per-task requirements COVERED by green automated tests.

---

## Validation Audit 2026-06-09

Retroactive audit of completed phase (State A — reconciled stale planning-time draft against shipped artifacts).

| Metric | Count |
|--------|-------|
| Requirements audited | 16 |
| COVERED | 16 |
| PARTIAL | 0 |
| MISSING | 0 |
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

**Verification:** `mix test test/crosswake/threadline/telemetry_test.exs test/crosswake/proof/phase91_threadline_contract_closeout_test.exs test/crosswake/bridge/contract_test.exs test/crosswake/shell/activation_test.exs` → **42 tests, 0 failures**.

No tests generated — all behaviors were already covered by tests committed during execution (944f63c, 8606255, 78f80bc, 35db85e, 4ccc646). The draft VALIDATION.md was authored at plan time and never reconciled post-execution; this audit flips it to NYQUIST-COMPLIANT.
