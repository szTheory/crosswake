# Phase 3 Plan 03-06 Summary

## Outcome

Plan `03-06` now wires Phase 3 shell, bridge, route-unavailable, pack/compatibility,
and proof-hook posture into `mix crosswake.doctor` and the public install/support
guides.

## What Changed

- `lib/crosswake/doctor/doctor.ex`
  - Added Phase 3 shell posture inspection for generated iOS and Android artifacts.
  - Added bounded bridge posture reporting from canonical contract truth.
  - Added blocking proof-hook posture and overall support-posture findings.
- `lib/crosswake/doctor/formatter.ex`
  - Added structured human-readable shell, bridge, and support summaries ahead of findings.
- `lib/crosswake/doctor/json_formatter.ex`
  - Added top-level `support`, `shells`, and `bridge` payloads for downstream tooling.
- `guides/install.md`
  - Reframed install flow around `mix crosswake.doctor` and `--native-checks`.
- `guides/compatibility.md`
  - Documented Phase 3 fail-closed activation, route-unavailable, and bridge denial posture.
- `guides/support_matrix.md`
  - Published the current proof-oriented shell support boundary as `verification required`
    until both generated-project proof hooks pass.
- `guides/native_shell.md`
  - Added the host-owned native shell guide covering manifest-first activation,
    route-unavailable surfaces, App-Bound Domains, and required proof hooks.
- `test/crosswake/doctor/doctor_test.exs`
  - Added doctor coverage for verification-required and supported proof states.
- `test/mix/tasks/crosswake_doctor_test.exs`
  - Added Mix task coverage for human and JSON shell-proof posture.

## Verification

- `mix test test/crosswake/doctor/doctor_test.exs test/mix/tasks/crosswake_doctor_test.exs`
- `rg -n 'shell|bridge|route unavailable|proof|verification required|ios|android|advisory|warning|unsupported|pack_incompatible' lib/crosswake/doctor/doctor.ex lib/crosswake/doctor/formatter.ex lib/crosswake/doctor/json_formatter.ex test/crosswake/doctor/doctor_test.exs test/mix/tasks/crosswake_doctor_test.exs`
- `rg -n 'host-owned|manifest-first|route unavailable|App-Bound Domains|iOS|Android|verification required|unsupported' guides/native_shell.md guides/support_matrix.md`
- `rg -n 'guides/native_shell\.md|guides/bridge\.md|mix crosswake\.doctor' guides/install.md guides/compatibility.md`

## Notes

- Doctor now blocks support claims with explicit `verification required` findings unless
  both generated-project proof hooks are present and pass.
- The targeted verification in this run used proof-hook stubs inside tests; repo-level
  shell support still depends on the real host environment passing
  `script/verify_generated_ios_shell.sh` and `script/verify_generated_android_shell.sh`.
