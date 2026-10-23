# Phase 175, Plan 175-29 — Summary

## Outcome

Plan 175-29 consumed the exact authorization `publish successor core 36082200744` in one protected PR #207 merge and observed the one ordinary Release Please run `36083361945`. The run is **PARTIAL**. Hex and iOS published; Maven did not. iOS and exact-public proof requirements remain incomplete. No retry or recovery was performed.

## Exact run result

Merge OID: `405acd0f2d5476dc81f1ad1252a1661fa235c735`.

- Hex publish succeeded; Hex 0.2.5 is present.
- iOS mirror publish succeeded; `v0.2.5` and `main` point to `424ab96ede1b92f2b751b54bce04c6e607f0f3c8`, matching rehearsal.
- Maven failed in receipt validation. The attestation artifact has three files, including `candidate-receipt.md`; the Maven consumer requires exactly two. Java setup and Maven publish were skipped. The Maven POM independently returns HTTP 404.
- iOS clean-room proof failed during shell generation because `Jason.encode_to_iodata!/2` was unavailable at archive runtime.
- Android clean-room and exact-public proof were skipped. Native and linked release rollups both recorded PARTIAL.

The independent registry checks and normalized run/job states are in `175-SUCCESSOR-CORE-RUN.md` and its two evidence JSON files. Only the expected Release Please run is associated with the merge OID; the unrelated collateral workflow run is not a release run.

## Stop condition

Gate 2 is consumed. The 0.2.5 result is PARTIAL; no recovery is authorized by this token. A future attempt requires a distinct repair plan, fresh exact evidence, and a new explicit authorization. The historic 0.2.4 outcome remains PARTIAL with Hex only.
