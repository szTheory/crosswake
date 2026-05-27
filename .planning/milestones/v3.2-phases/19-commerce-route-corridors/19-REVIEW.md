---
status: issues_found
phase: 19-commerce-route-corridors
updated: 2026-05-27T09:35:05Z
---

# Phase 19 Advisory Review

Reviewed scope:
- Plan execution changes for `19-01`, `19-02`, and `19-03` across `lib/`, `guides/`, and `test/`.
- Commit window analyzed: `0562919` through `d1a817b` (+ summaries/docs context).
- Verification run: phase-focused test suite (105 tests) passed.

## Findings

### MEDIUM - Commerce corridor remapping over-classifies unrelated capability failures
- **Files:** `lib/crosswake/compatibility/route_gate.ex`, `lib/crosswake/compatibility/compatibility.ex`
- **Issue:** For any route that has `commerce` metadata, `RouteGate.remap_commerce_corridor_findings/2` rewrites all `:capability_registry` and `:capability_version` findings to `:commerce_corridor_prerequisite_missing` without checking whether the capability is actually commerce-related. This causes unrelated capability failures (for example `haptics`) to be reported as corridor prerequisite denials.
- **Why this matters:** Activation and diagnostics lose root-cause precision. A non-commerce capability mismatch can surface as `commerce.corridor.prerequisite_missing`, which can mislead operators and hide the actual failing capability family.
- **Reproduction evidence:** Running a synthetic route-gate check with a commerce route that also requires `haptics` produced:
  - `{:commerce_corridor, "commerce.corridor.prerequisite_missing", %{subject: "haptics", ...}}`
- **Suggested direction:** Only remap capability findings to corridor prerequisites when the failing subject belongs to the corridor prerequisite set (or a dedicated commerce capability allowlist). Preserve original capability axes/codes for unrelated failures.

## Test Coverage Gaps

- **LOW - Missing regression test for mixed commerce + non-commerce capability failures**
  - **File:** `test/crosswake/compatibility/compatibility_test.exs`
  - Current tests validate canonical corridor mapping and corridor-native scenarios, but do not assert behavior when a commerce route fails due to unrelated capabilities. Add a test that ensures non-commerce capability mismatches keep non-corridor denial semantics.

## Security / Regression Summary

- No direct security vulnerability found in the reviewed phase-19 changes.
- Main residual risk is diagnostic and denial-code misclassification for mixed-capability commerce routes.
