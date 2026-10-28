# Amendment 1 to the 196-15 candidate evidence (2026-10-29)

This file is added on top of the 196-15 evidence. The 196-15 summary and its recorded results are unchanged. The earlier candidate record is kept in git history at commit ab38497c.

## Why a new candidate run was needed

Plan 16 halted at exact-head CI. Four commits followed: a pinned-subject reader for shallow CI checkouts (45f402a1), a collection assertion ledger regeneration (1dab312f), the example host `bandit` 1.14.1 lock pin (via main, 4ebe37fe) and the merge of that main commit (e1951cf8). They changed the supported-source roster, so the candidate identity changed.

| Identity part | 196-15 candidate | This amendment |
|---|---|---|
| supported-source roster | `685bcd49...` (1374 blobs) | `72e22d99...` (1376 blobs) |
| `phase-evidence.mjs` whole file | `b4c1124e...` | `b4c1124e...` (unchanged) |
| `measure-main.mjs` whole file | `af5acfc3...` | `af5acfc3...` (unchanged) |
| preserved roster | `44019928...` | `44019928...` (unchanged) |

Neither tool was edited. The candidate record was produced by the same `phase-evidence.mjs candidate` command on local head `d76d1507f17733460524e30f7d7be8fa1a72c20d` with origin/main at `4ebe37fe893f8ef420379d1f27c83bca37c0ce33`, and it replaces the earlier record at the same path, as the plan prescribes for a fresh candidate run.

## What was re-measured and what was not

- Re-run: all 40 candidate children, on the new identity.
- Review: amendment A-1 appended to `196-REVIEW.md` before the run, with no open finding.
- Not re-measured: the five actual-main receipts. Their guard blobs are byte-identical to the measured ones, and each receipt is pinned to main commit b8398c38. `measure-main.mjs verify-source` and `capture` now refuse with `main_ref_mismatch` because the pinned execution source names b8398c38 and main has moved. Re-pinning needs a tool edit, which plan 16 does not allow, so no capture was attempted.

## Candidate runs on this identity

Three runs of the full candidate were needed. A failed run is retained, not hidden.

| Run | Verdict | Failing child | Retained record |
|---|---|---|---|
| 1 | fail | `example-host-proof` (exit 1 after 803 s) | `candidate-amendment-1-failed-run-1.json` |
| 2 | fail | `root-core-suite` (exit 2, 2920 tests, 1 failure, 79 excluded, after 918 s) | `candidate-amendment-1-failed-run-2.json` |
| 3 | pass | none (40 of 40) | `candidate.json` |

The cause of the two failures was not observed: the candidate runner keeps only a hash of each child's output. What was checked afterwards:

- The example-host stage was re-run alone with `script/verify_repository.sh --stage example-host-proof` and exited 0.
- The core suite was re-run alone with the registry's own arguments (seed 748644, max cases 8) and reported 2920 tests, 0 failures, 79 excluded.
- Machine load averaged 17 to 33 during runs 1 and 2 because other repositories' jobs shared the machine, and it was 5 to 10 during run 3. A local timeout is the likely class, since a different child failed each time and each passed alone, but this is an inference and not an observation.
- No code or test changed between the runs.

Run 3 passed on the same bytes. This does not show that the two earlier failures cannot recur in CI.

## Run 3 results

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
