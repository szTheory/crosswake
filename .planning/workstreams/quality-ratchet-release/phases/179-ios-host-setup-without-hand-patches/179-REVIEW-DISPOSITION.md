---
phase: 179
review: 179-REVIEW.md
titles: json
findings:
  - id: CR-08
    severity: critical
    disposition: fixed
    title: "[BLOCKER] Proof project migration can overwrite a concurrent host edit"
  - id: WR-02
    severity: warning
    disposition: fixed
    title: "[WARNING] Version-1 proof recovery journals are accepted but cannot be recovered"
  - id: WR-03
    severity: warning
    disposition: fixed
    title: "[WARNING] A crash between stage and pending writes leaves an unrecoverable proof update"
  - id: WR-04
    severity: warning
    disposition: fixed
    title: "[WARNING] The caller timeout is shorter than the checker’s valid total runtime"
  - id: CR-01
    severity: critical
    disposition: fixed
    title: "[BLOCKER] Accepts malformed and out-of-range HTTPS ports"
  - id: CR-02
    severity: critical
    disposition: fixed
    title: "[BLOCKER] Managed output paths can escape through an ancestor symlink"
  - id: CR-03
    severity: critical
    disposition: fixed
    title: "[BLOCKER] Proof settings are published before all scaffold destinations are checked"
  - id: CR-04
    severity: critical
    disposition: fixed
    title: "[BLOCKER] Proof project migration accepts unrecognized build configurations"
  - id: CR-05
    severity: critical
    disposition: fixed
    title: "[BLOCKER] Proof recovery overwrites edits made after interruption"
  - id: CR-06
    severity: critical
    disposition: fixed
    title: "[BLOCKER] Effective-settings checker can miss settings bundled as resources"
  - id: CR-07
    severity: critical
    disposition: fixed
    title: "[BLOCKER] Published package omits the checker required by proof-lane checks"
  - id: WR-01
    severity: warning
    disposition: fixed
    title: "[WARNING] CLI entry-point check fails when the script path contains spaces"
open: 0
total: 12
recorded: 2026-10-14T00:47:19.847Z
---

# Phase 179: Code Review Disposition

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| CR-08 | critical | fixed | 179-REVIEW-FIX.md (not in the current review) |
| WR-02 | warning | fixed | 179-REVIEW-FIX.md (not in the current review) |
| WR-03 | warning | fixed | 179-REVIEW-FIX.md (not in the current review) |
| WR-04 | warning | fixed | 179-REVIEW-FIX.md (not in the current review) |
| CR-01 | critical | fixed | 179-REVIEW-FIX.iter1.md (not in the current review) |
| CR-02 | critical | fixed | 179-REVIEW-FIX.iter1.md (not in the current review) |
| CR-03 | critical | fixed | 179-REVIEW-FIX.iter1.md (not in the current review) |
| CR-04 | critical | fixed | 179-REVIEW-FIX.iter1.md (not in the current review) |
| CR-05 | critical | fixed | 179-REVIEW-FIX.iter1.md (not in the current review) |
| CR-06 | critical | fixed | 179-REVIEW-FIX.iter1.md (not in the current review) |
| CR-07 | critical | fixed | 179-REVIEW-FIX.iter1.md (not in the current review) |
| WR-01 | warning | fixed | 179-REVIEW-FIX.iter1.md (not in the current review) |

Dispositions: `open` (recorded, not yet triaged), `fixed`, `skipped`, `deferred`.
Set `deferred` by hand and put the reason in the Source cell; both are preserved. A `|` in the reason is kept as prose and escaped on the next run.
Re-running the gate keeps every row it can. A row the current review no longer reports is kept and its Source cell flagged, so a finding does not leave this record silently. ONE exception: when a finding id is REUSED by a different finding, the earlier decision cannot keep a row — the id is taken — and it is dropped. A RECORDED decision (anything but `open`) is named on the console when that happens; a row still at `open` is replaced silently, because `open` records no decision to lose.
