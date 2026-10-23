# Phase 174 Vacuity Taxonomy Addendum

This addendum supplies the taxonomy record omitted from the Phase 174 verification report. It
indexes the phase's existing measured classifications and mutation evidence in
[174-NON-VACUITY.md](174-NON-VACUITY.md). Shape definitions remain single-sourced in
[PITFALLS.md](../../../../research/v23/PITFALLS.md#pitfall-4-vacuous-assertions--absence-scored-as-success--the-taxonomy-and-detection-recipes).

## Vacuity Taxonomy

| Check ID | Shape | Non-vacuity evidence |
|---|---|---|
| `Crosswake.Proof.Phase174CleanRoomHostRealismTest` | A, mitigated | 8 tests, 0 failures; four independent roster/log/path mutations turn red. Full measured evidence is in 174-NON-VACUITY.md. |
| `Crosswake.Proof.Phase174CleanRoomLaneParityTest` | A, mitigated | 6 tests, 0 failures; removing a workflow job breaks the fixed roster comparison, and an empty-roster control is rejected. Full evidence is in 174-NON-VACUITY.md. |
| `Crosswake.Proof.Phase174CompanionFindingsTest` | A, mitigated | 7 tests, 0 failures; removing a finding fails the control, and an empty roster is not reported as satisfied. Full evidence is in 174-NON-VACUITY.md. |
| `Crosswake.Proof.Phase174ManifestContractImmutabilityTest` | matches none of A-F, because it compares bytes against a history-pinned fixed baseline and asserts non-empty extraction before comparison. | Five tests exercise the real script; byte drift, renamed function, deleted call, empty source, and reformatted call produce distinct failures. Full evidence is in 174-NON-VACUITY.md. |
| `Mix.Tasks.Crosswake.ProofLane.PhysicalIphoneTest` | matches none of A-F, because it proves exhaustiveness of an explicit classifier with a catch-all over a closed rule vocabulary. | The five classifier tests were red against the prior incomplete report-join implementation and green after the completeness fix. Full evidence is in 174-NON-VACUITY.md. |
| `manifest_contract.byte_identity` | A, mitigated | The script asserts non-empty, exact-count extraction before byte comparison; the measured live check exits 0 with `MANIFEST_CONTRACT_UNCHANGED_VERIFIED`. Full evidence is in 174-NON-VACUITY.md. |
| `phase174_cleanroom_lane_parity_test.exs` captured-log marker parity | A, mitigated | Both marker sets must be non-empty. Truncated logs and a renamed doctor marker each make the tests fail. Full evidence is in 174-NON-VACUITY.md. |
| `Crosswake.Proof.Phase174MatrixInstallOrderTest` | A, mitigated | Nine tests reject missing, duplicated, empty, unexpected, and misordered install/doctor events; six independent controls were measured red. Full evidence is in 174-NON-VACUITY.md. |
