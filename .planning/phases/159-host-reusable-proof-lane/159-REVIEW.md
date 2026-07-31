---
phase: 159-host-reusable-proof-lane
reviewed: 2026-07-31T23:20:51Z
depth: standard
files_reviewed: 23
files_reviewed_list:
  - examples/phoenix_host/e2e/crosswake_proof_lane/browser_online_restore.spec.ts
  - examples/phoenix_host/e2e/crosswake_proof_lane/support/proof_lane.ts
  - examples/phoenix_host/e2e/support/offline_route_proof.ts
  - examples/phoenix_host/e2e/support/offline_route_proof.typecheck.d.ts
  - examples/phoenix_host/tsconfig.offline_route_proof.json
  - lib/crosswake/proof_lane/config.ex
  - lib/crosswake/proof_lane/evidence.ex
  - lib/crosswake/proof_lane/generator.ex
  - lib/crosswake/proof_lane/native_promotion.ex
  - lib/mix/tasks/crosswake.gen.proof_lane.ex
  - priv/native/crosswake_evidence_promote.c
  - priv/templates/crosswake/proof_lane/e2e/support/proof_lane.ts.eex
  - priv/templates/crosswake/proof_lane/ios/CrosswakeProofLane.xcodeproj/project.pbxproj.eex
  - priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneTests/ProofLaneContractTests.swift.eex
  - priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneUITests/ProofLaneUITests.swift.eex
  - priv/templates/crosswake/proof_lane/ios/ProofLaneApp.swift.eex
  - priv/templates/crosswake/proof_lane/test/crosswake_proof_lane_test.exs.eex
  - script/verify_generated_ios_shell.sh
  - test/crosswake/proof_lane/config_test.exs
  - test/crosswake/proof_lane/evidence_test.exs
  - test/crosswake/proof_lane/ios_verifier_test.exs
  - test/crosswake/proof_lane/template_contract_test.exs
  - test/mix/tasks/crosswake_gen_proof_lane_test.exs
findings:
  critical: 3
  warning: 3
  info: 0
  total: 6
status: issues_found
---

# Phase 159: Code Review Report

**Reviewed:** 2026-07-31T23:20:51Z
**Depth:** standard
**Files Reviewed:** 23
**Status:** issues_found

## Summary

The supplied proof-lane implementation preserves host files and the focused ExUnit suite passes (32 tests). However, the iOS proof lane can emit a passing result without running a generated test or proving host behavior, and the generator does not maintain its claimed write containment when a host tree contains symlinks. The evidence hook and generated browser adapter also have fail-closed gaps.

## Critical Issues

### CR-01: Proof verifier reports `passed` without executing native tests

**Classification:** BLOCKER

**File:** `script/verify_generated_ios_shell.sh:143-155`

**Issue:** The proof-lane branch merely searches `xcodebuild -list` text for the test target names and runs `build-for-testing`; it never invokes `test` or `test-without-building`. The generated project supplies no shared `.xcscheme` test action, so the selected application scheme does not establish that either XCTest/XCUITest target is built or run. A compiling app can therefore produce the machine-readable `passed` outcome even when its native assertions fail or never execute, contrary to the required executable device-proof posture.

**Fix:** Generate and require a shared scheme with both test targets in its `TestAction`, then run `xcodebuild test` (or `build-for-testing` followed by `test-without-building`) against that scheme. Derive `passed` only from its zero exit status; treat absent scheme/targets or a test failure as blocked.

### CR-02: Fresh generated iOS lane passes static placeholder assertions, not host auth/replay behavior

**Classification:** BLOCKER

**File:** `priv/templates/crosswake/proof_lane/ios/ProofLaneApp.swift.eex:7-12`

**Issue:** The generated app always renders the ready/auth/outcome labels and a no-op reconnect button. The generated UI test only checks those fixed accessibility identifiers, while the contract test only checks hard-coded `blocked`/`unavailable` values. None of the configured route, router, evidence endpoint, backend authority, replay, or relaunch state reaches the Swift code. Thus even if CR-01 is fixed and tests execute, an unintegrated host scaffold is green and can be represented as proof of shell boot/auth continuity.

**Fix:** Make the initial generated lane explicitly non-passing until the host supplies an adapter that performs and exposes the real auth/replay assertions. Require that adapter in the generated test scheme and have it fail when absent; bind the UI assertions to observable host-provided state rather than literal placeholder text.

### CR-03: Generator containment check is bypassed by symlinked destination parents

**Classification:** BLOCKER

**File:** `lib/crosswake/proof_lane/generator.ex:133-135,246-249`

**Issue:** `within?/2` compares lexical `Path.expand` values, which does not resolve symlinks. If a host-owned path such as `<host-root>/e2e` or `<host-root>/native` is a symlink to a directory outside the root, `validate_destinations/2` accepts it and `File.mkdir_p`/`File.open` follows it. The missing-only generator can then create files outside the configured host root, defeating its fail-closed containment guarantee.

**Fix:** Reject symlinks in every existing destination ancestor before creating directories, and re-check immediately before opening the final path. For a strong race-safe boundary, perform traversal and creation using directory file descriptors (`openat`/`O_NOFOLLOW`) or a small native helper rather than path-string checks.

## Warnings

### WR-01: Hermetic verifier permanently mutates global Git and SwiftPM configuration

**Classification:** WARNING

**File:** `script/verify_generated_ios_shell.sh:94-120`

**Issue:** With `CROSSWAKE_IOS_USE_LOCAL_CORE=1`, the script deletes a fixed directory, writes a global Git `insteadOf` redirect, and overwrites `~/.swiftpm/configuration/mirrors.json`. Cleanup removes neither global setting. Later Git/SwiftPM commands can be redirected to the deleted temporary clone, and the user's pre-existing mirror configuration is lost.

**Fix:** Use per-process Git configuration (`git -c ...` or an isolated `GIT_CONFIG_GLOBAL`) and an isolated SwiftPM configuration/cache directory. Create the clone with `mktemp -d`, and restore any state in the exit trap if a global setting is unavoidable.

### WR-02: A malformed promotion hook raises instead of returning a sanitized error

**Classification:** WARNING

**File:** `lib/crosswake/proof_lane/evidence.ex:136,502-503`

**Issue:** `run_hook/1` returns any zero-arity callback value. Any value other than `:ok` or `{:error, ...}` makes the surrounding `with` fall through no `else` clause and raises `WithClauseError`. This was reproduced with `before_promote: fn -> :unexpected end`. The public promotion API therefore crashes instead of fail-closing with a `PL-EVIDENCE-*` result.

**Fix:** Accept only `:ok` from hooks; convert every other return (and exceptions) into `error("PL-EVIDENCE-PROMOTE", ...)`. Add a regression test for a non-`:ok` hook return.

### WR-03: Generated proof accepts any string as a mutation identifier

**Classification:** WARNING

**File:** `priv/templates/crosswake/proof_lane/e2e/support/proof_lane.ts.eex:23-28`

**Issue:** The generated adapter checks only `typeof value === 'string'`, whereas the repository proof helper requires the expected UUID form. A host adapter can accidentally extract an account/card label or another arbitrary string and still run the backend and duplicate checks, weakening the exact-once proof and risking that a stable identifier is passed through proof helpers.

**Fix:** Enforce the same closed mutation-ID format as the repository helper (or make the allowed opaque-ID validator an explicit required configuration contract) before reconnect/replay assertions; mirror the change in the checked-in generated fixture.

---

_Reviewed: 2026-07-31T23:20:51Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
