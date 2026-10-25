# Phase 175, Plan 175-25 — Summary

## Outcome

Plan 175-25 is complete. The refreshed 0.2.4 candidate contains the trusted receipt producer fix, passed exact-head CI and three fresh rehearsals, and received one independently validated canonical receipt artifact. Gate 2 remains `PENDING`, `authorized=false`, `authorization=null`, and was not presented.

## Producer correction

Trusted attestation `36022424895` exposed that the CI artifact download included `ci/cleanroom.json`, while the producer's exact evidence roster allowed only seven files. PR #204 added that eighth file to the exact roster and compared its SHA-256 to the CI receipt's `cleanroom_result_sha256`. Missing or mismatched cleanroom evidence fails closed. The fix passed 49/49 hosted checks on run `36023734843` and squash-merged at `e298793a40538500003602edb6b1d7ea2221ee84`.

A first PR #204 CI run stopped at the formatting gate; the fixture was formatted and pushed before a fresh run. The subsequent run passed. The initial Hex/iOS rehearsal dispatches also stopped at their input guards because the entered CI receipt digest omitted its final character; no checkout or rehearsal action ran in those attempts. Corrected exact-digest dispatches passed.

## Exact evidence

- Release Please refresh run: `36025966414`.
- Candidate PR #201, version `0.2.4`, base `e298793a40538500003602edb6b1d7ea2221ee84`, head `dfe7c0b4be909130f2474ed7d4e97e8e52d49498`, tree `215493f06e4119faa25a692db7f2e8de47d39b3c`.
- Candidate CI run `36026349375` passed all 49 checks; exact candidate receipt SHA-256 `9ca6d128c84773a9938ecf209d92fd836e241d46aa2bcf7e72f0e989597970c3`.
- Hex `36029591408`, iOS `36029609207`, and Maven `36029497304` passed with exact identity and no external change; Maven was `VALIDATED` then `DROP`, and the branch head was unchanged.
- Runbook ancestry passed for base and head; Hex/Maven returned 404 and iOS tag `v0.2.4` was absent.
- Trusted attestation `36030036687` uploaded exactly one unexpired artifact `phase168-candidate-receipt-dfe7c0b4be909130f2474ed7d4e97e8e52d49498` (ID `10821206063`, SHA-256 `aad9a9f23a291763353b4e087d7f9e332884bd68ee24cfabfe325c527a9947ee`, expires `2026-10-08T16:51:30Z`). Its receipt is `READY FOR APPROVAL`, exact-bound, 13/13 checks passing, and records publication `NONE` with no external state change.
- Local replay of the exact eight evidence files and local receipt schema validation both passed.

## Handoff

The machine records `175-fresh-candidate-0.2.4.json` and `175-fresh-gate-2-0.2.4.json` are refreshed. Gate 2 remains pending/null-authorized. Plan 175-20 may display its decision only after its own machine precheck. This plan did not merge PR #201, publish, recover, or authorize a release.
