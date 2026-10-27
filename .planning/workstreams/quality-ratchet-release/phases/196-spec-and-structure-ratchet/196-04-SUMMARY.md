---
phase: 196-spec-and-structure-ratchet
plan: "04"
subsystem: testing
tags: [swift, xctest, vectors, non-vacuity, privacy]
requires:
  - phase: 196-03
    provides: Existing bounded vector-control dispatcher and rebuilt-resource contract
provides:
  - Swift reply 2 loaded and 2 completed landing-pad evaluations
  - Three metadata readers independently pin 15 loaded requests with corpus verdicts not applicable
  - Topology 5 loaded, 1 selected, 1 completed and checked reader-role inventory
affects: [196-05, 196-15, phase198-parity]
tech-stack:
  added: []
  patterns: [throwing XCTest resource setup, independently pinned populations, byte restoration and clean rebuild]
key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-EVIDENCE/swift-other-vectors.json
  modified:
    - packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/BridgeReplyLegTests.swift
    - packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/ActivationConformanceTests.swift
    - packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/OfflineIslandAdmissionTests.swift
    - packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/Phase180TwinFeasibilityTests.swift
    - packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/NavigationCoordinatorTests.swift
    - .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/vector-controls.mjs
key-decisions:
  - Metadata readers prove availability and loaded15; JSON verdict executions remain not applicable.
  - Evidence retains the exact helper revision actually tested rather than relabeling earlier receipts after new modes are added.
requirements-completed: []
actuals:
  tokens: 18989
  tasks: 3
  commits: 6
plan_head_before: 3aa4e14649a120324545279f7841f42c5343703d
plan_head_after: 75da76f2afd5153e63db1519b50be26544ca2613
coverage:
  - id: reply
    description: Two JSON replies complete real landing-pad and decoded roundtrip assertions
    requirement: SPEC-01
    verification:
      - kind: integration
        ref: node .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/vector-controls.mjs swift-reply
        status: pass
    human_judgment: false
  - id: metadata
    description: All three metadata owners reject unavailable or shortened request corpora
    requirement: SPEC-01
    verification:
      - kind: integration
        ref: node .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/vector-controls.mjs swift-metadata
        status: pass
    human_judgment: false
  - id: topology
    description: Real topology selection rejects input loss and duplicate selected IDs; reader roles checked from source
    requirement: SPEC-01
    verification:
      - kind: integration
        ref: node .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/vector-controls.mjs swift-topology
        status: pass
    human_judgment: false
duration: 17min
completed: 2026-10-27
status: complete
---

# Phase 196 Plan 04: Remaining real Swift vector readers Summary

**Swift proves reply 2/2 and topology 5/1/1; three metadata readers independently require 15 requests, with 18 real loss controls and byte-exact restoration.**

## Execution

One main checkout on `fix/spec-structure-ratchet`, starting at `3aa4e14649a120324545279f7841f42c5343703d`, based on main `b8398c38`. Recorded implementation window: 2026-10-27T14:58:50Z through 2026-10-27T15:15:46Z, 17 minutes rounded. Three tasks changed seven declared artifacts. The ledger measures six task commits before summary/lifecycle metadata. Actual tokens are `ceil(75956/4)` over the realized task diff, on the estimate's chars/4 scale.

Reply setup throws a named XCTest failure for missing or non-two-case input before the existing single-ID helpers can crash. The corpus path evaluates both actual landing pads and decodes the delivered script payload before collecting completed IDs. Existing adversarial and sink tests remain.

Each metadata owner decodes the real request collection and independently requires 15 cases before using its protocol version. Phase180's former `bridgeVersion()` file read now occurs in throwing setup and the helper returns that loaded version. Their authored inline/exported behaviors remain; JSON verdict executions are `null` with explicit not-applicable classification. There is no invented exclusion control for these unfiltered metadata readers.

Navigation's actual JSON read independently requires five loaded cases, exactly one `synthetic_authorized_root`, and one completed identity collected after authorization/state assertions. Its other six navigation tests remain inline.

The helper preserves the original Elixir and Swift-request public modes. New quick checks use only Node and synthetic scratch, reject population/selection loss and child failure, restore scratch bytes in finally, enforce a20-second deadline, and write no acceptance receipt. Full controls mutate actual canonical reader inputs, execute `swift package clean` then the exact owner suite for every attempt, restore bytes in finally, and perform a final clean restored build. Suppression mutates the reply loop's actual selection seam; all-suppressed execution fails its completed-count assertions. Output retention is relative commands, statuses, counts, timings and SHA-256 identities, without raw output, payloads or private paths.

## Task commits

| Task | RED | GREEN | Result |
| --- | --- | --- | --- |
| 196-04-01 | `8103e13e` | `28bb00b8` | Reply2/2 and four rebuilt loss controls |
| 196-04-02 | `a2a437b2` | `d4a74cfc` | Three metadata owners loaded15, nine rebuilt loss controls |
| 196-04-03 | `1d0d8102` | `75da76f2` | Topology5/1/1, five rebuilt loss controls,17 checked inventory rows |

Every commit used a successful privacy conditional with absolute per-file arguments before staging, followed immediately by a rescan. No tracked file was deleted. No dependency, lock, wire contract, canonical JSON, runtime source or CI lane changed. No push, PR, merge, publish, tag, remote deletion, worktree or subagent operation occurred.

## Verification

All commands run from repository root. Let `P=.planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet`.

| Exact command | Observed result |
| --- | --- |
| `node "$P/scripts/vector-controls.mjs" quick swift-reply` | Final exit0;2/2 TAP tests;25.5485ms |
| `node "$P/scripts/vector-controls.mjs" swift-reply` | Exit0;4 discriminating controls;95,844ms; clean before/after8 tests,0 skipped,0 failures |
| `node "$P/scripts/vector-controls.mjs" quick swift-metadata` | Final exit0;2/2 TAP tests;24.465834ms |
| `node "$P/scripts/vector-controls.mjs" swift-metadata` | Exit0;3 owners/9 controls;311,517ms; clean before/after4,15,6 discovered tests respectively,0 failures |
| `node "$P/scripts/vector-controls.mjs" quick swift-topology` | Final exit0;2/2 TAP tests including inventory validation;24.77175ms |
| `node "$P/scripts/vector-controls.mjs" swift-topology` | Exit0;5 discriminating controls;119,524ms; clean before/after7 tests,0 skipped,0 failures |
| `node "$P/scripts/vector-controls.mjs" quick elixir` | Preserved public mode; exit0;2/2 TAP tests;39.997583ms |
| `node "$P/scripts/vector-controls.mjs" quick swift-request` | Preserved public mode; exit0;2/2 TAP tests;41.784417ms |
| `swift test --package-path packages/crosswake-shell-core-ios --filter BridgeReplyLegTests` | Post-commit tracer feedback: exit0;8/8 XCTest tests before metadata expansion |
| `swift test --package-path packages/crosswake-shell-core-ios` | Final exit0;89 discovered,87 completed,2 existing optional export tests skipped,0 failures |
| `node --check "$P/scripts/vector-controls.mjs"` and `git diff --check` | Exit0; touched script syntax and whitespace checked; existing formatting style preserved |
| Independent receipt/source audit using Node SHA-256 and `git show` | Exit0;5 owners,18 controls,17 inventory rows; source/resource identities matched |
| `git diff --exit-code -- priv/contract_vectors/navigation_topology_vectors.json packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/Resources/bridge_contract_vectors.json` | Exit0; canonical resources unchanged |

The two existing Phase180 export tests require `PHASE180_EXPORT_DIR`, were not requested here, and receive no execution credit. Its clean runs discover6, skip2 and complete4 tests; the other metadata owners complete4 and15. The separate Swift Testing footer's0 tests is not evidence; the adapter requires the named XCTest case and exact nonzero owner suite count. No plan verification was skipped.

### Real controls

| Owner | Mutation | Child exit and verified failure |
| --- | --- | --- |
| BridgeReplyLegTests | Missing resource |1; named missing assertion;8 discovered/8 setup skips/8 failures; no case evaluations credited |
| BridgeReplyLegTests | One removed; empty |1 each; loaded expected2;8 discovered/8 setup skips/8 failures each |
| BridgeReplyLegTests | Actual loop selects nothing |1; completed expected2;8 discovered,0 skips,2 assertions fail only in corpus test |
| ActivationConformanceTests | Missing; one removed; empty |1 each; named missing/loaded15 diagnostics;4 discovered/4 setup skips/4 failures each |
| OfflineIslandAdmissionTests | Missing; one removed; empty |1 each; named missing/loaded15 diagnostics;15 discovered/15 setup skips/15 failures each |
| Phase180TwinFeasibilityTests | Missing; one removed; empty |1 each; named missing/loaded15 diagnostics;6 discovered/6 setup skips/6 failures each |
| NavigationCoordinatorTests | Missing; one removed; empty |1 each; named missing/loaded5 diagnostics;7 discovered,0 skips,1 failure only in JSON scenario |
| NavigationCoordinatorTests | Selected ID lost; duplicate selected ID |1 each; selected expected1 diagnostic;7 discovered,0 skips,1 failure only in JSON scenario |

Every mutation changed input bytes. Every attempt ran clean/build, and final restoration verified both source bytes and fresh reader success. Shared bridge corpus SHA-256: `3b64c8d81e1ca086494a1910aa5fb2d05d7a2d263b3d72f229f319d22e0064c0`. Topology SHA-256: `eb5473bfcb4cb452fe86098823ac7024d12a19ef3bc8743e921c90e93122afe1`.

### Reader inventory and evidence identity

The receipt's17 source-checked entries cover six behavioral readers (Elixir request; Swift request/reply/topology; Kotlin request/reply), four metadata readers (three Swift and Kotlin activation), ContractDriftTest's integrity checks, publish-readiness's version checks, generated-surface vocabulary checks, catalog source scans, the navigation advisory input, the producer's integrity behavior and a reference-only path inventory. A structural check is not a JSON verdict execution. Navigation-transition remains an advisory input with no native consumer claim. Kotlin is inventoried, with execution pending196-05. Phase198 retains set-hash and parity-ledger ownership.

Each mode retains its actual tested whole-helper hash. Independently verified provenance:

| Mode | Committed helper revision | SHA-256 |
| --- | --- | --- |
| swift-reply | `28bb00b8` | `c9711677b439f654319dd6afae5e22a8a8142fa37bb35e30e677113f4d6e6281` |
| swift-metadata | `d4a74cfc` | `002cf8a1ea2823d06a8eb302f7f59ff54c2c5f84780db0086aa543722821fcd8` |
| swift-topology | `75da76f2` | `3d21604b2f70c1c6732c2d75f035422a119deaebb4d5acc916e38ccf12cfc374` |

The later topology-specific branches and inventory do not relabel the earlier executed revisions. Original dispatcher modes and shared child/byte-restoration implementations remain. All current quick modes and all current Swift test owners passed final regression verification. Receipts contain exact current owner hashes, output hashes, command plans and process counts; earlier whole-helper hashes are not claims that a different whole-helper blob was integration-tested.

## TDD Gate Compliance

All three tasks have RED before GREEN. Each complete TAP report returned `RED_EVIDENCE_OK` from `gsd-tools check tdd-red-evidence`; semantic inspection verified the named assertion failed, with nonzero tests and no setup/build failure:

- Reply rejected completed1 instead of2.
- Metadata rejected14 claimed JSON completions instead of not applicable.
- Topology detected duplicate-ID acceptance caused by first-match truncation.

Unchanged reports remain locally excluded because TAP carries private runner paths. Durable report hashes: reply `f69f10bd347a8c44fc309957760b5455f347b29193cebf406c7c6876c2d3a01d`; metadata `11b5f81fd095cb6cb4c7de5ff4a2c4b167b44c04686ecfc8ac8efec8dbfea704`; topology `4ac0b4081ba5dde3fbaaafd4bf3d9b247d3bb78b2e23cc1161683f3ceb012a55`. No refactor-only commit was needed.

## Deviations from Plan

**[Rule1 - Bug] Corrected the inventory's Elixir reader symbol.** During task3, all five native controls and clean restoration succeeded, then the source-checked inventory rejected research shorthand `BridgeBehavioralVectorTest`; the actual module is `BridgeVectorBehavioralTest`. Corrected the symbol in the owned helper, added inventory validation to quick checks, and reran full topology acceptance successfully. No acceptance receipt was written for the rejected attempt. Fix committed in `75da76f2`; no scope expansion.

## Issues Encountered

The restricted environment blocked git-index writes and SPM manifest sandbox initialization. Reconciled the unchanged git state and reran authorized local operations with permitted execution. The environment failure received no red-control credit and produced no receipt. No authentication or human-action gate occurred.

Stub and threat-surface scans found no new unresolved stub, skipped plan test, unrun verification, network endpoint, auth path, schema or undeclared runtime surface. Existing empty test-state arrays are initialized storage, not proof fallbacks. Raw reports remain excluded; retained evidence and every scoped commit passed privacy scans.

## Self-Check: PASSED

All seven task artifacts and this summary exist. All six task commits are ancestors of HEAD. Independent source/receipt checks verified five owner hashes,18 executed controls,17 inventory source hashes and byte-exact canonical restoration. Final quick, syntax, whitespace and Swift regression checks passed after the last implementation edit.

## Decisions and next action

Keep metadata corpus verdicts not applicable and completion IDs after real assertions. Preserve exact executed helper revisions and always restore canonical bytes plus rebuilt resources.

Ready for196-05. Exact next command: `$gsd-execute-phase 196 --ws quality-ratchet-release`, resuming at `196-05-PLAN.md`; do not repeat plans01-04. Last completed phase remains195. Phase196 is executing,4/17 plans complete; SPEC-01 and every other phase requirement plus GR-06 remain pending until all declaring owners and final verification finish. Adopter work stays parked. These results prove local macOS Swift package behavior; no device, adopter, Android execution, new CI or delivery claim is made.
