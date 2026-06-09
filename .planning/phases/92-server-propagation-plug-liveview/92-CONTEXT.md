# Phase 92: Server Propagation — Plug + LiveView - Context

**Gathered:** 2026-06-09
**Status:** Ready for planning

<domain>
## Phase Boundary

Ship the two server-side `thread_id` propagation surfaces that consume the Phase 91 contract:

- **`Crosswake.Plug.Threadline`** — reads `X-Crosswake-Thread-Id` from the request header, mints a UUIDv4 fallback when absent, never overwrites an inbound id, sets `Logger.metadata(crosswake_thread_id: …)`, echoes the id on the response header, and emits the `[:crosswake, :threadline, :request, :start | :stop | :exception]` telemetry triplet (routed through the Phase 91 allowlist guard).
- **`Crosswake.Live.Threadline.on_mount/4`** — reads `_crosswake_thread_id` from LiveView connect params and sets `crosswake_thread_id` on the LiveView process `Logger.metadata`.

Backend-only — **no visual surface** (the visual UI is UI-01's separate `crosswake_dashboard` package, not in this milestone).

**Delivers (PROP-01, PROP-03).**

**Explicitly NOT in this phase:** native header injection / `window.crosswakeBridge.threadId` (Phase 93), the audit ledger (Phase 94), operator surface / `mix crosswake.threadline` (Phase 95), docs guide (Phase 96). No OTel dependency, ever. No new runtime dependency of any kind.

</domain>

<decisions>
## Implementation Decisions

All four areas below were researched in parallel (advisor mode, `minimal_decisive` tier) against the actual Plug 1.19 / Phoenix 1.8 / LiveView 1.1 source. Recommendations are locked.

### Request span lifecycle (the Plug)
- **D-01:** Emit the triplet via the **`Plug.Telemetry` idiom, NOT a literal `:telemetry.span/3` call.** In `call/2`: read-or-mint the id, capture `System.monotonic_time/0`, emit `[:crosswake, :threadline, :request, :start]`, then `Plug.Conn.register_before_send/2` a callback that emits `:stop` with real `monotonic_time - start` duration when the response is actually sent.
- **D-02:** **Reconcile with Phase 91 D-07:** D-07's phrase "the `:telemetry.span/3` triplet the Phase 92 Plug emits" denotes the event-name *shape* (start/stop/exception as a set), **not** a mandate to call the `span/3` function. A function plug returns to the pipeline before downstream work runs, so a real `span/3` wrapping the plug body would fire `:stop` at ~microsecond duration before the response is sent — a dishonest duration, against house style. All three declared event names are still emitted; only the mechanism differs.
- **D-03:** **`:exception` is scoped honestly to the plug's OWN synchronous minting work** (header read, UUID generation, `Logger.metadata` set, resp-header put) via a local `try/rescue` in `call/2` that emits `[:crosswake, :threadline, :request, :exception]` and re-raises. A function plug **cannot** catch downstream pipeline raises — those unwind past `register_before_send` without firing it; `Phoenix.Router` already owns `[:phoenix, :router_dispatch, :exception]` for that case. This narrow scope MUST be stated in a code comment and in the eventual guide so the `:exception` event is not over-claimed.
- **D-04:** All telemetry metadata (`thread_id`, `correlation_id`, `route_id`, `source`) is routed through `Crosswake.Threadline.Telemetry.execute/3` / `metadata/1` so the Phase 91 allowlist + forbidden-key guard is applied at every emission (satisfies success criterion 4). `source` is set by a single pattern-match on whether `get_req_header(conn, "x-crosswake-thread-id")` returned a non-empty value → `:inbound`, else `:minted` (Phase 91 D-09).
- **D-05:** The library **never** calls `Logger.info/warning/error` — only `Logger.metadata` + the `Threadline.Telemetry` emitter (success criterion 2; this is the first `Logger.metadata` use in the codebase).

### LiveView `on_mount/4`
- **D-06:** **Read-only, no minting.** `on_mount(:default, _params, _session, socket)`: guard on `Phoenix.LiveView.connected?(socket)` (connect params are always `nil` on the static render), read `_crosswake_thread_id` via `get_connect_params/1`, and set `Logger.metadata(crosswake_thread_id: id)` on the LiveView GenServer process. The **Plug is the sole mint authority** (PROP-01) — minting in `on_mount` would create a phantom thread_id divorced from the Plug-minted id. The LiveView WebSocket is a separate connection that does NOT traverse the HTTP plug pipeline, so the new process starts with empty metadata; `on_mount` establishes parity by setting it.
- **D-07:** Absent connect param (or disconnected render) → `{:cont, socket}` no-op, **no metadata set, no error.** Until Phase 93 supplies `window.crosswakeBridge.threadId` as the `_crosswake_thread_id` connect param, absence is an intentional, valid correlation gap — not a failure.
- **D-08:** **No telemetry from `on_mount`** — metadata-only. Phase 91 declares exactly the three `[:crosswake, :threadline, :request, …]` event names; D-08 (one declared event = one emitter) forbids emitting an undeclared mount event. `:halt` is not used (it's for auth-redirect, not applicable).
- **D-09:** Metadata key is `crosswake_thread_id` (parity with the Plug — `Logger.metadata`, NOT `socket.assigns`).

### Zero-dep UUID minting
- **D-10:** Ship a shared `Crosswake.Threadline.Id` module with one public `generate/0` returning a canonical 36-char hyphenated **RFC-4122 v4** string: `:crypto.strong_rand_bytes(16)` → overlay version nibble `4::4` + variant bits `2::2` (the `10` high bits per RFC-4122 §4.1.1) → hex-format 8-4-4-4-12 (~12 LOC; `:crypto` is already used in `companions/chimeway/redaction.ex`).
- **D-11:** **No transitive UUID exists to reuse** — verified against source: `Plug.RequestId`'s generator is private and produces a 20-char base64 (non-UUID) id; `Phoenix.LiveView.UploadConfig.generate_uuid/0` is a `defp` in a module we don't own (unsupported, breaks across point releases). Hand-rolling is the only honest zero-dep path. Satisfies the "mints a UUID fallback" criterion while honoring Phase 91 D-02's opaque-string wire contract (UUID format is additive — the contract imposes no wire-level validation).

### Plug options surface + response-header echo
- **D-12:** **Echo the id immediately** via `Plug.Conn.put_resp_header(conn, header_name, id)` in `call/2` — the id is known synchronously (mirrors `Plug.RequestId`). NOT `register_before_send` (adds ordering risk for a known value; `put_resp_header` replaces deterministically so no clobber/duplicate concern).
- **D-13:** **Minimal public `init/1` option set, validated via `nimble_options`** (already a dep), three keys with defaults:
  - `:header_name` → default `"x-crosswake-thread-id"`
  - `:logger_metadata_key` → default `:crosswake_thread_id`
  - `:telemetry_prefix` → default `[:crosswake, :threadline, :request]`
  - **No `:mint` toggle** (a never-mint plug is a different plug, not a flag); **no `:assign_as`** until a concrete adopter request. This is the only new public API surface introduced by the phase — additive, mirrors `Plug.RequestId`.

### Versioning / release
- **D-14:** Hex release is a **minor** bump (additive new public modules `Crosswake.Plug.Threadline`, `Crosswake.Live.Threadline`, `Crosswake.Threadline.Id`) — `feat:`, no `feat!:`, no `~> 0.1` adopter break. (Researcher/planner to confirm exact version against the v7.0 release posture; Phase 91 shipped the `thread_id` field as a patch.)

### Claude's Discretion
Module/function file layout, exact `@forbidden`/`@metadata` wiring call shape, test file organization, whether `Threadline.Id` exposes anything beyond `generate/0`, and the precise `nimble_options` schema literal — left to research/planning. The decisive recommendations above are the locked spine.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase 91 contract this phase consumes (MOST important)
- `.planning/phases/91-identity-telemetry-contract/91-CONTEXT.md` — locked upstream decisions: `source ∈ {:inbound, :minted}` semantics (D-09/D-10), event-name scope (D-07/D-08), the telemetry module shape, and the opaque-string `thread_id` wire contract (D-02). **Read before anything else.**
- `lib/crosswake/threadline/telemetry.ex` — the Phase 91 `Crosswake.Threadline.Telemetry` allowlist guard (`@event_names`, `@metadata_keys [:thread_id, :correlation_id, :route_id, :source]`, `@forbidden_metadata_keys`, `safe_value?/1`, `metadata/1`, `execute/3`, `valid_event_name?/1`). The Plug emits exclusively through this. *(Confirm exact path during research — created in Phase 91.)*

### Pattern to mirror (in-repo + framework)
- `lib/crosswake/compatibility/route_gate.ex` (~lines 124, 152) and `lib/crosswake/doctor/doctor.ex` (~line 571) — existing `:telemetry.span/3` usage. Note: these wrap **bounded synchronous** calls; the Plug deliberately does NOT follow this for the full-request span (D-01/D-02).
- `Plug.Telemetry` (dep source) — the canonical `:start` + `register_before_send` → `:stop` request-lifecycle pattern the Plug mirrors.
- `Plug.RequestId` (dep source) — precedent for `put_resp_header` in `call/2` (D-12) and the minimal `:http_header` / `:logger_metadata_key` option surface (D-13).
- `lib/crosswake/companions/chimeway/redaction.ex` (~line 56) — existing `:crypto` + `Base.encode16` usage; precedent for the hand-rolled `Threadline.Id` (D-10).

### Requirements & north star
- `.planning/REQUIREMENTS.md` §PROP — PROP-01 (Plug: read/mint/metadata/echo/span) and PROP-03 (LiveView `on_mount` connect-param read) are this phase's requirements.
- `.planning/ROADMAP.md` §"Phase 92" — goal + 4 success criteria (the acceptance bar).
- `.planning/threads/threadline-audit.md` — canonical Threadline definition (its "rich spans at every boundary" framing is aspirational, NOT v7.0 scope — see Phase 91 D-08).
- `.planning/research/SUMMARY.md` — v7.0 north star; "What Threadline is NOT" anti-scope (not APM, not OTel, not a logging framework).
- `prompts/crosswake-elixir-oss-dna.md` — maintainer OSS house style (install/claim honesty, narrow scope; underpins the honest `:exception` scoping in D-03 and the no-undeclared-events rule in D-08).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`Crosswake.Threadline.Telemetry`** (Phase 91): the Plug's only telemetry emission path — `execute/3` applies the allowlist + forbidden-key guard, satisfying success criterion 4 for free.
- **`nimble_options ~> 1.1`** (existing dep): the project idiom for validating public option keywords — use for the Plug's `init/1` schema (D-13).
- **`:crypto`** (already used in `redaction.ex`): backing for `Threadline.Id.generate/0` — zero new deps.

### Established Patterns
- **Telemetry contract = published allowlist**: proof tests assert the exact `@event_names` / `@metadata_keys` lists (cf. Sigra/Phase-91 closeout). The Plug must emit only the three declared names.
- **Narrow-scope honesty**: no undeclared telemetry events (D-08), no over-claimed `:exception` coverage (D-03), no config knobs nobody asked for (D-13).
- **`:telemetry.span/3` in-repo** is for bounded synchronous calls only — explicitly the wrong tool for the full-request span (D-01/D-02).

### Integration Points
- **First HTTP Plug and first `Logger.metadata` call in the codebase** — no prior plug/`register_before_send`/`Logger.metadata` usage to extend; greenfield modules under `Crosswake.Plug.*` / `Crosswake.Live.*` / `Crosswake.Threadline.*`.
- thread_id flow: native shell / inbound header (Phase 93) → **`Plug.Threadline` mints-or-reads + sets `Logger.metadata` + emits the request span (THIS phase)** → bridge/activation envelopes carry it (Phase 91 field) → audit ledger records it (Phase 94) → operator surface reads it (Phase 95).
- The Plug serves the HTTP path; `on_mount` serves the separate LiveView WebSocket path. The **two-channel split** (HTTP header on initial load vs connect param for the WebSocket) is the design Phase 93 native injection mirrors.

</code_context>

<specifics>
## Specific Ideas

- `source` operator microcopy (reuse from Phase 91 for the eventual guide/doctor text): "`source` — `:inbound` if the thread_id arrived on the `X-Crosswake-Thread-Id` header (journey continuing); `:minted` if the Plug generated a fresh UUID because no header was present (journey starts here)."
- `Threadline.Id.generate/0` concrete recipe: `:crypto.strong_rand_bytes(16)`, overlay `<<u0::48, 4::4, u1::12, 2::2, u2::62>>`, hex-format to canonical 8-4-4-4-12.
- Document the `:exception`-scope boundary (own-plug-only, not downstream) inline at the `try/rescue` site and in the Phase 96 guide so the event is not over-claimed.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope. No scope creep surfaced; no pending todos matched this phase (`todo.match-phase 92` → 0 matches).

</deferred>

---

*Phase: 92-server-propagation-plug-liveview*
*Context gathered: 2026-06-09*
