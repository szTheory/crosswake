---
phase: 121-canonical-contract-source
plan: "02"
subsystem: contract-gen
tags: [canonical-contract, mix-task, idempotent, derived-surfaces, bridge-protocol]
dependency_graph:
  requires: ["121-01"]
  provides: ["mix crosswake.contract.gen", "test/fixtures/bridge_contract_vectors.json", "docs/_contract_snippet.md"]
  affects: ["Phase 122 (drift guards consume gen task)", "Phase 123 (bridge_contract_vectors.json seed schema)"]
tech_stack:
  added: []
  patterns: ["sorted-pairs-to-map idempotent JSON encoding", "write_if_changed idempotent file write", "Mix.Task.run(app.start) before reading Contract module"]
key_files:
  created:
    - lib/mix/tasks/crosswake.contract.gen.ex
    - test/fixtures/bridge_contract_vectors.json
    - docs/_contract_snippet.md
  modified:
    - examples/ios_shell_host/Fixtures/route_activation.json
    - examples/android_shell_host/app/src/main/assets/route_activation.json
decisions:
  - "Sorted-pairs-to-map approach for deterministic JSON: list of {key,value} tuples sorted by key, converted to Map.new(), then Jason.encode!(pretty: true) — guarantees byte-stable output independent of BEAM map ordering"
  - "write_if_changed/2 reads existing file before writing; skips write if content is identical — proven idempotent by second run reporting all four files unchanged"
  - "_generated_by key used for JSON files (no comment syntax in JSON); DO-NOT-EDIT HTML comment header for markdown docs snippet"
  - "docs/_contract_snippet.md placed under docs/ (new directory created by gen task)"
  - "seed vector IDs: vec-001-version-mismatch-deny, vec-002-unknown-command-deny, vec-003-canonical-version-ok"
metrics:
  duration: "4m"
  completed_date: "2026-06-20"
  tasks_completed: 2
  tasks_total: 2
  files_created: 3
  files_modified: 2
status: complete
---

# Phase 121 Plan 02: Contract Gen Task Summary

**One-liner:** `mix crosswake.contract.gen` — hermetic Mix task regenerating iOS/Android route_activation.json (bridge 1.0.0→1.1.0), new bridge_contract_vectors.json seed, and docs/_contract_snippet.md from `Contract.version()`, proven idempotent.

## What Was Built

### Task 1: Create mix crosswake.contract.gen

Created `lib/mix/tasks/crosswake.contract.gen.ex` defining `Mix.Tasks.Crosswake.Contract.Gen`.

Key design decisions:
- `run/1` calls `Mix.Task.run("app.start")` then reads `Crosswake.Bridge.Contract.version()` as the sole authority — no hardcoded version string drives any output
- `write_if_changed/2` helper mirrors `crosswake.gen.shell.ex`'s `ensure_file/2` pattern: `mkdir_p` + read-before-write, skipping write if content is already identical
- Deterministic JSON encoding via a `pairs_to_map/1` function: list of `{key, value}` 2-tuples sorted by key, converted to `Map.new()`, then `Jason.encode!(pretty: true)` — this produces byte-stable output on consecutive runs
- Never calls `Shell.Fixtures.export/1` (would emit wrong dashboard-route fixture)
- Never writes to any `build/` path
- Every generated JSON file carries `"_generated_by": "mix crosswake.contract.gen"`
- The docs snippet carries `<!-- DO NOT EDIT -->` HTML comment header

Commit: `ad1e058` (then amended in the outputs commit: `2477289`)

### Task 2: Run gen task, commit outputs, prove idempotency

Ran `mix crosswake.contract.gen`:

**Updated (bridge_protocol_version 1.0.0 → 1.1.0 + _generated_by marker):**
- `examples/ios_shell_host/Fixtures/route_activation.json` — correlation_id: `ios-example-capture-1`, native_runtime_version stays `1.0.0`
- `examples/android_shell_host/app/src/main/assets/route_activation.json` — correlation_id: `android-example-capture-1`, native_runtime_version stays `1.0.0`

**Created:**
- `test/fixtures/bridge_contract_vectors.json` — protocol + commands + denial_reasons from live Contract module + 3 seed vectors (see schema below)
- `docs/_contract_snippet.md` — generated markdown table with bridge 1.1.0, native-runtime 1.0.0, manifest-schema 1.0.0

**Idempotency proof:** Second `mix crosswake.contract.gen` run reported all four files "unchanged". Then `git diff --exit-code` on the four files exited 0 — CANON-03 satisfied.

Commit: `2477289`

## Seed Vectors in bridge_contract_vectors.json

Phase 123 consumes this file. The starting schema and vector IDs:

| ID | Request Override | Expected Outcome | Expected Denial Reason |
|----|-----------------|-----------------|----------------------|
| `vec-001-version-mismatch-deny` | `{"version": "1.0.0"}` | `deny` | `compatibility_mismatch` |
| `vec-002-unknown-command-deny` | `{"version": "1.1.0", "command": "unknown.command"}` | `deny` | `undeclared_capability` |
| `vec-003-canonical-version-ok` | `{"version": "1.1.0", "command": "app.info.get"}` | `ok` | `null` |

Top-level fields: `_comment`, `_generated_by`, `_regenerate`, `bridge_protocol_version`, `commands` (10 items from Contract.commands()), `denial_reasons` (12 items from Shell.Denial.reasons()), `manifest_schema_version`, `native_runtime_version`, `protocol`, `vectors`.

## Docs Snippet Path

`docs/_contract_snippet.md` — new `docs/` directory created by the gen task. Phase 124 public docs updates can include or reference this snippet.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Nested JSON objects encoded as escaped strings on first attempt**
- **Found during:** Task 2 first run
- **Issue:** `json_object/1` returned a string, but `json_value/1` treated any binary as a JSON string value (calling `Jason.encode!/1` on it, producing a double-escaped string). Two conflicting `json_value/1` clauses for `is_binary` meant the pre-encoded path was unreachable.
- **Fix:** Rewrote the encoding strategy. Instead of a string-building approach, used `pairs_to_map/1` which recursively converts `{key, value}` tuple lists into sorted plain Elixir maps, then calls `Jason.encode!(pretty: true)` once at the top level. This correctly produces nested JSON objects.
- **Files modified:** `lib/mix/tasks/crosswake.contract.gen.ex`
- **Commit:** included in `2477289`

**2. [Rule 1 - Bug] Unused variable `map` and duplicate Jason.Encoder.List impl warnings**
- **Found during:** Task 1 compile with --warnings-as-errors
- **Issue:** Intermediate draft had an unused `map =` binding and a conflicting `defimpl Jason.Encoder, for: List` that shadowed the Jason library's own implementation.
- **Fix:** Removed both; rewrote to the clean `pairs_to_map` approach that needs neither.
- **Files modified:** `lib/mix/tasks/crosswake.contract.gen.ex`
- **Commit:** included in `ad1e058`

## Threat Surface Scan

| Flag | File | Description |
|------|------|-------------|
| threat_flag: generated-marker | `test/fixtures/bridge_contract_vectors.json` | New file in `test/fixtures/` — carries `_generated_by` marker per T-121-03 mitigation |
| threat_flag: generated-marker | `docs/_contract_snippet.md` | New file in `docs/` — carries `<!-- DO NOT EDIT -->` header per T-121-03 mitigation |

No new network endpoints, auth paths, or trust-boundary schema changes introduced.

## Verification Results

| Check | Result |
|-------|--------|
| `mix help crosswake.contract.gen` | PASS — task registered |
| `grep -c 'Contract.version()' ...gen.ex` >= 1 | PASS — 2 occurrences |
| `grep -c 'Shell.Fixtures.export' ...gen.ex` = 0 | PASS |
| `grep -c 'build/' ...gen.ex` = 0 | PASS |
| `mix compile --warnings-as-errors` | PASS |
| bridge_protocol_version = 1.1.0 in both route_activation.json | PASS |
| native_runtime_version = 1.0.0 in both (D-03 axis discipline) | PASS |
| bridge_contract_vectors.json exists with bridge_protocol_version | PASS |
| No build/ or unrelated-fixture churn | PASS |
| Second run: all four files "unchanged" | PASS |
| `git diff --exit-code` on four files exits 0 | PASS — CANON-03 |

## Commits

| Hash | Message |
|------|---------|
| `ad1e058` | feat(121-02): add mix crosswake.contract.gen task |
| `2477289` | feat(121-02): run contract.gen — emit four derived surfaces at 1.1.0 |

## Self-Check: PASSED

- `lib/mix/tasks/crosswake.contract.gen.ex` — exists (committed `ad1e058`)
- `examples/ios_shell_host/Fixtures/route_activation.json` — exists, bridge_protocol_version=1.1.0
- `examples/android_shell_host/app/src/main/assets/route_activation.json` — exists, bridge_protocol_version=1.1.0
- `test/fixtures/bridge_contract_vectors.json` — exists (committed `2477289`)
- `docs/_contract_snippet.md` — exists (committed `2477289`)
- Commits `ad1e058` and `2477289` verified in git log
