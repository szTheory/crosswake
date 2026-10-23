# Phase 175 — Successor Gate 2: 0.2.5

## Decision requested

Authorize one protected merge of successor PR [#207](https://github.com/szTheory/crosswake/pull/207) and its ordinary Release Please run for **0.2.5**.

The exact candidate is open and non-draft, mergeable and clean:

- Base: `d9ac0e39d7bee33d659f4823b7747d3e1f14a6b7`
- Head: `11c2b03295ddf1c470340bb3ebaf71fd030e41ae`
- Tree: `c5aa596736dec12078804c8d7d8e5a9c72747757`
- Required-check policy: strict; `Crosswake CI`
- Exact-head CI: run `36080344519`, success, 49 checks
- Runbook ancestry: `d3401e516c5e158accf2b8c5629ce6bcf9bd80f8` passes on base and head

The exact candidate rehearsals passed: Hex `36082200994` (six packages), iOS `36082200744` (`PASS` / `PROVEN`, split `424ab96ede1b92f2b751b54bce04c6e607f0f3c8`), and Maven `36082200777` (`VALIDATED` then `DROP`, with the PR head unchanged). Receipt attestation `36082522240` produced one unexpired `READY FOR APPROVAL` artifact, ID `10842771650`, digest `c0798491c272a58b5fdbf10a993e003fca4b649b59b4b5ad8aa6fd07086de19e`, with all 13 checks passing, publication `NONE`, and no external mutation.

Independent registry checks still show Hex `0.2.5` HTTP 404, iOS tag `v0.2.5` absent, and the Maven `0.2.5` POM HTTP 404. Central Portal’s public state is not independently observed outside the trusted rehearsal.

## Irreversibility costs

- **Hex:** A published package version cannot be removed or replaced. Retirement is an advisory; the version remains resolvable.
- **iOS mirror:** A later tag correction changes what new SwiftPM resolutions receive. Consumers who already resolved an old commit retain it until they explicitly re-resolve.
- **Maven Central:** A coordinate is permanent once reported `PUBLISHED`; it cannot be deleted, retired, or overwritten.

The earlier **0.2.4** authorization was consumed and its outcome remains permanently **PARTIAL**: Hex only. That authorization and receipt do not apply to this successor.

**Gate 2 state: `CONSUMED`; outcome `PARTIAL`.** The exact response was received:

`publish successor core 36082200744`

The authorization was consumed by the single protected merge `405acd0f2d5476dc81f1ad1252a1661fa235c735`. Sole ordinary Release Please run `36083361945` ended PARTIAL: Hex and iOS published, Maven failed before publish, iOS clean-room failed, and Android/exact-public proof were skipped. The exact Hex and iOS registry entries are present; the Maven POM returns HTTP 404. No retry or recovery was performed or authorized by this decision.

Machine record: `evidence/175-successor-gate-2.json`.
