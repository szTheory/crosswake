---
phase: 174-clean-room-host-realism-adopter-fidelity
reviewed: 2026-09-18T10:50:22-04:00
depth: standard
files_reviewed: 9
files_reviewed_list:
  - lib/mix/tasks/crosswake.proof_lane.physical_iphone.ex
  - script/verify_companion_cleanroom.sh
  - script/assert_manifest_contract_unchanged.sh
  - .github/workflows/clean-room-proof-rehearsal.yml
  - test/crosswake/proof/phase174_cleanroom_lane_parity_test.exs
  - test/crosswake/proof/phase174_companion_findings_test.exs
  - test/crosswake/proof/phase174_manifest_contract_immutability_test.exs
  - test/crosswake/proof_lane/physical_iphone_report_contract_script_test.exs
  - test/mix/tasks/crosswake.proof_lane.physical_iphone_test.exs
findings:
  critical: 0
  warning: 2
  info: 1
  total: 3
status: issues_found
---

# Phase 174: Code Review Report

**Reviewed:** 2026-09-18T10:50:22-04:00
**Depth:** standard
**Files Reviewed:** 9
**Status:** issues_found

## Summary

Reviewed the phase 174 changes to the physical-iPhone proof-lane exit-status classifier and
`join_reports/3` completeness fix, the clean-room harness realism changes (`script/verify_companion_cleanroom.sh`,
via commit `d04397a4`, which the diff-base range excludes but which the task's own
`<specific_concerns>` named as in scope), the new byte-identity guard
(`script/assert_manifest_contract_unchanged.sh`), the new `clean-room-proof-rehearsal.yml`
workflow, and the accompanying test suite.

This phase's own `174-NON-VACUITY.md` and `deferred-items.md` already record two real, non-trivial
self-caught defects (Finding A: the SC#4 parity test doesn't guard the evidence logs it cites;
Finding B: the new rehearsal workflow's expression-bearing job name broke 9 CI-policy tests,
fixed in `b4ffa989`) plus ROOM-03's genuinely-not-satisfied CI dispatch. Those are not
re-litigated here.

Against the five specific concerns in the task:

1. **`join_reports/3`'s changed completeness check does NOT weaken the contract.** Elixir list
   equality (`Enum.map(report, &Map.take(&1, [:id, :owner])) != Enum.map(expected, ...)`) is
   positional — it still enforces exact ordinal position across the full concatenated
   `device_report ++ backend_report`, not just set membership. Dropping `:outcome` from the
   comparison only routes non-passing-but-complete reports to the (previously unreachable)
   `PI-REPORT-OUTCOME` branch instead of misclassifying them as `PI-REPORT-COMPLETE` — this is
   the intended fix, confirmed correct by tracing `PhysicalIphoneContract.assertions/0`'s ordering
   (all `:device_local` entries precede all `:backend_authority` entries, matching the
   concatenation order). See WR-01 below for a test-coverage gap this concern surfaced.
2. **`exit_status_for/1`'s catch-all is exhaustive for every rule id actually reachable in this
   codebase**, and its inline comment correctly documents the fail-closed intent. See WR-02 below
   for a latent (currently unreachable) gap in the function's own clause coverage.
3. **`script/assert_manifest_contract_unchanged.sh` is sound.** No verdict is taken from a
   pipeline tail; the sole `|| true` on `diff | head -1` is diagnostic-only, appended after the
   verdict-determining `if ! diff -q ...` has already run; `set -euo pipefail` interacts correctly
   with every `$(...)` capture (each risky capture that could legitimately return non-zero is
   deliberately paired with its own `|| true`, and the count is checked explicitly afterward
   rather than inferred from the capture's exit status); the extraction-empty assertions (lines
   113–123) run before either byte-identity comparison (lines 127, 140). No vacuity gap found.
4. **The rehearsal workflow's injection surface is adequately mitigated.** Inputs reach the
   `run:` step only via `env:`-bound shell variables, never interpolated directly into the script
   text; `package` is a closed `type: choice` enum; `version`, `engine_package`, and
   `engine_module` are quoted throughout and, for `version`, validated against a strict semver
   regex (`script/verify_companion_cleanroom.sh` line 852) before ever reaching a generated file.
   `contents: read` is minimal and no secrets are used. `workflow_dispatch` itself already
   requires repository write access to trigger, so this isn't a new privilege boundary.
5. Two known vacuity gaps (Finding A, Finding B/ROOM-03) are already recorded and are not
   re-reported. See WR-01 and IN-01 for gaps this review found that are not already recorded.

No Critical findings. Two Warnings and one Info item below, none of which represent live
incorrect behavior in the shipped code — they are test-coverage and robustness gaps that could
allow a *future* edit to silently regress the guarantees this phase establishes.

## Warnings

### WR-01: No test exercises `join_reports/3`'s ordinal-position enforcement directly

**File:** `test/mix/tasks/crosswake.proof_lane.physical_iphone_test.exs` (whole file, e.g. lines
47–95, 194–263)

**Issue:** The task's own review brief flags `join_reports/3`'s completeness check as the single
highest-risk change in this phase, specifically calling out ordering. The check is in fact still
order-sensitive (confirmed by code trace: Elixir list `!=` is positional), but no test in this
suite constructs a `device_report`/`backend_report` pair that is complete and correctly-owned yet
internally out of canonical order. Every `device_report()`/`backend_report()` test helper builds
its list by filtering `PhysicalIphoneContract.assertions/0`, which preserves canonical order by
construction — so a future edit that swapped the ordinal check for a `MapSet`/set-equality
comparison (silently downgrading "exact set AND order" to "exact set") would pass every test in
this file today. This is exactly the shape of regression the phase's own vacuity-taxonomy
convention exists to catch, and it is currently unguarded.

**Fix:** Add a test that reorders two entries within an otherwise-complete, otherwise-correctly-
owned `device_report()` (e.g. `Enum.reverse/1` on the first two elements) and asserts
`{:blocked, %{rule_id: "PI-REPORT-COMPLETE"}}`:

```elixir
test "a complete, correctly-owned report out of canonical order is rejected as incomplete" do
  reordered_device_report =
    device_report()
    |> List.update_at(0, fn _ -> Enum.at(device_report(), 1) end)
    |> List.update_at(1, fn _ -> Enum.at(device_report(), 0) end)

  assert {:blocked, %{outcome: "blocked", rule_id: "PI-REPORT-COMPLETE"}} =
           PhysicalIphone.run_with(
             ["--run", "--json"],
             ready_options() ++
               [device_report: fn _ -> reordered_device_report end, backend_report: fn _ -> backend_report() end]
           )
end
```

### WR-02: `exit_status_for/1` lacks a true universal catch-all — a non-binary, non-`:readiness_blocked` rule id crashes instead of degrading to 2

**File:** `lib/mix/tasks/crosswake.proof_lane.physical_iphone.ex:108-126`

**Issue:** The function's clauses are: a literal match on `"PI-REPORT-OUTCOME"`, a literal match
on `:readiness_blocked`, and a guard clause `when is_binary(rule_id)` whose `case` body has the
documented catch-all (`_unrecognised -> 2`). That inner catch-all only fires for binaries that
reach the `is_binary(rule_id)` clause — there is no clause at all for a rule id that is neither a
recognized literal, `:readiness_blocked`, nor a binary (e.g. `nil`, an unexpected atom, a map).
Such a value raises `FunctionClauseError` instead of degrading to the documented "could not run"
(2). Since `handle_result/1` doesn't wrap the call in a `rescue`, an uncaught exception here
propagates out of `Mix.Task.run/1`'s call chain in `run/1`, `System.halt/1` is never reached, and
Mix's own crash-exit behavior takes over — typically a non-JSON, non-zero exit that a
status-code-only consumer cannot distinguish from "found a defect" (violating the design intent
stated in the moduledoc and CW-REQ-B). Every current call site (`PhysicalIphonePreflight` and this
module's own internal `{:error, rule}` tuples) only ever supplies hardcoded binary rule ids or the
literal atom `:readiness_blocked`, so this is not reachable today — but the module's own
moduledoc promises "any rule id this module does not otherwise recognise" degrades to 2, and the
function as written does not keep that promise for the full domain of its declared `@spec`
(`String.t() | :readiness_blocked`, which a non-conforming caller could still violate at runtime
since Elixir specs are not enforced).

**Fix:** Add a true catch-all clause so no input to this function can ever crash it:

```elixir
def exit_status_for(_rule_id), do: 2
```
placed as the final clause, after the existing `when is_binary(rule_id)` clause.

## Info

### IN-01: `script/verify_companion_cleanroom.sh`'s new `mix crosswake.install` step (Step 6.5) is not exercised by any of the phase's new automated tests

**File:** `script/verify_companion_cleanroom.sh:1486-1509` (Step 6.5, ROOM-02)

**Issue:** `Crosswake.Proof.Phase174CleanRoomHostRealismTest` asserts marker-roster completeness
and ordering (`install` before `doctor`) against a single committed real-run log
(`evidence/174-legacy-rindle-local-run.log`), but that log is a point-in-time capture, not
something CI re-derives on every run — the script itself only runs post-publish / CI-dispatch
(per its own header comment) and is not otherwise exercised by `mix test`. This is consistent with
the phase's documented scope (ROOM-03 is recorded as NOT satisfied, precisely because no CI run of
the new workflow has happened yet) and is not a new finding beyond what `174-NON-VACUITY.md`
Finding A already discloses about the evidence-log gap — recorded here only because it is a
slightly different angle (the *installer step's own correctness*, not just the marker-parity
measurement, has never been asserted by CI) and should inform whoever executes the ROOM-03
post-merge dispatch: confirm Step 6.5 actually succeeds against a live published package, not just
that its log line appears.

**Fix:** No code change needed now; when the ROOM-03 post-merge dispatch runs
(`gh workflow run clean-room-proof-rehearsal.yml --ref main -f package=crosswake_rindle ...`),
capture and commit the resulting CI log as `evidence/174-rindle-ci-run.log` per the plan already
recorded in `174-NON-VACUITY.md`, and consider adding an assertion (even a manual checklist item)
that Step 6.5's `mix crosswake.install` invocation exits 0 in that log, not just that a `step=install`
marker line is present.

---

_Reviewed: 2026-09-18T10:50:22-04:00_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
