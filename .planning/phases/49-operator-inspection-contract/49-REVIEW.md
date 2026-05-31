---
phase: 49-operator-inspection-contract
reviewed: 2026-05-31T21:05:00Z
depth: standard
files_reviewed: 9
files_reviewed_list:
  - lib/crosswake/operator_inspection.ex
  - lib/crosswake/operator_inspection/types.ex
  - lib/crosswake/operator_inspection/json_formatter.ex
  - lib/crosswake/operator_inspection/formatter.ex
  - lib/mix/tasks/crosswake.inspect.ex
  - test/crosswake/operator_inspection/operator_inspection_test.exs
  - test/crosswake/operator_inspection/json_formatter_test.exs
  - test/crosswake/operator_inspection/formatter_test.exs
  - test/mix/tasks/crosswake_inspect_test.exs
findings:
  critical: 1
  warning: 2
  info: 0
  total: 3
status: findings
---

# Phase 49: Code Review Report

**Reviewed:** 2026-05-31T21:05:00Z  
**Depth:** standard  
**Files Reviewed:** 9  
**Status:** issues_found

## Summary

Phase 49 correctly introduces a route-authoritative inspection surface, but the submitted implementation has one security defect and two correctness defects that misstate operator truth (proof/rebuild posture). These must be fixed before relying on this output for CI/support decisions.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Unbounded Atom Creation From CLI Input

**Classification:** BLOCKER  
**File:** `lib/mix/tasks/crosswake.inspect.ex:49`  
**Issue:** `String.to_atom(name)` creates atoms from untrusted CLI input. Atoms are not garbage-collected; repeated invocation with unique names can exhaust the VM atom table (DoS vector).  
**Fix:**
```elixir
defp router_module!(name) when is_binary(name) do
  module =
    try do
      String.to_existing_atom(name)
    rescue
      ArgumentError -> Mix.raise("router module #{name} is not available")
    end

  if Code.ensure_loaded?(module) do
    module
  else
    Mix.raise("router module #{name} is not available")
  end
end
```

## Warnings

### WR-01: Proof Class Is Computed Only From Capabilities, Ignoring Other Advisory Axes

**Classification:** WARNING  
**File:** `lib/crosswake/operator_inspection.ex:345-350`  
**Issue:** `support.proof_class` is set from capability proof class only. Routes with no capabilities but advisory verification requirements (e.g., commerce/auth/notification/companion) can be mislabeled `merge_blocking`, producing incorrect operator truth.  
**Fix:** Derive `proof_class` from all route readiness axes (capabilities + commerce advisory provider proof + companion/auth/notification verification signals), or compute from already-derived `support.status`/blocking reasons with explicit rules.

### WR-02: Commerce Rebuild Marks Companion Required Whenever Native Is Required

**Classification:** WARNING  
**File:** `lib/crosswake/operator_inspection.ex:210-214`  
**Issue:** `commerce_rebuild/1` sets `companion_required: native_required`, which conflates two independent rebuild axes and can over-report companion rebuild requirements. This distorts `rebuild_required_count`, route conditions, and support posture.  
**Fix:** Use dedicated companion rebuild data (if available) or default companion requirement to `false` unless explicitly indicated by support truth.

---

_Reviewed: 2026-05-31T21:05:00Z_  
_Reviewer: the agent (gsd-code-reviewer)_  
_Depth: standard_
