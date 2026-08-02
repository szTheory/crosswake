---
phase: 159-host-reusable-proof-lane
verified: 2026-08-02T00:06:25Z
status: gaps_found
score: 22/23 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 22/23
  gaps_closed:
    - "A generated host receives an executable Playwright browser/offline-island proof scaffold that exercises the generated support adapter."
  gaps_remaining:
    - "Generation and evidence promotion use collision-safe staged writes; interruption or a concurrent writer cannot overwrite host files or expose a partial retained artifact."
  regressions:
    - "Evidence promotion accepts a stage-directory symlink swapped after scanning and publishes it successfully."
    - "Manifest publication accepts a swapped staging-file symlink and reports it as a created generated artifact."
gaps:
  - truth: "Generation and evidence promotion use collision-safe staged writes; interruption or a concurrent writer cannot overwrite host files or expose a partial retained artifact."
    status: failed
    reason: "Both final publication helpers follow an attacker-controlled staging symlink after the last validation, return success, and leave a symlink at the supposedly safe host/evidence destination."
    artifacts:
      - path: "priv/native/crosswake_evidence_promote.c"
        issue: "Uses stat(), which follows a swapped stage-directory symlink, immediately before no-replace rename."
      - path: "priv/native/crosswake_proof_lane_fs.c"
        issue: "Uses linkat() on the staging leaf without O_NOFOLLOW/fstat regular-file validation, allowing a swapped manifest symlink to be published."
    missing:
      - "Reject non-regular/no-follow staging sources at the final publication boundary and add deterministic symlink-swap regressions for evidence and manifest publication."
---

# Phase 159: Host-Reusable Proof Lane Verification Report

**Phase Goal:** Generate configurable host-owned browser, shell, offline-island, and physical-device proof scaffolding.
**Verified:** 2026-08-02T00:06:25Z
**Status:** gaps_found
**Re-verification:** Yes — after gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Generation is non-destructive and supports diff/check behavior. | ✓ VERIFIED | Focused ExUnit generator/config/template/evidence suite passed; `Generator.generate/1`, `check/1`, and `diff/1` are wired through `GeneratorFS`. The symlink-publication defect below is a separate final-write failure. |
| 2 | Existing browser tests and fixtures remain the primary web/island coverage. | ✓ VERIFIED | `bash script/verify_phoenix_host_proof_lane.sh` passed, generating an isolated v2 spec, typechecking it, and executing that exact spec through the existing Phoenix Playwright lifecycle. |
| 3 | Native proof is limited to shell boot/auth, kill/relaunch replay, and offline pack audio. | ✓ VERIFIED | iOS verifier/template controls passed; unavailable prerequisites remain closed `blocked`/`unavailable`, and the accessibility runtime is explicitly advisory rather than a device-support claim. |
| 4 | Evidence generation fails when sensitive payload or identity fields appear. | ✗ FAILED | Typed input rejection passes, but a symlink substituted after scanning can be promoted as retained evidence. The final retained destination therefore is not constrained to the scanned allowlisted artifact. |
| 5 | Generated browser proof is an executable host-owned additive scaffold, not an inert wrapper. | ✓ VERIFIED | The v2 template imports `proofLaneHostAdapter`, calls `runOfflineIslandProof`, and the isolated-host gate executed it; this closes the prior failed browser-template gap. |
| 6 | Generation and evidence promotion use collision-safe staged writes; interruption or a concurrent writer cannot overwrite host files or expose a partial retained artifact. | ✗ FAILED | Independent reproduction: evidence promotion returned `:ok` with a symlink destination after stage swap; manifest publication returned `{:ok, :created}` with a symlinked manifest after staging-leaf swap. |
| 7 | Configuration accepts exactly the required route, storage, mutation, endpoint, router, and shell-root inputs and rejects unsafe endpoint bytes before writes. | ✓ VERIFIED | `Config.normalize/1` is the single nine-key boundary; the focused suite passed quote/backslash, direct-struct, application, and selected-config pre-write controls. |

**Score:** 22/23 must-haves verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `lib/mix/tasks/crosswake.gen.proof_lane.ex` | iOS generator entry and action selection | ✓ VERIFIED | Exists, substantive, and calls the closed config boundary before generator actions. |
| `lib/crosswake/proof_lane/config.ex` | Closed configuration normalization | ✓ VERIFIED | Exists, substantive, and is exercised by focused configuration controls. |
| `lib/crosswake/proof_lane/generator.ex` | Missing-only rendered proof scaffolding | ⚠️ PARTIAL | Template wiring and missing-only behavior work, but manifest publication delegates to an unsafe final native helper. |
| `lib/crosswake/proof_lane/evidence.ex` | Typed safe evidence construction and final promotion | ⚠️ PARTIAL | Closed schema and stage scan are substantive, but the wired final native promotion can publish a substituted symlink. |
| `priv/native/crosswake_evidence_promote.c` | No-replace evidence directory publication | ✗ STUB AT SECURITY BOUNDARY | The helper exists and builds, but `stat(argv[1])` follows a symlink and cannot prove the stage directory is the scanned directory. |
| `priv/native/crosswake_proof_lane_fs.c` | No-follow manifest publication | ✗ STUB AT SECURITY BOUNDARY | The helper exists and builds, but `linkat(..., 0)` has no no-follow/regular-file check for the source leaf. |
| `priv/templates/crosswake/proof_lane/e2e/proof_lane.spec.ts.eex` | Executable generated browser proof | ✓ VERIFIED | Imports Playwright, support, and host adapter; declares and runs the generated offline-island test. |
| `priv/templates/crosswake/proof_lane/e2e/support/proof_lane_host_adapter.ts.eex` | Fail-closed host seam | ✓ VERIFIED | Missing host callbacks reject with stable `PL-BROWSER-HOST-ADAPTER`; fixture-backed generated output passed. |
| `priv/templates/crosswake/proof_lane/ios/CrosswakeProofLane.xcodeproj/project.pbxproj.eex` | XCTest/XCUITest target wiring | ✓ VERIFIED | Artifact checks and iOS contract verifier passed. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Generated browser spec | generated support and host adapter | imports and `runOfflineIslandProof(page, context, proofLaneHostAdapter, proofLaneConfig)` | ✓ WIRED | `verify.key-links` for Plan 159-21 reports all three declared links verified; browser gate passed. |
| Phoenix wrapper | isolated generated v2 spec | fresh isolated host, template provenance check, exact Playwright spec selection | ✓ WIRED | Wrapper excludes the repository surrogate, pre-seeds the adapter byte-for-byte, generates output, typechecks, then runs the exact generated spec. |
| `Evidence.promote/3` | evidence native publisher | final no-replace stage publication | ✗ NOT SAFELY WIRED | `before_promote` can replace the scanned stage with a symlink; helper returns success and publishes it. |
| `Generator.promote_manifest/4` | `GeneratorFS.publish/3` | staging-leaf manifest publication | ✗ NOT SAFELY WIRED | A staging symlink is linked as the destination manifest and reported `:created`. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Isolated generated browser spec | mutation ID, queue, backend result | Phoenix host UI, IndexedDB, reconnect endpoint, adapter callbacks | Yes — executed gate confirms one backend result, drained outbox, and duplicate idempotency | ✓ FLOWING |
| Retained evidence destination | scanned stage directory | stage created by `Evidence.promote/3` | No — stage can be swapped after scanning and before publication | ✗ HOLLOW / UNSAFE |
| Generated manifest | helper-owned staging leaf | `GeneratorFS.write/4` then native `publish_file` | No — a staging symlink can replace the generated leaf before publication | ✗ HOLLOW / UNSAFE |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Generator/config/template/iOS/evidence contract controls | `mix test test/mix/tasks/crosswake_gen_proof_lane_test.exs test/crosswake/proof_lane/config_test.exs test/crosswake/proof_lane/template_contract_test.exs test/crosswake/proof_lane/ios_verifier_test.exs test/crosswake/proof_lane/evidence_test.exs` | 40 tests passed | ✓ PASS, but does not cover staging-source swaps |
| Generated host browser proof | `bash script/verify_phoenix_host_proof_lane.sh` | Isolated rendered spec typechecked and one generated Playwright test passed | ✓ PASS |
| Script syntax and proof-lane formatting | `bash -n script/verify_generated_ios_shell.sh script/verify_phoenix_host_proof_lane.sh` and `mix format --check-formatted ...` | Exit 0 | ✓ PASS |
| Evidence symlink-swap publication | `mix run -e` with `before_promote` replacing the stage with a symlink | `{:ok, :symlink}` | ✗ FAIL |
| Manifest symlink-swap publication | `mix run -e` calling `GeneratorFS.publish/3` with a staging symlink | `{{:ok, :created}, :symlink}` | ✗ FAIL |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| PROOF-01 | 159-01 through 159-21 | Configurable host-owned ExUnit, Playwright, shell, and device scaffold without overwriting host files | ✗ BLOCKED | Browser scaffold is now executable, but the manifest publication path can report a symlinked host artifact as safely created. |
| PROOF-02 | 159-01 through 159-21 | Explicit route/storage/mutation/endpoint/router/shell configuration | ✓ SATISFIED | Closed nine-key normalizer and endpoint/path regressions pass before render or filesystem authority. |
| PROOF-03 | 159-01 through 159-21 | Preserve existing browser/unit/fixture corpus and add bounded host proof | ✓ SATISFIED | Existing Phoenix lifecycle remains primary; isolated generated output runs additively through it. |
| PROOF-04 | 159-01 through 159-21 | Evidence rejects raw mutation payloads, account identifiers, media, tokens, and stable device identifiers | ✗ BLOCKED | Input allowlist rejects sensitive values, but retention can publish an unscanned substituted symlink, invalidating the final privacy boundary. |

All plan-declared requirement IDs are PROOF-01, PROOF-02, PROOF-03, and PROOF-04; each appears in `REQUIREMENTS.md` and none is orphaned.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `priv/native/crosswake_evidence_promote.c` | 20–24 | `stat()` follows staging symlink before publication | 🛑 BLOCKER | A successfully retained evidence destination can escape the scanned privacy-safe artifact. |
| `priv/native/crosswake_proof_lane_fs.c` | 192–206 | `linkat()` publishes unverified staging leaf | 🛑 BLOCKER | A generated manifest can be a symlink despite a `:created` success result. |

No unreferenced `TBD`, `FIXME`, or `XXX` debt markers were found in the Phase 159 implementation files inspected. The two issues are not addressed by Phases 160–162: those phases cover replay/auth, pack/audio, and physical-device proof, not Phase 159 final publication safety.

### Gaps Summary

The prior executable-generated-browser gap is closed: the current tree renders, typechecks, and executes the generated spec in an isolated Phoenix host. The phase still fails its own collision-safe, privacy-safe publication contract. Both defects are observable and reproducible; they are BLOCKER gaps, not human-verification items. The required repair is a final no-follow, type-checked source boundary for both the evidence directory and manifest leaf, followed by regressions that perform the exact swaps reproduced here.

---

_Verified: 2026-08-02T00:06:25Z_
_Verifier: the agent (gsd-verifier)_
