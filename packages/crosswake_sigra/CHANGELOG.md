# Changelog

All notable changes to `crosswake_sigra` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Independent versioning

`crosswake_sigra` is versioned **independently** of core `crosswake` — it is NOT
in the lockstep `linked-versions` release group. The `{:crosswake, "~> 0.1"}`
requirement declares a compatible-core floor, not a lockstep pin. See
`guides/companion_compatibility.md` in the core repo for the cross-package
compatibility matrix.

## [0.1.2](https://github.com/szTheory/crosswake/compare/crosswake_sigra-v0.1.1...crosswake_sigra-v0.1.2) (2026-08-09)


### Bug Fixes

* align browser proof fixtures with scoped replay ([21dd21b](https://github.com/szTheory/crosswake/commit/21dd21b3dca1550166339c68ea0afd84b95843c3))

## [0.1.1](https://github.com/szTheory/crosswake/compare/crosswake_sigra-v0.1.0...crosswake_sigra-v0.1.1) (2026-07-03)


### Bug Fixes

* **companions:** add ex_doc to sigra/chimeway/rulestead/rindle for hex.publish ([eccb49d](https://github.com/szTheory/crosswake/commit/eccb49d584259ee2d16997619b7f1c8619d624b2))
* **companions:** add ex_doc to sigra/chimeway/rulestead/rindle for hex.publish ([12d39b7](https://github.com/szTheory/crosswake/commit/12d39b7e65f8f894a93a754ee741f4fd07a23719))
* **companions:** drop runtime:false from ex_doc — trips D-27 guard ([c822db5](https://github.com/szTheory/crosswake/commit/c822db5ae8bebf4f7e129fd27b5cea7b23f5478f))

## [0.1.0](https://github.com/szTheory/crosswake/compare/crosswake_sigra-v0.1.0...crosswake_sigra-v0.1.0) (2026-07-03)


### Features

* **137-03:** add clean-room proof, move remaining sigra-dependent core tests to package ([b92e001](https://github.com/szTheory/crosswake/commit/b92e0015faef2ec462a1358665e5ecc924b6ae79))
* **137-03:** move sigra-internal tests to package, split proof tests ([24510cc](https://github.com/szTheory/crosswake/commit/24510ccab664b43d775b6cd99a0387a241925c3d))
* **137-03:** scaffold crosswake_sigra package, move sigra source to package, update core mix.exs ([a18c3e8](https://github.com/szTheory/crosswake/commit/a18c3e814afd4dc0d05c8eb6b2e2cdfe3cbc7602))
* **141-02:** bump v17.0 companion crosswake_dep seams to ~&gt; 0.2 ([4285a85](https://github.com/szTheory/crosswake/commit/4285a85ddf7eb4f42cd9588f9727a490a9046ad7))


### Bug Fixes

* **138:** stop :companions env nil-poisoning in test captures (seed-stable suite) ([0804ba5](https://github.com/szTheory/crosswake/commit/0804ba57c669620e8258a4e79e80f32528651865))

## [0.1.0](https://github.com/szTheory/crosswake/compare/crosswake_sigra-v0.1.0...crosswake_sigra-v0.1.0) (2026-07-03)


### Features

* **137-03:** add clean-room proof, move remaining sigra-dependent core tests to package ([b92e001](https://github.com/szTheory/crosswake/commit/b92e0015faef2ec462a1358665e5ecc924b6ae79))
* **137-03:** move sigra-internal tests to package, split proof tests ([24510cc](https://github.com/szTheory/crosswake/commit/24510ccab664b43d775b6cd99a0387a241925c3d))
* **137-03:** scaffold crosswake_sigra package, move sigra source to package, update core mix.exs ([a18c3e8](https://github.com/szTheory/crosswake/commit/a18c3e814afd4dc0d05c8eb6b2e2cdfe3cbc7602))


### Bug Fixes

* **138:** stop :companions env nil-poisoning in test captures (seed-stable suite) ([0804ba5](https://github.com/szTheory/crosswake/commit/0804ba57c669620e8258a4e79e80f32528651865))

## [Unreleased]

### Added

* Initial standalone package skeleton for the Sigra auth companion adapter
  (`Crosswake.Companions.Sigra`), extracted from in-tree core so hosts can adopt
  the companion as a Hex dependency. The module namespace and
  the adopter touch-point (`config :crosswake, :companions, [...]`) are unchanged
  — extraction is non-breaking.
