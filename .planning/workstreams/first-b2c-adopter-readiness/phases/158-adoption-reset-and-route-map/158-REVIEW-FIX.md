---
phase: 158
fixed_at: 2026-07-31T19:16:00Z
review_path: /Users/jon/projects/crosswake/.planning/phases/158-adoption-reset-and-route-map/158-REVIEW.md
iteration: 1
findings_in_scope: 4
fixed: 3
skipped: 1
status: partial
---

# Phase 158: Code Review Fix Report

**Fixed at:** 2026-07-31T19:16:00Z
**Source review:** `/Users/jon/projects/crosswake/.planning/phases/158-adoption-reset-and-route-map/158-REVIEW.md`
**Iteration:** 1

**Summary:**
- Findings in scope: 4
- Fixed: 3
- Skipped: 1

## Fixed Issues

### CR-01: Single-digit dollar prices bypass the privacy scanner

**Files modified:** `lib/crosswake/planning/first_adopter_context.ex`, `test/crosswake/planning/first_adopter_context_test.exs`, `test/mix/tasks/crosswake_adoption_context_scan_test.exs`
**Commits:** 9a57dce0, 4e0dbc8f
**Applied fix:** Detects zero and single-digit commercial amounts only in prose-oriented Markdown, HTML, XML, text, and SVG content when a commercial context is present; retains multi-digit and decimal detection everywhere. Shell/awk/Swift positional placeholders remain accepted. Direct and production Mix-task regressions cover both sides without echoing matched content.

### CR-02: Textual SVG artifacts are excluded from the privacy scan

**Files modified:** `lib/crosswake/planning/first_adopter_context.ex`, `test/crosswake/planning/first_adopter_context_test.exs`, `test/mix/tasks/crosswake_adoption_context_scan_test.exs`
**Commit:** 3676577c
**Applied fix:** Classified `.svg` as textual and added direct plus production Mix-task private-term coverage without echoing matched content.

### WR-01: Duplicate route fields escape the safe validator error contract

**Files modified:** `lib/crosswake/adoption/route_inventory.ex`, `test/crosswake/adoption/route_inventory_test.exs`
**Commit:** 2187e60b
**Applied fix:** Rejects duplicate keyword fields before NimbleOptions with the stable `RI-DUPLICATE_FIELD` ValidationError; required, forbidden, and unknown duplicate cases are covered without value echoes.

## Skipped Issues

### WR-02: Protected scan makes all fork pull requests fail solely for missing secrets

**File:** `.github/workflows/hex-page-proof.yml:61`
**Reason:** Intentional policy mismatch. The accepted fail-closed protected private-term trust boundary requires untrusted fork PRs to have no merge path that bypasses the secret-backed scan. The workflow was left unchanged.
**Original issue:** Fork pull requests fail the protected gate when they cannot access trusted private-term secrets.

## Verification

Focused RED/GREEN regressions passed for CR-01, CR-02, and WR-01. The complete focused scanner/Mix-task and route-inventory suite passed (48 tests), the production `mix crosswake.adoption_context.scan` passed, explicit-file `mix format --check-formatted` passed, and compilation passed.

---

_Fixed: 2026-07-31T19:16:00Z_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 1_
