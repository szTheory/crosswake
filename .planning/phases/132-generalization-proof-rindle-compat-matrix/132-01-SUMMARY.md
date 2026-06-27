---
phase: 132-generalization-proof-rindle-compat-matrix
plan: 01
subsystem: companion-packaging
tags: [extraction, hex-package, skeleton, test-support, rindle]
status: complete
requires:
  - "packages/crosswake_rulestead/ (copy-template skeleton)"
  - "Crosswake.Companion behaviour + Crosswake.Companion.State struct"
provides:
  - "packages/crosswake_rindle/ compiling Hex package skeleton (no companion source yet)"
  - "Crosswake.TestSupport.StubRindleAbsentCompanion"
  - "Path.wildcard(packages/crosswake_*/mix.exs) >= 2 (non-vacuity precondition for 132-02)"
affects:
  - "132-02 (compat-matrix drift test — AST-parses crosswake_dep/0, counts >= 2 packages)"
  - "132-03 (seam rewrites — register rindle-shaped companion via the stub, not a direct alias)"
tech-stack:
  added: []
  patterns:
    - "env-conditional crosswake_dep/0 resolver (CROSSWAKE_RELEASE gate, D-11/D-13)"
    - "ENGINE_PRESENT_LANE conditional elixirc_paths engine-present advisory lane (D-33)"
    - "StubXxxAbsentCompanion @behaviour-driven test double"
key-files:
  created:
    - packages/crosswake_rindle/mix.exs
    - packages/crosswake_rindle/mix.lock
    - packages/crosswake_rindle/test/test_helper.exs
    - packages/crosswake_rindle/config/config.exs
    - packages/crosswake_rindle/test/engine_present/rindle.ex
    - packages/crosswake_rindle/README.md
    - packages/crosswake_rindle/CHANGELOG.md
    - packages/crosswake_rindle/LICENSE
    - packages/crosswake_rindle/lib/.gitkeep
  modified:
    - test/support/stub_companion.ex
decisions:
  - "rindle config.exs is intentionally minimal — Rindle reads :crosswake/:rindle config directly with no flag-source mock indirection (unlike rulestead's :rulestead_flag_source/MockFlagSource), so no test-only flag-source wiring was added (plan-anticipated)."
  - "crosswake_rindle CHANGELOG.md written as a clean Keep-a-Changelog skeleton with an [Unreleased] section + independent-versioning note, NOT a verbatim copy of the core-inherited rulestead CHANGELOG — a brand-new 0.1.0 companion should not carry core's 0.1.0/0.1.2 release history."
  - "lib/.gitkeep added so the empty lib/ dir is tracked and elixirc_paths([\"lib\"]) compiles before any companion source moves in 132-03."
metrics:
  duration: ~12m
  completed: 2026-06-26
  tasks: 2
  files: 10
---

# Phase 132 Plan 01: Rindle Package Skeleton + StubRindleAbsentCompanion Summary

Scaffolded the `packages/crosswake_rindle/` Hex package skeleton (mix.exs + test infrastructure, **no companion source moved**) and added `Crosswake.TestSupport.StubRindleAbsentCompanion` to core test support — the Wave-0 foundation the parallel Wave-2 plans (132-02 drift test, 132-03 source move) assert against.

## What Was Built

**Task 1 — `packages/crosswake_rindle/` skeleton (commit d502114)**
Copied the `packages/crosswake_rulestead/` skeleton structure, substituting `CrosswakeRulestead`→`CrosswakeRindle`, `crosswake_rulestead`→`crosswake_rindle`, `rulestead`→`rindle`, `Rulestead`→`Rindle`. Created only the skeleton — no `lib/` companion source, no moved test files (those land in 132-03):

- `mix.exs` — `CrosswakeRindle.MixProject`; `app: :crosswake_rindle`; `@version "0.1.0"` with the `# x-release-please-version` marker on the same line; `deps/0` returns `[crosswake_dep(), {:rindle, "~> 0.1", optional: true}]` (engine cap stays `~> 0.1` per D-16 — rindle 0.3.0 is outside `~> 0.1`, widening deferred); `crosswake_dep/0` env-conditional resolver matching the rulestead literal verbatim (`CROSSWAKE_RELEASE == "1"` → `{:crosswake, "~> 0.1"}`, else `{:crosswake, path: "../.."}`) — the exact AST parse target for the 132-02 drift test; `elixirc_paths(:test)` appends `test/engine_present` only under `ENGINE_PRESENT_LANE=1` (D-33); `engine-present.test` alias runs `clean` then the gated lane; `package/0` files allowlist `lib mix.exs README.md LICENSE CHANGELOG.md` (test/ excluded, D-24).
- `test/test_helper.exs` — verbatim `ExUnit.start(exclude: [:engine_present, :collateral_binaries, :advisory_only])`.
- `config/config.exs` — minimal (see Deviations note).
- `test/engine_present/rindle.ex` — fake top-level `Rindle` presence stub, compiled ONLY under `ENGINE_PRESENT_LANE=1` (D-33).
- `README.md`, `CHANGELOG.md`, `LICENSE` — companion-package allowlist members.

The skeleton compiles standalone (`mix deps.get && mix compile` resolves the path-dep core and generates `crosswake_rindle` from the empty `lib/`).

**Task 2 — `StubRindleAbsentCompanion` (commit a242e15)**
Appended `Crosswake.TestSupport.StubRindleAbsentCompanion` to `test/support/stub_companion.ex` immediately after `StubRulesteadAbsentCompanion`, copy-substituting `:rulestead`→`:rindle`. Implements the full `Crosswake.Companion` behaviour: `companion_id/0 == :rindle`, `validate_dependency/0 == {:error, [:"Elixir.Rindle"]}` (rindle absent from core deps, D-21), and `report_state/0` reads `Application.get_env(:crosswake, :rindle, %{})` per the rulestead analog (PATTERNS.md flagged that the RESEARCH.md draft dropped this line). Runtime-verified: the stub reports `:rindle` / `{:missing, [:"Elixir.Rindle"]}` correctly.

## Verification

- `test -f packages/crosswake_rindle/mix.exs` + `x-release-please-version` + `crosswake_dep` + `{:rindle, "~> 0.1", optional: true}` → **SKELETON_OK**.
- `Path.wildcard("packages/crosswake_*/mix.exs")` returns **2** (rulestead + rindle) — non-vacuity precondition for the 132-02 drift test satisfied.
- `MIX_ENV=test mix compile --warnings-as-errors` → clean; `StubRindleAbsentCompanion` present → **STUB_OK**.
- Runtime smoke: stub `companion_id == :rindle`, `validate_dependency == {:error, [:"Elixir.Rindle"]}`, `report_state` populates the full `Crosswake.Companion.State` struct.

## Deviations from Plan

None that changed scope. One plan-anticipated judgment call:

- **`config/config.exs` minimal (plan-anticipated):** The plan said "if rindle has no flag-source mock, mirror whatever the rulestead config.exs contains, substituting names. Keep it minimal — only what the moved tests need." Inspection confirmed `Crosswake.Companions.Rindle` reads only `Application.get_env(:crosswake, :rindle, %{})` directly — there is **no** rindle flag-source mock analogous to rulestead's `:rulestead_flag_source`/`MockFlagSource`. So `config/config.exs` is a minimal `import Config` with a `:test`-env no-op and a comment documenting why no flag-source indirection is wired. Not a deviation — the plan explicitly covered this branch.
- **CHANGELOG.md shape:** Written as a clean Keep-a-Changelog skeleton (`[Unreleased]` + independent-versioning note) rather than a verbatim copy of the core-inherited rulestead CHANGELOG. A fresh 0.1.0 companion should not carry core's 0.1.0/0.1.2 release history; this is the honest shape for a new package and matches the package's actual release state.

## Known Stubs

- `test/engine_present/rindle.ex` (fake `Rindle`) and `Crosswake.TestSupport.StubRindleAbsentCompanion` are **intentional** test doubles, not production stubs. The real `Crosswake.Companions.Rindle` source move into `packages/crosswake_rindle/lib/` lands in **132-03** (same-PR rule with the `CompanionGuard` `@extracted_companion_names` edit). `packages/crosswake_rindle/lib/` is empty (`lib/.gitkeep`) by design at this Wave-0 stage.

## Threat Surface

No new threat surface beyond the plan's `<threat_model>`. T-132-SC (no package-manager installs) holds — only an in-tree skeleton copy and a stub module; no new external packages added. `{:rindle, "~> 0.1", optional: true}` (T-132-01) was declared but not resolved as a hard dep; the `~> 0.1` cap is no wildcard.

## Self-Check: PASSED

All 8 artifacts present on disk; both task commits (d502114, a242e15) present in git history.
