<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
(None provided via CONTEXT.md)

### the agent's Discretion
(None provided via CONTEXT.md)

### Deferred Ideas (OUT OF SCOPE)
(None provided via CONTEXT.md)
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| DIAG-01 | Doctor, operator inspection, support matrix, and guides distinguish token binding/open-routing readiness from APNs/FCM delivery support. | Confirmed `Crosswake.OperatorInspection` needs `open_routing_active` field. `Doctor` needs new `phase_62_notification_findings/1`. `SupportMatrix` needs update to clearly state v3.9 readiness for open routing and deferred state for delivery. |
| DIAG-02 | Notification telemetry uses stable low-cardinality events and forbids raw tokens, raw payloads, PII, route params, and provider payload bodies. | Confirmed `Crosswake.Companions.Chimeway.Telemetry` implements strictly filtered allowlists and denylists. This contract needs to be surfaced into `SupportMatrix` and exposed via `Doctor` / `OperatorInspection`. |
</phase_requirements>

# Phase 62: Diagnostics, Support Truth, And Docs - Research

**Researched:** [date]
**Domain:** Diagnostics, Telemetry, and Documentation
**Confidence:** HIGH

## Summary

This phase publishes operator-facing truth for the v3.9 notification capabilities (Chimeway token binding and open-routing). It updates `Crosswake.OperatorInspection`, `Crosswake.Doctor`, `Crosswake.SupportMatrix`, and public guides to distinguish clearly between token-binding/open-routing readiness (which are fully supported and route-resolvable) and APNs/FCM push delivery execution (which remains deferred and unsupported). It also verifies and surfaces the strict telemetry constraints that prevent PII, raw payload bodies, and raw tokens from leaking into logs.

**Primary recommendation:**
1. Expand `Crosswake.SupportMatrix.notification_support_truth/0` to include telemetry and open-routing status.
2. Update `Crosswake.OperatorInspection.notifications_entry/1` to compute and expose `open_routing_active`.
3. Add `phase_62_notification_findings/1` in `Crosswake.Doctor` to output diagnostic warnings/advisories that reflect the `SupportMatrix` truth.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Token Binding Readiness | API / Backend | Native Client | Token binding requires native client extraction but backend coordination for validation and storage |
| Open-Routing Readiness | API / Backend | Native Client | Resolution logic lives in Elixir (`RouteGate`), client provides intent evidence |
| Notification Telemetry | API / Backend | — | Emitted via Elixir `:telemetry`, ensuring filtering happens before APM export |
| Operator Inspection | API / Backend | — | Manifest and support matrix compiled locally by Elixir logic |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `Crosswake.Doctor` | n/a | Host-truth-first diagnostics | Existing CLI tool to verify manifest and project health |
| `Crosswake.OperatorInspection` | n/a | JSON route-authoritative inspection | Integrates with n8n/telemetry workflows |
| `Crosswake.SupportMatrix` | n/a | Canonical truth | Single source of truth for support claims across docs and CLI |
| `:telemetry` | ~> 1.0 | Event emission | Standard Elixir telemetry library used throughout the project |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `Crosswake.Doctor` | Hand-rolled scripts | Duplicates effort, inconsistent output across projects |

## Package Legitimacy Audit
*(No external packages are installed in this phase.)*

## Architecture Patterns

### Recommended Additions to Doctor and Operator Inspection

1. **`OperatorInspection` Enhancement:**
   Update `notifications_entry(route)` in `lib/crosswake/operator_inspection.ex` to extract and expose:
   `open_routing_active: route.notification_open != false and route.notification_open != nil`. Update the `Types.Route` documentation in `types.ex` if needed.

2. **`Doctor` Notification Findings:**
   Create a new diagnostic pass `phase_62_notification_findings(manifest)` in `lib/crosswake/doctor/doctor.ex` that emits `notification.telemetry_contract` and `notification.delivery_deferred` findings when `notification_token` capabilities or active `notification_open` routes are present. This mirrors what was done in `phase_46_auth_findings/1`.

3. **`SupportMatrix` Updates:**
   Update `@notification_support_truth` in `lib/crosswake/support_matrix/support_matrix.ex` to reflect `v3.9` open-routing readiness and strictly bounded telemetry truth. Add `telemetry` maps (similar to `@auth_contract_truth`) specifying `event_names`, `metadata_keys`, and `forbidden_metadata_keys`.

### Anti-Patterns to Avoid
- **Implicit Delivery Support:** Do not let the presence of `notification_token` imply that Crosswake owns APNs/FCM delivery. 
- **Leaky Telemetry:** Do not log `:token`, `:raw_token`, `:provider_payload`, or `:route_params` in any diagnostic output.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Telemetry redaction | Custom `inspect` or logging logic | `Chimeway.Telemetry.metadata/1` | Already enforces strict key allowlists and explicitly forbids PII and raw payloads |

## Runtime State Inventory
*Not a refactor or migration phase (no runtime strings are being changed).*

## Common Pitfalls

### Pitfall 1: Telemetry PII Leaks
**What goes wrong:** Developers log entire provider payloads when debugging notifications.
**Why it happens:** Push payloads often contain the exact data causing the issue.
**How to avoid:** Rely on `Crosswake.Companions.Chimeway.Telemetry` which explicitly drops `@forbidden_metadata_keys`.

### Pitfall 2: Delivery Support Confusion
**What goes wrong:** Operators assume that since token binding works, push delivery works.
**Why it happens:** Documentation fails to separate token-capture from server-side APNs/FCM push execution.
**How to avoid:** Explicitly state in `SupportMatrix` and `Doctor` output that delivery is NOT supported.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| v3.8 | v3.9 | Phase 62 | Token binding and open-routing are supported; telemetry is strictly governed; APNs/FCM delivery remains explicitly unsupported. |

## Assumptions Log
*(No assumptions made. All telemetry and support matrix claims are backed by existing implementations.)*

## Environment Availability
Step 2.6: SKIPPED (no external dependencies identified)

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DIAG-01 | Operator inspection distinguishes open-routing from delivery | unit | `mix test test/crosswake/operator_inspection/operator_inspection_test.exs` | ✅ Wave 0 |
| DIAG-01 | Doctor outputs notification open routing vs delivery truth | unit | `mix test test/crosswake/doctor/doctor_test.exs` | ✅ Wave 0 |
| DIAG-02 | Telemetry structure reflects restricted keys | unit | `mix test test/crosswake/companions/chimeway/telemetry_test.exs` | ✅ Wave 0 |
| DIAG-02 | Support Matrix exports notification telemetry and open-routing constraints | unit | `mix test test/crosswake/support_matrix/support_matrix_test.exs` | ✅ Wave 0 |
