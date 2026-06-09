# Phase 91: Identity + Telemetry Contract - Context

**Gathered:** 2026-06-09
**Status:** Ready for planning

<domain>
## Phase Boundary

Establish `thread_id` as a first-class, **optional** field on the existing bridge + activation contract envelopes (alongside the unchanged per-command `correlation_id`), and ship `Crosswake.Threadline.Telemetry` — the `:telemetry` event-name + low-cardinality metadata allowlist guard — **before** any Plug (Phase 92), native (Phase 93), or ledger (Phase 94) code consumes it. This is the shared-foundation phase: Phases 92 and 94 both depend on the contract surface defined here.

**Delivers (PROP-02, PROP-04):**
- `thread_id` declared on `Bridge.Contract.Request`/`Reply`, `Bridge.Denial`, and `Shell.Activation.Request`.
- `Crosswake.Threadline.Telemetry` with `@event_names`, `@metadata_keys`, `@forbidden_metadata_keys`, `safe_value?/1`, `metadata/1`, `execute/3`, `valid_event_name?/1` — mirroring the Sigra telemetry pattern.

**Explicitly NOT in this phase:** the Plug itself (`Crosswake.Plug.Threadline` → Phase 92), LiveView `on_mount` (Phase 92), native header injection (Phase 93), the audit ledger (Phase 94), and any operator surface (Phase 95). No OTel dependency, ever.

</domain>

<decisions>
## Implementation Decisions

### Contract field: `thread_id` placement & versioning
- **D-01:** `thread_id` is an **optional** field — added to `defstruct` with default `nil`, **NOT** added to `@enforce_keys` — on `Bridge.Contract.Request`, `Bridge.Contract.Reply`, `Bridge.Denial`, and `Shell.Activation.Request`. Rationale: at the moment this ships, no caller can supply it (native shells populate it in Phase 93; the Plug mints it server-side in Phase 92). Enforcing a field nobody can fill is a self-imposed deadlock and a full test-suite break. Presence is enforced at the ledger/Plug layer, never at the wire envelope — the lesson protobuf/Avro/CloudEvents all learned.
- **D-02:** Type spec is `thread_id: String.t() | nil` (opaque string, mirroring `correlation_id` — no format validation in the contract; UUID minting lives in the Phase 92 Plug).
- **D-03:** `thread_id` is copied through the existing from-request helper paths exactly like `correlation_id`: `Contract.ok_reply/2`, `Contract.deny_reply/2`, `Denial.from_request/2` propagate `request.thread_id` onto the response envelope.
- **D-04:** Bump the bridge envelope `Crosswake.Bridge.Contract.@version` `"1.0.0" → "1.1.0"` (additive/minor). This attribute is **informational** — it is NOT wired into the compatibility gate (the gate validates `bridge_protocol_version` from the manifest's `CompatibilityTruth`, sourced from `request.version`; see `compatibility.ex` ~lines 300-320, 604-607). So the bump signals "envelope can now carry thread_id" without any gate-breakage. A `"2.0.0"` bump would be dishonest — no breaking change occurred.
- **D-05:** **Footgun fix (required):** the `to_map(%Request{})` clause in `bridge/contract.ex` (lines 165-180) does **not** currently nil-filter, unlike the `Reply` clause and `Activation.to_map`. Add `|> Enum.reject(fn {_k, v} -> is_nil(v) end) |> Map.new()` so a nil `thread_id` serializes as absent rather than `"thread_id" => null`. This keeps existing `to_map` equality assertions green (field stripped when nil) and prevents wire-key drift.
- **D-06:** Hex release stays a **patch** bump (`0.1.0 → 0.1.1`) — purely additive, no `feat!:`, no adopter `~> 0.1` break.

### Telemetry event-name scope
- **D-07:** `Crosswake.Threadline.Telemetry.@event_names` declares **exactly three** names in v1:
  `[:crosswake, :threadline, :request, :start]`, `[:crosswake, :threadline, :request, :stop]`, `[:crosswake, :threadline, :request, :exception]` (the `:telemetry.span/3` triplet the Phase 92 Plug emits).
- **D-08:** Rule: **one declared event = one emitter, introduced together.** Bridge-dispatch / activation-boundary event names are added in the later phase whose code actually emits them (additive, zero cost). Do NOT pre-declare unemitted events — that is documentation debt, and an attached handler that never fires burns adopter trust. This is consistent with how Phoenix/Ecto/Oban/Finch/Broadway ship telemetry and with the project's narrow-scope honesty thesis. (The thread doc's "rich spans at every boundary" line is aspirational, not v7.0 scope.)

### `source` metadata semantics
> **Phase 91 scope note.** D-09/D-10 define the value-domain semantics and inclusion rationale for the `source` metadata key. Phase 91 *publishes* `source` as one of the four `@metadata_keys` (PROP-02, declared in plan 91-01 and asserted by the 91-02 closeout proof) but ships **zero `source` emission** — the `:inbound | :minted` value is *set* by the Phase 92 Plug (single pattern-match on the `X-Crosswake-Thread-Id` header; see `<specifics>`). The allowlist membership is real Phase 91 surface; the emission is Phase 92.
- **D-09:** `source` means **thread provenance at the boundary**, value domain `:inbound | :minted`:
  - `:inbound` — `thread_id` arrived on the `X-Crosswake-Thread-Id` request header (journey continuing from upstream).
  - `:minted` — the Plug generated a fresh UUID because no header was present (journey boundary starts here).
- **D-10:** Rationale: it is the only one of PROP-02's four allowlist keys (`thread_id`, `correlation_id`, `route_id`, `source`) carrying information not reconstructable from the others; maps cleanly onto W3C `traceparent` continuation / OTel `SpanContext.isRemote()` / `Plug.RequestId` mint-or-echo conventions; is a fixed 2-atom low-cardinality enum (no drift); and does **not** collide with the audit ledger's `provenance ∈ {:device_claimed, :backend_accepted}` (different tier, disjoint values, orthogonal question). The shallow English-word overlap with `Shell.Activation.Request.source` (`:cold_start | :deep_link | …`) is tolerable: distinct module namespaces and fully disjoint value domains.

### Threadline.Telemetry module shape (mirror Sigra exactly)
- **D-11:** Mirror `Crosswake.Companions.Sigra.Telemetry` structure:
  - `@metadata_keys [:thread_id, :correlation_id, :route_id, :source]` (PROP-02 fixed set).
  - `@forbidden_metadata_keys` — a PII denylist in the spirit of Sigra's (e.g. tokens, ids, email, ip, user_agent, subject/session/actor refs). Researcher/planner to finalize the exact list from Sigra's `@forbidden_metadata_keys`.
  - `safe_value?/1` — atom OK; non-negative integer OK; binary OK iff `String.length(value) <= 128`; `nil` and everything else rejected.
  - `metadata/1` — reduce-filter that drops forbidden keys, keeps allowlisted keys with safe values, drops everything else (no raise).
  - `execute/3` — wraps `:telemetry.execute/3`, passing metadata through `metadata/1` first.
  - `valid_event_name?/1` / `event_names/0` accessors.

### Claude's Discretion
- Exact ordering of `defstruct` keys, the precise `@forbidden_metadata_keys` membership (derive from Sigra), whether a small `Event` helper struct (à la Sigra's) is worth it for Threadline's narrow surface, and test file organization — all left to research/planning.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Threadline definition & requirements
- `.planning/threads/threadline-audit.md` — canonical Threadline definition (note: its "rich spans at every boundary" framing is aspirational, NOT v7.0 scope — see D-08).
- `.planning/research/SUMMARY.md` — v7.0 north star; "What Threadline is NOT" anti-scope.
- `.planning/REQUIREMENTS.md` §PROP — PROP-02 (telemetry allowlist + forbidden-key rejection) and PROP-04 (`thread_id` first-class on bridge/activation contracts) are this phase's requirements.

### Pattern to mirror (MOST important code ref)
- `lib/crosswake/companions/sigra/telemetry.ex` — the exact telemetry-contract pattern Threadline mirrors (`@event_names`, `@metadata_keys`, `@forbidden_metadata_keys`, `safe_value?/1`, `metadata/1`, `execute/3`, `valid_event_name?/1`).
- `lib/crosswake/companions/chimeway/telemetry.ex`, `lib/crosswake/offline/telemetry.ex` — two more in-repo telemetry contracts for comparison (note: Offline declares only `@metadata_keys`, no event-name allowlist — do NOT follow that looser shape; follow Sigra).

### Envelopes to extend
- `lib/crosswake/bridge/contract.ex` — `Request`/`Reply` structs, `@version "1.0.0"`, `new_request/1`, `ok_reply/2`, `deny_reply/2`, `to_map/1` (nil-filter footgun — D-05).
- `lib/crosswake/bridge/denial.ex` — `Denial` struct + `from_request/2`, `to_map/1`.
- `lib/crosswake/shell/activation.ex` — `Activation.Request` struct (`@enforce_keys` incl. `correlation_id`), `new_request/1`, `to_map/1` (already nil-filters).
- `lib/crosswake/compatibility/compatibility.ex` (~lines 300-320, 604-607) & `lib/crosswake/compatibility/route_gate.ex` — confirm envelope `@version` is NOT gate-wired (D-04); `bridge_protocol_version` is the gated value.

### Project conventions
- `.planning/research/REC-VERSIONING.md` — project versioning philosophy (supports additive-minor / patch posture in D-04, D-06).
- `prompts/crosswake-elixir-oss-dna.md` — maintainer OSS house style (install/claim honesty, narrow-scope; underpins D-08).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`Crosswake.Companions.Sigra.Telemetry`**: near-exact template for `Crosswake.Threadline.Telemetry`. Copy the structure (allowlist atoms, `safe_value?/1` ≤128-char rule, reduce-filter `metadata/1`, `execute/3` wrapper, `valid_event_name?/1` raise-free guard), narrow `@metadata_keys` to the PROP-02 four, declare only the request span triplet.
- **`Bridge.Contract` from-request helpers** (`ok_reply/2`, `deny_reply/2`) and **`Denial.from_request/2`**: already copy `correlation_id` request→response; `thread_id` rides the same path (D-03).
- **`Chimeway.Redaction.fingerprint_token/2`** (`lib/crosswake/companions/chimeway/redaction.ex`): the HMAC helper Phase 94's `actor_ref` will mirror — noted for continuity, NOT in Phase 91 scope.

### Established Patterns
- **Versioned wire envelopes**: `@protocol`/`@version` module attributes + `to_map/1` serialization with nil-rejection (Reply/Activation already do this; Request does not yet — D-05).
- **`@enforce_keys` discipline**: enforce only fields the caller is definitionally responsible for at construction time; everything else gets a default. `thread_id` is not the caller's responsibility yet → optional (D-01).
- **Telemetry contract = published allowlist**: `@event_names` + `@metadata_keys` accessors function as the public contract; proof tests assert the exact lists (cf. Sigra's phase-58 closeout test).

### Integration Points
- `thread_id` flows: native shell / inbound header (Phase 93) → `Plug.Threadline` mints-or-reads + sets `Logger.metadata` + emits the request span (Phase 92) → bridge/activation envelopes carry it (this phase's field) → audit ledger records it (Phase 94) → operator surface reads it (Phase 95).
- Phase 91 ships **zero runtime emission**: it defines the field + the telemetry guard. The first emitter is the Phase 92 Plug.

</code_context>

<specifics>
## Specific Ideas

- `source` operator microcopy (for the eventual guide/doctor text): "`source` — `:inbound` if the thread_id arrived on the `X-Crosswake-Thread-Id` header (journey continuing); `:minted` if the Plug generated a fresh UUID because no header was present (journey starts here)."
- `source` is set by a single pattern-match on whether `Plug.Conn.get_req_header(conn, "x-crosswake-thread-id")` returned a non-empty value (Phase 92 impl note — recorded so the contract semantics and the future Plug stay aligned).

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope. (No scope creep surfaced; no pending todos matched this phase.)

</deferred>

---

*Phase: 91-identity-telemetry-contract*
*Context gathered: 2026-06-09*
