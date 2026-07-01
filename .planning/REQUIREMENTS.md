# Requirements: Crosswake — v17.0 Companion Family Completion

**Defined:** 2026-06-30
**Core Value:** Replace host-owned generated shell code with standalone SPM/Maven dependencies, enforcing strict delegate-based customization to eliminate the "eject trap" and boilerplate for adopters.
**Milestone Goal:** Extract the remaining three first-party companions — `sigra` (auth), `chimeway` (notifications), `threadline` (audit) — into standalone, independently-versioned, fail-closed Hex packages, completing the companion family. Unlike v16.0's clean rulestead/rindle seams, sigra/chimeway are compile-coupled into core in four sites, so a core-decoupling phase that inverts those onto the `:companions` registry seam lands first.

> Naming convention reminder: each companion ships as Hex package `crosswake_<name>` while keeping module namespace `Crosswake.Companions.<Name>` (and `Crosswake.Threadline.*`/`Crosswake.Audit.*` for threadline), so the sole adopter touch-point — `config :crosswake, :companions, [...]` — is unchanged and extraction is non-breaking.

> Design spine: the locked decisions D-1..D-9, the 5-stream research synthesis, the four coupling sites, and the footgun register are in `.planning/research/v17-companion-family-completion.md`. Requirements below trace to those decisions.

## v1 Requirements

Requirements for this milestone. Each maps to exactly one roadmap phase (136+).

### DECOUPLE — Core-Inversion Seam (lands first, no publish risk)

- [x] **DECOUPLE-01**: Core's `Crosswake.Telemetry` aggregates companion telemetry events **and** forbidden-metadata-keys at runtime by iterating the `:companions` registry via optional behaviour callbacks (`telemetry_events/0`, new `forbidden_metadata_keys/0`) guarded by `function_exported?/3` — with zero compile-time reference to any companion module (`telemetry.ex:145,289` inverted). (D-1, D-5)
- [x] **DECOUPLE-02**: Core's `RouteGate` resolves the auth evaluator at runtime from the registry via a dedicated `evaluate_auth/3` + `auth_authority?/0` callback pair, with no static `Crosswake.Companions.Sigra.Evaluator` alias (`route_gate.ex:9,258` inverted). The auth callback is distinct from `route_gated?/2` (richer `AuthContext` input, distinct denial namespace). (D-2)
- [ ] **DECOUPLE-03**: Core's `SupportMatrix` and `Doctor` obtain companion denial codes and support truth at runtime from the registry via an optional `denial_codes/0` callback — the `@auth_contract_truth`/`@notification_support_truth` module attributes are converted to runtime helpers so no companion function is called at module-evaluation time (`support_matrix.ex:226,266`, `doctor.ex:792,797` inverted). (D-1)
- [x] **DECOUPLE-04**: An absent or misconfigured auth companion on an auth-predicated route (`auth_min_level`/`requires_recent_auth`/`auth_posture` set) fails closed — denies with `:dependency_missing`; a companion raising during evaluation is rescued and treated as deny. "No evaluation = allow" is reachable only on non-auth routes; multiple `auth_authority?/0` companions resolve to the first registered plus a doctor warning. (D-3)
- [x] **DECOUPLE-05**: Core ships a hardcoded baseline PII forbidden-metadata-key denylist (auth tokens + identity fields) that the safe logger **always** applies regardless of which companions are present, layered above the per-companion runtime aggregation — so an absent/misconfigured companion can never silently drop token/identity scrubbing. (D-5)
- [ ] **DECOUPLE-06**: The AST/grep guards enforcing "core never compile-depends on a companion" cover all core `lib/` files (not just the companion dir), and `crosswake` compiles `--warnings-as-errors`, passes COMPAT-01 fail-closed behavior, and passes the Phase-129 companion-contract freeze test with **no** companion package present. (D-1, D-9)

### SIGRA — `crosswake_sigra` Extraction

- [ ] **SIGRA-01**: `sigra` source + tests move to a standalone `packages/crosswake_sigra/` Hex project (own `mix.exs`, own `@version`), with all sub-modules (`Evaluator`, `Handoff`, `StepUp`, `StepUpCeremony`, `AuthReturn`, `Contracts`, `DenialCodes`, `Telemetry`) preserving the `Crosswake.Companions.Sigra.*` namespace. (D-9)
- [ ] **SIGRA-02**: Sigra internals emit `Crosswake.Compatibility.Finding` at the companion boundary; `Crosswake.Shell.Denial` stays core-private and absent from the sigra package; PII detail-sanitization (`DenialCodes.sanitize_details/1`) lives inside the package. All internal `Denial.new` call sites across the sub-modules are refactored to the `Finding` boundary. (D-4)
- [ ] **SIGRA-03**: `crosswake_sigra` publishes to Hex as an independent `release-please` component (not lockstep), preceded by a path-dep dress rehearsal and gated by `hex.publish --dry-run` + a clean-room install lane before the irreversible publish. (D-8, D-9)

### CHIME — `crosswake_chimeway` Extraction

- [ ] **CHIME-01**: `chimeway` source + tests move to a standalone `packages/crosswake_chimeway/` Hex project (own `mix.exs`, own `@version`), preserving the `Crosswake.Companions.Chimeway.*` namespace. (D-9)
- [ ] **CHIME-02**: `crosswake_chimeway` depends only on core — no `crosswake_sigra` dependency; `auth_context` stays typed `map()` with a moduledoc note guarding against tightening to `AuthContext.t()`; the clean-room lane installs `crosswake + crosswake_chimeway + chimeway` but **not** `crosswake_sigra` (vacuity guard). (D-8)
- [ ] **CHIME-03**: `crosswake_chimeway` publishes to Hex as an independent `release-please` component, preceded by a dress rehearsal and gated by `hex.publish --dry-run` + clean-room before publish. (D-8, D-9)

### THREAD — `crosswake_threadline` Extraction (observer, extracted last)

- [ ] **THREAD-01**: threadline (`Crosswake.Threadline.*`, `Crosswake.Audit.Ledger`, `Crosswake.Plug.Threadline`, `Crosswake.Live.Threadline`, and the `crosswake.threadline` + `crosswake.gen.audit` mix tasks) moves to a standalone `packages/crosswake_threadline/` Hex project; the `gen.audit` template path is repointed to `Application.app_dir(:crosswake_threadline, ...)`; host Plug/Live wiring touch-points stay stable. (D-7)
- [ ] **THREAD-02**: threadline observes companion/core events purely via `:telemetry.attach_many` by event-name (zero compile deps on sibling companions); it owns its forbidden-metadata-key list locally; the audit handler is crash-isolated (`try/rescue`) so a write failure cannot silently detach it; the ledger stays append-only and PII-free. (D-7)
- [ ] **THREAD-03**: `crosswake_threadline` publishes to Hex as an independent `release-please` component, gated by `hex.publish --dry-run` + clean-room before publish, after sigra and chimeway are live. (D-7, D-9)

### FAMILY — Package-Family Discipline & Close

- [ ] **FAMILY-01**: Each new companion has a drift-tested compatibility-matrix row in `guides/companion_compatibility.md` (single `Requires crosswake >= X` column); the matrix stays O(N) with no inter-companion columns — companions depend only on core. (D-8)
- [ ] **FAMILY-02**: The extraction recipe `script/extract_companion.md` gains a documented "Step 0: core decoupling" prerequisite for entangled companions and a guard step that greps all of `lib/` (not just the companion dir) for stale companion references. (D-9)
- [ ] **FAMILY-03**: Each companion package carries its own telemetry "declared ⇔ emitted" Side-A contract test; core's hardcoded reserved-event count assertion (`length(reserved_events) >= 24`) is removed in favor of a shape assertion. (D-6)
- [ ] **FAMILY-04**: The three publishes are registered and executed **sequentially** (sigra → chimeway → threadline), one `release-please` component added per PR so a misfire cannot publish all three; the carried `merge-blocking-*` lane-registration ship-gate (`register_required_checks.sh`) is run before new v17.0 lanes are relied upon as merge-blocking. (D-9)

## Future Requirements (deferred)

- **DASH-01**: A self-contained `crosswake_dashboard` package (Oban Web model) surfaces operator/telemetry metrics — unblocked by the `Crosswake.Telemetry` public event contract; deferred until the family is complete.
- **SYNCP-01**: Offline-sync productization (reusable idempotent replay helpers; likely a `crosswake_sync` package).
- **NTV-01**: Extend offline storage budgets to native physical disk space.
- **SEED-002**: Phoenix-first native capability breadth (scanner/QR, biometrics, location) + paywall/subscription seams.

## Out of Scope

- Re-versioning the existing `crosswake_rulestead` / `crosswake_rindle` packages — v17.0 only adds the three remaining companions.
- Any inter-companion Hex dependency — companions depend only on core; shared types graduate to core's public contract surface rather than creating companion-on-companion coupling (the Absinthe `absinthe_phoenix → absinthe_plug` cautionary pattern).
- Folding companions into the core `linked-versions` lockstep group — independent versioning is confirmed correct (Ash/Broadway/Oban precedent).
- New companion **features** — v17.0 is extraction/coherence work; the auth/notification/audit surfaces ship at their current behavior, only relocated and decoupled.
- Closing the TELEM-04 Side-B vacuity in core via a `:telemetry` wildcard handler — distributed to each companion's own Side-A proof instead.

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| DECOUPLE-01 | Phase 136 | Complete |
| DECOUPLE-02 | Phase 136 | Complete |
| DECOUPLE-03 | Phase 136 | Pending |
| DECOUPLE-04 | Phase 136 | Complete |
| DECOUPLE-05 | Phase 136 | Complete |
| DECOUPLE-06 | Phase 136 | Pending |
| SIGRA-01 | Phase 137 | Pending |
| SIGRA-02 | Phase 137 | Pending |
| SIGRA-03 | Phase 137 | Pending |
| CHIME-01 | Phase 138 | Pending |
| CHIME-02 | Phase 138 | Pending |
| CHIME-03 | Phase 138 | Pending |
| THREAD-01 | Phase 139 | Pending |
| THREAD-02 | Phase 139 | Pending |
| THREAD-03 | Phase 139 | Pending |
| FAMILY-01 | Phase 140 | Pending |
| FAMILY-02 | Phase 140 | Pending |
| FAMILY-03 | Phase 140 | Pending |
| FAMILY-04 | Phase 140 | Pending |
