---
phase: 175-rehearsal-and-publish
plan: 65
type: execute
status: complete
---

# Plan 175-65 Summary

## Outcome

Plan65 completed one fresh, bounded diagnostic under its own lifecycle identity. The Plan65 decoder accepted the workflow-content response and decoded it within the existing size limits. The workflow-content reason is `ok`; the decoded workflow did not satisfy the existing aggregate contract, so `aggregate_proven` is `FALSE`. The D-76 failed-jobs rerun was not requested because that proof gate failed. The stale-age interval itself passed (more than 24 hours and no more than 365 days).

The selected run was `36438452825`, attempt `1`. Its complete roster contains 49 jobs: 47 SUCCESS, 2 FAILURE, and 0 UNKNOWN. The observed required-status connection is 49/49 unique contexts, complete: `TRUE`. The exact two-failure shape is present, but it is not enough to authorize a rerun without the decoded workflow aggregate proof.

The source tag observation matched the validated expected source identity. PR, run, required-status, declaration, tag-policy, push-permission, and latest-run probes were complete. Workflow envelope counts were 111781 encoded bytes and 82460 decoded bytes; no workflow bytes or content hash were persisted.

## Closeout

CI rerun: `NOT_REQUESTED` (`rerun_predicates_false`). Repair-attempt eligibility: `BLOCKED`. Candidate release readiness: `BLOCKED`. Plan55 remains UNKNOWN; REL-13 and REL-17 remain OPEN; the release hold is ACTIVE; Phase 175 remains incomplete. No source split, push dry-run, tag write, merge, Gate 2, recovery, registry operation, or publication occurred.

## Verification

- Focused ExUnit suites: 69 tests, 0 failures.
- Formatter check passed for the two source modules and two focused test files.
- Plan65 artifact/lifecycle validator passed.
- The independent Plan65 plan checker and corrected D-76 source review passed.

## Next step

Create a separate reviewed local diagnostic to identify why the decoded exact-head workflow did not satisfy the aggregate contract. Preserve this Plan65 pair and do not repeat its collection or conditional rerun. Any further remote collection needs its own reviewed plan; source and release actions remain outside this boundary.

<!-- plan65-closeout: {"attempt_id":"5297b97bc524f94ffa3c9fb739f29452","candidate_release_readiness":"BLOCKED","ci_rerun":"NOT_REQUESTED","plan55":"UNKNOWN","rel13":"OPEN","rel17":"OPEN","release_hold":"ACTIVE","repair_attempt_eligibility":"BLOCKED","rerun_reason":"rerun_predicates_false","schema":"crosswake-plan65-closeout/v1","sha256":"321c95fd1643f7c7d5f4868b991b2ab67aa9e36fc87578998db9b73bc0e008ea","terminal_event":"preflight-collected","workflow_contents_reason":"ok"} -->
