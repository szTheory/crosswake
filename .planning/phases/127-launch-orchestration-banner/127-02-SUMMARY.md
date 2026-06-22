---
phase: 127-launch-orchestration-banner
plan: "02"
subsystem: launch-orchestration
tags: [mix-task, drift-guard, banner, launch, anti-vacuity]
status: complete

dependency_graph:
  requires: [127-01]
  provides: [mix crosswake.demo alias, banner drift guard]
  affects: []

tech_stack:
  added: []
  patterns:
    - thin Mix.Task shell-out alias (System.cmd passthrough, no banner logic)
    - source-derived drift guard with anti-vacuity synthetic cases (D-21 house idiom)
    - PORT derived from runtime.exs via regex — never hardcoded

key_files:
  created:
    - lib/mix/tasks/crosswake.demo.ex
    - test/crosswake/guides/see_it_run_banner_test.exs
  modified: []

decisions:
  - mix crosswake.demo resolved script path via __DIR__ walking three levels up to repo root
  - Banner scan asserts "    /              " (with leading spaces) for the home route to avoid false matches against JAVA_HOME
  - Anti-vacuity wrong-port case replaces "localhost:#{port}" substring (not bare port) to avoid mutating JAVA_HOME path

metrics:
  duration: "4 min"
  completed: "2026-06-22"
  tasks_completed: 2
  files_created: 2
  files_modified: 0
---

# Phase 127 Plan 02: Elixir Companions (mix alias + banner drift guard) Summary

**One-liner:** Thin `mix crosswake.demo` System.cmd passthrough alias and a source-derived `see_it_run_banner_test.exs` drift guard with anti-vacuity synthetic cases.

## Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | Thin mix crosswake.demo alias | da8cb6b | lib/mix/tasks/crosswake.demo.ex |
| 2 | see_it_run_banner_test.exs source-derived banner drift guard | 4e95669 | test/crosswake/guides/see_it_run_banner_test.exs |

## What Was Built

**Task 1 — `mix crosswake.demo` alias (`lib/mix/tasks/crosswake.demo.ex`)**

A pure passthrough `Mix.Task` that carries no banner/boot/docker/curl logic. The `run/1` implementation resolves `bin/see-it-run.sh` from `__DIR__` (three levels up to repo root) then calls `System.cmd(script_path, args, into: IO.stream(:stdio, :line))`, streaming all output (progress dots + ASCII banner) live to the terminal. Args are forwarded verbatim — no `OptionParser.parse`. Non-zero exit status propagates via `exit({:shutdown, status})`. The `@moduledoc` carries the explicit note `# logic lives in bin/see-it-run.sh` (D-01). Does not reference `Crosswake.Doctor` (D-18).

**Task 2 — `Crosswake.Guides.SeeItRunBannerTest` (`test/crosswake/guides/see_it_run_banner_test.exs`)**

Source-derived drift guard for the `bin/see-it-run.sh` banner string. PORT is derived from `examples/phoenix_host/config/runtime.exs` via `~r/System\.get_env\("PORT"\)\s*\|\|\s*"(\d+)"/` — `4700` does not appear as a hardcoded literal anywhere in the test. The main scan asserts:
- Derived URL (`http://localhost:4700` resolved at test-run time)
- Three routes: `/` home, `/offline`, `/bridge-proof`
- iOS command literals: `-scheme Dev`, `Debug-Dev`
- Android command literals: `installDevDebug`, `adb shell am start -n dev.crosswake.shell.dev/.MainActivity`, `JAVA_HOME=/opt/homebrew/opt/openjdk@17`
- Native posture words: `advisory`, `simulator`, `emulator`, `proven native build`

Three synthetic anti-vacuity cases (D-21 house idiom) prove the guard is not vacuous:
- Wrong port case: replaces `localhost:4700` → `localhost:4000`; asserts `:wrong_port` failure
- Missing route case: replaces `/bridge-proof` → `/nope`; asserts `:missing_route` failure
- Missing posture case: replaces `advisory` (case-insensitive) → `optional`; asserts `:missing_native_label` failure

All 5 tests (1 readability + 1 main + 3 anti-vacuity) pass green.

## Verification

- `mix compile --warnings-as-errors` — passes (clean)
- `mix test test/crosswake/guides/see_it_run_banner_test.exs` — 5 tests, 0 failures
- `git status` — clean; only the two new files added; no change to `bin/see-it-run.sh`, `runtime.exs`, or any proof fixture

## Deviations from Plan

None — plan executed exactly as written.

## Threat Surface Scan

No new network endpoints, auth paths, or trust-boundary schema changes introduced. The `System.cmd` invocation in `mix crosswake.demo` targets a fixed repo-relative path (not user-supplied), satisfying T-127-06. The drift test reads two files read-only, satisfying T-127-07/T-127-08.

## Self-Check: PASSED

- [x] `lib/mix/tasks/crosswake.demo.ex` exists
- [x] `test/crosswake/guides/see_it_run_banner_test.exs` exists
- [x] Commit `da8cb6b` exists (Task 1)
- [x] Commit `4e95669` exists (Task 2)
- [x] `mix test test/crosswake/guides/see_it_run_banner_test.exs` passes (5/5)
