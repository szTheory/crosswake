---
phase: 158-adoption-reset-and-route-map
reviewed: 2026-07-31T18:02:01Z
depth: standard
files_reviewed: 16
files_reviewed_list:
  - .github/workflows/hex-page-proof.yml
  - guides/capability_map.md
  - guides/support_matrix.md
  - lib/crosswake/adoption/route_inventory.ex
  - lib/crosswake/capability_map.ex
  - lib/crosswake/capability_map/renderer.ex
  - lib/crosswake/planning/first_adopter_context.ex
  - lib/crosswake/support_matrix/renderer.ex
  - lib/crosswake/support_matrix/support_matrix.ex
  - lib/mix/tasks/crosswake.adoption_context.scan.ex
  - test/crosswake/adoption/route_inventory_test.exs
  - test/crosswake/capability_map/capability_map_test.exs
  - test/crosswake/capability_map/renderer_test.exs
  - test/crosswake/planning/first_adopter_context_test.exs
  - test/crosswake/support_matrix/renderer_test.exs
  - test/mix/tasks/crosswake_adoption_context_scan_test.exs
findings:
  critical: 2
  warning: 1
  info: 0
  total: 3
status: issues_found
---

# Phase 158: Code Review Report

**Reviewed:** 2026-07-31T18:02:01Z
**Depth:** standard
**Files Reviewed:** 16
**Status:** issues_found

## Summary

The route-inventory validation and generated-guide parity checks are largely well covered. The new repository privacy scan, however, leaves important repository-facing content outside its non-secret rules and can echo attacker-controlled map keys in validation errors. The focused suite passed, but it does not exercise either boundary.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Generic privacy rules do not cover newly added repository artifacts

**File:** `lib/crosswake/planning/first_adopter_context.ex:301-304, 399-400`

**Issue:** `policy_scan_path?/1` limits commercial-detail, identifying-field, and public-wording checks to the small named-artifact list plus this phase directory. Every other scannable repository file is still discovered and read, but `policy_violations/2` returns no generic violations for it. Consequently, an unregistered guide, workflow, source file, script, or later phase artifact can contain prohibited public-facing detail and the normal CI scan passes whenever no configured private term happens to match it. This violates the required fail-closed repository privacy boundary.

**Fix:** Apply `generic_violations/2` to every `scan?: true` entry. Classify all public guide paths as `:public` (or equivalently apply the public wording checks to all public renderings), then retain only the destination-specific rules behind the destination check. Add filesystem tests using unregistered guide and source paths with sanitized synthetic prohibited patterns and an empty private-term list.

### CR-02: Route validation error messages can disclose caller-controlled map keys

**File:** `lib/crosswake/adoption/route_inventory.ex:148, 158-162, 433-440`

**Issue:** Map input is converted directly with `Map.to_list/1`; non-atom keys then reach `reject_unknown_fields/1`. The selected key is interpolated into `ValidationError.message` as the field name. A caller can therefore put sensitive text in a string key and cause it to be emitted to logs or diagnostics, despite this module's explicit no-echo privacy contract. Existing tests only prove that rejected *values* are omitted.

**Fix:** Reject any non-atom input key before building a field-specific error, using a stable generic field label such as `"route_row"`; do not interpolate untrusted keys. Add a test that passes a map with a synthetic sensitive string key and asserts neither the key nor its value appears in `Exception.message/1`.

## Warnings

### WR-01: CI executes third-party actions from mutable version tags

**File:** `.github/workflows/hex-page-proof.yml:38, 41`

**Issue:** The workflow executes third-party actions by movable `@v7` and `@v1` tags. A retagged or compromised upstream release changes CI code without a repository review, including jobs that access repository checkout and secrets on trusted runs.

**Fix:** Pin each `uses:` reference to a reviewed full commit SHA and annotate it with the intended release version; update pins through a controlled dependency-update process.

---

_Reviewed: 2026-07-31T18:02:01Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
