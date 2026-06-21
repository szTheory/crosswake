---
phase: 123-native-package-behavioral-proof
plan: "01"
subsystem: bridge-contract
tags: [vectors, gen-task, behavioral-test, guard-01, elixir, ntest-01]
dependency_graph:
  requires: [121-03, 122-01]
  provides: [bridge_contract_vectors_7_vectors, ios_android_native_copies, elixir_behavioral_test, guard01_native_tripwires]
  affects: [123-02, 123-03]
tech_stack:
  added: []
  patterns: [pairs-list-encoding, write_if_changed-idempotency, bridge_findings-anti-vacuous-proof, compile-time-vector-load]
key_files:
  created:
    - test/crosswake/bridge/bridge_behavioral_vector_test.exs
    - packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/Resources/bridge_contract_vectors.json
    - packages/crosswake-shell-core-android/src/test/resources/bridge_contract_vectors.json
  modified:
    - lib/mix/tasks/crosswake.contract.gen.ex
    - test/fixtures/bridge_contract_vectors.json
    - test/crosswake/contract/contract_drift_test.exs
decisions:
  - "app.info.get command maps to app_info capability_id in Elixir Bridge.Registry; manifest and request must use app_info not the command string"
  - "session_override.capabilities keys use command names (app.info.get) in JSON; test translates to registry capability_id (app_info) via @command_to_cap_id module attribute"
  - "vec-004 inactive_route triggered by route_presence check (route not in manifest), not active_route check, because route_id == active_route_id when both are other-route"
  - "D-05 applied: GUARD-01 tripwire extended to 5 generated JSON paths; readability test count updated to seven"
metrics:
  duration: "5m 20s"
  completed: "2026-06-20"
  tasks: 3
  files: 6
status: complete
---

# Phase 123 Plan 01: Gen Task Expansion and Elixir Behavioral Proof Summary

Expanded the bridge contract gen task to author 7 vectors with session_override, emit byte-identical DO-NOT-EDIT copies to both native test-resource dirs, and delivered the Elixir behavioral vector test proving vectors map to real bridge_findings/2 decision logic (NTEST-01 anti-vacuous proof).

## What Was Built

### Task 1: Expanded gen task + 7-vector fixture + native copies

**`lib/mix/tasks/crosswake.contract.gen.ex`** — expanded in three ways:

1. Two new module attributes:
   ```elixir
   @ios_vectors_path "packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/Resources/bridge_contract_vectors.json"
   @android_vectors_path "packages/crosswake-shell-core-android/src/test/resources/bridge_contract_vectors.json"
   ```

2. Two new `write_if_changed` calls in `run/1` after the root `@vectors_path` emit, passing the same `vectors_json/4` expression (byte-identical copies).

3. `seed_vectors/1` expanded from 3 to 7 vectors. All 7 vectors gain a `session_override` key (existing vec-001..003 get empty list `[]`; new vec-004..007 get their overrides):

| Vector ID | Expected Outcome | Expected Denial | Elixir check that fires |
|-----------|-----------------|-----------------|------------------------|
| `vec-001-version-mismatch-deny` | deny | `compatibility_mismatch` | validate_bridge_protocol (check 4) |
| `vec-002-unknown-command-deny` | deny | `undeclared_capability` | validate_bridge_command (check 3) |
| `vec-003-canonical-version-ok` | ok | nil | none |
| `vec-004-inactive-route-deny` | deny | `inactive_route` | validate_route_presence (check 2) |
| `vec-005-origin-denied-deny` | deny | `origin_denied` | validate_origin (check 7) |
| `vec-006-pack-incompatible-deny` | deny | `pack_incompatible` | validate_packs (check 6) |
| `vec-007-capability-version-deny` | deny | `unavailable_capability` | validate_bridge_capability_version (check 3) |

**Fixtures generated:**
- `test/fixtures/bridge_contract_vectors.json` — canonical 7-vector fixture (regenerated)
- `packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/Resources/bridge_contract_vectors.json` — iOS copy (byte-identical, DO-NOT-EDIT)
- `packages/crosswake-shell-core-android/src/test/resources/bridge_contract_vectors.json` — Android copy (byte-identical, DO-NOT-EDIT)

Two consecutive gen runs produce zero diff (idempotent, GUARD-02-safe).

### Task 2: Elixir behavioral vector test

**`test/crosswake/bridge/bridge_behavioral_vector_test.exs`** — module `Crosswake.Bridge.BridgeVectorBehavioralTest`.

- Loads committed vectors at compile time via `@vectors Jason.decode!(File.read!("test/fixtures/bridge_contract_vectors.json"))`
- Reads `bridge_protocol_version` from `@vectors["bridge_protocol_version"]`, never hardcoded (D-10)
- `make_permissive_manifest/1` uses `Types.new_root/1`, `Types.new_host/0`, `Types.new_compatibility/1`, `Types.new_capability/1`, `Types.new_route_entry/1`, `SupportMatrix.canonical/0` factory functions (no raw struct literals)
- `make_permissive_request/1` uses `Contract.new_request/1`
- Single `for vector <- @vectors["vectors"]` parametric test: calls `bridge_findings/2` then `finding_to_denial/2`, asserts outcome and reason

**Key implementation detail:** The Elixir bridge registry maps command `"app.info.get"` to capability_id `"app_info"`. Manifest routes use `capabilities: ["app_info"]` and capability_registry uses `"app_info"`. The request carries `capability: "app_info"`. JSON session_override.capabilities uses the command name as key; the test translates via `@command_to_cap_id` module attribute.

### Task 3: GUARD-01 tripwire extension (D-05)

**`test/crosswake/contract/contract_drift_test.exs`** — added two paths to `@generated_json_paths`:
- `"packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/Resources/bridge_contract_vectors.json"`
- `"packages/crosswake-shell-core-android/src/test/resources/bridge_contract_vectors.json"`

Both carry `bridge_protocol_version` at the JSON document root, fitting `compare_generated_surface/3` with zero new helper code. Updated readability test description from "six" to "seven". All 5 existing tests pass.

## Decisions Made

- **D-05 applied:** GUARD-01 tripwire extended to include the two native vector copies (same JSON-root shape, zero new helper code, fast local developer experience).
- **`app_info` vs `app.info.get`:** The Elixir bridge registry capability_id is `"app_info"`, not `"app.info.get"`. All manifest/request construction uses `"app_info"`. Session_override JSON keys use command names and are translated via `@command_to_cap_id`.
- **`bridge_findings/2` accumulates, not short-circuits:** The pipeline prepends each failure. First element = last check that fired. Each vector is designed so exactly one check fires.
- **vec-004 route mechanism:** inactive_route is triggered by `validate_route_presence` (route "other-route" not in manifest), not `validate_active_route` (route_id == active_route_id = "other-route" passes that check).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Capability identity mismatch in behavioral test**
- **Found during:** Task 2 first run
- **Issue:** JSON request_override `"capability": "app.info.get"` was passed verbatim, but Elixir bridge validates `request.capability == Registry.command_capability(command)` = `"app_info"`. All vectors using `app.info.get` command produced `bridge_command` identity errors instead of targeting the intended check.
- **Fix:** Added `@command_to_cap_id` module attribute mapping command names to capability_ids; translated `raw_cap` via `Map.get(@command_to_cap_id, raw_cap, raw_cap)` in `make_permissive_request/1`. Unknown commands (vec-002: `"unknown.command"`) pass through verbatim, correctly triggering `bridge_command` check.
- **Files modified:** `test/crosswake/bridge/bridge_behavioral_vector_test.exs`
- **Commit:** d2d70f6

## Known Stubs

None. All vectors are real behavioral assertions against `bridge_findings/2`.

## Threat Surface Scan

No new network endpoints, auth paths, file access patterns, or schema changes at trust boundaries. The behavioral test reads only the committed fixture file at compile time (hermetic). The gen task writes local files only.

## Self-Check: PASSED

All created files exist on disk. All commits confirmed in git log.

| Check | Result |
|-------|--------|
| `test/crosswake/bridge/bridge_behavioral_vector_test.exs` | FOUND |
| `test/fixtures/bridge_contract_vectors.json` | FOUND |
| `packages/crosswake-shell-core-ios/.../Resources/bridge_contract_vectors.json` | FOUND |
| `packages/crosswake-shell-core-android/src/test/resources/bridge_contract_vectors.json` | FOUND |
| commit b368382 (Task 1 — gen task + fixtures) | FOUND |
| commit d2d70f6 (Task 2 — behavioral test) | FOUND |
| commit b4b6346 (Task 3 — GUARD-01 extension) | FOUND |
