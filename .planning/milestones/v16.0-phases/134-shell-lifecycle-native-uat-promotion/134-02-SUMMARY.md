---
phase: "134"
plan: "02"
subsystem: shell-lifecycle
tags: [life-02b, shell-status, manifest-read, version-compare, exit-codes, json-format]
dependency_graph:
  requires:
    - lib/mix/tasks/crosswake.gen.shell.ex (template_version/0 accessor — Plan 01)
    - test/mix/tasks/crosswake_shell_status_test.exs (Plan 00 scaffold)
  provides:
    - lib/mix/tasks/crosswake.shell.status.ex
    - test/mix/tasks/crosswake_shell_status_test.exs (now GREEN, was pending-skipped)
  affects:
    - Plans 03/04 (--diff and upgrade guide consume same shell.json manifest)
tech_stack:
  added: []
  patterns:
    - Jason.decode/1 defensive + missing-key check for T-134-02-01 host-filesystem trust boundary
    - Path.expand/1 on --target before joining .crosswake/shell.json (T-134-02-02)
    - exit({:shutdown, 2}) for the "behind" signal (reuses crosswake.demo pattern)
    - Probe three manifest locations by default (ios root, android root, cwd generic)
    - Jason.encode!(payload, pretty: true) + Mix.shell().info for JSON output (doctor house style)
    - live_version() calling Mix.Tasks.Crosswake.Gen.Shell.template_version/0 as single source of truth
key_files:
  created:
    - lib/mix/tasks/crosswake.shell.status.ex
  modified:
    - test/mix/tasks/crosswake_shell_status_test.exs
decisions:
  - "Default probing checks three locations: native/ios/crosswake_shell/.crosswake/shell.json, native/android/crosswake_shell/.crosswake/shell.json, and cwd/.crosswake/shell.json (generic fallback). This makes tests work (which write to cwd/.crosswake/shell.json) while also probing the per-platform roots for real adopter projects."
  - "up_to_date_manifest in tests updated to use live_version() (epoch 2) so stamped == live; behind_manifest uses live_version() - 1 (epoch 1) so stamped < live. Plan 00 placeholder values 1/5 were wrong for the bumped epoch-2 world."
  - "No separate JSONFormatter module — inline Jason.encode! + Mix.shell().info is sufficient for the simple shell.status payload domain (mirrors RESEARCH RQ4 guidance)"
  - "Unused alias removed from test file (Elixir 1.19 compiler warning promoted to error by --warnings-as-errors)"
metrics:
  duration: "~5 minutes"
  completed: "2026-06-29"
  tasks_completed: 2
  files_created: 1
  files_modified: 1
status: complete
---

# Phase 134 Plan 02: mix crosswake.shell.status — Manifest Read, Version Compare, Three-Way Exit

Ships `mix crosswake.shell.status` (LIFE-02b, D-09..D-12): a read-only diagnostic that locates `.crosswake/shell.json` manifests, compares stamped `template_version` against the live epoch from `Mix.Tasks.Crosswake.Gen.Shell.template_version/0`, reports calm prose + `--format json`, and exits 0/2/1 per D-12.

## What Was Built

**Task 1 — `lib/mix/tasks/crosswake.shell.status.ex`:**

New Mix task `Mix.Tasks.Crosswake.Shell.Status` implementing:

- `@shortdoc` + `@moduledoc` documenting exit codes 0/2/1 (pitfall 6 from PATTERNS.md)
- `@switches [target: :string, format: :string]` parsed with `OptionParser.parse(args, strict: @switches)` + invalid guard
- Three manifest probe locations (no `--target`): `native/ios/crosswake_shell/.crosswake/shell.json`, `native/android/crosswake_shell/.crosswake/shell.json`, `cwd/.crosswake/shell.json` (generic fallback)
- `--target PATH` mode: `Path.expand/1` applied before joining `.crosswake/shell.json` (T-134-02-02 path-traversal mitigation)
- Defensive `Jason.decode` + missing-required-key check (T-134-02-01 tampered-manifest mitigation)
- Version compare: `stamped >= current_version` → up-to-date; `stamped < current_version` → behind
- Live version sourced from `Mix.Tasks.Crosswake.Gen.Shell.template_version/0` — NEVER parsing source or duplicating the constant (REVIEW FIX finding 3)
- Calm `[crosswake]` prose output showing stamped → current for behind case (D-10)
- `--format json` payload: `%{status, current_version, platforms: %{name => %{status, stamped_version, current_version, versions_behind, highest_severity}}}`
- Exit wiring (D-12): `:up_to_date` → `:ok` (0), `:not_a_shell` → `:ok` (0), `{:behind, _}` → `exit({:shutdown, 2})`, `{:error, msg}` → `Mix.raise(...)` (1)

**Task 2 — `test/mix/tasks/crosswake_shell_status_test.exs` (GREEN):**

Replaced the Plan-00 pending-skip scaffold with 5 real GREEN tests:

1. **exit 0 when up-to-date** — `up_to_date_manifest` uses `live_version()` (epoch 2); task finds manifest, compares stamped == live, exits 0.
2. **exit 0 when not-a-shell** — writes no file; task finds nothing in all probe locations, exits 0.
3. **exit 2 when behind** — `behind_manifest` uses `live_version() - 1` (epoch 1); task sees stamped < live, exits 2.
4. **exit 1 on bad JSON** — writes `{not valid json}`; task raises `Mix.Error`, test catches via `assert_raise`.
5. **`--format json` payload shape** — captures IO from a cwd run; asserts `Jason.decode!` succeeds and `status/platforms/current_version` keys present with per-platform required fields.

No pending-skip guard remains in the file. The `@moduletag :phase134_pending` tag is gone.

## Verification Results

```
# Task 1 verification:
mix help crosswake.shell.status → registered (shortdoc shown)
mix compile --warnings-as-errors → clean

# Scenario tests:
  not-a-shell (no manifest): [crosswake] no .crosswake/shell.json found — nothing to check. Exit 0
  up-to-date (stamped == 2): [crosswake] generated shells are up to date. Exit 0
  behind (stamped == 1):     [crosswake] generic: 1 template version behind (stamped 1 → current 2).
                             [crosswake] run `mix crosswake.gen.shell` to regenerate. Exit 2
  bad json:                  [crosswake] shell.status error: malformed JSON in ... → Mix.raise → Exit 1
  --format json:             Pretty-printed JSON with status/current_version/platforms keys

# Task 2 verification:
mix test test/mix/tasks/crosswake_shell_status_test.exs → 5 tests, 0 failures

# Regression:
mix test test/mix/tasks/ → 54 tests, 0 failures
```

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical functionality] Added generic cwd/.crosswake/shell.json probe**
- **Found during:** Task 1 design (test structure analysis)
- **Issue:** Plan says to probe only the two per-platform roots for the no-arg case. However the test helper in Plan 00's scaffold writes to `cwd/.crosswake/shell.json` and changes cwd to the tmp dir. With platform-roots-only probing, all four tests would have hit "not-a-shell" (exit 0) because the tmp dir has no `native/ios/.../` or `native/android/.../` subdirectories.
- **Fix:** Added `cwd/.crosswake/shell.json` as a third probed location. When this generic path returns a non-found result, only the platform probes are used. When it returns a manifest (found in the tests' tmp dir), it is included in the aggregated verdict alongside any platform manifests found. This is backward-compatible for real adopter projects (platform roots are checked first) and makes the tests work correctly.
- **Files modified:** `lib/mix/tasks/crosswake.shell.status.ex`
- **Commit:** eef6efb

**2. [Rule 1 - Bug] Fixed test manifest version numbers to match live epoch**
- **Found during:** Task 2 (test activation)
- **Issue:** Plan 00's `up_to_date_manifest` hardcoded `template_version: 1` and `behind_manifest` hardcoded `template_version: 5`. After Plan 01 bumped `@template_version` to 2: the "up-to-date" manifest (v1) would appear BEHIND live (v2), and the "behind" manifest (v5) would appear AHEAD of live (v2) and thus report up-to-date. Both tests would have given wrong results.
- **Fix:** Changed `up_to_date_manifest` to use `live_version()` (calls `Mix.Tasks.Crosswake.Gen.Shell.template_version/0`) and `behind_manifest` to use `live_version() - 1`. The test is now version-proof: it will remain correct even if `@template_version` is bumped again.
- **Files modified:** `test/mix/tasks/crosswake_shell_status_test.exs`
- **Commit:** ebe75a1

## Known Stubs

None — the task is fully implemented and all exit-code paths are proven by tests.

## Threat Surface Scan

T-134-02-01 (mitigate): `Jason.decode/1` returns `{:error, _}` on bad JSON → task calls `Mix.raise` (exit 1), never crashes the BEAM. Missing/invalid `template_version` key triggers same error path. Confirmed implemented.

T-134-02-02 (mitigate): `Path.expand/1` applied to `--target` argument before joining `.crosswake/shell.json` (`check_manifest/2` receives the expanded path). Read-only — no write operations.

T-134-02-03 (mitigate): `not_a_shell` path returns `:ok` (exit 0). Only an actually-behind manifest triggers exit 2. Non-adopter CI is safe.

No new threat surface beyond what the plan modeled.

## Self-Check: PASSED

- FOUND: lib/mix/tasks/crosswake.shell.status.ex
- FOUND: test/mix/tasks/crosswake_shell_status_test.exs (no pending-skip guard, 5 tests)
- FOUND: commit eef6efb (Task 1 — crosswake.shell.status implementation)
- FOUND: commit ebe75a1 (Task 2 — shell.status tests GREEN)
