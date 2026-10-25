---
phase: 175-rehearsal-and-publish
plan: 99
status: complete
completed: 2026-10-07
---

# Plan99 Execution Summary

Plan99 closed the local collector defect found after Plan98. The source checkout now happens before `git subtree split`, and the diagnostic validator accepts failures at that new step.

## Accomplishments

- The Plan98 source commit contains `packages/crosswake-shell-core-ios` with tree `b80f3bf00ef61708120b062bc88738fed88294a9`.
- A disposable local clone reproduced the failure without checkout and succeeded after a detached checkout of the exact source commit. The split commit is `424ab96ede1b92f2b751b54bce04c6e607f0f3c8`, equal to the observed mirror `main` and `v0.2.5` commit. Its tree matches the source package tree.
- Saved the local result, bound to Plan98's sealed attempt and preflight, in `evidence/175-plan98-split-reproduction.json`. Plan98's terminal BLOCKED file remains unchanged; the reproduction made no public requests.
- Updated the collector to check out the exact peeled source commit before splitting. Removed the redundant final object check because resolving the split commit's tree already proves the commit exists. The sequence stays within nine Git spawns.
- Added a fake-runner test for the exact checkout command/order and updated the Elixir diagnostic allowlist/test for the new `SOURCE_CHECKOUT` stage.

## Verification

- `node --test script/release_candidate/plan87_mirror_ref.test.mjs` — 21 passed.
- `node --check script/release_candidate/plan87_mirror_ref.mjs` — passed.
- `mix test test/crosswake/release_candidate/plan94_mirror_read_test.exs` — 11 passed.
- Scoped `git diff --check` — passed.
- Supplemental evidence OID and no-network assertions — passed.

No additional GitHub/API request, CI run, credential lookup, tag operation, merge, or release action occurred. Write permission remains `UNKNOWN`, tag authority `NONE`, release readiness `BLOCKED`, and the release hold remains active. Phase175 is still incomplete.
