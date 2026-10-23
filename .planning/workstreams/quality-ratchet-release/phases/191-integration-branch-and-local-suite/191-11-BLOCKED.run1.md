# Phase 191 Plan 11: BLOCKED (stage_failed)

Cause label: `stage_failed` (example-host-proof). Not a SUMMARY: LAND-02 is NOT met yet.

## In plain words

At the final carry head 0dff1f22 the full local run passes eight of the nine stages but the example-host-proof stage fails with 2 test failures. Those two tests are not on Phase 190's list of known failures, so the plan cannot call the suite green. Nothing was committed or changed in the integration clone (tree clean, HEAD unmoved), nothing in the recovery checkout was committed, nothing was pushed.

## What ran

- Environment shims: private npm 10.9.2 in the run folder (integrity matched, global npm still 11.1.0), Java 17 on PATH for the run only, Node 22.14.0, Swift 6.3.3, Xcode 26.6, gitleaks 8.30.1.
- Separately measured floors (all exit 0, 0 failures): rulestead 11 (1 excluded), rindle 55 (7 excluded), sigra 139, chimeway 53, threadline 98, host 167, swift 89.
- phase41 and main floors: T=2660, X=78 (RESOLVER plain root run), P=3, Q=2735 (phase41-only run at the final head). P+Q=2738=T+X and P differs from T, so assumption A11 is disproved: phase41 floor 3, main floor 2657, main_excluded 81. The carry touched only `.planning/` (diff of test, lib, mix, config, packages between RESOLVER and the final head is empty).
- Task 1 tracer (example host through the gate at the final head): pass, 167 tests, 0 failures.
- `--all`, third attempt (after the environment repairs below): preflight, root-proof, browser-proof, ios-package-proof, android-package-proof, format-proof, warnings-proof, repository-cleanliness all PASS. example-host-proof FAILS.
- Tasks 2 (rest) and 3 were not run (CI-parity extras, pin recount, exclusions table, dispositions table, Swift export final run), because the plan ends on a failed stage.

## The blocking failure

`MIX_ENV=test mix test --only requires_example_host --seed 17` gives 68 tests, 2 failures; the full `CROSSWAKE_INCLUDE_EXAMPLE_HOST=1 mix test --seed 17` gives 2728 tests, 2 failures (10 excluded). Both failures are in `test/mix/tasks/crosswake_doctor_router_test.exs`:

1. accepts a freshly written Phoenix router without external preloading
2. discovers the installed router when --router is omitted

Cause: the doctor now reports `[error] host_commands (host_commands_stale)` ("generated iOS manifest Fixtures/crosswake_manifest.json is malformed"). The stale host-command check came in with the v25 to v27 doctor work (commit d63de956, tightened in bd294007 and a53fbef7, none of them on main). The test fixture written at line 254 of the test file is `{"manifest_schema_version":"1.0.0"}` with no `routes` object, which the new check treats as malformed. The test is tagged `requires_example_host`, so the default root run never executes it; only the example-host-proof stage does. This is a real test-fixture defect on the branch, not an environment effect.

Suggested repair (needs its own plan and one commit, since a commit after the carry breaks D-02's order here): add a `"routes":{}` object to that fixture (or write a minimal valid generated manifest), then re-run `--all`. It is outside this plan's allowed actions (no commit, no code change).

## Gate and environment issues found (to carry into the repair plan)

1. `suite-gate-191.sh` mode all made its run folder as `run.XXXXXX`; the repository verifier only accepts a folder named `crosswake-repository-verify.*`, so every stage failed preflight. Fixed in the committed-in-recovery script (now `$R191/crosswake-repository-verify.XXXXXX`); `selftest-suite-191.sh` still 30 of 30.
2. The same gate expects a `repository-preflight.log`; the orchestrator writes none for preflight (it reports PASS in its summary), so the gate says "stage count 8 expected 9" and "stage missing repository-preflight" even when everything passes. Not yet fixed; needs a gate change (treat preflight as the summary line, or count 8 logs plus the summary PASS).
3. `suite-gate-191.sh all` takes `lane N` floor lines (7) and a one-line `main_excluded N` file, not the named floors-191.txt and three-line excl-191.txt the plan specifies. Derived gate-format files were used (in the run folder).
4. npm 10.9.2 shim: asdf's `node` shim rewrites PATH so `npm` resolves back to 11.1.0 inside the verifier. The shim must put the real node 22.14.0 bin directory after the private npm10 bin and before the rest of PATH.
5. android-package-proof needs an Android SDK. The plan did not provide for one. The existing SDK at the user's `.crosswake/android-sdk` (platform 34 and 35, build-tools 34.0.0) was pointed to through `ANDROID_HOME` and `ANDROID_SDK_ROOT` for the run only (no global change); then the stage passed.
6. The log of the failed run also shows a logged (not failing) `Protocol.UndefinedError` for `Exqlite.Query` inside a Phase7 SaaS lane test setup; it is noise from a rescued error and was not investigated.

## A-14

Denylist dropped: no terms loaded, scans use `SCAN191_ADOPTER_SKIP=A-14`. The first-adopter context test (CI-parity step) was not reached in this run; when run it must run as CI runs it, without private terms, and mitigation T-191-43 is waived by the user's decision of 2026-10-22.

## Evidence left in 191-EVIDENCE

env-shims-191.txt, floors-191.txt, excl-191.txt, suite-HOST-FINAL.txt (pass), suite-ALL.txt (result fail, from the gate, third attempt). Earlier failed attempts wrote only to the run folder.

Commit in the recovery checkout: none (D-23). No push.
