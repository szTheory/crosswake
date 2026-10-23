---
phase: 175-rehearsal-and-publish
plan: 49
subsystem: release-evidence
tags: [ios-mirror, tag-preflight, rel17]
requires:
  - phase: 175-43
    provides: Candidate-specific release evidence and policy context
provides:
  - Reconciled record of the completed read-only preflight for the missing v0.2.6 iOS mirror tag
affects: [175-45, quality-ratchet-release]
actuals:
  tokens: 1362
  tasks: 1
  commits: 3
plan_head_before: fd12949775d1a80bc45aa7d9a3c33413c85b6231
tech-stack:
  added: []
  patterns: [credential-free-public-ref-preflight, create-only-tag-decision]
key-files:
  created: []
  modified:
    - evidence/175-ios-tag-026-repair.json
key-decisions:
  - Keep tag creation behind a separate blocking-human decision bound to a fresh preflight digest.
  - Do not treat the consumed 0.2.6 Gate 2 token as authority for this one-ref repair.
requirements-completed: []
duration: "checkpointed across prior execution"
completed: 2026-09-28
status: halted
---

# Phase 175 Plan 49: iOS Mirror Tag Preflight Recovery

**The committed preflight is reconciled; its fresh direct-Git dry-run failed, then two later diagnostic retries passed. The receipt remains blocked pending a new full preflight.**

## Performance

- **Duration:** Not reliably measurable across the interrupted execution.
- **Started:** 2026-09-28T16:46:46Z (first plan-scoped preflight commit)
- **Stopped:** 2026-09-28T18:35:03Z
- **Tasks completed:** Task 1 only; Task 2 decision and Task 3 remain pending.
- **Files modified:** 1

## Accomplishments

- Inspected the three existing plan-scoped commits and confirmed their only changed artifact is the phase-local evidence receipt.
- Reconciled Task 1's fresh preflight: exact source tag and subtree split, complete mirror ref observations, configured GitHub credential helper, accepted single-ref dry-run, and current PR #219 identity are recorded.
- Confirmed no public tag write was attempted (`write.attempts` is 0). The 0.2.6 Gate 2 remains consumed and cannot authorize this separate tag action.
- Preserved the newer working-tree checkpoint recheck; it is uncommitted and was not included in the measured three-commit count.
- The latest checkpoint recheck confirmed the source and mirror refs, helper, push permission and PR identity, but the exact direct-Git dry-run exited 1. The receipt now records `BLOCKED_PREFLIGHT`; no create decision was offered.
- At `2026-09-28T18:50:25Z`, two subsequent exact dry-run-only retries each exited 0 and reported the expected single new `refs/tags/v0.2.6` ref. They did not write a ref. The cause of the earlier failure is unknown; these isolated retries do not update the complete preflight receipt or digest.

## Task Commits

1. **Task 1 preflight setup** — `e72f276b` (`docs(175-49): record iOS v0.2.6 tag preflight`)
2. **Task 1 blocked preflight record** — `5633318e` (`docs(175-49): record blocked iOS tag preflight`)
3. **Task 1 fresh preflight** — `97189d71` (`fix(175-49): record fresh iOS tag preflight`)

The commits were measured from `fd12949775d1a80bc45aa7d9a3c33413c85b6231` to the current plan head before this recovery summary.

## Decisions Made

- Task 2 must present the exact target ref, target object, current source and mirror observations, dry-run result, and PREFLIGHT digest before requesting the separate `create_exact_tag` or `hold` decision.
- Do not offer either Task 2 option after a failed dry-run. The later successful diagnostics do not replace Task 1's full preflight; create a fresh plan/preflight and digest before any decision.
- Any change in those facts requires a fresh preflight. A hold results in no write.

## Deviations from Plan

- Manual recovery was required because Task 1 had three plan-scoped commits but no SUMMARY.md and no async-job manifest. This summary records Task 1 only and leaves the plan blocked at its blocking-human decision.

## Next Phase Readiness

The recorded checkpoint recheck failed the exact native-Git dry-run (exit 1; sanitized classification `OTHER_GIT_PUSH_FAILURE`), so Task 2 was not offered. Two later dry-run-only retries passed at `2026-09-28T18:50:25Z`, but no full source/mirror/PR preflight was repeated. The public refs remain unchanged and `write.attempts` is 0. Scope and execute a fresh preflight, then compute a new receipt digest. Only a fully passing fresh preflight may be presented for the separate `create_exact_tag` or `hold` decision. No 0.2.7 merge or publisher action is authorized.

---
*Phase: 175-rehearsal-and-publish*
*Blocked: 2026-09-28 at Task 2 decision*
