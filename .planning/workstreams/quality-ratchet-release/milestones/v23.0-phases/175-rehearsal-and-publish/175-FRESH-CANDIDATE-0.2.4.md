# Phase 175 — Fresh 0.2.4 Candidate and Trusted Receipt

**Observed:** `2026-09-24T16:53:14Z`
**Disposition:** `READY FOR APPROVAL`; this plan records evidence only. Gate 2 remains pending and no decision was presented.

## Candidate identity

- PR #201 is `OPEN`, non-draft, `MERGEABLE` / `CLEAN`, and proposes `0.2.4`.
- Base: `e298793a40538500003602edb6b1d7ea2221ee84` (`main`). Head: `dfe7c0b4be909130f2474ed7d4e97e8e52d49498`. Tree: `215493f06e4119faa25a692db7f2e8de47d39b3c`. The release branch resolves to the exact candidate head.
- The candidate directly descends from producer fix merge `e298793a40538500003602edb6b1d7ea2221ee84`. Release Please refresh run `36025966414` completed at `2026-09-24T16:17:51Z`.
- Strict branch protection requires only `Crosswake CI`. Exact runbook ancestry passed for both base and head against `d3401e516c5e158accf2b8c5629ce6bcf9bd80f8`.

## Fresh CI and registry absence

- Candidate CI run `36026349375` passed all 49 checks at the exact head. Its receipt binds six packages, five profiles, two installs per profile, and no external state change. CI receipt SHA-256: `9ca6d128c84773a9938ecf209d92fd836e241d46aa2bcf7e72f0e989597970c3`.
- Hex `crosswake@0.2.4` returned HTTP 404; iOS `refs/tags/v0.2.4` has no matching ref; Maven `io.github.sztheory:crosswake-shell-core-android:0.2.4` returned HTTP 404.

## Fresh rehearsals

- **Hex** run `36029591408` passed with six packages, exact base/head/tree and candidate-receipt binding, and `external_state_changed=false`. Manifest SHA-256: `391eb66ee374f7eeed78a658b3393f0ca7a8a85f817248de9826c22b6243c2e0`.
- **iOS** run `36029609207` passed with authorization `PROVEN`, atomic dry-run `PASS`, exact candidate identity, no tag, and no external change. Mirror split and remote main are `424ab96ede1b92f2b751b54bce04c6e607f0f3c8`.
- **Maven** run `36029497304` reached `VALIDATED`, then `DROP`, for disposable coordinate `io.github.sztheory:crosswake-shell-core-android:0.2.4-firedrill-36029497304`. Candidate branch head was `dfe7c0b4be909130f2474ed7d4e97e8e52d49498` immediately before and after.

## Canonical receipt attestation

Trusted attestation run `36030036687` succeeded at the exact candidate head and uploaded exactly one unexpired `phase168-candidate-receipt-dfe7c0b4be909130f2474ed7d4e97e8e52d49498` artifact (ID `10821206063`), expiring `2026-10-08T16:51:30Z`. Independently downloaded receipt SHA-256: `aad9a9f23a291763353b4e087d7f9e332884bd68ee24cfabfe325c527a9947ee`. The receipt is `READY FOR APPROVAL`, binds the exact candidate and all four run IDs, has all 13 checks `PASS`, mirror authority `PROVEN`, publication `NONE`, and `external_state.changed=false`. Its schema validation passed locally against the candidate source.

The local replay and this artifact inspection are validation evidence. The canonical authority is the workflow artifact identified above. The plan did not present or consume a Gate 2 decision.
