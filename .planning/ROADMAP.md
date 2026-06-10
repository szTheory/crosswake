# Roadmap: Crosswake

## Milestones

- 🚧 **v7.0 Threadline Audit Capstone** — Phases 91-96 (in progress)
- ✅ **v6.0 Adoption Evidence Demo App (Flashcard Cohort)** — Phases 84-90 (shipped 2026-06-09)
- ✅ **v5.1 Adoption Evidence Demo App** — Phases 80-83 (shipped 2026-06-09)
- ✅ **v5.0 Standalone Publishable Shell Packages** — Phases 76-79 (shipped 2026-06-06)

_Full shipped history: see `.planning/MILESTONES.md`. Archived roadmaps: `.planning/milestones/`._

## Phases

<details>
<summary>✅ v6.0 Adoption Evidence Demo App (Flashcard Cohort) (Phases 84-90) — SHIPPED 2026-06-09</summary>

- [x] Phase 84: Offline Substrate Foundation (1/1 plans)
- [x] Phase 85: Sync & Event Log Foundation (1/1 plans)
- [x] Phase 86: Flashcard Domain Setup (Demo App) (2/2 executed; 86-00 TDD plan superseded)
- [x] Phase 87: Online LiveView & Architecture (1/1 plans)
- [x] Phase 88: Offline Island & Local Engine (1/1 plans)
- [x] Phase 89: E2E Integration & UI Polish (1/1 plans)
- [x] Phase 90: Shift-Left CI/CD & Closeout (1/1 plans)

Full detail: `.planning/milestones/v6.0-ROADMAP.md`

</details>

### 🚧 v7.0 Threadline Audit Capstone (In Progress)

**Milestone Goal:** Give Crosswake day-2 operational viability — correlate the Native → Bridge → Phoenix → DB event sequence for a single user journey and durably record terminal critical events, narrowly and honestly, PII-free, without becoming an APM, an OTel replacement, or a database-bloat machine.

- [x] **Phase 91: Identity + Telemetry Contract** - Add `thread_id` to bridge/activation contracts and ship the `Crosswake.Threadline.Telemetry` allowlist module (completed 2026-06-09)
- [x] **Phase 92: Server Propagation — Plug + LiveView** - Ship `Crosswake.Plug.Threadline` (read/mint header, Logger metadata, telemetry spans) and `Crosswake.Live.Threadline` on_mount (completed 2026-06-09)
- [x] **Phase 93: Native Shell Propagation** - iOS and Android inject `X-Crosswake-Thread-Id` on initial load and expose `window.crosswakeBridge.threadId` (completed 2026-06-09)
- [x] **Phase 94: Audit Ledger Contract + Generator** - Ship `Crosswake.Audit.Ledger` contract struct and `mix crosswake.gen.audit` scaffold with full PII-free, append-only schema (completed 2026-06-09)
- [x] **Phase 95: Operator Surface** - Ship `mix crosswake.threadline` task, Threadline doctor findings, and `@audit_ledger_support_truth` support-matrix row (gaps_found 2026-06-10 — gap-closure plans 95-03/95-04 created) (completed 2026-06-10)
- [x] **Phase 96: Docs-Contract + Proof** - Ship `guides/threadline.md` with mechanically-checked parity, hermetic merge-blocking proof lane, and advisory example-host ledger proof (completed 2026-06-10)

## Phase Details

### Phase 91: Identity + Telemetry Contract
**Goal**: The `thread_id` identity is established as a first-class field on bridge and activation contracts, and the `Crosswake.Threadline.Telemetry` module enforces low-cardinality metadata allowlisting before any Plug or native code is written
**Depends on**: Phase 90 (v6.0 closeout complete)
**Requirements**: PROP-02, PROP-04
**Success Criteria** (what must be TRUE):
  1. `thread_id` is a declared field on the bridge `Request`/`Reply`/`Denial` and `ActivationRequest` envelopes alongside the unchanged `correlation_id`
  2. `Crosswake.Threadline.Telemetry` exists with `@metadata_keys` allowlist, `@forbidden_metadata_keys`, and `safe_value?/1` mirroring the Sigra telemetry pattern
  3. Telemetry emission via `execute/3` rejects any metadata key on the forbidden list without raising — tested hermetically
  4. No OTel dependency is introduced; the module uses only the existing `:telemetry` application
**Plans**: 2 plans
- [x] 91-01-PLAN.md — `Crosswake.Threadline.Telemetry` allowlist module + hermetic unit tests (PROP-02)
- [x] 91-02-PLAN.md — `thread_id` on bridge/activation envelopes, `@version`/Hex bumps, published-contract closeout proof (PROP-04, PROP-02)

### Phase 92: Server Propagation — Plug + LiveView
**Goal**: A Phoenix team can add `Crosswake.Plug.Threadline` to a pipeline and opt a LiveView in via `on_mount` so that every HTTP request and every LiveView WebSocket mount carries a `thread_id` in `Logger.metadata` and emits telemetry spans
**Depends on**: Phase 91
**Requirements**: PROP-01, PROP-03
**Success Criteria** (what must be TRUE):
  1. `Crosswake.Plug.Threadline` reads `X-Crosswake-Thread-Id` from the request header, mints a UUID fallback when absent, never overwrites an inbound id, sets `Logger.metadata(crosswake_thread_id: …)`, echoes the id on the response header, and emits `[:crosswake, :threadline, :request, :start|:stop|:exception]` telemetry
  2. The library never calls `Logger.info/warning/error` — only `Logger.metadata` and `:telemetry.span/3`
  3. `Crosswake.Live.Threadline` `on_mount/4` reads `_crosswake_thread_id` from LiveView connect params and sets `thread_id` on the LiveView process metadata
  4. The Plug correctly rejects forbidden/PII keys via the shared allowlist guard from Phase 91
**Plans**: 3 plans
- [x] 92-01-PLAN.md — `Crosswake.Threadline.Id` UUID minting + `Crosswake.Plug.Threadline` (read/mint header, Logger.metadata, response echo, telemetry triplet) (PROP-01)
- [x] 92-02-PLAN.md — `Crosswake.Live.Threadline` `on_mount/4` connect-param metadata bridge (PROP-03)
- [x] 92-03-PLAN.md — hermetic merge-blocking closeout proof lane + `mix.exs` 0.1.1→0.1.2 (PROP-01, PROP-03)
**UI hint**: no (backend-only: Plug + LiveView on_mount; no visual surface. The visual UI is UI-01's `crosswake_dashboard`, a separate opt-in package not in this milestone)

### Phase 93: Native Shell Propagation
**Goal**: The iOS and Android native shells carry `thread_id` across the full activation sequence so that Native → Bridge → Phoenix correlation is complete end-to-end
**Depends on**: Phase 92
**Requirements**: PROP-05
**Success Criteria** (what must be TRUE):
  1. The iOS shell (`ActivationCoordinator` / `LiveViewContainerViewController`) injects `X-Crosswake-Thread-Id` as a header on the initial WebView `URLRequest` load
  2. The Android shell injects the same header on `loadUrl` for the initial WebView load
  3. Both shells expose `window.crosswakeBridge.threadId` for the LiveView WebSocket path (LiveSocket connect param)
  4. `thread_id` is carried across `cold_start → deep_link → notification → in_app_navigation` activation continuations without being overwritten
  5. The two-channel design (HTTP header on initial load; connect param for WebSocket) and the documented JS `fetch`/`XHR` sub-navigation gap are reflected in native code and comments
**Plans**: 2 plans
- [x] 93-01-PLAN.md — iOS Native Shell Thread Propagation
- [x] 93-02-PLAN.md — Android Native Shell Thread Propagation

### Phase 94: Audit Ledger Contract + Generator
**Goal**: A host team can run `mix crosswake.gen.audit` to scaffold a fully-formed, PII-free, append-only Ecto audit ledger with ProvenanceLane and advisory hash columns — and the `Crosswake.Audit.Ledger` contract struct is available in core so producers know the canonical event shape
**Depends on**: Phase 91
**Requirements**: LEDG-01, LEDG-02, LEDG-03, LEDG-04, LEDG-05, LEDG-06
**Success Criteria** (what must be TRUE):
  1. `mix crosswake.gen.audit` scaffolds the host-owned `crosswake_audit_events` Ecto schema idempotently — rerunning prints `[crosswake] reused` and never overwrites host edits (matching `gen.sync` behavior)
  2. The generated schema contains all canonical columns: `thread_id`, `correlation_id`, `route_id`, `actor_ref` (opaque), `actor_kind`, `event_class`, `event_type`, `outcome`, `provenance`, `occurred_at`, `recorded_at`, `idempotency_key` (unique index), `metadata`, `row_hash`, `prev_hash`
  3. The `provenance` column is a first-class enum constraining values to `{:device_claimed, :backend_accepted}` — no raw strings; device evidence cannot masquerade as backend authority
  4. `reject_pii_in_metadata/1` changeset guard fails closed on any forbidden key in the `metadata` field; an HMAC `actor_ref` helper mirrors `Chimeway.Redaction.fingerprint_token/2`
  5. The generated writer exposes `record/1` (standalone immediate insert) and `record_in_multi/2` (compose into host `Ecto.Multi`) with docstrings clearly stating `record/1` is not transactionally atomic with the caller
  6. No `update` or `delete` helpers are generated; `row_hash`/`prev_hash` are computed at insert for offline tamper detection
**Plans**: 3 plans
- [x] 94-01-PLAN.md — Core Audit Ledger Contract and HMAC Helper
- [x] 94-02-PLAN.md — Audit Ledger Schema and Migration Templates
- [x] 94-03-PLAN.md — Mix Generator for Audit Ledger

### Phase 95: Operator Surface
**Goal**: An operator can query the event sequence for a thread or actor in text form and the doctor + support matrix give honest, actionable Threadline posture — including a fail-closed PII error
**Depends on**: Phase 94
**Requirements**: OPER-01, OPER-02, OPER-03
**Success Criteria** (what must be TRUE):
  1. `mix crosswake.threadline --thread-id <id>` (and `--actor-ref <ref>`) prints an ordered Native → Bridge → Phoenix event table with explicit `posture: ephemeral` when no ledger is configured and `posture: durable` when the ledger is configured
  2. `mix crosswake.doctor` reports Threadline posture and emits `threadline.plug_missing` (advisory), `threadline.ledger_not_configured` (advisory), `threadline.ledger_schema_drift` (warning), and `threadline.pii_forbidden_field_present` (error, fail-closed)
  3. The support matrix exposes a `@audit_ledger_support_truth` module attribute row with explicit denial/fallback posture — `ephemeral-only` when no ledger is configured is non-blocking, not an error
  4. All three operator surfaces use only text output; no LiveDashboard dependency is introduced
**Plans**: 5 plans (2 executed + 3 gap-closure)
- [x] 95-01-PLAN.md — Support Matrix Truth & Doctor Findings
- [x] 95-02-PLAN.md — CLI Task for Threadline Posture
- [x] 95-03-PLAN.md — Gap closure: doctor fail-closed PII correctness (CR-01/CR-02/CR-04, OPER-02)
- [x] 95-04-PLAN.md — Gap closure: threadline chronological sort across month boundaries (CR-03, OPER-01)
- [x] 95-05-PLAN.md — Gap closure: guard Code.ensure_loaded? against non-atom :schema config (fail-closed, OPER-02)

### Phase 96: Docs-Contract + Proof
**Goal**: `guides/threadline.md` is the honest public contract for the Threadline feature, mechanically verified against the shipped code, with a hermetic merge-blocking proof lane and an advisory example-host ledger proof
**Depends on**: Phase 95
**Requirements**: DOCS-01, DOCS-02, DOCS-03, PROOF-01, PROOF-02
**Success Criteria** (what must be TRUE):
  1. `guides/threadline.md` exists and documents the header name (`X-Crosswake-Thread-Id`), all canonical `AuditEvent` field names, the forbidden-field list, ephemeral-vs-durable posture, module/task names, and the "terminal critical events only" scope — each asserted via `contains-exact` tests that block merge on failure
  2. The guide contains a mechanically-checked "What Threadline is NOT" anti-scope section (not APM, not OTel, not a logging framework, not a plugin bus, no PII, no session replay)
  3. The guide documents the honest limitations: WebView WebSocket/`fetch`/`XHR` header gap, "hash-chaining detects but does not prevent tampering," and OTel coexistence with zero OTel dependency
  4. A hermetic merge-blocking proof lane passes: Plug metadata and telemetry emission, telemetry forbidden-key rejection, `gen.audit` idempotency, doctor findings, and `guides/threadline.md` parity — no Ecto/network/device required
  5. An advisory example-host proof lane verifies real Ecto-backed `record_in_multi/3` persistence and `mix crosswake.threadline` reconstruction with `durable` posture against a seeded ledger
**Plans**: 3 plans
- [x] 96-01-PLAN.md — Restructure `guides/threadline.md` to the contract-first 10-section outline with verbatim contract content, anti-scope, and locked microcopy (DOCS-01/02/03)
- [x] 96-02-PLAN.md — Hermetic docs-contract parity test + merge-blocking proof workflow (DOCS-01/02/03, PROOF-01)
- [x] 96-03-PLAN.md — Example-host gen.audit output + Ecto-backed durable-posture proof + advisory workflow (PROOF-02)

### Phase 97: Fix guide accuracy: conn.assigns claim + record_in_multi arity

**Goal:** `guides/threadline.md` accurately documents the two surfaces the v7.0 milestone audit flagged — adopters read the thread id via `Logger.metadata()[:crosswake_thread_id]` (not the non-existent `conn.assigns[:thread_id]`, WR-03) and call `record_in_multi/3` (not `/2`, WR-02) — with two hermetic parity assertions that fail CI if either bug reappears.
**Requirements**: WR-03, WR-02 (milestone-audit items); D-03 (regression-guard decision)
**Depends on:** Phase 96
**Plans:** 1 plan

Plans:
- [ ] 97-01-PLAN.md — Fix WR-03 (Logger.metadata read-path) + WR-02 (record_in_multi/3) guide lines and add two regression-prevention parity assertions, in one atomic commit
