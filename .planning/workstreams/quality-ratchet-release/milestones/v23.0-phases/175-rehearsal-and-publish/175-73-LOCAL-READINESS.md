# Plan 175-73 local readiness stop

**Date:** 2026-10-02  
**Status:** Read decision granted; the one remote preflight has not started.

**Superseding next-action record (2026-10-03):** Plan75's local-only rulesets repair is complete.
After `CROSSWAKE_PLAN73_READ_TOKEN` is available, run
`$gsd-execute-phase 175 --ws quality-ratchet-release --wave 6`. The older planning recommendation
below is historical; do not repeat it.

## 2026-10-03 credential setup follow-up

Do not issue or store `CROSSWAKE_PLAN73_READ_TOKEN` yet. The local collector still requests
`/repos/szTheory/crosswake-shell-core-ios/tags/protection` and requires its response to complete
the policy snapshot. GitHub sunset tag protections on August 30, 2024, migrated them to rulesets,
and documents repository rulesets as the replacement. The old API returns null data after sunset,
so a token cannot make the current collector produce complete policy evidence. See the
[GitHub sunset notice](https://github.blog/changelog/2024-05-29-sunset-notice-tag-protections/) and
[repository rulesets API](https://docs.github.com/en/rest/repos/rules).

Before credential setup, plan a local-only continuation to remove the retired route from both
allowlists and the policy projection, use the already-approved repository-rulesets observation as
the canonical policy source, and update Plan73/Plan74 evidence validation. This reduces the token
to repository `Metadata: read` for rulesets plus the existing `Contents: read`, `Checks: read`,
and `Pull requests: read` requirements. No added endpoint or authority is needed. The existing
one-read authorization stays valid for the same source, mirror, PR, CI, and applicable tag-policy
scope; do not request it again. Keep the credential absent until the revised local contract passes.

**Historical next GSD action (superseded by Plans75/76):** `$gsd-plan-phase 175 --ws quality-ratchet-release`.
After planning and implementing the local contract, the user must create a short-lived
fine-grained read-only token for only `crosswake` and `crosswake-shell-core-ios`, with no write
permissions, then make it available as `CROSSWAKE_PLAN73_READ_TOKEN` to the GSD execution
environment without pasting it into chat or saving it in the repository. The agent must not use
stored `gh` login, an alternate token variable, or the GitHub connector for this bounded read.

## Boundary

The maintainer explicitly authorized one read-only Plan73 preflight for the previously stated
source, mirror, PR #219, and applicable tag-policy scope. That authorization remains limited to
that scope. No remote command, GitHub API call, clone, fetch, credential validation, tag write, CI
rerun, or release action ran during this readiness review. Both planned Plan73 evidence paths remain
absent; no attempt ID or receipt was created.

The execution environment has no `CROSSWAKE_PLAN73_READ_TOKEN`, `GH_TOKEN`, or `GITHUB_TOKEN`.
`gh` is installed and a stored login may exist, but its scopes are unverified. Do not use it for
Plan73: checking the stored login may itself contact GitHub, and it does not establish an
endpoint-minimum read-only credential.

## Local execution blockers

1. `Mix.Tasks.Crosswake.Release.MirrorTag026` only accepts the test-injected
   `:plan72_injected_adapter`; no production read adapter is configured.
2. The current preflight reducer stops at the first failed stage and marks candidate identity ready
   only when required CI is `SUCCESS` on the PR head. The known required-CI failure is caused by the
   missing mirror tag, so this gates the prerequisite read on the downstream result the tag is
   intended to unblock. It also prevents the later candidate and policy observations from running.
3. The coordinator writes filenames directly under its root using
   `175-ios-tag-026-plan73-preflight.json` and `175-ios-tag-026-plan73.lifecycle.jsonl`. Plan73
   expects different names under the phase `evidence/` directory.
4. The emitted schema is `crosswake-plan73-ios-mirror-tag-preflight/v1`, while Plan73 specifies
   `crosswake-plan73-mirror-tag-026-preflight/v1`.
5. The current artifact/fake callback contract does not represent all Plan73 facts: start/end
   identity snapshots, exact mirror main/prior refs, source-prefix and split tree comparison, PR
   tree and 0.2.7 identity, and complete applicable tag-policy observations.

The existing bounded child collector is a useful local primitive, but it does not provide these
missing operation and evidence contracts by itself.

## Required replan before the read

Create a local Plan73 implementation task that:

- adds a production adapter with fixed endpoint/command allowlists, bounded pagination, time and
  output limits, sanitized results, and explicit use of `CROSSWAKE_PLAN73_READ_TOKEN` only;
- collects all required source, mirror, candidate, CI, and policy facts in one attempt, including
  the required start/end identity comparisons, without requiring candidate CI to pass before the
  tag prerequisite is observed;
- aligns the artifact and lifecycle paths, schema, offline inspector, and Plan73/Plan74 validators;
- adds deterministic fake coverage for complete, incomplete, drifted, and persistence-failure
  cases, and runs the plan's named local checks before any remote request.

Keep the remote endpoint and operation scope identical to the already-authorized Plan73 read. If
the implementation requires any additional remote endpoint or authority, stop and obtain a new
decision for that changed scope. Once local checks pass and a read-only credential is available
through the execution environment, the existing one-read authorization can be used without asking
again for the same scope. Plan74 still requires its separate digest/object/ref-bound tag-write
authorization.

## Release posture

Plan73 has no remote result and remains incomplete. Plan74 was not started. Plan55 and Plan70 remain
UNKNOWN; REL-13/REL-17 remain OPEN; candidate readiness remains BLOCKED; merge-policy remains
UNKNOWN; the release hold remains ACTIVE; Plans45–48 remain held.
