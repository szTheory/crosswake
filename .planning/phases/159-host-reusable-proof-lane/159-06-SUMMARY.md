---
phase: 159-host-reusable-proof-lane
plan: "06"
subsystem: host-reusable-proof
tags: [playwright, typescript, ios, proof-lane]
requires:
  - 159-03 host-owned browser proof seam
provides:
  - cleanup-safe primary and generated browser helpers
  - focused TypeScript proof gate
  - closed generated-iOS proof outcome protocol
affects: [PROOF-01, PROOF-03]
tech_stack:
  added: [TypeScript focused tsconfig, Playwright helper regression, ExUnit fake xcodebuild shims]
  patterns: [opaque mutation-ID retention, try/finally context cleanup, JSON-lines closed outcomes]
key_files:
  created:
    - examples/phoenix_host/tsconfig.offline_route_proof.json
    - examples/phoenix_host/e2e/support/offline_route_proof.typecheck.d.ts
    - examples/phoenix_host/e2e/crosswake_proof_lane/browser_online_restore.spec.ts
    - examples/phoenix_host/e2e/crosswake_proof_lane/support/proof_lane.ts
    - test/crosswake/proof_lane/ios_verifier_test.exs
  modified:
    - examples/phoenix_host/e2e/support/offline_route_proof.ts
    - priv/templates/crosswake/proof_lane/e2e/support/proof_lane.ts.eex
    - script/verify_generated_ios_shell.sh
decisions:
  - Retain the opaque mutation ID returned by the shared helper for the history assertion.
  - Restore BrowserContext online state in finally before allowing proof errors to propagate.
  - Generated iOS proof uses only passed, blocked, or unavailable JSON outcomes; only a successful target build exits zero.
metrics:
  duration: "14m"
  completed_date: "2026-07-31"
  tasks_completed: 3
  files_changed: 10
status: complete
---

# Phase 159 Plan 06: Browser Proof and Closed iOS Outcome Summary

The preserved primary browser corpus now type-checks, retains its app-generated opaque mutation ID through the history assertion, and restores shared browser connectivity even when a mutation callback fails; generated iOS proof results are closed, machine-readable outcomes.

## Tasks Completed

1. Added the focused TypeScript gate and made repository/template helpers return the opaque mutation ID after reconnect, confirmation, empty-outbox, and duplicate-idempotency assertions.
2. Added an executable Playwright regression for failure-path online restoration in both the repository and byte-checked rendered generated helper.
3. Added fake-toolchain ExUnit coverage and changed proof-lane iOS verification to emit JSON Lines `passed`, `blocked`, or `unavailable` outcomes with zero reserved for a successful generated-target build.

## Verification

- `npm --prefix examples/phoenix_host run typecheck:offline-route-proof`
- `npm --prefix examples/phoenix_host test -- offline_sync.spec.ts e2e/crosswake_proof_lane/browser_online_restore.spec.ts`
- `mix test test/crosswake/proof_lane/ios_verifier_test.exs test/crosswake/proof_lane/template_contract_test.exs`
- `bash -n script/verify_generated_ios_shell.sh`

All commands passed.

## Decisions Made

- Browser proof cleanup is structural: each helper calls `setOffline(false)` in `finally` before reconnect and later proof assertions.
- The iOS verifier keeps raw tool output out of proof-lane machine records and emits only stable outcome, rule ID, and low-cardinality scope fields.

## Deviations from Plan

### Auto-fixed Issues

1. [Rule 3 - Blocking issue] Corrected the isolated regression's repository-helper import path.
- **Found during:** Task 2
- **Issue:** The proof-owned spec initially resolved the shared helper outside the E2E support directory.
- **Fix:** Changed the import to the direct sibling support path before running the runtime regression.
- **Files modified:** `examples/phoenix_host/e2e/crosswake_proof_lane/browser_online_restore.spec.ts`
- **Commit:** `552fb18a`

2. [Rule 3 - Blocking issue] Made missing-tool simulation independent of the local Xcode installation.
- **Found during:** Task 3
- **Issue:** A host-installed `xcodebuild` could make the missing-tool fake fixture exercise enumeration instead.
- **Fix:** Added the internal `CROSSWAKE_IOS_XCODEBUILD_BIN` command selector used by the hermetic fake-toolchain test.
- **Files modified:** `script/verify_generated_ios_shell.sh`, `test/crosswake/proof_lane/ios_verifier_test.exs`
- **Commit:** `78e40ad5`

## Known Stubs

None.

## Self-Check: PASSED

- All ten plan artifacts exist in the working tree.
- Task commits `cdbd4391`, `a97c9345`, `552fb18a`, `a3d73055`, and `78e40ad5` exist in Git history.
