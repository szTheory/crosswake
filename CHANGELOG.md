# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Planning milestones vs Hex releases

This changelog uses **[Semantic Versioning](https://semver.org/spec/v2.0.0.html)** headings like **`[0.1.0]`** for **published Hex releases**. Separately, maintainers track **planning milestones** labeled **v1.0–v3.6** in **`.planning/MILESTONE-ARC.md`** and archived milestone evidence under **`.planning/milestones/`** — those labels describe shipped *tranches of work*, **not** a second installable version axis on Hex (this repo remains **0.x** on Hex until a real **1.0.0**). When in doubt, treat **`.planning/MILESTONE-ARC.md`** as canonical for milestone ordering and archive paths.

## [Unreleased]

### Unpublished support claims

* v3.6 operator-truth work adds local diagnostics, support-matrix parity, closeout verification, and docs-contract proof around route/runtime support claims. These are unreleased planning milestone claims until the next Hex package is cut.
* v3.7 StoreKit and Play Billing adapter seams are unreleased support claims until the next Hex package is cut.

### Verification-required and advisory surfaces

* Storefront, provider, device, generated-shell, and optional companion proof lanes remain visible as advisory or verification-required evidence. They are not equivalent to fully supported native runtime breadth.
* Provider/device sandbox proof remains advisory unless promotion criteria pass.

### Deferred non-shipped claims

* RevenueCat provider adapter, full Sigra auth/session machinery, Chimeway notification delivery, and standalone generated shell packages are not shipped in the published Hex package. They stay routed to future milestones and must not be promoted without provider/native proof.

### Published Hex truth

* The latest published Hex release remains `0.1.0`. Public readers should treat this `[Unreleased]` section as development and planning continuity, not an installable release.

## [0.1.2] — Unreleased (pending next Hex publish)

> Staged next release. Bundles the installable changes since `0.1.0`, including work briefly carried as an internal `0.1.1` version bump that was never published. Not yet cut on Hex — `0.1.0` remains the only published release; see the `[Unreleased]` section above for the authoritative deferral/support-claim truth.

### Added

* **Threadline** request-correlation observability: a stable correlation id propagated across the Plug pipeline (`Crosswake.Plug.Threadline`), the LiveView lifecycle (`Crosswake.Live.Threadline`), and bridge command envelopes, with structured telemetry (`Crosswake.Threadline.Telemetry`, `Crosswake.Threadline.Id`) and a `mix crosswake.threadline` docs-contract task. Surfaced through `mix crosswake.doctor` and the support matrix.
* Compatibility-contract and support-matrix refinements, including bridge-protocol-version and commerce-corridor-version gating in route compatibility checks.
* Provider adapter **seam contracts** only (StoreKit / Play Billing adapters remain out of scope — the seam vocabulary and entitlement-lane semantics are operationalized, not the providers).
* Expanded ExDoc guide set shipped in the package (`guides/`): adoption, install, compatibility, support matrix, native shell, commerce, companions, threadline, Android UAT, and user-flow guides.
* `mix crosswake.doctor` publish-readiness checks (`--check-publish`) covering Hex metadata parity and CHANGELOG/release truth.

### Notes

* The v9.0 brand system (`brandbook/` — brand book, design tokens, logo suite, collateral, and the COLL-05 automated brand-verification suite) was developed in this window but is **excluded from the Hex package** (`:exclude_patterns: ["brandbook"]`), so it is not part of this installable release.
* Deferred and not shipped (unchanged from `[Unreleased]`): RevenueCat provider adapter, full Sigra auth/session machinery, Chimeway notification delivery, and standalone generated shell packages.

## [0.1.0] — 2026-05-29

### Added

* Route policy DSL for declaring per-route runtime ownership: LiveView, offline island, native screen, or adapter. Runtime manifest and compatibility contract generated from route policy declarations.
* Bounded bridge contract for low-frequency native capability families (`haptics`, `share`, `app_info`, `deep_link`, `permissions.status`, `notification_token`, `file_picker`) with route-local enforcement and typed command envelopes.
* Offline semantics: cached read-only routes, offline islands with append-only journals, sync endpoints, and server-authoritative reconciliation — each with explicit contract boundaries and doctor diagnostics.
* Commerce corridor declarations with provider-neutral `commerce.corridor.*` denial vocabulary, entitlement lifecycle lane semantics (authority/access/reconciliation/freshness/evidence), and a Phoenix-owned reconciliation inbox example. Provider adapters (StoreKit, Play Billing) are not included; this release operationalizes the seam contract only. There are no first-party companions yet.
* `mix crosswake.doctor` diagnostics, support matrix, and proof lanes verified against three adopter-shaped exemplar lanes: Phoenix SaaS portal, selective-native flow, and local-first study flow.

### Roadmap traceability

Internal planning milestones v1.0 (Route Policy Foundation), v2.0 (Adopter Stress Profiles), v3.0 (Capability Contract And Packaging), v3.1 (Native Capabilities and Bridge Expansion), and v3.2 (Commerce And Entitlement Seams) are archived in `.planning/MILESTONES.md`. These are not separate Hex releases. See `.planning/PROJECT.md` for overarching goals.

[Unreleased]: https://github.com/szTheory/crosswake/compare/v0.1.0...HEAD
[0.1.2]: https://github.com/szTheory/crosswake/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/szTheory/crosswake/releases/tag/v0.1.0
