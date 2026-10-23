# Phase 175 — 0.2.4 Recovery Decision Draft

**Status:** Draft for planning; not a publish authorization.
**Prepared:** 2026-09-24
**Decision scope:** Missing iOS tag and Maven Central coordinate for core `0.2.4`.

## Observed state

The one authorized ordinary Release Please run, `36035737504`, is bound to merge
`f3827d0bf4131badd96d04d924f9faca2789d284` and concluded `failure`. Its Hex publish job
succeeded; the iOS and Maven jobs failed; exact-public proof and clean-room jobs were skipped.
The Gate 2 authorization was for this one ordinary graph and is recorded as consumed in
`evidence/175-fresh-core-release-run-0.2.4.json`.

Fresh read-only observations at `2026-09-24T19:12:44Z`:

| Coordinate | Observation | Evidence |
|---|---|---|
| Hex `crosswake@0.2.4` | Present | Hex package API lists `0.2.4` |
| iOS `refs/heads/main` | `424ab96ede1b92f2b751b54bce04c6e607f0f3c8` | `git ls-remote`; matches the recorded rehearsal split |
| iOS `refs/tags/v0.2.4` | Absent | Exact tag query returned no ref |
| Maven `io.github.sztheory:crosswake-shell-core-android:0.2.4` | HTTP 404 | Exact POM query |

The run's iOS job log ends with `env: ‘mix’: No such file or directory`. The ordinary
`release-please.yml` iOS job invokes `script/release_candidate/ios_mirror.sh`, whose result
projection runs `mix run`; that job does not install the Elixir toolchain. The script failed
before its guarded push path, consistent with the unchanged mirror main and absent version tag.

The Maven job invoked `android_publication.sh` with the exact 0.2.4 merge, approved head, tree,
and receipt digest. That script still compares these values to hard-coded Phase 168 identities
before it checks out the publish directory or invokes Gradle. Its fail-closed identity check
therefore rejected the 0.2.4 transaction before a Central deployment could be started. The public
POM remains absent.

## Proposed work before any recovery write

1. Repair the ordinary iOS job so it installs the repository-pinned Elixir/Mix toolchain before
   running the mirror evaluator. Keep the mirror's exact-ref checks and atomic publish behavior.
2. Separate the Maven ordinary-publish authority from the legacy Phase 168 recovery pin. The
   ordinary job must continue to accept only the candidate identity emitted by the successful
   approved-release guard, and must reject mismatched version, merge, approved head/tree, receipt,
   or source checkout. Keep old recovery authority closed until a reviewed, exact 0.2.4 recovery
   binding exists.
3. Add automated regression coverage for the missing iOS runtime and for accepted/rejected Maven
   identities. Rehearse only non-publishing paths and inspect the resulting evidence before any
   external write is considered.
4. Create a separate recovery plan with exact iOS and Maven operations, source OIDs, receipt
   identity, expected old/new refs, target coordinates, bounded post-write checks, and explicit
   stop conditions. Require a new, separately captured authorization for each external mutation.

## Proof boundary requiring a plan decision

The 0.2.4 ordinary run skipped exact-public proof. A later iOS/Maven recovery run cannot be
reported as proof that those jobs succeeded in run `36035737504`, and recovery alone does not
satisfy the same-run proof contract in Plan 175-21. Before calling REL-14 or Phase 175 complete,
the phase plan must define how the exact-public and linked-rollup requirements are met without
rewriting the historical run. If that contract cannot be met for 0.2.4, preserve its PARTIAL state
and plan a separately versioned ordinary release whose own run can execute the full proof lane.

## Stop conditions

- No retry of run `36035737504`, no rerun of an individual publish job, and no reuse of its Gate 2
  authorization.
- No Hex write: `crosswake@0.2.4` is already present and immutable.
- No iOS or Maven write until the workflow fixes are reviewed, non-publishing checks pass, and a
  separate exact recovery authorization is captured.
- Do not infer Maven Portal state from the public 404 beyond the evidence that this run's script
  rejected its identity before Gradle; keep any independent Portal deployment status unknown unless
  queried through an authorized read-only source.
- Keep the 0.2.3 partial and the historical REL-10 breach unchanged.

## Recommendation

Proceed with a bounded implementation plan for the two proven ordinary-lane defects and the
separate proof-contract decision. Keep Phase 175-21 blocked. Return for a new explicit authorization
only after the repaired paths, recovery plan, exact targets, and automated preflight are reviewable.
