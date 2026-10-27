---
phase: 196-spec-and-structure-ratchet
plan: "05"
subsystem: testing
tags: [kotlin, gradle, junit, vectors, non-vacuity, privacy]
requires:
  - phase: 196-04
    provides: Bounded vector-control dispatcher and source-checked reader inventory
provides:
  - Kotlin request 15 loaded and 14 completed real evaluations
  - Kotlin reply 2 loaded and 2 completed duplex evaluations with unique intended IDs
  - Kotlin activation metadata loaded15 with JSON verdict executions not applicable
  - Twelve real rebuilt JVM loss controls and byte-exact restoration
affects: [196-06, 196-15, phase198-parity]
tech-stack:
  added: []
  patterns: [explicit installed JDK17, clean selected Gradle tests, fresh JUnit XML, post-assertion completion IDs]
key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/196-EVIDENCE/kotlin-vectors.json
  modified:
    - packages/crosswake-shell-core-android/src/test/java/dev/crosswake/shell/core/BridgeConformanceTest.kt
    - packages/crosswake-shell-core-android/src/test/java/dev/crosswake/shell/core/BridgeReplyLegTest.kt
    - packages/crosswake-shell-core-android/src/test/java/dev/crosswake/shell/core/ActivationConformanceTest.kt
    - .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/vector-controls.mjs
key-decisions:
  - Verify fresh named JUnit suites and intended assertion failures; unrelated setup failures earn no control credit.
  - Keep activation metadata verdict executions null and filtering controls not applicable by reader kind.
requirements-completed: []
actuals:
  tokens: 14887
  tasks: 2
  commits: 4
plan_head_before: 7494735e2de03319fd5bb128b6748a1c401da4c0
plan_head_after: 77c74b4b1a3ecbe21c26ce232b33e5cc65e5112a
coverage:
  - id: request
    description: Request15/14 and four clean rebuilt loss controls
    requirement: SPEC-01
    verification:
      - kind: integration
        ref: node .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/vector-controls.mjs kotlin-request
        status: pass
    human_judgment: false
  - id: reply-metadata
    description: Reply2/2 and metadata15/N/A with eight real loss controls
    requirement: SPEC-01
    verification:
      - kind: integration
        ref: node .planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet/scripts/vector-controls.mjs kotlin-other
        status: pass
    human_judgment: false
duration: 8min
completed: 2026-10-27
status: complete
---

# Phase 196 Plan 05: Kotlin request, reply and metadata reader proof Summary

**Kotlin proves request15/14 and reply2/2; activation requires15 loaded requests with verdicts N/A, backed by12 real clean Gradle mutation controls.**

## Execution and changes

One main checkout on `fix/spec-structure-ratchet`, starting at `7494735e2de03319fd5bb128b6748a1c401da4c0`, based on actual main `b8398c38`. Recorded implementation window: 2026-10-27T15:20:06Z through 2026-10-27T15:27:33Z, rounded8min. Two tasks changed five declared artifacts. The persisted plan ledger measures four task commits before summary/lifecycle metadata. Actual tokens are `ceil(59547/4)` over the realized task diff, on the estimate's chars/4 scale.

The request reader rejects missing resources explicitly, closes its stream, pins15 loaded requests before the original loop and records14 unique completed IDs after real status/denial assertions. Existing `elixir_only` semantics and authored delegate tests remain.

The reply setup requires two loaded entries and each intended ID exactly once. Its corpus test iterates selected cases and records completion after landing-pad and actual duplex assertions. Existing ok/adversarial tests retain their assertions through private helpers, also used by the corpus loop. Suppressing the actual corpus loop fails completed2 even though the separately authored tests still run.

Activation checks15 requests at its metadata read boundary. Its three activation examples remain separately authored behaviors. No14-case JSON verdict execution or exclusion loop is invented: `completed` is null and selection controls are `not-applicable-no-filter`.

The helper discovers a working installed OpenJDK17.0.19, verifies the executable, sets child `JAVA_HOME`, verifies the Android package cwd, and runs `./gradlew clean testDebugUnitTest --tests dev.crosswake.shell.core.<owner>` for every positive, mutation and restored positive. It requires fresh clean/compile/resource/test tasks and fresh named JUnit XML: exactly3 discovered tests per owner, no skips/errors, and intended assertion diagnostics in every failing case. Missing resources must also disappear from rebuilt output; present resources must match source bytes. Both source and resource bytes restore in finally, followed by a clean positive even after a rejected attempt.

Quick checks use Node built-ins and isolated synthetic scratch, verify populations/selection/kind and exact JDK/cwd/clean/test command plans, propagate real child failure, restore scratch bytes, enforce20seconds and write no acceptance receipt. They invoke neither Gradle nor Java. Existing Elixir and Swift public modes remain. The17-row reader-role inventory is source-checked; three Kotlin owners now point to196-05 evidence. Prior receipts retain their actual tested helper identities. Phase198 retains set hashes and parity-ledger ownership.

## Task commits

| Task | RED | GREEN | Verified result |
| --- | --- | --- | --- |
| 196-05-01 | `911fc282` | `38bef11c` | Request15/14, four real controls, clean3/3 restored suite |
| 196-05-02 | `ed23447e` | `77c74b4b` | Reply2/2 and metadata15/N/A, eight real controls |

Every commit used a successful privacy conditional with absolute per-file arguments before staging and an immediate rescan afterward. No tracked deletion, dependency/lock change, canonical corpus change, runtime feature, external delivery or irreversible operation occurred.

## Verification

All helper commands run from repository root; `P=.planning/workstreams/quality-ratchet-release/phases/196-spec-and-structure-ratchet`.

| Exact command | Observed result |
| --- | --- |
| `node "$P/scripts/vector-controls.mjs" quick kotlin-request` | Final exit0;2/2 TAP tests;29.066ms |
| `node "$P/scripts/vector-controls.mjs" kotlin-request` | Final exit0;4 intended failures;11,566ms; clean before/after3tests,0failures |
| `node "$P/scripts/vector-controls.mjs" quick kotlin-other` | Final exit0;2/2 TAP tests;30.998ms |
| `node "$P/scripts/vector-controls.mjs" kotlin-other` | Exit0;2owners/8 intended failures;20,172ms; each clean before/after3tests,0failures |
| `node "$P/scripts/vector-controls.mjs" quick elixir` | Preserved mode exit0;2/2 TAP tests;48.8895ms |
| `node "$P/scripts/vector-controls.mjs" quick swift-request` | Preserved mode exit0;2/2 TAP tests;49.941875ms |
| `node "$P/scripts/vector-controls.mjs" quick swift-reply` | Preserved mode exit0;2/2 TAP tests;29.8825ms |
| `node "$P/scripts/vector-controls.mjs" quick swift-metadata` | Preserved mode exit0;2/2 TAP tests;29.522417ms |
| `node "$P/scripts/vector-controls.mjs" quick swift-topology` | Preserved mode exit0;2/2 TAP tests;32.095375ms |
| `JAVA_HOME=<discovered-installed-jdk17> ./gradlew clean testDebugUnitTest` from `packages/crosswake-shell-core-android` | Final exit0;BUILD SUCCESSFUL;19tasks executed;fresh XML totals12tests,0failures,0errors,0skips |
| `node --check "$P/scripts/vector-controls.mjs"` and `git diff --check` | Exit0; touched script syntax/whitespace and existing formatting style checked |
| Independent Node SHA-256/JUnit/receipt audit | Exit0;3owner hashes, both exact final helper hashes,12controls and17inventory identities matched |
| `git diff --exit-code -- packages/crosswake-shell-core-android/src/test/resources/bridge_contract_vectors.json` | Exit0; canonical generated bytes unchanged |

The mandatory request tracer feedback reran both quick and full acceptance after its GREEN commit, passing all4controls in14,336ms before reply/metadata expansion. Final request acceptance was rerun on the completed helper. Both final modes bind the exact final helper SHA-256 `cba824642680d6fc690070c6048e4d2a8c25bfef11041f29ca48b77dd223f54c` committed in `77c74b4b`. Final quick regressions and full Android suite passed after the last implementation edit. No plan verification was skipped.

### Real controls

Every mutation changed actual input bytes and ran a fresh clean selected Gradle test. All child exits were1 with3 discovered tests,0errors and0skips. Setup failure is distinct from completed JSON evaluation; it earns no evaluation credit.

| Owner | Control | Intended reason | Failed tests |
| --- | --- | --- | --- |
| BridgeConformanceTest | Missing resource | `CW-VECTOR-MISSING bridge_contract_vectors.json` | 3 |
| BridgeConformanceTest | One removed; empty | `CW-VECTOR-LOADED expected 15` | 1each |
| BridgeConformanceTest | All `elixir_only` | `CW-VECTOR-COMPLETED expected 14` | 1 |
| BridgeReplyLegTest | Missing resource | `CW-VECTOR-MISSING bridge_contract_vectors.json` | 3 |
| BridgeReplyLegTest | One removed; empty | `CW-VECTOR-LOADED expected 2` | 3each |
| BridgeReplyLegTest | Actual loop suppresses all cases | `CW-VECTOR-COMPLETED expected 2` | 1 |
| BridgeReplyLegTest | Duplicate intended ID with2loaded | `CW-VECTOR-SELECTED expected 1` | 3 |
| ActivationConformanceTest | Missing resource | `CW-VECTOR-MISSING bridge_contract_vectors.json` | 3 |
| ActivationConformanceTest | One removed; empty | `CW-VECTOR-LOADED expected 15` | 3each |

Canonical resource SHA-256 before and after every owner: `3b64c8d81e1ca086494a1910aa5fb2d05d7a2d263b3d72f229f319d22e0064c0`. Request owner: `e498b97d5d93fa89f123c33dd873935cea5fefc6d27ec5fa01b67d59eb5b711a`; reply owner: `b06a976119bd5eceab06fcb25615cf8b82250be6176fd8b3f58598a1f6522b9b`; activation owner: `e7787080513e7923790d2e6dbb9bfaaf4f451d3f2f556621f8e1f8dcdf0550cb`. Receipt retains relative command plans, counts, statuses, timings and output/JUnit/executable hashes, with public JDK version/discovery identity and no raw output, payload or private path.

## TDD Gate Compliance

Both tasks followed RED before GREEN. Complete unmodified TAP reports returned `RED_EVIDENCE_OK`; each run discovered2tests and failed its named assertion with no setup/load failure. Semantic inspection confirmed task1 accepted all-excluded input and task2 accepted invented14 metadata completions before their fixes. Raw reports remain locally excluded because TAP includes private runner paths. Durable SHA-256 identities: request RED `6c6623297381e3be4e8669e0238c609079bbcf143e9a0d0de76d36721f2fb532`; other RED `a3bf4758075325d0fbd72cc297d9507c1d341c3679d71d312de535c09afa4398`. No refactor-only commit was needed.

## Deviations from Plan

None. Adapter development followed the real Gradle output as required; no extra runtime surface, architecture or package installation was introduced.

## Issues Encountered

The macOS default Java launcher had no configured runtime; installed Homebrew OpenJDK17.0.19 worked explicitly. The restricted environment blocked Gradle native services and git-index writes; reconciled unchanged state before permitted local retries. These failures received no proof credit. One real request-control attempt exposed a parser error on mixed self-closing and failing JUnit testcases; the adapter refused it, restored bytes and clean-built the positive suite, then was corrected and every control rerun. No acceptance receipt was written for the refused attempt.

Stub/threat-surface review found no new unresolved stub, skipped test, unrun plan verification, endpoint, auth path or schema change. Existing empty maps/lists are test-state initialization, not fabricated proof. No authentication or human-action gate occurred. No full Swift suite rerun is claimed by this Kotlin plan; preserved quick modes verify helper contracts only.

## Next action and limits

Last completed phase remains195. Phase196 is executing,5/17plans complete; all eight phase requirements and GR-06 remain pending. Exact next command: `$gsd-execute-phase 196 --ws quality-ratchet-release`, resuming at `196-06-PLAN.md`; do not repeat plans01-05. The adopter lane stays parked. Evidence is local JVM-hermetic proof only, with no emulator, device, adopter, new CI or delivery claim.

## Self-Check: PASSED

All five declared task artifacts and this summary exist. All four task commits are ancestors of HEAD. Independent receipt/source validation confirmed twelve discriminating controls, final helper/owner identities, seventeen inventory rows and exact canonical restoration. Final required integrations, full Android regression, quick checks, syntax, whitespace and per-file privacy scans passed after the final implementation edit.
