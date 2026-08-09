# Changelog

All notable changes to `crosswake_rulestead` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Independent versioning

`crosswake_rulestead` is versioned **independently** of core `crosswake` — it is NOT
in the lockstep `linked-versions` release group. The `{:crosswake, "~> 0.1"}`
requirement declares a compatible-core floor, not a lockstep pin. See
`guides/companion_compatibility.md` in the core repo for the cross-package
compatibility matrix.

## [0.1.0](https://github.com/szTheory/crosswake/compare/crosswake_rulestead-v0.1.0...crosswake_rulestead-v0.1.0) (2026-08-09)


### Bug Fixes

* **rulestead:** replace core-inherited changelog with the package's own ([a36779e](https://github.com/szTheory/crosswake/commit/a36779ecc84759d7afa67d646b2bdfac4a1147b9))
* **rulestead:** replace core-inherited changelog with the package's own ([0ad6970](https://github.com/szTheory/crosswake/commit/0ad69701b9d5554652f12dfbcea529f36659321c))

## [Unreleased]

`crosswake_rulestead` has not been published to Hex yet, so there is no released
version below. This section describes pre-release development only.

### Added

* Initial standalone package skeleton for the Rulestead companion adapter
  (`Crosswake.Companions.Rulestead`), extracted from in-tree core so hosts can
  adopt the companion as an `optional: true` Hex dependency. The module namespace
  and the adopter touch-point (`config :crosswake, :companions, [...]`) are
  unchanged — extraction is non-breaking.
