---
phase: 165-efficient-and-maintainable-ci
fixed_at: 2026-09-09T02:52:51Z
review_path: .planning/workstreams/quality-ratchet-release/phases/165-efficient-and-maintainable-ci/165-REVIEW.md
iteration: 2
findings_in_scope: 1
fixed: 1
skipped: 0
status: all_fixed
---

# Phase 165: Code Review Fix Report

**Fixed at:** 2026-09-09T02:52:51Z
**Source review:** `.planning/workstreams/quality-ratchet-release/phases/165-efficient-and-maintainable-ci/165-REVIEW.md`
**Iteration:** 2

**Summary:**

- Findings in scope: 1
- Fixed: 1
- Skipped: 0

## Fixed Issues

### CR-03: Exact required-check verification drops the required producer app identity

**Files modified:** `script/normalize_required_checks.py`, `script/check_required_checks_registered.sh`, `script/register_required_checks.sh`, `script/check_phase165_efficient_ci.sh`, `test/fixtures/ci/required-checks/cases.json`, `test/crosswake/proof/phase165_evidence_test.exs`
**Commit:** 5a0ec74d
**Status:** fixed: requires human verification
**Applied fix:** Both required-check scripts now share one fail-closed normalizer for GitHub's real response shape. The normalizer accepts a strict app-bound `checks` array when `contexts` is its exact mirrored name set, keeps `{context: "Crosswake CI", app_id: 15368}` as the policy authority, and rejects extra/different mirrors, absent or invalid app IDs, duplicate/ambiguous checks or contexts, and non-strict protection.

## Verification

Structural verification first ran in the isolated review-fix worktree at `/Users/jon/projects/crosswake/.claude/worktrees/rf-165-iter2-4411-1788922020`. The committed tree was then verified in the main checkout because the isolated worktree intentionally has no dependency installation.

- `python3 script/normalize_required_checks.py --self-test` — passed against eight realistic positive/negative response fixtures
- Injected exact-target audit — valid mirrored response passed; wrong-app, extra/different mirror, missing-app, duplicate-authority, and non-strict cases failed closed
- Live registered-authority audit, read-only — passed against GitHub's current response
- Live exact-target policy audit, read-only — passed with strict sole `Crosswake CI` authority
- `script/check_phase165_efficient_ci.sh` — passed end to end, including the exact 44-leaf manifest, response-shape self-test, immutable actions, 48 focused ExUnit tests, and workflow syntax
- `git diff --check` — passed before commit
- External branch protection was not mutated

---

_Fixed: 2026-09-09T02:52:51Z_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 2_
