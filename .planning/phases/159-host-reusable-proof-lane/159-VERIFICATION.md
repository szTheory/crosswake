---
phase: 159-host-reusable-proof-lane
verified: 2026-08-01T23:18:30Z
status: gaps_found
score: 22/23 must-haves verified
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "A generated host receives an executable Playwright browser/offline-island proof scaffold that exercises the generated support adapter."
    status: failed
    reason: "The generator renders an inert proof_lane.spec.ts module; the passing Phoenix corpus uses a separate hand-maintained example-host spec instead."
    artifacts:
      - path: "priv/templates/crosswake/proof_lane/e2e/proof_lane.spec.ts.eex"
        issue: "Contains neither a Playwright test declaration nor a call to the generated support module's runOfflineIslandProof."
      - path: "examples/phoenix_host/e2e/crosswake_proof_lane/proof_lane.spec.ts"
        issue: "Supplies the test and adapter callbacks outside the generator, masking the generated-template omission."
    missing:
      - "Generate a host-owned Playwright spec that imports test and runOfflineIslandProof and supplies explicit host adapter callbacks."
      - "Add a rendered-template contract and execution path proving that generated spec, rather than the repository fixture, is run."
---

# Phase 159: Host-Reusable Proof Lane Verification Report

**Phase Goal:** Generate configurable host-owned browser, shell, offline-island, and physical-device proof scaffolding.
**Verified:** 2026-08-01T23:18:30Z
**Status:** gaps_found
**Re-verification:** No — independent current-tree verification; the previous report had no `gaps:` section.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Generation is non-destructive and supports diff/check behavior. | ✓ VERIFIED | `Generator.generate/1`, `check/1`, and `diff/1` use `GeneratorFS`; the focused ExUnit gate passed rerun, read-only, interruption, and concurrent-winner controls. |
| 2 | One configurable invocation produces host-owned ExUnit, Playwright, shell, and iOS proof scaffolding without overwriting host files. | ✗ FAILED | The generated Playwright spec template is a non-runnable wrapper. It has no `@playwright/test` import, `test(...)`, or connection to generated support. Thus a newly generated host lacks the promised executable browser/offline-island scaffold. |
| 3 | Existing browser tests and fixtures remain the primary web/island coverage while the generated host proof is an additive member of that corpus. | ✗ FAILED | `bash script/verify_phoenix_host_proof_lane.sh` passed six tests, but its generated-proof test is `examples/phoenix_host/.../proof_lane.spec.ts`, a hand-maintained fixture not emitted by the template. The generator output cannot supply the additive member it claims to validate. |
| 4 | Configuration is closed and evidence rejects sensitive retained data; native proof does not falsely promote unavailable prerequisites. | ✓ VERIFIED | Focused config/evidence/iOS tests passed. `Config.normalize/1` owns all nine fields and rejects unsafe endpoint bytes; `Evidence.build/1` enforces its closed allowlist; iOS outcomes are closed to passed/blocked/unavailable. |

**Score:** 22/23 plan must-haves verified. The one failed browser-template wiring truth blocks the phase goal.

## Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `lib/mix/tasks/crosswake.gen.proof_lane.ex` | iOS generator and generate/check/diff selection | ✓ VERIFIED | Calls `Config.normalize/1` before `Generator.generate/check/diff`. |
| `lib/crosswake/proof_lane/config.ex` | Closed normalization boundary | ✓ VERIFIED | Exact nine-key validation and endpoint grammar are substantive; focused tests passed. |
| `lib/crosswake/proof_lane/generator.ex` | Missing-only desired-state rendering | ✓ VERIFIED | Maps the proof templates and delegates filesystem operations to `GeneratorFS`; focused generator tests passed. |
| `lib/crosswake/proof_lane/evidence.ex` | Typed safe evidence and no-replace promotion | ✓ VERIFIED | Closed schema, final scan, approved-byte hash source checks, and native promotion boundary are substantive; focused evidence tests passed. |
| `priv/templates/crosswake/proof_lane/e2e/support/proof_lane.ts.eex` | Generated offline-island helper | ⚠️ ORPHANED | It implements the semantic sequence, but the generated spec does not import or invoke it. |
| `priv/templates/crosswake/proof_lane/e2e/proof_lane.spec.ts.eex` | Executable generated browser proof | ✗ STUB | Lines 2–8 only define a type, a wrapper, and config. No Playwright test or adapter callbacks exist. |
| `priv/templates/crosswake/proof_lane/ios/CrosswakeProofLane.xcodeproj/project.pbxproj.eex` | XCTest/XCUITest target wiring | ✓ VERIFIED | Target-membership and iOS verifier controls passed in the focused gate. |

## Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `Mix.Tasks.Crosswake.Gen.ProofLane.run/1` | `Config.normalize/1` | selected/application config before action | ✓ WIRED | Direct call at task line 69. |
| `Generator.generate/1` | proof-lane templates | normalized config rendered into desired files | ✓ WIRED | Template map includes the browser spec and support template. |
| Generated `proof_lane.spec.ts` | generated `support/proof_lane.ts` | Playwright test calls `runOfflineIslandProof` | ✗ NOT_WIRED | No import or invocation exists in `e2e/proof_lane.spec.ts.eex`. |
| Phoenix wrapper | checked-in example spec | explicit package command | ✓ WIRED, misleading | Wrapper preflights and runs the example fixture; that proves the example, not generator output. |
| `Evidence.promote/2` | safe retained destination | final scan and no-replace native helper | ✓ WIRED | Code and focused evidence regression passed. |

## Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Generated browser spec | N/A | N/A | No browser test or adapter is rendered | ✗ DISCONNECTED |
| Checked-in Phoenix example spec | queued mutation / backend result | Real Phoenix test host and IndexedDB | Yes; its six-test command passes | ✓ FLOWING — but it is not generator output |

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Generator/config/evidence/iOS contract controls | `mix test test/mix/tasks/crosswake_gen_proof_lane_test.exs test/crosswake/proof_lane/config_test.exs test/crosswake/proof_lane/template_contract_test.exs test/crosswake/proof_lane/ios_verifier_test.exs test/crosswake/proof_lane/evidence_test.exs` | 40 tests passed | ✓ PASS |
| Primary Phoenix proof command | `bash script/verify_phoenix_host_proof_lane.sh` | TypeScript check passed; 6 Playwright tests passed | ✗ FALSE-GREEN for generated output: executable proof is the checked-in fixture, while the rendered spec is inert |

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| PROOF-01 | 159 plans | Configurable host-owned ExUnit, Playwright, shell, and device scaffold without overwrite | ✗ BLOCKED | Missing-only lifecycle is tested, but the generated Playwright scaffold is not executable. |
| PROOF-02 | 159 plans | Explicit route/storage/mutation/endpoint/router/shell configuration | ✓ SATISFIED | Closed nine-field `Config.normalize/1`; focused boundary tests passed. |
| PROOF-03 | 159 plans | Preserve existing browser/unit/fixture corpus and add bounded host proof | ✗ BLOCKED | Existing corpus is preserved, but the additive running browser proof is hand-maintained, not generated for a reusable host. |
| PROOF-04 | 159 plans | Evidence rejects raw sensitive data | ✓ SATISFIED | Typed allowlist and sensitive-content checks passed in the focused evidence gate. |

No Phase 159 requirement is orphaned from PLAN frontmatter: PROOF-01, PROOF-02, PROOF-03, and PROOF-04 are all declared and assessed above.

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `priv/templates/crosswake/proof_lane/e2e/proof_lane.spec.ts.eex` | 4–5 | Export-only wrapper in a `*.spec.ts` proof artifact | 🛑 BLOCKER | A generated host has no executable browser proof. |

No unreferenced `TBD`, `FIXME`, or `XXX` debt markers were found in the inspected Phase 159 implementation files.

## Gaps Summary

The phase’s central reusable browser/offline-island deliverable is not achieved. The current test command is healthy only because an example-host fixture manually duplicates the missing generated specification. This is not deferred to Phases 160–162: those phases cover replay/auth, pack/audio, and physical-device evidence, not repair of Phase 159’s generator output. The required remediation is to make the browser spec template executable and validate the rendered output directly.

---

_Verified: 2026-08-01T23:18:30Z_
_Verifier: the agent (gsd-verifier)_
