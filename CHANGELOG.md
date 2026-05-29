# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Planning milestones vs Hex releases

This changelog uses **[Semantic Versioning](https://semver.org/spec/v2.0.0.html)** headings like **`[0.1.0]`** for **published Hex releases**. Separately, maintainers track **planning milestones** labeled **v1.0–v3.2** in **`.planning/MILESTONES.md`** — those labels describe shipped *tranches of work*, **not** a second installable version axis on Hex (this repo remains **0.x** on Hex until a real **1.0.0**). When in doubt, treat **`.planning/MILESTONES.md`** as canonical for milestone dates and archive paths.

## 0.1.0 (2026-05-29)


### Features

* **28-01:** add release-please config, manifest, and tool-versions ([59831b9](https://github.com/szTheory/crosswake/commit/59831b93ca4c5f3441db5e0483b8d4ebb4f79cb1))
* **29-01:** add automated release-please pipeline ([845591a](https://github.com/szTheory/crosswake/commit/845591a863dc52b9533a5b69f1bb1cddecb93d28))
* **29-01:** add Dependabot for Actions and verify workflows ([85632ba](https://github.com/szTheory/crosswake/commit/85632ba9c5746aec009762b29e72e1480c89c737))
* **29-01:** add manual hex-publish recovery pipeline ([21bd722](https://github.com/szTheory/crosswake/commit/21bd7222be38cc59a679da17d4c1e82e54542cfb))


### Bug Fixes

* **30:** rewrite leaked absolute paths in guide links; harden link test ([a273f1a](https://github.com/szTheory/crosswake/commit/a273f1a50500627fe120f83d162ad92bf14005ee))
* **phase-26:** repair summary frontmatter and test glob ([7aa36e0](https://github.com/szTheory/crosswake/commit/7aa36e07b1ee0876d99506be49a1fa7ed4a418ef))

## [Unreleased]

## [0.1.0] — 2026-05-28

### Added

* Route policy DSL for declaring per-route runtime ownership: LiveView, offline island, native screen, or adapter. Runtime manifest and compatibility contract generated from route policy declarations.
* Bounded bridge contract for low-frequency native capability families (`haptics`, `share`, `app_info`, `deep_link`, `permissions.status`, `notification_token`, `file_picker`) with route-local enforcement and typed command envelopes.
* Offline semantics: cached read-only routes, offline islands with append-only journals, sync endpoints, and server-authoritative reconciliation — each with explicit contract boundaries and doctor diagnostics.
* Commerce corridor declarations with provider-neutral `commerce.corridor.*` denial vocabulary, entitlement lifecycle lane semantics (authority/access/reconciliation/freshness/evidence), and a Phoenix-owned reconciliation inbox example. Provider adapters (StoreKit, Play Billing) are not included; this release operationalizes the seam contract only. There are no first-party companions yet.
* `mix crosswake.doctor` diagnostics, support matrix, and proof lanes verified against three adopter-shaped exemplar lanes: Phoenix SaaS portal, selective-native flow, and local-first study flow.

### Roadmap traceability

Internal planning milestones v1.0 (Route Policy Foundation), v2.0 (Adopter Stress Profiles), v3.0 (Capability Contract And Packaging), v3.1 (Native Capabilities and Bridge Expansion), and v3.2 (Commerce And Entitlement Seams) are archived in `.planning/MILESTONES.md`. These are not separate Hex releases. See `.planning/PROJECT.md` for overarching goals.

[Unreleased]: https://github.com/szTheory/crosswake/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/szTheory/crosswake/releases/tag/v0.1.0
