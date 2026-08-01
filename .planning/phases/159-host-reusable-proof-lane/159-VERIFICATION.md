---
phase: 159-host-reusable-proof-lane
verified: 2026-08-01T22:35:06Z
status: gaps_found
score: 21/23 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: passed
  previous_score: 23/23
  gaps_closed: []
  gaps_remaining:
    - "The configured Phoenix-host proof command omits the generated host proof and its typecheck scope."
    - "A single backslash remains accepted in TypeScript-interpolated endpoint configuration."
  regressions:
    - "The prior append-only passed reconciliation contradicts current-tree source and executable evidence."
gaps:
  - truth: "One automated command starts the configured Phoenix test host and executes the primary offline Playwright corpus through real UI mutation, IndexedDB queueing, app reconnect, one backend confirmation, empty outbox, and duplicate idempotency."
    status: failed
    reason: "The configured command runs only offline_sync.spec.ts and helper-only browser_online_restore.spec.ts. The generated host proof spec is absent and is neither executed nor typechecked, so the command can pass without the host-owned adapter/replay assertions."
    artifacts:
      - path: "examples/phoenix_host/package.json"
        issue: "proof:offline-island omits e2e/crosswake_proof_lane/proof_lane.spec.ts."
      - path: "examples/phoenix_host/tsconfig.offline_route_proof.json"
        issue: "files includes only the repository offline-route helper, not generated proof-lane support."
      - path: "examples/phoenix_host/e2e/crosswake_proof_lane/proof_lane.spec.ts"
        issue: "Generated host proof is absent from the fixture tree."
    missing:
      - "Fail closed when the generated host proof is absent, or include and typecheck it in the proof command."
      - "Exercise the real host adapter's backend confirmation, outbox drain, and duplicate replay assertions."
  - truth: "Config.normalize/1 rejects double-quote and backslash characters in sync_path and evidence_path with stable non-echoing PL-CONFIG-VALUE errors before any generator filesystem action."
    status: failed
    reason: "host_local_path?/1 rejects the two-backslash sequence but accepts a single backslash. That accepted byte is directly interpolated into a TypeScript double-quoted literal, changing its runtime value or making generated source invalid."
    artifacts:
      - path: "lib/crosswake/proof_lane/config.ex"
        issue: "Line 151 tests a two-backslash sequence rather than one backslash character."
      - path: "priv/templates/crosswake/proof_lane/e2e/support/proof_lane.ts.eex"
        issue: "sync_path and evidence_path are raw EEx interpolation in TypeScript string literals."
      - path: "test/crosswake/proof_lane/config_test.exs"
        issue: "Regression uses two backslashes; no case covers one backslash."
    missing:
      - "Reject every single backslash before rendering or write authority."
      - "Add direct-config, application-config, selected-config, render, and pre-write regressions using exactly one backslash for both endpoint keys."
---

# Phase 159: Host-Reusable Proof Lane Verification Report

**Phase Goal:** Generate configurable host-owned browser, shell, offline-island, and physical-device proof scaffolding.
**Verified:** 2026-08-01T22:35:06Z
**Status:** gaps_found
**Re-verification:** Yes — current-tree review after the prior append-only `passed` reconciliation.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Generation is non-destructive and supports a diff/check mode. | ✓ VERIFIED | `mix test test/crosswake/proof_lane/config_test.exs test/mix/tasks/crosswake_gen_proof_lane_test.exs` exited 0; current generator normalizes before `generate/check/diff` and delegates destination operations to `GeneratorFS`. |
| 2 | Existing browser tests and fixtures remain the primary web/island coverage. | ✗ FAILED | `npm run proof:offline-island` passed 5 tests, but `package.json` excludes the generated host proof; the existing browser helper tests can pass after that real proof is deleted. |
| 3 | Native proof is limited to shell boot/auth, kill/relaunch replay, and offline pack audio. | ✓ VERIFIED | The generated driver exposes only adapter-derived `passed/blocked/unavailable`; 27 focused template/iOS/evidence tests passed and the verifier requires exact XCTest/XCUITest evidence before `passed`. |
| 4 | Evidence generation fails when sensitive payload or identity fields appear. | ✓ VERIFIED | `test/crosswake/proof_lane/evidence_test.exs` passed in the 27-test focused gate; evidence construction and promotion remain typed, allowlisted, and final-byte scanned. |
| 5 | The closed proof-lane configuration rejects unsafe endpoint input before rendering any language surface. | ✗ FAILED | Direct `Config.normalize/1` with `/study/` plus one backslash plus `n` returned `{:ok, %Config{...}}`; raw EEx then makes that value a TypeScript escape. |

**Score:** 21/23 must-haves verified (0 present, behavior-unverified).

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `lib/crosswake/proof_lane/config.ex` | Closed endpoint normalization | ✗ STUB AT SECURITY BOUNDARY | Existing tests cover quote and two-backslash values, but line 151 accepts one backslash. |
| `priv/templates/crosswake/proof_lane/e2e/support/proof_lane.ts.eex` | Generated browser adapter | ⚠️ HOLLOW | Substantive template, but raw endpoint interpolation makes accepted single-backslash input unsafe. |
| `examples/phoenix_host/package.json` | Runnable primary proof corpus | ✗ UNWIRED | The passing script lacks the generated host proof. |
| `examples/phoenix_host/tsconfig.offline_route_proof.json` | Typecheck of exercised proof surfaces | ✗ UNWIRED | Excludes `e2e/crosswake_proof_lane/support/proof_lane.ts` and any generated spec. |
| `lib/crosswake/proof_lane/generator.ex` + `generator_fs.ex` | Missing-only generator/check/diff lifecycle | ✓ VERIFIED | Substantive, wired through the Mix task, and focused generator tests passed. |
| `script/verify_generated_ios_shell.sh` and generated iOS templates | Fail-closed native scaffold verifier | ✓ VERIFIED | Exact evidence transcript gate is wired before its only `passed` branch; focused iOS verifier tests passed. |
| `lib/crosswake/proof_lane/evidence.ex` | Safe retained-evidence construction and promotion | ✓ VERIFIED | Focused evidence regressions passed. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `script/verify_phoenix_host_proof_lane.sh` | generated host proof | `npm run proof:offline-island` | ✗ NOT WIRED | Command targets only `offline_sync.spec.ts` and `browser_online_restore.spec.ts`; no generated proof exists. |
| TypeScript proof typecheck | generated proof-lane support | `tsconfig.offline_route_proof.json` | ✗ NOT WIRED | Only `e2e/support/offline_route_proof.*` files are listed. |
| `Config.normalize/1` | generated TypeScript config | EEx assignment | ✗ NOT SAFE | A single backslash reaches `syncPath: "<%= @config.sync_path %>"`. |
| Generator | filesystem boundary | `GeneratorFS` | ✓ WIRED | All generate/check/diff entry points call the confined filesystem helper. |
| iOS bundle transcript | `emit_proof_outcome passed` | three exact test markers | ✓ WIRED | Script checks all markers before line 170's passed outcome. |
| Evidence builder | promotion seam | allowlist + scanner | ✓ WIRED | Focused evidence suite passed. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Generated browser config | `proofLaneConfig.syncPath` / `evidencePath` | normalized endpoint fields | No | ✗ HOLLOW — a valid-by-normalizer one-backslash value is reinterpreted by TypeScript. |
| Phoenix host proof command | browser proof assertions | `proof:offline-island` target list | No | ✗ DISCONNECTED — real generated/host adapter proof is absent and not selected. |
| Phoenix offline fixture | mutation ID and IndexedDB outbox | real UI, IndexedDB, reconnect, Ecto | Yes | ✓ FLOWING — its one spec passed, but it cannot substitute for the omitted generated host proof. |
| Native scaffold | host adapter outcome | host-supplied factory plus exact test markers | Yes when supplied | ✓ FLOWING — no host authority is fabricated; nil adapter remains non-passing. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Single-backslash endpoint rejects before render/write | `mix run -e 'Config.normalize(...)'` with one backslash | Returned `{:ok, %Config{sync_path: "/study/\\n"}}`. | ✗ FAIL |
| Existing focused config/generator gate | `mix test test/crosswake/proof_lane/config_test.exs test/mix/tasks/crosswake_gen_proof_lane_test.exs` | Exit 0 despite the direct counterexample. | ✓ PASS — coverage gap |
| Existing focused template/iOS/evidence gate | `mix test ...template_contract... ...ios_verifier... ...evidence...` | 27 tests, 0 failures. | ✓ PASS |
| Configured Phoenix browser proof | `npm --prefix examples/phoenix_host run proof:offline-island` | 5 tests passed; generated proof absent and omitted. | ✗ FAIL |
| Browser helper typecheck | `npm --prefix examples/phoenix_host run typecheck:offline-route-proof` | Exit 0; generated support excluded. | ✗ FAIL |
| Shell syntax and phase formatting | `bash -n ...; mix format --check-formatted ...` | Exit 0. | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| PROOF-01 | 159-01, 02, 03, 05, 06, 08, 09, 12–17 | Configurable host-owned scaffolding without overwriting host files | ✓ SATISFIED | Missing-only generator lifecycle is wired and focused generator regressions pass. |
| PROOF-02 | 159-01, 02, 05, 08, 10, 12, 14, 16, 17 | Route/storage/mutation/endpoint/router/shell-root configuration | ✗ BLOCKED | A single backslash is accepted for endpoint configuration and can change/invalidly render generated TypeScript. |
| PROOF-03 | 159-01, 03, 06, 09, 10, 12, 14, 15, 17 | Preserve browser/unit/fixture corpus and add only bounded shell/island coverage browser automation cannot provide | ✗ BLOCKED | The advertised proof command omits the generated, host-owned browser proof and can pass on helper-only tests. |
| PROOF-04 | 159-01, 04, 07, 10, 11, 12, 14, 17 | Reject sensitive retained evidence | ✓ SATISFIED | Focused evidence suite passes; no contradicting data-flow was found. |

Every Phase 159 plan requirement ID (`PROOF-01` through `PROOF-04`) appears in `REQUIREMENTS.md`; no orphaned Phase 159 requirement was found.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `examples/phoenix_host/package.json` | 8 | Proof command is a selective corpus with no generated host proof | 🛑 BLOCKER | A green proof artifact does not establish generated host adapter/replay behavior. |
| `examples/phoenix_host/tsconfig.offline_route_proof.json` | 10–13 | Narrow `files` allowlist excludes generated support | 🛑 BLOCKER | Typecheck cannot reveal errors in the surface the generator is meant to supply. |
| `lib/crosswake/proof_lane/config.ex` | 141–155 | Two-backslash check instead of one-backslash rejection | 🛑 BLOCKER | Unsafe input crosses a supposedly closed config boundary. |
| `priv/templates/crosswake/proof_lane/e2e/support/proof_lane.ts.eex` | 63–64 | Raw EEx interpolation inside TypeScript literals | 🛑 BLOCKER | An accepted escape changes generated source semantics. |

No `TBD`, `FIXME`, or `XXX` marker was found in the inspected Phase 159 implementation surface. `.planning/config.json` remains the pre-existing modified file with SHA-256 `de08e6a97eedb77d5b7bb23c1193c1e4aab126508e8cd26ea029e824f3391ab8`; this verification did not edit it.

### Gaps Summary

Phase 159 has not achieved its proof-scaffolding goal in the current tree. Two independent, reproducible failures remain:

1. The claimed one-command Phoenix proof does not run or typecheck the generated host proof, and still returns green when that file is absent.
2. The closed endpoint boundary accepts exactly one backslash, which subsequently reaches a raw TypeScript string interpolation.

Neither item is deferred to Phases 160–162. Those phases own replay/auth capability, pack/audio implementation, and physical-iPhone evidence; Phase 159 itself owns truthful host proof scaffolding and its closed configuration boundary.

---

_Verified: 2026-08-01T22:35:06Z_
_Verifier: the agent (gsd-verifier)_
