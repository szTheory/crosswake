# Phase 175 — Successor Core Run: 0.2.5

## Outcome: PARTIAL

The exact Gate 2 authorization `publish successor core 36082200744` was consumed by the single protected merge of PR #207 at `405acd0f2d5476dc81f1ad1252a1661fa235c735`. The sole ordinary Release Please run for that merge was `36083361945` and concluded failure. No retry or recovery was performed or authorized by this token.

| Child | Conclusion | Observation |
|---|---|---|
| Hex publish | success | Hex reports `crosswake` 0.2.5 present. |
| iOS mirror | success | `v0.2.5` and `main` both point to rehearsed split `424ab96ede1b92f2b751b54bce04c6e607f0f3c8`. |
| Maven publish | failure | Receipt consumer rejected the artifact roster because `candidate-receipt.md` was an extra file. Failure occurred before Java setup and the Maven publish step was skipped. |
| iOS clean-room proof | failure | Shell generation raised `UndefinedFunctionError`: `Jason.encode_to_iodata!/2` is unavailable at archive runtime. |
| Android clean-room proof | skipped | Maven publication did not succeed. |
| Exact-public proof | skipped | Run did not satisfy proof prerequisites. |
| Native and linked rollups | failure | Both recorded PARTIAL. Linked child states preserve Hex/iOS mirror success, Android failure, iOS proof failure, and remaining proof skips. |

Independent registry observations confirm Hex 0.2.5 present, iOS `v0.2.5` present at the expected split, and Maven POM absent (HTTP 404). Central Portal state was not independently observed. Exactly one Release Please run is associated with the merge OID; a separate collateral workflow run is not a publication run.

**Stop state:** PARTIAL. The Gate 2 token is consumed. Do not retry or recover under it. A future attempt requires a separate repair plan, fresh evidence, and new authorization.

Machine records: `evidence/175-successor-core-run.json`, `evidence/175-successor-core-registry.json`, and updated `evidence/175-successor-gate-2.json`.
