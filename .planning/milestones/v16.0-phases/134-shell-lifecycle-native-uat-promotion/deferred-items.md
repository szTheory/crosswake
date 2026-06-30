# Phase 134 Deferred Items

## Pre-existing Flaky Test (discovered in Plan 03)

**File:** `test/mix/tasks/crosswake_shell_status_test.exs` (from Plan 02)

**Issue:** `run_status/3` helper calls `File.cd!(tmp_dir)` which changes the OS process CWD — a process-global
side effect. When `crosswake_gen_shell_test.exs` runs concurrently (it uses `async: true`), it calls
`EEx.eval_file` with a path from `Application.app_dir(:crosswake)` which resolves relative to whatever the
current CWD is. If the status test has changed CWD to `/tmp/cw_status_test_NNN`, `Application.app_dir`
returns a path inside that tmp dir, which doesn't have `priv/templates/...`, causing a File.Error.

**Reproduction rate:** ~10-15% of `mix test test/mix/tasks/` runs.

**Root cause:** Pre-existing in Plan 02's `shell.status` test; not introduced by Plan 03.

**Fix options:**
1. Change `crosswake_shell_status_test.exs` to `async: false` (safest, matches diff test)
2. Use `ExUnit.Callbacks.on_exit/1` to restore CWD after each test in shell.status test
3. Rewrite `run_status/3` to avoid `File.cd!` (pass the tmp_dir as a `--target` flag or cwd override)

**Out of scope for Plan 03** — this is a pre-existing race outside the current task's files.
