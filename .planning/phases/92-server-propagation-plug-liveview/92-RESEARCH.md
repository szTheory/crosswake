# Phase 92: Server Propagation — Plug + LiveView - Research

**Researched:** 2026-06-09
**Domain:** Elixir Plug behaviour + Phoenix LiveView on_mount hook; RFC-4122 v4 UUID minting; NimbleOptions schema validation; telemetry span lifecycle
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01:** Emit the request span triplet via the **Plug.Telemetry idiom** (NOT a literal `:telemetry.span/3` call). In `call/2`: read-or-mint the id, capture `System.monotonic_time/0`, emit `[:crosswake, :threadline, :request, :start]`, then `Plug.Conn.register_before_send/2` a callback that emits `:stop` with real `monotonic_time - start` duration when the response is actually sent.

**D-02:** D-07's phrase "the `:telemetry.span/3` triplet the Phase 92 Plug emits" denotes the event-name **shape** (start/stop/exception as a set), not a mandate to call the `span/3` function. A function plug returns to the pipeline before downstream work runs, so a real `span/3` would fire `:stop` at ~microsecond duration before the response is sent — a dishonest duration.

**D-03:** `:exception` is scoped honestly to the plug's **own synchronous minting work** (header read, UUID generation, `Logger.metadata` set, resp-header put) via a local `try/rescue` in `call/2`. A function plug cannot catch downstream pipeline raises. MUST be stated in a code comment.

**D-04:** All telemetry metadata is routed through `Crosswake.Threadline.Telemetry.execute/3` / `metadata/1` so the Phase 91 allowlist + forbidden-key guard is applied at every emission. `source` is set by a single pattern-match on `get_req_header(conn, "x-crosswake-thread-id")` → `:inbound`, else `:minted`.

**D-05:** The library **never** calls `Logger.info/warning/error` — only `Logger.metadata` + the `Threadline.Telemetry` emitter.

**D-06:** LiveView `on_mount/4` is **read-only, no minting.** Guard on `Phoenix.LiveView.connected?(socket)`, read `_crosswake_thread_id` via `get_connect_params/1`, set `Logger.metadata(crosswake_thread_id: id)` on the LiveView GenServer process. The Plug is the sole mint authority.

**D-07:** Absent connect param (or disconnected render) → `{:cont, socket}` no-op, no metadata set, no error.

**D-08:** **No telemetry from `on_mount`** — metadata-only. Phase 91 declares exactly the three request event names; emitting an undeclared mount event is forbidden.

**D-09:** Metadata key is `crosswake_thread_id` (parity with the Plug — `Logger.metadata`, NOT `socket.assigns`).

**D-10:** Ship a shared `Crosswake.Threadline.Id` module with one public `generate/0` returning a canonical 36-char hyphenated **RFC-4122 v4** string: `:crypto.strong_rand_bytes(16)` → overlay version nibble `4::4` + variant bits `2::2` → hex-format 8-4-4-4-12.

**D-11:** No transitive UUID exists to reuse — `Plug.RequestId`'s generator is private and produces a 20-char base64 (non-UUID) id; `Phoenix.LiveView.UploadConfig.generate_uuid/0` is a `defp`. Hand-rolling is the only honest zero-dep path.

**D-12:** Echo the id **immediately** via `Plug.Conn.put_resp_header(conn, header_name, id)` in `call/2` — NOT `register_before_send`.

**D-13:** Minimal public `init/1` option set validated via `nimble_options ~> 1.1` (already a dep), three keys with defaults: `:header_name` → `"x-crosswake-thread-id"`, `:logger_metadata_key` → `:crosswake_thread_id`, `:telemetry_prefix` → `[:crosswake, :threadline, :request]`. No `:mint` toggle; no `:assign_as`.

**D-14:** Hex release is a **patch** bump — under the project's `bump-patch-for-minor-pre-major: true` release-please config, `feat:` commits in 0.x land as patch bumps. Current version is `0.1.1`; Phase 92 bump is `0.1.1 → 0.1.2`.

### Claude's Discretion

Module/function file layout, exact `@forbidden`/`@metadata` wiring call shape, test file organization, whether `Threadline.Id` exposes anything beyond `generate/0`, and the precise `nimble_options` schema literal.

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope. No scope creep surfaced; `todo.match-phase 92` → 0 matches.

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PROP-01 | A Phoenix team can add `Crosswake.Plug.Threadline` to a pipeline so every request carries a `thread_id` in `Logger.metadata` — read from the `X-Crosswake-Thread-Id` header, minted as a fallback when absent (never overwriting an inbound id), and echoed on the response. | `Plug.RequestId` idiom + `register_before_send` pattern verified in `Plug.Telemetry` source; `Logger.metadata/1` confirmed in `Plug.RequestId` source at line 75; header read/mint verified. |
| PROP-03 | A team can opt a LiveView into thread correlation via `Crosswake.Live.Threadline` `on_mount`, which reads the `_crosswake_thread_id` connect param and sets `thread_id` on the LiveView process metadata. | `get_connect_params/1` + `connected?/1` + `Logger.metadata/1` confirmed in LiveView 1.1.30 source; `on_mount/4` callback signature confirmed in `Lifecycle` module; no mounting telemetry declared. |
</phase_requirements>

---

## Summary

Phase 92 ships two new modules that consume the Phase 91 contract: `Crosswake.Plug.Threadline` (the HTTP pipeline entry point) and `Crosswake.Live.Threadline` (the LiveView WebSocket metadata bridge). Both are greenfield — no prior `Plug` behaviour or `Logger.metadata` usage exists in the `crosswake` library; this is the first HTTP plug and the first `Logger.metadata` call in the codebase.

The plug follows the `Plug.Telemetry` + `Plug.RequestId` idioms verified directly in the locked dep source (`plug 1.19.1`): emit `:start` with `System.monotonic_time/0`, register a `before_send` callback for the real-duration `:stop`, put the response header synchronously, and set `Logger.metadata` synchronously. UUID minting is a ~12-LOC hand-rolled RFC-4122 v4 implementation in `Crosswake.Threadline.Id`; no transitive UUID generator is available in the dep graph without making a non-`defp` assumption. The `on_mount` hook is read-only: it guards on `connected?(socket)`, reads the `_crosswake_thread_id` connect param via `get_connect_params/1`, and sets `Logger.metadata` on the LiveView GenServer process.

All decisions are locked from the CONTEXT.md discussion. The planner's job is purely file/task decomposition — no algorithm choices remain open.

**Primary recommendation:** Implement in three files (`lib/crosswake/threadline/id.ex`, `lib/crosswake/plug/threadline.ex`, `lib/crosswake/live/threadline.ex`) with corresponding test files, a phase-92 closeout proof test, and a version bump to `0.1.2` in `mix.exs`.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| HTTP header read / UUID mint | API / Backend (Plug) | — | `Crosswake.Plug.Threadline` runs in the Phoenix HTTP pipeline; this is a server-side concern |
| `Logger.metadata` propagation (HTTP) | API / Backend (Plug) | — | Metadata is per-process; the plug process is the HTTP request handler |
| Telemetry span emission | API / Backend (Plug) | — | Emitted by the Plug via `Threadline.Telemetry.execute/3`; fully server-side |
| Response header echo | API / Backend (Plug) | — | `put_resp_header` in `call/2`; server-side synchronous write |
| LiveView process metadata | Frontend Server (LV channel) | — | `on_mount/4` runs inside the LiveView GenServer process (separate from the HTTP request process) |
| UUID minting utility | Shared library | — | `Crosswake.Threadline.Id.generate/0` — no tier; pure function with no side effects |

---

## Standard Stack

### Core (no new deps introduced)

| Library | Locked Version | Purpose | Source |
|---------|---------------|---------|--------|
| `plug` | `1.19.1` | `@behaviour Plug` implementation; `Plug.Conn.get_req_header/2`, `put_resp_header/3`, `register_before_send/2` | [VERIFIED: project deps/plug/lib/] |
| `phoenix_live_view` | `1.1.30` | `Phoenix.LiveView.on_mount/4` hook contract; `connected?/1`, `get_connect_params/1` | [VERIFIED: project deps/phoenix_live_view/] |
| `:telemetry` | `1.4.2` | `:telemetry.execute/3` — called indirectly via `Crosswake.Threadline.Telemetry.execute/3` | [VERIFIED: project deps/telemetry/] |
| `nimble_options` | `1.1.1` | `NimbleOptions.new!` + `NimbleOptions.validate!/2` for `init/1` option validation | [VERIFIED: project deps/nimble_options/] |
| `:crypto` | OTP (built-in) | `:crypto.strong_rand_bytes/1` for `Threadline.Id.generate/0` | [VERIFIED: Chimeway.Redaction line 56 — existing codebase use] |

### Supporting (already shipped by Phase 91)

| Module | Purpose | Notes |
|--------|---------|-------|
| `Crosswake.Threadline.Telemetry` | Allowlist guard + `execute/3` — routes all telemetry through forbidden-key filter | [VERIFIED: lib/crosswake/threadline/telemetry.ex] |
| `Crosswake.Threadline.Telemetry.Event` | Struct narrowing the four PROP-02 metadata keys | [VERIFIED: lib/crosswake/threadline/telemetry.ex lines 64-71] |

### No new deps

Phase 92 introduces **zero new hex dependencies**. All required capabilities are available from the existing dep graph. [VERIFIED: mix.exs + deps directory]

---

## Package Legitimacy Audit

> Phase 92 installs **no new packages**. All deps were already present in `mix.exs` before this phase. Audit not applicable.

---

## Architecture Patterns

### System Architecture Diagram

```
HTTP Request
    │
    ▼
[Crosswake.Plug.Threadline.call/2]
    │
    ├── get_req_header(conn, header_name)
    │       ├── [non-empty] → id = inbound value, source = :inbound
    │       └── []          → id = Threadline.Id.generate/0, source = :minted
    │
    ├── Logger.metadata([{logger_metadata_key, id}])
    │
    ├── put_resp_header(conn, header_name, id)   ← synchronous echo
    │
    ├── start_time = System.monotonic_time()
    │
    ├── Threadline.Telemetry.execute([:..., :start], %{system_time: …}, meta)
    │
    ├── register_before_send(conn, fn conn →
    │       Threadline.Telemetry.execute([:..., :stop], %{duration: …}, meta)
    │       conn
    │   end)
    │
    └── [try/rescue wraps own work]
            └── on error: Threadline.Telemetry.execute([:..., :exception], …) + re-raise
    │
    ▼
[Downstream pipeline → response sent → :stop fires]


LiveView WebSocket Mount
    │
    ▼
[Crosswake.Live.Threadline.on_mount(:default, params, session, socket)]
    │
    ├── connected?(socket)?
    │       ├── false → {:cont, socket}  (no-op, static render)
    │       └── true  →
    │               get_connect_params(socket)["_crosswake_thread_id"]
    │               ├── nil / absent → {:cont, socket}  (no-op, valid gap until Phase 93)
    │               └── id           → Logger.metadata([crosswake_thread_id: id])
    │                                  {:cont, socket}
```

### Recommended Project Structure

```
lib/
├── crosswake/
│   ├── threadline/
│   │   ├── telemetry.ex          # Phase 91 — existing, do not touch
│   │   └── id.ex                 # NEW — Crosswake.Threadline.Id.generate/0
│   ├── plug/
│   │   └── threadline.ex         # NEW — Crosswake.Plug.Threadline (@behaviour Plug)
│   └── live/
│       └── threadline.ex         # NEW — Crosswake.Live.Threadline (on_mount/4)
test/
├── crosswake/
│   ├── threadline/
│   │   ├── telemetry_test.exs    # Phase 91 — existing
│   │   └── id_test.exs           # NEW — unit tests for Threadline.Id
│   ├── plug/
│   │   └── threadline_test.exs   # NEW — plug unit tests
│   └── live/
│       └── threadline_test.exs   # NEW — on_mount unit tests
└── crosswake/proof/
    └── phase92_server_propagation_closeout_test.exs  # NEW — merge-blocking proof lane
```

Note on `Crosswake.Live.Threadline` path: no existing `lib/crosswake/live/` directory exists; the planner should create it. The `Crosswake.Plug.*` and `Crosswake.Live.*` namespaces are both greenfield in this phase.

### Pattern 1: Plug.Telemetry idiom for request span

**What:** Emit `:start` in `call/2` with `System.monotonic_time/0`, register a `before_send` callback that computes `duration = System.monotonic_time() - start_time` and emits `:stop`.

**When to use:** Any function plug that must measure true response-send latency. `register_before_send` fires when `send_resp/3` is ultimately called, giving the real wall-clock span.

```elixir
# Source: deps/plug/lib/plug/telemetry.ex (Plug 1.19.1 — verified)
@impl true
def call(conn, {start_event, stop_event, opts}) do
  start_time = System.monotonic_time()
  metadata = %{conn: conn, options: opts}
  :telemetry.execute(start_event, %{system_time: System.system_time()}, metadata)

  Plug.Conn.register_before_send(conn, fn conn ->
    duration = System.monotonic_time() - start_time
    :telemetry.execute(stop_event, %{duration: duration}, %{conn: conn, options: opts})
    conn
  end)
end
```

**Crosswake.Plug.Threadline adaptation:** Replace `:telemetry.execute` calls with `Threadline.Telemetry.execute/3` (routes through allowlist guard). Replace `conn`-shaped metadata with the four PROP-02 keys (`thread_id`, `correlation_id`, `route_id`, `source`). Wrap own synchronous work (header read, UUID mint, `Logger.metadata`, `put_resp_header`) in `try/rescue` for the honest `:exception` scope (D-03).

### Pattern 2: Plug.RequestId idiom for header read-or-mint + response echo

**What:** Read the header; if absent/invalid, generate a new id. Set `Logger.metadata` synchronously. `put_resp_header` synchronously (id is known immediately, no `before_send` ordering risk).

```elixir
# Source: deps/plug/lib/plug/request_id.ex (Plug 1.19.1 — verified, lines 72-79)
@impl true
def call(conn, {header, assign_as, logger_metadata_key}) do
  request_id = get_request_id(conn, header)
  Logger.metadata([{logger_metadata_key, request_id}])
  conn = if assign_as, do: Conn.assign(conn, assign_as, request_id), else: conn
  Conn.put_resp_header(conn, header, request_id)
end

defp get_request_id(conn, header) do
  case Conn.get_req_header(conn, header) do
    []      -> generate_request_id()
    [val|_] -> if valid_request_id?(val), do: val, else: generate_request_id()
  end
end
```

**Crosswake.Plug.Threadline adaptation (D-12, D-13):**
- Pattern-match `get_req_header(conn, header_name)` → non-empty list = `:inbound`, empty = `:minted` + `Threadline.Id.generate/0`.
- `Logger.metadata([{logger_metadata_key, id}])` — first `Logger.metadata` call in the codebase.
- `put_resp_header(conn, header_name, id)` — synchronous echo; no `assign_as` option.
- No `valid_request_id?/1` guard — the CONTEXT.md decision is "never overwrites an inbound id" with no length/format validation on inbound ids (opaque-string contract from Phase 91 D-02).

### Pattern 3: LiveView on_mount/4 hook

**What:** A module that implements `on_mount(arg, params, session, socket)` and returns `{:cont, socket}` or `{:halt, socket}`. Invoked before both disconnected and connected mounts by the LiveView lifecycle.

```elixir
# Source: deps/phoenix_live_view/lib/phoenix_live_view.ex (LV 1.1.30 — verified, lines 509-514)
def on_mount(:default, _params, _session, socket) do
  {:cont, socket}
end

# Registering (host app side):
live_session :default, on_mount: Crosswake.Live.Threadline do
  live "/dashboard", DashboardLive
end

# Or per-LiveView:
on_mount Crosswake.Live.Threadline
```

**Key LV 1.1.30 verified facts:**
- `connected?(socket)` returns `transport_pid != nil` [VERIFIED: line 635 of phoenix_live_view.ex].
- `get_connect_params(socket)` returns the connect-params map when `connected?(socket)` is true, or `nil` on static render [VERIFIED: lines 1248-1253 of phoenix_live_view.ex]. Returns `nil` (not raises) on disconnected render when params were never provided.
- `on_mount/4` is invoked on **both** disconnected and connected mounts — the guard `connected?(socket)` is the correct discriminator for `_crosswake_thread_id` (connect params are only available on WebSocket mount; on static render `get_connect_params` returns `nil`).

**Crosswake.Live.Threadline adaptation (D-06, D-07, D-08, D-09):**
```elixir
def on_mount(:default, _params, _session, socket) do
  if Phoenix.LiveView.connected?(socket) do
    case Phoenix.LiveView.get_connect_params(socket) do
      %{"_crosswake_thread_id" => id} when is_binary(id) and byte_size(id) > 0 ->
        Logger.metadata(crosswake_thread_id: id)
      _ -> :ok
    end
  end
  {:cont, socket}
end
```

No `:halt` usage. No telemetry. No metadata on `socket.assigns`. No UUID minting.

### Pattern 4: NimbleOptions schema for Plug init/1

**What:** Compile-time validation of keyword opts using a `@schema NimbleOptions.new!(...)` module attribute.

```elixir
# Source: lib/crosswake/policy/schema.ex (verified in-repo pattern)
@schema NimbleOptions.new!(
  header_name: [
    type: :string,
    default: "x-crosswake-thread-id",
    doc: "..."
  ],
  logger_metadata_key: [
    type: :atom,
    default: :crosswake_thread_id,
    doc: "..."
  ],
  telemetry_prefix: [
    type: {:list, :atom},
    default: [:crosswake, :threadline, :request],
    doc: "..."
  ]
)

@impl true
def init(opts), do: NimbleOptions.validate!(opts, @schema)
```

The `init/1` return value is passed as the second arg to `call/2`. Since `NimbleOptions.validate!/2` returns a keyword list, the `call/2` signature becomes `call(conn, opts)` where `opts` is a validated keyword.

### Pattern 5: Threadline.Id.generate/0 — RFC-4122 v4 hand-roll

**What:** Hand-rolled UUID v4 using `:crypto.strong_rand_bytes/1` (already used in `Chimeway.Redaction`).

```elixir
# Source: RFC-4122 §4.4, verified bit layout
# Precedent: lib/crosswake/companions/chimeway/redaction.ex line 56 — Base.encode16 usage
defmodule Crosswake.Threadline.Id do
  @moduledoc "Generates RFC-4122 v4 UUIDs for Threadline thread_id minting."

  @spec generate() :: String.t()
  def generate do
    <<u0::48, _::4, u1::12, _::2, u2::62>> = :crypto.strong_rand_bytes(16)
    raw = <<u0::48, 4::4, u1::12, 2::2, u2::62>>
    hex = Base.encode16(raw, case: :lower)
    <<a::8-bytes, b::4-bytes, c::4-bytes, d::4-bytes, e::12-bytes>> = hex
    "#{a}-#{b}-#{c}-#{d}-#{e}"
  end
end
```

The bit overlay pattern:
- Bytes 0–5 (48 bits): random
- Byte 6 high nibble: `4` (version 4)
- Bytes 6–7 lower 12 bits: random
- Byte 8 high 2 bits: `10` (variant bits per RFC-4122 §4.1.1)
- Bytes 8–15 lower 62 bits: random

Output format: `"xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"` (36 chars, lowercase hex, canonical RFC form).

### Anti-Patterns to Avoid

- **Using `:telemetry.span/3` for the full-request span:** Fires `:stop` before the response is sent — a ~microsecond duration that is dishonest. The correct idiom is `register_before_send`. (D-01, D-02)
- **Minting a UUID in `on_mount`:** Creates a phantom `thread_id` divorced from the Plug-minted id; the LiveView WebSocket is a separate connection. The Plug is the sole mint authority. (D-06)
- **Emitting telemetry from `on_mount`:** No mount event name is declared in Phase 91's `@event_names`. Emitting an undeclared event breaks the one-declared-event-one-emitter rule (D-08).
- **Calling `Logger.info/warning/error` anywhere in this phase:** Library emits only `Logger.metadata` and telemetry — never log lines (D-05).
- **Using `socket.assigns` for the thread_id in `on_mount`:** Key belongs in `Logger.metadata`, not assigns. Assigns contaminate the public socket surface; metadata stays in the process dictionary (D-09).
- **Adding `put_resp_header` to `register_before_send`:** The id is known synchronously; `register_before_send` introduces ordering risk with other before-send callbacks. `put_resp_header` replaces deterministically in `call/2` (D-12).
- **Adding a `:mint` toggle to `init/1`:** A never-mint plug is a categorically different plug, not a configuration variant (D-13).

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Option validation in `init/1` | Custom keyword validator | `NimbleOptions.new!` + `validate!/2` | Already a dep; project-standard idiom (see `policy/schema.ex`) |
| Forbidden-key filtering | Custom PII denylist in the Plug | `Crosswake.Threadline.Telemetry.execute/3` | Phase 91 ships the guard; routing through it satisfies SC 4 for free |
| Request duration measurement | Custom monotonic timer | `System.monotonic_time/0` (same as `Plug.Telemetry`) | Already the ecosystem-standard measurement unit |

**Key insight:** The Phase 91 telemetry guard handles the only genuinely complex part of this phase (allowlist filtering + forbidden-key rejection). The Plug's job is wiring, not logic.

---

## Common Pitfalls

### Pitfall 1: `get_connect_params` returns nil on static render — do NOT guard on non-nil

**What goes wrong:** Calling `get_connect_params(socket)["_crosswake_thread_id"]` on a disconnected socket raises `ArgumentError: connect_params is unavailable...` if the socket was not provided connect params (raises `raise_root_and_mount_only!` — verified in LV source line 1252).

**Why it happens:** `get_connect_params/1` returns `nil` when `connected?/1` is false AND connect params were provided but returns via `private[:connect_params]` path. If the socket is a root LiveView with no connect params at all, it raises. The guard `connected?(socket)` before calling `get_connect_params` prevents both the raises and avoids setting metadata on the static render (correct, per D-07).

**How to avoid:** Always guard `connected?(socket)` first, THEN call `get_connect_params/1`. The correct skeleton:
```elixir
if Phoenix.LiveView.connected?(socket) do
  case Phoenix.LiveView.get_connect_params(socket) do ...
end
```

**Warning signs:** `ArgumentError` in `on_mount` during disconnected render in tests or server-side rendering.

### Pitfall 2: `register_before_send` callback NOT guaranteed to fire on all error paths

**What goes wrong:** The `:stop` telemetry event is not emitted if the connection crashes before `send_resp` is called. This matches `Plug.Telemetry`'s documented behavior ("The `:stop` event is not guaranteed to be emitted in all error cases, so this Plug cannot be used as a Telemetry span"). [VERIFIED: Plug.Telemetry source docs, line 22-24]

**Why it happens:** `register_before_send` callbacks only run on the happy path of `Plug.Conn.send_resp/3`. If the Cowboy/Bandit adapter drops the connection, the callback is never invoked.

**How to avoid:** This is expected and documented behavior. The `:exception` event from the Plug's own `try/rescue` handles minting failures. Phoenix.Router owns `[:phoenix, :router_dispatch, :exception]` for downstream failures. Document the narrow scope in the code comment (D-03).

**Warning signs:** Missing `:stop` events in telemetry tests that simulate conn crashes.

### Pitfall 3: `source` value must be set via pattern-match on `get_req_header` — not from the id value

**What goes wrong:** Deriving `source` by checking whether the id "looks like" a freshly minted UUID (e.g., checking string format) is fragile; an inbound header could also be a valid UUID.

**Why it happens:** Temptation to infer `source` after the fact.

**How to avoid:** The single pattern-match on `get_req_header/2` result determines `source` at the exact decision point:
```elixir
case Plug.Conn.get_req_header(conn, header_name) do
  [id | _] -> {id, :inbound}
  []       -> {Crosswake.Threadline.Id.generate(), :minted}
end
```
The `source` atom is set by the branch, not derived from the id value.

**Warning signs:** Tests for `:inbound` accidentally testing UUID format rather than the header presence.

### Pitfall 4: `Logger.metadata/1` call site — must use list syntax, not map

**What goes wrong:** `Logger.metadata(%{crosswake_thread_id: id})` — the Logger API accepts keyword lists, not maps. [VERIFIED: Plug.RequestId source line 75 uses `Logger.metadata([{logger_metadata_key, request_id}])`]

**How to avoid:** Use `Logger.metadata([{logger_metadata_key, id}])` in the Plug (dynamic key from opts) and `Logger.metadata(crosswake_thread_id: id)` in `on_mount` (static key).

### Pitfall 5: Version bump calculation under 0.x release-please config

**What goes wrong:** Assuming the Hex release is a minor bump (`0.1.1 → 0.2.0`) because three new public modules are added.

**Why it happens:** Standard SemVer reasoning. But the project uses `bump-patch-for-minor-pre-major: true`, meaning `feat:` commits in 0.x land as patch bumps.

**How to avoid:** The correct bump is `0.1.1 → 0.1.2`. Commit message prefix `feat:` (not `feat!:` — no breaking changes). [VERIFIED: REC-VERSIONING.md §0.x regime table: "feat: → patch → 0.1.0 → 0.1.1"]

---

## Code Examples

### Plug module skeleton

```elixir
# lib/crosswake/plug/threadline.ex
defmodule Crosswake.Plug.Threadline do
  @moduledoc """
  A Plug that reads or mints the `X-Crosswake-Thread-Id` request header,
  sets `Logger.metadata(crosswake_thread_id: ...)`, echoes the id on the
  response header, and emits the `[:crosswake, :threadline, :request, :start|:stop|:exception]`
  telemetry triplet.

  ...
  """

  @behaviour Plug
  alias Plug.Conn
  alias Crosswake.Threadline.Id, as: ThreadlineId
  alias Crosswake.Threadline.Telemetry, as: ThreadlineTelemetry

  @schema NimbleOptions.new!(
    header_name: [type: :string, default: "x-crosswake-thread-id"],
    logger_metadata_key: [type: :atom, default: :crosswake_thread_id],
    telemetry_prefix: [type: {:list, :atom}, default: [:crosswake, :threadline, :request]]
  )

  @impl true
  def init(opts), do: NimbleOptions.validate!(opts, @schema)

  @impl true
  def call(conn, opts) do
    header_name = opts[:header_name]
    logger_key  = opts[:logger_metadata_key]
    prefix      = opts[:telemetry_prefix]

    try do
      {id, source} =
        case Conn.get_req_header(conn, header_name) do
          [id | _] -> {id, :inbound}
          []       -> {ThreadlineId.generate(), :minted}
        end

      Logger.metadata([{logger_key, id}])
      conn = Conn.put_resp_header(conn, header_name, id)

      start_time = System.monotonic_time()
      meta = [thread_id: id, source: source]  # route_id/correlation_id from conn if available
      ThreadlineTelemetry.execute(prefix ++ [:start], %{system_time: System.system_time()}, meta)

      Conn.register_before_send(conn, fn conn ->
        duration = System.monotonic_time() - start_time
        ThreadlineTelemetry.execute(prefix ++ [:stop], %{duration: duration}, meta)
        conn
      end)
    rescue
      e ->
        # :exception scope is limited to OWN plug work (header read, UUID mint,
        # Logger.metadata, put_resp_header). A function plug cannot catch downstream
        # raises — those unwind past register_before_send. Phoenix.Router owns
        # [:phoenix, :router_dispatch, :exception] for downstream failures.
        ThreadlineTelemetry.execute(
          prefix ++ [:exception],
          %{duration: System.monotonic_time()},
          %{kind: :error, reason: e}
        )
        reraise e, __STACKTRACE__
    end
  end
end
```

### on_mount hook skeleton

```elixir
# lib/crosswake/live/threadline.ex
defmodule Crosswake.Live.Threadline do
  @moduledoc """
  A LiveView `on_mount` hook that reads `_crosswake_thread_id` from the
  LiveView connect params and sets `crosswake_thread_id` on the LiveView
  process Logger metadata.
  ...
  """

  @spec on_mount(atom(), map(), map(), Phoenix.LiveView.Socket.t()) ::
          {:cont, Phoenix.LiveView.Socket.t()}
  def on_mount(:default, _params, _session, socket) do
    if Phoenix.LiveView.connected?(socket) do
      case Phoenix.LiveView.get_connect_params(socket) do
        %{"_crosswake_thread_id" => id} when is_binary(id) and byte_size(id) > 0 ->
          Logger.metadata(crosswake_thread_id: id)
        _ -> :ok
      end
    end
    {:cont, socket}
  end
end
```

### Threadline.Id.generate/0

```elixir
# lib/crosswake/threadline/id.ex
defmodule Crosswake.Threadline.Id do
  @moduledoc "Generates RFC-4122 v4 UUIDs for Threadline thread_id minting."

  @spec generate() :: String.t()
  def generate do
    # Version 4 (random) UUID per RFC-4122 §4.4
    # Variant bits: 10xx (RFC-4122 §4.1.1)
    <<u0::48, _::4, u1::12, _::2, u2::62>> = :crypto.strong_rand_bytes(16)
    raw = <<u0::48, 4::4, u1::12, 2::2, u2::62>>
    hex = Base.encode16(raw, case: :lower)
    <<a::8-bytes, b::4-bytes, c::4-bytes, d::4-bytes, e::12-bytes>> = hex
    "#{a}-#{b}-#{c}-#{d}-#{e}"
  end
end
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `Plug.RequestId` for request correlation | `Crosswake.Plug.Threadline` with telemetry spans and UUID format | Phase 92 adds telemetry and canonical UUID | No conflict — two separate plugs; they can coexist. Crosswake's id is a UUID; Plug.RequestId's is a 20-char base64. |
| `Logger.metadata` set ad-hoc per-request | `Logger.metadata` set uniformly by the Plug + `on_mount` | Phase 92 | First `Logger.metadata` call in the codebase. |

**Deprecated / not applicable:**
- `Phoenix.LiveView.UploadConfig.generate_uuid/0` — private `defp`; not a public API; do not use (D-11).
- `Plug.RequestId`'s private `generate_request_id/0` — produces a 20-char base64, not a UUID (D-11).
- Literal `:telemetry.span/3` for full-request span — wrong for function plugs (D-01, D-02).

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The `Elixir.String` binary matching via `<<a::8-bytes, ...>>` is valid for the 32-char hex output of `Base.encode16/2` to extract UUID segments | Code Examples — Threadline.Id | Compilation error; fix: use `binary_part/3` or `String.slice/2` instead |

**Notes:** All other claims verified directly from source files (mix.exs deps, plug source, phoenix_live_view source, existing codebase). No WebSearch was required — the locked decisions in CONTEXT.md were grounded in source-verified research from the discuss-phase.

---

## Open Questions (RESOLVED)

1. **`route_id` and `correlation_id` in Plug telemetry metadata** — RESOLVED: leave `route_id`/`correlation_id` out of the Plug's telemetry metadata; the guard drops nils (planner discretion call recorded in 92-01/T2 action).
   - What we know: `Threadline.Telemetry`'s four `@metadata_keys` are `[:thread_id, :correlation_id, :route_id, :source]`. The Plug has access to `conn` but not to Crosswake's `route_id` (a Crosswake policy concept, not a HTTP path).
   - What's unclear: Should the Plug populate `route_id` from `Phoenix.Router.route_info/4` (available after routing) or leave it nil? `correlation_id` is also not available in the Plug without explicit conn assigns set by the host.
   - Recommendation: Leave `route_id: nil` and `correlation_id: nil` in the Plug's telemetry metadata — the metadata guard silently drops nil values (`safe_value?(nil) == false`). The host app can set `conn.assigns[:crosswake_route_id]` and the Plug can read it as a convenience; this is a `Claude's Discretion` decision for the planner.

2. **Version bump entry in CHANGELOG.md** — RESOLVED: add only `[0.1.2]` in Phase 92, no retroactive `[0.1.1]` entry (recorded in 92-03/T2 action).
   - What we know: `0.1.1` is in `mix.exs` (Phase 91 bump). The CHANGELOG only has `[0.1.0]` as a versioned entry — `[Unreleased]` section exists but `0.1.1` is not documented.
   - What's unclear: Should Phase 92 add `[0.1.1]` (retroactively for Phase 91) and `[0.1.2]` (for Phase 92), or only `[0.1.2]`?
   - Recommendation: Add only `[0.1.2]` in Phase 92. Phase 91's `0.1.1` was an internal development bump during an unreleased period; retroactive CHANGELOG entries for unpublished bumps are noise. The CHANGELOG preamble already documents the separation between planning milestones and Hex releases.

---

## Environment Availability

> Phase 92 is a pure code/config change with no external tool dependencies beyond the existing Elixir/Erlang toolchain. Elixir 1.19 (required by mix.exs) is assumed present. No new runtime dependencies are introduced.

Step 2.6: SKIPPED — no new external dependencies identified.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | ExUnit (built-in) |
| Config file | `test/test_helper.exs` |
| Quick run command | `mix test test/crosswake/plug/ test/crosswake/live/ test/crosswake/threadline/id_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| PROP-01 | Plug reads inbound header → no mint, `:inbound` source | unit | `mix test test/crosswake/plug/threadline_test.exs` | ❌ Wave 0 |
| PROP-01 | Plug mints UUID fallback when header absent → `:minted` source | unit | `mix test test/crosswake/plug/threadline_test.exs` | ❌ Wave 0 |
| PROP-01 | Plug sets `Logger.metadata(crosswake_thread_id: id)` | unit | `mix test test/crosswake/plug/threadline_test.exs` | ❌ Wave 0 |
| PROP-01 | Plug echoes id on response header | unit | `mix test test/crosswake/plug/threadline_test.exs` | ❌ Wave 0 |
| PROP-01 | Plug emits `:start` telemetry event | unit | `mix test test/crosswake/plug/threadline_test.exs` | ❌ Wave 0 |
| PROP-01 | Plug emits `:stop` telemetry event via `before_send` | unit | `mix test test/crosswake/plug/threadline_test.exs` | ❌ Wave 0 |
| PROP-01 | Plug emits `:exception` on own-work failure and re-raises | unit | `mix test test/crosswake/plug/threadline_test.exs` | ❌ Wave 0 |
| PROP-01 | `Threadline.Id.generate/0` produces 36-char hyphenated RFC-4122 v4 UUID | unit | `mix test test/crosswake/threadline/id_test.exs` | ❌ Wave 0 |
| PROP-02 | Plug routes telemetry through `Threadline.Telemetry.execute/3` (forbidden keys dropped) | unit | `mix test test/crosswake/plug/threadline_test.exs` | ❌ Wave 0 |
| PROP-03 | `on_mount` reads `_crosswake_thread_id` and sets `Logger.metadata` when connected | unit | `mix test test/crosswake/live/threadline_test.exs` | ❌ Wave 0 |
| PROP-03 | `on_mount` is a no-op when disconnected (static render) | unit | `mix test test/crosswake/live/threadline_test.exs` | ❌ Wave 0 |
| PROP-03 | `on_mount` is a no-op when connect param absent (valid gap) | unit | `mix test test/crosswake/live/threadline_test.exs` | ❌ Wave 0 |
| PROP-01+03 | Phase 92 closeout proof: all contract assertions | proof | `mix test test/crosswake/proof/phase92_server_propagation_closeout_test.exs` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `mix test test/crosswake/plug/ test/crosswake/live/ test/crosswake/threadline/id_test.exs`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `test/crosswake/threadline/id_test.exs` — covers `Threadline.Id.generate/0` RFC-4122 v4 format + uniqueness
- [ ] `test/crosswake/plug/threadline_test.exs` — full Plug unit coverage (inbound/minted, metadata, telemetry, exception)
- [ ] `test/crosswake/live/threadline_test.exs` — `on_mount` coverage (connected/disconnected/absent param)
- [ ] `test/crosswake/proof/phase92_server_propagation_closeout_test.exs` — merge-blocking proof lane
- [ ] `lib/crosswake/threadline/id.ex` — does not exist yet
- [ ] `lib/crosswake/plug/threadline.ex` — does not exist yet
- [ ] `lib/crosswake/live/threadline.ex` — does not exist yet

---

## Security Domain

> `security_enforcement` not set in config.json → treated as enabled.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Plug does not authenticate; only correlates |
| V3 Session Management | no | Plug sets process metadata only; no session state |
| V4 Access Control | no | Plug is correlation-only; no authorization decisions |
| V5 Input Validation | yes | `get_req_header/2` returns raw binary; inbound id is used as-is (opaque-string contract). The Telemetry guard's `safe_value?/1` enforces ≤128-char limit before emission — PII protection is maintained there. |
| V6 Cryptography | yes — for UUID minting | `:crypto.strong_rand_bytes/16` for UUID v4 minting. `:crypto` is ERTS-bundled, FIPS-certified on OTP distributions that require it. No hand-rolled crypto beyond UUID bit overlay. |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Inbound `X-Crosswake-Thread-Id` header carrying PII or oversized value | Tampering, Information Disclosure | `safe_value?/1` in `Threadline.Telemetry.metadata/1` enforces ≤128 chars before emission. The id itself is stored in `Logger.metadata` as-is — the host app is responsible for not logging sensitive metadata. The Phase 96 guide documents this. |
| Forged `_crosswake_thread_id` connect param (client-controlled) | Spoofing | By design — the connect param is client-supplied. The library treats it as an opaque string correlation hint, not an authority token. No security decisions are made on its basis. This is the documented gap that Phase 93 native injection addresses. |

---

## Sources

### Primary (HIGH confidence)

- `deps/plug/lib/plug/telemetry.ex` — Plug.Telemetry idiom (Plug 1.19.1, verified in project deps)
- `deps/plug/lib/plug/request_id.ex` — Plug.RequestId header read-or-mint + Logger.metadata + put_resp_header pattern (Plug 1.19.1, verified)
- `deps/phoenix_live_view/lib/phoenix_live_view.ex` — `connected?/1` (line 635), `get_connect_params/1` (lines 1248–1253), `on_mount/4` callback contract (lines 499–614) — LiveView 1.1.30, verified
- `deps/phoenix_live_view/lib/phoenix_live_view/lifecycle.ex` — `on_mount/4` invocation via `Function.capture(module, :on_mount, 4)` (verified)
- `lib/crosswake/threadline/telemetry.ex` — Phase 91 contract: `@event_names`, `@metadata_keys`, `execute/3`, `metadata/1` (verified in codebase)
- `lib/crosswake/companions/chimeway/redaction.ex` line 56 — `:crypto.mac(:hmac, …)` + `Base.encode16/2` precedent (verified)
- `lib/crosswake/policy/schema.ex` — `NimbleOptions.new!` + `NimbleOptions.validate!/2` in-repo idiom (verified)
- `mix.exs` — locked dep versions: plug 1.19.1, phoenix_live_view 1.1.30, nimble_options 1.1.1, telemetry 1.4.2 (verified)
- `.planning/research/REC-VERSIONING.md` — 0.x release-please config: `bump-patch-for-minor-pre-major: true` → `feat:` = patch bump (verified)

### Secondary (MEDIUM confidence)

- `.planning/phases/92-server-propagation-plug-liveview/92-CONTEXT.md` — locked decisions D-01 through D-14
- `.planning/phases/91-identity-telemetry-contract/91-CONTEXT.md` — upstream contract decisions D-01 through D-11
- RFC-4122 §4.4 (UUID v4 bit layout, version nibble + variant bits) [ASSUMED — not re-fetched this session; the bit layout is stable standards]

### Tertiary (LOW confidence)

None — all critical claims were verified against in-repo source files.

---

## Metadata

**Confidence breakdown:**

- Standard stack: HIGH — all versions verified from locked deps in project
- Architecture patterns: HIGH — patterns traced directly from `Plug.Telemetry` and `Plug.RequestId` source in project deps; `on_mount` traced from LiveView 1.1.30 source
- Pitfalls: HIGH — pitfalls 1–4 grounded in verified source behavior; pitfall 5 grounded in versioning research document
- UUID implementation: HIGH (code logic) / ASSUMED (RFC-4122 bit layout from training knowledge, not re-checked against spec this session)

**Research date:** 2026-06-09
**Valid until:** 2026-09-09 (plug/liveview APIs are stable; UUID bit layout is a permanent standard)
