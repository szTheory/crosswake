# Phase 180 probe tests inverted in place (Phase 191, D-14, A-7)

Each test below used to assert the fact observed before the Phase 180 decision. It now asserts the fact that the Phase 180 gate record decided.

| Gate | Where | Decided fact it now asserts |
|---|---|---|
| G1 | root proof tests (Plan 05) | The host audio command validates cleanly on an offline_island route, and an unknown capability yields exactly one capabilities error. |
| G2 | example host | The generated activation for the probe route carries exactly the host audio command at version 1.0.0 (exact map equality). |
| G6 | example host | Exactly one compiled route declares a host capability: the offline study route with only the host audio command, and its runtime is offline_island (exact list equality). |
| G4 | Swift shell core | The bounded shell admits an offline_island runtime (the result is the offlineIsland presentation). The test was renamed to say so. |

G3 (Swift) was not inverted (A-7). It already passes when the export exists. Its two tests skip by default because the export is not present, and the export-enabled run (suite-SWIFT-EXPORT) shows both passing with 0 skips and 0 failures. The two default skips are therefore justified by an observed pass; they are listed by name in swift-allowed-skips-191.txt.

The Phase 180 records are unchanged. Their test_files_sha256 pins are historical: two had already drifted before Phase 191, and these edits move the pinned test files further. Nothing re-pins them.

Fact for Phase 193: no CI lane runs the full example-host suite, so the G2 and G6 failures were never visible in CI. CI is not changed in Phase 191.
