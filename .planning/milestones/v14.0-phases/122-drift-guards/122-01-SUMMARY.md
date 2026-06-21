---
phase: 122-drift-guards
plan: 01
subsystem: testing
tags: [elixir, exunit, drift-guard, json, jason, contract-versioning]

requires:
  - phase: 121-canonical-contract-source
    provides: "Crosswake.Bridge.Contract.version/0 as the authoritative contract version source; bridge_contract_vectors.json; updated manifests at 1.1.0"

provides:
  - "GUARD-01 merge-blocking ExUnit drift test for all committed contract version surfaces"
  - "Parse-based Jason.decode! check for compatibility.bridge_protocol_version in two hand-maintained crosswake_manifest.json files"
  - "Tripwire check for top-level bridge_protocol_version in three generated JSON files"
  - "Synthetic regression tests proving the guard is non-vacuous"
  - "House-contract failure message naming canonical source, each drifted surface, and fix command"

affects: [122-02, 122-03, 123-native-proof]

tech-stack:
  added: []
  patterns:
    - "Pure comparison helpers (compare_manifest_surface/3, compare_generated_surface/3) accept decoded maps so synthetic tests can feed drifted in-memory content without touching disk"
    - "Failure category atoms (:manifest_version_drift, :generated_version_drift) distinguish hand-maintained from generated surfaces"
    - "Anti-vacuity via synthetic regression tests that feed drifted in-memory content and assert failure categories are produced"

key-files:
  created:
    - test/crosswake/contract/contract_drift_test.exs
  modified: []

key-decisions:
  - "Read bridge_protocol_version from compatibility[bridge_protocol_version] for crosswake_manifest.json files (nested, not JSON root) — the plan referred to 'top-level' but the actual manifest structure nests it under compatibility"
  - "Use Jason.decode! + key lookup, never String.contains? or regex, because manifests carry prose mentions of bridge_protocol_version at lines 1135+ that text scans would falsely match"
  - "Two separate compare_* helpers (manifest vs generated) to keep failure categories distinct and the key extraction path explicit"

patterns-established:
  - "Drift-test module pattern: module attribute captures canonical value once, two explicit surface lists (primary + tripwire), pure compare helpers, format_failure_message/1 for house-contract messages, synthetic regressions prove non-vacuity"

requirements-completed: [GUARD-01]

duration: 3min
completed: 2026-06-20
status: complete
---

# Phase 122 Plan 01: Parse-Based Contract Version Drift Test Summary

**GUARD-01 ExUnit drift test reads bridge_protocol_version from all six committed surfaces via Jason.decode (never text grep), asserts each equals Crosswake.Bridge.Contract.version/0, and proves non-vacuity with synthetic regressions that feed drifted in-memory JSON and assert expected failure categories**

## Performance

- **Duration:** 3 min
- **Started:** 2026-06-20T18:19:32Z
- **Completed:** 2026-06-20T18:22:48Z
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments

- Created `test/crosswake/contract/contract_drift_test.exs` as `Crosswake.Contract.ContractDriftTest`
- Readability test asserts all six surface paths exist and canonical version matches semver pattern
- Primary drift test reads `compatibility.bridge_protocol_version` from both manifests and top-level `bridge_protocol_version` from three generated JSONs via Jason.decode, aggregating mismatches by category
- Two pure compare helpers accept decoded maps so synthetic tests feed drifted content without disk I/O
- Synthetic regression proves :manifest_version_drift is produced for a manifest map with wrong version
- Synthetic regression proves :generated_version_drift is produced for a generated-JSON map with wrong version
- Message format assertion verifies the failure message names `mix crosswake.contract.gen`, `lib/crosswake/bridge/contract.ex`, `Crosswake.Bridge.Contract.version/0`, the drifted path, actual version, and expected version
- Guard verified non-vacuous: temporarily mutating iOS manifest's compatibility.bridge_protocol_version to "0.9.0" made the test fail with the correct path, actual, expected, and fix command; git checkout restored the file

## Task Commits

1. **Task 1: Parse-assert all committed contract surfaces against the canonical version** - `4710015` (test)
2. **Task 2: Contract-form failure message + anti-vacuous synthetic regressions** - `3c9aa02` (test)

## Files Created/Modified

- `/Users/jon/projects/crosswake/test/crosswake/contract/contract_drift_test.exs` - GUARD-01 pure-Elixir ExUnit contract version drift guard; 5 tests covering readability, primary drift, and synthetic regressions

## Decisions Made

- Read `compatibility["bridge_protocol_version"]` for manifests (not JSON root) — the manifest structure nests this field under `compatibility`, while the plan's "top-level" wording referred to the primary machine-readable location vs the prose-mention decoys at lines 1135+. Using `get_in(decoded, ["compatibility", "bridge_protocol_version"])` correctly captures the value.
- Separate `compare_manifest_surface/3` vs `compare_generated_surface/3` helpers keep the two key-extraction paths explicit and the failure categories distinct.
- Jason.decode + key lookup throughout — never String.contains? or regex — to avoid false positives from prose mentions of `bridge_protocol_version` in compatibility_signal/compatibility_contract strings.

## Deviations from Plan

### Structural deviation: manifest key path is `compatibility.bridge_protocol_version`, not JSON root

- **Found during:** Task 1 — reading the actual iOS manifest structure before writing the test
- **Nature:** Plan stated "read the TOP-LEVEL bridge_protocol_version key" for manifests, but the actual manifests have this at `["compatibility"]["bridge_protocol_version"]` (line 350), not the JSON document root. The motivation for the "never grep" rule (lines 1135+ prose decoys) is accurate and unaffected — Jason.decode still solves it.
- **Decision:** Implemented `get_in(decoded, ["compatibility", "bridge_protocol_version"])` to read the actual location. The plan's intent (parse-based, non-grep, catches drift in the hand-maintained manifests) is fully satisfied.
- **Classification:** Auto-fix (Rule 1 — factual discrepancy between plan description and actual surface structure; implementing to actual structure is the only correct choice)
- **Committed in:** `4710015`

## Issues Encountered

None — test suite ran green on first attempt after implementing the correct key path.

## Threat Surface Scan

No new network endpoints, auth paths, file write paths, or schema changes introduced. This plan is test-only. No new threat flags.

## Self-Check

- [x] `test/crosswake/contract/contract_drift_test.exs` exists
- [x] `4710015` commit exists in git log
- [x] `3c9aa02` commit exists in git log
- [x] `mix test test/crosswake/contract/contract_drift_test.exs` passes: 5 tests, 0 failures

## Next Phase Readiness

GUARD-01 is complete. Phase 122 plan 02 (GUARD-03: contract_version_parity doctor check) can proceed. Phase 122 plan 03 (GUARD-02 + GUARD-04: CI workflow + branch-protection script) depends on both 01 and 02.

---
*Phase: 122-drift-guards*
*Completed: 2026-06-20*
