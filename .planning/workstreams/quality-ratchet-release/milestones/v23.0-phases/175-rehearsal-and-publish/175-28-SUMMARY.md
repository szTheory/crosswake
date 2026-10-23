# Phase 175, Plan 175-28 — Summary

## Outcome

Plan 175-28 is complete. PR #207 now has exact-head CI, all three safe rehearsals, and one independently attested canonical receipt for version 0.2.5. Gate 2 remains pending and unauthorized. Nothing was published or recovered; 0.2.4 remains permanently PARTIAL with Hex only.

## Candidate and CI

The ordinary Release Please workflow completed successfully after test-only PR #208 merged as `d9ac0e39d7bee33d659f4823b7747d3e1f14a6b7`; publication jobs were skipped. Because the existing release proposal remained on its previous base, PR #207 was refreshed through GitHub’s update-branch path. It remains open/non-draft, mergeable, and clean at base `d9ac0e39d7bee33d659f4823b7747d3e1f14a6b7`, head `11c2b03295ddf1c470340bb3ebaf71fd030e41ae`, tree `c5aa596736dec12078804c8d7d8e5a9c72747757`, version 0.2.5.

Candidate CI run `36080344519` passed all 49 leaf checks at that exact head. Strict branch protection requires `Crosswake CI`. Both runbook ancestry checks passed, the repair commits are in the candidate lineage, and independent post-rehearsal checks found Hex and Maven HTTP 404 with no iOS `v0.2.5` tag.

## Safe rehearsals and attestation

Exact candidate-branch rehearsals passed: Hex `36082200994` built six packages; iOS `36082200744` proved mirror authority; Maven `36082200777` reached VALIDATED then DROP. Each recorded no external state change. The Maven run observed the same PR head before and after, and no Release Please proposal mutation followed the drill.

The first rehearsal dispatch set was run from `main`. Its outputs were not used because GitHub run metadata bound them to the base SHA. The attestation rejected that mismatch. Fresh exact-branch rehearsals and attestation corrected the binding without external mutation.

Attestation run `36082522240` produced one unexpired canonical artifact (ID `10842771650`, SHA-256 `c0798491c272a58b5fdbf10a993e003fca4b649b59b4b5ad8aa6fd07086de19e`). The receipt is `READY FOR APPROVAL`, matches the observed candidate, passes all 13 checks, records publication `NONE`, and records no external state change.

## Handoff

The exact normalized evidence is in `175-SUCCESSOR-CANDIDATE.md` and the three `evidence/175-successor-*.json` files. Continue to Plan 175-29 only for a fresh, distinct Gate 2 decision. No prior 0.2.4 authorization or receipt applies to this successor.
