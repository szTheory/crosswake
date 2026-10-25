---
phase: 192
review: 192-REVIEW.md
titles: json
findings:
  - id: WR-01
    severity: warning
    disposition: open
    title: "Root-proof failure tail masking misses Bearer tokens, AWS secrets and cookies (public CI log)"
  - id: WR-02
    severity: warning
    disposition: open
    title: "TwinFaultBoundary owner checks do not handle os_pid nil from the CI-FIX-3 race fix"
  - id: WR-03
    severity: warning
    disposition: open
    title: "requires_xcodebuild tests now run nowhere in CI (silent skip)"
  - id: WR-04
    severity: warning
    disposition: open
    title: "postmerge other-push-runs check passes on an empty or partial run set"
  - id: WR-05
    severity: warning
    disposition: open
    title: "ci-poll writes ran_on/required_set literals without proving them"
  - id: WR-06
    severity: warning
    disposition: open
    title: "push-192 cause_word 403 match is unanchored; failed read-back reports not delivered instead of uncertain"
  - id: WR-07
    severity: warning
    disposition: open
    title: "privacy-192 lacks UDID, Authorization/Bearer and generic token classes"
  - id: WR-08
    severity: warning
    disposition: open
    title: "gh-shim stub jq pipeline masks the first jq's failure"
  - id: IN-01
    severity: info
    disposition: open
    title: "start_child blanket rescue reports every exception as prerequisite_missing"
  - id: IN-02
    severity: info
    disposition: open
    title: "PR #242 body is stale (names 4a6c1af2 and 114 commits)"
  - id: IN-03
    severity: info
    disposition: open
    title: "scan-191 notes scan covers only refs/notes/commits; append_units ignores awk status"
  - id: IN-04
    severity: info
    disposition: open
    title: "Failure-tail caps count characters, not bytes; sqlite3 error text may include a path"
  - id: IN-05
    severity: info
    disposition: open
    title: "privacy-192 account match may false-positive on a short name"
  - id: IN-06
    severity: info
    disposition: open
    title: "ci-history-192.txt has a duplicated line (poll append not idempotent)"
---

# Phase 192 review disposition

The code review (192-REVIEW.md) found 0 critical, 8 warning and 6 info items. All are recorded as
open: the PR is already merged, and any fix to product code on main needs a new PR. That is a new
GitHub write and is outside Phase 192's authority.

Product code now on main: WR-01 (CI log masking), WR-02 (race-fix follow-through), WR-03 (Xcode-only
tests not run in CI) and IN-01 and IN-04. These are the candidates for a follow-up fix PR.

The rest are in the one-time phase scripts (WR-04 to WR-08, IN-03, IN-05, IN-06) or are records
(IN-02). They did not change any outcome in this phase: CI, the merge and post-merge checks were
also confirmed by direct live reads.
