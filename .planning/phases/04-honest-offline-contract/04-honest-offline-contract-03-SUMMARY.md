# Phase 4 Plan 04-03 Summary

## Outcome

Crosswake now exposes a stable offline status vocabulary, a route-level telemetry
metadata contract, and offline posture through both `mix crosswake.doctor`
human-readable output and its JSON report.

## What Changed

- `lib/crosswake/offline/status.ex`
  - Added stable route-local offline states for cached read-only, stale, saved
    locally, queued replay, replay failure, and conflict-required attention.
- `lib/crosswake/offline/telemetry.ex`
  - Added the typed telemetry metadata contract for route id, runtime, offline
    mode, sync seam, journal entry id, manifest/runtime versions, correlation
    id, and terminal outcome.
- `lib/crosswake/doctor/doctor.ex`
  - Added offline posture inspection derived from explicit cache and island
    contracts in the manifest.
- `lib/crosswake/doctor/formatter.ex`
  - Added a human-readable offline posture section.
- `lib/crosswake/doctor/json_formatter.ex`
  - Added machine-readable offline posture payloads.
- `test/crosswake/offline/status_test.exs`
- `test/crosswake/offline/telemetry_test.exs`
- `test/crosswake/doctor/doctor_test.exs`
- `test/mix/tasks/crosswake_doctor_test.exs`
  - Added coverage for the stable vocabulary, telemetry contract, and doctor
    output surfaces.

## Verification

- `mix test test/crosswake/offline/status_test.exs test/crosswake/offline/telemetry_test.exs test/crosswake/doctor/doctor_test.exs test/mix/tasks/crosswake_doctor_test.exs`
- `rg -n 'cached|stale|saved_locally|queued_for_replay|replay_failed|conflict_requires_attention|route_id|runtime|offline_mode|sync_seam|journal_entry_id|manifest_version|native_runtime_version|correlation_id|terminal_outcome' lib/crosswake/offline/status.ex lib/crosswake/offline/telemetry.ex lib/crosswake/doctor/doctor.ex lib/crosswake/doctor/formatter.ex lib/crosswake/doctor/json_formatter.ex test/crosswake/offline/status_test.exs test/crosswake/offline/telemetry_test.exs test/crosswake/doctor/doctor_test.exs test/mix/tasks/crosswake_doctor_test.exs`
