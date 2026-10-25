---
phase: 175-rehearsal-and-publish
plan: 07
subsystem: release-pipeline
tags: [publish, hex, incident-closeout, remote-ancestry]

requires:
  - phase: 175-06
    provides: "three successful rehearsal legs and the candidate evidence record"
provides:
  - "A factual closeout of the first companion publish, including independent publish and registry evidence"
  - "The permanent REL-10 breach record and the exact-OID guard results that protect every remaining one-way gate"
affects: [175-08, 175-10]

requirements-completed: [REL-12]
requirements-breached: [REL-10]

actuals:
  tasks: 3
  commits: 0
  closeout: manual-reconciliation
completed: 2026-09-20
status: complete_with_historical_incident
---

# Phase 175 Plan 07: Gate 1 Incident Closeout

`crosswake_rulestead 0.1.1` was published successfully, but Gate 1 did not satisfy REL-10: the required runbook commit was absent from the exact remote base, head, and merge graph used for the publish. This closeout records that breach without rewriting history, while proving the repaired exact-OID guard passes for the remaining gates.

## Historical publish evidence

- PR #147 merged as `096371e3008d19da775c0d561d092fb3d349b26e`.
- Release Please run [35461665164](https://github.com/szTheory/crosswake/actions/runs/35461665164) concluded `success` on that exact merge.
- Its `Publish crosswake_rulestead to Hex.pm` job concluded `success`; its `Clean-room proof — crosswake_rulestead resolvability + doctor` job also concluded `success`.
- Hex.pm was queried directly on 2026-09-20. Its release list contains `0.1.1` and `0.1.0`; `latest_stable_version` is `0.1.1`. This establishes the REL-12 registry fact independently of workflow-definition inspection.

The originally typed Gate 1 checkpoint response was not preserved as a standalone artifact. It is therefore not reconstructed or claimed here. The already-executed publish is recorded from independent GitHub run and Hex registry evidence only.

## REL-10 incident record

The historical remote audit is non-passing and immutable:

- PR #147 base `4627170fffb6688dcb2750c07fae3a18c6d0ee19`: runbook ancestor **no**.
- PR #147 head `491c7a74e2128f7e77c411d50aa22276626c6f51`: runbook ancestor **no**.
- PR #147 merge `096371e3008d19da775c0d561d092fb3d349b26e`: runbook ancestor **no**.

The required runbook commit is `d3401e516c5e158accf2b8c5629ce6bcf9bd80f8`. It and `docs/RELEASE-INCIDENT-RESPONSE.md` were absent from each historical publish object. Gate 1 and REL-10 are historically noncompliant; no later landing repairs that fact.

## Remaining-gate protection

After PR #192's protected merge, the repaired guard was run against freshly fetched live PR #164 identities:

- Base `392a6b21a2282fc9e4dd05c265588ac73767f547`: `release-runbook-ancestry status=pass`.
- Head `fc6d28dcf176fd68f48b5e858c790fad3e78f526`: `release-runbook-ancestry status=pass`.

PR #164's fresh Crosswake CI run [35512555806](https://github.com/szTheory/crosswake/actions/runs/35512555806) completed successfully. This is eligibility evidence for presenting Gate 2 only; it is not authorization to merge or publish.

## Disposition

REL-12 is complete: the selected lower-observed-blast-radius companion is live on Hex and the clean-room lane ran successfully. REL-10 remains breached for the first publish. Gates 2 and 3 must fetch and match their then-live remote base/head OIDs, pass `script/check_release_runbook_ancestry.sh` for both, and receive their separate human authorization immediately before any merge.
