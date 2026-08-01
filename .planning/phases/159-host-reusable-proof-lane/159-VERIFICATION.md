---
phase: 159-host-reusable-proof-lane
verified: 2026-08-01T02:21:09Z
status: gaps_found
score: 21/23 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: passed
  previous_score: 23/23
  gaps_closed:
    - "Post-create read, write, fsync, and manifest-collision cleanup regressions remain covered by the focused generator suite."
  gaps_remaining: []
  regressions:
    - "A generated iOS lane without a host adapter is promoted as passed."
    - "Accepted endpoint configuration can render syntactically invalid TypeScript."
gaps:
  - truth: "Missing replay/auth or pack/audio capability yields a named blocked or unavailable result and cannot become a passing proof claim."
    status: failed
    reason: "The generated host-adapter factory always returns nil, the XCUITest explicitly accepts Unavailable, and the verifier returns passed solely after both bundles execute. An unintegrated host lane is therefore reported as successful."
    artifacts:
      - path: "priv/templates/crosswake/proof_lane/ios/ProofLaneDriver.swift.eex"
        issue: "ProofLaneHostAdapterFactory.make/0 unconditionally returns nil."
      - path: "priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneUITests/ProofLaneUITests.swift.eex"
        issue: "Lifecycle test asserts that the outcome contains Unavailable."
      - path: "script/verify_generated_ios_shell.sh"
        issue: "Emits passed after bundle execution without requiring an installed, non-placeholder adapter."
    missing:
      - "Make missing or placeholder host integration a stable blocked outcome and require adapter evidence before passed."
      - "Add a regression proving an unconnected generated lane cannot exit passed."
  - truth: "The closed proof-lane configuration rejects unsafe input before rendering any language surface."
    status: failed
    reason: "Config.normalize/1 accepts a double quote in sync_path/evidence_path and the EEx template interpolates the value directly into a TypeScript double-quoted literal."
    artifacts:
      - path: "lib/crosswake/proof_lane/config.ex"
        issue: "host_local_path?/1 does not reject quote or backslash characters."
      - path: "priv/templates/crosswake/proof_lane/e2e/support/proof_lane.ts.eex"
        issue: "sync_path and evidence_path are raw EEx interpolation within TypeScript string literals."
    missing:
      - "Reject TypeScript-string-unsafe endpoint input, or encode rendered values with a real JSON/TypeScript string encoder."
      - "Add generation/typecheck regressions for quote and backslash endpoint input before any file is written."
---

# Phase 159: Host-Reusable Proof Lane Verification Report

**Phase Goal:** Generate configurable host-owned browser, shell, offline-island, and physical-device proof scaffolding.
**Verified:** 2026-08-01T02:21:09Z
**Status:** gaps_found
**Re-verification:** Yes — previous completion evidence was checked against the current source and the post-completion code-review findings.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Generation is non-destructive and supports a diff/check mode. | ✓ VERIFIED | Focused generator tests passed; the prior post-create cleanup paths remain present and no new failure was observed in this check. |
| 2 | Existing browser tests and fixtures remain the primary web/island coverage. | ✓ VERIFIED | `bash script/verify_phoenix_host_proof_lane.sh` typechecked the host proof and ran all five Playwright tests successfully. |
| 3 | Native proof is limited to shell boot/auth, kill/relaunch replay, and offline pack audio. | ✗ FAILED | The native scaffold's only adapter factory returns `nil`; its UI test expects `Unavailable`, while the verifier still emits `passed`. This is false positive proof, not a blocked prerequisite. |
| 4 | Evidence generation fails when sensitive payload or identity fields appear. | ✓ VERIFIED | Focused evidence and template-contract ExUnit checks passed; current review findings do not invalidate the typed allowlist/final-scan path. |

**Roadmap score:** 3/4 success criteria verified.

### Detailed Must-Have Score

**Score:** 21/23 must-haves verified (0 present, behavior-unverified).

The two failed must-haves are independently reproducible, code-contract failures. They are not human-verification items: a source-level unconditional `nil` and direct unescaped rendering make absence of the required behavior observable.

## Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `lib/crosswake/proof_lane/config.ex` | Closed normalized configuration boundary | ✗ FAILED | Accepts `sync_path: "/proof\""` despite this being unsafe for the rendered TypeScript surface. |
| `priv/templates/crosswake/proof_lane/e2e/support/proof_lane.ts.eex` | Host-owned browser adapter | ✗ FAILED | Direct interpolation renders `syncPath: "/proof"",`, an invalid TypeScript literal. |
| `priv/templates/crosswake/proof_lane/ios/ProofLaneDriver.swift.eex` | Host-adapter-backed native proof driver | ✗ FAILED | Factory at lines 18–21 always returns `nil`; no host crossing is installed. |
| `priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneUITests/ProofLaneUITests.swift.eex` | Lifecycle XCUITest boundary | ✗ FAILED | Treats the placeholder `Unavailable` state as the expected lifecycle outcome. |
| `script/verify_generated_ios_shell.sh` | Fail-closed shared-scheme verifier | ✗ FAILED | Returns `passed` after test-bundle completion, without adapter-installation evidence. |
| `lib/crosswake/proof_lane/generator.ex` + `generator_fs.ex` | Missing-only generator/check/diff lifecycle | ✓ VERIFIED | Present, substantive, wired to the generator task, and focused lifecycle tests passed. |
| Browser helper and Phoenix-host script | Primary browser/island corpus | ✓ VERIFIED | Live typecheck and five Playwright tests passed. |
| `lib/crosswake/proof_lane/evidence.ex` | Typed safe evidence construction/promotion | ✓ VERIFIED | Focused evidence tests passed. |

## Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `Config.normalize/1` | generated TypeScript config | EEx assigns | ✗ NOT SAFE | Accepted quote value flows directly into a TypeScript quoted literal without encoding. |
| `ProofLaneHostAdapterFactory.make/0` | `ProofLaneApp` / UI lifecycle | generated driver factory | ✗ NOT WIRED | Factory returns `nil`, so the generated app has no host adapter. |
| Generated XCUITest | verifier outcome | shared-scheme bundle execution | ✗ NOT SAFE | XCUITest accepts `Unavailable`; shell script maps only bundle execution to `passed`. |
| Phoenix proof script | existing offline browser corpus | TypeScript + Playwright | ✓ WIRED | Real host run completed all five tests. |
| Evidence builder | final scan/native promotion | allowlist and promotion seam | ✓ WIRED | Focused evidence tests passed. |

## Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Generated browser adapter | `proofLaneConfig.syncPath` | normalized `sync_path` | No | ✗ HOLLOW — accepted data renders invalid source when it contains a quote. |
| Generated iOS probe | `ProofLaneHostAdapter` | `ProofLaneHostAdapterFactory.make()` | No | ✗ DISCONNECTED — unconditional `nil` leaves only placeholder unavailable state. |
| Phoenix Playwright proof | mutation ID and IndexedDB outbox | real UI, IndexedDB, reconnect, Ecto assertion | Yes | ✓ FLOWING |
| Retained evidence | typed sanitized fields | allowlist and canonical bytes | Yes | ✓ FLOWING |

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Unsafe endpoint fails before rendering | `mix run -e 'Config.normalize(...)'` with `sync_path: "/proof\""` | Returned `{:ok, %Config{sync_path: "/proof\""}}`. | ✗ FAIL |
| Rendered browser config is valid for accepted input | EEx render of browser template with that accepted config | Rendered `syncPath: "/proof"",` at line 63. | ✗ FAIL |
| Focused proof-lane regression suite | `mix test` for config, template, iOS-verifier, and generator tests | Exit 0; existing suite does not cover either failure. | ✓ PASS (coverage gap) |
| Existing browser corpus remains primary | `bash script/verify_phoenix_host_proof_lane.sh` | Typecheck and 5 Playwright tests passed. | ✓ PASS |
| Shell scripts parse | `bash -n script/verify_generated_ios_shell.sh script/verify_phoenix_host_proof_lane.sh` | Exit 0. | ✓ PASS |

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| PROOF-01 | 159-01, 02, 03, 05, 06, 08, 09, 12–14 | Configurable host-owned scaffold without overwriting host files | ✗ BLOCKED | A generated native scaffold without a host adapter is promoted as successful rather than blocked. |
| PROOF-02 | 159-01, 02, 05, 08, 10, 12, 14 | Route/storage/mutation/endpoint/router/shell-root configuration | ✗ BLOCKED | Accepted endpoint input can make generated TypeScript syntactically invalid. |
| PROOF-03 | 159-01, 03, 06, 09, 10, 12, 14 | Preserve browser/unit/fixture corpus and add only bounded shell/island coverage | ✗ BLOCKED | Browser corpus is preserved, but the claimed native proof accepts an unconnected placeholder as passed. |
| PROOF-04 | 159-01, 04, 07, 10, 11, 12, 14 | Reject sensitive retained evidence | ✓ SATISFIED | Focused evidence checks passed; no contradicting implementation was found. |

All four IDs declared in Phase 159 plan frontmatter (`PROOF-01` through `PROOF-04`) are present in `.planning/REQUIREMENTS.md`. No Phase 159 orphaned requirement was found.

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `priv/templates/crosswake/proof_lane/ios/ProofLaneDriver.swift.eex` | 18–21 | Placeholder factory unconditionally returns `nil` | 🛑 BLOCKER | Native proof cannot observe a host adapter. |
| `priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneUITests/ProofLaneUITests.swift.eex` | 10–17 | XCUITest declares `Unavailable` to be success | 🛑 BLOCKER | Placeholder state satisfies the test that feeds a passed verifier result. |
| `script/verify_generated_ios_shell.sh` | 164 | Passed outcome keyed only to bundle execution | 🛑 BLOCKER | Missing integration is falsely promoted. |
| `lib/crosswake/proof_lane/config.ex` | 141–144 | Path grammar allows quote/backslash | 🛑 BLOCKER | Unsafe configuration reaches generated source. |
| `priv/templates/crosswake/proof_lane/e2e/support/proof_lane.ts.eex` | 63–64 | Raw EEx string interpolation | 🛑 BLOCKER | Accepted quotes produce invalid TypeScript. |

No unreferenced `TBD`, `FIXME`, or `XXX` debt marker was found in the Phase 159 implementation surface. The pre-existing `.planning/config.json` remains modified but byte-identical during verification (SHA-256 `de08e6a97eedb77d5b7bb23c1193c1e4aab126508e8cd26ea029e824f3391ab8` before and after).

## Gaps Summary

Phase 159 has not achieved its goal. The prior cleanup gaps remain covered, but two independent regressions invalidate the fail-closed, configurable proof lane:

1. The generated iOS proof can report `passed` with no installed host adapter.
2. Accepted endpoint configuration can generate invalid TypeScript after output is rendered.

Neither concern is deferred to Phases 160–162: those phases own replay/auth, pack/audio, and physical-device evidence, while this phase explicitly owns a truthful scaffold and its closed configuration boundary. Both are blocking gaps requiring source and test fixes before the phase can be completed.

---

_Verified: 2026-08-01T02:21:09Z_
_Verifier: the agent (gsd-verifier)_
