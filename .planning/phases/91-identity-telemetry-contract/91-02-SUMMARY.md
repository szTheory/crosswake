---
phase: 91-identity-telemetry-contract
plan: "02"
subsystem: bridge-activation-envelope
tags: [thread_id, envelope, prop-04, prop-02, tdd, closeout-proof, version-bump]
dependency_graph:
  requires:
    - "91-01 (Crosswake.Threadline.Telemetry allowlist contract)"
  provides:
    - thread_id optional field on Bridge.Contract.Request, Bridge.Contract.Reply, Bridge.Denial, Shell.Activation.Request
    - from-request helpers propagate thread_id like correlation_id
    - Bridge.Contract @version 1.1.0
    - Hex package 0.1.1
    - Phase91ThreadlineContractCloseoutTest proof
  affects:
    - Phase 92 Plug.Threadline (consumes Request/Reply thread_id)
    - Phase 94 audit ledger (consumes thread_id on envelopes)
tech_stack:
  added: []
  patterns:
    - TDD red/green cycle (RED: failing tests, GREEN: implementation)
    - Additive-minor version bump (1.0.0 -> 1.1.0) — semver >= compat gate still passes
    - Closeout proof pattern (exact-list equality + execute/3 PII rejection handler)
    - Local nil-filter before shared Types.to_map/1 (Denial to_map footgun fix)
key_files:
  created:
    - test/crosswake/proof/phase91_threadline_contract_closeout_test.exs
  modified:
    - lib/crosswake/bridge/contract.ex
    - lib/crosswake/bridge/denial.ex
    - lib/crosswake/shell/activation.ex
    - mix.exs
    - test/crosswake/bridge/contract_test.exs
    - test/crosswake/shell/activation_test.exs
decisions:
  - "thread_id NOT added to @enforce_keys on any struct (D-01) — no caller can populate it until Phase 92/93; enforcing would break the full suite"
  - "thread_id type spec is String.t() | nil (D-02) — opaque string mirroring correlation_id, no format validation in the contract"
  - "Request to_map nil-filter added (D-05 footgun fix) — the Request clause had no nil-filter before; now consistent with Reply clause"
  - "Denial to_map nil-filter is LOCAL before Types.to_map/1 (D-05 for Denial) — Types.to_map does not nil-filter; fix is scoped to denial.ex; Types.to_map unchanged"
  - "@version bump to 1.1.0 (D-04) — additive-minor; compatibility gate uses semver >= so 1.1.0 satisfies 1.0.0 requirement; verified by compatibility/ suite"
  - "Hex @version bump to 0.1.1 (D-06) — patch, purely additive, no ~ 0.1 adopter break"
metrics:
  duration: "15 minutes"
  completed: "2026-06-09"
  tasks_completed: 2
  files_created: 1
  files_modified: 6
---

# Phase 91 Plan 02: Bridge/Activation Envelope thread_id + Version Bump + Closeout Proof Summary

**One-liner:** thread_id optional field on all four wire envelopes with propagation via from-request helpers, nil-filter footgun fixes on Request and Denial to_map/1, @version 1.1.0, Hex 0.1.1, and a closeout proof locking the published Threadline telemetry contract (PROP-04 + PROP-02).

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 (RED) | Failing tests for thread_id on envelopes, propagation, nil-filter | 78f80bc | test/crosswake/bridge/contract_test.exs, test/crosswake/shell/activation_test.exs |
| 1 (GREEN) | Add thread_id to all four envelopes + propagation + nil-filter fixes | 35db85e | lib/crosswake/bridge/contract.ex, lib/crosswake/bridge/denial.ex, lib/crosswake/shell/activation.ex, test/crosswake/bridge/contract_test.exs |
| 2 | Bump @version 1.1.0, Hex 0.1.1, write closeout proof | 4ccc646 | lib/crosswake/bridge/contract.ex, mix.exs, test/crosswake/proof/phase91_threadline_contract_closeout_test.exs |

## What Was Built

**thread_id on all four envelopes (PROP-04 wire-envelope foundation):**
- `Bridge.Contract.Request`: `thread_id: nil` in defstruct, `String.t() | nil` in @type, `Keyword.get(attrs, :thread_id)` in `new_request/1`
- `Bridge.Contract.Reply`: same pattern; `ok_reply/2` and `deny_reply/2` propagate `request.thread_id` (D-03)
- `Bridge.Denial`: `thread_id: nil` in defstruct (NOT @enforce_keys); `from_request/2` propagates `request.thread_id`; `to_map/1` gets local `Enum.reject(is_nil)` BEFORE `Types.to_map/1` to nil-filter correctly
- `Shell.Activation.Request`: `thread_id: nil` in defstruct; `new_request/1` and `to_map/1` updated

**Nil-filter footgun fixes (T-91-WIRE):**
- `Contract.to_map(%Request{})`: added `Enum.reject(fn {_k, v} -> is_nil(v) end) |> Map.new()` — the Request clause had no nil-filter before (D-05)
- `Denial.to_map/1`: added local nil-filter BEFORE `Types.to_map/1` — Types.to_map does NOT nil-filter; fix is local and Types module is unchanged

**Version bumps:**
- `Bridge.Contract @version`: `"1.0.0"` → `"1.1.0"` (additive-minor, D-04)
- `mix.exs @version`: `"0.1.0"` → `"0.1.1"` (patch, D-06)
- Compatibility gate unaffected — semver >= means 1.1.0 satisfies a 1.0.0 requirement

**Closeout proof (PROP-02 published-contract half):**
`test/crosswake/proof/phase91_threadline_contract_closeout_test.exs` — 6 tests:
- Exact-list equality for `event_names/0` (three request-span names)
- Exact-list equality for `metadata_keys/0` (four PROP-02 keys)
- Forbidden-key membership + disjointness via MapSet
- `execute/3` PII rejection: attaches handler, asserts `:access_token` absent, `:thread_id` present in received metadata
- `Bridge.Contract.version() == "1.1.0"`
- All four envelope structs construct with `thread_id: nil`
- thread_id propagates through `ok_reply/2`, `from_request/2`, `deny_reply/2`

## Test Results

- `mix test test/crosswake/bridge/contract_test.exs test/crosswake/shell/activation_test.exs test/crosswake/proof/phase91_threadline_contract_closeout_test.exs test/crosswake/compatibility/` — **49 tests, 0 failures**
- Full `mix test` — 970 tests; 64 pre-existing failures from `CrosswakeExample.*` modules not compiled in the test environment (out of scope, pre-existed before this plan)

## Deviations from Plan

None — plan executed exactly as written. The test assertion update for `"version" => "1.0.0"` → `"1.1.0"` was performed as part of Task 1 (plan permits this sequence).

## Known Stubs

None — all contract functions are fully implemented and verified.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes beyond the plan's threat model. All four T-91 mitigations are implemented and verified:

| Threat | Mitigation Verified |
|--------|---------------------|
| T-91-WIRE | nil-filter on Request.to_map and Denial.to_map — nil thread_id serializes as absent; verified by nil-absent assertions |
| T-91-ENF | thread_id not in @enforce_keys on any struct — no caller breaks; verified by default-nil construction assertions |
| T-91-VER | @version 1.1.0 (additive-minor); compatibility gate unchanged — verified by compatibility/ suite (0 failures) |
| T-91-PII | Closeout proof locks forbidden-key denylist + execute/3 PII rejection — verified by 6 closeout proof tests |

## Self-Check

## Self-Check: PASSED

- FOUND: lib/crosswake/bridge/contract.ex (thread_id in Request/Reply, @version 1.1.0, nil-filter on Request.to_map)
- FOUND: lib/crosswake/bridge/denial.ex (thread_id in Denial, from_request propagation, local nil-filter)
- FOUND: lib/crosswake/shell/activation.ex (thread_id in Activation.Request, new_request/1, to_map)
- FOUND: mix.exs (@version "0.1.1")
- FOUND: test/crosswake/proof/phase91_threadline_contract_closeout_test.exs
- FOUND: 78f80bc (RED test commit)
- FOUND: 35db85e (GREEN implementation commit)
- FOUND: 4ccc646 (Task 2 version bump + closeout proof commit)
