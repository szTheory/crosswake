# Amendment 2 to the 196-15 candidate evidence (2026-10-29)

This file is added on top of the 196-15 evidence and amendment 1. The 196-15 summary, amendment 1 and their recorded results are unchanged. The candidate record from amendment 1 (committed at 393b7b51, with the pass on identity `bc288cde...` and tool hash `b4c1124e...`) is kept in git history, and `candidate.json` is replaced by the record from this amendment, as the plan prescribes for a fresh candidate run.

## Why a new candidate run was needed

PR 260 merged to main as `88c8bdd8`. The actual-main landed proof then refused `landed_restoration_failed` after 78 minutes (2026-10-29 01:53Z to 03:11Z), as recorded in `196-17-BLOCKED.md`. The landed mode of `phase-evidence.mjs` ran the 40 children in the main checkout after detaching it onto the merge commit. Four vector children rewrite tracked receipts under `196-EVIDENCE`, those edits followed the switch back, and the whole-tree inventory check refused. The tool kept no per-child result.

The fix changes `phase-evidence.mjs`, which is part of the candidate identity, so the plan 16 rule that the tools stay byte-unchanged could not hold. The user directed this fix-forward, and `196-17-BLOCKED.md` names it. The change is recorded here as an amendment and reviewed as `196-REVIEW.md` amendment A-2 with its addendum.

| Identity part | Amendment 1 | This amendment |
|---|---|---|
| supported-source roster | `bc288cde...` (1376 blobs) | `bc288cde...` (unchanged) |
| `phase-evidence.mjs` whole file | `b4c1124e...` | `8b825268...` |
| `measure-main.mjs` whole file | `af5acfc3...` | `af5acfc3...` (unchanged) |
| preserved roster | `44019928...` | `44019928...` (unchanged) |

## What the tool change is

- The landed mode runs the registry in a linked worktree of the merge commit at `<git dir>/crosswake-196-landed`, with that worktree as the root of every child, and removes it in a `finally` block. The main checkout is never switched or written. The head, branch and whole-tree inventory checks remain as asserted invariants.
- Per-child results persist to `<git dir>/crosswake-196-landed-children.json` after every child and on any refusal. An earlier ledger is rotated to a dated name, never overwritten.
- Only path-independent fetched inputs (`deps`, `node_modules`, `local.properties`) are cloned into the worktree. Build output is never cloned, because a cloned SwiftPM `.build` is refused for recording an absolute path. Every build starts cold. A clone failure refuses with `landed_cache_warm_failed`, and no child is skipped.
- The explicit-format child reads the Elixir files changed since the recorded base `4ebe37fe` instead of since `origin/main`, because `origin/main` now contains the work (see R-25).
- The candidate may run on `fix/196-landed-restoration` as well as `fix/spec-structure-ratchet`.
- Scoped controls were written first and run red: `self-test --scope landed` failed on the missing `runLandedRegistry` (the first control also reproduces the defect by showing the in-place procedure changes the inventory), and the format control failed on the empty diff. All self-tests are green: the landed, merge and unscoped runs.

## What was re-measured and what was not

- Re-run: all 40 candidate children, on the new identity, at head `5fac5839ab6044593e387ddf340ab63347f79484` with origin/main at `88c8bdd88c234c7d9c6b4cc8dbcc2fc9d63fe1be`.
- Not re-measured: the five actual-main receipts (untouched, still pinned to main commit b8398c38) and the Muex baseline (not run).
- The `landed.json`, `delivery.json` and `196-VERIFICATION-INPUTS.md` records from the blocked attempt are untouched.

## Observation of the isolated worktree before the candidate run

This is not the landed proof. It used no approval record, evidence branch or landed receipt.

| Observation | Children | Result |
|---|---|---|
| First calibration at the fix commit (12 children) | 12 | 11 pass; `ios-package-counts` failed because a cloned `.build` was refused; cloning of build output was removed |
| Second calibration at the fix commit (7 children, cold builds) | 7 | 7 pass (example host 1651 s, core suite 2920 tests, browser proof, Swift package 89 tests, Android package 12 tests, manifest lane 11 tests, Swift request vectors) |
| Full registry in the isolated worktree at merge commit `88c8bdd8` with the final tool | 40 | 40 pass, the worktree removed, the main checkout clean |

## Candidate runs on this identity

| Run | Verdict | Failing child | Retained record |
|---|---|---|---|
| 1 (tool without the format-scope fix, identity `bfe5d415...`) | fail (39 of 40) | `format-explicit` (`format_scope_empty`) | `candidate-amendment-2-failed-run-1.json` |
| 2 (final identity, `8b825268...`) | pass (40 of 40) | none | `candidate.json` |

Run 2 started 2026-10-29T07:36:49Z and ended about 08:30Z (child time 3182 s).

## Run 2 results

| Lane | Result |
|---|---|
| core suite run directly | 2920 tests, 0 failures, 79 excluded |
| Swift package suite | 89 tests, 2 skipped, 0 failures |
| Android package suite (fresh JUnit XML) | 12 tests, 0 failures |
| node suite | 344 tests, 0 failures |
| enabled manifest lane | 11 tests, 0 excluded |
| enabled threadline lane | 5 tests, 0 excluded |
| wire contract and version | 19 tests; version `1.1.0` |
| example host proof | pass (1480 s) |

The vector controls rewrote their own receipts (`elixir-vectors.json`, `kotlin-vectors.json`, `swift-other-vectors.json`, `swift-request-vectors.json`) with fresh durations and hashes, as in amendment 1. Those rewrites are committed with the candidate record.

## SPEC-04

SPEC-04 stays moved to v29.0 and no further attempt was started.

## Residual items

- A landed proof for the merge of this fix needs its own recorded attempt and approval record. The landed mode still reads the single local ref `refs/crosswake/196-17-approval`, which names PR 260 (R-22).
- The local branch `docs/196-landed-evidence`, created by hand in the blocked attempt, already exists, and the landed mode creates that branch name when it succeeds. That clash is for the plan that runs the landed proof to resolve.
