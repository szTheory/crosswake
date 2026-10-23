# Phase 175 — Fresh Gate 2 Evidence

**Candidate:** PR #196, `0.2.3` — open, mergeable, and clean. This is a new candidate-specific
record. It does not reuse the historic `0.2.2` approval or failed preparation.

## Exact identity and runbook bar

| Field | Value | Result |
| --- | --- | --- |
| Base OID | `7a615cb0ddf2a55ef6ffab1c0c841ec3d92dea60` | fetched and matched |
| Head OID | `a8d86b29ee5731332ceac9abc176ecdc8262e7e1` | fetched and matched |
| Head tree OID | `873210c237fe0bdceca65b90f222dd93b0c8b595` | fetched and matched |
| Runbook commit | `d3401e516c5e158accf2b8c5629ce6bcf9bd80f8` | PASS against exact base and head |

REL-10 remains **BREACHED** at historic Gate 1: the published first companion's remote base,
head, and merge did not contain the runbook commit. The fresh base and head passing the runbook
check do not retroactively repair that incident.

## Fresh zero-mutation rehearsals

| Leg | Immutable run | Required result | Candidate binding |
| --- | --- | --- | --- |
| Hex | `35809831057` — Hex candidate rehearsal and recovery | `package_count=6`; `external_state_changed=false` | exact base/head/tree: PASS |
| iOS | `35809832762` — iOS mirror authority | `state=PASS`; `authorization_result=PROVEN`; `external_state_changed=false` | exact base/head/tree: PASS; split `424ab96ede1b92f2b751b54bce04c6e607f0f3c8` |
| Maven | `35860341954` — Maven publish fire-drill | `VALIDATED`, deployment `46132a1c-6492-43e0-9973-898c693c78bf`, then `DROP` | head before and after both `a8d86b29ee5731332ceac9abc176ecdc8262e7e1` |

## Canonical receipt boundary

The canonical receipt is artifact `10729014450` from iOS mirror authority run `35810821392`:
`phase168-candidate-receipt-a8d86b29ee5731332ceac9abc176ecdc8262e7e1`, SHA-256
`ef151fcf8a2a8b1b189328cea23d11548e71c82732f671acf1396c93ecb502e4`.

Its state is `READY FOR APPROVAL`, all 12 checks pass, and its bound and observed
base/head/tree/version equal this candidate. It records no external state change and
`publication=NONE`. The focused recovery proof recorded the seeded missing-receipt failure and
fresh matching-receipt pass; the receipt boundary therefore remains fail closed.

## Current registry absence

At `2026-09-23T16:37:51Z`, independent direct queries immediately before this gate found:

| Registry | Coordinate/ref | Observation |
| --- | --- | --- |
| Hex | `crosswake@0.2.3` | HTTP `404` — absent |
| iOS mirror | `refs/tags/v0.2.3` | no matching ref — absent |
| Maven Central | `io.github.sztheory:crosswake-shell-core-android:0.2.3` POM | HTTP `404` — absent |

## Historic guard and decision boundary

Historic failed run `35555386857` was not retried. No individual registry job was dispatched, no
receipt for historic `0.2.2` was reconstructed, and no bypass was used. No protected merge,
publication, tag operation, retirement, or remote mutation occurred while refreshing this record.

This is the only phase leg that would open three one-way doors together. The recovery terms are
unchanged: [Hex retirement does not remove a published version](../../../../../docs/RELEASE-INCIDENT-RESPONSE.md#irreversibility-summary); an [iOS tag re-point cannot change already-resolved consumers](../../../../../docs/RELEASE-INCIDENT-RESPONSE.md#irreversibility-summary); and [Maven is droppable only before publication, not after `PUBLISHED`](../../../../../docs/RELEASE-INCIDENT-RESPONSE.md#irreversibility-summary). See also [mid-sequence partial failure](../../../../../docs/RELEASE-INCIDENT-RESPONSE.md#mid-sequence-partial-failure) and [retire / backfill after a bad publish](../../../../../docs/RELEASE-INCIDENT-RESPONSE.md#retire--backfill-after-a-bad-publish).

## Required maintainer decision

No merge or remote mutation is authorized by this evidence. To authorize only this exact candidate,
the maintainer must type:

```text
publish fresh core 35809832762
```

`publish core 35554774599`, the Gate 1 Hex token, the Gate 3 proof token, generic approval, and
`--no-reversibility-gates` are rejected. `stop` declines the gate without mutation.

## Gate 2 decision

Gate 2 decision: authorized

- Typed token: `publish fresh core 35809832762`
- Recorded at: `2026-09-23T17:10:36Z`
- Binding: fresh iOS rehearsal run `35809832762` for PR #196 / `0.2.3` only.

This records authorization for Plan 175-14's ordinary publish graph. This plan did not merge,
publish, tag, retire, dispatch, retry, or otherwise mutate remote state.
