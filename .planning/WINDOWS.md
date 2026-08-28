---
schema_version: 1
open_count: 16
waived_count: 0
fixed_count: 0
total_count: 16
last_updated: 2026-08-28T13:07:34.571Z
---

# Broken Windows Ledger

> Cross-phase defect register. `/gsd-ship` blocks while `open_count > 0`.
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
  }
]
````
