---
phase: 64
slug: runtime-line-policy-contract-support-truth-taxonomy
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-03
---

# Phase 64 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (existing — no install needed) |
| **Config file** | `test/test_helper.exs` (existing) |
| **Quick run command** | `mix test test/crosswake/proof/phase64_runtime_line_policy_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~5 seconds (hermetic, no device/host fixtures) |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/crosswake/proof/phase64_runtime_line_policy_test.exs`
- **After every plan wave:** Run `mix test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** ~5 seconds

---

## Per-Task Verification Map

> Plans assign Task IDs. The planner MUST tag each proof assertion below to the task that delivers it. Until then, this maps requirements → observable behavior → automated proof.

| Req | Behavior | Test Type | Automated Command | File Exists | Status |
|-----|----------|-----------|-------------------|-------------|--------|
| RLINE-01 | `classify/2` returns correct verdict for all 8 change classes | unit | `mix test …/phase64_runtime_line_policy_test.exs` | ❌ W0 | ⬜ pending |
| RLINE-01 | `rebuild_required?/1` returns correct boolean for all 3 `Capability.rebuild` values | unit | `mix test …/phase64_runtime_line_policy_test.exs` | ❌ W0 | ⬜ pending |
| RLINE-02 | `Compatibility` struct has EXACTLY its 5 current fields (enumerated) | proof | `mix test …/phase64_runtime_line_policy_test.exs` | ❌ W0 | ⬜ pending |
| RLINE-02 | `manifest_schema_version` value unchanged from pre-phase-64 | proof | `mix test …/phase64_runtime_line_policy_test.exs` | ❌ W0 | ⬜ pending |
| RLINE-02 | `classify/2` agrees with `action_classes()` `rebuild_required` for every action class (co-truth parity) | proof | `mix test …/phase64_runtime_line_policy_test.exs` | ❌ W0 | ⬜ pending |
| RLINE-03 | `SupportMatrix.rebuild_matrix/1` returns `[RuntimeLineRow.t()]` with expected runtime-line bands | unit | `mix test …/phase64_runtime_line_policy_test.exs` | ❌ W0 | ⬜ pending |
| RLINE-03 | Doctor human output contains `"rebuild & compatibility matrix:"` block | integration | `mix test …/phase64_runtime_line_policy_test.exs` | ❌ W0 | ⬜ pending |
| RLINE-03 | Doctor JSON output contains `"rebuild_matrix"` key with rows | integration | `mix test …/phase64_runtime_line_policy_test.exs` | ❌ W0 | ⬜ pending |
| RLINE-03 | Doctor human and JSON render the SAME `rebuild_matrix` data (structural parity) | integration | `mix test …/phase64_runtime_line_policy_test.exs` | ❌ W0 | ⬜ pending |
| RLINE-04 | `verification_method: :device_verified` renders as `"device-verified"` | unit | `mix test …/phase64_runtime_line_policy_test.exs` | ❌ W0 | ⬜ pending |
| RLINE-04 | `verification_method: :jvm_hermetic` renders as `"jvm-hermetic (CI only)"` | unit | `mix test …/phase64_runtime_line_policy_test.exs` | ❌ W0 | ⬜ pending |
| RLINE-04 | `SupportMatrix.validate/1` rejects `:device_verified` on a CI-only entry | unit | `mix test …/phase64_runtime_line_policy_test.exs` | ❌ W0 | ⬜ pending |
| RLINE-04 | Doctor `evidence posture:` line renders `ios=device-verified  android=jvm-hermetic (CI only)` | integration | `mix test …/phase64_runtime_line_policy_test.exs` | ❌ W0 | ⬜ pending |
| RLINE-05 | `promotion_rules()` has `shell.android.jvm_hermetic` (`minimum_consecutive_passes: 3`, `required_verification_method: :jvm_hermetic`) | proof | `mix test …/phase64_runtime_line_policy_test.exs` | ❌ W0 | ⬜ pending |
| RLINE-05 | `promotion_rules()` has `shell.android.device_verified` (`required_verification_method: :device_verified`, gating note in `demotion_trigger`) | proof | `mix test …/phase64_runtime_line_policy_test.exs` | ❌ W0 | ⬜ pending |
| RLINE-05 | Android `SupportEntry.status` stays `:verification_required` after phase changes | proof | `mix test …/phase64_runtime_line_policy_test.exs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/crosswake/proof/phase64_runtime_line_policy_test.exs` — hermetic proof lane covering all RLINE-01..05 assertions above (no `@moduletag :requires_example_host`; uses `ExUnit.CaptureIO` + `Crosswake.TestSupport.ProofAssertions`, mirroring `phase52_operator_truth_test.exs`)

*All other test infrastructure is in place — ExUnit, ProofAssertions, CaptureIO already used in phase52.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| — | — | — | — |

*All phase behaviors have automated verification — this phase is pure Elixir contract/data + doctor rendering, all hermetically provable.*

---

## Security Domain

| Threat | STRIDE | Mitigation (proof-asserted) |
|--------|--------|------------------------------|
| Evidence laundering (CI-only labeled device-verified) | Spoofing/Elevation | `validate/1` rejects `:device_verified` on CI-only entries; formatter uses explicit string conversion, no implicit atom promotion |
| Overclaiming rebuild safety (classify by label, not `Capability.rebuild`) | Spoofing | `classify/2` keys off `Capability.rebuild`, never the change-class label |
| Android promoted before criteria pass | Elevation | D-20: Android `SupportEntry.status` stays `:verification_required`; proof asserts it |
| Serialization drift (human vs JSON doctor) | Information Disclosure | Shared traversal of `[RuntimeLineRow.t()]`; proof compares both outputs |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
