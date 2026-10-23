---
phase: 186-host-seam-and-harness-honesty
plan: 03
status: complete
requirements: [LOOP-06]
commits: 0
plan_head_before: 25614cf685e2ee299646e04b833293c677023c45
plan_head_after: 25614cf685e2ee299646e04b833293c677023c45
actuals:
  tasks: 3
  commits: 0
---

# Phase 186 Plan 03: Loopback harness cannot pass after its own failure Summary

The loopback Simulator harness now blocks (exit 2) when its own cleanup, generated-file check or evidence write fails, and 15 shimmed cases prove each path. All edits are uncommitted in the candidate (186-05 commits), so `commits: 0` is intentional. The real harness, a Simulator, xcodebuild and the twin were never run.

## What was built

- `script/verify_loopback_origin_simulator.sh`:
  - Bundle id read uses `plutil -extract CFBundleIdentifier raw` (no Apple-only tool).
  - `cleanup_and_emit` downgrades a passed run to blocked (exit 2, `LOOP-IOS-CLEANUP`) when the uninstall failed or the device was not left Shutdown. It sets the fields directly, never through `block`.
  - The restored-state check and the assertion-membership check use captured output and bash pattern tests, not a piped quiet grep. The unused `local rc` is gone.
  - `tree_hashes` (find -print0, `LC_ALL=C sort -z`, per-file shasum) and `compare_tree_hashes` (python3 helper) are used at three points: before the swap (H0), after the build (H1), and in the exit trap (H2). Only `CrosswakeShell/CrosswakeShellApp.swift` may change, and its hash must equal ProbeApp.swift's and differ from H0. An empty H0, a removed file, or an addition outside the allow-list fails. Rule id: `LOOP-IOS-OWNED-HASH`, causes name project-relative paths.
  - Evidence precheck right after the trap: path made absolute against the invoking directory; a directory, a missing parent or an unwritable parent ends blocked with `LOOP-IOS-EVIDENCE` before any build. At exit the JSON goes to `EVIDENCE.tmp.PID` and is moved into place with `mv -f`, both checked. A failure removes the temp file; a passed run becomes blocked (exit 2), an already-failed run keeps its exit code and gains `LOOP-IOS-EVIDENCE`. stdout JSON is printed once, after the write.
  - `add_rule` keeps rule ids unique.
- `test/crosswake/proof_lane/loopback_origin_harness_test.exs` (new): 15 tests with the exact interface names; shims for mix, xcodebuild, plutil, xcrun, mv, plus a shasum shim only if `shasum` is missing; mode variable `CROSSWAKE_LOOP_SHIM_MODE` (comma list allowed, used for the composed case), state variable `CROSSWAKE_LOOP_SHIM_STATE`. The suite copies the script and helpers from the repository root it lives in, into a committed temp clone; shim state, TMPDIR and evidence stay outside the clone. Every case checks exit code against outcome, expected rule id, no sentinel directory name or home path in stdout or evidence, and no leftover run directory.
- `guides/native_shell.md`: one paragraph after the loopback paragraph (command, exits `0`/`2`/`3`, "manually run phase evidence, not a CI lane"). `loopback_origin_guide_test.exs` pins it.

## Verification (exit status, evidence in /private/tmp/crosswake-phase180-run)

| Step | Result |
|------|--------|
| Red 1 (plutil change only), `red-186-03-t1.out` | exit 2, 4 tests 3 failures: baseline passed (shims faithful); uninstall, not-restored and long-list cases failed |
| Red 1b (cleanup downgrade added), `red-186-03-t1b.out` | exit 2, 4 tests 1 failure: only the long-list case (pipefail false negative reproduced with a 200000-line list) |
| Green task 1, `t1-186-03.out` | exit 0, 4 tests 0 failures |
| Red 2, `red-186-03-t2.out` | exit 2, 15 tests 10 failures: all nine named cases plus the relative-path case; the byproducts case passed (allowed already by the old script) |
| Green task 2, `green-186-03.out` | exit 0, 15 tests 0 failures |
| Guide red, `guide-186-03.red.out` | exit 2, the new test failed |
| `guides-186-03.out` (test/crosswake/guides plus harness) | exit 0, 215 tests 0 failures (7 excluded) |
| docs sync --check, format check, bash -n | all exit 0 |
| The three plan `<automated>` verify commands | all exit 0 |

## Notes

- Build-addition allow-list: `CrosswakeShell.xcodeproj/project.xcworkspace/` and `CrosswakeShell.xcodeproj/xcuserdata/` only. This is an assumption (research A2); Phase 188's real Simulator run must confirm it, and the script comment says so.
- The `shasum` shim was not needed on this host (macOS ships `/usr/bin/shasum`); it is untested here. Linux execution of the suite is unverified here (orchestrator decision 6).
- Long-list size: 200000 lines (first line Shutdown, rest Booted), enough to trigger the old false negative every time on this host.
- The plan's "case list asserted non-empty" is met by the baseline asserting a non-empty assertions map; the tests are written out explicitly rather than generated from a list.
- Process substitution and bash 3.2 compatibility were kept (no associative arrays; the comparison runs in python3, which the script already requires).

## For 186-04 / 186-05 mutation targets

Perl patterns should target these actual script pieces:
- The `LOOP-IOS-CLEANUP` downgrade block in `cleanup_and_emit` (the `if [[ "$OUTCOME" == "passed" && ( "$APP_UNINSTALLED" ...` condition): remove it, and the two cleanup tests plus the uninstall case go red.
- The H1 check after the build (`H1="$(tree_hashes)"` / `compare_tree_hashes "$H0" "$H1"`), the trap's H2 block (`D-11` comment), and the python allow-list tuple in `compare_tree_hashes` (`xcuserdata` entry; widening it should turn the outside-allow-list case green-to-red inverse, narrowing it fails the byproducts case). Restoring the four-file list is the T-186-11 reversion.
- The evidence precheck (`EVIDENCE_READY=1` assignment and the `-d "$EVIDENCE"` branch) and the `mv -f -- "$tmp" "$EVIDENCE"` write (replace with a plain `printf >"$EVIDENCE"`).
- The captured-output restored-state check (`device_line="${device_lines%%...`): reverting to a piped quiet grep turns the long-list case red.

## Deviations from Plan

None of substance. Task 1 red run 1 also failed the long-list case (not only the two named cleanup cases); the plan's verify only required the named ones and still passes. No STATE/ROADMAP/REQUIREMENTS writes, no staging or commits, no workflow, generated-guide or Android change, no new file under script/.

## Known Stubs

None.

## Self-Check: PASSED
