---
phase: 158-adoption-reset-and-route-map
reviewed: 2026-07-31T16:41:00Z
depth: standard
files_reviewed: 15
files_reviewed_list:
  - .github/workflows/hex-page-proof.yml
  - guides/capability_map.md
  - guides/support_matrix.md
  - lib/crosswake/adoption/route_inventory.ex
  - lib/crosswake/capability_map.ex
  - lib/crosswake/capability_map/renderer.ex
  - lib/crosswake/planning/first_adopter_context.ex
  - lib/crosswake/support_matrix/renderer.ex
  - lib/mix/tasks/crosswake.adoption_context.scan.ex
  - test/crosswake/adoption/route_inventory_test.exs
  - test/crosswake/capability_map/capability_map_test.exs
  - test/crosswake/capability_map/renderer_test.exs
  - test/crosswake/planning/first_adopter_context_test.exs
  - test/crosswake/support_matrix/renderer_test.exs
  - test/mix/tasks/crosswake_adoption_context_scan_test.exs
findings:
  critical: 1
  warning: 0
  info: 0
  total: 1
status: issues_found
---

# Phase 158: Code Review Report

**Reviewed:** 2026-07-31T16:41:00Z
**Depth:** standard
**Files Reviewed:** 15
**Status:** issues_found

## Summary

The selected tests pass, but the protected privacy scan covers only an allowlist of a few files. New repository-facing source, guide, workflow, or later-phase artifact paths fall outside that allowlist and can carry a configured private adopter term without being inspected.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Privacy gate silently skips unregistered repository artifacts

**File:** `/Users/jon/projects/crosswake/lib/crosswake/planning/first_adopter_context.ex:29-51`

**Classification:** BLOCKER

**Issue:** `scan_filesystem/2` discovers files only through this fixed, narrow `@artifact_globs` list. It does not scan new guides, workflows, most library modules, test files, or any phase other than 158. For example, a future `.planning/phases/159-*/` artifact or a new guide can contain a value from `CROSSWAKE_PRIVATE_ADOPTER_TERMS` and the CI task reports success because `discovered_entries/1` never returns that path. This violates the fail-closed privacy boundary: sensitive adopter data can be committed to a repository-facing artifact while the "protected" scan passes.

**Fix:** Make repository-facing artifacts exhaustive by deriving the scan set from tracked, non-ignored files and classifying every path, or expand the registered glob policy to cover every permitted source/documentation/phase directory and fail when a tracked file has no destination. Add a regression test that places a configured private term in an unregistered future-phase or guide file and asserts `privacy.private_term`.

```elixir
# Require every repository-facing path to be classified before its contents are read.
unclassified =
  tracked_repository_paths(root)
  |> Enum.reject(&classified_by_artifact_glob?/1)

if unclassified != [] do
  Enum.map(unclassified, &%{rule_id: "routing.unclassified_path", path: &1})
else
  filesystem_content_violations(discovered_entries(root), terms)
end
```

---

_Reviewed: 2026-07-31T16:41:00Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
