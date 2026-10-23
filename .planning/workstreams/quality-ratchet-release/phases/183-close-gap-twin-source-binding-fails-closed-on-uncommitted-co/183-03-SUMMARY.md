---
phase: 183-close-gap-twin-source-binding-fails-closed-on-uncommitted-co
plan: 03
status: complete
requirements: [TWIN-01, TWIN-05, TWIN-06]
commits: 1
plan_head_before: da214c59f018d0af9b1c122f6d5f4d97d259da97
plan_head_after: 50fcd5743243c0b20275a7e2bd9338bf25468687
actuals:
  tasks: 3
  commits: 1
---

# Phase 183 Plan 03: Fail closed on an uncommitted twin candidate - Summary

The reference twin now refuses an uncommitted candidate in plain language, refuses a run root placed inside the candidate, and the whole guard (183-02 plus this plan) is one candidate commit, `50fcd5743243c0b20275a7e2bd9338bf25468687` (tree `d71bc587ce73d8a253465ea8c31f9eed5e286e17`), directly on top of `feat(180-07)`. The SHA is in `/private/tmp/crosswake-phase180-run/fix-183.commit`.

## What was done

1. **Run root containment (D-11).** `TwinRuntime.prepare/1` calls a new private `outside_candidate/2` after reading the candidate record. It compares device and inode of the candidate with the run root and each ancestor, so a symlink alias into the candidate is caught and a sibling that only shares a name prefix (`<candidate>-run`) is accepted. A refusal exits 2 with `prerequisite_missing`, `report: none written`, and no `receipt.json`.
2. **Plain-language output (D-08..D-10).** For `source_dirty` the command still prints four lines and exits 2. The first-cause line is `first cause: source_dirty`. The next action reads "The candidate has N uncommitted or untracked files. Commit or remove the uncommitted changes in the candidate, write a new prepared record, and run into a new run root. Run git status in the candidate to see them." (without N when git cannot count). N is stored as the integer `measure` on the blocked observations; no path or file name is printed or stored.
3. **Fifth fidelity limit (D-12)** "source edit made and reverted during a run not detected", and **guide sentence (D-16)** "The candidate tree must be clean at the recorded head; a dirty tree is refused." The guide has 0 occurrences of B2C. New guide SHA-256: `d8c97d03a431f94a46db4dfa7ed76e1362f366b1ac9278e90c3cc9afde30d769` (use for the STATE "Guide pending reconciliation" line).
4. **New tests:** run-root inside / symlink alias / prefix sibling; dirty git candidate with a marker file (count 1, marker absent from the four lines, `receipt.json`, `twin-result.json`); non-git candidate (measure nil); five-entry fidelity list and `safe_cause(:source_dirty)`.

## Committed paths (10)

`guides/see_it_run.md`, `lib/crosswake/proof_lane/twin_journey.ex`, `twin_producers.ex`, `twin_receipt.ex`, `twin_runtime.ex`, `lib/mix/tasks/crosswake.proof_lane.verify_twin.ex`, and the four test files (`twin_producers_test.exs`, `twin_journey_test.exs`, `twin_receipt_test.exs`, `crosswake_proof_lane_verify_twin_test.exs`).

## Test results

- Quick set (five twin suites, guides, phase69): 296 tests, 0 failures. Phase170 ledger suite and `mix crosswake.docs.sync --check` pass.
- Full suite (`mix test --exclude requires_example_host`): 2399 tests, 1 failure. The failure is `test/crosswake/proof/phase180_twin_feasibility_test.exs:30`, identical to the 183-01 baseline (`cmp` of `fix-183.failures` and `baseline-183.failures` is clean). No new failure.
- Committed tree: producers, receipt and mix-task suites 77 tests, 0 failures.

## Negative-control mutations (throwaway copy, deleted afterwards; log in `mutation-183.log`)

All eight failed as expected, and the unmutated copy's producers suite passed (43 tests, 0 failures).

| # | Mutation | Result |
|---|---|---|
| 1 | freeze skips `clean_tree` | 3 failures |
| 2 | probe drops `core.excludesFile=/dev/null` | 1 failure |
| 3 | `info/exclude` rule count forced to 0 | 1 failure |
| 4 | `@git_scrub_env` replaced with `[]` | 1 failure |
| 5 | re-probe and HEAD/tree comparison removed (5a: 3 failures); journey calls `observe_identities` directly (5b: 1 failure) | failed |
| 6 | `:source_dirty` removed from `@causes` | 4 failures |
| 7 | `outside_candidate/2` always ok | 1 failure |
| 8 | `sh` stderr wrapper removed (fd-level fake-git sentinel reads "leak") | 1 failure |

## Deviations

- **[Rule 3 - Blocking, avoided regeneration]** The first placement of the new mix-task tests shifted line numbers of rows in the phase170 vacuous-assertion ledger and made its suite fail. I moved the new tests to the end of the file instead, so the ledger is unchanged and was not regenerated.
- The mutation script wrote the exact `1 failure` counts from mix output; the specific failing test names were not retained per control.
- Planning-doc commits were skipped as instructed (isolation none, recovery checkout untouched); this SUMMARY is a plain uncommitted file. STATE.md and ROADMAP.md were not updated (orchestrator-owned).

## Self-Check: PASSED

Candidate porcelain empty; HEAD equals `fix-183.commit`; parent is `feat(180-07)`; push URL still `no-push-phase180`; recovery checkout has nothing staged and HEAD `d0f3e2f1`; `/private/tmp/crosswake-183-mutation` removed.
