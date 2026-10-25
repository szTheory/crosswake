# Plan 175-38 — Exact Successor Gate 2

**Decision state: CONSUMED; the single attempt ended PARTIAL.** The user supplied the exact candidate token at
`2026-09-27T21:22:43Z`; it authorized one normal protected merge and one ordinary Release Please run only.

## Candidate under review

| Field | Live value |
|---|---|
| Pull request | [#215](https://github.com/szTheory/crosswake/pull/215) |
| Version | `0.2.6` |
| Base | `b5608a3dc0b013d83ac2b25768f1907873739b20` |
| Head | `0968fea84dc758c05b9b0161db2f221c9e778c3b` |
| Tree | `0199c0bee29dbcf76bc1a12d241c0ed140a244bd` |
| Merge OID | `998742856a37a97ae7247f6c532f9c154ea20885` |
| Current state | Merged through the normal protected path, with exact base/head parents and identical tree |

The live exact-head Crosswake CI run is `36346477576` (`SUCCESS`). The protected required context
is `Crosswake CI`; live required-check policy is strict, has no bypass actors, and matches policy
SHA-256 `0f851ff07172993c88ff6f293273d138e911e01f0d51765904acd8865f998fa4`. The live commit check
view had 67 completed records: 53 successful, 14 skipped, zero failed, and zero pending. The
required context itself is successful on this exact head.

## Rehearsal and receipt evidence

| Leg | Exact-head run | Outcome | Artifact | Current target |
|---|---:|---|---|---|
| Hex | `36348273088` | PASS; six package artifacts; no external state change | `10940919612`, live through 2026-10-11 | `crosswake 0.2.6` absent (HTTP 404) |
| iOS mirror | `36348273033` | PASS / PROVEN; atomic push supported; no external state change | `10941566545`, live through 2026-10-11 | `v0.2.6` tag absent; rehearsed split and `main` were `424ab96ede1b92f2b751b54bce04c6e607f0f3c8` |
| Maven | `36348273114` | VALIDATED then DROP; no external state change | `10940879675`, live through 2026-10-11 | Android core POM absent (HTTP 404) |

All three run records, artifacts, and candidate identities were re-fetched. Their shared rehearsal
correlation digest is `e8523fde68919b4d4c79bb7fdce999665e5c7855e420246660d218ea609d972a`.

The canonical candidate receipt is READY FOR APPROVAL with all 13 checks passing and publication
`NONE`. It is bound to exact-head CI and these rehearsals. Attestation run `36348696331` retains
artifact `10941079991` through 2026-10-11; the exact raw receipt SHA-256 is
`c51181d384661e77cf68935a6496b4c4bdf9e147854889027f64312dd5d6e9ba`.

The fresh live REL-17 pre-merge capture passed at `2026-09-27T21:35:43Z` for
`(linked_release, 36348273088)` and the same receipt digest and candidate OIDs. Required checks,
pagination, receipt artifact, response-table row, exact Hex response, and runbook ancestry on both
base and head passed. The three rehearsal run job summaries and artifact IDs were rechecked at this
boundary. Exact-head CI remained successful, the PR stayed `MERGEABLE`, and all four evidence
artifacts remained unexpired. Runbook commit:
`d3401e516c5e158accf2b8c5629ce6bcf9bd80f8`. Exact target responses and the complete live capture
are retained in `evidence/175-next-successor-premerge-sources/`.

Direct target rechecks at `2026-09-27T21:37:01Z` found Hex HTTP 404, no iOS `refs/tags/v0.2.6`, and
Maven POM HTTP 404. After the single merge, direct checks again found Hex HTTP 404, no iOS
`refs/tags/v0.2.6`, and Maven POM HTTP 404.


## Attempt outcome — PARTIAL

- PR #215 merged at `2026-09-27T21:42:47Z` as `998742856a37a97ae7247f6c532f9c154ea20885`. Parents are the exact authorized base and candidate head; the merge tree matches the candidate tree. No admin bypass was used.
- Post-merge REL-17 capture passed at `2026-09-27T21:45:47Z`, including exact merge identity and runbook ancestry at base, head, and merge.
- The one ordinary Release Please run, [36352732061](https://github.com/szTheory/crosswake/actions/runs/36352732061), failed in `release: approved-candidate merge guard` at “Require approved head parentage, identical tree, and exact receipt.” The job log ended with exit code 1 after all three runbook ancestry checks passed; it emitted no specific REL-17 reason.
- Release Please, Hex core, iOS mirror, Maven, and exact-public jobs were skipped. The linked rollup artifact is `NOT_APPLICABLE`; its job success does not prove publication. No publisher ran.
- Post-run registry checks still show all three 0.2.6 coordinates absent. The automatic alert opened [issue #217](https://github.com/szTheory/crosswake/issues/217).
- Gate 2 is consumed and recorded as `PARTIAL`. No retry or recovery was performed or authorized. Plan 175-39’s precondition is false; diagnose the guard before planning any fresh candidate gate.

## Publication costs

These are three different one-way costs, as documented in the matching registry rows of
[`RELEASE-INCIDENT-RESPONSE.md`](../../../../../docs/RELEASE-INCIDENT-RESPONSE.md):

- **Hex:** a published version cannot be removed or replaced. `mix hex.retire` adds a forward-only
  advisory; existing lockfiles still resolve the version.
- **iOS SwiftPM mirror:** the tag and `main` can be corrected for new resolutions, but consumers
  that already resolved a commit keep it in their resolved-package cache until they re-resolve.
- **Maven Central:** once the coordinate reaches `PUBLISHED`, it cannot be deleted, retired, or
  overwritten. A later version can supersede it in practice.

## Gate 2 decision

The authorization was marked **CONSUMED** at `2026-09-27T21:39:47Z`. Its one normal protected
merge completed, but the guarded ordinary run failed before any publisher. The exact approved trailer
authorized no retry or recovery:

```text
publish successor core 36348273033
```

That decision is separate from the earlier authorization to merge repair PR #216. It permits no
retry or recovery if the ordinary run is partial. The machine-readable, exact-key authorization
envelope and its single-line merge trailer are retained in `evidence/175-next-successor-gate-2.json`.
