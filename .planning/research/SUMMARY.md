# v7.0 Threadline Audit Capstone — Research Synthesis

> Milestone-scoped north star. Produced from 3 parallel codebase-grounded research tracks
> (propagation/OTel, durable ledger, operator UX/packaging) plus a deep map of the live code.
> Consumed by `gsd-roadmapper`. Canonical milestone definition: `.planning/threads/threadline-audit.md`.

## One-line goal

Give Crosswake **day-2 operational viability**: correlate the sequence of Native → Bridge → Phoenix → DB
events for a single user journey, and durably record terminal critical events — narrowly, honestly, and
PII-free, without becoming an APM, an OTel replacement, or a database-bloat machine.

## The shape: three-tier, ephemeral-first

1. **Correlation propagation (core, zero new deps).** A new session-spanning `thread_id` sits *above* the
   existing per-command `correlation_id` (trace_id/span_id semantics). A `Crosswake.Plug.Threadline` reads
   `X-Crosswake-Thread-Id` (mints as fallback like `Plug.RequestId`), sets `Logger.metadata`, emits
   `:telemetry` spans at boundary crossings. A `Crosswake.Live.Threadline` `on_mount` picks the id up from a
   LiveView connect param for the WebSocket path. The library **never calls Logger itself** — it emits
   telemetry and sets metadata; the host logs.
2. **Durable audit ledger (companion, opt-in).** `mix crosswake.gen.audit` scaffolds a **host-owned** Ecto
   schema + thin writer (copying the `gen.sync` pattern) recording **only terminal critical events**
   (commerce receipt, auth handoff/step-up, notification-open, media-acceptance). PII-free by construction
   (opaque `actor_ref`), append-only, with a first-class **ProvenanceLane** column
   (`device_claimed` vs `backend_accepted`) that encodes the backend-authority thesis.
3. **Operator surface (text-only in v1).** `mix crosswake.threadline` prints an ordered event table with
   `ephemeral`/`durable` posture; Doctor + SupportMatrix + OperatorInspection get additive Threadline truth.
   The LiveDashboard Native→Bridge→Server timeline is **deferred** to a future `crosswake_dashboard` package.

## Locked decisions (user-confirmed 2026-06-09)

| Decision | Choice | Why |
|---|---|---|
| Version | **v7.0** | Major capstone — a new cross-cutting correlation/audit plane |
| Identity | New `thread_id` **above** unchanged `correlation_id` | trace/span semantics; no breaking renames |
| Standard | Bespoke `X-Crosswake-Thread-Id`, **zero OTel dep**, documented coexistence | honest scope; no forced observability stack |
| Logging | Plug sets `Logger.metadata` + emits telemetry; **lib never logs** | idiomatic Elixir library posture |
| Ledger ownership | Host-owned generated (gen.sync pattern), opt-in | house style; no lib-owned PII tables |
| Write path | scaffold `record/1` + `record_in_multi/2` | honest durability; no overclaimed transactional guarantee |
| Provenance | first-class `provenance` enum column | backend-authority thesis; offline-replay attribution |
| PII/GDPR | PII-free by construction; opaque `actor_ref`; fail-closed metadata guard | erasure = delete host mapping, ledger intact |
| Integrity | append-only by convention + nullable `row_hash`/`prev_hash` (advisory) | detects, does not prevent tamper — stated plainly; verify-task deferred |
| Operator UI | text-only mix task + doctor in v1; LiveDashboard deferred | no overclaiming; rich timeline needs the opt-in ledger anyway |
| Packaging | **split** — propagation Plug/telemetry core; ledger scaffold companion (in-tree) | Ecto is host-side; Plug is zero-dep cross-cutting |

## Stack additions: essentially none (this is a feature, not a dependency)

- **No new runtime deps.** `:telemetry` and `Logger` are already present; `Ecto.UUID.generate/0` is available
  via Phoenix/Ecto; native UUIDs come from platform stdlib (`UUID().uuidString` / `UUID.randomUUID()`).
- **Explicitly NOT added:** `opentelemetry*` (coexist, don't depend), `phoenix_live_dashboard` in core
  (UI deferred to a separate package), any ULID/UUIDv7 library (binary_id PK + UUIDv4 propagation suffice).

## Feature map (table stakes vs differentiators)

**Propagation (PROP-)** — *table stakes:* thread_id mint/accept/echo, Logger metadata, telemetry spans,
LiveView on_mount, native header injection (iOS+Android). *Differentiator:* honest two-channel design that
states the WebView WebSocket-header limitation rather than faking full coverage.

**Audit ledger (LEDG-)** — *table stakes:* opt-in generator, host-owned schema, idempotency, append-only.
*Differentiators:* **ProvenanceLane** (evidence vs authority), **PII-free-by-construction + fail-closed guard**,
`record_in_multi/2` for atomic terminal events — none of the mainstream audit libs (paper_trail/ex_audit/
carbonite) ship the evidence-vs-authority distinction.

**Operator (OPER-)** — *table stakes:* `mix crosswake.threadline`, doctor findings, support-matrix row.
*Differentiator:* honest `ephemeral` vs `durable` posture reporting; fail-closed PII doctor error.

**Docs/Proof (DOCS-/PROOF-)** — *table stakes:* `guides/threadline.md`, merge-blocking contains-exact docs
parity, hermetic Plug proof, advisory example-host ledger proof. *Differentiator:* a mechanically-checked
"What Threadline is NOT" anti-scope section in the guide.

## Build order (dependency-aware)

1. Identity + telemetry contract: `thread_id` field on bridge/activation contracts + `Crosswake.Threadline.Telemetry`.
2. `Crosswake.Plug.Threadline` + `Crosswake.Live.Threadline` (server propagation, Logger metadata, spans).
3. Native shell propagation (iOS+Android initial-load header + `window.crosswakeBridge.threadId`).
4. `Crosswake.Audit.Ledger` contract struct (core) + `mix crosswake.gen.audit` scaffold + templates (companion).
5. Operator surface: `mix crosswake.threadline`, doctor findings, `@audit_ledger_support_truth`, optional `audit_entry/1`.
6. `guides/threadline.md` + docs-contract assertions + hermetic & advisory proof lanes + CI workflow.

## Watch out for (top pitfalls — see PITFALLS.md)

- **PII in append-only logs (GDPR).** Right-to-erasure vs immutable ledger. Mitigation: store opaque
  `actor_ref` only; never raw identity; fail-closed `reject_pii_in_metadata/1` guard; doctor PII scan.
- **Overclaimed durability.** Telemetry can drop; don't drive the durable write from a telemetry handler.
  Scaffold an explicit `record_in_multi/2` so terminal events commit atomically with the business change.
- **hash-chaining detects ≠ prevents tamper.** State it plainly in docs; ship detection only in v1.
- **WebView header limits.** WKWebView/Android WebView cannot inject headers on the LiveView WS upgrade —
  use the connect-param channel and document the `fetch`/`XHR` sub-navigation gap honestly.
- **Library-logging anti-pattern.** The lib must emit telemetry + set Logger metadata, never `Logger.info`.
- **Scope creep into APM.** Hard anti-scope: not OTel, not a tracer, not session replay, not a plugin bus.

## Reuse, don't reinvent (verified code anchors)

- Telemetry allowlist + `safe_value?` guard: `lib/crosswake/companions/sigra/telemetry.ex` (copy verbatim).
- Fail-closed authority guard: `reject_trace_authority_lane/2` in `lib/crosswake/companions/rindle/contracts.ex`.
- Generator pattern: `lib/mix/tasks/crosswake.gen.sync.ex` + `priv/templates/crosswake/sync/*.eex` (`ensure_file/2`).
- Opaque pseudonym helper: `Chimeway.Redaction.fingerprint_token/2`.
- Additive extension points: Doctor `phase_N_*_findings/1`, SupportMatrix `@*_support_truth`,
  OperatorInspection `*_entry/1`; docs parity via `test/support/proof_assertions.ex`.
- `correlation_id` already first-class on bridge/activation/native envelopes — `thread_id` layers above it.
