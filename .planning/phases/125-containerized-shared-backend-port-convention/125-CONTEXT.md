# Phase 125: Containerized Shared Backend + Port Convention - Context

**Gathered:** 2026-06-21
**Status:** Ready for planning

<domain>
## Phase Boundary

Deliver one-command Dockerized boot of the `examples/phoenix_host` demo backend,
reachable from all three runtimes (web + iOS simulator via `localhost:4700`,
Android emulator via `10.0.2.2:4700`), with fast iteration loops (polling
live-reload), persistent named-volume SQLite, a lean build context, and a
committed, reusable port convention so the demo never collides with the
maintainer's other concurrently-running OSS lib demos.

**Requirements:** DOCKER-01..05, PORT-01..03 (see REQUIREMENTS.md — locked).

**NOT in this phase:** native iOS/Android dev-wiring (Phase 126), launch
orchestration/banner (Phase 127), visual collateral + see_it_run guide (Phase 128).
</domain>

<decisions>
## Implementation Decisions

All four gray areas were researched (parallel subagents covering Elixir/Phoenix
idiom, cross-ecosystem DX, and the repo's own values) and resolved into one
coherent, mutually-reinforcing set. Confidence high on all four.

### Port 4700 — Full Migration (chosen over env-overlay-only)
- **D-01:** Make **4700** the single canonical default everywhere; rip out `4002`
  entirely. No two-numbers-in-the-repo. This is the only option coherent with the
  repo's "no drift / honesty" culture and matches the already-locked v15.0 plan
  ("4002 → 4700 across config/scripts/Playwright").
- **D-02:** Blast radius is tiny and grep-confirmed — the port default (moving to
  `runtime.exs`, see D-04), `examples/phoenix_host/playwright.config.ts` (2 lines),
  and `examples/QUICK_START.md` (~9 refs). No other source references `4002`.
- **D-03:** The existing doc-contract test `quick_start_adoption_drift_test.exs`
  derives the port from config dynamically — it self-updates and will fail loudly
  on any doc line still showing the old port. Run it first after the change.

### Config Structure — Conventional Split (chosen over single config.exs)
- **D-04:** Introduce `config/dev.exs` + `config/runtime.exs` (no `prod.exs`/`test.exs`
  needed for a demo). The current single `config.exs` is unconventional; the demo is
  not actually minimal (70+ source files), and a newcomer cloning it expects the
  standard Phoenix layout (least surprise). `config.exs` keeps the base
  (json_library, adapter, secret_key_base placeholder, companions, repo, router URL).
- **D-05:** `runtime.exs` owns `http: [ip: …, port: …]` — bind `0.0.0.0` in the
  container / `127.0.0.1` native, `port` from env **defaulting to 4700** (this is
  where D-01's default now lives). Also reads `DATABASE_PATH` (see D-08). Guard the
  container-vs-native branch carefully — `runtime.exs` also runs under `:test`, so
  prefer a `config_env()`-aware or explicit-env-var gate that does not flip test to
  `0.0.0.0`.
- **D-06:** `dev.exs` owns dev-only behavior: `code_reloader: true`,
  `check_origin: false`, and `live_reload` with **polling `interval: 1500`** (macOS
  Docker bind-mounts don't propagate filesystem events), watching
  `~r"lib/.+\.ex(s)?$"` and `~r"priv/static/.+\.(css|js)$"`. **Never** watch
  `_build/` or `deps/` (reload storms).
- **D-07:** Add `{:phoenix_live_reload, "~> 1.5", only: :dev}` to `mix.exs` AND add
  the `Phoenix.LiveReloader` / `Phoenix.CodeReloader` plugs (guarded by
  `code_reloading?`) to the endpoint — the config keys alone do nothing without the
  plugs. There is no esbuild/Tailwind pipeline; styles are static/inline, so no
  asset watchers are configured.

### Committed SQLite `.db` — Don't Commit; seeds.exs is single source of truth
- **D-08:** SQLite lives only in the **named volume**; `seeds.exs` + migrations are
  the single source of truth. The `crosswake_example.db*` files already in the tree
  are **untracked runtime artifacts** — commit `80a18c3` already gitignored them.
  They are **NOT** a proof fixture (proof fixtures = iOS `Info.plist`/`Info-Dev.plist`
  + Android assets; every proof test builds its own temp DB and never reads this file).
- **D-09:** Container entrypoint runs idempotently: `mix ecto.create --quiet` →
  `mix ecto.migrate --quiet` → `mix run priv/repo/seeds.exs` → `exec mix phx.server`,
  pointed at a DB path **inside the named volume** (e.g. `/data/crosswake_example.db`
  via `DATABASE_PATH` read in `runtime.exs`). `seeds.exs` is already idempotent
  (`delete_all` → insert 1 deck + 3 cards) and reproduces the demo exactly.
- **D-10:** Add `crosswake_example.db*` to `.dockerignore` (alongside the locked
  exclusion list) so untracked tree artifacts never bake into the image and shadow
  the volume. The stale `mix.exs` test-alias comment about "the committed .db" should
  be corrected.

### PORT-REGISTRY — Hybrid (reserved block + table + simple algorithm)
- **D-11:** `docs/PORT-REGISTRY.md` documents a **reserved 4700–4799 block** for the
  maintainer's OSS lib demos, with explicit exclusions (3000 React/Next, 4000 Phoenix,
  4002 old demo default, 5000 = macOS AirPlay, 5173 Vite, 8080, IANA ephemeral 49152+).
  Allocation rule: "take next free port in block, one per lib, commit
  `PORT=`/`COMPOSE_PROJECT_NAME=` in `.env`, add a registry row." Seed row:
  `crosswake = 4700`. Lowest-friction scheme for a solo maintainer — a table beats a
  hash algorithm.
- **D-12:** Document the `COMPOSE_PROJECT_NAME` caveat honestly: it namespaces
  container/network/volume names, **NOT** host port bindings — the unique committed
  port is the real collision guard. Include the Android `10.0.2.2` = host-loopback note.
- **D-13:** Drift-proof the registry the same way as existing guides — a source-derived
  doc-contract test (new `test/crosswake/guides/port_registry_test.exs` or a block in
  the existing drift test) that extracts the committed `PORT` from `.env`/config and
  asserts the registry's crosswake row matches, and that it mentions
  `COMPOSE_PROJECT_NAME` and `10.0.2.2`. Satisfies DOCS-03 / PORT-03 culture.

### Claude's Discretion (planner/researcher to settle)
- Docker base image flavor (hexpm/elixir Debian vs Alpine). Note: `ecto_sqlite3`
  compiles a NIF — musl(Alpine) vs glibc(Debian) affects build; mix.exs requires
  **Elixir ~> 1.19**, so the base tag must provide it. Recommend Debian-slim unless
  image size dominates.
- Exact `runtime.exs` container-vs-native gate mechanism (env var name, e.g.
  `BIND_ALL`/`DOCKER`, vs `config_env()`), keeping `:test` on loopback.
- Whether to guard the entrypoint re-seed with `count == 0` so UI-entered demo data
  survives a container restart (nice-to-have for a live demo; default re-seed is fine).
- Where exactly `.env` / `docker-compose.yml` sit (`examples/phoenix_host/.env` is
  named by the success criteria; compose likely `examples/` or `examples/phoenix_host/`).
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & roadmap
- `.planning/REQUIREMENTS.md` — DOCKER-01..05, PORT-01..03 (locked requirement text).
- `.planning/ROADMAP.md` §"Phase 125" — goal + 5 success criteria (the acceptance bar).

### Code to modify / extend
- `examples/phoenix_host/config/config.exs` — current single config; base keys stay,
  `http`/port move to `runtime.exs`, dev reload to `dev.exs`.
- `examples/phoenix_host/mix.exs` — add `phoenix_live_reload`; correct stale `.db`
  test-alias comment; deps include `ecto_sqlite3`, `bandit`, phoenix 1.8 / LV 1.1.
- `examples/phoenix_host/lib/` endpoint module — add LiveReloader/CodeReloader plugs.
- `examples/phoenix_host/priv/repo/seeds.exs` + `priv/repo/migrations/` — source of
  truth for demo data (idempotent; sufficient).
- `examples/phoenix_host/playwright.config.ts` — port `4002` → `4700` (2 lines).
- `examples/QUICK_START.md` — port refs `4002` → `4700` (~9), add Docker path.

### Drift-test culture (mirror these)
- `test/crosswake/guides/quick_start_adoption_drift_test.exs` — derives port from
  config; the pattern to mirror for the new PORT-REGISTRY test.
- `test/crosswake/guides/*_test.exs` — existing guide doc-contract tests (DOCS-03).

### Files to create
- `examples/phoenix_host/.env` — `COMPOSE_PROJECT_NAME=crosswake`, `PORT=4700`.
- `examples/phoenix_host/Dockerfile` (multi-stage, layer-ordered) + `.dockerignore`.
- `docker-compose.yml` (location per planner) — bind-mount source, named volumes for
  `deps`/`_build`/`node_modules`/SQLite, map host `4700`.
- `docs/PORT-REGISTRY.md` — reusable convention + crosswake seed row.

### Vision / values context (skimmed during research)
- `prompts/crosswake-elixir-oss-dna.md` — "install truth is product truth", docs-contract
  checks prevent README drift, first-integrator legibility > minimalism-for-its-own-sake.
- `prompts/crosswake-research-synthesis.md`, `prompts/crosswake-brand-book.md` —
  voice/tone for PORT-REGISTRY + docs (brand-voiced but honest, no native overclaim).
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `quick_start_adoption_drift_test.exs` — proven source-derived port-extraction +
  doc-scan pattern; copy it for the PORT-REGISTRY drift guard (D-13).
- `seeds.exs` — already idempotent and minimal; no change needed to become the
  single source of truth (D-08).
- `mix.exs` aliases (`setup`, `ecto.setup`, `ecto.reset`, `test`) — entrypoint reuses
  `ecto.create`/`ecto.migrate`/`seeds.exs` directly (D-09).

### Established Patterns
- Doc-contract tests assert docs match source (DOCS-03 / honesty culture) — every
  port/route/command claim must be guarded, not just written.
- Native PROOF FIXTURES are sacred and must stay untouched (iOS plist + Android
  assets) — the SQLite `.db` is explicitly NOT one of them (D-08).
- Phoenix 1.8 is in deps; conventional `config.exs`/`dev.exs`/`runtime.exs` layout is
  the least-surprise target for newcomers (D-04).

### Integration Points
- Endpoint binds `ip`/`port` (moving to `runtime.exs`); `0.0.0.0` needed inside the
  container for host reachability; Android emulator reaches host via `10.0.2.2`.
- Docker named volumes for `deps`/`_build`/`node_modules` + SQLite; source bind-mounted
  for polling live-reload.
</code_context>

<specifics>
## Specific Ideas

- The maintainer wanted a single coherent, one-shot recommendation set (not
  sequential one-by-one questions) — delivered via four parallel research subagents,
  synthesized into the mutually-reinforcing decisions above.
- Coherence threads: the port default (D-01) and the volume DB path (D-09) both land
  in `runtime.exs` (D-05); the PORT-REGISTRY (D-11) is guarded by the same
  doc-contract mechanism that guards the port (D-03/D-13).
- Live-reload polling interval anchored at **1500ms** (500ms flickers, 2000ms feels
  sluggish on Docker-for-Mac).
</specifics>

<deferred>
## Deferred Ideas

- Dockerizing the Android emulator — explicitly OUT OF SCOPE (nested virt on macOS is
  slow/fragile; native AVD is better). Recorded in REQUIREMENTS "Out of Scope".
- Native iOS Dev scheme / Android dev flavor wiring → **Phase 126**.
- `bin/see-it-run.sh` launch orchestration + ASCII banner → **Phase 127**.
- Three-runtime screenshots, screen recording, `guides/see_it_run.md`, README/QUICK_START
  routing → **Phase 128**.

None — discussion stayed within phase scope.
</deferred>

---

*Phase: 125-containerized-shared-backend-port-convention*
*Context gathered: 2026-06-21*
