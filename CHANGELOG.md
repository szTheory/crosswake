# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Planning milestones vs Hex releases

This changelog uses **[Semantic Versioning](https://semver.org/spec/v2.0.0.html)** headings like **`[0.1.0]`** for **published Hex releases**. Separately, maintainers track **planning milestones** labeled **v1.0–v3.6** in **`.planning/MILESTONE-ARC.md`** and archived milestone evidence under **`.planning/milestones/`** — those labels describe shipped *tranches of work*, **not** a second installable version axis on Hex (this repo remains **0.x** on Hex until a real **1.0.0**). When in doubt, treat **`.planning/MILESTONE-ARC.md`** as canonical for milestone ordering and archive paths.

## [Unreleased]

### Unpublished support claims

* No new support claims have been cut after `0.1.2` yet. Future entries here must distinguish planning milestone work from published Hex release truth.

### Verification-required and advisory surfaces

* Storefront, provider, device, checked-in native host, and optional companion proof lanes remain visible as advisory or verification-required evidence. They are not equivalent to fully supported native runtime breadth.
* Provider/device sandbox proof remains advisory unless promotion criteria pass.

### Deferred non-shipped claims

* RevenueCat provider adapter, Chimeway notification delivery, native device/emulator proof lanes, companion extraction, and broad native runtime expansion are not shipped in the published Hex package. They stay routed to future milestones and must not be promoted without provider/native proof.

### Published Hex truth

* The current published Hex release is `0.1.2`. Public readers should treat this `[Unreleased]` section as future development and planning continuity, not a newer installable release.

## [0.1.2] — 2026-06-17

> Published release. Bundles the installable changes since `0.1.0`, including work briefly carried as an internal `0.1.1` version bump that was never published.

### Upgrade Impact

**native or companion rebuild required**

This release publishes the reusable iOS and Android shell-core packages to SwiftPM and Maven Central, adds release-time clean-room proof jobs, and extends compatibility-contract gating. Adopters integrating the generated native shell scaffolds must rebuild and resubmit their native host apps.

Lower-impact changes bundled in this release (no native rebuild needed):

* **core-only/no native rebuild** — Threadline request-correlation observability (`Crosswake.Plug.Threadline`, `Crosswake.Live.Threadline`), structured telemetry, and `mix crosswake.threadline` docs-contract task are Elixir-only additions inside the existing contract axes; no native rebuild required.
* **core-only/no native rebuild** — `mix crosswake.doctor` publish-readiness checks (`--check-publish`), expanded ExDoc guide set, and provider adapter seam contract vocabulary are Elixir-side additions; no native rebuild required.

### Added

* Published native shell core distribution path: generated iOS scaffolds resolve `github.com/szTheory/crosswake-shell-core-ios` through SwiftPM, generated Android scaffolds resolve `io.github.sztheory:crosswake-shell-core-android` through Maven Central, and both coordinates derive from the Crosswake package version.
* Release-time clean-room proof jobs for iOS and Android that scaffold outside the monorepo and run `swift build` / `gradle build` against the just-published artifacts.
* A merge-blocking published-dependency parity guard in `mix crosswake.doctor --check-publish` so generator templates cannot drift back to monorepo paths, placeholder orgs, or mismatched versions.
* **Threadline** request-correlation observability: a stable correlation id propagated across the Plug pipeline (`Crosswake.Plug.Threadline`), the LiveView lifecycle (`Crosswake.Live.Threadline`), and bridge command envelopes, with structured telemetry (`Crosswake.Threadline.Telemetry`, `Crosswake.Threadline.Id`) and a `mix crosswake.threadline` docs-contract task. Surfaced through `mix crosswake.doctor` and the support matrix.
* Compatibility-contract and support-matrix refinements, including bridge-protocol-version and commerce-corridor-version gating in route compatibility checks.
* Provider adapter **seam contracts** only (StoreKit / Play Billing adapters remain out of scope — the seam vocabulary and entitlement-lane semantics are operationalized, not the providers).
* Expanded ExDoc guide set shipped in the package (`guides/`): adoption, install, compatibility, support matrix, native shell, commerce, companions, threadline, Android UAT, and user-flow guides.
* `mix crosswake.doctor` publish-readiness checks (`--check-publish`) covering Hex metadata parity and CHANGELOG/release truth.

### Notes

* The v9.0 brand system (`brandbook/` — brand book, design tokens, logo suite, collateral, and the COLL-05 automated brand-verification suite) was developed in this window but is **excluded from the Hex package** (`:exclude_patterns: ["brandbook"]`), so it is not part of this installable release.
* Deferred and not shipped (unchanged from `[Unreleased]`): RevenueCat provider adapter, Chimeway notification delivery, native device/emulator proof lanes, companion extraction, and broad native runtime expansion beyond the published-core shell path.

## [0.1.0] — 2026-05-29

### Upgrade Impact

**native or companion rebuild required**

This is the initial published release. Adopters adopting Crosswake for the first time must scaffold and build their native host shells using the generated iOS and Android shell-core project templates. The route policy DSL, bridge contract, offline semantics, and commerce corridor declarations all require native shell code to activate native routes and capabilities.

### Added

* Route policy DSL for declaring per-route runtime ownership: LiveView, offline island, native screen, or adapter. Runtime manifest and compatibility contract generated from route policy declarations.
* Bounded bridge contract for low-frequency native capability families (`haptics`, `share`, `app_info`, `deep_link`, `permissions.status`, `notification_token`, `file_picker`) with route-local enforcement and typed command envelopes.
* Offline semantics: cached read-only routes, offline islands with append-only journals, sync endpoints, and server-authoritative reconciliation — each with explicit contract boundaries and doctor diagnostics.
* Commerce corridor declarations with provider-neutral `commerce.corridor.*` denial vocabulary, entitlement lifecycle lane semantics (authority/access/reconciliation/freshness/evidence), and a Phoenix-owned reconciliation inbox example. Provider adapters (StoreKit, Play Billing) are not included; this release operationalizes the seam contract only. There are no first-party companions yet.
* `mix crosswake.doctor` diagnostics, support matrix, and proof lanes verified against three adopter-shaped exemplar lanes: Phoenix SaaS portal, selective-native flow, and local-first study flow.

### Roadmap traceability

Internal planning milestones v1.0 (Route Policy Foundation), v2.0 (Adopter Stress Profiles), v3.0 (Capability Contract And Packaging), v3.1 (Native Capabilities and Bridge Expansion), and v3.2 (Commerce And Entitlement Seams) are archived in `.planning/MILESTONES.md`. These are not separate Hex releases. See `.planning/PROJECT.md` for overarching goals.

[Unreleased]: https://github.com/szTheory/crosswake/compare/v0.1.2...HEAD
[0.1.2]: https://github.com/szTheory/crosswake/compare/v0.1.0...v0.1.2
[0.1.0]: https://github.com/szTheory/crosswake/releases/tag/v0.1.0
