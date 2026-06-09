# Phase 92: Server Propagation — Plug + LiveView - Pattern Map

**Mapped:** 2026-06-09
**Files analyzed:** 7 (3 source + 4 test)
**Analogs found:** 7 / 7

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/crosswake/threadline/id.ex` | utility | transform | `lib/crosswake/companions/chimeway/redaction.ex` (`:crypto` + `Base.encode16`) | role-match |
| `lib/crosswake/plug/threadline.ex` | middleware | request-response | `deps/plug/lib/plug/telemetry.ex` + `deps/plug/lib/plug/request_id.ex` (dep source, verified) | exact |
| `lib/crosswake/live/threadline.ex` | hook | event-driven | `deps/phoenix_live_view/lib/phoenix_live_view.ex` on_mount contract (dep source, verified) | exact |
| `test/crosswake/threadline/id_test.exs` | test | transform | `test/crosswake/threadline/telemetry_test.exs` | exact |
| `test/crosswake/plug/threadline_test.exs` | test | request-response | `test/crosswake/threadline/telemetry_test.exs` + `Plug.Test` (used in proof tests) | role-match |
| `test/crosswake/live/threadline_test.exs` | test | event-driven | `test/crosswake/threadline/telemetry_test.exs` | role-match |
| `test/crosswake/proof/phase92_server_propagation_closeout_test.exs` | test (proof) | request-response | `test/crosswake/proof/phase39_route_policy_gating_test.exs` | exact |
| `mix.exs` (version bump only) | config | — | `mix.exs` line 4: `@version "0.1.1"` | exact |

---

## Pattern Assignments

### `lib/crosswake/threadline/id.ex` (utility, transform)

**Analog:** `lib/crosswake/companions/chimeway/redaction.ex`

**Module structure pattern** (lines 1-7 of telemetry.ex — nearest structured-module analog):
```elixir
defmodule Crosswake.Threadline.Id do
  @moduledoc """
  Generates RFC-4122 v4 UUIDs for Crosswake Threadline thread_id minting.
  """
```

**`:crypto` + `Base.encode16` pattern** (`lib/crosswake/companions/chimeway/redaction.ex` lines 55-56):
```elixir
digest = :crypto.mac(:hmac, :sha256, opts[:fingerprint_secret], raw_token)
{:ok, "hmac-sha256:" <> Base.encode16(digest, case: :lower)}
```
Phase 92 adaptation — use `:crypto.strong_rand_bytes/1` (not `:crypto.mac`) and format as UUID segments via binary pattern matching:
```elixir
<<u0::48, _::4, u1::12, _::2, u2::62>> = :crypto.strong_rand_bytes(16)
raw = <<u0::48, 4::4, u1::12, 2::2, u2::62>>
hex = Base.encode16(raw, case: :lower)
<<a::8-bytes, b::4-bytes, c::4-bytes, d::4-bytes, e::12-bytes>> = hex
"#{a}-#{b}-#{c}-#{d}-#{e}"
```

**`@spec` pattern** (`lib/crosswake/threadline/telemetry.ex` line 73):
```elixir
@spec generate() :: String.t()
def generate do
```

---

### `lib/crosswake/plug/threadline.ex` (middleware, request-response)

**Analog:** `deps/plug/lib/plug/telemetry.ex` + `deps/plug/lib/plug/request_id.ex` (both verified against Plug 1.19.1 in project deps)

**`@behaviour Plug` + module attribute schema pattern** (from RESEARCH.md verified Pattern 4 + in-repo `lib/crosswake/policy/schema.ex` line 50):
```elixir
@behaviour Plug

@schema NimbleOptions.new!(
  header_name: [
    type: :string,
    default: "x-crosswake-thread-id"
  ],
  logger_metadata_key: [
    type: :atom,
    default: :crosswake_thread_id
  ],
  telemetry_prefix: [
    type: {:list, :atom},
    default: [:crosswake, :threadline, :request]
  ]
)

@impl true
def init(opts), do: NimbleOptions.validate!(opts, @schema)
```
`NimbleOptions.new!` at compile time (module attribute) + `NimbleOptions.validate!/2` in `init/1` is the in-repo idiom from `lib/crosswake/policy/schema.ex` line 50. The `init/1` return (validated keyword list) is passed as second arg to `call/2`.

**Plug.Telemetry idiom for start + register_before_send stop** (verified from `deps/plug/lib/plug/telemetry.ex`, documented in RESEARCH.md Pattern 1):
```elixir
@impl true
def call(conn, opts) do
  start_time = System.monotonic_time()
  # ... mint/read id ...
  Threadline.Telemetry.execute(prefix ++ [:start], %{system_time: System.system_time()}, meta)

  Plug.Conn.register_before_send(conn, fn conn ->
    duration = System.monotonic_time() - start_time
    Threadline.Telemetry.execute(prefix ++ [:stop], %{duration: duration}, meta)
    conn
  end)
end
```
Key difference from raw `Plug.Telemetry`: replace `:telemetry.execute` with `Threadline.Telemetry.execute/3` so allowlist guard fires at every emission (D-04).

**Plug.RequestId header read-or-mint + Logger.metadata + put_resp_header pattern** (verified from `deps/plug/lib/plug/request_id.ex` lines 72-79, documented in RESEARCH.md Pattern 2):
```elixir
# Read-or-mint with source provenance via pattern-match (not post-hoc inference — Pitfall 3)
{id, source} =
  case Plug.Conn.get_req_header(conn, header_name) do
    [id | _] -> {id, :inbound}
    []       -> {Crosswake.Threadline.Id.generate(), :minted}
  end

# Logger keyword list syntax, not map (Pitfall 4 — verified from Plug.RequestId line 75)
Logger.metadata([{logger_key, id}])

# Synchronous echo — NOT register_before_send (D-12)
conn = Plug.Conn.put_resp_header(conn, header_name, id)
```

**try/rescue for honest :exception scope** (D-03 — own-plug synchronous work only):
```elixir
try do
  # header read, UUID mint, Logger.metadata, put_resp_header, :start emit, register_before_send
rescue
  e ->
    # NOTE: :exception scope is limited to OWN plug work (header read, UUID mint,
    # Logger.metadata, put_resp_header). A function plug CANNOT catch downstream
    # raises — those unwind past register_before_send without firing it.
    # Phoenix.Router owns [:phoenix, :router_dispatch, :exception] for downstream failures.
    Threadline.Telemetry.execute(prefix ++ [:exception], %{duration: System.monotonic_time()}, ...)
    reraise e, __STACKTRACE__
end
```

**Alias block pattern** (from `lib/crosswake/companions/chimeway/redaction.ex` lines 9-13):
```elixir
alias Plug.Conn
alias Crosswake.Threadline.Id, as: ThreadlineId
alias Crosswake.Threadline.Telemetry, as: ThreadlineTelemetry
```

---

### `lib/crosswake/live/threadline.ex` (hook, event-driven)

**Analog:** `deps/phoenix_live_view/lib/phoenix_live_view.ex` on_mount/4 contract (LiveView 1.1.30, verified)

**Module structure** (no existing on_mount hook in codebase — greenfield; use LV verified pattern from RESEARCH.md Pattern 3):
```elixir
defmodule Crosswake.Live.Threadline do
  @moduledoc """
  A LiveView `on_mount` hook that reads `_crosswake_thread_id` from the
  LiveView connect params and sets `crosswake_thread_id` on the LiveView
  GenServer process Logger metadata.

  The Plug is the sole mint authority — this hook is read-only and never
  mints a thread_id (D-06).
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

**Critical guard ordering** (Pitfall 1 from RESEARCH.md — `connected?(socket)` MUST precede `get_connect_params/1`):
- `connected?(socket)` first — prevents `ArgumentError` on disconnected/static render
- `get_connect_params(socket)["_crosswake_thread_id"]` only inside the `if` block
- Always returns `{:cont, socket}` — `:halt` is not used (D-07)

**Logger.metadata static-key syntax** (parity with Plug — D-09):
```elixir
Logger.metadata(crosswake_thread_id: id)
```
vs. Plug's dynamic-key syntax:
```elixir
Logger.metadata([{logger_key, id}])   # keyword list, not map — Pitfall 4
```

---

### `test/crosswake/threadline/id_test.exs` (test, transform)

**Analog:** `test/crosswake/threadline/telemetry_test.exs`

**Module + use pattern** (telemetry_test.exs lines 1-4):
```elixir
defmodule Crosswake.Threadline.IdTest do
  use ExUnit.Case, async: true

  alias Crosswake.Threadline.Id
```

**Section comment pattern** (telemetry_test.exs lines 6-8 — dashes + label):
```elixir
# -----------------------------------------------------------------------
# Contract: generate/0 — RFC-4122 v4 format + uniqueness
# -----------------------------------------------------------------------
```

**Assertion style for format contracts** (telemetry_test.exs lines 10-15):
```elixir
test "generate/0 returns a 36-character hyphenated string" do
  id = Id.generate()
  assert String.length(id) == 36
  assert Regex.match?(~r/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/, id)
end

test "generate/0 returns unique values on successive calls" do
  ids = for _ <- 1..100, do: Id.generate()
  assert length(Enum.uniq(ids)) == 100
end
```

---

### `test/crosswake/plug/threadline_test.exs` (test, request-response)

**Analog:** `test/crosswake/threadline/telemetry_test.exs` (structure) + `Plug.Test` (verified used in `test/crosswake/proof/phase55_session_handoff_tickets_test.exs` line 327)

**Module + use pattern with Plug.Test import**:
```elixir
defmodule Crosswake.Plug.ThreadlineTest do
  use ExUnit.Case, async: true

  import Plug.Test
  import Plug.Conn

  alias Crosswake.Plug.Threadline
```

**Telemetry handler setup pattern** (telemetry_test.exs lines 135-147 — attach/detach with `on_exit`):
```elixir
handler_id = "test-plug-threadline-#{System.unique_integer()}"

:telemetry.attach(
  handler_id,
  [:crosswake, :threadline, :request, :start],
  fn event_name, measurements, metadata, _config ->
    send(self(), {:telemetry, event_name, measurements, metadata})
  end,
  nil
)

on_exit(fn -> :telemetry.detach(handler_id) end)
```

**Plug.Test conn construction** (from `test/crosswake/proof/phase55_session_handoff_tickets_test.exs` line 327):
```elixir
conn = conn(:get, "/some/path")
conn = conn |> put_req_header("x-crosswake-thread-id", "existing-id")
opts = Threadline.init([])
result_conn = Threadline.call(conn, opts)
```

**Response header assertion**:
```elixir
assert get_resp_header(result_conn, "x-crosswake-thread-id") == ["existing-id"]
```

**Logger.metadata assertion** (read process metadata after plug call):
```elixir
assert Logger.metadata()[:crosswake_thread_id] == "existing-id"
```

---

### `test/crosswake/live/threadline_test.exs` (test, event-driven)

**Analog:** `test/crosswake/threadline/telemetry_test.exs`

**Module + use pattern**:
```elixir
defmodule Crosswake.Live.ThreadlineTest do
  use ExUnit.Case, async: true

  alias Crosswake.Live.Threadline
```

**Pattern for testing on_mount with mock socket** — no existing LiveView test in the lib; use `Phoenix.LiveView.Utils` or a minimal struct. The RESEARCH.md confirms `connected?(socket)` checks `socket.transport_pid != nil` (LV 1.1.30 line 635), so a mock socket struct suffices:
```elixir
# Disconnected socket stub
defp disconnected_socket do
  %Phoenix.LiveView.Socket{transport_pid: nil, private: %{connect_params: nil}}
end

# Connected socket stub with connect params
defp connected_socket(params \\ %{}) do
  %Phoenix.LiveView.Socket{
    transport_pid: self(),
    private: %{connect_params: params}
  }
end
```

**No-op assertions** (mirror telemetry_test.exs style — assert return value is `{:cont, socket}`):
```elixir
test "on_mount/4 returns {:cont, socket} and does not set metadata when disconnected" do
  socket = disconnected_socket()
  assert {:cont, ^socket} = Threadline.on_mount(:default, %{}, %{}, socket)
  refute Keyword.has_key?(Logger.metadata(), :crosswake_thread_id)
end
```

---

### `test/crosswake/proof/phase92_server_propagation_closeout_test.exs` (proof test)

**Analog:** `test/crosswake/proof/phase39_route_policy_gating_test.exs`

**Module + @moduledoc pattern** (phase39 lines 1-18):
```elixir
defmodule Crosswake.Proof.Phase92ServerPropagationCloseoutTest do
  @moduledoc """
  Hermetic merge-blocking proof lane for Phase 92 server-side thread_id propagation.

  Proves PROP-01: Crosswake.Plug.Threadline reads inbound X-Crosswake-Thread-Id
  (source: :inbound), mints a UUID fallback when absent (source: :minted), sets
  Logger.metadata, echoes the response header, and emits the three-event telemetry
  triplet via Threadline.Telemetry.execute/3.

  Proves PROP-03: Crosswake.Live.Threadline.on_mount/4 reads _crosswake_thread_id
  from connect params and sets Logger.metadata on the LiveView process. No-op on
  disconnected render or absent param.

  This test is fully hermetic: no example host, no network, no simulator.
  """

  use ExUnit.Case, async: true
  import Plug.Test
  import Plug.Conn
```

**`async: false` vs `async: true`** — use `async: true` (hermetic, no shared state). Phase 39 uses `async: true` (line 18). Phase 70 uses `async: false` due to Application.put_env side effects (not applicable here).

**Hermeticity self-assertion pattern** (phase39 lines 70+):
```elixir
# ---------------------------------------------------------------------------
# Hermeticity self-assertion
# ---------------------------------------------------------------------------

test "proof test is hermetic — no example host dependency" do
  refute Code.ensure_loaded?(CrosswakeExample)
end
```

---

## Shared Patterns

### NimbleOptions `@schema` module attribute
**Source:** `lib/crosswake/policy/schema.ex` lines 50-135
**Apply to:** `lib/crosswake/plug/threadline.ex` `init/1` only
```elixir
# Compile-time schema definition as module attribute
@schema NimbleOptions.new!(
  key: [type: :type, default: default_value, doc: "..."]
)

# Runtime validation in init/1 — returns validated keyword list passed to call/2
@impl true
def init(opts), do: NimbleOptions.validate!(opts, @schema)
```

### `:telemetry.attach` / `on_exit` test cleanup
**Source:** `test/crosswake/threadline/telemetry_test.exs` lines 136-147
**Apply to:** `test/crosswake/plug/threadline_test.exs` and proof test (any test that attaches telemetry handlers)
```elixir
handler_id = "test-handler-#{System.unique_integer()}"
:telemetry.attach(handler_id, event_name, fn name, meas, meta, _cfg ->
  send(self(), {:telemetry_received, name, meas, meta})
end, nil)
on_exit(fn -> :telemetry.detach(handler_id) end)
# ...
assert_receive {:telemetry_received, _name, _meas, metadata}
```

### `Base.encode16(_, case: :lower)` binary formatting
**Source:** `lib/crosswake/companions/chimeway/redaction.ex` line 56
**Apply to:** `lib/crosswake/threadline/id.ex`
```elixir
Base.encode16(binary, case: :lower)
```

### Section comment delimiter style
**Source:** `test/crosswake/threadline/telemetry_test.exs` lines 6-8
**Apply to:** All new test files
```elixir
# -----------------------------------------------------------------------
# Contract: <description>
# -----------------------------------------------------------------------
```

### `async: true` + hermetic proof lane
**Source:** `test/crosswake/proof/phase39_route_policy_gating_test.exs` line 18
**Apply to:** All Phase 92 test files (no shared process state, no Application.put_env)
```elixir
use ExUnit.Case, async: true
```

---

## No Analog Found

No files lack a codebase analog. The greenfield Plug and LiveView hook namespaces have strong framework-source analogs verified directly from `deps/plug/` and `deps/phoenix_live_view/`. The test files mirror the established `TelemetryTest` pattern.

---

## Anti-Patterns Confirmed (do not copy these)

| Pattern | Where it exists in codebase | Why NOT to copy |
|---|---|---|
| `:telemetry.span/3` wrapping a function plug's full body | `lib/crosswake/compatibility/route_gate.ex` lines 124, 152 | These wrap bounded synchronous calls. A function plug returns to the pipeline before downstream work runs; `:span/3` would fire `:stop` at ~microsecond duration — dishonest. Use `register_before_send` idiom instead (D-01, D-02). |
| `Logger.metadata(%{key: value})` (map syntax) | Not in codebase — but common mistake | `Logger.metadata/1` requires keyword list, not map. Copy Plug.RequestId line 75: `Logger.metadata([{logger_key, id}])`. |

---

## Version Bump Pattern

**Source:** `mix.exs` line 4
**Apply to:** `mix.exs` — single line change

```elixir
# Before:
@version "0.1.1"

# After:
@version "0.1.2"
```

Rationale: `bump-patch-for-minor-pre-major: true` config means `feat:` commits in 0.x land as patch bumps. Three new public modules = `feat:` commit = patch bump `0.1.1 → 0.1.2` (RESEARCH.md Pitfall 5, verified against REC-VERSIONING.md).

---

## Metadata

**Analog search scope:** `lib/crosswake/`, `test/crosswake/`, `deps/plug/lib/plug/`, `deps/phoenix_live_view/lib/`
**Files scanned:** 9 source files read (telemetry.ex, redaction.ex, policy/schema.ex, route_gate.ex excerpt, mix.exs, test_helper.exs, telemetry_test.exs, phase39 proof test, phase70 proof test)
**Pattern extraction date:** 2026-06-09
