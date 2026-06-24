# Phase 125: Containerized Shared Backend + Port Convention - Pattern Map

**Mapped:** 2026-06-21
**Files analyzed:** 11 (4 modified, 7 created)
**Analogs found:** 6 / 11 (5 greenfield)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `examples/phoenix_host/config/config.exs` | config | request-response | self (current single config) | exact — prune only |
| `examples/phoenix_host/config/dev.exs` | config | request-response | none in repo | greenfield — Phoenix convention |
| `examples/phoenix_host/config/runtime.exs` | config | request-response | none in repo | greenfield — Phoenix convention |
| `examples/phoenix_host/mix.exs` | config | CRUD | self (current mix.exs) | exact — additive |
| `examples/phoenix_host/lib/crosswake_example/endpoint.ex` | middleware | request-response | self (current endpoint.ex) | exact — additive |
| `examples/phoenix_host/playwright.config.ts` | config | request-response | self (current playwright.config.ts) | exact — 2-line port swap |
| `examples/phoenix_host/.env` | config | n/a | none | greenfield |
| `examples/phoenix_host/Dockerfile` | config | file-I/O | none in repo | greenfield |
| `examples/phoenix_host/.dockerignore` | config | file-I/O | none in repo | greenfield |
| `docker-compose.yml` | config | event-driven | none in repo | greenfield |
| `docs/PORT-REGISTRY.md` | utility | n/a | `docs/_contract_snippet.md` (by role: committed docs artifact) | partial — content greenfield |
| `test/crosswake/guides/port_registry_test.exs` | test | request-response | `test/crosswake/guides/quick_start_adoption_drift_test.exs` | exact |

## Pattern Assignments

### `examples/phoenix_host/config/config.exs` (config — prune)

**Analog:** self — `examples/phoenix_host/config/config.exs`

**What stays** (all lines except line 11 `http:` and line 17 `database:`):
- `:phoenix, :json_library, Jason`
- `CrosswakeExample.Endpoint` adapter/url/server/secret_key_base/live_view (minus `http:`)
- `CrosswakeExample.Repo` without `database:` path (that moves to runtime.exs)
- `CrosswakeExample.Router` url config
- `:crosswake, :companions` and `:rulestead` companion config

**What moves out** (lines 11 and 17 — move to runtime.exs):
```elixir
# line 11 — moves to runtime.exs
http: [ip: {127, 0, 0, 1}, port: String.to_integer(System.get_env("PORT") || "4002")],
# line 17 — moves to runtime.exs
database: Path.expand("../crosswake_example.db", Path.dirname(__ENV__.file)),
```

---

### `examples/phoenix_host/config/dev.exs` (config — greenfield)

**Analog:** none in repo. Follow standard Phoenix 1.8 `config/dev.exs` convention.

**Structure to produce:**
```elixir
import Config

config :crosswake_example, CrosswakeExample.Endpoint,
  code_reloader: true,
  check_origin: false,
  live_reload: [
    patterns: [
      ~r"lib/.+\.ex(s)?$",
      ~r"priv/static/.+\.(css|js)$"
    ],
    interval: 1500
  ]

config :crosswake_example, CrosswakeExample.Repo,
  show_sensitive_data_on_connection_error: true
```

Key decisions from D-06:
- `interval: 1500` — polling interval for macOS Docker bind-mounts (filesystem events don't propagate).
- Never watch `_build/` or `deps/` (reload storms).
- No asset watchers (no esbuild/Tailwind pipeline; styles are static/inline).

---

### `examples/phoenix_host/config/runtime.exs` (config — greenfield)

**Analog:** none in repo. Standard Phoenix 1.8 `config/runtime.exs` shape.

**Structure to produce (D-05):**
```elixir
import Config

# Bind 0.0.0.0 inside Docker; 127.0.0.1 native. Port defaults to 4700.
# Gate on an explicit env var (e.g. BIND_ALL=true) so :test env stays on loopback.
ip =
  if System.get_env("BIND_ALL") == "true" do
    {0, 0, 0, 0}
  else
    {127, 0, 0, 1}
  end

port = String.to_integer(System.get_env("PORT") || "4700")

config :crosswake_example, CrosswakeExample.Endpoint,
  http: [ip: ip, port: port]

database_path =
  System.get_env("DATABASE_PATH") ||
    Path.expand("../crosswake_example.db", Path.dirname(__ENV__.file))

config :crosswake_example, CrosswakeExample.Repo,
  database: database_path
```

Key decisions:
- D-01: default port is **4700** (not 4002).
- D-05: container sets `BIND_ALL=true` and `DATABASE_PATH=/data/crosswake_example.db`.
- D-05: `:test` must NOT flip to `0.0.0.0`; the `BIND_ALL` env-var gate achieves this since test runs don't set it.
- Planner must decide exact gate mechanism (e.g. `BIND_ALL` vs `DOCKER`); the above is the reference shape.

---

### `examples/phoenix_host/mix.exs` (config — additive)

**Analog:** self — `examples/phoenix_host/mix.exs`

**Current deps block** (lines 37-48) to extend:
```elixir
defp deps do
  [
    {:crosswake, path: "../.."},
    {:phoenix, "~> 1.8"},
    {:phoenix_live_view, "~> 1.1"},
    # ADD:
    {:phoenix_live_reload, "~> 1.5", only: :dev},
    {:plug, "~> 1.16"},
    {:jason, "~> 1.4"},
    {:ecto_sql, "~> 3.10"},
    {:ecto_sqlite3, "~> 0.16"},
    {:bandit, "~> 1.0"}
  ]
end
```

**Stale comment to correct** (line 33, per D-10):
```elixir
# BEFORE (stale):
# Required in CI where the committed .db file is absent or stale.
# AFTER (correct):
# Provisions the SQLite DB and applies all migrations before running tests.
```

---

### `examples/phoenix_host/lib/crosswake_example/endpoint.ex` (middleware — additive)

**Analog:** self — `examples/phoenix_host/lib/crosswake_example/endpoint.ex`

**Current plug stack** (full file, 33 lines) — insert LiveReloader/CodeReloader after socket, before Plug.Static:
```elixir
# CURRENT (lines 1-32):
defmodule CrosswakeExample.Endpoint do
  use Phoenix.Endpoint, otp_app: :crosswake_example

  @session_options [...]

  socket("/live", Phoenix.LiveView.Socket, ...)

  plug(Plug.Static, ...)   # line 12 — LiveReloader/CodeReloader go BEFORE this
  ...
end

# ADD after socket/live (per D-07), guarded by code_reloading?:
if code_reloading? do
  socket("/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket)
  plug(Phoenix.LiveReloader)
  plug(Phoenix.CodeReloader)
end
```

D-07: The config keys (`code_reloader: true`, `live_reload: [...]`) alone do nothing — the plugs must also be present.

---

### `examples/phoenix_host/playwright.config.ts` (config — 2-line port swap)

**Analog:** self — `examples/phoenix_host/playwright.config.ts`

**Lines to change** (lines 11 and 24, currently `4002`):
```typescript
// line 11 — BEFORE:
baseURL: 'http://localhost:4002',
// line 11 — AFTER:
baseURL: 'http://localhost:4700',

// line 24 — BEFORE:
port: 4002,
// line 24 — AFTER:
port: 4700,
```

No other changes. The drift test `quick_start_adoption_drift_test.exs` (line 151) extracts the Playwright port via `~r/\bport:\s*(\d+)/` and asserts it matches the config port — it will self-validate after both changes.

---

### `examples/phoenix_host/.env` (config — greenfield)

**Analog:** none in repo.

**Content (D-11, D-12):**
```
COMPOSE_PROJECT_NAME=crosswake
PORT=4700
```

Note: `COMPOSE_PROJECT_NAME` namespaces container/network/volume names, NOT host port bindings. The committed `PORT=4700` is the real collision guard.

---

### `examples/phoenix_host/Dockerfile` (config — greenfield)

**Analog:** none in repo. No existing Dockerfile anywhere in the tree.

**Conventional multi-stage structure for Elixir + NIF deps (D-09):**

```dockerfile
# Stage 1: build
FROM hexpm/elixir:1.19.x-erlang-27.x-debian-bookworm-slim AS build
# (exact tag: planner resolves latest 1.19 + Erlang 27 on Debian bookworm-slim)
# Note: ecto_sqlite3 compiles a NIF; Debian-slim (glibc) is required.
# Alpine (musl) is NOT safe unless ecto_sqlite3 explicitly supports musl.

WORKDIR /app
ENV MIX_ENV=dev

RUN mix local.hex --force && mix local.rebar --force

COPY mix.exs mix.lock ./
RUN mix deps.get

COPY config/ config/
COPY lib/ lib/
COPY priv/ priv/

RUN mix deps.compile

# Stage 2: runtime image (same base for NIF compat)
FROM hexpm/elixir:1.19.x-erlang-27.x-debian-bookworm-slim

WORKDIR /app
ENV MIX_ENV=dev

# Copy compiled app from build stage
COPY --from=build /app /app
COPY --from=build /root/.mix /root/.mix

# Entrypoint runs idempotent DB setup then starts server (D-09)
COPY entrypoint.sh ./
RUN chmod +x entrypoint.sh

EXPOSE 4700
CMD ["./entrypoint.sh"]
```

**Entrypoint script pattern (D-09):**
```sh
#!/bin/sh
set -e
mix ecto.create --quiet
mix ecto.migrate --quiet
mix run priv/repo/seeds.exs
exec mix phx.server
```

Layer ordering note: `mix.exs`/`mix.lock` BEFORE source files — deps layer cached unless deps change.

For development with live-reload (bind-mount), docker-compose.yml overrides the CMD with the same entrypoint or `mix phx.server` directly (deps come from named volumes, not the image).

---

### `examples/phoenix_host/.dockerignore` (config — greenfield)

**Analog:** none in repo.

**Content (D-10):**
```
_build/
deps/
.git/
.github/
test/
node_modules/
*.db
*.db-shm
*.db-wal
crosswake_example.db*
.env
```

Key: `crosswake_example.db*` must be excluded so untracked tree artifacts never bake into the image and shadow the named volume (D-10).

---

### `docker-compose.yml` (config — greenfield)

**Analog:** none in repo.

**Location:** `examples/phoenix_host/docker-compose.yml` (collocated with `.env` and `Dockerfile`; planner confirms).

**Conventional structure:**
```yaml
services:
  phoenix:
    build: .
    env_file: .env
    environment:
      - BIND_ALL=true
      - DATABASE_PATH=/data/crosswake_example.db
    ports:
      - "4700:4700"
    volumes:
      - .:/app                        # source bind-mount for polling live-reload
      - deps_cache:/app/deps          # compiled deps cached across restarts
      - build_cache:/app/_build       # compiled bytecode cached
      - sqlite_data:/data             # named volume for SQLite persistence

volumes:
  deps_cache:
  build_cache:
  sqlite_data:
```

Key decisions:
- `BIND_ALL=true` triggers `{0, 0, 0, 0}` binding in `runtime.exs` (D-05).
- `DATABASE_PATH=/data/crosswake_example.db` keeps SQLite in named volume (D-08/D-09).
- Source bind-mount + named dep volumes = fast iteration with polling live-reload (D-06).
- `COMPOSE_PROJECT_NAME` comes from `.env` to namespace volumes/networks (D-12).

---

### `docs/PORT-REGISTRY.md` (utility — greenfield)

**Analog:** `docs/_contract_snippet.md` exists but is a single snippet file, not a guide.
Conceptually closest docs format is `guides/adoption.md` and `guides/commerce.md` (human-readable, drift-tested, brand-voiced).

**Content shape (D-11, D-12):**

The file must contain:
- Reserved block: **4700–4799** for the maintainer's OSS lib demos
- Excluded ports: 3000 React/Next, 4000 Phoenix default, 4002 old demo default, 5000 macOS AirPlay, 5173 Vite, 8080, 49152+ IANA ephemeral
- Allocation rule: "take next free port in block, one per lib, commit `PORT=` / `COMPOSE_PROJECT_NAME=` in `.env`, add a registry row"
- Table with seed row: `crosswake | 4700 | crosswake | examples/phoenix_host`
- `COMPOSE_PROJECT_NAME` caveat: namespaces container/network/volume names, NOT host port bindings
- Android note: emulator reaches host via `10.0.2.2` (not `localhost`)

These three strings are asserted by the drift test (D-13):
- `COMPOSE_PROJECT_NAME`
- `10.0.2.2`
- `crosswake` + `4700` in the registry table

---

### `test/crosswake/guides/port_registry_test.exs` (test — exact mirror)

**Analog:** `test/crosswake/guides/quick_start_adoption_drift_test.exs` — copy the structure verbatim.

**Module header pattern** (lines 1-8 of analog):
```elixir
defmodule Crosswake.Guides.PortRegistryTest do
  use ExUnit.Case, async: true

  @port_registry_path "docs/PORT-REGISTRY.md"
  @env_path "examples/phoenix_host/.env"
  @runtime_config_path "examples/phoenix_host/config/runtime.exs"
```

**Port extraction pattern** (analog lines 134-138) — derive from `runtime.exs`:
```elixir
defp committed_port do
  @runtime_config_path
  |> File.read!()
  |> source_port!(~r/System\.get_env\("PORT"\)\s*\|\|\s*"(\d+)"/, @runtime_config_path)
end
```

Note: after phase 125, the port default lives in `runtime.exs` (not `config.exs`). The existing `quick_start_adoption_drift_test.exs` still reads `config.exs` (line 135 — `@phoenix_config_path`). The new test reads `runtime.exs`. The existing test's `phoenix_host_port/0` helper will need updating too (see `examples/QUICK_START.md` section below).

**`require_contains` pattern** (analog lines 588-594) — copy helper verbatim:
```elixir
defp require_contains(path, contents, needle, category, detail) do
  if String.contains?(contents, needle) do
    []
  else
    [failure(path, category, detail: detail)]
  end
end
```

**Test structure to produce (D-13):**
```elixir
test "source-derived facts are readable" do
  assert committed_port() =~ ~r/^\d+$/
  assert File.exists?(@port_registry_path)
  assert File.exists?(@env_path)
end

test "PORT-REGISTRY mentions COMPOSE_PROJECT_NAME, 10.0.2.2, and the crosswake seed row" do
  contents = File.read!(@port_registry_path)
  port = committed_port()

  failures =
    [
      require_contains(@port_registry_path, contents, "COMPOSE_PROJECT_NAME", :missing_caveat,
        "document COMPOSE_PROJECT_NAME namespacing caveat"),
      require_contains(@port_registry_path, contents, "10.0.2.2", :missing_android_note,
        "document Android emulator host loopback address"),
      require_contains(@port_registry_path, contents, port, :wrong_port,
        "registry must list the source-derived port"),
      require_contains(@port_registry_path, contents, "crosswake", :missing_seed_row,
        "registry must have a crosswake seed row")
    ]
    |> List.flatten()

  assert failures == [],
         "PORT-REGISTRY drift found:\n" <> format_failures(failures)
end

test "PORT-REGISTRY scanner rejects missing COMPOSE_PROJECT_NAME" do
  contents = File.read!(@port_registry_path)
  without_caveat = String.replace(contents, "COMPOSE_PROJECT_NAME", "PROJECT_NAME")
  assert_failure_category(
    scan_registry({"synthetic/port_registry_no_compose.md", without_caveat}),
    :missing_caveat
  )
end
```

**`failure/3` and `format_failures/1` helpers** — copy verbatim from analog (lines 388-415). No changes needed.

---

### `examples/QUICK_START.md` (utility — 9 port refs + Docker section)

**Analog:** self — `examples/QUICK_START.md`.

**Changes needed:**
1. Replace all `4002` occurrences with `4700` (~9 refs — exact count from D-02).
2. Add Docker path section documenting `docker compose up` workflow.
3. `PORT=4002 mix phx.server` → `PORT=4700 mix phx.server` (also asserted by `quick_start_adoption_drift_test.exs` line 185 via `require_contains` for `"PORT=#{port} mix phx.server"`).

The existing drift test will fail loudly on any remaining `4002` refs (line 501-515 of analog: `wrong_port_failures/3` scans every line for `localhost:NNNN` and `PORT=NNNN`).

---

## Shared Patterns

### Source-Derived Port Extraction
**Source:** `test/crosswake/guides/quick_start_adoption_drift_test.exs` lines 430-435
**Apply to:** `test/crosswake/guides/port_registry_test.exs`
```elixir
defp source_port!(contents, regex, path) do
  case Regex.run(regex, contents) do
    [_match, port] -> port
    _ -> raise "could not derive port from #{path}"
  end
end
```

After phase 125, port default moves to `runtime.exs`. Both the new port registry test AND the existing `quick_start_adoption_drift_test.exs` `phoenix_host_port/0` helper (line 135, currently pointing at `config.exs` with regex `~r/System\.get_env\("PORT"\)\s*\|\|\s*"(\d+)"/`) must be updated to point at `runtime.exs` instead.

### Failure Struct + Formatting
**Source:** `test/crosswake/guides/quick_start_adoption_drift_test.exs` lines 388-415
**Apply to:** `test/crosswake/guides/port_registry_test.exs`
```elixir
defp failure(path, category, opts) do
  %{
    path: path,
    line: Keyword.get(opts, :line),
    category: category,
    claim: Keyword.get(opts, :claim),
    detail: Keyword.fetch!(opts, :detail)
  }
end

defp format_failures(failures) do
  Enum.map_join(failures, "\n", fn failure ->
    location = if failure.line, do: "#{failure.path}:#{failure.line}", else: failure.path
    claim = failure.claim |> to_string() |> String.trim()
    claim_suffix = if claim == "", do: "", else: " -- #{claim}"
    "- #{location} [#{failure.category}] #{failure.detail}#{claim_suffix}"
  end)
end
```

### Doc-Contract Test Structure
**Source:** `test/crosswake/guides/quick_start_adoption_drift_test.exs` (full file pattern)
**Apply to:** `test/crosswake/guides/port_registry_test.exs`
Pattern: (1) read source file, extract truth, (2) assert doc contains truth, (3) assert scanner rejects synthetic stale inputs for each category.

### Mix Alias Idempotent DB Setup
**Source:** `examples/phoenix_host/mix.exs` lines 26-35
**Apply to:** `examples/phoenix_host/Dockerfile` entrypoint
```elixir
"ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
```
The entrypoint mirrors this exact sequence with `--quiet` flags. `seeds.exs` is already idempotent (`delete_all` then insert).

---

## No Analog Found

Files with no close match in the codebase (planner uses conventional structure described above):

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `examples/phoenix_host/config/dev.exs` | config | request-response | No existing dev.exs in phoenix_host; only a single config.exs |
| `examples/phoenix_host/config/runtime.exs` | config | request-response | No existing runtime.exs; only a single config.exs |
| `examples/phoenix_host/.env` | config | n/a | No .env files exist anywhere in repo |
| `examples/phoenix_host/Dockerfile` | config | file-I/O | No Dockerfiles exist anywhere in repo |
| `examples/phoenix_host/.dockerignore` | config | file-I/O | No .dockerignore files exist anywhere in repo |
| `docker-compose.yml` | config | event-driven | No docker-compose files exist anywhere in repo |
| `docs/PORT-REGISTRY.md` | utility | n/a | No PORT-REGISTRY or equivalent docs exist; docs/ only has `_contract_snippet.md` |

## Metadata

**Analog search scope:** `examples/phoenix_host/`, `test/crosswake/guides/`, `docs/`, `.github/workflows/`
**Files scanned:** 10 (config.exs, mix.exs, endpoint.ex, playwright.config.ts, seeds.exs, quick_start_adoption_drift_test.exs, phase23-proof.yml, QUICK_START.md path pattern, docs/, examples/)
**Pattern extraction date:** 2026-06-21
