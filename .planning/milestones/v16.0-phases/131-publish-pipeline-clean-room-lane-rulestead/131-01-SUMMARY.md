---
phase: 131-publish-pipeline-clean-room-lane-rulestead
plan: "01"
subsystem: publish-pipeline
tags: [hex-publish, release-please, companion-extraction, elixir]
status: complete

dependency_graph:
  requires: []
  provides:
    - crosswake_dep/0 env-conditional resolver in packages/crosswake_rulestead/mix.exs
    - release-please crosswake_rulestead component registration with release-as 0.1.0
    - rulestead_release_created / rulestead_tag_name / rulestead_version output aliases
    - verify_companion_package.sh Step 2 dep-presence gate (hex_metadata.config)
    - extract_companion.md Phase 131+ registration recipe for rindle reuse
  affects:
    - .github/workflows/release-please.yml (output block extended)
    - release-please-config.json (new elixir component)
    - .release-please-manifest.json (0.1.0 baseline for crosswake_rulestead)
    - script/verify_companion_package.sh (dress-rehearsal gate removed, Step 2 activated)
    - script/extract_companion.md (Step 12 generalized, crosswake_dep/0 pattern documented)

tech_stack:
  patterns:
    - Env-conditional dep resolver via System.get_env in mix.exs private function
    - release-please manifest mode with separate-pull-requests for independent companion versioning
    - release-please-action v4 bracket-notation slash-path output aliasing (D-08)
    - hex_metadata.config dep-presence assertion via grep (D-14)

key_files:
  modified:
    - packages/crosswake_rulestead/mix.exs
    - release-please-config.json
    - .release-please-manifest.json
    - .github/workflows/release-please.yml
    - script/verify_companion_package.sh
    - script/extract_companion.md

decisions:
  - "crosswake_dep/0: env-conditional branch on CROSSWAKE_RELEASE=1 (Hex dep) vs unset (path dep); path: literal appears inside function body post-pivot — expected (Pitfall 4)"
  - "verify script Step 3 uses env -u CROSSWAKE_RELEASE to restore path dep context matching committed mix.lock for local compile"
  - "Step 12 rewritten as generalized registration recipe rather than just removing the prohibition; crosswake_dep/0 pivot recap added to recipe"

metrics:
  duration: "6m"
  completed: "2026-06-26"
  tasks: 3
  files_modified: 6
---

# Phase 131 Plan 01: Publish Pipeline Foundation — Release-Please + Dep Pivot Summary

## One-liner

Env-conditional `crosswake_dep/0` resolver in companion `mix.exs`, `crosswake_rulestead` registered as independent release-please elixir component (not in lockstep group), slash-path output aliases wired, and `verify_companion_package.sh` Step 2 activated with `hex_metadata.config` dep-presence gate.

## What Was Built

**Task 1 — `crosswake_dep/0` resolver (ca484ae)**

Added `defp crosswake_dep` private function to `packages/crosswake_rulestead/mix.exs` that branches on `System.get_env("CROSSWAKE_RELEASE") == "1"`:
- With `CROSSWAKE_RELEASE=1`: returns `{:crosswake, "~> 0.1"}` (honest Hex requirement in tarball)
- Without: returns `{:crosswake, path: "../.."}` (local/in-tree CI tests against LOCAL core, D-11)

`deps/0` now calls `crosswake_dep()` instead of the bare path tuple. `@version "0.1.0"` and its `# x-release-please-version` marker are byte-identical to before. Compiles clean with `--warnings-as-errors` (engine-absent default).

**Task 2 — Release-please registration + output aliases (0522be8)**

- `release-please-config.json`: `packages/crosswake_rulestead` entry added — `component: crosswake_rulestead`, `release-type: elixir`, `separate-pull-requests: true`, `release-as: "0.1.0"` (D-04 first-cut bootstrap), `extra-files: ["packages/crosswake_rulestead/mix.exs"]` (D-02), full `changelog-sections`. NOT added to `linked-versions` components array (SC#1, D-01).
- `.release-please-manifest.json`: `"packages/crosswake_rulestead": "0.1.0"` added (D-03).
- `.github/workflows/release-please.yml`: three output aliases in `release-please` job `outputs:` block — `rulestead_release_created`, `rulestead_tag_name`, `rulestead_version` — each reading from bracket-notation `packages/crosswake_rulestead--{name}` slash-path outputs (D-08).

**Task 3 — verify script + extract_companion.md (a259192)**

- `script/verify_companion_package.sh`: dress-rehearsal `HAS_PATH_DEP` gate removed (it would wrongly stay in dress-rehearsal mode because `path:` still appears inside `crosswake_dep/0` body — Pitfall 4). Step 1 and Step 2 now always run the full tarball path under `CROSSWAKE_RELEASE=1`. Step 2 replaces old `hex.publish --dry-run` with `hex_metadata.config` dep-presence grep (D-12/D-14). Step 3 uses `env -u CROSSWAKE_RELEASE mix compile --warnings-as-errors` to restore path dep context matching the committed `mix.lock`. Full end-to-end: `CROSSWAKE_RELEASE=1 bash script/verify_companion_package.sh crosswake_rulestead` exits 0, Steps 1–3 all green.
- `script/extract_companion.md`: Step 4 updated with `crosswake_dep/0` env-conditional pattern; Step 10 updated with `CROSSWAKE_RELEASE=1` usage; Step 12 rewritten from "DON'T touch release-please" into "Register the release-please component (Phase 131+)" with the mechanical 6-step recipe parameterized for rindle (Phase 132) reuse (D-05/D-16). Checklist Summary extended with release-please registration items.

## Verification Results

All plan acceptance criteria met:

| Check | Result |
|-------|--------|
| `grep -q 'defp crosswake_dep' packages/crosswake_rulestead/mix.exs` | PASS |
| `cd packages/crosswake_rulestead && mix compile --warnings-as-errors` | PASS |
| `@version "0.1.0"` / `# x-release-please-version` marker unchanged | PASS |
| `python3` JSON assertions (config+manifest OK, not in linked-versions) | PASS |
| `grep -q "rulestead_release_created:" .github/workflows/release-please.yml` | PASS |
| `grep -q "packages/crosswake_rulestead--release_created" ...` | PASS |
| `bash -n script/verify_companion_package.sh` | PASS |
| `grep -q 'HAS_PATH_DEP' verify_companion_package.sh` exits non-zero | PASS |
| `grep -q 'CROSSWAKE_RELEASE=1 mix hex.build --unpack' ...` | PASS |
| `grep -q 'hex_metadata.config' ...` | PASS |
| `grep -q 'hex.publish --dry-run' ...` exits non-zero | PASS |
| `CROSSWAKE_RELEASE=1 bash script/verify_companion_package.sh crosswake_rulestead` | PASS — Steps 1/2/3 all green |

## Deviations from Plan

**1. [Rule 1 - Bug] `env -u CROSSWAKE_RELEASE` in Step 3 of verify script**

- **Found during:** Task 3 end-to-end verification
- **Issue:** Script called with `CROSSWAKE_RELEASE=1` from the caller; Step 3 `mix compile` inherited this env var and resolver switched to Hex dep, but `mix.lock` has path dep locked → `mix compile` failed with "dependency not available, run mix deps.get"
- **Fix:** Step 3 now runs `env -u CROSSWAKE_RELEASE mix compile --warnings-as-errors` to unset the env var before compiling, restoring path dep resolution that matches the committed `mix.lock` (correct for local dev compile)
- **Files modified:** `script/verify_companion_package.sh`
- **Commit:** a259192

**2. [Rule 2 - Improvement] "HAS_PATH_DEP" removed from comments too**

- **Found during:** Acceptance criteria check (`grep -q 'HAS_PATH_DEP'` must exit non-zero)
- **Issue:** The string "HAS_PATH_DEP" remained in a comment explaining the removal of the gate
- **Fix:** Reworded comment to describe the gate behavior without using the old variable name
- **Files modified:** `script/verify_companion_package.sh`
- **Commit:** a259192 (same)

## Known Stubs

None. All acceptance criteria are fully implemented — no placeholder values or deferred wiring.

## Threat Flags

None. No new network endpoints, auth paths, or schema changes introduced beyond the planned scope. The `release-please-config.json` change does expose version metadata (T-131-03: accepted, public release metadata only).

## Self-Check: PASSED

- `packages/crosswake_rulestead/mix.exs` — FOUND, `defp crosswake_dep` present
- `release-please-config.json` — FOUND, `packages/crosswake_rulestead` entry present
- `.release-please-manifest.json` — FOUND, `packages/crosswake_rulestead` key present
- `.github/workflows/release-please.yml` — FOUND, `rulestead_release_created` alias present
- `script/verify_companion_package.sh` — FOUND, Step 2 active, HAS_PATH_DEP absent
- `script/extract_companion.md` — FOUND, `crosswake_dep` and `release-as` present
- Commits: ca484ae, 0522be8, a259192 — all verified in git log
