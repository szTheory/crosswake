---
phase: 186-host-seam-and-harness-honesty
plan: 02
status: complete
requirements: [SEAM-07, SEAM-09]
commits: 0
plan_head_before: 25614cf685e2ee299646e04b833293c677023c45
plan_head_after: 25614cf685e2ee299646e04b833293c677023c45
actuals:
  tasks: 3
  commits: 0
---

# Phase 186 Plan 02: Legacy-manifest denial in the native session, guides and changelog Summary

A manifest route with no `host_commands` field now grants no host command in the iOS shell session. Each host command it declares, and on the entry route each one the activation carries, is denied with the existing reasons and recorded as a diagnostic. The guides and changelog say so. All edits are uncommitted in the candidate (186-05 commits), so `commits: 0` is intentional.

## What was built

- `ActivationCoordinator.grantHostCommands` legacy branch now returns no grants plus denials. Every `host.*` name in `route.capabilities` gets `not_registered`. On the entry route, every `host.*` key of the request overrides that: `version_unsupported` if `HostCommandSeam.supportsCommandVersion` fails, else `not_registered`. A name in both places yields one denial. Comments updated (also the one near the navigation resolver). No reason string, session field or public declaration changed.
- `HostCommandNavigationTests`: entry test renamed and flipped, `lacking_the_command` extended, three new tests (version, unregistered with diagnostic, plain route as control).
- `Phase180TwinFeasibilityTests`: `makeManifest` gained optional `allowlistedOrigin` and `hostCommands`. The G3 control now declares the command on its route.
- `native_shell_upgrade.md`: legacy row and paragraph replaced (denial, `host_commands_legacy_manifest`, repair `mix crosswake.gen.shell ios`, no compatibility window); doctor sentence names `host_commands_legacy_manifest` and the advisory `host_commands_stale_skipped`.
- `compatibility.md`: the "refuses to activate" sentence replaced by the floor wording (route still activates; each declared command denied with `seam_unsupported` when the shell's seam is lower).
- `CHANGELOG.md`: bullet "* **Legacy-manifest denial (iOS shell, not released).**" after the Host-command seam bullet (which stays the first regex match).
- `host_command_seam_guide_test.exs`: upgrade test renamed with new needles and a refute of the old phrase; two new tests (compatibility floor, changelog bullet).

## Verification

| Step | Result |
|------|--------|
| Swift baseline (before any Swift edit) | 86 tests, 2 skipped, 1 failure: only `Phase180TwinFeasibilityTests.test_G4_gate_bounded_shell_denies_offline_island_runtime` (`swift-baseline-186.failures`) |
| Swift red (`--filter HostCommandNavigationTests`, old code) | 4 failing: renamed entry test, lacking-command, version, unregistered; plain test passed as control |
| Swift green after fix, full run | 89 tests, failing set equals baseline (G4 only) |
| G3 control with `PHASE180_EXPORT_DIR` at the tracked example Fixtures | red run: failed; green run: control and gate both passed, G3 not in failing set (`swift-186-02.g3.out`) |
| Final full Swift run (`swift-186-02.out`) | failing set equals baseline; 89 tests |
| Guides red | exit 2, the three named tests failed |
| Guides green (10 paths) | exit 0, 285 tests, 0 failures; docs sync --check exit 0; format check exit 0 |

Evidence is in /private/tmp/crosswake-phase180-run (names as in the plan). No home path appears in any 186-02 file.

## Deviations from Plan

1. **[Rule 1 - plan arithmetic] Test count threshold.** The plan's "at least 90 tests executed" cannot be met: baseline 86 plus the plan's three new tests is 89. The Task 1 and Task 2 verify commands' `Executed (9[0-9]...)` clause therefore does not match. Every other clause holds (failing set equals baseline, 89 executed with all new tests running). Orchestrator and 186-05 should use 89 as the Swift test count.
2. **[Rule 1 - bug in a CI-skipped test] G3 red was for the wrong reason.** With the tracked example export, the control (and the G3 gate test) failed with `originDenied`, not because of D-01: the export's origin is `http://127.0.0.1:4790` while `makeManifest` hard-coded `study.crosswake.test`. I made `makeManifest` take the request's origin for both G3 export tests, and the control declares the command. Result: both pass against the export. The G3 control was therefore never demonstrated red on the grant alone; the four Navigation tests are the D-01 red evidence. The G3 gate test was touched only for the origin fix (its assertion is unchanged).
3. **Guide test needle.** The compatibility needle is "The route still activates" (capitalised, sentence start) instead of the lowercase form I first wrote; one red-then-fixed iteration.
4. `HostCommandSeamTests.swift` needed no change (no legacy assertion pinned a grant).

## Notes for 186-03..05

- Swift mutation target for 186-05: the legacy branch of `grantHostCommands` (revert to the old grant, or drop the `supportsCommandVersion` check); the four Navigation tests should go red.
- Candidate now has 186-02 paths modified: ActivationCoordinator.swift, HostCommandNavigationTests.swift, Phase180TwinFeasibilityTests.swift, CHANGELOG.md, guides/compatibility.md, guides/native_shell_upgrade.md, host_command_seam_guide_test.exs, besides 186-01's.
- Pre-existing G4 failure is out of scope and deferred (orchestrator decision 3).
- No STATE/ROADMAP/REQUIREMENTS writes; no git staging or commits.

## Known Stubs

None.

## Self-Check: PASSED
