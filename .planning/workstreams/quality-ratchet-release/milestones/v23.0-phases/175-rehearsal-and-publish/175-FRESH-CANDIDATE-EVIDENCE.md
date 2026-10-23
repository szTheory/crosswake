# Phase 175 — Fresh Candidate Gate 2 Evidence

**State:** not merged / not published. This is a new candidate evidence set; it does not reuse the
merged `0.2.2` intent or historic failed workflow `35555386857`.

## Exact candidate identity

| Field | Exact value | Verification |
| --- | --- | --- |
| Candidate PR | [#196](https://github.com/szTheory/crosswake/pull/196) | open, non-draft Release Please PR |
| Proposed version | `0.2.3` | `.release-please-manifest.json` at exact candidate head |
| Base OID | `7a615cb0ddf2a55ef6ffab1c0c841ec3d92dea60` | GitHub PR value equals fetched OID |
| Head OID | `a8d86b29ee5731332ceac9abc176ecdc8262e7e1` | GitHub PR value equals fetched OID |
| Head tree OID | `873210c237fe0bdceca65b90f222dd93b0c8b595` | GitHub commit value equals fetched tree |
| Mergeability | `MERGEABLE` / `CLEAN` | live GitHub PR query |
| Required CI | `Crosswake CI` run [`35801086301`](https://github.com/szTheory/crosswake/actions/runs/35801086301) | `SUCCESS` for this head |
| Historic intent comparison | `0.2.2` / `a71578fc4dcbd7944a34a2410c3845c8224d19f9` | different version and head: PASS |
| Runbook ancestry — base | `d3401e516c5e158accf2b8c5629ce6bcf9bd80f8` | PASS against exact fetched base |
| Runbook ancestry — head | `d3401e516c5e158accf2b8c5629ce6bcf9bd80f8` | PASS against exact fetched head |

The candidate receipt, every rehearsal leg, and every registry-absence query below use **only** the
`0.2.3` / base / head / tree tuple above. No symbolic ref is used as identity authority.

## Boundary statement

No protected merge, package publication, tag push, historic-workflow retry, recovery dispatch,
individual-registry job, or administrator bypass has occurred while recording this evidence.

## Fresh zero-mutation rehearsals and canonical receipt

All entries in this section bind the exact `0.2.3` / `7a615cb0ddf2a55ef6ffab1c0c841ec3d92dea60` /
`a8d86b29ee5731332ceac9abc176ecdc8262e7e1` /
`873210c237fe0bdceca65b90f222dd93b0c8b595` candidate identity above. Historic `0.2.2` material was
not used as authority.

| Leg | Run / immutable artifact | Exact result | Freshness and identity verdict |
| --- | --- | --- | --- |
| Hex rehearsal | Hex rehearsal run [35809831057](https://github.com/szTheory/crosswake/actions/runs/35809831057) | `package_count=6`; `external_state_changed=false` | requested/observed/run head, base, and tree all equal the candidate: PASS |
| iOS rehearsal | iOS rehearsal run [35809832762](https://github.com/szTheory/crosswake/actions/runs/35809832762) | `state=PASS`; `authorization_result=PROVEN`; `external_state_changed=false`; split SHA `424ab96ede1b92f2b751b54bce04c6e607f0f3c8` | requested/observed/run head, base, and tree all equal the candidate: PASS |
| Canonical receipt | receipt workflow [iOS mirror authority run 35810821392](https://github.com/szTheory/crosswake/actions/runs/35810821392), immutable artifact `10729014450` (`phase168-candidate-receipt-a8d86b29ee5731332ceac9abc176ecdc8262e7e1`) | receipt digest `f5e91a9a10ead43306c5a55580bb07e54db199d12c6e0d629d6eb56f2766ca92`; unexpired through `2026-10-07T02:34:03Z` | `READY FOR APPROVAL`, 12/12 `PASS` checks, exact bound=observed base/head/tree/version, `external_state.changed=false`, and `publication=NONE`: PASS |

The attestation workflow itself was a `workflow_dispatch` run from the protected-base source
(`35810821392`); its immutable receipt artifact is the authority and binds the candidate tuple above.
The artifact download was independently revalidated against that tuple and its SHA-256 digest before
the Maven drill. The focused recovery proof (`MIX_ENV=test mix test
test/crosswake/proof/phase175_release_recovery_test.exs --max-cases 1`) passed 5/5, including the
seeded `missing-receipt: FAIL` denial and `matching-receipt: PASS` acceptance paths.

## Isolated Maven fire drill and head stability

Maven head before: `a8d86b29ee5731332ceac9abc176ecdc8262e7e1`
Maven head after: `a8d86b29ee5731332ceac9abc176ecdc8262e7e1`

The one dedicated [Maven fire-drill run 35860341954](https://github.com/szTheory/crosswake/actions/runs/35860341954)
used `fire_drill_version=0.2.3` against the candidate branch. Its isolated Central Portal step reached
`VALIDATED`, recorded deployment `46132a1c-6492-43e0-9973-898c693c78bf`, then completed `DROP` with a
successful workflow conclusion. The byte-for-byte before/after candidate-head equality is PASS.

After DROP, the exact base/head/tree/version were re-fetched and revalidated; the canonical receipt
still matched and the runbook commit `d3401e516c5e158accf2b8c5629ce6bcf9bd80f8` remained an ancestor of
both exact fetched base and head: PASS.

## Fresh registry absence and Gate 2 boundary

At `2026-09-23T14:36:23Z`, independent direct queries found the fresh target coordinates absent:

| Registry | Target | Observation | Verdict |
| --- | --- | --- | --- |
| Hex | `crosswake@0.2.3` | release API HTTP `404` | absent |
| iOS mirror | `refs/tags/v0.2.3` | exact `ls-remote` query returned no ref | absent |
| Maven Central | `io.github.sztheory:crosswake-shell-core-android:0.2.3` POM | HTTP `404` | absent |

The candidate is **not merged** and **not published**. No Hex publish, iOS mirror tag push, or Maven
`PUBLISHED` state occurred. Historic workflow `35555386857` was not retried, no recovery or
individual-registry job was dispatched, and no previous Gate 2 answer was reused. This record ends
before any protected merge or publication decision.
