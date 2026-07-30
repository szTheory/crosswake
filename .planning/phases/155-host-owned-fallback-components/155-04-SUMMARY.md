---
phase: 155-host-owned-fallback-components
plan: 04
subsystem: infra
tags: [plug-static, mix-installer, mix-doctor, marker-reconciliation, elixir]

requires:
  - phase: 155-host-owned-fallback-components
    provides: "155-01's Plug.Static block serving /crosswake/tokens.css and crosswake.esm.js, and the endpoint_static_plug_block/1 canonical block whose `only:` list this plan's reconciler diffs against"
provides:
  - "One served tokens.css — the ungated third copy under examples/phoenix_host/priv/static/css/ is deleted, all eight references resolve to /crosswake/tokens.css"
  - "mix crosswake.gen.offline_ui no longer emits a 404'ing ~p\"/assets/tokens.css\" link, and stops copying tokens.css into the host"
  - "Crosswake.Install.Patcher.patch_endpoint/1 reconciles marker CONTENT, not just marker presence — a Phase 154 adopter's stale endpoint block is detected and reported as :marker_stale, never silently rewritten"
  - "mix crosswake.doctor gains native_controls_ui.stamp_drift (:warning, version-integer comparison only) and native_controls_ui.wiring (:advisory, best-effort grep, never fails doctor)"
affects: [155-05, 155-06, 155-07]

tech-stack:
  added: []
  patterns:
    - "Marker-content reconciliation: extract the substring between install markers (inclusive), normalize trailing whitespace per line, compare against the canonical block rendered at the detected indentation. Byte-equal -> reuse action, unchanged. Different -> a distinct :marker_stale action, contents STILL unchanged (report, never rewrite a file the adopter owns)."
    - "Doctor findings that say exactly what they inspected: a stamp-drift finding is a pure template_version integer comparison with a remediation that never suggests regenerating over the adopter's edits (no --force, never will be); a wiring finding is an :advisory best-effort grep worded 'could not find' rather than 'is not wired', mirroring the Phase 154 bridge-hook wiring finding's advisory discipline."

key-files:
  created: []
  modified:
    - lib/crosswake/install/patcher.ex
    - lib/mix/tasks/crosswake.install.ex
    - lib/crosswake/doctor/doctor.ex
    - test/mix/tasks/crosswake_install_test.exs
    - test/crosswake/doctor/doctor_test.exs

key-decisions:
  - "The plan named test/crosswake/install/patcher_test.exs and test/crosswake/doctor_test.exs, neither of which exists in this codebase (same deviation class as 155-02). Extended the real, established files instead: test/mix/tasks/crosswake_install_test.exs and test/crosswake/doctor/doctor_test.exs (module Crosswake.DoctorTest)."
  - "Widened native_controls_ui_findings/1 from private to public (with a @spec) to give it a direct test seam, mirroring the established bridge_hook_wiring_findings/2 pattern where the public combined function is the test entry point and its private stamp/wiring helpers stay unexported."

requirements-completed: [FALL-01]

coverage:
  - id: D1
    description: "Exactly one served tokens.css — the ungated third copy is deleted, all eight references in the example host resolve to /crosswake/tokens.css, and the generated offline layout no longer links a 404"
    requirement: FALL-01
    verification:
      - kind: unit
        ref: "grep acceptance criteria (file absence, reference counts, unused-function check) — see Verification below"
        status: pass
      - kind: integration
        ref: "mix compile --warnings-as-errors (root) and examples/phoenix_host mix compile --warnings-as-errors"
        status: pass
    human_judgment: false
  - id: D2
    description: "Crosswake.Install.Patcher reconciles endpoint marker CONTENT so a Phase 154 adopter running mix crosswake.install is told their endpoint is stale, without the reconciler ever rewriting the adopter-owned file"
    requirement: FALL-01
    verification:
      - kind: unit
        ref: "test/mix/tasks/crosswake_install_test.exs#describe \"endpoint marker content reconciliation (D-52)\""
        status: pass
    human_judgment: false
  - id: D3
    description: "mix crosswake.doctor carries native_controls_ui.stamp_drift (:warning, integer-only comparison) and native_controls_ui.wiring (:advisory, best-effort grep, never fails doctor's exit code)"
    requirement: FALL-01
    verification:
      - kind: unit
        ref: "test/crosswake/doctor/doctor_test.exs#describe \"native controls ui findings\""
        status: pass
    human_judgment: false

duration: ~2h (across a paused/resumed session; Task 1 committed 2026-07-30T11:24:45-04:00, this session's audit+test+commit work completed 2026-07-30T13:17:49-04:00)
completed: 2026-07-30
status: complete
---

# Phase 155 Plan 04: One served tokens.css and a reconciling installer Summary

**Deleted the ungated stray tokens.css copy and fixed the generated offline_ui 404, then made `Crosswake.Install.Patcher` diff marker CONTENT (not just marker presence) so Phase 154 adopters are told their endpoint block is stale, plus two doctor findings (version-integer stamp drift and advisory grep-based wiring) that never overclaim what they inspected.**

## Performance

- **Duration:** ~2h across a paused/resumed session (see frontmatter)
- **Tasks:** 2 (Task 1 pre-committed as `79e2c638` before this session started; Task 2 audited, corrected, tested, and committed this session)
- **Files modified this session:** 5 (`lib/crosswake/install/patcher.ex`, `lib/mix/tasks/crosswake.install.ex`, `lib/crosswake/doctor/doctor.ex`, `test/mix/tasks/crosswake_install_test.exs`, `test/crosswake/doctor/doctor_test.exs`)

## Accomplishments

- Re-verified Task 1's acceptance criteria still hold (all greps pass, `mix compile --warnings-as-errors` clean at repo root and in `examples/phoenix_host`, `node brandbook/tools/check-consumer-drift.mjs` exits 0).
- Audited the uncommitted Task 2 implementation against the plan's `<behavior>`, `<action>`, `<acceptance_criteria>`, and `<threat_model>` — found it correct and matching every requirement (byte-equal reuse, stale-without-rewrite, no-marker patch path unchanged, second `marker_reused` site at `ensure_install_block/2` untouched, stamp remediation never tells the adopter to regenerate over their edits, wiring finding is `:advisory` and says "could not find").
- Wrote the missing test coverage for both the patcher reconciliation behavior and the two doctor findings, extending the real established test files (see Deviations).
- Ran all specified gates and confirmed green (module-scoped and full-suite, modulo the documented pre-existing unrelated warning failure).

## Task Commits

Task 1 was committed in a prior session:

1. **Task 1: One served tokens.css — retire the stray copy and fix the generated 404** - `79e2c638` (feat)

This session:

2. **Task 2: Reconcile stale marker blocks and add two honest doctor findings** - `e086a079` (feat)

## Files Created/Modified

- `lib/crosswake/install/patcher.ex` - `ensure_endpoint_block/1` now extracts and normalizes the existing marker body, compares it against `endpoint_static_plug_block/1` rendered at the detected indentation; byte-equal returns `:marker_reused` unchanged, different returns `{:ok, contents, [:marker_stale]}` with `contents` unmodified. `:marker_stale` added to the `patch_action()` typespec. New private helpers `extract_marker_block/1` and `normalize_block/1`. The second `marker_reused` site (`ensure_install_block/2`, the router block) is untouched, exactly as the plan required.
- `lib/mix/tasks/crosswake.install.ex` - `patch_endpoint/2` appends a printed notice (`stale_endpoint_block_notice/0`) with the canonical replacement block whenever `:marker_stale` is in the result actions. Never auto-applied.
- `lib/crosswake/doctor/doctor.ex` - New `native_controls_ui_findings/1` (now `def`, was `defp` in the uncommitted diff) combining `native_controls_ui_stamp_findings/1` (private, `:warning`, reads `template_version=` integer and compares against `Mix.Tasks.Crosswake.Gen.NativeControlsUi.template_version/0`) and `native_controls_ui_wiring_findings/1` (private, `:advisory`, best-effort grep over `lib/**/*.ex` for a reference to the generated module name). Wired into `Doctor.run/1`'s finding pipeline as `phase_155_findings`.
- `test/mix/tasks/crosswake_install_test.exs` - New `describe "endpoint marker content reconciliation (D-52)"` block with four tests: byte-equal marker body returns `:marker_reused` unchanged; the concrete pre-155 `only: ~w(crosswake.esm.js)` fixture is detected `:marker_stale` with contents left byte-equal to input; a marker-less endpoint is patched exactly as before; and a Mix.Task-level test asserting `mix crosswake.install` prints the stale notice with the canonical replacement text while leaving the file untouched.
- `test/crosswake/doctor/doctor_test.exs` - New `describe "native controls ui findings"` block with five tests: matching-stamp negative control (zero stamp-drift findings), a lower-stamp component fixture producing a `:warning` finding naming the file and both versions with a remediation asserting `"no --force"` / `"apply by hand"` and refuting `"regenerate the file"`, a lower-stamp stylesheet fixture proving both generated globs are covered, an unreferenced-component fixture producing the `:advisory` wiring finding worded `"could not find"` (never `"is not wired"`), and an explicit assertion that the wiring finding never carries `:error` severity.

## Decisions Made

- **Test-path deviation (same class as 155-02):** the plan named `test/crosswake/install/patcher_test.exs` and `test/crosswake/doctor_test.exs`, neither of which exists — there is no `test/crosswake/install/` directory at all. Extended the real, established files instead: `test/mix/tasks/crosswake_install_test.exs` (which already covers `Crosswake.Install.Patcher` behavior through both direct module calls and `Mix.Task.run/2` integration) and `test/crosswake/doctor/doctor_test.exs` (module `Crosswake.DoctorTest`, which already covers `Doctor.bridge_hook_wiring_findings/2` directly).
- **`native_controls_ui_findings/1` widened from private to public.** The plan's action text describes `native_controls_stamp_findings/1` as private, and the uncommitted implementation kept the combining wrapper (`native_controls_ui_findings/1`) private too. To give the doctor findings a direct test seam without constructing the full heavyweight `Doctor.run/1` fixture (router source, install manifest, shell proof hooks, etc. — see the ~100-line `setup` block earlier in the same test file), I exposed the combining function as `def` with a `@spec`, exactly mirroring how `bridge_hook_wiring_findings/2` is the public, directly-tested entry point while its own private `ejected_hook_stamp_findings/1` stays unexported. This is a minimal, established-pattern-following change, not a new architectural surface.

## Deviations from Plan

### Auto-fixed Issues

None — the uncommitted Task 2 implementation, on audit, already matched the plan's `<behavior>`, `<action>`, `<acceptance_criteria>`, and `<threat_model>` requirements exactly. No Rule 1/2/3 fixes were needed to the implementation itself.

**1. [Rule 3 - Blocking] Corrected the plan's phantom test file paths**
- **Found during:** Task 2 (writing the missing test coverage)
- **Issue:** The plan's `<files>` list and `must_haves.artifacts` named `test/crosswake/install/patcher_test.exs` and `test/crosswake/doctor_test.exs`. Neither exists; there is no `test/crosswake/install/` directory anywhere in the tree.
- **Fix:** Extended the real, established files (`test/mix/tasks/crosswake_install_test.exs`, `test/crosswake/doctor/doctor_test.exs`) instead of creating phantom paths that would duplicate existing conventions.
- **Files modified:** `test/mix/tasks/crosswake_install_test.exs`, `test/crosswake/doctor/doctor_test.exs`
- **Verification:** All acceptance-criteria greps target file content and function shapes, not the specific test file path, so they pass unchanged against the real files.
- **Committed in:** `e086a079` (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (blocking — phantom path correction), same class as the deviation 155-02 hit.
**Impact on plan:** No scope creep. The substance of every acceptance criterion is met against the real test files.

## Issues Encountered

None beyond the documented pre-existing `mix test --warnings-as-errors` full-suite abort (see Verification below), which is out of scope for this plan and untouched by these changes.

## Verification

Ran and confirmed:

```
$ mix test test/mix/tasks/crosswake_install_test.exs test/crosswake/doctor/doctor_test.exs test/mix/tasks/crosswake_doctor_test.exs --warnings-as-errors
Finished in 2.0 seconds (1.8s async, 0.1s sync)
63 tests, 0 failures
```

```
$ mix compile --warnings-as-errors   # repo root
Compiling 1 file (.ex)
Generated crosswake app
```

Task 2 acceptance-criteria greps, verbatim, actual output:

| Criterion | Result |
|---|---|
| `mix test test/crosswake/install/patcher_test.exs test/crosswake/doctor_test.exs --warnings-as-errors` exits 0 | Path does not exist (deviation) — real-file equivalent above exits 0, 63 tests, 0 failures |
| `grep -c 'marker_stale' lib/crosswake/install/patcher.ex` at least 2 | **3** |
| `sed -n '/defp ensure_endpoint_block/,/^  end/p' ... \| grep -c 'endpoint_static_plug_block'` at least 2 | **2** |
| Patcher test fixture with `only: ~w(crosswake.esm.js)` asserting `:marker_stale` | Present (`test/mix/tasks/crosswake_install_test.exs`) |
| Patcher test asserts stale-block returned contents byte-equal to input | Present (three separate `File.read!(endpoint_path) == contents` assertions) |
| `grep -c 'native_controls_ui.stamp_drift' lib/crosswake/doctor/doctor.ex` at least 1 | **2** |
| `grep -c 'native_controls_ui.wiring' lib/crosswake/doctor/doctor.ex` at least 1 | **6** |
| `sed -n '/native_controls_ui.wiring/,+6p' ... \| grep -c ':advisory'` at least 1 | **1** |
| Doctor test includes matching-stamp negative control asserting zero stamp-drift findings | Present (`"a stamp matching the current template_version produces no drift finding (negative control)"`) |
| `mix test --warnings-as-errors` (full core suite) exits 0 | **Fails** — see below, pre-existing and out of scope |

Full suite, for failure count:

```
$ mix test
Finished in 64.0 seconds (41.7s async, 22.3s sync)
1279 tests, 0 failures (73 excluded)
```

```
$ mix test --warnings-as-errors
Finished in 62.0 seconds (43.2s async, 18.8s sync)
1279 tests, 0 failures (73 excluded)

ERROR! Test suite aborted after successful execution due to warnings while using the --warnings-as-errors option
```

This abort is the documented pre-existing, out-of-scope issue: confirmed via `mix test --warnings-as-errors 2>&1 | grep -A3 "warning: variable ... comparison between distinct types ... Rulestead.validate_dependency"` that every warning traces to `test/crosswake/offline/proof_lane_test.exs`, `test/crosswake/doctor/doctor_threadline_test.exs`, and `test/crosswake/proof/phase43_rulestead_advisory_test.exs` — none of which this plan touches. Zero test failures either way (1279 tests, 0 failures, both runs). Not fixed, per the task brief.

Task 1 acceptance criteria re-verified (all cheap greps + compiles, all still pass):

```
$ test -e examples/phoenix_host/priv/static/css/tokens.css; echo $?
1
$ grep -rn '/css/tokens.css' examples/phoenix_host/lib; echo $?
1
$ grep -rc '/crosswake/tokens.css' examples/phoenix_host/lib | awk -F: '{s+=$2} END {print s}'
8
$ grep -c 'assets/tokens.css' priv/templates/crosswake/offline_ui/offline_root.html.heex.eex
0
$ grep -c 'tokens.css' lib/mix/tasks/crosswake.gen.offline_ui.ex
2
$ grep -c 'tokens_css_dest' lib/mix/tasks/crosswake.gen.offline_ui.ex
0
$ mix compile --warnings-as-errors  # repo root — clean
$ (cd examples/phoenix_host && mix compile --warnings-as-errors)  # clean
$ node brandbook/tools/check-consumer-drift.mjs
All 7 consumer file(s) passed drift check.
```

(Playwright's full unfiltered suite was not re-run this session — Task 1 is already committed and its file-level/compile-level acceptance criteria are the cheap re-verification the task brief asked for.)

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- 155-05, 155-06, 155-07 can proceed; `Crosswake.Install.Patcher` and `Crosswake.Doctor` now carry the reconciliation and finding surfaces this plan's `key_links` promised.
- No blockers. The pre-existing `mix test --warnings-as-errors` full-suite abort (unrelated test files) remains open and out of scope, as documented in prior 155-0x summaries' handoff notes.

## Self-Check: PASSED

All files confirmed present (`lib/crosswake/install/patcher.ex`, `lib/mix/tasks/crosswake.install.ex`, `lib/crosswake/doctor/doctor.ex`, `test/mix/tasks/crosswake_install_test.exs`, `test/crosswake/doctor/doctor_test.exs`). Both commit hashes confirmed present in git log (`e086a079`, `79e2c638`).

---
*Phase: 155-host-owned-fallback-components*
*Completed: 2026-07-30*
