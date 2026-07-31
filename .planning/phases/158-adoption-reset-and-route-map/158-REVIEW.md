---
phase: 158-adoption-reset-and-route-map
reviewed: 2026-07-31T15:12:32Z
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
  warning: 0
  info: 0
  total: 2
status: issues_found
---

# Phase 158: Code Review Report

**Reviewed:** 2026-07-31T15:12:32Z
**Depth:** standard
**Files Reviewed:** 16
**Status:** issues_found

## Summary

The route-inventory validator and generated-guide parity checks are well covered by the focused suite, but the newly added privacy gate does not reliably prevent private adopter context from being merged into the repository. The gate both omits most repository files from its scan and withholds secret-backed matching from pull requests.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Private-term scan excludes most repository files

**File:** `lib/crosswake/planning/first_adopter_context.ex:29`
**Issue:** `scan_filesystem/2` only discovers paths matched by the small `@artifact_globs` allowlist (lines 29-51). It therefore never examines source files such as `lib/crosswake/adoption/route_inventory.ex`, CI workflows, tests, or any newly added public guide outside the two listed guides. A configured protected term can be committed to one of those unscanned files and `mix crosswake.adoption_context.scan --require-private-terms` will still pass. This violates the stated prohibition on recording the adopter's identifying/private context in repository content, and creates a direct bypass for the merge privacy gate.

**Fix:** Scan all tracked, non-ignored repository text files (or maintain a denylist only for generated/binary/private paths), then apply destination-specific phrase checks to the routed artifact subset. Add a regression test that places a private canary in an otherwise unlisted source file and asserts `scan_filesystem/2` reports `privacy.private_term` without echoing its content.

### CR-02: Secret-backed privacy enforcement runs only after PR merge

**File:** `.github/workflows/hex-page-proof.yml:55`
**Issue:** The only invocation that requires `CROSSWAKE_PRIVATE_ADOPTER_TERMS` is explicitly skipped for every `pull_request` (line 56). The ordinary PR scan at line 53 consequently runs with no protected terms, while the required scan runs only on `push` to `main`—after a PR's content can already have been merged and exposed. GitHub makes repository secrets available to same-repository PR workflows; skipping the protected scan for all PRs leaves the normal merge path unprotected.

**Fix:** Run `mix crosswake.adoption_context.scan --require-private-terms` for trusted, same-repository PRs as well as protected pushes, for example gate it on a non-fork PR. For fork PRs, keep secrets unavailable but require a maintainer-owned trusted workflow/merge queue check before merging (or fail closed when the required term set cannot be supplied). Add workflow-level coverage/documentation that the protected check is a required PR status check.

---

_Reviewed: 2026-07-31T15:12:32Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
