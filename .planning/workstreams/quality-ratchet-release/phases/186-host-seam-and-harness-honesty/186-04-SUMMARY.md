---
phase: 186-host-seam-and-harness-honesty
plan: 04
status: complete
requirements: [LOOP-07]
commits: 0
plan_head_before: 25614cf685e2ee299646e04b833293c677023c45
plan_head_after: 25614cf685e2ee299646e04b833293c677023c45
actuals:
  tasks: 2
  commits: 0
---

# Phase 186 Plan 04: Physical-iPhone preparation refuses a local-loopback host Summary

The regression test was red against the unchanged preflight: preparation reported ready for a host generated in local loopback mode. I added the check in `PhysicalIphonePreflight.config/1` and it is now blocked with `PI-PREFLIGHT-CONFIG` in all three modes. All edits are uncommitted in the candidate (186-05 commits), so `commits: 0` is intentional. No device, Simulator, xcodebuild or twin was touched.

## Assumption A3 (confirmed by grep)

- `lib/mix/tasks/crosswake.gen.shell.ex:128`: `managed_root = Path.join(target, "native/ios/crosswake_shell")`
- `lib/crosswake/proof_lane/config.ex:168`: `["native", "ios"] <- Enum.take(components, -2)` (`ios_shell_root` must end in `native/ios`)

So the check reads `Path.join(ios_shell_root, "crosswake_shell")`.

## What was built

- Three tests plus one separate cause test in `test/mix/tasks/crosswake.proof_lane.physical_iphone_test.exs`, each looping over `--preflight-only`, `--readiness` and `--run` (all with `--json`):
  - local `:ios_host` declaration blocks all three and `device_report` is never called;
  - real `mix crosswake.gen.shell ios` output generated in local-loopback mode on disk, with a production declaration, blocks all three (the test first asserts `Info.plist` and `Fixtures/route_activation.json` exist);
  - the cause test: every blocked result carries `Generator.local_mode_refusal()`, in both cases and all three modes;
  - the control: a production declaration over real production output gives `{:ready, _}`, readiness `"ready"` and `{:passed, _}` with `device_report` called.
- `ios_host: nil` added to `ready_options/0` in both `physical_iphone_test.exs` and `physical_iphone_preflight_test.exs`; the new tests use `Keyword.put`.
- `lib/crosswake/proof_lane/physical_iphone_preflight.ex`: `config/1` now returns `{:config_error, :local_loopback}` when `IOSHostOriginMode.observe/2` returns anything other than `:none`. The declaration is read with `Keyword.get_lazy(options, :ios_host, ...Application.get_env(:crosswake, :ios_host))`. A new `@doc false origin_refusal/1` returns `Generator.local_mode_refusal()` or `nil`, and an exception during observation becomes the refusal, never a pass.
- `lib/mix/tasks/crosswake.proof_lane.physical_iphone.ex`: a `PI-PREFLIGHT-CONFIG` block caused by this check carries `cause: <refusal text>`. For readiness, the cause is on the top-level result. No new rule id and no exit-status change.

## Red verdict

`red-186-04.verdict` = red. `red-186-04.exit` = 2, "27 tests, 3 failures", headers:

1. test real local-mode gen.shell output under a production declaration blocks preflight-only, readiness and run with PI-PREFLIGHT-CONFIG and never calls device_report
2. test a local-loopback ios_host declaration blocks preflight-only, readiness and run with PI-PREFLIGHT-CONFIG and never calls device_report
3. test a local-loopback refusal carries the generator refusal text as its cause

The first two failed because `--preflight-only` returned `{:ready, ...}`. The control passed. One earlier run failed only on a test syntax error (a `case` inside `assert`); that was fixed in the test before the real red run, and no lib file was edited before the red run.

## Verification (evidence in /private/tmp/crosswake-phase180-run)

| Step | Result |
|------|--------|
| Red run, `red-186-04.out` | exit 2, verdict red (above) |
| Green, `green-186-04.out`: physical_iphone, preflight, gen_proof_lane, ios_host_origin_mode, doctor_origin_mode tests | exit 0, 100 tests, 0 failures |
| `mix compile --force --warnings-as-errors` (dev tree), `compile-186-04.out` | exit 0 |
| `mix format --check-formatted` on the four changed files, `format-186-04.out` | exit 0 |
| Task 2 `<automated>` command (rule-id comparison against 25614cf6, home-path scan) | exit 0 |
| Candidate porcelain | 22 paths: the 18 from 186-01..03 plus these 4; no staging, no commits |

## Deviations from Plan

- **Placement (orchestrator decision 1):** the check lives in `PhysicalIphonePreflight.config/1`, not in `run_with` as D-17's wording says, so that `check/1` and `readiness/1` both reach it. The task module only adds the cause text.
- No existing assertion was changed; no existing test pins the key set of these result maps.
- The 186-04 test names and verify commands were used as written. The plan said to use only `ios_host: nil` in the preflight test, and that is the only change there.

## Unclassified edge (flagged, not resolved)

A host regenerated between preparation and the device run, or a shell root other than `ios_shell_root/crosswake_shell`, is not covered.

## Known Stubs

None.

## For 186-05 (mutation targets)

- Remove the `origin_refusal_for(config, options)` branch in `config/1` (return `{:ok, config}` always): the two blocking tests and the cause test must go red; the control stays green.
- Change `:none -> nil` handling so any signal returns nil (weakens the check): same tests go red.
- Change the `rescue` in `origin_refusal_for` to return `nil`: no current test covers it (an exception path is untested; flag if 186-05 wants that mutation to bite).
- Remove the `blocked_result("PI-PREFLIGHT-CONFIG", ...)` cause or the readiness `Map.put(result, :cause, ...)`: only the cause test goes red.
- Test names in failure headers are the three above plus "a local-loopback refusal carries the generator refusal text as its cause" and "a production declaration over production gen.shell output still passes preflight-only, readiness and run".

## Self-Check: PASSED
