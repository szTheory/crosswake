# Phase 65: Diagnostic Export Seam (Elixir) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-04
**Phase:** 65-Diagnostic Export Seam (Elixir)
**Areas discussed:** HTTP seam shape, Envelope + layer attribution, Redaction allowlist, Readiness posture
**Mode:** advisor (minimal_decisive calibration; NON_TECHNICAL_OWNER=false — technical framing kept)

All four areas were selected for discussion, researched by four parallel advisor researchers (sonnet), synthesized into one coherent recommendation set, then locked by the user in a single confirmation.

---

## HTTP seam shape

| Option | Description | Selected |
|--------|-------------|----------|
| Behaviour-only contract | Typed envelope + `@callback export/1` the host/native-shell implements; no Elixir transport code; no new dep (mirrors `Chimeway.IntentConsumer`) | ✓ |
| Contract + Req/Finch default sender | Ship a working fire-and-forget Elixir sender (`Task.start`); adds first HTTP runtime dep to a published lib | |

**User's choice:** Behaviour-only contract (locked all four as-is).
**Notes:** The real senders are native (MetricKit / `ApplicationExitInfo`) in Phase 67; an Elixir sender would be a first-party-service claim the lib doesn't own and contradicts host-owned-authority DNA. Proof asserts no `diagnostics.*` bridge vocabulary and no HTTP dep added.

---

## Envelope + layer attribution

| Option | Description | Selected |
|--------|-------------|----------|
| Stable typed outer + opaque inner `raw_payload: map()` | Fully typed/enforce-keyed outer envelope; inner carries an opaque passthrough map for MetricKit/ApplicationExitInfo divergence | partial |
| Fully typed per-platform inner structs | Separate `MetricKitDiagnostic`/`AppExitInfoDiagnostic` tagged union | |

**User's choice:** Stable typed outer envelope — but with the inner reconciled against the redaction decision (see below): typed `exit_reason` enum, **no `raw_payload` map**. Per-platform structs deferred until Phase 67 device evidence.
**Notes:** Own `@schema_version` distinct from bridge protocol; manual `to_map/1`, no `@derive`. `layer :: :native|:web|:bridge`; carries `native_runtime_version` from Phase 64. Fixtures per layer×exit-reason.

---

## Redaction allowlist

| Option | Description | Selected |
|--------|-------------|----------|
| Allowlist-by-construction (typed struct, no free-form text) | Struct cannot represent forbidden data; free-form crash text out of scope/host-owned; `sanitize/1` fail-closed | ✓ |
| Dual allowlist + content scrubbing | Carry bounded `crash_text` through regex/length-cap scrubbing; best-effort | |

**User's choice:** Allowlist-by-construction (locked all four as-is).
**Notes:** DIAG-03's "forbids" requires the schema to make forbidden data unrepresentable, not merely unlikely. Free-form text is un-allowlistable (tokens hide inside stack traces/URLs) → host-owned. `sanitize/1 :: {:ok, Envelope.t()} | {:error, :redaction_failed}`, fail-closed. Merge-blocking test reuses Phase 58 idiom + Chimeway forbidden-key set.

**Cross-area reconciliation (resolved during synthesis):** the envelope researcher's opaque `raw_payload: map()` conflicted with allowlist-by-construction. Reconciled in favor of redaction — drop `raw_payload`; any bounded metadata map (default: none) must pass the Chimeway `safe_value?` + key-allowlist guard, never a raw passthrough. User confirmed this reconciliation when locking the set.

---

## Readiness posture

| Option | Description | Selected |
|--------|-------------|----------|
| Mirror `@notification_support_truth` exactly | New `@diagnostic_export_support_truth` + accessor; one `:advisory` doctor check; posture string separates shipped-contract / deferred-native-transport / host-owns-data | ✓ |
| Code-comment only, no truth attribute/check | Defer all surface truth to Phase 67 | |

**User's choice:** Mirror notification truth exactly (locked all four as-is).
**Notes:** `:advisory` severity (nothing actionable yet); `delivery_supported: false`; `deferred: [:native_diagnostic_export, :metrickit_capture, :application_exit_info_capture]`; `authority_source: :host_configured_endpoint`; posture string explicitly states "Crosswake is not a crash-reporting service."

---

## Claude's Discretion

Exact module/struct/callback/function names and field/atom spellings; sub-module split vs single module; fixture directory + proof-lane file placement; `SupportMatrix` entry field population + `docs_anchor` + `check_ids`; whether the fail-closed guard lives in the constructor vs a dedicated function. Locked semantics preserved (see CONTEXT.md "Claude's Discretion").

## Deferred Ideas

- Optional dep-gated Elixir reference sender (Req/Finch + Task) — rejected for Phase 65; possible future companion package.
- Bounded free-form crash text / structured stack frames — rejected for the Elixir contract; host-owned.
- Per-platform fully-typed inner structs — deferred to Phase 67 device evidence.
- Native MetricKit/`ApplicationExitInfo` capture + real HTTP transport + merge-blocking JVM lane — Phase 67.
- Host endpoint generator scaffolds / `ADOPT:` markers — Phase 66.
- Docs-contract parity gate + Android promotion + closeout — Phase 69.
