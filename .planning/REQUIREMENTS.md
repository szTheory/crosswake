# Requirements: Crosswake v16.0 — Companion Extraction & Package-Family Discipline

**Defined:** 2026-06-25
**Core Value:** Replace host-owned generated shell code with standalone SPM/Maven dependencies, enforcing strict delegate-based customization to eliminate the "eject trap" and boilerplate for adopters.
**Milestone Goal:** Turn the in-tree companion seams into real, independently-versioned, fail-closed first-party Hex packages — proving the extraction pattern end-to-end on `rulestead` then `rindle` — and ship the lifecycle, compatibility-matrix, and telemetry-as-public-API discipline a package family requires.

> Naming convention reminder: each companion ships as Hex package `crosswake_<name>` while keeping module namespace `Crosswake.Companions.<Name>`, so the sole adopter touch-point — `config :crosswake, :companions, [...]` — is unchanged and extraction is non-breaking.

## v1 Requirements

Requirements for this milestone. Each maps to exactly one roadmap phase (129–134).

### SEAM — Stable Companion Contract Surface

- [ ] **SEAM-01**: An extension author can depend on a documented, semver-governed set of public companion-contract types (`Crosswake.Companion`, `Crosswake.Companion.State`, `Crosswake.Compatibility.Finding`, `Crosswake.Compatibility.Target`, `Crosswake.Manifest.Types.RouteEntry`) — each carries a non-`false` `@moduledoc`/`@typedoc` and a stability note.
- [ ] **SEAM-02**: A reader can find one curated `guides/companion_contract.md` page that enumerates exactly the public surface extracted packages may depend on, and labels everything else private/patch-volatile.
- [ ] **SEAM-03**: A companion implementation can return restriction evidence (`Compatibility.Finding`) but cannot author the user-facing denial — `Crosswake.Shell.Denial` is absent from the public companion surface.
- [ ] **SEAM-04**: A developer browsing hexdocs sees the companion-contract types grouped under a "Companion Contract" `groups_for_modules` heading.
- [ ] **SEAM-05**: The same extraction checklist applies to a second companion with no companion-specific branches added to core (verified when rindle extracts in Phase 132).

### EXTRACT — Companion Package Extraction Mechanics

- [ ] **EXTRACT-01**: A maintainer no longer relies on the `MIX_INCLUDE_RULESTEAD`/`MIX_INCLUDE_RINDLE` env hack in core `mix.exs`; companions are ordinary `optional: true` deps declared in adopter/example/test mix files, and core lists no companion deps at all.
- [ ] **EXTRACT-02**: `rulestead` lives as a standalone `packages/crosswake_rulestead/` Hex project (own `mix.exs`, own `@version`) with its source and tests moved out of core, preserving the `Crosswake.Companions.Rulestead` module name.
- [ ] **EXTRACT-03**: A merge-blocking guard fails the build if any core (`lib/`) module statically references an extracted companion module — core discovers companions only via the behaviour + the runtime `:companions` registry.
- [ ] **EXTRACT-04**: A guard verifies companions probe their optional dependency at runtime (`Code.ensure_loaded?` inside function bodies), never at module-evaluation time — preventing the stale-recompile footgun.
- [ ] **EXTRACT-05**: `release-please` carries `crosswake_rulestead` as a separate `elixir` release component (independent versioning), explicitly NOT in the core lockstep `linked-versions` group.
- [ ] **EXTRACT-06**: A per-companion publish job (`deps.get` → `compile --warnings-as-errors` → `test` → `hex.publish --dry-run` → `hex.publish`) runs for `crosswake_rulestead`, keyed on its release-please output.
- [ ] **EXTRACT-07**: `rindle` is extracted by the identical recipe (including its owned `Crosswake.Companions.Rindle.Contracts` incl. `MediaObject` and `Reconciliation`) and goes live on Hex, independently versioned.

### COMPAT — Compatibility & Fail-Closed Discipline

- [ ] **COMPAT-01**: With a companion registered and enabled but its package absent from deps, `mix crosswake.doctor` returns an `:error` finding (`companion.dependency_missing`) and `RouteGate` fail-closes the gated route — never a silent no-op.
- [ ] **COMPAT-02**: An adopter can read `guides/companion_compatibility.md` to learn each companion's minimum required core version and the cross-package compatibility matrix.
- [ ] **COMPAT-03**: A drift test fails if any companion's declared `{:crosswake, "~> ..."}` requirement is missing from the compatibility matrix doc.

### PROOF — Clean-Room Verification

- [ ] **PROOF-01**: A clean-room CI lane (and `script/verify_companion_cleanroom.sh`) creates a throwaway mix project OUTSIDE the monorepo, installs the published `crosswake` + companion package, compiles `--warnings-as-errors`, registers the companion, and runs its tests + a `mix crosswake.doctor` smoke check — all green, with Hex-propagation polling.
- [ ] **PROOF-02**: No companion package is published to Hex until a `hex.publish --dry-run` gate and the clean-room/in-monorepo proof lanes are green.

### TELEM — Telemetry Public API

- [ ] **TELEM-01**: A developer can call `Crosswake.Telemetry.events/0` to get the canonical list of every `:telemetry` event Crosswake emits across companion/RouteGate, doctor, sigra, chimeway, threadline, and offline subsystems.
- [ ] **TELEM-02**: A reader can find `guides/telemetry.md` documenting every event's measurements and metadata, following Keathley naming (`[:crosswake, :subsystem, :start|:stop|:exception]`) with stop metadata a superset of start metadata.
- [ ] **TELEM-03**: A host can opt into `Crosswake.Telemetry.attach_default_logger/1`; core never auto-attaches a handler.
- [ ] **TELEM-04**: A bidirectional contract test fails if any event in `events/0` is never emitted, or any emitted event is undeclared.

### LIFE — Generated-Shell Lifecycle & Native UAT

- [ ] **LIFE-01a**: The hermetic Android JVM generated-shell UAT lane is promoted to merge-blocking (in an aggregator modeled on `native-behavioral-proof-gate.yml`).
- [ ] **LIFE-01b**: The iOS simulator/device UAT stays advisory, with the support posture honestly labeled in `guides/support_matrix.md` (no over-promise).
- [ ] **LIFE-02a**: A generated native shell records the `@template_version` and live `crosswake` version that produced it, and a drift test fails if `@template_version` is not bumped when shell templates change.
- [ ] **LIFE-02b**: A host can run `mix crosswake.shell.status` (reports up-to-date / N versions behind) and `mix crosswake.gen.shell --diff` (prints a non-destructive unified diff against current templates — never overwrites host files).
- [ ] **LIFE-02c**: A host can follow `guides/native_shell_upgrade.md` (per-template-version changelog referencing `RuntimeLine.RebuildPolicy.classify/2` for rebuild guidance); the dangling "patch-or-doc guidance" promise in `gen.shell.ex` is replaced with a real pointer.

## v2 Requirements (deferred — future milestones)

### Remaining Companion Extraction

- **EXTRACT-FUT-01**: Extract `sigra` (most entangled — depends on `Manifest.Types.RouteEntry`, `Shell.Denial`, bridge types).
- **EXTRACT-FUT-02**: Extract `chimeway` (depends on sigra `AuthContext`).
- **EXTRACT-FUT-03**: Extract `threadline` (consumes the other companions' contracts — build last).

### Operator Dashboard

- **DASH-01**: Ship a self-contained `crosswake_dashboard` package (LiveDashboard plugin or standalone LiveView, Oban-Web model — no host asset-pipeline coupling) consuming the v16.0 telemetry contract.

### Other Deferred Tracks

- **SYNCP-01**: Offline-sync productization (reusable idempotent replay helpers; likely a `crosswake_sync` package).
- **NTV-01**: Native disk-budget bridge command (real `volumeAvailableCapacity` / `StatFs` vs browser `navigator.storage.estimate()` heuristic).
- **SEED-002**: Native capability breadth (scanner/QR, biometrics, location) + Phoenix-first commerce paywall/subscription seam — each as a bounded package in the family.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Adding companion packages to the core `linked-versions` lockstep group | Companions must version independently; lockstep would force needless core bumps for companion fixes. |
| Renaming companion modules (e.g. to `CrosswakeRulestead`) | Would break the one adopter touch-point (`config :crosswake, :companions`); package name ≠ module name is the deliberate least-surprise call. |
| `Crosswake.Shell.Denial` in the public companion surface | Companions emit evidence (`Finding`) and may further-restrict; core owns the final denial envelope — minimal seam. |
| Destructive `mix crosswake.gen.shell --upgrade` that overwrites host files | Host owns the generated artifact; upgrade is doc-driven `--diff`, never auto-overwrite. |
| Promoting iOS simulator/device UAT to merge-blocking | Environment-flaky; only the hermetic Android JVM lane becomes required (honest support labels). |
| Building the operator dashboard UI in this milestone | Telemetry contract ships now as the prerequisite; the dashboard is deferred to `crosswake_dashboard` (DASH-01). |
| New native capabilities, commerce/paywall breadth, sync productization | Deliberately deferred until the package-family pattern is proven — building breadth first is the Cordova-unbounded-bus footgun. |
| Auto-attaching telemetry handlers from core | Telemetry attachment is the host's job; core only emits + documents + offers an opt-in logger. |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| SEAM-01..04 | Phase 129 | Pending |
| SEAM-05 | Phase 132 | Pending |
| EXTRACT-01..04, COMPAT-01 | Phase 130 | Pending |
| EXTRACT-05..06, PROOF-01..02 | Phase 131 | Pending |
| EXTRACT-07, COMPAT-02..03 | Phase 132 | Pending |
| TELEM-01..04 | Phase 133 | Pending |
| LIFE-01a/b, LIFE-02a/b/c | Phase 134 | Pending |
