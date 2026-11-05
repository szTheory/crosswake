---
phase: 197-public-docs-truth
plan: 09
subsystem: public-docs
tags: [docs, cleanroom-markers, executed-floor, reader-audit, ios-host, negative-controls, d-04, d-05, d-06, d-25]

requires:
  - phase: 197-public-docs-truth
    provides: "197-08 marked and wired README Integrating section and guides/install.md; 197-07 DOCS_EXECUTED_FLOOR placeholder, since= and ios_host deferral"
provides:
  - "test/crosswake/guides/cleanroom_doc_markers_test.exs: network-free, merge-blocking marker test (16 tests) with a mutation control per rule and the floor equality check"
  - "script/verify_published_cleanroom.sh: DOCS_EXECUTED_FLOOR pinned to 18"
  - "test/crosswake/guides/ios_host_doc_values_test.exs: documented :ios_host values validated by the current IOSHostConfig (5 tests)"
  - "197-EVIDENCE/cleanroom-docs-reader-audit-197.txt: per-step reader audit against the published 0.2.11 tarball, rc 0"
affects: [197-10, 197-13, 197-14, 199]

actuals:
  tokens: 6775
  tasks: 2
  commits: 2
plan_head_before: fa2e27083e1f77621aee1d54128b36e3a6db8325
plan_head_after: b5e0768656d1d6726b4c850ba24b0e038977d0c6

tech-stack:
  added: []
  patterns:
    - "Marker test parses the real docs with the same fence rule as strip_fences/1 and the same marker regex as the docs leg; every control mutates a copy, raises if the copy is unchanged, and asserts a specific violation tag"
    - "Documented config values are read from the doc fence through a literal-only AST walk before Code.eval_quoted, never copied into a test"
    - "Fixture-docs runs of the cleanroom script use a floor-lowered copy; the pinned floor is exercised separately against the fixture docs (red) and against the real docs (equality in the marker test)"

key-files:
  created:
    - test/crosswake/guides/cleanroom_doc_markers_test.exs
    - test/crosswake/guides/ios_host_doc_values_test.exs
    - .planning/workstreams/quality-ratchet-release/phases/197-public-docs-truth/197-EVIDENCE/cleanroom-docs-reader-audit-197.txt
  modified:
    - script/verify_published_cleanroom.sh
    - test/crosswake/release/published_cleanroom_test.exs

key-decisions:
  - "DOCS_EXECUTED_FLOOR is 18: 8 run/apply blocks without since= per file (16) plus one harness compile per file (2); it equals executed=18 in cleanroom-docs-selftest-197.txt. The since-marked ios-host blocks are excluded."
  - "The D-06 summary line (Steps marked \"Needs a clone\"...) never counts as a label for a repo-only line, so it cannot satisfy the lead-in rule for the install quick list."
  - "For list items the repo-only label must be on the item itself or on the list's lead-in line; the nearest-preceding-line shortcut applies only to non-list lines, so a labeled bullet cannot launder the bullet after it."

patterns-established:
  - "Reader audit fails closed: fetch status, both extractions and a tree non-vacuity check (version 0.2.11, at least 20 .ex files, install task present) are recorded before any reader is judged"

requirements-completed: []

duration: 50min
completed: 2026-11-05
status: complete
---

# Phase 197 Plan 09: Marker test, pinned executed floor and 0.2.11 reader audit Summary

**The rewritten README and install guide are now guarded in the merge-blocking suite without the network (markers, repo-only labels, wiring tokens, one route id, `since=0.2.12` only on the ios-host block), `DOCS_EXECUTED_FLOOR` is pinned from the placeholder 1 to the measured 18, the documented `:ios_host` values pass the current `IOSHostConfig` validator, and a fail-closed audit of the published 0.2.11 tarball shows every executed step has a reader there, with `:ios_host` the only deferral.**

## Accomplishments

- Task 1 (tracer, `882357f8`): `Crosswake.Guides.CleanroomDocMarkersTest` has 16 tests, no tags. The real docs produce `[]` violations; non-vacuity asserts at least 10 fences in install.md and at least 8 in the README Integrating scope, at least 3 repo-only occurrences per file, and exactly one `:ios_host` block per file carrying `since=0.2.12`. Marker ids are unique across both files. Every rule has a control on a copy of the real doc: a stripped marker (unmarked fence), a `bash script/` line in a run block, a removed clone label, each of the five required tokens removed per file, a diverged `entry_route_id`, the install quick-list items 6 and 7 and the README `bash script/verify_phase5_example_hosts.sh` bullet losing "(needs a clone)", the label after the README `bin/see-it-run.sh` fence removed, `since=0.2.12` removed from the ios-host marker and added to the bridge-hook marker, and the D-06 summary line removed. Each control raises if its mutation changed nothing.
- `DOCS_EXECUTED_FLOOR` is 18. The marker test computes the count from the docs (16 run/apply blocks without `since=` plus 2 harness compiles) and fails with the update instruction otherwise; I confirmed it turns red at 17. 18 equals `executed=18` in `cleanroom-docs-selftest-197.txt`, so nothing needed reconciling.
- Task 2 (`b5e07686`): reader audit against `https://repo.hex.pm/tarballs/crosswake-0.2.11.tar`: fetch rc 0 http 200, both extractions rc 0, tree version 0.2.11 with 138 `.ex` files, final `reader-audit: rc 0`. `deps` (outer `metadata.config` names 0.2.11), `install` (`lib/mix/tasks/crosswake.install.ex`), `bridge_hook` (`priv/static/crosswake.esm.js` exports `CrosswakeBridge`; `Crosswake.Install.Patcher` adds the `Plug.Static`), `route` (the router macro pops the `crosswake:` option in `lib/crosswake/router.ex`) and `attach` (`def attach(` in `lib/crosswake/bridge.ex`) are `found`; `esbuild` is `not_applicable_host_tool`; `:ios_host` is `not_found` in 0.2.11 and deferred.
- `Crosswake.Guides.IOSHostDocValuesTest` (5 tests, no tags): the `:ios_host` fence of each doc is parsed (`Code.string_to_quoted!`), checked literal-only (a control proves a `System.get_env` call is refused before evaluation), evaluated, the two docs' values are equal, the placeholder router is swapped for `Crosswake.TestSupport.RouterFixtures.ManagedRouter`, and `IOSHostConfig.normalize(values, env: :prod)` returns `{:ok, %IOSHostConfig{}}` for both. Controls: an origin that gains `/x` and a proof bundle id equal to the app bundle id are both `{:error, _}`. Values are read from the docs; the test holds no origin or bundle literal.

## Task Commits

1. Task 1 (tracer): marker test, floor pinned, fixture-run adaptation: `882357f8` (test)
2. Task 2: ios_host values test and reader-audit evidence: `b5e07686` (test)

## Verification Run (through `script/mix_test_gate.sh`)

- Markers test: ran=16, failures=0, min 11: PASS.
- `published_cleanroom_test.exs` plus `absence_is_not_success_test.exs`: ran=167, failures=0, min 126: PASS.
- ios_host values test: ran=5, failures=0, min 4: PASS.
- `mix format --check-formatted` on both new test files: clean. `grep -c "@tag"` 0 in both; the values-test literal grep prints 0.
- Reader-audit status greps and the seven-line awk check: pass (`matched=7 ok=1`).
- `git log --format=%H origin/main..HEAD -- .planning/config.json`: prints nothing.
- Privacy scan (`privacy-193.sh`, absolute paths) over the changed files and the evidence: clean before each commit. No push was made.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Pinning the floor to 18 made 28 hermetic cleanroom tests red**
- **Found during:** Task 1, the second verify gate
- **Issue:** `published_cleanroom_test.exs` runs the real script against small fixture docs that execute 14 to 16 steps; with the real floor of 18 every docs-leg fixture run ended `executed_below_floor <n> 18`.
- **Fix:** `run/4` now runs docs-leg fixture runs on a copy of the script whose floor is lowered to 1 (asserted changed); `pinned_floor: true` runs the real script. The floor test now asserts the real pinned floor is red against the fixture docs (`executed_below_floor 14 <pinned>`, parsed from the script) and the lowered copy passes, and the constants test asserts the floor is above the placeholder. The env-sentinel test's script copy gets the same lowering. No behavior test was weakened and no script behavior changed. The file is not in the plan's `files_modified`, but the plan's own second verify gate requires it to pass.
- **Files modified:** `test/crosswake/release/published_cleanroom_test.exs`
- **Commit:** `882357f8`

**2. [Process] Reader-audit checks tightened before the recorded run**
- My first draft of the audit script looked for `Plug.Static` in the install task file and for `crosswake:` text in the router; both real readers sit elsewhere (`lib/crosswake/install/patcher.ex`, the `Keyword.pop(opts, :crosswake)` clause in `lib/crosswake/router.ex`), so it wrongly reported `bridge_hook` as `not_found` (rc 1). I inspected the extracted tree by hand, confirmed the readers exist, tightened the checks to those readers, and re-ran from scratch; only the second, fully recorded run is committed. The audit is a throwaway script in the session scratchpad, not repository code.

## Known Stubs

None.

## Threat Flags

None. T-197-19 is mitigated in the normal suite (values parsed from the docs, literal-only AST walk, current validator, two controls). T-197-35 is mitigated: `reader-audit: rc 0` with every executed step's reader found and only `ios_host` deferred. No dependency was installed (T-197-SC-09): the tarball was read and deleted.

## Requirement status

DOCS-01 is carried by this plan but is not marked complete: later plans (197-10 onward) also carry it.

## Not yet proven

- The floor equals the executed count of the docs as run against the real registry (197-08 evidence). Whether it stays right at 0.2.12 (where the ios-host blocks execute and `executed` exceeds the floor) is for Phase 199.
- `normalize/2` checks only that `entry_route_id` is non-empty; the route-id match to the documented router is covered by the marker test's consistency rule and, at generation time, by `IOSHostGeneration` (not exercised here).

## Self-Check: PASSED

- FOUND: test/crosswake/guides/cleanroom_doc_markers_test.exs, test/crosswake/guides/ios_host_doc_values_test.exs, 197-EVIDENCE/cleanroom-docs-reader-audit-197.txt, script/verify_published_cleanroom.sh (`DOCS_EXECUTED_FLOOR=18`)
- FOUND commits: `882357f8`, `b5e07686` (ancestors of HEAD); `commits: 2` measured from ledger base `fa2e2708`; no file deletions
