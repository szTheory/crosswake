---
phase: 91
slug: identity-telemetry-contract
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-09
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
| `Threadline.Telemetry.event_names/0` returns exactly 3 span names | 0 | PROP-02 | — | N/A | unit | `mix test test/crosswake/threadline/telemetry_test.exs` | ❌ W0 | ⬜ pending |
| `metadata_keys/0` == `[:thread_id, :correlation_id, :route_id, :source]` | 0 | PROP-02 | — | low-cardinality allowlist | unit | `mix test test/crosswake/threadline/telemetry_test.exs` | ❌ W0 | ⬜ pending |
| `forbidden_metadata_keys/0` contains PII keys, disjoint from allowlist | 0 | PROP-02 | T-91-PII | PII denylist enforced | unit | `mix test test/crosswake/threadline/telemetry_test.exs` | ❌ W0 | ⬜ pending |
| `metadata/1` drops forbidden keys silently (no raise) | 0 | PROP-02 | T-91-PII | fail-silent, no leak | unit | `mix test test/crosswake/threadline/telemetry_test.exs` | ❌ W0 | ⬜ pending |
| `safe_value?/1` rejects >128-char binary, nil, non-allowed types | 0 | PROP-02 | T-91-CARD | cardinality bound | unit | `mix test test/crosswake/threadline/telemetry_test.exs` | ❌ W0 | ⬜ pending |
| `execute/3` with forbidden metadata does not raise | 0 | PROP-02 | T-91-PII | fail-silent | unit | `mix test test/crosswake/threadline/telemetry_test.exs` | ❌ W0 | ⬜ pending |
| Published-allowlist proof: exact list equality | 0 | PROP-02 | — | contract is published | proof | `mix test test/crosswake/proof/phase91_threadline_contract_closeout_test.exs` | ❌ W0 | ⬜ pending |
| `Bridge.Contract.Request` has `thread_id`, default nil, NOT enforced | 0 | PROP-04 | — | N/A | unit | `mix test test/crosswake/bridge/contract_test.exs` | ✅ modify | ⬜ pending |
| `Bridge.Contract.Reply` has `thread_id` field | 0 | PROP-04 | — | N/A | unit | `mix test test/crosswake/bridge/contract_test.exs` | ✅ modify | ⬜ pending |
| `Bridge.Denial` has `thread_id` field | 0 | PROP-04 | — | N/A | unit | `mix test test/crosswake/bridge/contract_test.exs` | ✅ modify | ⬜ pending |
| `Shell.Activation.Request` has `thread_id`, default nil | 0 | PROP-04 | — | N/A | unit | `mix test test/crosswake/shell/activation_test.exs` | ✅ modify | ⬜ pending |
| `Request.to_map` nil-filters `thread_id` when nil (D-05 footgun) | 0 | PROP-04 | — | no wire-key drift | unit | `mix test test/crosswake/bridge/contract_test.exs` | ✅ modify | ⬜ pending |
| `Denial.to_map` nil-filters `thread_id` when nil (Types.to_map does NOT) | 0 | PROP-04 | — | no wire-key drift | unit | `mix test test/crosswake/bridge/contract_test.exs` | ✅ modify | ⬜ pending |
| `ok_reply` / `deny_reply` propagate `thread_id` from request (D-03) | 0 | PROP-04 | — | N/A | unit | `mix test test/crosswake/bridge/contract_test.exs` | ✅ modify | ⬜ pending |
| `Denial.from_request/2` propagates `thread_id` | 0 | PROP-04 | — | N/A | unit | `mix test test/crosswake/bridge/contract_test.exs` | ✅ modify | ⬜ pending |
| `Contract.@version` is `"1.1.0"` (informational, not gate-wired, D-04) | 0 | PROP-04 | — | N/A | proof | `mix test test/crosswake/proof/phase91_threadline_contract_closeout_test.exs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/crosswake/threadline/telemetry_test.exs` — covers PROP-02 (unit; mirrors `test/crosswake/companions/sigra/telemetry_test.exs`)
- [ ] `test/crosswake/proof/phase91_threadline_contract_closeout_test.exs` — published-allowlist proof for PROP-02 + `@version "1.1.0"` assertion for PROP-04 (mirrors the phase-58 auth-diagnostics closeout test pattern)

*Existing `contract_test.exs` and `activation_test.exs` are modified in place to cover the new `thread_id` field and propagation; no new file needed for those.*

---

## Manual-Only Verifications

*All phase behaviors have automated verification.* Phase 91 emits no runtime telemetry and touches no UI, network, or DB, so there is nothing requiring manual observation.

---

## Validation Sign-Off

- [ ] All tasks have automated verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers both MISSING test files
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
