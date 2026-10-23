---
phase: "171"
plan: "171-03"
status: complete
requirements: [WELD-06]
completed: "2026-09-17"
---

# Plan 171-03 Summary — CLI entrypoints, identity, mirror, status, Coordinate

## What was built

**Task 1 (`1db75441`)** — format-checked the two CLI entrypoints so any well-formed semver reaches the
graph, rather than only the frozen candidate.

**Task 2 (`588b2f7e`)** — `identity.ex`, `mirror.ex` and `release_status.ex` now follow the version they
are supplied instead of a frozen literal. New `test/crosswake/release_candidate/identity_test.exs`;
`mirror_test.exs`, `crosswake_release_status_test.exs` and `crosswake_release_candidate_test.exs`
extended.

**Task 3 (`7c5a1a65`)** — `coordinate.ex`'s `@candidate "0.2.1"` replaced by a version derived from the
release manifest's `.` entry, guarded by an anchored `\A\d+\.\d+\.\d+\z` pattern. Every other source in
the module is now asserted equal to that single derived value rather than independently equal to a
literal — the same authority ordering the rest of the phase uses. All comparisons remain **exact
equality**; nothing was loosened to a substring or prefix match. The raise-site count is unchanged: the
format check and the `input.version` cross-check were folded into the existing raise site rather than
adding a new one.

## D-171-C guard — re-run, and it still holds

The plan requires the `Coordinate` caller grep to be re-run immediately before editing, and a STOP if a
production caller has appeared. Re-run by the orchestrator before committing Task 3:

```
grep -rn "Coordinate" lib script .github
```

excluding the module's own file and the unrelated `"Coordinated deploy with updated Hex package"` prose,
returns **nothing**. The module still has no production caller, so the premise D-171-C rests on holds.

**Disposition: parameterized, not deleted.** Deleting an orphaned module may well be correct, but it is
not what WELD-01..08 asked for, and bundling a deletion into a repair PR hides it from review.

**WELD-01 inventory row type (consumed by plan 171-05):**
`orphaned validator (no production caller; test-only)` — deliberately NOT `live gate`.

## Execution note — the executor was lost mid-plan

The `gsd-executor` agent running this plan terminated with an `ENOTFOUND` API error after Task 1 had
committed and while Task 3's test updates were in progress. This was an infrastructure failure, not a
defect in the work, and the agent could not be resumed.

The orchestrator assessed the working tree, found Tasks 2 and 3 substantively complete and coherent,
verified them, and committed them. Tasks 2 and 3 are committed separately to match their code
boundaries, **but were verified as one unit** — the executor was lost before it could verify them
apart. That is recorded in the commit messages too, so the provenance is not inferable only from here.

No work was reverted and none was redone.

## Verification

Run on the assembled tree before committing:

| Command | Result |
|---|---|
| `mix test test/crosswake/release_candidate test/mix/tasks/crosswake_release_candidate_test.exs --max-cases 1` | 67 tests, 0 failures |
| `mix test test/crosswake/proof --max-cases 1` | 677 tests, 0 failures (67 excluded) |
| `elixir script/check_release_workflow_integrity.exs` | exit 0 — 69 of 69 roster checks emitted, 0 failed |
| `elixir script/inventory_collection_assertions.exs --check` | 224 classified sites, ledger matches the live tree exactly |
| `mix format --check-formatted` | clean |

## Fallout carried

`script/collection_assertion_ledger.json` regenerated for line-number shifts only (same keys, buckets
and shapes). `phase169_diagnostic_legibility_test.exs` and `phase170_vacuous_assertion_ledger_test.exs`
updated for the same shifts. Both are attached to the Task 3 commit because both tasks contributed to
them.

## Not done

No push, no PR, no branch operations — plan 171-05 Task 3 remains the sole authorized PR point.
`STATE.md` and `ROADMAP.md` untouched.
