---
phase: 186-host-seam-and-harness-honesty
plan: 05
status: complete
requirements: [SEAM-07, SEAM-08, SEAM-09, LOOP-06, LOOP-07]
commits: 1
plan_head_before: 25614cf685e2ee299646e04b833293c677023c45
plan_head_after: bd29400722e14bed74c987bf5a9903f486dc6fc2
actuals:
  tasks: 3
  commits: 1
---

# Phase 186 Plan 05: Prove and land Phase 186 Summary

Phase 186 is now one local commit in the candidate checkout, on top of the Phase 185 commit. The uncommitted tree passed every gate against the Phase 185 baselines, and all 25 guards that change behaviour were shown to matter: reverting each one in a throwaway copy made its named test fail. Nothing was pushed, the twin, Simulator and xcodebuild were not run, and the recovery checkout was not touched. (Planning files here are plain uncommitted files, as the plan requires.)

## The commit

- Candidate commit `bd29400722e14bed74c987bf5a9903f486dc6fc2`, tree `12f71262ee7d61a817088152558e6016d00f9e2f`, parent `25614cf685e2ee299646e04b833293c677023c45`.
- Subject `fix(186): make the host seam, doctor and loopback harness fail closed`; the last line is the Co-Authored-By trailer given by the orchestrator. Path list staged by name; no `git add -A`.
- 24 committed paths (bound 20-26): the 20 required paths, the two LOOP-07 lib files (`physical_iphone_preflight.ex` and `crosswake.proof_lane.physical_iphone.ex`, because the 186-04 verdict was red), and the two orchestrator-authorised doctor fixture tests (`test/crosswake/doctor/doctor_test.exs`, `test/mix/tasks/crosswake_doctor_test.exs`). The optional ledger and optional extra test files were not part of the change set, so they were not committed (the ledger needed no regeneration).
- Porcelain empty after the commit. Push URL still `no-push-phase180`.

## Gates on the uncommitted tree (Task 1)

| Gate | Result |
|------|--------|
| Absence checker pin | literal 249 untouched; 251 test files; flagless checker exit 0, "scanned 251 test files, pin 249" |
| Ledger `--check` | exit 0, 243 sites, no regeneration |
| Full suite | 2590 tests, 1 failure (78 excluded); failure set cmp-equal to `fix-185.failures` (only `phase180_twin_feasibility_test.exs:30`) |
| Swift | 89 tests executed, 1 failure (0 unexpected); failing set cmp-equal to `swift-baseline-186.failures` (pre-existing G4 test, deferred) |
| Focused ExUnit | 219 tests, 0 failures (includes the two doctor fixture files) |
| Guides and readers | 289 tests, 0 failures |
| Docs sync, compile with warnings as errors, format, `bash -n` | all exit 0 |
| Adoption scan | the five `routing.*` findings cmp-equal to the Phase 185 set |
| Diff boundaries | no `.github`, Android, generated guide, manifest, BridgeChannel or fixture-resource path; only script path is the harness; no changed `public` Swift line; no added `assert/refute Enum.all?/any?(` line |

## Mutation controls (Task 2)

Script `mutate-186.sh` (derived from the 185 harness); log `mutation-186.log` has exactly 27 control lines and no HARNESS FAILURE. The 24-path pre-mutation sha256 manifest verified after the run (24 OK), the throwaway copy was removed, and the candidate HEAD did not move.

```
control 0: unmutated: passed (85 tests, 0 failures)
control 1: unmutated swift HostCommandNavigationTests: passed (10 tests, 0 failures)
control 2: doctor.ex replaced whole by 25614cf6: failed as expected (14 tests, 6 failures)
control 3: non-enoent read-error branch returns []: failed as expected (14 tests, 1 failure)
control 4: malformed branch returns []: failed as expected (14 tests, 1 failure)
control 5: host_commands_stale_skipped branch returns []: failed as expected (14 tests, 1 failure)
control 6: legacy fixture routes compared as empty commands: failed as expected (14 tests, 1 failure)
control 7: route_missing branch skips the absent route: failed as expected (14 tests, 1 failure)
control 8: legacy finding severity always warning: failed as expected (14 tests, 1 failure)
control 9: display_location returns its absolute input: failed as expected (20 tests, 11 failures)
control 10: canonical reduced to Path.expand: failed as expected (16 tests, 1 failure)
control 11: inside? replaced by starts_with on joined paths: failed as expected (16 tests, 1 failure)
control 12: doctor shell_unsupported_finding prints package.location raw: failed as expected (4 tests, 2 failures)
control 13: shell_gate passes package.location raw: failed as expected (4 tests, 2 failures)
control 14: compatibility.md replaced whole by 25614cf6: failed as expected (11 tests, 1 failure)
control 15: native_shell_upgrade.md replaced whole by 25614cf6: failed as expected (11 tests, 1 failure)
control 16: CHANGELOG.md replaced whole by 25614cf6: failed as expected (11 tests, 1 failure)
control 17: ActivationCoordinator.swift replaced whole by 25614cf6: failed as expected (10 tests, 4 failures)
control 18: legacy version_unsupported reason replaced by not_registered: failed as expected (10 tests, 1 failure)
control 19: compare_tree_hashes always succeeds: failed as expected (15 tests, 5 failures)
control 20: swap target must differ from its pre-swap hash removed: failed as expected (15 tests, 1 failure)
control 21: at-exit hash comparison removed: failed as expected (15 tests, 1 failure)
control 22: evidence precheck sets EVIDENCE_READY without checking: failed as expected (15 tests, 2 failures)
control 23: mv status ignored: failed as expected (15 tests, 2 failures)
control 24: LOOP-IOS-CLEANUP downgrade removed: failed as expected (15 tests, 2 failures)
control 25: restored-state check reverted to piped quiet grep: failed as expected (15 tests, 1 failure)
control 26: origin refusal signal returns nil (origin_refusal_for): failed as expected (19 tests, 3 failures)
```

Each failing control names its tests in the log (full names, as the plan lists them).

## Post-commit checks (Task 3)

- `TwinProducers.probe_source` on the committed candidate: `{:ok, %{modified: 0, flagged: 0, excludes: 0}}`.
- Post-commit focused list: 219 tests, 0 failures. Flagless checker exit 0.
- Twin history manifest: 87 OK lines. No `twin-05` directory.
- Read-only twin preflight (ios, never-created record, identity and run-root paths): exit 2, four lines, `result: blocked`, `first cause: prerequisite_missing`, `report: none written; no run root was created or consumed`. None of the three paths was created.
- Home-path and username scan: scope and result in `home-scan-186.files` and `home-scan-186.log` (phase `186-*` files plus depth-1 RUNS files with 186 in the name). Result recorded below.

## Deviations from Plan

### Orchestrator deviations (recorded and authorised by the orchestrator)

**1. [orchestrator deviation] Stale doctor fixture fix.** Run 1 stopped because two older tests wrote an iOS fixture `{"manifest_schema_version":"1.0.0"}` with no `routes` map, which the new doctor correctly reports as `host_commands_stale` reason `malformed`. I confirmed by reading the surrounding lines that each was the iOS fixture, then changed only that literal to `{"manifest_schema_version":"1.0.0","routes":{}}` at `test/crosswake/doctor/doctor_test.exs` line 1174 and `test/mix/tasks/crosswake_doctor_test.exs` line 355. The Android fixtures stayed unchanged. The two paths were added to the diff-path checks, the pre-mutation manifest and the commit allowlist (24 paths, within 20-26).

**2. [orchestrator deviation] Swift test count.** The clause `Executed (9[0-9]|[1-9][0-9]{2}) tests` is a planner miscount; the suite has 89 tests (86 baseline + 3 from 186-02). Accepted as satisfied by 89 with the failure set equal to baseline.

### Auto-fixed in scope

**3. [Rule 1 - Bug, run 1, kept] Forbidden `assert Enum.all?`.** `test/mix/tasks/crosswake.proof_lane.physical_iphone_test.exs` carried an added `assert Enum.all?` line from 186-04; replaced with an explicit comparison (`others = List.delete(checks, config)`, `assert others != []`). It also removed the one unclassified ledger site, so no ledger regeneration was needed.

**4. [Rule 1 - harness correction] Controls 25 and 26 as first written did not bite.** The first harness run logged two HARNESS FAILURES, so I corrected the mutations (not the product code) and re-ran the whole harness from a clean start:
- Control 25: my first mutation used a two-stage `xcrun ... | grep -q` pipe. The test shim for `xcrun` always exits 0, so the early-exiting `grep -q` could never fail the pipeline through it. The bug the guard protects against is the three-stage form `xcrun ... | grep -F "$UDID" | grep -q "(Shutdown)"`, where the middle grep fails under pipefail on a long list. The mutation now restores exactly that form; the test fails as expected.
- Control 26: the plan's description, "`origin_refusal/1` returns nil", only removes the refusal cause text; the block itself comes from `config/1` calling `origin_refusal_for/2` directly, so the two named PI-PREFLIGHT-CONFIG tests do not fail. The mutation now makes the signal branch of `origin_refusal_for/2` return nil (a local-loopback host is no longer refused). Both named tests fail. The separate cause-text test also fails under it.

No product code changed because of these two corrections.

### Decision-time notes

- The candidate checkout is a detached HEAD on the Phase 185 commit (not a protected branch). The generic "HEAD must be on an agent branch" assertion cannot apply there; the plan and the orchestrator specify committing on `25614cf6`, so I followed the plan.

## Deferred items (with reopen triggers)

- The pre-existing Swift G4 failure (`Phase180TwinFeasibilityTests`): reopen at the Phase 188 twin rerun.
- 182 WR-06 and IN-03; the harness uninstalling a pre-existing app; 185 WR-02..WR-05; other absolute paths in doctor output; empty `hostCommandDeniedVersions` on legacy routes: reopen if a later phase touches those surfaces.
- The loopback harness's build-addition allow-list (workspace and xcuserdata only) is an assumption that Phase 188's real run must confirm.
- Linux execution of the harness suite is unverified locally.
- The absence checker's test-files pin (249, with 251 files present) stays a Phase 188 freeze item.
- Composed evidence case (a passed run whose evidence cannot be written and whose cleanup also fails) is covered by two separate tests, not one combined test.

## Known Stubs

None.

## Next step

The workstream STATE names the next command; this plan did not modify STATE.md, ROADMAP.md or REQUIREMENTS.md, so the orchestrator records completion and routes to Phase 187 (which builds on `bd294007`).

## Home-path and username scan

Scanned 170 files: every `186-*` file in the phase directory (this SUMMARY and the updated VALIDATION included) and every depth-1 file in the run directory with 186 in its name, except the scan's own list and log. Two raw tool outputs (`mut-186-9.out`, `history-186.after.out`) carried the home path and were redacted to `<home>`. After that, no listed file contains the home path and none contains the username as a whole word; every listed path exists and is readable. List: `home-scan-186.files`; log: `home-scan-186.log`.

## Self-Check: PASSED

Commit `bd294007` is present in the candidate with parent `25614cf6`; the 24 committed paths exist; the throwaway mutation copy is gone; `mutation-186.log` has 27 control lines; the candidate porcelain is empty.

