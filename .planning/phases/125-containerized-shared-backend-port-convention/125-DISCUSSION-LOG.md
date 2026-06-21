# Phase 125: Containerized Shared Backend + Port Convention - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-21
**Phase:** 125-containerized-shared-backend-port-convention
**Areas discussed:** Port 4700 blast radius, Config restructure depth, Committed .db fate, PORT-REGISTRY design

The maintainer selected all four gray areas and requested a single, coherent,
researched, one-shot recommendation set (rather than sequential one-by-one
questions). Four parallel research subagents (one per area) investigated
Elixir/Phoenix/Ecto idiom, cross-ecosystem DX lessons, the repo's own research
under `prompts/`, and the existing honesty/no-drift culture. Results synthesized
into the mutually-reinforcing decisions in CONTEXT.md. All four returned high
confidence; two confirmed a partial decision already present in the repo.

---

## Port 4700 blast radius

| Option | Description | Selected |
|--------|-------------|----------|
| A — Full migration | 4700 becomes the single committed default everywhere; rip out 4002 (config, Playwright, docs, native). | ✓ |
| B — Env-overlay only | Keep 4002 as code default; set 4700 only via `.env`/compose. Smaller diff, two numbers in play. | |

**User's choice:** A (recommended). Coherent with the repo's no-drift culture and
the already-locked v15.0 plan; blast radius is tiny (config default → runtime.exs,
playwright.config.ts 2 lines, QUICK_START.md ~9 refs) and the existing drift test
self-derives the port.
**Notes:** The drift test `quick_start_adoption_drift_test.exs` will fail loudly on
any missed doc line — run it first after the change.

---

## Config restructure depth

| Option | Description | Selected |
|--------|-------------|----------|
| A — Conventional split | Introduce `config/dev.exs` + `config/runtime.exs`; reload/code_reloader in dev, ip/port from env in runtime. Least surprise for Phoenix devs. | ✓ |
| B — Keep single config.exs | Preserve the one-file look; gate dev-only behavior with inline `config_env()`/env checks. | |

**User's choice:** A (recommended). The demo isn't actually minimal (70+ source
files); newcomers expect standard Phoenix layout and look in `dev.exs` first.
Requires adding `phoenix_live_reload` to deps + the LiveReloader/CodeReloader plugs.
**Notes:** Polling live_reload `interval: 1500` for Docker-on-macOS; watch
`lib/**/*.ex(s)` + `priv/static/*.{css,js}`, never `_build`/`deps`.

---

## Committed .db fate

| Option | Description | Selected |
|--------|-------------|----------|
| A — Keep committed .db | Native path opens the committed DB; Docker volume gets a fresh seeded copy. | |
| B — Stop committing; seeds.exs single source | Both paths create+seed from migrations+seeds; remove the binary blob. | ✓ |

**User's choice:** B (recommended). The `.db*` files were already gitignored by
commit `80a18c3` — the tree copies are untracked runtime artifacts, NOT a proof
fixture (proof fixtures = iOS plist + Android assets; proof tests build their own
temp DBs). `seeds.exs` is already idempotent and sufficient.
**Notes:** Idempotent entrypoint (create/migrate/seed against named-volume DB path);
add `crosswake_example.db*` to `.dockerignore`; correct the stale mix.exs comment.

---

## PORT-REGISTRY design

| Option | Description | Selected |
|--------|-------------|----------|
| Reserved-range table | Hand-maintained lib → port table. | |
| Allocation algorithm | Deterministic hash/next-free derivation, no central table. | |
| Hybrid | Reserved 47xx block + short written rule + seed table. | ✓ |

**User's choice:** Hybrid (recommended). Lowest-friction for a solo maintainer; a
table beats a hash function. Reserved 4700–4799, explicit exclusions (3000/4000/4002/
5000-AirPlay/5173/8080/ephemeral), rule = "next free port, one per lib, commit in
`.env`, add a row." Seed: crosswake=4700.
**Notes:** Document the `COMPOSE_PROJECT_NAME` caveat (namespaces containers/networks/
volumes, NOT host ports) and the Android `10.0.2.2` note; guard with a source-derived
doc-contract test (DOCS-03 / PORT-03).

---

## Claude's Discretion

- Docker base image flavor (Debian-slim vs Alpine; `ecto_sqlite3` NIF musl/glibc; must
  provide Elixir ~> 1.19).
- Exact `runtime.exs` container-vs-native bind gate (keep `:test` on loopback).
- Whether to guard the entrypoint re-seed with `count == 0` (preserve UI-entered data).
- Exact location of `docker-compose.yml`.

## Deferred Ideas

- Dockerizing the Android emulator — explicitly out of scope.
- Native dev-wiring → Phase 126; launch orchestration/banner → Phase 127;
  collateral + see_it_run guide → Phase 128.
