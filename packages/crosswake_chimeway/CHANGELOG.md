# Changelog

All notable changes to `crosswake_chimeway` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Independent versioning

`crosswake_chimeway` is versioned **independently** of core `crosswake` — it is NOT
in the lockstep `linked-versions` release group. The `{:crosswake, "~> 0.1"}`
requirement declares a compatible-core floor, not a lockstep pin. See
`guides/companion_compatibility.md` in the core repo for the cross-package
compatibility matrix.

## [0.1.1](https://github.com/szTheory/crosswake/compare/crosswake_chimeway-v0.1.0...crosswake_chimeway-v0.1.1) (2026-08-28)


### Bug Fixes

* align browser proof fixtures with scoped replay ([21dd21b](https://github.com/szTheory/crosswake/commit/21dd21b3dca1550166339c68ea0afd84b95843c3))

## [0.1.0](https://github.com/szTheory/crosswake/compare/crosswake_chimeway-v0.1.0...crosswake_chimeway-v0.1.0) (2026-07-04)


### Features

* **138-01:** scaffold crosswake_chimeway package, move source, remove from core ([526bc15](https://github.com/szTheory/crosswake/commit/526bc1582dea0665e863ba4d0ce19f07d763a1d1))
* **138-02:** move chimeway tests to package, split phase59 (support truth stays in core) ([e36ca93](https://github.com/szTheory/crosswake/commit/e36ca93fd22480842a6530527fb44b3751e10ff6))
* **138-02:** move phase71 to chimeway package with test-only crosswake_sigra dep ([4ac425a](https://github.com/szTheory/crosswake/commit/4ac425a6b2cdc77b96bcbfe32dd62bbaf35509db))
* **138-02:** non-vacuous chimeway clean-room proof (telemetry + forbidden keys + CHIME-02) ([13a9c64](https://github.com/szTheory/crosswake/commit/13a9c64664c596a3462a801a15123b1c3d20da4d))
* **141-02:** bump v17.0 companion crosswake_dep seams to ~&gt; 0.2 ([4285a85](https://github.com/szTheory/crosswake/commit/4285a85ddf7eb4f42cd9588f9727a490a9046ad7))


### Bug Fixes

* **companions:** add ex_doc to sigra/chimeway/rulestead/rindle for hex.publish ([eccb49d](https://github.com/szTheory/crosswake/commit/eccb49d584259ee2d16997619b7f1c8619d624b2))
* **companions:** add ex_doc to sigra/chimeway/rulestead/rindle for hex.publish ([12d39b7](https://github.com/szTheory/crosswake/commit/12d39b7e65f8f894a93a754ee741f4fd07a23719))
* **companions:** drop runtime:false from ex_doc — trips D-27 guard ([c822db5](https://github.com/szTheory/crosswake/commit/c822db5ae8bebf4f7e129fd27b5cea7b23f5478f))

## [Unreleased]

### Added

* Initial standalone package skeleton for the Chimeway notification companion adapter
  (`Crosswake.Companions.Chimeway`), extracted from in-tree core so hosts can adopt
  the companion as a Hex dependency. The module namespace and
  the adopter touch-point (`config :crosswake, :companions, [...]`) are unchanged
  — extraction is non-breaking.
