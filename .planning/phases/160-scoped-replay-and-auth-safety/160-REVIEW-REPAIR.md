---
phase: 160-scoped-replay-and-auth-safety
reviewed: 2026-08-03T03:01:03Z
depth: standard
files_reviewed: 3
files_reviewed_list:
  - examples/phoenix_host/e2e/crosswake_proof_lane/proof_lane.spec.ts
  - examples/phoenix_host/e2e/offline_sync.spec.ts
  - test/fixtures/crosswake/proof_lane/phoenix_host/proof_lane_host_adapter.ts
findings:
  critical: 0
  warning: 1
  info: 0
  total: 1
status: issues_found
---

# Phase 160: Repair Code Review Report

**Reviewed:** 2026-08-03T03:01:03Z
**Depth:** standard
**Files Reviewed:** 3
**Status:** issues_found

## Summary

Reviewed the repair's request-bound session setup, scope-isolation assertions, test-only confinement, sensitive-data exposure, and replay-proof assertions. The proof establishes its session through the test-only endpoint before navigation, then requires a real successful replay response, a server-side persisted row for the app-generated mutation ID, an empty scoped IndexedDB outbox, and an idempotent duplicate result. The test-only endpoint is compile-time confined to `:test` and `:e2e`; the reviewed test data contains only fixture scope references and mutation metadata, not raw answers, credentials, account IDs, tokens, or stable device IDs.

The initially named `examples/.../phoenix_host/proof_lane_host_adapter.ts` path is absent from the worktree. The actual generated-host adapter fixture is `test/fixtures/crosswake/proof_lane/phoenix_host/proof_lane_host_adapter.ts`, which is now included in this review.

## Narrative Findings (AI reviewer)

## Warnings

### WR-01: Module-global adapter state can validate a different proof invocation

**File:** `test/fixtures/crosswake/proof_lane/phoenix_host/proof_lane_host_adapter.ts:12-13`

**Issue:** `request` and `proofPage` are module globals that `navigate` overwrites (lines 17-18), while the later backend and outbox assertions consume those globals (lines 46 and 64-65). A generated host can enable parallel tests or invoke this adapter twice concurrently in one worker. In that case, proof A can persist its mutation but inspect proof B's request context and empty IndexedDB outbox after proof B overwrites the globals. This allows A to pass the "outbox empty" portion without its own replay having removed its queued event, weakening the generated proof's replay guarantee.

**Fix:** Export an adapter factory and instantiate it per test invocation, retaining request and page only in that closure. Update the generated spec template to call the factory inside its test.

```ts
export function createProofLaneHostAdapter(): ProofLaneAdapter {
  let request: APIRequestContext | undefined;
  let proofPage: Page | undefined;

  return {
    async navigate(page) {
      request = page.request;
      proofPage = page;
      // establish the test-only session and navigate
    },
    async assertBackendConfirmation(mutationId) {
      await expectSyncedReview(request!, mutationId);
    },
    async assertDuplicateIdempotency(mutationId, record, config) {
      // use request! for the duplicate request
      await expectOutboxEmpty(proofPage!);
    },
  };
}
```

---
---

_Reviewed: 2026-08-03T03:01:03Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
