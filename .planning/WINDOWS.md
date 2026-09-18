---
schema_version: 1
open_count: 34
waived_count: 0
fixed_count: 0
total_count: 34
last_updated: 2026-09-17T21:53:26.882Z
---

# Broken Windows Ledger

> Cross-phase defect register. With `workflow.windows_enforce` enabled, `/gsd-ship` blocks while `open_count > 0`.
> Waive with `gsd-tools windows waive <id> "<reason>"` (reason required).
> Mark fixed with `gsd-tools windows fixed <id>`.

| id | phase | kind | file | line | description | status | reason | recorded_at | resolved_at |
|----|-------|------|------|------|-------------|--------|--------|-------------|-------------|
| 1 | 154 | deviation | lib/crosswake/bridge/catalog_guard.ex |  | Cross-native enum drift: iOS carries connection.state.update where Kotlin carries server.state.update for the same outbound fan-out; both exempt as outbound-only so the guard does not fire. Recorded in SEED-008 Breadcrumbs. | open |  | 2026-07-29T23:35:11.008Z |  |
| 2 | 154 | deviation | lib/crosswake/bridge/catalog_guard.ex |  | Eight-entry out-of-vocabulary native denial allowlist (D-16 option-b): CTRL-02 is 'one typed denial at the adopter boundary', not 'one vocabulary on the wire', until SEED-008 is worked. | open |  | 2026-07-29T23:35:11.072Z |  |
| 3 | 155 | deviation | examples/phoenix_host/e2e/native_controls_fallback.spec.ts |  | Auto-fixed (Rule 1): hardcoded template_version=1 assertion updated to template_version=2 to match the 155-06 stamp bump | open |  | 2026-07-30T18:21:22.547Z |  |
| 4 | 158 | unrun-verify | test/crosswake/planning/first_adopter_context_test.exs |  | Broader Task 2 planning-context verification is blocked by the executor-start STATE.md transition. | open |  | 2026-07-31T13:45:25.123Z |  |
| 5 | 159 | stub | priv/templates/crosswake/proof_lane/ios/CrosswakeProofLane.xcodeproj/project.pbxproj.eex |  | Focused native XCTest/XCUITest source expansion is intentionally deferred to Plan 159-03. | open |  | 2026-07-31T20:45:02.500Z |  |
| 6 | 159 | deviation | priv/templates/crosswake/proof_lane/ios/CrosswakeProofLane.xcodeproj/project.pbxproj.eex |  | Auto-fixed incomplete PBX project skeleton so Xcode enumerates the proof-owned targets. | open |  | 2026-07-31T20:46:49.899Z |  |
| 7 | 159 | unrun-verify | script/verify_generated_ios_shell.sh |  | Fresh non-mocked native proof verifier remains unavailable until an installed concrete iPhone simulator exists. | open |  | 2026-08-01T00:46:07.479Z |  |
| 8 | 160 | deviation | examples/phoenix_host/e2e/support/offline_route_proof.ts | 293 | Scoped browser proof reader used legacy IndexedDB store after the scoped migration | open |  | 2026-08-02T17:35:34.942Z |  |
| 9 | 160 | deviation | examples/phoenix_host/e2e/offline_sync.spec.ts |  | Rule 1 test scope capture correction during legacy browser regression | open |  | 2026-08-03T02:40:38.572Z |  |
| 10 | 160 | deviation | examples/phoenix_host/e2e/crosswake_proof_lane/proof_lane.spec.ts |  | Generated proof adapter now establishes the existing request-bound test session before online replay | open |  | 2026-08-03T02:58:59.105Z |  |
| 11 | 160 | deviation | examples/phoenix_host/e2e/offline_sync.spec.ts |  | Activation replay console capture begins after unrelated setup reload teardown | open |  | 2026-08-03T02:58:59.173Z |  |
| 12 | 162 | deviation | script/verify_physical_iphone_report_contract.sh |  | Plan-named support-matrix Mix task was unavailable; existing support-matrix contract suite was run instead. | open |  | 2026-08-05T02:37:57.808Z |  |
| 13 | 162 | unrun-verify | .planning/phases/162-physical-iphone-adoption-proof/162-10-PLAN.md |  | Repository-wide adoption-context scan remains non-passing for the evidence completion marker and a pre-existing binary reference asset; it is not a passing verification claim. | open |  | 2026-08-26T17:41:03.526Z |  |
| 14 | 162 | deviation | lib/crosswake/support_matrix/renderer.ex |  | Used authorized source-bound Evidence.check/2 because Evidence.check/1 deliberately rejects approved hashes without supplied canonical source bytes. | open |  | 2026-08-26T17:41:03.602Z |  |
| 15 | 163.1 | deviation | examples/phoenix_host/native/ios/CrosswakeProofLane/ProofLaneDriver.swift |  | Reference proof target lacks CrosswakeShellCore linkage; private decoder preserves the closed transport boundary. | open |  | 2026-08-28T03:42:12.753Z |  |
| 16 | 163.1 | deviation | examples/phoenix_host/native/ios/CrosswakeProofLane.xcodeproj/project.pbxproj |  | Plan 163.1-05 added the local Core package and shared shell controller because physical composition otherwise could not compile. | open |  | 2026-08-28T13:07:34.571Z |  |
| 17 | 165 | unrun-verify | .github/workflows/release-please.yml | 27 | Repository-wide actionlint is blocked by the pre-existing unsupported concurrency.queue key and required-checks-audit SC2016 diagnostic; Plan 165-09 changed workflow lint passes. | open |  | 2026-09-08T18:32:27.078Z |  |
| 18 | 166 | deviation | test/fixtures/repository_quality/stage-cases.json |  | Corrected Java fixture quoting and added the missing Xcode version so exact preflight controls exercise intended scheduler behavior | open |  | 2026-09-09T17:00:42.334Z |  |
| 19 | 166 | deviation | script/verify_repository.mjs |  | Escaped hostile artifact paths and kept them out of remediation command text | open |  | 2026-09-09T17:23:36.661Z |  |
| 20 | 167 | deviation | README.md |  | Restored route-owner guidance before canonical support detail after the new answer-first copy changed navigation order. | open |  | 2026-09-10T21:17:04.170Z |  |
| 21 | 167 | deviation | guides/compatibility.md |  | Named the public SupportMatrix owner instead of linking ExDoc to its private change-class helper. | open |  | 2026-09-10T21:17:04.313Z |  |
| 22 | 168 | deviation | script/release_candidate/hex_artifacts.sh |  | Pinned Hex archive was resolved from the active Mix runtime. | open |  | 2026-09-13T03:10:29.898Z |  |
| 23 | 168 | deviation | script/release_candidate/hex_artifacts.sh |  | Companion audits were seeded from the candidate core tarball. | open |  | 2026-09-13T03:10:30.028Z |  |
| 24 | 168 | deviation | test/crosswake/release_candidate/artifact_test.exs |  | Artifact module loading was made deterministic across test seeds. | open |  | 2026-09-13T03:10:30.142Z |  |
| 25 | 168 | deviation | script/release_candidate/hex_artifacts.sh |  | Candidate dependency atoms were bounded to the known core dependency set. | open |  | 2026-09-13T03:10:30.254Z |  |
| 26 | 168 | deviation | script/release_candidate/hex_artifacts.sh |  | Invocation-local companion locks are serialized without a loaded Mix project. | open |  | 2026-09-13T03:10:30.367Z |  |
| 27 | 168 | deviation | script/release_candidate/hex_artifacts.sh |  | Pinned asdf versions are passed into exact-ref source snapshots. | open |  | 2026-09-13T03:10:30.456Z |  |
| 28 | 168 | deviation | lib/crosswake/release_candidate/artifact.ex |  | Official tuple-shaped Hex link metadata is normalized. | open |  | 2026-09-13T03:10:30.550Z |  |
| 29 | 168 | deviation | script/release_candidate/hex_artifacts.sh |  | Manifest paths are canonicalized across macOS temporary-directory aliases. | open |  | 2026-09-13T03:10:30.643Z |  |
| 30 | 168 | deviation | lib/crosswake/release_candidate/mirror.ex |  | Preserve observed mirror ref mutation in bounded evidence instead of normalizing external_state_changed to false | open |  | 2026-09-13T04:25:48.040Z |  |
| 31 | 168 | deviation | lib/crosswake/release_candidate/workflow.ex |  | Added executable linked-release workflow policy required for validated PARTIAL truth | open |  | 2026-09-13T05:29:51.085Z |  |
| 32 | 168 | deviation | lib/crosswake/release_candidate/receipt.ex | 185 | Extended bounded receipt coordinates to accept the fixed Maven group/artifact identity | open |  | 2026-09-13T05:29:51.445Z |  |
| 33 | 173 | deviation | .github/workflows/exact-public-proof.yml |  | Record-assertion step carries a step-level if: on the applicability marker; the job itself is if: always() and the marker step is unconditional | open |  | 2026-09-17T21:53:26.882Z |  |
| 34 | 173 | deviation | .github/workflows/exact-public-proof.yml |  | record-ledger is gated on needs.exact-public-proof.outputs.applicable == 'true'; when the proof job fails INSIDE the applicability step (bad lane, or recovery lane with blank approved_head/merge_oid) no output is emitted, so a recovery publish that already succeeded records no ledger row for its failed verdict. Run is red, so not a false green, but the durable record XPUB-06 promises is absent for exactly the XPUB-05 failure mode. | open |  | 2026-09-18T00:45:00.000Z |  |

````json
[
  {
    "id": 1,
    "kind": "deviation",
    "phase": "154",
    "file": "lib/crosswake/bridge/catalog_guard.ex",
    "line": null,
    "description": "Cross-native enum drift: iOS carries connection.state.update where Kotlin carries server.state.update for the same outbound fan-out; both exempt as outbound-only so the guard does not fire. Recorded in SEED-008 Breadcrumbs.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-29T23:35:11.008Z",
    "resolved_at": null
  },
  {
    "id": 2,
    "kind": "deviation",
    "phase": "154",
    "file": "lib/crosswake/bridge/catalog_guard.ex",
    "line": null,
    "description": "Eight-entry out-of-vocabulary native denial allowlist (D-16 option-b): CTRL-02 is 'one typed denial at the adopter boundary', not 'one vocabulary on the wire', until SEED-008 is worked.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-29T23:35:11.072Z",
    "resolved_at": null
  },
  {
    "id": 3,
    "kind": "deviation",
    "phase": "155",
    "file": "examples/phoenix_host/e2e/native_controls_fallback.spec.ts",
    "line": null,
    "description": "Auto-fixed (Rule 1): hardcoded template_version=1 assertion updated to template_version=2 to match the 155-06 stamp bump",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-30T18:21:22.547Z",
    "resolved_at": null
  },
  {
    "id": 4,
    "kind": "unrun-verify",
    "phase": "158",
    "file": "test/crosswake/planning/first_adopter_context_test.exs",
    "line": null,
    "description": "Broader Task 2 planning-context verification is blocked by the executor-start STATE.md transition.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-31T13:45:25.123Z",
    "resolved_at": null
  },
  {
    "id": 5,
    "kind": "stub",
    "phase": "159",
    "file": "priv/templates/crosswake/proof_lane/ios/CrosswakeProofLane.xcodeproj/project.pbxproj.eex",
    "line": null,
    "description": "Focused native XCTest/XCUITest source expansion is intentionally deferred to Plan 159-03.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-31T20:45:02.500Z",
    "resolved_at": null
  },
  {
    "id": 6,
    "kind": "deviation",
    "phase": "159",
    "file": "priv/templates/crosswake/proof_lane/ios/CrosswakeProofLane.xcodeproj/project.pbxproj.eex",
    "line": null,
    "description": "Auto-fixed incomplete PBX project skeleton so Xcode enumerates the proof-owned targets.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-31T20:46:49.899Z",
    "resolved_at": null
  },
  {
    "id": 7,
    "kind": "unrun-verify",
    "phase": "159",
    "file": "script/verify_generated_ios_shell.sh",
    "line": null,
    "description": "Fresh non-mocked native proof verifier remains unavailable until an installed concrete iPhone simulator exists.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-01T00:46:07.479Z",
    "resolved_at": null
  },
  {
    "id": 8,
    "kind": "deviation",
    "phase": "160",
    "file": "examples/phoenix_host/e2e/support/offline_route_proof.ts",
    "line": 293,
    "description": "Scoped browser proof reader used legacy IndexedDB store after the scoped migration",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-02T17:35:34.942Z",
    "resolved_at": null
  },
  {
    "id": 9,
    "kind": "deviation",
    "phase": "160",
    "file": "examples/phoenix_host/e2e/offline_sync.spec.ts",
    "line": null,
    "description": "Rule 1 test scope capture correction during legacy browser regression",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-03T02:40:38.572Z",
    "resolved_at": null
  },
  {
    "id": 10,
    "kind": "deviation",
    "phase": "160",
    "file": "examples/phoenix_host/e2e/crosswake_proof_lane/proof_lane.spec.ts",
    "line": null,
    "description": "Generated proof adapter now establishes the existing request-bound test session before online replay",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-03T02:58:59.105Z",
    "resolved_at": null
  },
  {
    "id": 11,
    "kind": "deviation",
    "phase": "160",
    "file": "examples/phoenix_host/e2e/offline_sync.spec.ts",
    "line": null,
    "description": "Activation replay console capture begins after unrelated setup reload teardown",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-03T02:58:59.173Z",
    "resolved_at": null
  },
  {
    "id": 12,
    "kind": "deviation",
    "phase": "162",
    "file": "script/verify_physical_iphone_report_contract.sh",
    "line": null,
    "description": "Plan-named support-matrix Mix task was unavailable; existing support-matrix contract suite was run instead.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-05T02:37:57.808Z",
    "resolved_at": null
  },
  {
    "id": 13,
    "kind": "unrun-verify",
    "phase": "162",
    "file": ".planning/phases/162-physical-iphone-adoption-proof/162-10-PLAN.md",
    "line": null,
    "description": "Repository-wide adoption-context scan remains non-passing for the evidence completion marker and a pre-existing binary reference asset; it is not a passing verification claim.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-26T17:41:03.526Z",
    "resolved_at": null
  },
  {
    "id": 14,
    "kind": "deviation",
    "phase": "162",
    "file": "lib/crosswake/support_matrix/renderer.ex",
    "line": null,
    "description": "Used authorized source-bound Evidence.check/2 because Evidence.check/1 deliberately rejects approved hashes without supplied canonical source bytes.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-26T17:41:03.602Z",
    "resolved_at": null
  },
  {
    "id": 15,
    "kind": "deviation",
    "phase": "163.1",
    "file": "examples/phoenix_host/native/ios/CrosswakeProofLane/ProofLaneDriver.swift",
    "line": null,
    "description": "Reference proof target lacks CrosswakeShellCore linkage; private decoder preserves the closed transport boundary.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-28T03:42:12.753Z",
    "resolved_at": null
  },
  {
    "id": 16,
    "kind": "deviation",
    "phase": "163.1",
    "file": "examples/phoenix_host/native/ios/CrosswakeProofLane.xcodeproj/project.pbxproj",
    "line": null,
    "description": "Plan 163.1-05 added the local Core package and shared shell controller because physical composition otherwise could not compile.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-28T13:07:34.571Z",
    "resolved_at": null
  },
  {
    "id": 17,
    "kind": "unrun-verify",
    "phase": "165",
    "file": ".github/workflows/release-please.yml",
    "line": 27,
    "description": "Repository-wide actionlint is blocked by the pre-existing unsupported concurrency.queue key and required-checks-audit SC2016 diagnostic; Plan 165-09 changed workflow lint passes.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-08T18:32:27.078Z",
    "resolved_at": null
  },
  {
    "id": 18,
    "kind": "deviation",
    "phase": "166",
    "file": "test/fixtures/repository_quality/stage-cases.json",
    "line": null,
    "description": "Corrected Java fixture quoting and added the missing Xcode version so exact preflight controls exercise intended scheduler behavior",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-09T17:00:42.334Z",
    "resolved_at": null
  },
  {
    "id": 19,
    "kind": "deviation",
    "phase": "166",
    "file": "script/verify_repository.mjs",
    "line": null,
    "description": "Escaped hostile artifact paths and kept them out of remediation command text",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-09T17:23:36.661Z",
    "resolved_at": null
  },
  {
    "id": 20,
    "kind": "deviation",
    "phase": "167",
    "file": "README.md",
    "line": null,
    "description": "Restored route-owner guidance before canonical support detail after the new answer-first copy changed navigation order.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-10T21:17:04.170Z",
    "resolved_at": null
  },
  {
    "id": 21,
    "kind": "deviation",
    "phase": "167",
    "file": "guides/compatibility.md",
    "line": null,
    "description": "Named the public SupportMatrix owner instead of linking ExDoc to its private change-class helper.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-10T21:17:04.313Z",
    "resolved_at": null
  },
  {
    "id": 22,
    "kind": "deviation",
    "phase": "168",
    "file": "script/release_candidate/hex_artifacts.sh",
    "line": null,
    "description": "Pinned Hex archive was resolved from the active Mix runtime.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-13T03:10:29.898Z",
    "resolved_at": null
  },
  {
    "id": 23,
    "kind": "deviation",
    "phase": "168",
    "file": "script/release_candidate/hex_artifacts.sh",
    "line": null,
    "description": "Companion audits were seeded from the candidate core tarball.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-13T03:10:30.028Z",
    "resolved_at": null
  },
  {
    "id": 24,
    "kind": "deviation",
    "phase": "168",
    "file": "test/crosswake/release_candidate/artifact_test.exs",
    "line": null,
    "description": "Artifact module loading was made deterministic across test seeds.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-13T03:10:30.142Z",
    "resolved_at": null
  },
  {
    "id": 25,
    "kind": "deviation",
    "phase": "168",
    "file": "script/release_candidate/hex_artifacts.sh",
    "line": null,
    "description": "Candidate dependency atoms were bounded to the known core dependency set.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-13T03:10:30.254Z",
    "resolved_at": null
  },
  {
    "id": 26,
    "kind": "deviation",
    "phase": "168",
    "file": "script/release_candidate/hex_artifacts.sh",
    "line": null,
    "description": "Invocation-local companion locks are serialized without a loaded Mix project.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-13T03:10:30.367Z",
    "resolved_at": null
  },
  {
    "id": 27,
    "kind": "deviation",
    "phase": "168",
    "file": "script/release_candidate/hex_artifacts.sh",
    "line": null,
    "description": "Pinned asdf versions are passed into exact-ref source snapshots.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-13T03:10:30.456Z",
    "resolved_at": null
  },
  {
    "id": 28,
    "kind": "deviation",
    "phase": "168",
    "file": "lib/crosswake/release_candidate/artifact.ex",
    "line": null,
    "description": "Official tuple-shaped Hex link metadata is normalized.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-13T03:10:30.550Z",
    "resolved_at": null
  },
  {
    "id": 29,
    "kind": "deviation",
    "phase": "168",
    "file": "script/release_candidate/hex_artifacts.sh",
    "line": null,
    "description": "Manifest paths are canonicalized across macOS temporary-directory aliases.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-13T03:10:30.643Z",
    "resolved_at": null
  },
  {
    "id": 30,
    "kind": "deviation",
    "phase": "168",
    "file": "lib/crosswake/release_candidate/mirror.ex",
    "line": null,
    "description": "Preserve observed mirror ref mutation in bounded evidence instead of normalizing external_state_changed to false",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-13T04:25:48.040Z",
    "resolved_at": null
  },
  {
    "id": 31,
    "kind": "deviation",
    "phase": "168",
    "file": "lib/crosswake/release_candidate/workflow.ex",
    "line": null,
    "description": "Added executable linked-release workflow policy required for validated PARTIAL truth",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-13T05:29:51.085Z",
    "resolved_at": null
  },
  {
    "id": 32,
    "kind": "deviation",
    "phase": "168",
    "file": "lib/crosswake/release_candidate/receipt.ex",
    "line": 185,
    "description": "Extended bounded receipt coordinates to accept the fixed Maven group/artifact identity",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-13T05:29:51.445Z",
    "resolved_at": null
  },
  {
    "id": 33,
    "kind": "deviation",
    "phase": "173",
    "file": ".github/workflows/exact-public-proof.yml",
    "line": null,
    "description": "Record-assertion step carries a step-level if: on the applicability marker; the job itself is if: always() and the marker step is unconditional",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-17T21:53:26.882Z",
    "resolved_at": null,
    "milestone": null
  },
  {
    "id": 34,
    "kind": "deviation",
    "phase": "173",
    "file": ".github/workflows/exact-public-proof.yml",
    "line": null,
    "description": "record-ledger is gated on needs.exact-public-proof.outputs.applicable == 'true'; when the proof job fails INSIDE the applicability step (bad lane, or recovery lane with blank approved_head/merge_oid) no output is emitted, so a recovery publish that already succeeded records no ledger row for its failed verdict. Run is red, so not a false green, but the durable record XPUB-06 promises is absent for exactly the XPUB-05 failure mode.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-09-18T00:45:00.000Z",
    "resolved_at": null,
    "milestone": null
  }
]
````
