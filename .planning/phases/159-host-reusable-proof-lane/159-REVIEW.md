---
phase: 159-host-reusable-proof-lane
reviewed: 2026-08-01T22:31:08Z
depth: standard
files_reviewed: 29
files_reviewed_list:
  - examples/phoenix_host/e2e/crosswake_proof_lane/browser_online_restore.spec.ts
  - examples/phoenix_host/e2e/crosswake_proof_lane/support/proof_lane.ts
  - examples/phoenix_host/e2e/support/offline_route_proof.ts
  - examples/phoenix_host/e2e/support/offline_route_proof.typecheck.d.ts
  - examples/phoenix_host/package.json
  - examples/phoenix_host/tsconfig.offline_route_proof.json
  - lib/crosswake/proof_lane/config.ex
  - lib/crosswake/proof_lane/evidence.ex
  - lib/crosswake/proof_lane/generator.ex
  - lib/crosswake/proof_lane/generator_fs.ex
  - lib/crosswake/proof_lane/native_promotion.ex
  - lib/mix/tasks/crosswake.gen.proof_lane.ex
  - priv/native/crosswake_evidence_promote.c
  - priv/native/crosswake_proof_lane_fs.c
  - priv/templates/crosswake/proof_lane/e2e/support/proof_lane.ts.eex
  - priv/templates/crosswake/proof_lane/ios/CrosswakeProofLane.xcodeproj/project.pbxproj.eex
  - priv/templates/crosswake/proof_lane/ios/CrosswakeProofLane.xcodeproj/xcshareddata/xcschemes/CrosswakeProofLane.xcscheme.eex
  - priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneTests/ProofLaneContractTests.swift.eex
  - priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneUITests/ProofLaneUITests.swift.eex
  - priv/templates/crosswake/proof_lane/ios/ProofLaneApp.swift.eex
  - priv/templates/crosswake/proof_lane/ios/ProofLaneDriver.swift.eex
  - priv/templates/crosswake/proof_lane/test/crosswake_proof_lane_test.exs.eex
  - script/verify_generated_ios_shell.sh
  - script/verify_phoenix_host_proof_lane.sh
  - test/crosswake/proof_lane/config_test.exs
  - test/crosswake/proof_lane/evidence_test.exs
  - test/crosswake/proof_lane/ios_verifier_test.exs
  - test/crosswake/proof_lane/template_contract_test.exs
  - test/mix/tasks/crosswake_gen_proof_lane_test.exs
findings:
  critical: 1
  warning: 1
  info: 0
  total: 2
status: issues_found
---

# Phase 159: Code Review Report

**Reviewed:** 2026-08-01T22:31:08Z
**Depth:** standard
**Files Reviewed:** 29
**Status:** issues_found

## Summary

The proof lane has careful missing-only generation, opaque evidence validation, and fail-closed native verification. However, the advertised Phoenix-host proof command does not execute the generated host proof at all, so it can report success based only on repository-specific fixtures. Configuration validation also permits a single backslash through an EEx-to-TypeScript string boundary despite intending to reject TypeScript-unsafe endpoint characters.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Proof command omits the generated host proof

**File:** `/Users/jon/projects/crosswake/examples/phoenix_host/package.json:8`
**Issue:** `proof:offline-island` runs `offline_sync.spec.ts` and `browser_online_restore.spec.ts`, but not the generator's `e2e/crosswake_proof_lane/proof_lane.spec.ts`. The latter is the host-owned proof that supplies the real route adapter, checks backend confirmation, drains the outbox, and performs the duplicate replay. The included `browser_online_restore.spec.ts` only invokes the helpers with stubs (`contextLog` and callbacks that flip a boolean), so this command can pass even when the generated/host-specific proof has been deleted, does not compile, or fails all real replay assertions. This produces a false passing proof artifact for the first-adopter route.

**Fix:** Include the generated proof spec in the command and make the typecheck scope cover its support module. For example:

```json
"proof:offline-island": "playwright test e2e/offline_sync.spec.ts e2e/crosswake_proof_lane/proof_lane.spec.ts e2e/crosswake_proof_lane/browser_online_restore.spec.ts"
```

If the generated spec is deliberately absent until a host installs it, have the command fail closed with a stable `PL-*` prerequisite result rather than silently substituting helper-only tests.

## Warnings

### WR-01: Single backslashes bypass endpoint validation and alter generated TypeScript values

**File:** `/Users/jon/projects/crosswake/lib/crosswake/proof_lane/config.ex:141-155`
**Issue:** `host_local_path?/1` checks for `"\\\\"`, which is a two-backslash string in Elixir, rather than a single backslash. Consequently `Config.normalize/1` accepts `sync_path: "/study/\\n"` (confirmed directly), and the template writes it into a double-quoted TypeScript literal. TypeScript interprets the escape, so the runtime endpoint differs from the reviewed configuration; other escapes can make the generated source invalid. This violates the stated fail-closed protection for TypeScript-unsafe endpoint values.

**Fix:** Reject every backslash, and add a regression case with exactly one backslash (not two):

```elixir
not String.contains?(value, ["\\", "\"", "\0", "\r", "\n"])
```

Also retain the existing generated-render/typecheck test so a future interpolation change cannot reintroduce escape handling.

---

_Reviewed: 2026-08-01T22:31:08Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
