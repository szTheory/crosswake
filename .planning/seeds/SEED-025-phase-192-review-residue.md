---
id: SEED-025
title: Phase 192 review residue
status: dormant
severity: medium
trigger_when: >-
  Surface before the next change to CI failure output or to the Xcode-only test setup (the
  credential-masking gap ranks first), and again before the next twin run (the owner-check and
  child-process items). NOT blocking today: nothing here changed a Phase 192 outcome; what remains
  is one credential-leak gap in public CI logs plus hardening and a missing CI lane.
created: 2026-10-23
related: [SEED-023, SEED-024]
---

# SEED-025: Phase 192 review residue

The Phase 192 code review found 0 critical, 8 warning and 6 info items, all recorded open because
the PR had already merged and a fix to product code needs a new PR. The items below are the ones
Phase 193 chose to keep visible, each with a trigger so they are not forgotten. The other review
items live in the one-time phase scripts and stay in 192-REVIEW-DISPOSITION.md.

## Before any change to CI failure output (credential-leak gap, ranked first)

- WR-01: the failure-tail masking in the root proof script misses some credential shapes: an
  `Authorization: Bearer` line keeps its token, an `AWS_SECRET_ACCESS_KEY=` value prints unmasked,
  and a cookie line is not masked. That output goes to the public Actions log on every root-proof
  failure. Done looks like masking the whole credential line shape, with unit tests for the bearer,
  secret-access-key, cookie and short-value shapes that fail when the mask is removed.

## Before the next twin run

- WR-02: the twin owner check does not handle a missing OS process id (`os_pid` nil) that the
  CI race fix now returns, so a foreign listener on a dead backend's port raises instead of
  returning the typed denial. Done looks like a nil pid counting as not owned, with a test that
  passes a nil pid and a foreign listener and expects `backend_listener_not_owned`.
- IN-01: the child-start helper rescues every exception as `prerequisite_missing`, and a child with
  no pid is never signalled on cleanup. Done looks like rescuing only the port-open error and
  attempting group cleanup when the wrapper reports a group id, with a test for each path.

## Before the next change to the Xcode-only tests or the CI workflow

- WR-03: the tests tagged `requires_xcodebuild` are excluded whenever `xcodebuild` is missing and no
  CI lane runs them, so they run only on a developer's Mac and nothing reports the skip.
  Done looks like a macOS CI job that runs them with `xcodebuild` asserted present (so the lane cannot be
  empty), or a CI-only failure when the tag is excluded on a Mac host.
- The missing example-host full-suite CI lane (191 D-14): no CI lane runs the full example-host
  suite. Done looks like one CI job that runs it and goes red on a failing example-host test, added
  only after measuring its findings on a throwaway branch (see the absence-scored-as-success guard).

## Record fixes

- IN-02: PR #242's public body is stale against the merged head (older head, 114 commits instead of
  117) and its "clean" privacy claim excludes the adopter-identity check that was skipped (A-14).
  Done looks like the final head and commit count stated in the phase record, and the A-14 caveat
  carried in the Phase 193 handoff; the merged PR body is not edited.

## Source

- [192-REVIEW.md](../workstreams/quality-ratchet-release/phases/192-pr-ci-and-merge/192-REVIEW.md)
  and
  [192-REVIEW-DISPOSITION.md](../workstreams/quality-ratchet-release/phases/192-pr-ci-and-merge/192-REVIEW-DISPOSITION.md).
- [193-CONTEXT.md](../workstreams/quality-ratchet-release/phases/193-cleanup-and-new-working-rules/193-CONTEXT.md),
  decision D-21.
