---
phase: 187-doctor-and-proof-fidelity
plan: 01
subsystem: doctor
tags: [doctor, offline-posture, unmanaged-routes, json]
requires: []
provides:
  - unmanaged_routes finding details (unmanaged_paths, router)
  - offline_posture_incomplete error for an unbacked offline island (incoherent_routes)
  - offline.status not_claimed with advisory offline_posture_not_claimed
affects: [187-04, 187-06, 187-07]
actuals:
  tokens: 14000
  tasks: 3
  commits: 0
  note: "uncommitted by design; the single phase commit belongs to 187-07"
key-files:
  created: [test/crosswake/doctor/doctor_fidelity_test.exs]
  modified: [lib/crosswake/doctor/doctor.ex, test/mix/tasks/crosswake_doctor_test.exs, test/support/router_fixtures.ex, CHANGELOG.md, guides/offline.md, guides/install.md]
key-decisions:
  - "incoherent_ids computed over all manifest routes before the contract filter; predicate not widened (D-07, D-09)"
  - "status precedence incomplete > not_claimed > supported"
requirements-completed: [DOCTOR-01, DOCTOR-02]
status: complete
completed: 2026-10-16
---

# Phase 187 Plan 01: Doctor Fidelity Summary

**Doctor now keeps unmanaged route paths and router in its finding, errors on an unbacked offline island, and reports an honest not_claimed when no route claims offline.**

All edits are in the candidate checkout, uncommitted (187-07 commits). Nothing was staged or committed anywhere. Preconditions held: HEAD bd294007, push URL no-push-phase180, clean tree.

## Red and green evidence (RUNS = /private/tmp/crosswake-phase180-run)

| Task | Red (exit 2) failure headers | Green |
|------|------------------------------|-------|
| 1 tracer | T_U1, T_U2, T_J1 (red-187-01-t1.out) | 10 tests, 0 failures (t1-187-01.out) |
| 2 | T_H1, T_H2, T_J2; controls T_C1 and T_P passed (red-187-01-t2.out) | 15 tests, 0 failures (t2-187-01.out) |
| 3 | T_N1, T_N2, T_J3 (red-187-01-t3.out) | doctor, mix doctor task, phase154, offline and guides suites: 360 tests, 0 failures (19 excluded), exit 0 (green-187-01.out) |

Other gates, each exit 0: compile --force --warnings-as-errors (compile-187-01), crosswake.docs.sync --check (docsync-187-01), mix format --check-formatted on all changed .ex/.exs files (format-187-01). status-187-01.txt lists only this plan's seven paths. json_formatter.ex is unchanged. No RUNS output contains the home path.

## What changed

- `lib/crosswake/doctor/doctor.ex`: unmanaged_routes check passes `%{unmanaged_paths: sorted unique, router: warning.module && inspect(warning.module)}` (null for a route list). `phase_4_posture/1` computes `incoherent_ids` (runtime :offline_island, offline :local_first, no island_contract; unique, sorted) before the contract filter, and `claims_offline?`; the finding is one of offline_posture_incomplete (:error, details gain `incoherent_routes`), offline_posture_not_claimed (:advisory) or offline_posture_ready (:advisory).
- Tests: eight in the new `Crosswake.Doctor.FidelityTest`; T_J1, T_J2, T_J3 in `test/mix/tasks/crosswake_doctor_test.exs`.
- Fixtures: `OfflineHoleRouter` and `NoOfflineRouter` in `test/support/router_fixtures.ex` (synthetic paths only).
- Docs: one CHANGELOG [Unreleased] bullet (not_claimed distinct from the native-shell posture, unbacked island is now a doctor error, unmanaged_routes details); one guides/offline.md paragraph; two guides/install.md lines (`--router` accepts any module exporting `__routes__/0`; doctor JSON holds route patterns, do not paste into public issues).

## Deviations from Plan

None - plan executed as written.

- Assertion-only edits outside files_modified: none. No existing test broke, so no churn file (doctor_test.exs, formatter_test.exs, phase154, proof_lane_test.exs) was touched, and no pre-existing test in crosswake_doctor_test.exs was edited.
- T_J1 wraps the run in `try/rescue Mix.Error` defensively (output prints before any raise); the decoded JSON assertion decides the test.
- T_J3 assumption checked: with NoOfflineRouter and the hooks-pass setup, the only offline finding is offline_posture_not_claimed and the report status is not error. No fixture fix was needed.
- The offline_posture_incomplete hint was extended to name island_contract and incoherent_routes.

## Known Stubs

None.

## Threat Flags

None. Details carry route patterns and a module name only (T-187-03); the D-09 residual (cached_read_only without cache_contract, native_screen local_first without contract still report supported) is pinned by T_P and is for 187-04 to disclose.

## Self-Check: PASSED

Files verified present; exit files all 0 for green, compile, docsync and format; red exit files non-zero.
