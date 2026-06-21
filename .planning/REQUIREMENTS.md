# Requirements: Crosswake — v15.0 See It Run

**Defined:** 2026-06-21
**Core Value:** Replace host-owned generated shell code with standalone SPM/Maven dependencies, enforcing strict delegate-based customization to eliminate the "eject trap" and boilerplate for adopters.
**Milestone Goal:** Make it trivial and delightful to boot the web, iOS-simulator, and Android-emulator versions against one shared backend and compare them — Dockerized one-command DX, no port collisions, fast rebuilds, additive native dev-wiring that preserves the proof artifacts, committed visual collateral, a printed URL/route banner, and a reader-empathy guide.

## v1 Requirements

Requirements for this milestone. Each maps to a roadmap phase.

### DOCKER — Containerized shared backend

- [ ] **DOCKER-01**: A developer can boot the full shared demo backend with one command (`docker compose up`) from a clean checkout, with no local Elixir/Erlang/Node/SQLite toolchain required.
- [ ] **DOCKER-02**: The demo Dockerfile is multi-stage and layer-ordered so that editing application or style code does not re-download or re-compile dependencies (deps are keyed on `mix.exs`/`mix.lock` only).
- [ ] **DOCKER-03**: In-container live reload reflects Elixir/HEEx/CSS edits using the Phoenix polling reloader, with source bind-mounted and `deps`/`_build`/`node_modules` in named volumes.
- [ ] **DOCKER-04**: The demo SQLite database persists in a named volume (never a macOS bind-mount) and is auto-created/seeded on first boot; the native `mix phx.server` path remains supported and documented.
- [ ] **DOCKER-05**: A `.dockerignore` keeps the build context lean and prevents host/container binary mismatches (excludes `_build`, `deps`, `node_modules`, `priv/static`, `.git`, `.planning`, `.claude`, evidence/artifacts).

### PORT — Conflict-free multi-lib convention

- [ ] **PORT-01**: Crosswake's demo binds a unique, stable, committed host port (4700) via `COMPOSE_PROJECT_NAME` + a committed `.env`, so it does not collide with the maintainer's other concurrently running OSS lib demos.
- [ ] **PORT-02**: The same stable port is reachable by all three runtimes: web and iOS simulator via `localhost:4700`, Android emulator via `10.0.2.2:4700`.
- [ ] **PORT-03**: A reusable PORT-REGISTRY document records the per-lib port-allocation convention so the maintainer's other repos can adopt it consistently.

### NDEV — Additive native dev-wiring (proof posture intact)

- [ ] **NDEV-01**: The iOS host gains an additive `Dev` scheme + `Info-Dev.plist` (a localhost cleartext ATS exception) + a dev fixture pointing at `http://localhost:4700`, without modifying the checked-in public-coordinate proof fixtures or `Info.plist`.
- [ ] **NDEV-02**: The Android host gains an additive `dev` product flavor + a network-security-config permitting `10.0.2.2` cleartext + dev assets pointing at `http://10.0.2.2:4700`, with a separate non-autoVerify dev intent-filter, without modifying the checked-in proof assets.
- [ ] **NDEV-03**: From the running dev build, the iOS simulator and Android emulator load Crosswake routes served by the local shared backend, documented with exact CLI launch commands.

### LAUNCH — Orchestration + launch banner

- [ ] **LAUNCH-01**: A single friendly entrypoint (`bin/see-it-run.sh`, with an optional `mix crosswake.demo` alias) boots the shared backend and prints a brand-voiced, plain-ASCII banner listing the key URLs/routes, the exact next commands for each runtime, and an honest "what's proven / what needs a native build" block.
- [ ] **LAUNCH-02**: The launch helper advisorily boots the iOS simulator and/or Android emulator when the toolchain is present, and prints clear guidance (not an opaque failure) when the toolchain is absent.

### COLL — Seeing is believing (visual collateral)

- [ ] **COLL-01**: The repo includes committed screenshots of all three runtimes (web, iOS simulator, Android emulator) running against the one shared backend, honestly labeled as advisory native evidence.
- [ ] **COLL-02**: A short screen recording of the three-runtime comparison is captured and linked from the docs/README.

### DOCS — Reader-empathy guide + routing

- [ ] **DOCS-01**: A new `guides/see_it_run.md` with a gameplan summary at the top and digestible, JTBD-driven sections is added to the ExDoc "Start" group after README, linking to (not duplicating) `examples/QUICK_START.md`.
- [ ] **DOCS-02**: README and QUICK_START route readers to the new guide and the one-command Docker path while preserving honest support labels (no native overclaim).
- [ ] **DOCS-03**: Guide truth (ports, routes, commands) is guarded by source-derived doc-contract tests, consistent with the existing `test/crosswake/guides/*_test.exs` culture.

## Future Requirements

Deferred behind the v15.0 DX wedge; tracked but not in this roadmap.

- **LIFE-01 / LIFE-02**: Native runtime evidence and generated-shell upgrade/regenerate lifecycle hardening.
- **SYNCP-01**: Offline-sync productization (turn the proven outbox/island pattern into a more turnkey adopter surface).
- **DASH-01**: Operator metrics / offline-adoption dashboard (candidate `crosswake_dashboard` LiveDashboard package).
- **NTV-01**: Extend storage budgets to native physical disk space.
- **Companion package extraction**: pull companion seams (Sigra/Chimeway/Rindle/Threadline) into first-party packages.
- **Capability / commerce breadth**: new bounded native capability families or provider adapters.

## Out of Scope

Explicitly excluded from v15.0 to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Web landing-page (`/`) "demo hub" redesign | Maintainer chose lean scope (banner + guide); branded landing redesign deferred to keep this milestone focused on boot DX. |
| Dockerizing the Android emulator | Nested virtualization/KVM on macOS makes it slow and fragile with no benefit over the native AVD. |
| Switching the demo DB to Postgres by default | Adds a service/dependency against the "no micro-deps" goal; SQLite (single Phoenix writer) in a named volume is sufficient. Postgres remains documented as opt-in only. |
| Fully hermetic one-command boot of iOS sim + Android emulator | Xcode/SDK/JDK environment sensitivity makes it dishonest to claim; native boot stays an advisory helper. |
| Folding a `--dev` flag into `mix crosswake.gen.shell` | Dev-wiring is added to the checked-in hosts directly this milestone; generator integration is a possible follow-on. |
| Mutating the checked-in public-coordinate proof fixtures/assets | Would erode the "example hosts are proof artifacts" posture; all dev-wiring must be additive. |

## Traceability

Which phases cover which requirements. Populated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| DOCKER-01 | Phase 125 | Pending |
| DOCKER-02 | Phase 125 | Pending |
| DOCKER-03 | Phase 125 | Pending |
| DOCKER-04 | Phase 125 | Pending |
| DOCKER-05 | Phase 125 | Pending |
| PORT-01 | Phase 125 | Pending |
| PORT-02 | Phase 125 | Pending |
| PORT-03 | Phase 125 | Pending |
| NDEV-01 | Phase 126 | Pending |
| NDEV-02 | Phase 126 | Pending |
| NDEV-03 | Phase 126 | Pending |
| LAUNCH-01 | Phase 127 | Pending |
| LAUNCH-02 | Phase 127 | Pending |
| COLL-01 | Phase 128 | Pending |
| COLL-02 | Phase 128 | Pending |
| DOCS-01 | Phase 128 | Pending |
| DOCS-02 | Phase 128 | Pending |
| DOCS-03 | Phase 128 | Pending |

**Coverage:**
- v1 requirements: 18 total
- Mapped to phases: 18
- Unmapped: 0

---
*Requirements defined: 2026-06-21*
*Last updated: 2026-06-21 — traceability populated during roadmap creation*
