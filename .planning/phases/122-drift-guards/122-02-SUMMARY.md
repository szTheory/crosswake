---
phase: 122-drift-guards
plan: "02"
subsystem: doctor
tags: [guard, doctor, contract-version, drift-detection, read-only-parse]
dependency_graph:
  requires: [122-01]
  provides: [contract_version_parity_check, operator-facing-drift-detection]
  affects: [lib/crosswake/doctor/publish_readiness.ex, test/crosswake/doctor/publish_readiness_test.exs]
tech_stack:
  added: []
  patterns: [result_check helper, Jason.decode per-surface, get_in for nested manifest path]
key_files:
  created: []
  modified:
    - lib/crosswake/doctor/publish_readiness.ex
    - test/crosswake/doctor/publish_readiness_test.exs
    - test/fixtures/proof/phase52_publish_readiness.json
    - test/fixtures/proof/phase52_operator_inspection.json
decisions:
  - "Manifests read bridge_protocol_version from get_in(decoded, [\"compatibility\", \"bridge_protocol_version\"]) — NOT the document root. Generated JSONs read decoded[\"bridge_protocol_version\"] at root. Per-surface path resolution matches contract_drift_test.exs from 122-01."
  - "docs_reference uses guides/compatibility.md (already in @allowed_docs allow-list; fits semantically for a contract compatibility check)."
  - "proof_class: :merge_blocking — same as generator_coordinate_parity_check; contract version drift is a deterministic correctness defect."
  - "Missing or undecodable surfaces accumulate explicit error strings and block (T-122-06 mitigation)."
metrics:
  duration: "14m"
  completed: "2026-06-20"
  tasks: 2
  files: 4
status: complete
---

# Phase 122 Plan 02: Contract Version Parity Doctor Check Summary

Adds GUARD-03: a `contract_version_parity` doctor check in `Crosswake.Doctor.PublishReadiness`, a read-only JSON-parse check that decodes all five committed contract surfaces from cwd and compares each surface's `bridge_protocol_version` to `Crosswake.Bridge.Contract.version()`, reporting drift at `:error`/`:merge_blocking` severity without requiring operators to read CI logs.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| RED  | Failing category-presence test | 52579a0 | publish_readiness_test.exs |
| T1 GREEN | contract_version_parity_check/1 + build_checks registration | 8c5e0fd | publish_readiness.ex |
| T2 | Full tests (positive + drift) + fixture fixes | cda0b5f | publish_readiness_test.exs, phase52_*.json |

## What Was Built

### `contract_version_parity_check/1` in `lib/crosswake/doctor/publish_readiness.ex`

A private check function (lines 594+) modeled on `generator_coordinate_parity_check/1`:

- Resolves `expected = Crosswake.Bridge.Contract.version()` at call time (never a literal)
- Enumerates two manifest surfaces and three generated JSON surfaces
- **Manifests**: reads `get_in(decoded, ["compatibility", "bridge_protocol_version"])` — the version is nested under the `"compatibility"` key, NOT at the document root
- **Generated JSONs**: reads `decoded["bridge_protocol_version"]` at the document root
- Missing or undecodable file → explicit error string (T-122-06: no silent pass)
- Returns `result_check(id: "contract.version_parity", category: :contract_version_parity, code: diag.contract.version_parity_ok|_failed, passed?: errors == [], proof_class: :merge_blocking, docs_reference: "guides/compatibility.md", ...)`
- Never calls `Mix.Task.run` or `File.write` — read-only parse only (T-122-04 mitigation)
- Registered in `build_checks/4` next to `generator_coordinate_parity_check(cwd)`

### Tests in `test/crosswake/doctor/publish_readiness_test.exs`

Three new test additions:
1. **Category-presence assertions**: `:contract_version_parity` in categories, `diag.contract.` code prefix present
2. **Positive test**: check is `:pass` / not blocking on the real committed tree (all surfaces at 1.1.0)
3. **Drift test**: tmp_dir! with iOS manifest carrying `"compatibility" => %{"bridge_protocol_version" => "0.9.0"}` (nested path, matching how real manifests store the version), other four surfaces correct — asserts `blocking==true`, `result==:fail`, `severity==:error`, `proof_class==:merge_blocking`, drifted path appears in `details.errors`

## Deviations from Plan

### Critical Path-Resolution Deviation (Orchestrator-flagged)

**What the plan said:** "fetch top-level bridge_protocol_version" for all five surfaces.

**What was actually required:** The two hand-maintained manifests (`crosswake_manifest.json`) store the version at the NESTED path `compatibility.bridge_protocol_version` — the document root has NO `bridge_protocol_version` key. Reading the root returns `nil` and would falsely report the current (correct) tree as drifted.

**Fix applied:** Per-surface path resolution matching `contract_drift_test.exs` (122-01):
- Manifests: `get_in(decoded, ["compatibility", "bridge_protocol_version"])`
- Generated JSONs: `decoded["bridge_protocol_version"]` at root

This was flagged in the `<critical_deviation_from_prior_plan>` block by the orchestrator and verified against 122-01's committed test before any code was written.

### Rule 1: Fixed stale proof fixtures (pre-existing failures)

**Found during:** Task 2 fixture verification  
**Issue 1:** `test/fixtures/proof/phase52_publish_readiness.json` was missing the new `contract_version_parity` check entry (expected after adding the check) AND missing three `docs_extras` entries from phases 117-118 (`guides/route_policy.md`, `guides/troubleshooting.md`, `guides/web_to_mobile_migration.md`).  
**Issue 2:** `test/fixtures/proof/phase52_operator_inspection.json` had `source.bridge_protocol_version: "1.0.0"` but Phase 121 bumped `Crosswake.Bridge.Contract.@version` to `"1.1.0"` without updating this fixture.  
**Fix:** Updated both fixtures to match actual normalized output. Both `phase52_operator_truth_test.exs` tests now pass.  
**Commits:** cda0b5f

## Verification Results

- `mix compile --warnings-as-errors`: PASSED
- `mix test test/crosswake/doctor/publish_readiness_test.exs`: 11 tests, 0 failures
- `mix test test/crosswake/contract/contract_drift_test.exs`: 5 tests, 0 failures
- `mix test test/crosswake/proof/phase52_operator_truth_test.exs`: 6 tests, 0 failures
- Full `mix test`: 1132 tests, 4 failures (4 failures are pre-existing, not caused by this plan: HexPageTest x2, Phase48ProviderAdapterProofTest, Phase69DocsContractParityTest)

## Known Stubs

None. The check reads and decodes real committed files; all surfaces at the canonical version produce `:pass`.

## Threat Flags

No new threat surface introduced. The check reads fixed relative paths joined under `cwd`; no operator-supplied path enters the check (T-122-05 accepted per plan). The check is read-only parse (T-122-04 mitigated by source assertion). Missing/undecodable surfaces produce explicit blocking errors (T-122-06 mitigated by test).

## Self-Check: PASSED

Files created/modified:
- `lib/crosswake/doctor/publish_readiness.ex`: contains `defp contract_version_parity_check` at line 594 — FOUND
- `test/crosswake/doctor/publish_readiness_test.exs`: contains drift test and positive test — FOUND
- `test/fixtures/proof/phase52_publish_readiness.json`: updated — FOUND
- `test/fixtures/proof/phase52_operator_inspection.json`: updated — FOUND

Commits:
- 52579a0 (RED) — FOUND
- 8c5e0fd (GREEN implementation) — FOUND
- cda0b5f (tests + fixture fixes) — FOUND
