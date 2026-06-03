# Phase 63: Hermetic Proof And Advisory Promotion Criteria - Research

**Researched:** 2026-06-03
**Domain:** Testing / Hermetic Proof / Diagnostic Posture
**Confidence:** HIGH

## User Constraints (from Phase Context & Requirements)

### Locked Decisions
- **PROOF-01**: Merge-blocking hermetic proof must cover token contracts, binding/revocation lifecycle, open resolution, Sigra route gating, denial sanitization, support/docs parity, and telemetry redaction.
- **PROOF-02**: APNs/FCM device delivery, real token issuance, provider credentials, notification-tray behavior, and provider console metrics remain advisory with explicit promotion criteria.

## Summary

Phase 63 is the capstone proof phase for the v3.9 Notification and Token Binding milestone. It requires asserting that all capabilities shipped in Phases 59-62 (Token Contracts, Example Host Registry, Notification Open Resolution, and Diagnostic Posture) hold true end-to-end under a hermetic environment. The primary goal is to codify merge-blocking proofs for the shipped notification seam (binding, rotation, open validation) while explicitly asserting that device delivery guarantees and real APNs/FCM integration remain strictly advisory. 

**Primary recommendation:** Create a comprehensive `phase63_notification_seam_proof_test.exs` that exercises the end-to-end flow from token binding and rotation to notification-open validation, and strictly asserts the `:advisory` proof class for device delivery using the existing `Crosswake.SupportMatrix` and `Crosswake.Doctor.PublishReadiness` APIs.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Token Binding & Rotation | API / Backend | Database | Synchronous registry APIs manage state; no bundled background workers. |
| Open Resolution | API / Backend | — | Validating notification open intents and yielding activation source evidence. |
| Advisory Promotion Criteria | Doctor / Diagnostics | — | Publish readiness policies dictate that push delivery is advisory and non-blocking for CI. |
| Hermetic Proof | Test Suite | — | ExUnit assertions must run entirely without live provider endpoints. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| ExUnit | ~> 1.15 | Test framework | Standard Elixir testing framework. |
| Ecto Sandbox | ~> 3.10 | Database isolation | Required for the Example Host registry lifecycle proof. |
| :telemetry | ~> 1.0 | Observability | Used to capture and assert on redaction/sanitization of tokens in events. |

## Architecture Patterns

### Hermetic Proof Lane Pattern
**What:** The Crosswake project uses dedicated `phaseXX_*_proof_test.exs` files in `test/crosswake/proof/` to ensure milestone requirements are met deterministically.
**When to use:** For end-to-end validation of contracts across boundaries, particularly separating merge-blocking backend logic from advisory device/provider delivery.

### Recommended Project Structure
```text
test/crosswake/proof/
└── phase63_notification_seam_proof_test.exs   # New capstone proof test
```

### Advisory Posture Assertion
**What:** Validating that the support matrix and doctor do not claim false authority.
**Example:**
```elixir
# Asserting that delivery remains advisory
truth = Crosswake.SupportMatrix.notification_support_truth() |> List.first()
assert truth.proof_class == :advisory
assert truth.delivery_supported == false

# Asserting that publish readiness treats it as advisory
report = Crosswake.Doctor.PublishReadiness.check(...)
assert %{advisory_count: adv} = report.summary
assert adv > 0
```

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Emulating push delivery | HTTP mocks for APNs/FCM | `Crosswake.Companions.Chimeway.Contracts.ProviderFeedback` | Proof requires asserting the contract boundary, not the network request. |
| Telemetry validation | Custom process messaging | `:telemetry.attach/4` in ExUnit tests | Standard observability mechanism natively used by `Chimeway.Telemetry`. |
| Example Host state | Manual SQLite boilerplate | Mix script wrappers or Ecto Sandbox | Phase 60 established a pattern using temporary DB files and running `Ecto.Migrator` for registry assertions. |

## Common Pitfalls

### Pitfall 1: Leaking Raw Tokens in Test Assertions
**What goes wrong:** Hardcoding real token formats or allowing test output to print raw tokens when failing.
**Why it happens:** Convenience during test writing.
**How to avoid:** Use synthetic sentinels (e.g., `"raw_apns_token_should_not_leak_123"`) and explicitly assert their absence in `inspect()` and telemetry payloads. (Follow Phase 59/60 patterns).

### Pitfall 2: Treating Advisory Features as Merge-Blocking
**What goes wrong:** A test fails because push delivery is not implemented, breaking CI.
**Why it happens:** Confusing shipped backend contracts with deferred delivery mechanisms.
**How to avoid:** Ensure tests explicitly check that `proof_class: :advisory` is returned for delivery capabilities, passing the test when this is correctly reported.

### Pitfall 3: Asynchronous Event Testing Flakiness
**What goes wrong:** Tests fail randomly due to race conditions.
**Why it happens:** Waiting for `telemetry` events without proper synchronization.
**How to avoid:** Use explicit message passing and `assert_receive` with sensible timeouts when validating telemetry emission.

## Code Examples

Verified patterns from existing Phase 59/60 proofs:

### Asserting Telemetry Redaction
```elixir
telemetry_pid = self()
handler_id = "phase63-telemetry-proof"
:telemetry.attach(
  handler_id,
  [:crosswake, :notification, :token, :bound],
  fn _event_name, _measurements, metadata, _config ->
    send(telemetry_pid, {:telemetry, metadata})
  end,
  nil
)

# ... trigger binding ...

assert_receive {:telemetry, metadata}, 100
refute Map.has_key?(metadata, :apns_token)
refute inspect(metadata) =~ "raw_apns_token"
```

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `phase63_notification_seam_proof_test.exs` is the target artifact | Architecture Patterns | The planner might create tests in the wrong directory, though it aligns with the Phase 59/60 approach. |

## Open Questions

1. **Test Scope Overlap**
   - What we know: Phase 59 and 60 already contain comprehensive tests for Token Binding, Lifecycle, and the Registry. Phase 61 added Open Resolution.
   - What's unclear: Does Phase 63 need to duplicate these checks, or just combine them into an end-to-end "Notification Seam" integration test?
   - Recommendation: The Phase 63 proof test should focus on the integration flow: binding a token -> receiving an open intent -> resolving it -> asserting telemetry and route gating, and finally asserting the advisory promotion criteria across the Doctor reports.

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PROOF-01 | Merge-blocking hermetic proof covers token contracts, binding/revocation lifecycle, open resolution, Sigra route gating, denial sanitization, support/docs parity, and telemetry redaction. | Requires an end-to-end proof test (`phase63_notification_seam_proof_test.exs`) that executes the lifecycle and validates telemetry via `assert_receive`. |
| PROOF-02 | APNs/FCM device delivery, real token issuance, provider credentials, notification-tray behavior, and provider console metrics remain advisory with explicit promotion criteria. | Requires asserting `Crosswake.Doctor.PublishReadiness` and `SupportMatrix` structures emit `:advisory` proof classes for delivery. |
