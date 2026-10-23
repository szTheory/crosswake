# Phase 191 exclusions and skips (LAND-02)

Measured at the FIXTURE head 7075a441. Every test that the default local run leaves out is listed here with its reason and where it runs instead. Nothing else is excluded or skipped.

The main lane's excluded total is 81 (the formula in excl-191.txt: assumption A11 disproved, inputs T=2660 X=78 P=3 Q=2735). The example-host-isolation stage runs the excluded `requires_example_host` class explicitly (68 tests at seed 17) and then the whole suite including it (2728 tests, 10 excluded), for three seeds.

| Mechanism | Tag or test | Count | Reason | Where it runs instead |
|---|---|---|---|---|
| test_helper default exclusion | advisory_only | 2 static sites | The Rulestead advisory proof files only apply when the advisory engine is wanted (MIX_INCLUDE_RULESTEAD=1). | The phase43 and phase52 advisory workflows set MIX_INCLUDE_RULESTEAD=1; the merge-blocking CI lanes exclude it on purpose. |
| test_helper default exclusion | collateral_binaries | 1 static site | The See It Run collateral binaries are produced by people and tools outside the suite, so the existence guard stays out until they are committed. | The see-it-run-collateral workflow and script/collateral-guard.sh run it with CROSSWAKE_INCLUDE_COLLATERAL=1. |
| test_helper default exclusion | engine_present | 0 static sites | A hook for tests that need the Rulestead or Rindle engine loaded (MIX_ENGINE_PRESENT=1). No test carries the tag today. | Runs nowhere, because no test uses the tag; the exclusion is a no-op until one does. |
| test_helper default exclusion | requires_example_host | 22 static sites | These tests need the checked-in example Phoenix app compiled; a bare run excludes them so local and CI mean the same thing. | The example-host-proof stage (script/check_example_host_isolation.sh --matrix-only, seeds 17, 101, 1009, tagged and complete classes) and the proof-requires-example-host CI job. This run: the stage passed, and the 68 tagged tests plus the full 2728-test run had 0 failures. |
| verify alias exclusion | phase41_nested_process | 3 static sites | The Phase 41 nested-process tests run alone with one case at a time so they do not disturb other tests. | Its own lane (`mix test --only phase41_nested_process --seed 748644 --max-cases 1`), the phase41 lane of root-proof: 3 tests, 0 failures. |
| Swift default skip | test_G3_gate_generated_activation_session_lacks_host_command | 1 | Needs the example-host export of the generated activation. | The SWIFT-EXPORT-FINAL run with the export present: 89 tests, 0 skipped, 0 failures. |
| Swift default skip | test_G3_control_exported_request_carrying_command_reaches_delegate | 1 | Needs the example-host export of a request. | The same SWIFT-EXPORT-FINAL run. |

The full `--all` run (ios-package-proof) shows exactly these two Swift tests skipped and no other.

Static site counts come from a text search of `@tag`, `@moduletag` and `@describetag` lines under test/ that name the tag. No tagged test was run for counting.

Root skip tags: 0

Note on that count: two lines in `test/crosswake/proof/phase164_exunit_ownership_test.exs` contain the text `@moduletag :skip`. Both sit inside quoted fixture source that the test writes to a temporary folder to check its detector; neither tags a test in the real suite, so they are not skip tags.
