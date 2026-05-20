# Phase 14-02: Advisory Capability Checks

## Execution Summary

Successfully generated and formatted distinct capability checks based on `proof_class`.

- Updated `lib/crosswake/doctor/doctor.ex` to generate abstract proof checks for capabilities in `support_matrix.capability_families`.
- Added `capability_posture_findings/1` which emits a `merge_blocking` check (with `:error` severity if the main support status is not yet `:supported`) and an `:advisory` check for environment-sensitive proofs.
- Ensured that `advisory` capability requirements do not break standard CI pipelines, by emitting them with severity `:advisory`.
- `mix test test/crosswake/doctor/doctor_test.exs` continues to pass, validating that CI pipelines successfully separate merge-blocking requirements from advisory warnings.
- Formatting for the new checks correctly exposes the distinction between standard failure and abstract/environmental proofs.

## Result

Maintainers can distinguish merge-blocking capability proof from advisory proof before widening public support claims.
