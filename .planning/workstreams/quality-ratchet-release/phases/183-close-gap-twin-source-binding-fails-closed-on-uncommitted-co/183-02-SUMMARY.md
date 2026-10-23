---
phase: 183-close-gap-twin-source-binding-fails-closed-on-uncommitted-co
plan: 02
status: complete
requirements: [TWIN-01, TWIN-05]
commits: 0
---

# Phase 183 Plan 02: Fail-closed clean-tree guard in the twin producers

A twin candidate whose working tree differs from its attested commit is now refused at freeze, and again after the run, with the named cause `source_dirty`. No commit was made, by design (D-16): the edits sit uncommitted in `/private/tmp/crosswake-phase180-impl` for 183-03's single fix commit. Planning-doc commits were skipped (commit_docs not honored); STATE.md and ROADMAP.md were not touched.

## What was built

- `TwinProducers.clean_tree/2`: one scrubbed `git status --porcelain=v1 -z --untracked-files=all` probe plus an explicit `.git/info/exclude` check (any non-blank, non-`#` line blocks). Returns `:ok`, `{:blocked, :source_dirty}` or `{:blocked, :prerequisite_missing}`. Output is only counted.
- `TwinProducers.dirty_count/2`: dirty records plus active exclude rules (a rename counts once); `nil` if git cannot answer.
- `TwinProducers.checked_identities/3`: runs `clean_tree/2`, then `observe_identities/2`; otherwise `{:blocked, cause}`.
- `@git_scrub_env` and an `sh -c 'exec "$@" 2>/dev/null'` runner for every git call, including the reworked `git/2`; a missing git or sh becomes `:prerequisite_missing`, never a crash.
- `freeze/3`: probe runs after the HEAD/tree checks and before lock digests and the backend compile.
- `observe_identities/2`: reads HEAD/tree, probes, reads again; source, installed_build and backend_build exist only if the tree is clean and both reads equal the frozen commit.
- Journey observe step now goes only through `checked_identities/3`, so a dirty tree after the run becomes a blocked receipt with first cause `source_dirty`.
- `:source_dirty` added to `TwinReceipt` causes (before `:cause_not_retained`).

## Tests

- Producers suite: 24 existing (fixture moved so identity files and run root sit in a sibling temp dir, isolated real git per D-13) plus 19 new in `describe "source cleanliness"` = 43. They cover clean, modified, staged, deleted, untracked, rename (count 1), repo-gitignored (clean), global-excludes (control first, still blocks), info/exclude variants, GIT_DIR in the test env, unavailable git, non-repo, empty captured stderr, the fd-level fake-git stderr test (sentinel only "null", at least four lines), the twin-03 shape, the leak-marker privacy case, dirty-after-freeze, HEAD-moved, and the unchanged pass-through.
- Journey: one source-gate test. Mix task: one `first cause: source_dirty` exit-2 test.
- Final run of all five twin suites plus the phase170 ledger suite: 112 tests, 0 failures (exit 0). The producers suite alone is 43 tests.
- Plan grep checks all pass; no unscrubbed `System.cmd("git"`, no `"PATH"` in production code, journey has zero direct `observe_identities(` calls.

## Deviations

None of substance. Notes:
- To give the new describe the same fixture, the existing setup was extracted into a shared `repo_fixture/1` helper used by both describes.
- Backend_build also goes absent for a dirty or moved tree (accepted fail-closed, per plan); covered by its own test.
- The fd-level test's non-vacuity under mutation (removing the wrapper) was not exercised here; that is 183-03's mutation controls.

## State check

Candidate HEAD unchanged (subject "feat(180-07): document running the reference twin"); six files modified, uncommitted (555 insertions, 98 deletions). Recovery checkout HEAD still d0f3e2f1, nothing staged. The twin itself was not run.

Files: twin_producers.ex, twin_receipt.ex, twin_journey.ex under `lib/crosswake/proof_lane/`; twin_producers_test.exs, twin_journey_test.exs, and `test/mix/tasks/crosswake_proof_lane_verify_twin_test.exs` in the candidate.

## Self-Check: PASSED
