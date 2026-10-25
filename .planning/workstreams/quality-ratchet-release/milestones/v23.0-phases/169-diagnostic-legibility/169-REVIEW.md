---
phase: 169-diagnostic-legibility
reviewed: 2026-09-25T20:27:31Z
depth: standard
files_reviewed: 9
files_reviewed_list:
  - .github/workflows/phase70-proof.yml
  - .github/workflows/release-please.yml
  - docs/COMPANION-PUBLISH-RUNBOOK.md
  - lib/crosswake/release_status.ex
  - lib/mix/tasks/crosswake.release.status.ex
  - script/check_release_workflow_integrity.exs
  - script/check_required_checks_registered.sh
  - script/list_merge_blocking_checks.py
findings:
  critical: 1
  warning: 2
  info: 0
  total: 3
status: issues_found
---

# Phase 169: Code Review Report

**Reviewed:** 2026-09-25T20:27:31Z
**Depth:** standard
**Files Reviewed:** 9
**Status:** issues_found

## Summary

Reviewed the Phase 169 release-status implementation, workflow diagnostics, helper scripts, and runbook changes. The crash classification can discard a scanner failure already observed before termination, and the failure summary can state that every check ran while also reporting checks as unverifiable. Crash output can also break the promised one-line diagnostic format.

## Critical Issues

### CR-01: Partial scanner failures are discarded when the scanner terminates early

**File:** `lib/crosswake/release_status.ex:928-938`
**Issue:** When the scanner has emitted one or more `FAIL` records and then terminates before `DONE`, `classify_workflow_integrity_output/2` retains those records in `checks` while marking the run `:unverifiable`. This clause then replaces the parsed evidence with an empty `entries` list and reports only `:unverifiable`; `scanner_ids_result/2` also ignores parsed failures for this status. The confirmed defect therefore disappears from the owner check and can yield exit 3 instead of the documented precedence of exit 1 when a defect and an unknown coexist.
**Fix:** Preserve any parsed failing entries on early termination and represent scanner completeness separately from those failures. Keep the dependent scoped checks `:unverifiable`, but retain a `:error` finding for each observed failure so aggregation exits 1 and renders both the failure and the unknown outcome.

## Warnings

### WR-01: Failure summary claims all checks ran even when checks are unverifiable

**File:** `lib/crosswake/release_status.ex:197`
**Issue:** If an independent check reports `:error` while scanner-dependent checks are `:unverifiable`, the output emits both summary blocks, but this failure sentence says the status command “ran all” checks. The `:unverifiable` block explicitly says some checks could not run, so the report contradicts itself.
**Fix:** Use wording that counts the checks that ran and names the blocking issues without claiming all checks ran; derive the completed count from the non-`:unverifiable` checks.

### WR-02: Crash excerpts can inject newlines into the check summary line

**File:** `lib/crosswake/release_status.ex:1220-1227`
**Issue:** The excerpt is bounded by length but retains embedded newlines. It is interpolated into the owner check message, so multi-line compiler or exception output turns one rendered check into multiple lines and can make crash details look like separate report entries.
**Fix:** Flatten line breaks and repeated whitespace in the excerpt before inserting it into the message, then apply the existing length bound and truncation marker.

---

_Reviewed: 2026-09-25T20:27:31Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
