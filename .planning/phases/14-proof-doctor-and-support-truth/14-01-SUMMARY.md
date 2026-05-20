# Phase 14-01: Proof Doctor and Support Truth

## Execution Summary

Successfully extended the doctor outputs to include capability-family, package-boundary, and commerce-seam prerequisites and denials.
- Updated `lib/crosswake/doctor/doctor.ex` to pass struct data (capability_families, package_surfaces, release_boundaries, change_classes) through `release_policy_snapshot/1` directly instead of flattening to strings.
- Added comprehensive formatting blocks in `lib/crosswake/doctor/formatter.ex` to format these structs in the CLI text output (including prerequisites, denial, fallback, why, burden, versioning, rule).
- Derived `Jason.Encoder` on the struct types in `lib/crosswake/manifest/types.ex` to ensure doctor JSON outputs work correctly.
- Created `test/crosswake/doctor/formatter_test.exs` to verify the text rendering.
- Updated `test/crosswake/manifest/manifest_test.exs` to expect `core` package_class for commerce seams, aligning with truth.

## Result
Doctor explicitly renders package surfaces, capability families, and release boundaries including commerce seams.
