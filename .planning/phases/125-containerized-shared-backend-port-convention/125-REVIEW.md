---
phase: 125-containerized-shared-backend-port-convention
reviewed: 2026-06-21T00:00:00Z
depth: standard
files_reviewed: 15
files_reviewed_list:
  - examples/phoenix_host/config/config.exs
  - examples/phoenix_host/config/dev.exs
  - examples/phoenix_host/config/runtime.exs
  - examples/phoenix_host/mix.exs
  - examples/phoenix_host/lib/crosswake_example/endpoint.ex
  - examples/phoenix_host/playwright.config.ts
  - examples/phoenix_host/Dockerfile
  - examples/phoenix_host/.dockerignore
  - examples/phoenix_host/entrypoint.sh
  - examples/phoenix_host/docker-compose.yml
  - examples/phoenix_host/.env
  - docs/PORT-REGISTRY.md
  - examples/QUICK_START.md
  - test/crosswake/guides/port_registry_test.exs
  - test/crosswake/guides/quick_start_adoption_drift_test.exs
findings:
  critical: 3
  warning: 6
  info: 4
  total: 13
status: issues_found
---

# Phase 125: Code Review Report

**Reviewed:** 2026-06-21
**Depth:** standard
**Files Reviewed:** 15
**Status:** issues_found

## Summary

This phase containerizes the Phoenix demo host (config split, multi-stage
Dockerfile, docker-compose with named volumes + SQLite, shell entrypoint) and
adds a port-convention registry with drift tests. The documentation, port
registry, and drift tests are solid and self-consistent. **However, the
containerization has three structural defects that will prevent
`docker compose up` from working at all from a clean checkout** — the very
"one-command boot" the phase promises (LAUNCH/DOCKER reqs). The most serious is
that the build cannot resolve the `{:crosswake, path: "../.."}` path dependency
because the parent library lives outside the Docker build context. Secondary
issues concern volume layering that discards the image's compiled artifacts, and
a runtime image that ships a full Elixir/Mix toolchain running in `MIX_ENV=dev`
bound to `0.0.0.0` with `check_origin: false`.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Docker build cannot resolve the `crosswake` path dependency — `docker compose up` fails from clean checkout

**File:** `examples/phoenix_host/mix.exs:38`, `examples/phoenix_host/Dockerfile:11-19`, `examples/phoenix_host/docker-compose.yml:3`

**Issue:** `mix.exs` declares `{:crosswake, path: "../.."}` — a path dependency
on the parent crosswake library two directories up. The docker-compose build
context is `build: .` (i.e. `examples/phoenix_host`), so the Dockerfile only
copies files from inside `examples/phoenix_host`. The parent library at `../..`
is **outside the build context and is never copied into the image**. When
`RUN mix deps.get` (Dockerfile:12) and `RUN mix deps.compile` (Dockerfile:19)
execute, Mix cannot find the `crosswake` path dep (`../..` resolves to `/`
inside the container, where the library does not exist). The build fails.

This defeats the central goal of the phase ("Boot the shared backend with one
command", QUICK_START.md:24-29). The native path (`mix setup`) works because
`../..` resolves correctly on the host, which likely masked this during testing.

**Fix:** Set the build context to the repo root and point the Dockerfile at the
example, copying the parent library in. For example, in `docker-compose.yml`:
```yaml
services:
  phoenix:
    build:
      context: ../..                      # repo root — includes the crosswake lib
      dockerfile: examples/phoenix_host/Dockerfile
```
and update the Dockerfile COPY paths accordingly (copy `mix.exs`/`mix.lock` and
`config/`, `lib/`, `priv/` from `examples/phoenix_host/`, plus the parent
library's `mix.exs`/`lib`/`priv` so the path dep resolves). Then add a build
that validates the image boots in CI so this regression is caught.

### CR-02: docker-compose volume layering shadows the image's compiled deps/build, so first boot has empty `deps`/`_build`

**File:** `examples/phoenix_host/docker-compose.yml:10-14`

**Issue:** The service mounts three volumes that overlay the image filesystem:
```yaml
- .:/app                   # host source shadows the entire image /app
- deps_cache:/app/deps     # named volume, EMPTY on first run
- build_cache:/app/_build  # named volume, EMPTY on first run
```
On the first `docker compose up`, the named volumes `deps_cache` and
`build_cache` are empty and mount over `/app/deps` and `/app/_build`,
**hiding the deps and bytecode the Dockerfile just compiled** (Dockerfile:19).
Additionally `.:/app` replaces the image's `/app` source tree with the host
directory. The net effect: all build-stage compilation work is discarded at
runtime, and the entrypoint's first `mix ecto.create` (entrypoint.sh:4) runs
against empty `deps`, forcing a full `deps.get` + compile inside the container
on first boot — or failing outright if the path dep (CR-01) still can't be
resolved from the host bind-mount context. The multi-stage build's caching
intent (Dockerfile:1-2 comments) is nullified for runtime.

**Fix:** Decide on one strategy and make it coherent:
- If the goal is fast iterative dev with live-reload, drop the build-stage
  `deps.compile` (it is thrown away) and let the entrypoint populate the
  named volumes on first run (`mix deps.get && mix deps.compile` before
  migrations), guarded so it is skipped when already populated.
- If the goal is a self-contained image, remove the `.:/app` bind-mount and the
  `deps_cache`/`build_cache` volumes so the image's compiled artifacts are used.
  Keep only `sqlite_data:/data`.
Document which mode is intended; the current mix of both gives neither.

### CR-03: Runtime image ships full dev toolchain in `MIX_ENV=dev`, binds `0.0.0.0`, with `check_origin: false` and a static secret

**File:** `examples/phoenix_host/Dockerfile:25`, `examples/phoenix_host/docker-compose.yml:6`, `examples/phoenix_host/config/dev.exs:5`, `examples/phoenix_host/config/config.exs:12`

**Issue:** The container runs `MIX_ENV=dev` (Dockerfile:25) and is started with
`mix phx.server` via the entrypoint, while `docker-compose.yml:6` sets
`BIND_ALL=true`, so runtime.exs binds the listener to `{0,0,0,0}`
(runtime.exs:6-7) — reachable from anywhere that can route to the host. In dev
mode this combines several unsafe defaults:
- `check_origin: false` (dev.exs:5) disables WebSocket/CSRF origin checking on a
  publicly-bindable socket.
- `code_reloader: true` + `Phoenix.CodeReloader`/`LiveReloader` plugs are active
  (endpoint.ex:12-16), exposing the live-reload socket and on-disk recompilation
  surface to any client that can reach `0.0.0.0:4700`.
- `secret_key_base` is the hardcoded constant `String.duplicate("a", 64)`
  (config.exs:12) and `signing_salt` is the literal `"crosswake"`. Session
  cookies and LiveView state are signed with a publicly-known key, so any client
  can forge a valid session/CSRF token.

Binding `0.0.0.0` is appropriate inside Docker (the comment at runtime.exs:3 is
correct), but doing so in `dev` mode with a known signing key and disabled origin
checks means anyone on the same network as the host can drive the dev server,
forge sessions, and trigger code reload. For a demo this is "works on my
laptop"-acceptable only if the port is never exposed beyond loopback — but
`ports: "4700:4700"` (docker-compose.yml:8) publishes on all host interfaces.

**Fix:** At minimum, document that this is a localhost-only demo and bind the
published port to loopback: `ports: - "127.0.0.1:4700:4700"`. Better: confirm the
demo genuinely needs dev-mode live-reload inside Docker; if not, run a
`prod`-style config with a generated `SECRET_KEY_BASE` env var (read in
runtime.exs) and `check_origin` enabled. If dev mode is intentional for
live-reload, keep the loopback port binding and add an explicit security note in
QUICK_START.md that the container must not be exposed.

## Warnings

### WR-01: `entrypoint.sh` is not idempotent across schema changes — `ecto.migrate` will fail hard under `set -e` if a partial/legacy DB exists

**File:** `examples/phoenix_host/entrypoint.sh:1-7`

**Issue:** With `set -e`, any non-zero exit aborts the container. `mix ecto.create`
is safe when the DB exists (it no-ops), but if the persisted SQLite file in the
`sqlite_data` volume was created by an older schema or a partial migration, a
failing `mix ecto.migrate` will crash-loop the container with no recovery path —
the volume persists the bad DB across restarts (docker-compose.yml:14). The
header comment in the Dockerfile calls this "idempotent DB provisioning"
(Dockerfile:31), but re-running seeds is the only idempotent part. There is no
guard, retry, or reset affordance.

**Fix:** Keep `set -e` but add `set -u` and `set -o pipefail` for shell safety,
and document a reset path (`docker compose down -v`) in QUICK_START.md
troubleshooting. Optionally detect migration failure and emit a clear message
telling the user to drop the volume rather than crash-looping silently.

### WR-02: `entrypoint.sh` missing `set -u` / `pipefail` — unset-var and pipe failures pass silently

**File:** `examples/phoenix_host/entrypoint.sh:2`

**Issue:** Only `set -e` is enabled. POSIX `sh` here will silently treat unset
variables as empty and will not fail on errors in the left side of a pipe. While
the current script has no variable expansions, the script is the documented
extension point for "migrations+seeds+server", and the missing hardening is a
latent footgun for the next edit.

**Fix:**
```sh
#!/bin/sh
set -eu
# pipefail is not POSIX; if staying on /bin/sh, leave it out, otherwise:
# (only if switching to bash) set -o pipefail
```
Note `pipefail` is not POSIX `sh`; either keep `sh` with `set -eu` or switch the
shebang to `#!/bin/bash` and use `set -euo pipefail`.

### WR-03: `.dockerignore` excludes `mix.lock`'s sibling lock guarantees but the image still risks unpinned deps if `mix.lock` is absent

**File:** `examples/phoenix_host/Dockerfile:11`, `examples/phoenix_host/.dockerignore:1-30`

**Issue:** The Dockerfile `COPY mix.exs mix.lock ./` requires `mix.lock` to be
present in the build context. `mix.lock` currently exists on disk but is **not
yet committed to git** (verified via `git ls-files`). If the phase ships without
committing `mix.lock`, a clean checkout has no lock file, `COPY ... mix.lock`
fails, and even if made optional, `mix deps.get` would resolve unpinned versions
— non-reproducible builds. `.dockerignore` does not exclude `mix.lock` (good),
but nothing guarantees it is tracked.

**Fix:** Commit `examples/phoenix_host/mix.lock` as part of this phase and add a
guard/test asserting it is tracked. Reproducible Docker builds depend on it.

### WR-04: Dockerfile runtime stage copies build-stage `MIX_ENV=dev` artifacts but never compiles the application

**File:** `examples/phoenix_host/Dockerfile:19, 28`

**Issue:** The build stage runs `mix deps.compile` (deps only) but never
`mix compile` (the application itself). The runtime stage copies `/app` and
relies on `mix phx.server` to compile the app on first boot. Combined with CR-02
(the `.:/app` + empty `_build` volume), the app is recompiled at container start
every fresh run, so the build-stage `deps.compile` is the only precompiled piece
— and per CR-02 it is shadowed by the empty `deps_cache` volume anyway. The build
does meaningful work that runtime discards.

**Fix:** Either add `RUN mix compile` to the build stage and stop bind-mounting
over `_build`/`deps` (self-contained image), or remove `mix deps.compile` from
the build stage and let the entrypoint compile into the named volumes once. Align
this with the CR-02 decision.

### WR-05: Runtime image runs as `root`

**File:** `examples/phoenix_host/Dockerfile:22-36`

**Issue:** Neither stage creates or switches to a non-root user. The container
runs `mix phx.server` as `root`, and `/root/.mix` is copied in (Dockerfile:29).
A compromise of the dev-mode server (which has code-reload enabled and a known
signing key — see CR-03) executes as root inside the container, and any
host-mounted paths (the `.:/app` bind-mount) are written as root, which can leave
root-owned files on the host.

**Fix:** Add a non-root user in the runtime stage and `USER` switch, ensuring the
`/data` volume and `/app` are writable by it:
```dockerfile
RUN useradd --create-home --uid 1000 app && mkdir -p /data && chown -R app /app /data
USER app
```
(Move Mix home to the app user accordingly.)

### WR-06: `docker-compose.yml` loads `.env` for app secrets but `.env` is committed to git

**File:** `examples/phoenix_host/docker-compose.yml:4`, `examples/phoenix_host/.env`

**Issue:** `env_file: .env` loads the committed `.env` (tracked in git, contents
`COMPOSE_PROJECT_NAME=crosswake` / `PORT=4700`). The `.dockerignore` correctly
excludes `.env` from the image with the comment "Runtime secrets — never bake
into the image" (.dockerignore:22-23), signalling intent to treat `.env` as a
secrets file. But the file is git-tracked and would be the natural place a user
adds a real `SECRET_KEY_BASE` (per the CR-03 fix), at which point a committed
`.env` leaks secrets. The current values are non-sensitive, so this is a latent
hazard, not an active leak.

**Fix:** Keep the committed defaults as `.env.example`, gitignore the real
`.env`, and have docker-compose read `.env` (untracked) falling back to
documented defaults. Update QUICK_START.md to `cp .env.example .env`.

## Info

### IN-01: `config.exs:12` hardcoded `secret_key_base` flagged as note for the record

**File:** `examples/phoenix_host/config/config.exs:12`

**Issue:** `secret_key_base: String.duplicate("a", 64)` is a deterministic,
publicly-known key compiled into all environments. Acceptable for a pure local
demo, but see CR-03 — it becomes a real vulnerability the moment the port is
network-exposed (which docker-compose does).

**Fix:** Move to a `SECRET_KEY_BASE` env var resolved in runtime.exs with the
constant only as a dev fallback.

### IN-02: `config.exs:18` commented-out config line left in source

**File:** `examples/phoenix_host/config/config.exs:18`

**Issue:** `# show_sensitive_data_on_connection_error: true # dev only — omitted`
is dead/commented-out config. The same setting is correctly placed in
`dev.exs:15`, making the comment redundant noise.

**Fix:** Delete line 18; the dev.exs placement is the canonical home.

### IN-03: `runtime.exs` uses `String.to_integer/1` on `PORT` with no validation

**File:** `examples/phoenix_host/config/runtime.exs:12`

**Issue:** `String.to_integer(System.get_env("PORT") || "4700")` raises an
`ArgumentError` with an opaque stacktrace if `PORT` is set to a non-numeric value
(e.g. a typo in `.env`). Minor, but a clearer failure helps the "first-run DX"
goal.

**Fix:** Validate and emit a friendly error, e.g. `case Integer.parse(...)` with
a `raise "PORT must be an integer, got: #{value}"` fallback.

### IN-04: `BIND_ALL`/`PORT`/`DATABASE_PATH` env contract is undocumented in the registry/quick-start

**File:** `examples/phoenix_host/config/runtime.exs:3-22`, `docs/PORT-REGISTRY.md`

**Issue:** `runtime.exs` introduces three runtime knobs (`BIND_ALL`, `PORT`,
`DATABASE_PATH`). Only `PORT` is documented (PORT-REGISTRY.md). `BIND_ALL` and
`DATABASE_PATH` are set in docker-compose but never explained, so a user copying
the pattern to another lib (the explicit reuse goal of PORT-REGISTRY.md:3-6) has
no reference for them.

**Fix:** Add a short "Runtime env vars" subsection to PORT-REGISTRY.md or
QUICK_START.md documenting `BIND_ALL`, `PORT`, `DATABASE_PATH` and their defaults.

---

_Reviewed: 2026-06-21_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
