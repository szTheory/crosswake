# Domain Pitfalls: v7.0 Threadline Audit Capstone

**Domain:** Cross-boundary correlation + tamper-evident-ish audit (Phoenix↔mobile)
**Researched:** 2026-06-09 · **Confidence:** HIGH (codebase + cross-ecosystem)

Ordered by blast radius. Each: the trap, the cross-ecosystem evidence, the prevention, and which phase owns it.

## 1. PII in an append-only ledger (GDPR right-to-erasure conflict) — CRITICAL

- **Trap:** Storing `actor_id`/`email`/`session_ref` in immutable audit rows makes GDPR erasure a migration.
  `paper_trail` (Ruby) stores `whodunnit` as a raw id — a well-known GDPR trap.
- **Prevention:** PII-free by construction. Only an opaque `actor_ref` (HMAC pseudonym; reuse
  `Chimeway.Redaction.fingerprint_token/2`). `reject_pii_in_metadata/1` changeset guard **fails closed** on a
  forbidden-key list (mirror `reject_trace_authority_lane/2`). A doctor check scans the generated schema for
  forbidden field names and emits `threadline.pii_forbidden_field_present` (`:error`). Erasure = delete the
  host-owned actor mapping; ledger rows stay intact.
- **Owner:** ledger schema/generator + doctor phases.

## 2. Overclaimed durability via async telemetry writes — HIGH

- **Trap:** Driving the durable ledger write from a `:telemetry` handler looks elegant but telemetry events
  drop on process/VM crash and give no transactional guarantee — silent audit gaps. (Observability systems use
  async; *audit* systems must not.)
- **Prevention:** The library does **not** write the ledger from telemetry. The scaffold provides explicit
  `record/1` and `record_in_multi/2`; docstrings steer true terminal events (commerce receipt, auth handoff
  redeem) into the host's business `Ecto.Multi` so the audit row commits iff the business change commits.
  Docs state plainly that `record/1` is not atomic with the caller's transaction.
- **Owner:** ledger generator + guide.

## 3. "Tamper-proof" overclaim — HIGH (honesty)

- **Trap:** Claiming the ledger is tamper-proof. No OSS Elixir lib can prevent a DB admin from rewriting rows;
  hash-chaining **detects, does not prevent** (recorded footgun). AWS QLDB only achieves more via independently-
  stored digests; mainstream audit libs (carbonite/ex_audit/paper_trail) ship no hash chain at all.
- **Prevention:** v1 = append-only by convention (no update/delete helpers) + nullable `row_hash`/`prev_hash`
  for offline detection. Exact docs wording: "hash chaining detects tampering; it does not prevent it … treat
  this as a detective control, not a preventive one." Defer a `mix crosswake.audit.verify` chain-checker.
- **Owner:** guide + ledger schema.

## 4. WebView header-injection limits — HIGH (architecture honesty)

- **Trap:** Assuming a native-set `X-Crosswake-Thread-Id` flows transparently to all server requests.
  WKWebView and Android WebView **cannot** inject headers on the LiveView WebSocket upgrade, and JS
  `fetch`/`XHR` sub-navigations don't carry the header.
- **Prevention:** Two-channel design — header on the initial load; `window.crosswakeBridge.threadId` →
  LiveSocket connect param → `Crosswake.Live.Threadline` on_mount for the WS. Document the `fetch`/`XHR` gap.
- **Owner:** native propagation phase + guide.

## 5. Library logging instead of telemetry — MEDIUM (idiom)

- **Trap:** Having the lib call `Logger.info` (it currently has zero Logger usage). Log level/format/destination
  are host decisions; library log lines are noise the host can't control.
- **Prevention:** Plug sets `Logger.metadata` (like `Plug.RequestId`) and emits `:telemetry`; the lib never
  emits log lines. Hosts attach handlers.
- **Owner:** Plug + telemetry phases.

## 6. Telemetry cardinality / PII leakage — MEDIUM

- **Trap:** Putting raw ids, tokens, payloads, IP, or user-agent into telemetry metadata — high cardinality and
  a PII leak. Already an established forbidden pattern in Sigra/Chimeway.
- **Prevention:** `Crosswake.Threadline.Telemetry` copies the existing allowlist + `safe_value?` + forbidden-key
  guard verbatim. Only low-cardinality keys (`thread_id, correlation_id, route_id, source, …`).
- **Owner:** telemetry phase + hermetic proof.

## 7. Ecto.Multi atomicity edge cases — MEDIUM

- **Trap:** `record_in_multi/2` composed wrong (e.g. the audit step references a value not yet in the Multi, or
  the host forgets to wrap in a transaction) → audit row commits without the business change or vice versa.
- **Prevention:** Scaffold `record_in_multi/2` as a proper `Ecto.Multi.run`/`insert` step with a docstring example;
  advisory example-host proof exercises the real transaction path.
- **Owner:** ledger generator + advisory proof.

## 8. Scope creep into APM / OTel / plugin bus — MEDIUM (strategic)

- **Trap:** Threadline drifting into "Crosswake observability platform" — distributed tracing, sampling, a UI
  that implies full-journey capture, generic event subscriptions.
- **Prevention:** Hard anti-scope, mechanically checked: a "What Threadline is NOT" guide section asserted by
  `ProofAssertions`. Bespoke header (no OTel dep, documented coexistence). Text-only operator surface in v1;
  LiveDashboard deferred to a separate package. No generic subscription API beyond the typed audit writer.
- **Owner:** guide/docs-contract + scope guardrails in REQUIREMENTS.md Out-of-Scope.

## 9. Phase-archival/closeout brittleness (process) — LOW

- **Trap:** v6.0 closeout left phase dirs unarchived and used a mocked E2E that hid a compile break (recorded).
  Don't repeat: don't fake the proof lane, and archive phases honestly at closeout.
- **Prevention:** advisory example-host ledger proof must run for real before closeout; verifier should derive
  the milestone from frontmatter, not hardcode it.
- **Owner:** proof phase + milestone closeout.
