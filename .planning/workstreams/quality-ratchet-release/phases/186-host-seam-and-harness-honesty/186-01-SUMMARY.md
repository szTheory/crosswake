---
phase: 186-host-seam-and-harness-honesty
plan: 01
status: complete
requirements: [SEAM-07, SEAM-08, SEAM-09]
commits: 0
plan_head_before: 25614cf685e2ee299646e04b833293c677023c45
plan_head_after: 25614cf685e2ee299646e04b833293c677023c45
actuals:
  tasks: 3
  commits: 0
---

# Phase 186 Plan 01: Doctor stale check, legacy finding, path redaction Summary

Doctor now reports instead of passing when it cannot read or decode the generated iOS fixture, names a legacy fixture route with its repair, and every package path in doctor, the generation gate and the raised gen.shell text is project-relative or a placeholder. All edits are uncommitted in the candidate (186-05 commits); no commit was made in this plan, so `commits: 0` is intentional.

## What was built

- `Doctor.stale_host_command_findings/3`: one `host_commands_stale` error with `details.reason` of `unreadable` (plus `error` as the posix atom string), `malformed` (private `generated_routes/1` validator) or `route_missing`; the version-mismatch finding is unchanged. An absent fixture with a declaring router is an `:advisory` `host_commands_stale_skipped`; absent with a non-declaring router gives nothing.
- `host_commands_legacy_manifest`: fixture routes with no `host_commands` key. One finding per severity (`:error` for routes the router declares on, `:warning` for the rest), `route_ids` sorted, hint "Run mix crosswake.gen.shell ios". The stale comparison skips these routes (research assumption A4: grouped, at most one per severity).
- `ShellPackage.display_location/2` (`@doc false`): bounded (32 hops) symlink canonicalization, component-wise containment, `.` for root, `<home>/...`, `<outside project>`, `remote ...` unchanged, no raw-input clause.
- Callers redacted: doctor `shell_unsupported_finding/6` (message and `details.package_location`), `IOSHostGeneration.shell_gate/3` (new `:project_root` option, default `File.cwd!()`), and `gen.shell` passing `project_root: File.cwd!()` so the raised `Mix.Error` text is redacted. No other site prints a package location (grep found none). The "the managed project" label bypasses the helper.

## Verification (all run from the candidate, private build paths)

| Task | Red (old code) | Green |
|------|----------------|-------|
| 1 doctor | `red-186-01-t1.out`: exit 2, 14 tests, 6 failures (the six named new tests; controls passed) | `t1-186-01.out`: 14 tests, 0 failures |
| 2 helper | `red-186-01-t2.out`: exit 2, 16 tests, 8 failures (all display_location tests) | `t2-186-01.out`: 16 tests, 0 failures |
| 3 sentinel | `red-186-01-t3.out`: exit 2, 4 tests, 4 failures (assertions on the redacted text) | `green-186-01.out`: 77 tests, 0 failures (six files incl. gate, gen.shell, origin-mode) |

Also: `mix compile --force --warnings-as-errors` exit 0 (`compile-186-01.exit`), `mix format --check-formatted` on all changed files exit 0 (`format-186-01.exit`), mix.exs/mix.lock unchanged, candidate HEAD still 25614cf6, only this plan's seven paths modified or added (`status-186-01.txt`). All evidence is in /private/tmp/crosswake-phase180-run.

## Deviations from Plan

- None in behavior. `red-186-01-t2.out` contained the home path (a toolchain path); it was replaced with `<home>` in that file. A final grep of this plan's evidence files for the home path finds nothing.
- The existing gate test and gen.shell test files needed no change (their assertions never used absolute locations); `ios_host_generation_host_commands_test.exs` and `crosswake_gen_shell_host_commands_test.exs` are untouched.
- Plan files_modified listed them, but they are not modified, so the candidate diff has seven paths, not nine.

## Known Stubs

None.

## Notes for 186-02 and later

- All Phase 186 doctor.ex edits (D-02, D-04, D-05, D-07 doctor side) are done here (D-18); do not touch doctor.ex again in 186.
- Two reserved attribute names now exist in doctor.ex: `@generated_manifest_rel` and `@regenerate_hint`.
- The two backstop truths (Unicode normalization form, symlink change during the call) have no dedicated test by plan design; the helper has no raw-input return path.
- 186-05 mutation targets: `generated_routes/1`, the `{:error, :enoent}` / `{:error, posix}` branches, `legacy_finding/2`, `display_location/2` home/inside branches, `Keyword.get_lazy(opts, :project_root, ...)` in `ios_host_generation.ex`, and `project_root: File.cwd!()` in `gen.shell.ex`.

## Self-Check: PASSED
