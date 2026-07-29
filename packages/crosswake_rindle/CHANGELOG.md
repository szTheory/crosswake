# Changelog

All notable changes to `crosswake_rindle` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Independent versioning

`crosswake_rindle` is versioned **independently** of core `crosswake` — it is NOT
in the lockstep `linked-versions` release group. The `{:crosswake, "~> 0.1"}`
requirement declares a compatible-core floor, not a lockstep pin. See
`guides/companion_compatibility.md` in the core repo for the cross-package
compatibility matrix.

## [0.1.0](https://github.com/szTheory/crosswake/compare/crosswake_rindle-v0.1.0...crosswake_rindle-v0.1.0) (2026-07-29)


### Bug Fixes

* **companions:** add ex_doc to sigra/chimeway/rulestead/rindle for hex.publish ([eccb49d](https://github.com/szTheory/crosswake/commit/eccb49d584259ee2d16997619b7f1c8619d624b2))
* **companions:** add ex_doc to sigra/chimeway/rulestead/rindle for hex.publish ([12d39b7](https://github.com/szTheory/crosswake/commit/12d39b7e65f8f894a93a754ee741f4fd07a23719))
* **companions:** drop runtime:false from ex_doc — trips D-27 guard ([c822db5](https://github.com/szTheory/crosswake/commit/c822db5ae8bebf4f7e129fd27b5cea7b23f5478f))

## [Unreleased]

### Added

* Initial standalone package skeleton for the Rindle companion adapter
  (`Crosswake.Companions.Rindle`), extracted from in-tree core so hosts can adopt
  the companion as an `optional: true` Hex dependency. The module namespace and
  the adopter touch-point (`config :crosswake, :companions, [...]`) are unchanged
  — extraction is non-breaking.
