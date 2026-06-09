# Feature Landscape: v7.0 Threadline Audit Capstone

**Domain:** Cross-boundary correlation + terminal-event audit for Phoenix↔mobile apps
**Researched:** 2026-06-09 · **Confidence:** HIGH (codebase-grounded)

Features grouped by the categories that become REQ-ID prefixes (PROP / LEDG / OPER / DOCS-PROOF).

## PROP — Correlation propagation (core)

**Table stakes**
- New session-spanning `thread_id` layered above the existing per-command `correlation_id` (no renames).
- `Crosswake.Plug.Threadline`: read `X-Crosswake-Thread-Id`, mint-as-fallback, set `Logger.metadata`,
  emit `[:crosswake, :threadline, :request, :start|:stop|:exception]`, echo header on response.
- `Crosswake.Live.Threadline` `on_mount`: read `_crosswake_thread_id` connect param, set LiveView metadata,
  emit `[:crosswake, :threadline, :live_mount, …]`.
- `Crosswake.Threadline.Telemetry`: allowlist + `safe_value?` + forbidden-key guard (copy Sigra pattern).
- Native shell injects the header on initial WebView load (iOS `URLRequest`, Android `loadUrl/headers`) and
  exposes `window.crosswakeBridge.threadId` for the WS path. `thread_id` continues across cold_start →
  deep_link → notification → in_app_navigation activations.

**Differentiator**
- Honest two-channel propagation that documents the WebView WebSocket-header limitation and the
  `fetch`/`XHR` sub-navigation gap, instead of pretending full transparent coverage.

**Anti-features**
- No automatic instrumentation of arbitrary host endpoints; no request-body capture; no cross-service hop.

## LEDG — Durable audit ledger (companion, opt-in)

**Table stakes**
- `mix crosswake.gen.audit`: host-owned Ecto schema + thin writer, `ensure_file/2` (never overwrites),
  `[crosswake] created/reused` output — modeled on `mix crosswake.gen.sync`.
- Canonical columns incl. `idempotency_key` (unique), `event_class`/`event_type`/`outcome` enums, timestamps.
- Append-only by convention (no update/delete helpers generated).

**Differentiators (vs paper_trail / ex_audit / carbonite)**
- **ProvenanceLane**: first-class `provenance ∈ {:device_claimed, :backend_accepted}` column — encodes the
  backend-authority thesis and enables offline-replay attribution. No mainstream audit lib has this.
- **PII-free by construction**: opaque `actor_ref` (HMAC pseudonym) is the only identity; `reject_pii_in_metadata/1`
  changeset guard **fails closed** on forbidden keys.
- **Honest durability**: scaffold ships both `record/1` and `record_in_multi/2`; docstrings steer true terminal
  events into the host's business `Ecto.Multi` for atomicity. The lib never claims delivery it can't guarantee.
- **Advisory tamper-evidence**: nullable `row_hash`/`prev_hash` for offline detection; docs say plainly it
  detects but does not prevent tampering.

**Anti-features**
- No lib-owned table/migration; no raw payloads/tokens/PII; no async-telemetry-driven durable writes.

## OPER — Operator surface (text-only in v1)

**Table stakes**
- `mix crosswake.threadline --thread-id <id> | --actor-ref <ref>`: ordered Native→Bridge→Phoenix event table
  with `posture: ephemeral|durable`. Plain `key: value` output, `[crosswake]` prefix, careful-maintainer voice.
- Doctor `phase_N_threadline_findings/1`: `threadline.plug_missing` (advisory),
  `threadline.ledger_not_configured` (advisory), `threadline.ledger_schema_drift` (warning),
  `threadline.pii_forbidden_field_present` (error/fail-closed).
- SupportMatrix `@audit_ledger_support_truth` row + accessor; optional OperatorInspection `audit_entry/1` + `:audit` route key.

**Differentiator**
- Reports the truth that most observability is ephemeral — `ephemeral` vs `durable` posture is explicit, never implied away.

**Deferred (documented forward design, NOT built in v7.0)**
- `crosswake_dashboard` LiveDashboard/LiveView timeline: runtime-colored event chips (Native=Brass, Bridge=Plum,
  Phoenix=Harbor, Denied=Rust), dark/light/system, WCAG AA, careful-maintainer microcopy.

## DOCS-PROOF — Docs-contract & proof lanes

**Table stakes**
- `guides/threadline.md` with merge-blocking `assert_contains_exact` anchors: header name, AuditEvent field list,
  forbidden-field list, ephemeral-vs-durable posture, module/task names, "terminal critical events only".
- Hermetic proof (every PR): Plug metadata+telemetry, telemetry forbidden-key rejection, gen.audit idempotency,
  doctor findings, guide parity. Advisory/example-host proof: real Ecto `record_in_multi/2` persistence +
  `mix crosswake.threadline` reconstruction.

**Differentiator**
- A mechanically-checked **"What Threadline is NOT"** anti-scope section in the guide — the honesty contract is testable.
