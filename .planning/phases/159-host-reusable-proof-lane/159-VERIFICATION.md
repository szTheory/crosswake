---
phase: 159-host-reusable-proof-lane
verified: 2026-07-31T23:24:47Z
status: gaps_found
score: 16/23 must-haves verified
behavior_unverified: 1
overrides_applied: 0
gaps:
  - truth: "Generation is non-destructive and supports a diff/check mode."
    status: failed
    reason: "Lexical destination containment follows an existing symlink in a generated destination parent, so a normalized config can create scaffold files outside its declared host root."
    artifacts:
      - path: "lib/crosswake/proof_lane/generator.ex"
        issue: "within?/2 uses Path.expand/1, File.mkdir_p/1, and File.open/3 without rejecting or safely traversing symlinked ancestors."
    missing:
      - "Reject existing symlink ancestors (and recheck before final open), or use descriptor-based no-follow traversal, before any generator write."
  - truth: "Native proof is limited to shell boot/auth, kill/relaunch replay, and offline pack audio."
    status: failed
    reason: "The generated proof verifier reports passed after build-for-testing without executing XCTest/XCUITest, and the generated app/test targets only assert hard-coded placeholder labels rather than host auth, replay, or pack behavior."
    artifacts:
      - path: "script/verify_generated_ios_shell.sh"
        issue: "The proof-lane passed branch exits after build-for-testing at lines 150-156; it never invokes test or test-without-building."
      - path: "priv/templates/crosswake/proof_lane/ios/ProofLaneApp.swift.eex"
        issue: "The app renders fixed ready/auth/outcome labels and a no-op reconnect button; no host adapter or configured route/replay state is wired in."
    missing:
      - "Require an integrated host adapter and test action; run generated XCTest/XCUITest, deriving passed only from their successful execution."
  - truth: "Generated XCTest/XCUITest wiring compiles and proves the declared shell lifecycle boundaries."
    status: failed
    reason: "The project may build, but no test action is executed and its assertions observe only fixed generated literals, so lifecycle/auth/replay behavior is not proven."
    artifacts:
      - path: "priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneUITests/ProofLaneUITests.swift.eex"
        issue: "Assertions only check static accessibility identifiers after launch/relaunch."
    missing:
      - "Bind tests to observable host-provided state and execute them through a shared test scheme."
behavior_unverified_items:
  - truth: "Existing browser tests and fixtures remain the primary web/island coverage."
    test: "Run the existing offline Playwright spec against its configured Phoenix host."
    expected: "A real UI mutation is queued in IndexedDB, replayed by the application, confirmed once by the backend, and leaves an empty outbox."
    why_human: "The focused TypeScript compilation proves the wrapper is type-correct, but no runnable host server was available and this verifier does not start services."
---

# Phase 159: Host-Reusable Proof Lane Verification Report

**Phase Goal:** Generate configurable host-owned browser, shell, offline-island, and physical-device proof scaffolding; the smallest shippable version is `mix crosswake.gen.proof_lane ios` copying a host-owned scaffold from explicit route/storage/mutation/endpoint/router/shell-root config while reusing existing browser offline proof.
**Verified:** 2026-07-31T23:24:47Z
**Status:** gaps_found
**Re-verification:** Yes — after prior gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Generation is non-destructive and supports a diff/check mode. | ✗ FAILED | `check`/`diff` exist, but an `e2e` symlink under a normalized host root caused `Generator.generate/1` to create `proof_lane.spec.ts` outside that root. |
| 2 | Existing browser tests and fixtures remain the primary web/island coverage. | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | `tsc --noEmit -p examples/phoenix_host/tsconfig.offline_route_proof.json` passes and the wrapper retains `capturedId`, but the real Playwright/Phoenix sequence was not exercised. |
| 3 | Native proof is limited to shell boot/auth, kill/relaunch replay, and offline pack audio. | ✗ FAILED | The proof lane can emit `passed` after a build without executing tests; generated native behavior is static placeholder UI rather than host behavior. |
| 4 | Evidence generation fails when sensitive payload or identity fields appear. | ✓ VERIFIED | Focused evidence regressions pass; closed commit/assertion forms, canonical source hashing, final scan, and no-replace promotion are implemented. |
| 5 | One invocation creates an isolated, host-owned scaffold from one normalized Phoenix configuration. | ✗ FAILED | The configuration grammar is closed, but symlink traversal breaks the claimed host-owned isolation. |
| 6 | Generation and evidence promotion use collision-safe staged writes. | ✗ FAILED | Evidence promotion is atomic no-replace, but generator writes may escape through a symlinked destination parent. |
| 7 | Re-running a normalized configuration creates only missing scaffold and preserves existing bytes. | ✓ VERIFIED | Generator lifecycle tests cover reruns and exclusive file creation; existing files are reused. |
| 8 | Concurrent/interrupted generation preserves existing host files and fails closed on collisions. | ✗ FAILED | Collision controls pass for lexical paths, but the symlink escape invalidates containment before those controls protect the actual destination. |
| 9 | Native driver/target graph distinguishes passed, blocked, and unavailable without converting later prerequisites to success. | ✗ FAILED | Unavailable build paths are non-zero, but a buildable static target graph is promoted to `passed` without executing proof behavior. |
| 10 | The scaffold does not promote external-host or physical-device support while adoption inputs are unknown-blocking. | ✓ VERIFIED | Generated prerequisite driver remains `blocked`/`unavailable`; no device support or Android scope was added. |
| 11 | `Config.normalize/1` accepts exactly the required typed values and rejects unsafe forms without echoing them. | ✓ VERIFIED | Closed nine-key config plus final `native/ios` and non-root validation; focused config tests pass. |
| 12 | `--check` and `--diff` are read-only desired-state inspection modes. | ✓ VERIFIED | Task/generator lifecycle tests cover check/diff and provenance without write calls. |
| 13 | Generated browser support is a host-owned adapter over the shared semantic sequence, without example-host coupling. | ✓ VERIFIED | Template delegates to its adapter contract and contains no example-host model/fixture/schema strings. |
| 14 | XCTest/XCUITest wiring proves deterministic contracts and observable lifecycle boundaries. | ✗ FAILED | Sources exist, but tests assert fixed literals and the verifier never runs them. |
| 15 | Missing replay/auth or pack/audio prerequisites return named blocked/unavailable non-zero outcomes. | ✓ VERIFIED | Direct `bash script/verify_generated_ios_shell.sh --proof-lane` returned JSON `blocked` with non-zero status; focused verifier tests cover unavailable/blocked paths. |
| 16 | Native tooling remains advisory and non-promoting; no physical-device CI lane is added. | ✓ VERIFIED | No device lane/support promotion is present; unavailable paths remain machine-readable non-zero results. |
| 17 | Retained evidence uses the exact typed allowlist and excludes free-form diagnostic/media fields. | ✓ VERIFIED | `Evidence` has a fixed 12-field serializer and exact-key validation; focused evidence tests pass. |
| 18 | Staged evidence is recursively enumerated and final-byte scanned before promotion. | ✓ VERIFIED | `scan_stage/1`, canonical JSON scan, and stage-only cleanup are wired before native promotion. |
| 19 | Hashes derive only from approved canonical sanitized bytes. | ✓ VERIFIED | `source_hashes/1` computes SHA-256 internally and `check/2` re-verifies provided canonical sources. |
| 20 | Browser helpers restore online state in `finally` after an offline failure. | ✓ VERIFIED | Repository and rendered helper tests pass in `browser_online_restore.spec.ts`; both use `finally { setOffline(false) }`. |
| 21 | Retained revision/assertion references reject identity-like caller strings without echoing them. | ✓ VERIFIED | Git references and assertion IDs are closed allowlists; evidence regressions pass. |
| 22 | Evidence promotion is atomic no-replace and preserves a concurrent destination winner. | ✓ VERIFIED | `NativePromotion.rename_noreplace/2` is wired after final scan; evidence tests cover collision/concurrent promotion. |
| 23 | Interrupted/parallel evidence promotion leaves one canonical winner without a partial artifact. | ✓ VERIFIED | Focused evidence suite passes its staged-promotion interruption and contention controls. |

**Score:** 16/23 truths verified (1 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `lib/mix/tasks/crosswake.gen.proof_lane.ex` | iOS generator with generate/check/diff | ✓ VERIFIED | Normalizes config then dispatches the selected action. |
| `lib/crosswake/proof_lane/config.ex` | Closed configuration boundary | ✓ VERIFIED | Exact keys and normalized non-root `native/ios` shape are enforced. |
| `lib/crosswake/proof_lane/generator.ex` | Host-confined missing-only rendering | ✗ FAILED | Lexical containment does not defend existing symlink ancestors. |
| `lib/crosswake/proof_lane/evidence.ex` | Typed evidence and staged promotion | ✓ VERIFIED | Fixed schema, source-bound digests, final scan, and native no-replace handoff are substantive and tested. |
| `examples/phoenix_host/e2e/support/offline_route_proof.ts` | Primary browser semantic wrapper | ✓ VERIFIED | Type-check passes; `capturedId` is defined from `runOfflineIslandProof`. |
| `priv/templates/crosswake/proof_lane/e2e/support/proof_lane.ts.eex` | Reusable offline-island adapter | ✓ VERIFIED | Delegates through host callbacks and restores online state in `finally`. |
| iOS templates and project graph | Executable native proof boundaries | ✗ FAILED | Target sources are present but use placeholder state and lack an executed test scheme. |
| `script/verify_generated_ios_shell.sh` | Generated target verification | ✗ FAILED | Correctly returns blocked/unavailable when build cannot proceed, but reports passed after build-for-testing alone. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Mix task | `Config.normalize/1` | config load before action | ✓ WIRED | The task normalizes before generation/check/diff. |
| Generator | templates/manifest | one normalized struct and EEx assigns | ⚠️ HOLLOW | Render wiring exists, but symlinked destination parents evade containment. |
| Browser wrapper | `runOfflineIslandProof` | delegated adapter callbacks | ✓ WIRED | Type-check succeeds and returned mutation ID is consumed by the later assertion. |
| iOS project | verifier | xcodebuild target build | ✗ NOT_WIRED | The verifier builds but does not execute XCTest/XCUITest. |
| Evidence | native promotion | final scan then no-replace rename | ✓ WIRED | `scan_stage`, source-aware `check`, and `rename_noreplace` are ordered in `promote/3`. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Generator | destination paths | normalized `ios_shell_root` | Symlinked parent can redirect writes | ✗ HOLLOW |
| Browser proof | mutation ID | `runOfflineIslandProof` return | Type-correct; runtime host path unexercised | ⚠️ PRESENT |
| iOS proof | auth/replay/outcome UI | fixed Swift literals | No host route, authority, replay, or pack adapter reaches the UI | ✗ STATIC |
| Evidence | retained IDs/digests | closed fields plus canonical bytes | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Focused proof-lane regression suite | `mix test ...config...evidence...template_contract...ios_verifier...generator...` | 32 tests, 0 failures | ✓ PASS (does not cover review-critical native execution or symlink containment) |
| Browser proof type-check | `tsc --noEmit -p examples/phoenix_host/tsconfig.offline_route_proof.json` | Exit 0 | ✓ PASS |
| Unavailable native proof is non-passing | `bash script/verify_generated_ios_shell.sh --proof-lane` | JSON `blocked`, non-zero exit | ✓ PASS |
| Symlink containment | Temporary normalized host with `e2e` symlink outside root, then `Generator.generate/1` | External `proof_lane.spec.ts` created | ✗ FAIL |

### Probe Execution

Step 7c: SKIPPED — no phase-declared or conventional `probe-*.sh` file was found.

### Requirements Coverage

| Requirement | Source Plans | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| PROOF-01 | 159-01, 159-02, 159-03, 159-05, 159-06 | Non-overwriting configurable proof scaffold | ✗ BLOCKED | Symlink escape breaks host-root confinement; native pass is not behavioral proof. |
| PROOF-02 | 159-01, 159-02, 159-05 | Exact route/storage/mutation/endpoint/router/shell configuration | ✗ BLOCKED | Value grammar is closed, but the generator does not safely retain confinement for the accepted shell-root configuration. |
| PROOF-03 | 159-01, 159-03, 159-06 | Preserve existing browser/unit/fixture corpus and only add unavailable boundaries | ? NEEDS AUTOMATED HOST RUN | Type-check and cleanup test pass; the existing live browser corpus was not executed against a host. |
| PROOF-04 | 159-01, 159-04, 159-07 | Reject sensitive retained evidence | ✓ SATISFIED | Closed evidence schema, source-bound hashes, scan, and no-replace promotion pass focused regressions. |

All four Phase 159 requirement IDs are declared by plan frontmatter; no orphaned requirements were found.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `lib/crosswake/proof_lane/generator.ex` | 246 | Lexical `Path.expand` containment | 🛑 BLOCKER | Existing symlink ancestors redirect creation outside the host root. |
| `script/verify_generated_ios_shell.sh` | 150 | Build-for-testing followed by passed exit | 🛑 BLOCKER | A passing proof result does not mean any XCTest/XCUITest executed. |
| `priv/templates/crosswake/proof_lane/ios/ProofLaneApp.swift.eex` | 7 | Fixed ready/auth/outcome UI and no-op reconnect | 🛑 BLOCKER | Native pass can certify placeholders rather than host behavior. |
| `script/verify_generated_ios_shell.sh` | 94-120 | Global Git/SwiftPM configuration mutation under local-core mode | ⚠️ WARNING | Can overwrite user configuration and leave redirects after cleanup. |
| `lib/crosswake/proof_lane/evidence.ex` | 502-503 | Hook accepts arbitrary callback return | ⚠️ WARNING | A malformed hook can raise rather than return a sanitized fail-closed error. |
| `priv/templates/crosswake/proof_lane/e2e/support/proof_lane.ts.eex` | 23-28 | Any string accepted as mutation ID | ⚠️ WARNING | Does not enforce the repository helper's opaque mutation-ID shape. |

No `TBD`, `FIXME`, or `XXX` debt markers were found in the phase implementation files inspected.

## Gaps Summary

Phase 159 is not achieved. The original configuration-root, browser type-check, unavailable-proof exit, evidence identity, digest, and promotion-race gaps have been addressed. The final tree still has two independent blocking concerns: generator writes can escape a declared host root through a symlink, and the native lane can return `passed` without executing real tests or receiving host auth/replay/pack behavior. These are not deferred to later phases: Phases 160-162 depend on this proof lane being honest and host-confined.

The browser corpus remains present and type-checked but has no behavioral run in this verification; it is retained above as a behavior-unverified item, not silently counted as verified.

_Verified: 2026-07-31T23:24:47Z_
_Verifier: the agent (gsd-verifier)_
