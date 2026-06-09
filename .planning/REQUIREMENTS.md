# Requirements: Crosswake — v7.0 Threadline Audit Capstone

**Defined:** 2026-06-09
**Core Value:** Day-2 operational viability — correlate the Native → Bridge → Phoenix → DB event sequence for a single user journey and durably record terminal critical events, narrowly and honestly, without becoming an APM, an OTel replacement, or a database-bloat machine.
**North star:** `.planning/research/SUMMARY.md` · **Canonical definition:** `.planning/threads/threadline-audit.md`

## v1 Requirements (v7.0)

### Correlation Propagation (PROP)

- [x] **PROP-01**: A Phoenix team can add `Crosswake.Plug.Threadline` to a pipeline so every request carries a `thread_id` in `Logger.metadata` — read from the `X-Crosswake-Thread-Id` header, minted as a fallback when absent (never overwriting an inbound id), and echoed on the response.
- [x] **PROP-02**: The Plug emits `[:crosswake, :threadline, :request, :start|:stop|:exception]` telemetry carrying only low-cardinality metadata (`thread_id`, `correlation_id`, `route_id`, `source`), and rejects forbidden/PII keys via the shared allowlist guard.
- [x] **PROP-03**: A team can opt a LiveView into thread correlation via `Crosswake.Live.Threadline` `on_mount`, which reads the `_crosswake_thread_id` connect param and sets `thread_id` on the LiveView process metadata.
- [x] **PROP-04**: `thread_id` is a first-class field layered above the unchanged per-command `correlation_id` on the bridge and activation contracts, carried across `cold_start → deep_link → notification → in_app_navigation` activations.
- [x] **PROP-05**: The iOS and Android native shells inject `X-Crosswake-Thread-Id` on the initial WebView load and expose `window.crosswakeBridge.threadId` for the LiveView WebSocket path.

### Audit Ledger (LEDG)

- [ ] **LEDG-01**: A team can run `mix crosswake.gen.audit` to scaffold a host-owned Ecto audit schema and thin writer — idempotent, never overwriting host edits, with `[crosswake] created/reused` output matching `gen.sync`.
- [ ] **LEDG-02**: The generated ledger records terminal critical events with the canonical columns (`thread_id`, `correlation_id`, `route_id`, `actor_ref`, `actor_kind`, `event_class`, `event_type`, `outcome`, `provenance`, `occurred_at`, `recorded_at`, `idempotency_key` (unique), `metadata`, `row_hash`, `prev_hash`).
- [ ] **LEDG-03**: The ledger is PII-free by construction — the only identity field is an opaque `actor_ref` (HMAC helper provided, mirroring `Chimeway.Redaction`), and a `reject_pii_in_metadata/1` changeset guard fails closed on forbidden keys.
- [ ] **LEDG-04**: The ledger distinguishes device-claimed evidence from backend-accepted authority via a first-class `provenance ∈ {:device_claimed, :backend_accepted}` column (ProvenanceLane).
- [ ] **LEDG-05**: A team can record events standalone via `record/1` or atomically inside their business transaction via `record_in_multi/2`, with docstrings steering true terminal events to the Multi path and stating `record/1` is not transactionally atomic with the caller.
- [ ] **LEDG-06**: The generated ledger is append-only — no update/delete helpers are generated — with advisory `row_hash`/`prev_hash` computed at insert for offline tamper detection.

### Operator Surface (OPER)

- [ ] **OPER-01**: An operator can run `mix crosswake.threadline --thread-id <id>` (or `--actor-ref <ref>`) to see an ordered Native→Bridge→Phoenix event table with explicit `posture: ephemeral` (no ledger) or `posture: durable` (ledger configured).
- [ ] **OPER-02**: `mix crosswake.doctor` reports Threadline posture and emits `threadline.plug_missing` (advisory), `threadline.ledger_not_configured` (advisory), `threadline.ledger_schema_drift` (warning), and `threadline.pii_forbidden_field_present` (error, fail-closed).
- [ ] **OPER-03**: The support matrix exposes a Threadline `@audit_ledger_support_truth` row with explicit denial/fallback posture (no ledger configured = ephemeral-only, non-blocking).

### Documentation Contract (DOCS)

- [ ] **DOCS-01**: A `guides/threadline.md` guide documents the header name, the AuditEvent field list, the forbidden-field list, the ephemeral-vs-durable posture, the module/task names, and the "terminal critical events only" scope — each mechanically asserted `contains-exact` against the code (merge-blocking).
- [ ] **DOCS-02**: The guide includes a mechanically-checked "What Threadline is NOT" anti-scope section (not APM, not OTel, not a logging framework, not a plugin bus, no PII, no session replay).
- [ ] **DOCS-03**: The guide documents the honest limitations: WebView WebSocket/`fetch`/`XHR` header gaps, "hash-chaining detects but does not prevent tampering," and OTel coexistence with zero dependency.

### Proof Lanes (PROOF)

- [ ] **PROOF-01**: A hermetic, merge-blocking proof lane verifies Plug metadata + telemetry emission, telemetry forbidden-key rejection, `gen.audit` idempotency, doctor findings, and `guides/threadline.md` parity — no Ecto/network/device required.
- [ ] **PROOF-02**: An advisory / example-host proof lane verifies real Ecto-backed `record_in_multi/2` persistence and `mix crosswake.threadline` reconstruction with `durable` posture against a seeded ledger.

## v2 / Future Requirements (deferred, tracked)

### Operator UI (UI)
- **UI-01**: A `crosswake_dashboard` LiveDashboard/LiveView timeline — search `actor_ref`/`thread_id`, runtime-colored event chips (Native=Brass, Bridge=Plum, Phoenix=Harbor, Denied=Rust), dark/light/system, WCAG AA — shipped as a separate opt-in package.

### Ledger Integrity (INTG)
- **INTG-01**: A `mix crosswake.audit.verify` task that walks the `row_hash`/`prev_hash` chain and reports tamper/gap detection.

### Interop (INTOP)
- **INTOP-01**: An optional OTel bridge companion that maps `thread_id` into OpenTelemetry span attributes.
- **INTOP-02**: Cross-service `thread_id` propagation beyond a single Phoenix host.

## Out of Scope

| Feature | Reason |
|---------|--------|
| APM / observability platform (agent, ingestion, sampling) | Threadline is a thin correlation layer; emits `:telemetry`, does not collect/store telemetry |
| OpenTelemetry replacement or generic distributed tracer | Bespoke narrow header; coexists with OTel via host-owned handler, no OTel dependency |
| Logging framework | Library sets `Logger.metadata` and emits telemetry; it never emits log lines |
| Generic plugin / event bus | Only a typed audit writer; no open subscription API |
| PII in the audit ledger; library-owned audit tables | PII-free by construction (opaque `actor_ref`); host owns the generated schema |
| Async-telemetry-driven durable writes | Telemetry can drop; durable writes go through explicit `record/1`/`record_in_multi/2` |
| Full-session replay | Sequence reconstruction only; replay is not in scope |
| Cross-service thread propagation | Scoped to a single Phoenix host in v1 |
| Actor-identity reverse lookup | `actor_ref` stays opaque; no joins to user records |
| LiveDashboard / visual operator UI in v1 | Deferred to a separate `crosswake_dashboard` package (UI-01) |
| Hash-chain verify task | Append-only + advisory hash columns ship in v1; verify task deferred (INTG-01) |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| PROP-01 | Phase 92 | Complete |
| PROP-02 | Phase 91 | Complete |
| PROP-03 | Phase 92 | Complete |
| PROP-04 | Phase 91 | Complete |
| PROP-05 | Phase 93 | Complete |
| LEDG-01 | Phase 94 | Pending |
| LEDG-02 | Phase 94 | Pending |
| LEDG-03 | Phase 94 | Pending |
| LEDG-04 | Phase 94 | Pending |
| LEDG-05 | Phase 94 | Pending |
| LEDG-06 | Phase 94 | Pending |
| OPER-01 | Phase 95 | Pending |
| OPER-02 | Phase 95 | Pending |
| OPER-03 | Phase 95 | Pending |
| DOCS-01 | Phase 96 | Pending |
| DOCS-02 | Phase 96 | Pending |
| DOCS-03 | Phase 96 | Pending |
| PROOF-01 | Phase 96 | Pending |
| PROOF-02 | Phase 96 | Pending |

**Coverage:**
- v1 requirements: 19 total
- Mapped to phases: 19 (100%)
- Unmapped: 0

---
*Requirements defined: 2026-06-09*
*Last updated: 2026-06-09 — v7.0 Roadmap created (Phases 91-96)*
