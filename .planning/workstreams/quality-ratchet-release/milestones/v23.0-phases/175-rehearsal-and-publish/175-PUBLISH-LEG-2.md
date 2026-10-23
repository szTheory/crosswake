# Phase 175 — Core Publish Leg 2

## Gate and pre-merge identity

- Gate 2 answer, verbatim: `publish core 35554774599` at `2026-09-21T02:48:27Z`.
- Rehearsal head: `a71578fc4dcbd7944a34a2410c3845c8224d19f9`.
- Immediately pre-merge live PR #164 head: `a71578fc4dcbd7944a34a2410c3845c8224d19f9`.
- Head comparison: **equal**.
- Live base: `52345b48bb32e25b3ec9390e81612bacc8688f5d`.
- The exact fetched base and head each passed
  `script/check_release_runbook_ancestry.sh` with recorded runbook commit
  `d3401e516c5e158accf2b8c5629ce6bcf9bd80f8`.

Merge commit SHA: a0bdf83f5950a68578b6618d96bdf3c4b7bc76ba

The exact GitHub merge object also passed the runbook-ancestry check.

## Publish graph result — guard failure before publication

Release Please run: `35555386857` (push, completed `failure`).

| Watched job | Conclusion | Observation |
|---|---|---|
| `release: approved-candidate merge guard` | `failure` | Required `phase168-candidate-receipt-a71578fc4dcbd7944a34a2410c3845c8224d19f9` was absent. The workflow therefore failed closed before release or registry jobs. |
| `Publish to Hex.pm` | `skipped` | No Hex publish was attempted. |
| `Mirror iOS core to split repo` | `skipped` | No mirror publication was attempted. |
| `Publish Android core to Maven Central` | `skipped` | No Maven publication was attempted. |

Path taken: **neither ordinary publish nor recovery**. The ordinary path was blocked by the
approval-receipt guard before it could begin; no recovery path was dispatched.

The post-merge workflow guard requires a separately-attested canonical Phase 168 receipt. The
available inputs were the CI receipt plus successful Hex and iOS rehearsal artifacts, but the
canonical attestation was not produced before the candidate merged. That attestation requires
`origin/main` to equal the candidate base; after the merge, it cannot attest the already-merged
candidate under its original base identity. This is a release-gating defect, not a registry partial
failure.

## Independent post-guard registry checks

Observed after the failed run at `2026-09-21T02:57:32Z`:

- Hex `crosswake 0.2.2`: HTTP `404`.
- iOS mirror `refs/tags/v0.2.2`: absent.
- Maven Central core POM `0.2.2`: HTTP `404`.

No three-registry door opened. The rehearsed iOS split SHA
`424ab96ede1b92f2b751b54bce04c6e607f0f3c8` was not published as `v0.2.2`; tag-versus-split-SHA is
therefore **not applicable**, not equal.

## Required next action

Do not retry the failed push workflow or any individual registry job. A recovery design must first
re-establish an exact candidate/attestation boundary for the already-merged `0.2.2` release intent,
or deliberately create and authorize a new versioned candidate. Either route needs a new explicit
one-way-door gate.
