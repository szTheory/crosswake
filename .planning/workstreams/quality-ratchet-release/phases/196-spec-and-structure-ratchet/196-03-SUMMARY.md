---
phase: 196-spec-and-structure-ratchet
plan: "03"
subsystem: testing
tags: [exunit, swift, vectors, negative-controls, privacy]
requires:
  - phase: 196-02
    provides: Strict optional proof and preserved sequential execution context
provides:
  - Independently pinned Elixir 15 loaded and 9 completed request evaluations
  - Independently pinned Swift 15 loaded and 14 completed request evaluations
  - Eight real input-loss controls with byte restoration and fresh native resource builds
affects: [196-04, 196-05, 196-15, 198]
tech-stack:
  added: []
  patterns: [post-assertion-completion-markers, rebuilt-resource-controls, closed-proof-receipts]
key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/vector-controls.mjs
    - .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-EVIDENCE/elixir-vectors.json
    - .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-EVIDENCE/swift-request-vectors.json
  modified:
    - test/crosswake/bridge/bridge_behavioral_vector_test.exs
    - packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/BridgeConformanceTests.swift
key-decisions:
  - Preserve platform exclusions and count completion only after each eligible case's semantic assertions.
  - Treat XCTest missing-resource setup results as failures with explicit skip counts, never completed evaluations.
  - Restore canonical bytes and clean-rebuild copied resources even when a control is rejected.
requirements-completed: []
requirements-addressed: [SPEC-01]
actuals:
  tokens: 6953
  tasks: 2
  commits: 4
commits: 4
plan_head_before: 3f1985e4398224fd45d5373d9d79fbf765753a62
plan_head_after: b2dc413269e3f94dee2a02dcdfa36122ae912ed3
coverage:
  - id: elixir-requests
    description: Elixir loaded/completed pins reject all four input-loss mutations and restore cleanly.
    verification:
      - kind: integration
        ref: node .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/vector-controls.mjs elixir
        status: pass
    human_judgment: false
  - id: swift-requests
    description: Swift loaded/completed pins reject all four rebuilt-resource mutations and restore cleanly.
    verification:
      - kind: integration
        ref: node .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/vector-controls.mjs swift-request
        status: pass
      - kind: integration
        ref: swift test --package-path packages/crosswake-shell-core-ios
        status: pass
    human_judgment: false
  - id: quick-wrapper-controls
    description: Bounded quick checks reject lost input and wrong command plans and exercise real child failure and finally restoration.
    verification:
      - kind: unit
        ref: node .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/vector-controls.mjs quick elixir
        status: pass
      - kind: unit
        ref: node .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/vector-controls.mjs quick swift-request
        status: pass
    human_judgment: false
duration: 8min
completed: 2026-10-27
status: complete
---

# Phase 196 Plan 03: Elixir and primary Swift request-vector proof Summary

**Elixir proves 15 loaded/9 completed requests and Swift proves 15/14; both real readers reject missing, shortened, empty and fully excluded corpora.**

## Execution

One main checkout on `fix/spec-structure-ratchet`; initial HEAD `3f1985e4398224fd45d5373d9d79fbf765753a62`. The recorded implementation window runs from the first RED commit at 2026-10-27T14:46:15Z through final acceptance and GREEN commit at 2026-10-27T14:53:56Z (8 minutes rounded; initial inspection excluded). Two tasks changed five declared files. Actual tokens are `ceil(27812/4)` over the realized four-commit diff. The ledger measures four task commits before summary/lifecycle metadata.

Existing `native_only` and `elixirOnly` filters and every wire/denial assertion remain. Literal reviewed counts surround real evaluations; completion IDs are collected after assertions and checked for uniqueness. The Swift loader uses a throwing `XCTUnwrap` with a named missing-resource assertion instead of force-unwrapping an absent URL.

The phase-only helper runs modes sequentially. It rejects wrong modes, populations and command plans; quick tests invoke no Mix/SPM and mutate only disposable synthetic bytes. Full controls mutate each actual reader's canonical resource, demand the intended diagnostic, and retain only relative command plans, exits, counts, timings and hashes. Native children run `swift package clean`, then `swift test --filter BridgeConformanceTests` from the package directory every time, including before and after the mutations. The cleanup path restores bytes, compares hashes and reruns the clean reader even if a control is rejected. No receipt is written from an unsuccessful attempt.

### Helper contract for subsequent plans

Only `quick elixir`, `elixir`, `quick swift-request` and `swift-request` are implemented; unknown modes fail. `specs` declares relative `resource`, `owner`, literal `loaded`/`completed`, exclusion key and ordered `{command,args,cwd}` plan. `population` checks array shape, loaded count, unique IDs and eligibility. `child` enforces process exit/timeout handling; `withBytes` restores exact bytes in finally. `runConsumer` verifies real output and returns safe process records; `full` produces the corresponding reader receipt only after restored clean success. Quick runs emit TAP, have a20-second deadline and write no acceptance receipt. Full children have a300-second per-process timeout.

Plans04–05 must explicitly extend the quick expected owner/resource/command plans, corpus mutation selection, receipt naming and real reader-output adapter for their new modes. The current Swift adapter is specifically the three-test `BridgeConformanceTests` XCTest owner, selected by `elixir_only`; it is not a generic reply/metadata/topology adapter. Missing Swift setup is recorded as skipped plus failed, never completed. Resource-copy refresh must remain a real clean/build. Receipts identify the exact helper hash tested here; any subsequent common implementation change requires fresh affected controls before claiming those receipts certify the new helper. Never relabel a setup/build error as an intended red control.

## Task commits

| Task | Commit | Result |
| --- | --- | --- |
| 196-03-01 RED | `8315e866` | Shortened-corpus acceptance causes the named quick TAP assertion to fail |
| 196-03-01 GREEN | `d07543e1` | Elixir 15/9 pins and four real input-loss controls |
| 196-03-02 RED | `966fc23f` | Omitting Swift clean rebuild causes the named command-plan TAP assertion to fail |
| 196-03-02 GREEN | `b2dc4132` | Swift 15/14 pins, rebuilt controls, and refreshed receipts for the final common helper |

Each commit used a successful conditional privacy scan with absolute per-file arguments before staging, then an immediate rescan. No tracked file was deleted. No dependency, lock, CI wiring, generator or canonical JSON source changed. No push, PR, merge, publish, tag, remote deletion or worktree operation occurred.

## Verification

Let `P=.planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet`. All results below came after the final implementation edit.

| Command | Result |
| --- | --- |
| `node "$P/scripts/vector-controls.mjs" quick elixir` | Exit 0; 2/2 TAP tests; 50.129 ms |
| `node "$P/scripts/vector-controls.mjs" quick swift-request` | Exit 0; 2/2 TAP tests; 48.084 ms |
| `node "$P/scripts/vector-controls.mjs" elixir` | Exit 0; all four discriminating controls; 3,252 ms; clean reader before/after: 1 test, 0 failures |
| `node "$P/scripts/vector-controls.mjs" swift-request` | Exit 0; all four rebuilt controls; 120,096 ms; clean reader before/after: 3 tests, 0 skipped, 0 failures |
| `swift test --package-path packages/crosswake-shell-core-ios` | Exit 0; 89 discovered, 87 completed, 2 existing optional export tests skipped, 0 failures |
| `mix format --check-formatted test/crosswake/bridge/bridge_behavioral_vector_test.exs` | Exit 0; touched Elixir explicitly formatted |
| `node --check "$P/scripts/vector-controls.mjs"` and `git diff --check` | Exit 0 |
| Independent receipt/source hash check and canonical `git diff --exit-code` | Exit 0; both owners/helper match, both canonical resources unchanged |

The full Swift package's two pre-existing Phase180 tests require `PHASE180_EXPORT_DIR`; they were not requested by this plan and are not credited as executed. No plan verification was skipped. The separate Swift Testing footer's zero-test result is not proof: the helper requires the actual named XCTest case and a nonempty XCTest suite summary.

### Executed real controls

| Reader | Mutation | Child exit | Verified reason / actual test result |
| --- | --- | --- | --- |
| Elixir | File missing | 1 | Named resource read fails with no-such-file diagnostic; no vector evaluations credited |
| Elixir | One case removed | 2 | `CW-VECTOR-LOADED expected 15`; 1 test, 1 failure |
| Elixir | Empty corpus | 2 | `CW-VECTOR-LOADED expected 15`; 1 test, 1 failure |
| Elixir | All `native_only` | 2 | `CW-VECTOR-COMPLETED expected 9`; 1 test, 1 failure |
| Swift | Source resource missing before clean/build | 1 | `CW-VECTOR-MISSING bridge_contract_vectors.json`; 3 discovered, 3 skipped and 3 setup failures; no evaluation credit |
| Swift | One case removed | 1 | `CW-VECTOR-LOADED expected 15`; 3 tests, 2 assertions fail only in the request-vector test |
| Swift | Empty corpus | 1 | `CW-VECTOR-LOADED expected 15`; 3 tests, 4 assertions fail only in the request-vector test |
| Swift | All `elixir_only` | 1 | `CW-VECTOR-COMPLETED expected 14`; 3 tests, 2 assertions fail only in the request-vector test |

Every mutation was checked to differ from its original bytes. Both JSON resources were restored byte-for-byte with SHA-256 `3b64c8d81e1ca086494a1910aa5fb2d05d7a2d263b3d72f229f319d22e0064c0`.

### Source identities

The committed receipts contain all child output hashes and timings without raw output. Independently checked final owner hashes:

- Elixir reader: `4f84721eeeccebb50abc3f3e87e3b92161f048fb9b2089252cc0c5ba605c314e`.
- Swift reader: `1a354799ec43a8c2aadc142a2336fe14a192583dbb4a424666bc951dfc16d295`.
- Shared helper: `dfd3305762544b77172f9f643050c582f8347f2d6f72f6a8e5477c2b55ac0973`.

## TDD Gate Compliance

Each task has RED before GREEN. Both complete TAP reports were validated by `gsd-tools check tdd-red-evidence` as `RED_EVIDENCE_OK`. Semantic inspection confirmed that the named assertions executed: task1 failed because a shortened corpus was accepted; task2 failed because the real child plan omitted the mandatory Swift clean step. Neither RED was a syntax, setup, import or discovery failure. The Elixir tracer was rerun after its GREEN commit (1 test, 0 failures) before expanding to Swift. No refactor-only commit was needed.

The unmodified reports remain locally excluded because native runner paths are private: `196-EVIDENCE/tdd-elixir-red.json` (SHA-256 `3c3cbcebcfd4148de6786c23cf094a93b2e5e93b3ec6fd744d21888e1bc816ea`) and `196-EVIDENCE/tdd-swift-request-red.json` (SHA-256 `726bc8237188df841e9dbdd0d257ea3031e3ec9e6135340077a245783011e521`). Their hashes, counts and outcomes are durable here; raw output is not committed.

## Decisions Made

- Count loaded and completed cases separately, using literal reviewed expectations and post-assertion IDs.
- Preserve XCTest's actual discovered/skipped/failure distinctions for missing setup resources.
- Always clean-rebuild after restoring source resources, including rejected-control cleanup.

## Deviations from Plan

None. The common helper's Elixir receipt was refreshed after its Swift extension so both receipts identify the final tested helper.

## Issues Encountered

The restricted environment rejected SPM manifest sandbox setup before any proof; that attempt was rejected and produced no receipt. The authorized local Swift run then used the permitted execution environment. The first real deletion control exposed XCTest's actual summary grammar (`skipped and failures`); the adapter initially rejected it, was corrected from genuine output, and all controls were rerun. No unrelated build failure was counted as a successful red control. Both resolved issues left canonical bytes restored.

Scoped lifecycle SDK handlers were run. The roadmap updater did not recognize the existing decorated phase row and left it unchanged; the row/checklist/handoff were reconciled directly. The SDK also retained stale progress text and counted only phase directories already present; the final scoped STATE preserves all six milestone phases and the actual33/47 completed-plan ratio (70%), within40 lines. Requirements were not advanced.

No authentication gate occurred. Stub and threat-surface scans found no new stub, skipped plan test, unrun plan verification, endpoint, auth path, schema or undeclared runtime surface. The existing empty permissive test fixtures are intentional setup, not proof fallbacks.

## Next action and limits

Ready for 196-04, remaining real Swift vector readers. Exact command: `$gsd-execute-phase 196 --ws quality-ratchet-release`; resume at `196-04-PLAN.md`, without repeating plans01-03. Phase195 remains the last completed phase. Phase196 is executing, 3/17 plans complete; all eight phase requirements and GR-06 stay pending. This plan proves local Elixir and macOS Swift package behavior; device, adopter, CI and delivery evidence remain outside this result.

## Self-Check: PASSED

All five declared artifacts and this summary exist. All four task commits are ancestors of HEAD. Both canonical resources match their original hashes and have no git diff; both receipts match current reader/helper hashes. Final required controls, formatting, syntax and full Swift package verification passed after the final code edit.
