---
phase: "134"
plan: "00"
subsystem: test-scaffolding
tags: [nyquist, red-green-refactor, proof, life-02a, life-02b, life-02c]
dependency_graph:
  requires: []
  provides:
    - test/crosswake/proof/phase134_template_version_drift_test.exs
    - test/mix/tasks/crosswake_shell_status_test.exs
    - test/mix/tasks/crosswake_gen_shell_diff_test.exs
    - test/crosswake/guides/native_shell_upgrade_test.exs
  affects:
    - Plans 01–04 (each turns a RED scaffold GREEN)
tech_stack:
  added: []
  patterns:
    - ProofAssertions.stable_id_message/7 for merge-blocking stable IDs
    - File.cwd!() path anchoring (not Application.app_dir/2)
    - Code.ensure_loaded?/1 pending-skip guard for not-yet-built tasks
    - :crypto.hash(:sha256, blob) + Base.encode16 for template hashing
key_files:
  created:
    - test/crosswake/proof/phase134_template_version_drift_test.exs
    - test/mix/tasks/crosswake_shell_status_test.exs
    - test/mix/tasks/crosswake_gen_shell_diff_test.exs
    - test/crosswake/guides/native_shell_upgrade_test.exs
  modified: []
decisions:
  - "@checked_in_hash all-zero placeholder on dedicated line — regex rewrite target for mix crosswake.bump_template_version (Plan 01)"
  - "diff_switch_available? uses __info__(:attributes) not :module_info to detect --diff flag; :module_info is invalid for __info__/1"
  - "native_shell_upgrade_test.exs tests RED (not pending-skipped) — both guide-exists and placeholder-removed are provably false now; acceptance criteria allows either outcome"
  - "crosswake_shell_status_test.exs and crosswake_gen_shell_diff_test.exs use Code.ensure_loaded? guard to avoid FunctionClauseError on not-yet-built modules"
metrics:
  duration: "~4 minutes"
  completed: "2026-06-29"
  tasks_completed: 2
  files_created: 4
  files_modified: 0
status: complete
---

# Phase 134 Plan 00: Wave 0 Test Scaffold Summary

Wave 0 Nyquist sampling — four new RED test files that give every downstream Plan 01–04 an automated verify target before any code-producing task lands.

## What Was Built

**Task 1 — Drift test (LIFE-02a):** `test/crosswake/proof/phase134_template_version_drift_test.exs`

Mirrors `phase132_compat_matrix_drift_test.exs` exactly: `async: true`, `File.cwd!()` anchor, `ProofAssertions.stable_id_message/7` with stable ids. Three tests:
- Drift guard (`proof.life_02a.template_version_drift`) — RED on all-zero placeholder hash. Plan 01 stamps the real hash and turns this GREEN.
- Non-vacuity iOS (`proof.life_02a.non_vacuity.ios`) — GREEN immediately (templates exist).
- Non-vacuity Android (`proof.life_02a.non_vacuity.android`) — GREEN immediately.

`@checked_in_hash` on its own dedicated line (`@checked_in_hash "000...000"`) is the regex rewrite target for `crosswake.bump_template_version`.

**Task 2 — Three scaffold files:**

`test/mix/tasks/crosswake_shell_status_test.exs` (LIFE-02b, Plan 02 target):
- Four exit-code behavior stubs (exit 0 up-to-date, exit 0 not-a-shell, exit 2 behind, exit 1 bad manifest)
- Pending-skipped via `Code.ensure_loaded?(Mix.Tasks.Crosswake.Shell.Status)` guard

`test/mix/tasks/crosswake_gen_shell_diff_test.exs` (LIFE-02b diff, Plan 03 target):
- Three stubs: diff-no-write (snapshot mtimes), diff-stdout (unified-diff header), pbxproj-excluded
- Pending-skipped via `Code.ensure_loaded?` + `__info__(:attributes)` switch detection

`test/crosswake/guides/native_shell_upgrade_test.exs` (LIFE-02c, Plan 04 target):
- Doc-presence test: `guides/native_shell_upgrade.md` exists and references `RebuildPolicy.classify/2` — RED
- Structural test: `crosswake.gen.shell.ex` no longer holds the placeholder phrase — RED

## Verification Results

```
# Task 1 verification (finding 7 fix: || true guard, grep log for stable id + failure count):
drift test compiles, runs, and is RED with the contract stable id (expected on placeholder hash)

3 tests, 1 failure  (drift guard RED, 2 non-vacuity GREEN — exactly as specified)

# Task 2 verification:
10 tests, 2 failures  (no CompileError, shell.status/diff tests skipped, guide tests RED)

# Full suite regression check:
1195 tests, 3 failures  (all 3 failures are expected Phase 134 Plan 00 RED tests)
```

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed invalid `__info__(:module_info)` call in diff_switch_available?**
- **Found during:** Task 2 verification run
- **Issue:** Initial `diff_switch_available?` used `@gen_shell_module.__info__(:module_info)` which raises `FunctionClauseError` — `:module_info` is not a valid atom for `__info__/1` (valid keys: `:attributes`, `:functions`, `:macros`, etc.)
- **Fix:** Changed to `@gen_shell_module.__info__(:attributes)` and `Keyword.has_key?(switches, :diff)` — the correct way to check for a module attribute's presence
- **Files modified:** `test/mix/tasks/crosswake_gen_shell_diff_test.exs`
- **Commit:** ebe6ef0 (included in Task 2 commit)

## Known Stubs

None — this plan creates scaffolds, which are intentionally RED/pending by design. The RED state is the deliverable; Plans 01–04 turn each RED stub GREEN.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes. All four files are read-only test files that access only in-repo paths via `File.cwd!()` anchors. No new threat surface beyond what `134-PLAN.md` modeled (T-134-00-01, T-134-00-02 both accepted/mitigated).

## Self-Check: PASSED

- FOUND: test/crosswake/proof/phase134_template_version_drift_test.exs
- FOUND: test/mix/tasks/crosswake_shell_status_test.exs
- FOUND: test/mix/tasks/crosswake_gen_shell_diff_test.exs
- FOUND: test/crosswake/guides/native_shell_upgrade_test.exs
- FOUND: commit 761c9cf (Task 1 — drift test)
- FOUND: commit ebe6ef0 (Task 2 — three scaffold files)
