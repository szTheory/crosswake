---
phase: "134"
plan: "03"
subsystem: shell-lifecycle
tags: [life-02b, diff, unified-diff, non-destructive, rebuild-policy, advisory-verdict]
dependency_graph:
  requires:
    - lib/mix/tasks/crosswake.gen.shell.ex (template_version/0, @ios_templates, @android_templates — Plan 01)
    - .crosswake/shell.json manifest (Plan 01 write_shell_manifest/5)
    - test/mix/tasks/crosswake_gen_shell_diff_test.exs (Plan 00 scaffold)
  provides:
    - lib/mix/tasks/crosswake.gen.shell.ex (--diff switch, run_diff/4, file_advisory_verdict/1, @diff_excluded_templates)
    - test/mix/tasks/crosswake_gen_shell_diff_test.exs (now GREEN, was pending-skipped)
  affects:
    - Plan 04 (upgrade guide references --diff and shell.status for the per-version change entry)
tech_stack:
  added: []
  patterns:
    - Early fork in run/1 before any write (D-13 structural non-destructiveness guarantee)
    - Jason.decode/1 defensive read of manifest params for re-render assigns (D-14)
    - List.myers_difference/2 for unified diff computation (D-15, no external dep)
    - IO.ANSI.enabled?() gate for colorization (red/green diff lines on TTY)
    - file_advisory_verdict/1 private lookup reusing RebuildPolicy verdict vocabulary (D-16)
    - @diff_excluded_templates module attribute as the sole diff exclusion list
key_files:
  created: []
  modified:
    - lib/mix/tasks/crosswake.gen.shell.ex
    - test/mix/tasks/crosswake_gen_shell_diff_test.exs
decisions:
  - "@diff_excluded_templates contains ONLY project.pbxproj — gradlew/gradlew.bat are diffed with :ota_safe advisory verdict (REVIEW FIX finding 6 — D-02 stamps exclusion != D-15 diff exclusion)"
  - "run_diff/4 forks before generate_ios/android_shell and before any ensure_file/write call — non-destructiveness is a code guarantee not a convention (D-13)"
  - "file_advisory_verdict/1 uses cond with explicit basename/pattern matching, safe default :ota_safe for unmapped files — no RebuildPolicy.diff/2 call (D-16)"
  - "async: false in diff test to avoid Mix.Task.rerun global state races with concurrent mix-task tests"
metrics:
  duration: "~8 minutes"
  completed: "2026-06-29"
  tasks_completed: 2
  files_created: 0
  files_modified: 2
status: complete
---

# Phase 134 Plan 03: mix crosswake.gen.shell --diff — Non-Destructive Unified Diff Summary

Ships the `--diff` switch on `mix crosswake.gen.shell` (LIFE-02b, D-13..D-16): non-destructive
in-memory re-render + `List.myers_difference/2` unified diff with advisory RebuildPolicy-vocabulary
annotations, `project.pbxproj` excluded, ANSI colorized on TTY, and the diff test GREEN.

## What Was Built

**Task 1 — `--diff` branch in `lib/mix/tasks/crosswake.gen.shell.ex`:**

Module-level additions:
- `diff: :boolean` added to `@switches` (alongside existing target/router/local)
- `@diff_excluded_templates ["CrosswakeShell.xcodeproj/project.pbxproj"]` — the ONLY diff exclusion.
  `gradlew`/`gradlew.bat` are NOT excluded (REVIEW FIX finding 6: D-02's gradlew exclusion is scoped
  to stamp-only, not diff — the prior over-exclusion would hide wrapper-template changes from hosts).

`run/1` restructured:
- Trust banner printed immediately: `[crosswake] diff — read-only, no files changed`
- Fork in `run/1` BEFORE any `ensure_file/2` or `File.write!/2` call (D-13 structural guarantee)
- `if opts[:diff]` → `run_diff/4` (read-only); `else` → original generation path unchanged

`run_diff/4` flow (D-14 re-render assigns):
1. Reads `.crosswake/shell.json` at the per-platform root for saved `params`
2. Defensive `Jason.decode/1` — on bad JSON or missing keys, falls back to CLI opts with info message
3. Local-path-missing guard: if `params.local == true` but packages path absent → explicit warn + `local: false` fallback (never silent fail, D-14)
4. Re-renders each template in-memory with `render_template/4` using manifest params so app-name/bundle/router matches the original generation (no spurious diff noise)
5. Skips `@diff_excluded_templates` entries
6. Runs `List.myers_difference/2` on on-disk vs re-rendered lines; calls `file_advisory_verdict/1` per changed file
7. Prints git-style `---`/`+++` headers + ANSI-colored `-`/`+` lines (gated by `IO.ANSI.enabled?()`)
8. Prints advisory verdict annotation per changed file with "(advisory)" label
9. Prints summary stats: changed (ota-safe), changed (rebuild-required), unchanged, missing on disk
10. Prints oracle-caveat line when changes found: "advisory verdicts are tooling input, not release-gate oracles"

`file_advisory_verdict/1` (D-16 correctness catch — does NOT call `RebuildPolicy.diff/2`):
- Maps file basenames/patterns to RebuildPolicy verdict vocabulary atoms
- `{:rebuild_required, :native_shell}`: Info.plist, PrivacyInfo.xcprivacy, *.entitlements, AndroidManifest.xml, app/build.gradle, root build.gradle, gradle-wrapper.properties
- `:ota_safe`: *.swift, *.kt, gradlew, gradlew.bat, settings.gradle, gradle.properties, themes.xml
- Safe default: `:ota_safe` for any unmapped basename (no file left unannotated)

**Task 2 — `test/mix/tasks/crosswake_gen_shell_diff_test.exs` (GREEN):**

Removed the Plan-00 pending-skip guards and `@moduletag :phase134_pending`. Changed `async: true` to
`async: false` to prevent `Mix.Task.rerun` global state races. Implemented three real tests, each in
its own tmp dir:

1. **diff-no-write** — generate android shell, `snapshot_files/1` maps all paths→binary content,
   run `--diff`, re-snapshot, assert `Map.keys` identical and all content byte-equal.
2. **diff-stdout** — generate android shell, append a sentinel line to `gradle.properties` on disk
   (NOT in the template), run `--diff`, assert output contains `"---"` unified-diff header.
3. **pbxproj-excluded** — generate iOS shell, run `--diff`, `refute String.contains?(output, "project.pbxproj")`.

## Verification Results

```
# Task 1 verification (plan's automated check):
rm -rf /tmp/cw_diff && mix crosswake.gen.shell android --target /tmp/cw_diff
find /tmp/cw_diff -type f | sort > /tmp/cw_diff_before.txt
mix crosswake.gen.shell android --target /tmp/cw_diff --diff > /tmp/cw_diff_out.txt 2>&1
find /tmp/cw_diff -type f | sort > /tmp/cw_diff_after.txt
diff /tmp/cw_diff_before.txt /tmp/cw_diff_after.txt    → (no output — file sets identical)
! grep -q "project.pbxproj" /tmp/cw_diff_out.txt       → TRUE (pbxproj absent)
grep -q "read-only" /tmp/cw_diff_out.txt               → TRUE (banner present)
→ "diff non-destructive, pbxproj excluded, banner present"

# Unchanged shell summary output:
[crosswake] diff — read-only, no files changed
[crosswake] diff summary
  changed (ota-safe):        0
  changed (rebuild-required): 0
  unchanged:                 11
  missing on disk:           0
[crosswake] generated shell matches current templates — no changes.

# iOS template count (7 - 1 pbxproj = 6 unchanged):
[crosswake] diff summary: unchanged: 6

# Forced-change test (appended line to gradle.properties on disk):
--- gradle.properties (on disk)
+++ gradle.properties (current template)
[advisory verdict: ota-safe (advisory)]
-# extra line added
[crosswake] diff summary: changed (ota-safe): 1, unchanged: 10

# Task 2 verification:
mix test test/mix/tasks/crosswake_gen_shell_diff_test.exs → 3 tests, 0 failures

# Compile check:
mix compile --warnings-as-errors → clean
```

## Deviations from Plan

### Auto-fixed Issues

None — plan executed exactly as written. The REVIEW FIX finding 6 (gradlew/gradlew.bat inclusion) was already incorporated into the plan; the implementation follows the plan's stated resolution.

### Notes

**Pre-existing flaky test (not caused by this plan):** `mix test test/mix/tasks/` is intermittently
flaky (~10-15% of runs) due to a pre-existing race in `crosswake_shell_status_test.exs` (Plan 02)
which calls `File.cd!(tmp_dir)` in async tests. When `crosswake_gen_shell_test.exs` runs concurrently,
`Application.app_dir(:crosswake)` resolves relative to the changed CWD, causing `EEx.eval_file` to
fail. This race predates Plan 03 — verified by reproducing the failure with `--exclude phase134_pending`.
Logged to `deferred-items.md`.

## Known Stubs

None — `--diff` is fully implemented: re-renders from manifest, computes unified diff, annotates with
advisory verdicts, prints summary stats, and writes nothing.

## Threat Surface Scan

T-134-03-01 (mitigate): Re-render is in-memory only; diff output is printed to stdout, never written.
A poisoned manifest param can mislead the diff text but cannot modify host files (D-13 structural fork).
Confirmed implemented — `run_diff/4` never calls `ensure_file/2` or `File.write!/2`.

T-134-03-02 (mitigate): Local package path missing → explicit `Mix.shell().info` warn + `local: false`
fallback. Never silently crashes. Confirmed in `run_diff/4` local-path guard.

T-134-03-03 (accept): Host-owned files are printed back to the host's own terminal. No new exposure.

T-134-03-04 (mitigate): Fork happens at `if opts[:diff]` in `run/1`, before the `else` branch that calls
`generate_ios_shell/4` / `generate_android_shell/4` / `ensure_file/2`. No-write test asserts byte-identical
file set before/after `--diff`.

No new threat surface beyond what the plan modeled.

## Self-Check: PASSED

- FOUND: lib/mix/tasks/crosswake.gen.shell.ex (diff: :boolean in @switches, @diff_excluded_templates,
  run_diff/4, file_advisory_verdict/1, print_file_diff/4, render_diff_hunks/2)
- FOUND: test/mix/tasks/crosswake_gen_shell_diff_test.exs (no pending-skip guard, async: false, 3 tests)
- FOUND: commit 026dc2a (Task 1 — --diff branch)
- FOUND: commit 7acff79 (Task 2 — diff tests GREEN)
