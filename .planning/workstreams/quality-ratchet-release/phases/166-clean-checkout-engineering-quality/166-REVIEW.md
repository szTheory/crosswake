---
phase: 166-clean-checkout-engineering-quality
reviewed: 2026-09-10T04:26:29Z
depth: standard
files_reviewed: 48
files_reviewed_list:
  - .formatter.exs
  - .github/workflows/crosswake-ci.yml
  - .tool-versions
  - CHANGELOG.md
  - README.md
  - examples/phoenix_host/e2e/offline_storage.spec.ts
  - examples/phoenix_host/e2e/offline_sync.spec.ts
  - examples/phoenix_host/playwright.config.ts
  - examples/phoenix_host/priv/static/offline_study.js
  - guides/companion_compatibility.md
  - guides/install.md
  - guides/route_policy.md
  - lib/crosswake/doctor/doctor.ex
  - lib/crosswake/doctor/finding_policy.ex
  - lib/crosswake/install/patcher.ex
  - lib/crosswake/manifest/builder.ex
  - lib/mix/tasks/crosswake.doctor.ex
  - lib/mix/tasks/crosswake.install.ex
  - mix.exs
  - priv/templates/crosswake/install_manifest.json.eex
  - script/capture_repository_verification_evidence.sh
  - script/check_ci_leaf_manifest.py
  - script/check_dependency_security.sh
  - script/check_example_host_isolation.sh
  - script/check_phase166_clean_checkout_engineering_quality.sh
  - script/check_phase166_ownership_ledger.py
  - script/ci_leaf_manifest.json
  - script/list_merge_blocking_checks.py
  - script/repository_artifact_policy.json
  - script/repository_evidence_toolchain.json
  - script/repository_verification_stages.json
  - script/run_repository_evidence_environment.sh
  - script/verify_repository.mjs
  - script/verify_repository.sh
  - test/crosswake/doctor/doctor_test.exs
  - test/crosswake/guides/route_policy_test.exs
  - test/crosswake/offline/proof_lane_test.exs
  - test/crosswake/proof/phase164_example_host_isolation_test.exs
  - test/crosswake/proof/phase165_ci_integrity_test.exs
  - test/crosswake/proof/phase166_repository_quality_test.exs
  - test/fixtures/proof/phase52_publish_readiness.json
  - test/fixtures/repository_quality/artifact-cases.json
  - test/fixtures/repository_quality/stage-cases.json
  - test/js/playwright_repository_mode.test.mjs
  - test/js/repository_verification.test.mjs
  - test/mix/tasks/crosswake_doctor_router_test.exs
  - test/mix/tasks/crosswake_doctor_test.exs
  - test/mix/tasks/crosswake_install_test.exs
findings:
  critical: 2
  warning: 3
  info: 0
  total: 5
status: issues_found
---

# Phase 166: Code Review Report

**Reviewed:** 2026-09-10T04:26:29Z
**Depth:** standard
**Files Reviewed:** 48
**Status:** issues_found

## Summary

The phase adds a coherent fixed-stage verification facade and preserves the first-adopter privacy and Android-freeze boundaries, but two merge-blocking quality stages can currently report success without checking the behavior their names and manifests promise. Three additional defects affect installer compatibility, archive containment hardening, and ownership-graph validation.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: The root formatter contract excludes every Elixir source file

**File:** `.formatter.exs:1-3`
**Issue:** The new formatter configuration sets `inputs` to only `.formatter.exs`. Consequently the `format-proof` stage's `mix format --check-formatted` command never examines `lib/**/*.ex`, `test/**/*.exs`, `mix.exs`, or other Elixir source. The Phase 166 test at `test/crosswake/proof/phase166_repository_quality_test.exs:18-22` locks in this vacuous scope, so arbitrarily unformatted production code can pass the advertised repository format gate and its CI owner.
**Fix:** Define a real bounded repository source set, for example:

```elixir
[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"]
]
```

Then update the Phase 166 contract test to inject an unformatted `.ex`/`.exs` fixture and prove the default command rejects it.

### CR-02: `repository-cleanliness` declares `git diff --check` but never executes it

**File:** `script/verify_repository.mjs:271-275,381-383`
**Issue:** The stage manifest declares `repository-cleanliness` as `git diff --check` (`script/repository_verification_stages.json:119-127`), but the runner special-cases that stage to `runRepositoryCleanliness`, which only checks forbidden tracked artifacts and generated-contract regeneration. The declared argv is bypassed entirely. Committed whitespace errors therefore pass both the focused cleanliness stage and the final cleanliness path, while CI and retained evidence record `PASS repository-cleanliness`.
**Fix:** Execute the declared fixed argv and require it to pass before running the artifact/generated-contract checks. Add a negative test using a committed or staged whitespace-error fixture so a `PASS` record cannot be produced when `git diff --check` fails.

## Warnings

### WR-01: The installer advertises a nonstandard-router escape hatch that cannot work

**File:** `lib/mix/tasks/crosswake.install.ex:44-48,193-207`
**Issue:** `infer_router_module!/1` runs unconditionally before `opts[:web_module]` is considered and accepts only modules ending in `.Router`. On failure it tells the user to pass `--web-module`, but that option does not participate in router-module inference. A valid Phoenix host with a nonstandard router module cannot install even when it supplies both `--router` and `--web-module`, and the documented recovery instruction repeats the same failure.
**Fix:** Add an explicit `--router-module` option, or derive the full module from a general `defmodule` match while using `--web-module` only for the policy namespace. Make the error name the option that actually resolves the failure and add a non-`.Router` regression fixture.

### WR-02: Archive validation checks names but permits link entries and link targets

**File:** `script/run_repository_evidence_environment.sh:87-97,164-170,200-202`
**Issue:** `validate_archive_entries` rejects absolute and `..` entry names, but it does not inspect tar/zip entry types or symlink/hardlink targets before extracting into the owned tool root. The current artifacts are checksum-pinned, which limits immediate exposure, but a future pin update or fixture can still contain a safe-looking entry whose link target escapes the extraction root. That makes the claimed archive-containment guard incomplete.
**Fix:** Reject symlink and hardlink entries (or validate their resolved targets remain inside the extraction root) before extraction, and add tar and zip negative controls containing safe-named links to `../outside`.

### WR-03: Sorted ownership edges can reject valid multi-level expansions

**File:** `script/check_phase166_ownership_ledger.py:154-177`
**Issue:** The validator requires edge rows to be lexicographically sorted, but it also recognizes an expanded target as a valid source only after encountering the parent row. A valid chain such as `z -> m -> a` must sort as `m -> a`, `z -> m`; the first row is then rejected because `m` has not yet been added to `expansion_sources`. This makes graph validity depend on path spelling rather than reachability and prevents some legitimate ownership closures.
**Fix:** Validate sources after parsing the whole edge set: compute the set/graph reachable from Git candidates to a fixed point, then reject only sources outside that reachable set. Preserve deterministic sorted rendering as an independent check and add a reverse-lexical multi-hop fixture.

---

_Reviewed: 2026-09-10T04:26:29Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
