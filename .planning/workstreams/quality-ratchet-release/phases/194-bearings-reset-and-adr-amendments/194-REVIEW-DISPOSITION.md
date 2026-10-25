---
phase: 194-bearings-reset-and-adr-amendments
review: 194-REVIEW.md
review_status: issues_found
findings_total: 10
open: 10
fixed: 0
wontfix: 0
---

# Phase 194: Code Review Disposition

Every finding is advisory and none is critical. All ten sit in `script/bearings_report.exs` or its tests, which landed in PR #248. None is fixed in Phase 194. They stay `open` and are carried as one follow-up for the bearings-report tool. WR-01, WR-02 and WR-05 come first, because they can make a failed read look like a normal result or hang the report.

| ID | Severity | File | Disposition | Note |
|----|----------|------|-------------|------|
| WR-01 | warning | script/bearings_report.exs | open | A crash exits 1 (ATTENTION). It should map to UNVERIFIED and exit 2, and the launcher should check the Elixir version. |
| WR-02 | warning | script/bearings_report.exs | open | git and gh calls have no timeout. |
| WR-03 | warning | script/bearings_report.exs | open | A seed with malformed frontmatter is counted as prose-only, so its trigger is never evaluated. |
| WR-04 | warning | script/bearings_report.exs | open | Zero carried debt is reported with a misleading reason, and the table row count is fragile. |
| WR-05 | warning | script/bearings_report.exs | open | stderr is merged into the parsed stdout. |
| WR-06 | warning | script/bearings_report.exs | open | The persona ID regex and milestone substring match can under-count. |
| IN-01 | info | script/bearings_report.exs | open | The 40-line truncate bound can be exceeded. |
| IN-02 | info | script/bearings_report.exs | open | `valid_ws?` regex anchors. There is no traversal risk. |
| IN-03 | info | test/crosswake/planning/agents_contract_test.exs | open | Some negative controls are tautological, and some paths are untested. |
| IN-04 | info | script/bearings_report.exs | open | The CI line is always ATTENTION for an unpushed HEAD. This is by design. |
