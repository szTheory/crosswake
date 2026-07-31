---
schema_version: 1
open_count: 6
waived_count: 0
fixed_count: 0
total_count: 6
last_updated: 2026-07-31T20:46:49.899Z
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
  }
]
````
