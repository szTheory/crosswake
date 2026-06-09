# Phase 91: Identity + Telemetry Contract - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-09
**Phase:** 91-identity-telemetry-contract
**Areas discussed:** Contract field & versioning, Telemetry event-name scope, `source` metadata semantics
**Mode:** Advisor (minimal-decisive); user requested deep subagent research per area, then a single coherent one-shot recommendation set.

---

## Contract field & versioning — how `thread_id` lands on the shipped envelopes

| Option | Description | Selected |
|--------|-------------|----------|
| Optional field, bump to 1.1.0 | Non-enforced `nil`-default field; copied through from-request path like `correlation_id`; additive envelope `@version` bump; backward-compatible. | ✓ |
| Enforced field, bump to 2.0.0 | Add to `@enforce_keys`; forces every caller + native shell to supply it; breaking change, full test-suite break. | |

**User's choice:** Option A (optional field) — confirmed via research.
**Notes:** Research (Sonnet subagent) confirmed: native shells can't supply the field yet (Phase 93), so enforcing it is a self-imposed deadlock; protobuf/Avro/CloudEvents all converged on "optional wire field, enforce presence at the application/ledger layer." Surfaced two footguns now folded into CONTEXT.md: (1) the `to_map(%Request{})` clause lacks a nil-filter (unlike Reply/Activation) and must add one to avoid `"thread_id" => null` wire drift; (2) envelope `@version` is NOT wired into the compatibility gate (`bridge_protocol_version` is), so the `1.1.0` bump is informational — a `2.0.0` bump would be dishonest. Hex release stays a patch (`0.1.0 → 0.1.1`).

---

## Telemetry event-name scope — what `Crosswake.Threadline.Telemetry` declares in v1

| Option | Description | Selected |
|--------|-------------|----------|
| Request span only | Declare exactly `[:crosswake, :threadline, :request, :start\|:stop\|:exception]`. Narrow, honest, matches PROP-02. | ✓ |
| Request span + boundary events | Also pre-declare bridge-dispatch / activation boundary events for the future. | |

**User's choice:** Option A (request span only) — confirmed via research.
**Notes:** Research confirmed the universal Elixir ecosystem convention (Phoenix/Ecto/Oban/Finch/Broadway): declare an event name only in the release whose code emits it — adding names later is free/additive, while declaring unemitted events is documentation debt that misleads handlers and burns adopter trust. The thread-doc "rich spans at every boundary" line is aspirational, not v7.0 scope. Rule recorded: one declared event = one emitter, introduced together.

---

## `source` metadata semantics — meaning of the `source` allowlist key

| Option | Description | Selected |
|--------|-------------|----------|
| Thread provenance (`:inbound`/`:minted`) | `:inbound` = thread_id arrived on header; `:minted` = Plug generated fresh UUID. Answers "continued or started here?" | ✓ |
| Activation source enum | Reuse `:cold_start \| :deep_link \| :notification \| :in_app_navigation` from the activation request. | |

**User's choice:** Option A (`:inbound`/`:minted`) — confirmed via research.
**Notes:** Research confirmed it's the only PROP-02 key carrying non-reconstructable info; maps onto W3C traceparent continuation / OTel `isRemote()` / `Plug.RequestId` mint-or-echo; fixed 2-atom low-cardinality enum; no collision with the audit ledger's `provenance ∈ {:device_claimed, :backend_accepted}` (different tier, disjoint values). Activation-enum option rejected: would be `nil` on ~all Phoenix-only requests (useless noise) and creates deep word-collision with `Activation.Request.source`. PROP-02 fixed the key name as `source`; only the value domain was open.

## Claude's Discretion

- Exact `defstruct` key ordering; precise `@forbidden_metadata_keys` membership (derive from Sigra's list); whether a Threadline `Event` helper struct is worth it for this narrow surface; test file organization.

## Deferred Ideas

None — discussion stayed within phase scope. No scope creep surfaced; no pending todos matched this phase.
