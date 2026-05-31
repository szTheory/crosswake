---
phase: 47-companion-arc-guide-and-milestone-proof
reviewed: 2026-05-31T18:05:00Z
depth: standard
files_reviewed: 3
files_reviewed_list:
  - guides/companions.md
  - test/crosswake/guides/companions_test.exs
  - test/crosswake/proof/phase47_companion_arc_test.exs
findings:
  critical: 0
  warning: 4
  info: 0
  total: 4
status: issues_found
---

# Phase 47: Code Review Report

**Reviewed:** 2026-05-31T18:05:00Z
**Depth:** standard
**Files Reviewed:** 3
**Status:** issues_found

## Summary

Reviewed the companion guide and its proof/docs-contract tests for bugs, false support claims, optional-dependency fail-open risk, and maintainability. No direct security vulnerabilities were found in scope, but the proof and docs-contract tests include brittle assertions that can fail on benign internal changes and weaken long-term contract reliability.

## Narrative Findings (AI reviewer)

## Warnings

### WR-01: Docs-contract test can pass even if companion IDs are missing from the intended sections

**File:** `test/crosswake/guides/companions_test.exs:103`
**Issue:** The parity check only asserts `content =~ "#{companion_id}"` anywhere in the full guide body. This can produce false positives if the companion ID appears incidentally (for example in another section or code sample) while the intended support-truth section drifts or is deleted.
**Fix:** Assert against a scoped section or stronger anchor sentence instead of whole-file substring checks.
```elixir
# Example: extract/support-truth section first, then assert explicit labels.
assert support_truth_section =~ "Companion id: `:rindle`"
```

### WR-02: Proof test is over-coupled to exact denial-details shape for missing auth context

**File:** `test/crosswake/proof/phase47_companion_arc_test.exs:153`
**Issue:** The test enforces an exact key set (`["evaluated_at"]`) for `missing_context_decision.denial.details`. Any additive, safe metadata added later will break this proof despite preserving fail-closed behavior and denial reason semantics.
**Fix:** Assert required keys and reason semantics, not exact-map equality.
```elixir
assert missing_context_decision.denial.reason == :step_up_required
assert Map.has_key?(missing_context_decision.denial.details, "evaluated_at")
```

### WR-03: Optional-dependency proof is brittle by asserting exact missing module lists

**File:** `test/crosswake/proof/phase47_companion_arc_test.exs:116`
**Issue:** The test expects exact arrays (`[:"Elixir.Rulestead"]`, `[:"Elixir.Rindle"]`). If dependency validation later adds additional transitive/modules while still correctly reporting missing optional deps, this proof fails for non-breaking behavior.
**Fix:** Assert containment instead of exact list equality.
```elixir
assert :"Elixir.Rulestead" in rulestead_finding.details.missing_modules
assert :"Elixir.Rindle" in rindle_finding.details.missing_modules
```

### WR-04: Proof setup leaves temp directories behind, causing avoidable test-environment drift

**File:** `test/crosswake/proof/phase47_companion_arc_test.exs:54`
**Issue:** The test creates unique temp directories/files but never removes them. Over time this causes filesystem clutter and can create environmental noise for repeated local/CI runs.
**Fix:** Register cleanup in `on_exit/1` for the temp target path.
```elixir
on_exit(fn ->
  File.rm_rf(target)
  Application.delete_env(:crosswake, :companions)
  Application.delete_env(:crosswake, :rulestead)
  Application.delete_env(:crosswake, :rindle)
end)
```

---

_Reviewed: 2026-05-31T18:05:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
