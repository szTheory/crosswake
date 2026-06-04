# Plan 03 Summary

- Updated `lib/crosswake/doctor/doctor.ex` with `phase_66_generator_drift_findings/3`.
- Added a zero-dependency check for unreplaced `ADOPT:` placeholders in generated iOS and Android template files.
- Added a capability-permission drift check that emits `:error` if a declared capability is missing its required permission/entitlement string in the native files.
