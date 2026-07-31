---
phase: 158-adoption-reset-and-route-map
reviewed: 2026-07-31T17:25:34Z
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
  critical: 1
  warning: 0
  info: 0
  total: 1
status: issues_found
---

# Phase 158: Code Review Report

**Reviewed:** 2026-07-31T17:25:34Z
**Depth:** standard
**Files Reviewed:** 16
**Status:** issues_found

## Summary

The route-inventory, canonical map/rendering contracts, and focused test suite were reviewed. The privacy gate is not repository-wide as claimed: its classifier silently excludes executable CI/action/script files and all phase artifacts outside a fixed 158–162 range. A private term in those tracked, non-ignored files passes the protected scan and can ship.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Private-term scanner has permanent unscanned repository paths

**File:** `lib/crosswake/planning/first_adopter_context.ex:265-273,284-288,320-340,401-412`

**Issue:** `classify_repository_path/1` returns `{:excluded, :forbidden}` for every `.github/actions/` and `script/` file, and for all `.planning/` content after the narrowly hard-coded phase regex. Excluded entries have `scan?: false`, so `filesystem_content_violations/2` drops them before generic or private-term checks. Consequently a tracked, non-ignored `.github/actions/*.yml`, `script/*.sh`, or `.planning/phases/163-.../*.md` file containing a protected adopter term returns no `privacy.private_term` violation. This contradicts the claimed Git-backed, repository-facing protected scan and creates a direct privacy-leak bypass; the fixed regex also means the protection expires for every future phase.

**Fix:** Classify all tracked, non-ignored textual repository artifacts as scan candidates by default, retaining exclusions only for explicitly approved raw/binary evidence. In particular, remove `.github/actions/` and `script/` from `explicit_exclusion_path?/1`, and replace the finite phase allowlist with a future-safe active-phase rule (or scan all non-archival `.planning/phases/**/*.md`). Add production-seam regressions that place a canary in each formerly excluded path and assert `scan_filesystem/2` and the Mix task emit only `privacy.private_term <relative-path>`.

---

_Reviewed: 2026-07-31T17:25:34Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
