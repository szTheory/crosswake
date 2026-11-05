---
phase: 197-public-docs-truth
plan: 06
subsystem: release-tooling
tags: [cleanroom, docs-leg, apply-blocks, substitution-table, harness-compile, d-01, d-02]

requires:
  - phase: 197-public-docs-truth
    provides: "197-05 Hex tarball docs source; 197-04 marker parser, pinned phx_new host, scrubbed-env run-block executor"
provides:
  - "script/verify_published_cleanroom.sh: docs_subst (fixed substitution table), docs_apply_step with six modes (create, append, deps, esbuild-args, js-hook, router-route), harness compile step, parse-time apply and doctor validation"
  - "published_cleanroom_test.exs: Phoenix-shaped host skeleton in the mix stub, configurable compile output and exit, hermetic tests per mode (result text, idempotence, anchor removal, target_missing)"
affects: [197-07, 197-09, 197-13, 197-14, 199]

actuals:
  tokens: 8900
  tasks: 2
  commits: 2
plan_head_before: 681bbe8877ea2f04a38c3d13570d9c1e9006f1c2
plan_head_after: b11bd0547b94a0fc19043f8979e943861adb1756

tech-stack:
  added: []
  patterns:
    - "One awk program per apply mode, written to a work-dir temp file and copied over the host file only on exit 0, so an anchor failure never leaves a half-edited host"
    - "Per-mode target rule checked once in docs_apply_step; each mode function returns 0, 3 (anchor_missing) or 5 (exists)"
    - "Stub host skeleton edited between stub creation and the run to remove one anchor (each edit asserted to change the file)"

key-files:
  created: []
  modified:
    - script/verify_published_cleanroom.sh
    - test/crosswake/release/published_cleanroom_test.exs

key-decisions:
  - "Apply-block structure (mode, file, bad_path) and the doctor-run-block requirement are checked in docs_validate right after parsing, before any host is built; docs_apply_step re-checks the path as defense in depth."
  - "`compile_warning` prints the leg-written host path (for example `mix.exs`), not the doc path: the plan's artifact table says `<file>` is the doc path, its task text says `<path>` of the written file. The written path is the actionable one; `required_step doctor` keeps the doc path as the table says."
  - "Apply blocks count in `executed`, as does each harness `compile` step (a file with a doctor block executes its runs, any apply blocks and one compile)."
  - "The router-route scope is bounded by the first `end` at the scope line's indentation, so a `pipe_through :browser` in a later scope is not the anchor (proven by a control test)."
  - "A timeout flag is now a non-empty file truncated before each bounded run, because the compile step id is used once per doc file and a leftover flag would have mislabelled the second compile as a timeout."

patterns-established:
  - "Extra reason words beyond the plan, all fail-closed: `parse missing_file`, `apply <id> empty_body`, `apply <id> write_failed`, `apply <id> subst_failed`."

requirements-completed: []

duration: 75min
completed: 2026-11-05
status: complete
---

# Phase 197 Plan 06: Apply blocks and harness compile in the docs leg Summary

**The docs leg now executes `apply` blocks: a fixed substitution table maps the documented `my_app`/`MyApp` names and the `{:crosswake, "~> 0.2"}` requirement onto the throwaway host and the version under test, six idempotent modes (`create`, `append`, `deps`, `esbuild-args`, `js-hook`, `router-route`) inject the fragment into the named host file under their own failure rules, and a harness `mix compile` runs before each file's doctor block and fails on a non-zero exit or on a warning located in a file an apply block wrote.**

## Accomplishments

- Task 1 (tracer, `d6493045`): `docs_subst` (longest key first: `my_app_web`, `MyAppWeb`, `my_app`, `MyApp`, then the exact dependency tuple pinned to `== $VERSION`) applies to apply bodies and `file=` values only; run blocks stay verbatim. `docs_validate` rejects an apply with no `mode=` (`parse missing_mode`), an unknown one (`parse unknown_mode`), no `file=` (`parse missing_file`) and an absolute or `..` path (`parse bad_path`) before any host is built, and fails `required_step doctor <file>` for a doc file with no `mix crosswake.doctor` run block. `docs_apply_step` holds the per-mode target rule once (every mode but `create` needs its file, else `target_missing`). `deps` inserts absent tuples right after `defp deps do` and its `[` line. `docs_compile` runs `mix compile` under `docs_env` and `docs_bounded` as step `compile` before the first doctor run block of each file, output in `$WORK/docs-compile-<tag>.log`. `apply_unsupported` is gone from the script (0 occurrences).
- Task 2 (`b11bd054`): the five remaining modes in bash plus awk, no new dependency beyond `cat` and `cmp` added to the docs `need_tools` list. `create` writes new files and parents inside the host, an identical existing file is a no-op, a different one is `exists`. `append` is skipped when the exact body is already present. `esbuild-args` adds absent `--` tokens to the first `~w(js/app.js ...)` sigil (a `--name=value` is skipped when `--name=` exists, `--external:<v>` compares whole, a trailing `)` on a copied sigil is stripped). `js-hook` prepends absent import lines and puts `CrosswakeBridge, ` after the first `hooks: {` unless that object already names it. `router-route` inserts absent body lines, indented like the anchor, after the first `pipe_through :browser` inside the first `scope "/", ` block.
- Tests (hermetic, 87 in the file, was 61): the mix stub's `phx.new` now copies a Phoenix-shaped skeleton (deps list, esbuild sigil, LiveSocket hooks, router scope) and its `compile` prints `compile_out` and exits `compile_exit`. Per mode: result text, idempotent double apply, anchor removal on a changed copy of the skeleton (each edit asserted to change the file), the router later-scope control, one `target_missing` case each for the four anchored modes and `append`, `exists` for `create`, parse errors for missing and unknown mode and missing file, `bad_path` for `../x`, `/etc/x` and an absolute path (nothing written), `compile_warning` in a leg-written file, a foreign-file warning and a path-suffix lookalike that pass, a non-zero compile exit that stops the file before its doctor, and `required_step doctor` for each of the two files.
- Mutation control run by hand: turning the router scope-end detection off (`end` to `endx`) turned the later-scope test red; restored before the commit.

## Task Commits

1. Task 1: tracer, deps apply, substitution table, compile step: `d6493045` (feat)
2. Task 2: the five remaining apply modes: `b11bd054` (feat)

## Verification Run

- `published_cleanroom_test.exs` through `script/mix_test_gate.sh`: 71 tests PASS after Task 1 (floor 47), 87 tests PASS after Task 2 (floor 54).
- `test/crosswake/proof/absence_is_not_success_test.exs`: 59 tests PASS (floor 59). It failed once mid-task: a `refute Enum.any?(lines, ...)` in a new test was counted as a new `unsafe_collection` finding; replaced with string refutes on the output.
- `mix format --check-formatted` clean on the changed test file; `bash -n` clean.
- Acceptance greps: `apply_unsupported` 0, `esbuild-args|js-hook|router-route` 5 (at least 3), `target_missing` 3 (at least 1); `git log --format=%H origin/main..HEAD -- .planning/config.json` prints nothing.
- Privacy scan (`privacy-193.sh` through bash, absolute paths) over both changed files: clean, exit 0, before each commit. No push was made.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Compile step shares one id across two doc files**
- **Found during:** Task 1
- **Issue:** the timeout flag file was keyed on the step id and tested with `-e`; the `compile` step runs once per doc file, so a flag left by the first would have labelled the second a timeout.
- **Fix:** the flag is truncated before each bounded run, the watchdog writes into it, and the check is `-s`.
- **Commit:** `d6493045`

**2. [Rule 1 - Bug] esbuild sigil copied whole from the docs left a stray parenthesis**
- **Found during:** Task 2
- **Issue:** a copied `~w(... --format=esm)` made `--format=esm)` a token, so the host line ended `))`.
- **Fix:** trailing `)` is stripped from body tokens.
- **Commit:** `b11bd054`

**3. [Rule 3 - Blocking] awk regex `"[/]"` does not parse on macOS awk**
- **Fix:** the scope line is matched with `substr(trim($0), 1, 10) == "scope \"/\","`.
- **Commit:** `b11bd054`

**4. [Process] Existing fixtures changed because the doctor requirement is now enforced**
- The README fixture gained a doctor run block, the stuck-step fixture gained one, the D-07a mutation now appends a failing `mix crosswake.no_such_task` after the doctor line (replacing the text would now be `required_step doctor`), `executed=5` became `executed=8` (two compile steps and the README doctor), and the old "apply is not yet supported" test was replaced by the apply tests.

**5. [Process] Reason words beyond the plan** (`parse missing_file`, `apply <id> empty_body`, `write_failed`, `subst_failed`) so that an apply with no file, an empty body or an unwritable target cannot pass silently. The `compile_warning` argument choice is recorded under key decisions.

## Known Stubs

None. (The test stub `mix` is hermetic test infrastructure, not shipped behaviour.)

## Threat Flags

None. T-197-14 is mitigated: absolute and `..` paths are `parse bad_path` before any host is built and again before each write, with three hermetic cases proving nothing is written. No new dependency (T-197-SC-06).

## Requirement status

DOCS-01 is carried by this plan but is not marked complete: 197-07 and later plans also carry it.

## Not yet proven

The apply modes were proven against the stub skeleton, not a real generated Phoenix 1.8 host, and the real README and guide carry no `apply` markers yet; wiring the real docs and a real-host run belongs to the later plans (197-09 onward).

## Self-Check: PASSED

- FOUND: script/verify_published_cleanroom.sh, test/crosswake/release/published_cleanroom_test.exs
- FOUND commits: `d6493045`, `b11bd054` (ancestors of HEAD); `commits: 2` measured from ledger base `681bbe88`; no file deletions
