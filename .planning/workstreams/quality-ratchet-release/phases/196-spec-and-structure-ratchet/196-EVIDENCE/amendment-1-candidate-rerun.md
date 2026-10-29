# Amendment 1 to the 196-15 candidate evidence (2026-10-29)

This file is added on top of the 196-15 evidence. The 196-15 summary and its recorded results are unchanged. The earlier candidate record is kept in git history at commit ab38497c.

## Why a new candidate run was needed

Plan 16 halted at exact-head CI. Four commits followed, and a fifth was needed during this amendment: a pinned-subject reader for shallow CI checkouts (45f402a1), a collection assertion ledger regeneration (1dab312f), the example host `bandit` 1.14.1 lock pin (via main, 4ebe37fe) and the merge of that main commit (e1951cf8). The fifth (ffcba481) removes an address-shaped fixture literal from the new helper test, because the privacy scan that `gate pr-open` runs flagged it. They changed the supported-source roster, so the candidate identity changed.

| Identity part | 196-15 candidate | This amendment |
|---|---|---|
| supported-source roster | `685bcd49...` (1374 blobs) | `bc288cde...` (1376 blobs) |
| `phase-evidence.mjs` whole file | `b4c1124e...` | `b4c1124e...` (unchanged) |
| `measure-main.mjs` whole file | `af5acfc3...` | `af5acfc3...` (unchanged) |
| preserved roster | `44019928...` | `44019928...` (unchanged) |

Neither tool was edited. The candidate record was produced by the same `phase-evidence.mjs candidate` command on local head `ffcba4813872ec7c5359cd3e4af7d3c8d152cd55` with origin/main at `4ebe37fe893f8ef420379d1f27c83bca37c0ce33`, and it replaces the earlier record at the same path, as the plan prescribes for a fresh candidate run.

## What was re-measured and what was not

- Re-run: all 40 candidate children, on the new identity.
- Review: amendment A-1 appended to `196-REVIEW.md` before the run (17 findings in all, none open). The privacy-scan finding R-17 was added after run 3 and before run 4.
- Not re-measured: the five actual-main receipts. Their guard blobs are byte-identical to the measured ones, and each receipt is pinned to main commit b8398c38. `measure-main.mjs verify-source` and `capture` now refuse with `main_ref_mismatch` because the pinned execution source names b8398c38 and main has moved. Re-pinning needs a tool edit, which plan 16 does not allow, so no capture was attempted.

## Candidate runs on this identity

Four runs of the full candidate were needed. Runs 1 to 3 ran on the roster `72e22d99...`; the privacy finding changed one test file, so run 4 is the one on the final identity `bc288cde...`. A failed run is retained, not hidden.

| Run | Verdict | Failing child | Retained record |
|---|---|---|---|
| 1 | fail | `example-host-proof` (exit 1 after 803 s) | `candidate-amendment-1-failed-run-1.json` |
| 2 | fail | `root-core-suite` (exit 2, 2920 tests, 1 failure, 79 excluded, after 918 s) | `candidate-amendment-1-failed-run-2.json` |
| 3 | pass (40 of 40) | none; superseded by the fixture edit before any push, so not the final identity | replaced in `candidate.json` by run 4 (committed at 393b7b51) |
| 4 | pass (40 of 40) | none | `candidate.json` |

The cause of the two failures was not observed: the candidate runner keeps only a hash of each child's output. What was checked afterwards:

- The example-host stage was re-run alone with `script/verify_repository.sh --stage example-host-proof` and exited 0.
- The core suite was re-run alone with the registry's own arguments (seed 748644, max cases 8) and reported 2920 tests, 0 failures, 79 excluded.
- Machine load averaged 17 to 33 during runs 1 and 2 because other repositories' jobs shared the machine, and it was 5 to 10 during runs 3 and 4. A local timeout is the likely class, since a different child failed each time and each passed alone, but this is an inference and not an observation.
- No code or test changed between runs 1, 2 and 3.

Run 3 passed on the same bytes as runs 1 and 2. This does not show that the two earlier failures cannot recur in CI.

## Run 4 results (identical counts to run 3)

| Lane | Result |
|---|---|
| core suite run directly | 2920 tests, 0 failures, 79 excluded |
| Swift package suite | 89 tests, 2 skipped, 0 failures |
| Android package suite (fresh JUnit XML) | 12 tests, 0 failures |
| node suite | 344 tests, 0 failures; secret masking 207 |
| enabled manifest lane | 11 tests, 0 excluded |
| enabled threadline lane | 5 tests, 0 excluded |
| wire contract and version | 19 tests; version `1.1.0` |
| new helper controls | included in the core suite count (5 more than the 196-15 run) |

Environment routes: Node used the asdf toolchain (v22.14.0, npm 10.9.2), the JDK route asserted java 17. Native proof is JVM-hermetic and Swift-package only, never device.

The vector controls rewrote their own receipts (`elixir-vectors.json`, `kotlin-vectors.json`, `swift-other-vectors.json`, `swift-request-vectors.json`) with fresh durations and hashes, as they did in 196-15. Those rewrites are committed with the candidate record.

## SPEC-04

SPEC-04 stays moved to v29.0 and no further attempt was started.
