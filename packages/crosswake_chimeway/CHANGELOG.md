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

## [Unreleased]

### Added

* Initial standalone package skeleton for the Chimeway notification companion adapter
  (`Crosswake.Companions.Chimeway`), extracted from in-tree core so hosts can adopt
  the companion as a Hex dependency. The module namespace and
  the adopter touch-point (`config :crosswake, :companions, [...]`) are unchanged
  — extraction is non-breaking.
