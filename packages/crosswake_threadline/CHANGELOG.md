# Changelog

All notable changes to `crosswake_threadline` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Independent versioning

`crosswake_threadline` is versioned **independently** of core `crosswake` — it is NOT
in the lockstep `linked-versions` release group. The `{:crosswake, "~> 0.1"}`
requirement declares a compatible-core floor, not a lockstep pin. See
`guides/companion_compatibility.md` in the core repo for the cross-package
compatibility matrix.

## [0.1.0](https://github.com/szTheory/crosswake/compare/crosswake_threadline-v0.1.0...crosswake_threadline-v0.1.0) (2026-07-04)


### Features

* **139-01:** scaffold packages/crosswake_threadline with priv/, optional-Phoenix guards, move source + EEX templates, wire test-only core dep ([a62b4ba](https://github.com/szTheory/crosswake/commit/a62b4ba12bfdb711d81b315745815c2fa4a90835))
* **139-02:** add vacuity-safe clean-room proof for threadline extraction (async: true) ([107e962](https://github.com/szTheory/crosswake/commit/107e96228174599cdabf07a573919d7026a913ee))
* **139-02:** empty-result guard in durable path of mix crosswake.threadline ([81250d7](https://github.com/szTheory/crosswake/commit/81250d73f8bea841fe4783f5ff49c889e269703b))
* **139-02:** extend gen.audit + ledger tests for Task 5 brand-voice assertions (RED phase) ([cca8a40](https://github.com/szTheory/crosswake/commit/cca8a40f644afb8d43b10caff303296881b5f73e))
* **139-02:** harden generated audit ledger template with try/rescue, on_conflict, advisory moduledoc ([c666afb](https://github.com/szTheory/crosswake/commit/c666afbe51ef27c2e9ac05e3e20078f6977e6436))
* **139-02:** HMAC ArgumentError names both :secret opt and :audit_hmac_secret app-env key ([244cf00](https://github.com/szTheory/crosswake/commit/244cf00ef224066457d044343ae080045589931c))
* **139-02:** move threadline tests to package lane + add anti-drift PII-floor test ([afee444](https://github.com/szTheory/crosswake/commit/afee444a575c481f9199e182080d98278e5c1fcd))
* **139-02:** NO_COLOR env detection + ASCII tree fallback in mix crosswake.threadline ([8d581f2](https://github.com/szTheory/crosswake/commit/8d581f26bbf96d17fefb78863732efdff2d915f5))
* **139-02:** posture microcopy rewrites in mix crosswake.threadline (brand-voice §6) ([1f6d7b7](https://github.com/szTheory/crosswake/commit/1f6d7b7c9a0762c86f0c5f82336cfdfc2cc075e6))
* **141-02:** bump v17.0 companion crosswake_dep seams to ~&gt; 0.2 ([4285a85](https://github.com/szTheory/crosswake/commit/4285a85ddf7eb4f42cd9588f9727a490a9046ad7))


### Bug Fixes

* **threadline:** remove dead default arg in render_durable/2 ([#70](https://github.com/szTheory/crosswake/issues/70)) ([9db3972](https://github.com/szTheory/crosswake/commit/9db397209660f8bf8e1151690d3194c5f8fe58f0))

## [Unreleased]

### Added

* Initial standalone package skeleton for the Threadline audit and correlation observer
  (`Crosswake.Threadline.*`, `Crosswake.Audit.Ledger`, `Crosswake.Plug.Threadline`,
  `Crosswake.Live.Threadline`, `mix crosswake.gen.audit`, `mix crosswake.threadline`),
  extracted from in-tree core so hosts can adopt threadline as a Hex dependency.
  The module namespaces and the adopter touch-points (`plug Crosswake.Plug.Threadline`,
  `on_mount: Crosswake.Live.Threadline`) are unchanged — extraction is non-breaking.
