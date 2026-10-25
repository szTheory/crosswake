# Phase 175 — Successor Candidate 0.2.5

**Disposition:** `READY FOR APPROVAL`. This record captures reversible evidence only. Gate 2 remains `PENDING`, `authorized=false`, and was not presented.

## Exact candidate

- PR [#207](https://github.com/szTheory/crosswake/pull/207), open and non-draft; base `d9ac0e39d7bee33d659f4823b7747d3e1f14a6b7`, head `11c2b03295ddf1c470340bb3ebaf71fd030e41ae`, tree `c5aa596736dec12078804c8d7d8e5a9c72747757`.
- Proposed version: `0.2.5`. The PR is `MERGEABLE` / `CLEAN` and not behind.
- The 175-26 iOS runtime repair, 175-27 Maven receipt repair, and permanent 0.2.4 parity disposition are in the candidate lineage.
- Exact-head Crosswake CI run `36080344519` passed all 49 leaf checks. The required branch policy is strict and requires `Crosswake CI`.
- Runbook commit `d3401e516c5e158accf2b8c5629ce6bcf9bd80f8` is an ancestor of both candidate base and head.
- Independent coordinate observations: Hex `0.2.5` HTTP 404; iOS `v0.2.5` tag absent; Maven POM HTTP 404. Central Portal public state is not independently observed outside the trusted drill.

## Rehearsals and receipt

- Hex run `36082200994` passed the exact six-package build with no external mutation.
- iOS run `36082200744` proved the atomic mirror operation for split `424ab96ede1b92f2b751b54bce04c6e607f0f3c8`; mirror `main` already equals that split, candidate tag is absent, and no external mutation occurred.
- Maven run `36082200777` reached `VALIDATED`, then `DROP`; its run-unique disposable coordinate was dropped and the PR head remained unchanged.
- Attestation run `36082522240` uploaded one unexpired artifact (`10842771650`, expires 2026-10-09T01:34:46Z). The canonical receipt is `READY FOR APPROVAL`, exact-bound, 13/13 checks pass, publication is `NONE`, and external state is unchanged. Receipt SHA-256: `c0798491c272a58b5fdbf10a993e003fca4b649b59b4b5ad8aa6fd07086de19e`.
- An initial attestation attempt was correctly rejected because its rehearsal workflows ran from `main`, so GitHub run metadata identified the base. Those attempts produced no mutation and are excluded; all evidence above comes from fresh runs dispatched on PR #207’s exact branch.

## Gate status

Gate 2 remains unpresented and unauthorized. No Hex publication, iOS tag push, Maven publication, or recovery occurred. The 0.2.4 disposition remains permanently `PARTIAL` with Hex only; its authorization is consumed.

Machine evidence: `evidence/175-successor-candidate.json`, `evidence/175-successor-rehearsals.json`, and `evidence/175-successor-receipt.json`.
