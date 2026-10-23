---
phase: 190
review: 190-REVIEW.md
titles: json
findings:
  - id: WR-01
    severity: warning
    disposition: fixed
    title: "Only :registry_timeout reaches the verdict; :child_still_alive and :registry_gone still degrade silently, and a kept registry has no later reaper"
  - id: WR-02
    severity: warning
    disposition: deferred
    title: "Registry timeouts are handled for one read only; later registry calls can still exit uncaught"
  - id: WR-03
    severity: warning
    disposition: deferred
    title: "Provenance now needs git 2.40 or newer, with no version guard, and one new test passes vacuously on older git"
  - id: WR-04
    severity: warning
    disposition: skipped
    title: "A nested host is indistinguishable from \"no git\", so monorepo hosts can never carry a commit"
  - id: WR-05
    severity: warning
    disposition: fixed
    title: "An existing route_activation.json that parses but has no usable origin still passes the physical-iPhone preflight"
  - id: WR-06
    severity: warning
    disposition: fixed
    title: "The new verdict annotation is tested only as a pure function; the wiring in run/1 is untested"
  - id: WR-07
    severity: warning
    disposition: fixed
    title: "scan-privacy-190 self-test has no failing control for most hit classes or for binary files"
  - id: WR-08
    severity: warning
    disposition: deferred
    title: "Two gate checks in run-once-05-190.sh can pass while checking nothing"
  - id: WR-09
    severity: warning
    disposition: fixed
    title: "suite-gate-190.sh can accept an empty suite, persists an unvalidated baseline, and ignores untracked files"
  - id: WR-10
    severity: warning
    disposition: fixed
    title: "recovery-snap-190.sh can compare two empty snapshots, and it cannot see index or object changes"
  - id: WR-11
    severity: warning
    disposition: fixed
    title: "locate/ensure-work source a code file from a predictable shared temp folder without an ownership check, and ensure-work uses unpinned git"
  - id: IN-01
    severity: info
    disposition: deferred
    title: "twin_producers re-implements GitPins.spawn_env/0"
  - id: IN-02
    severity: info
    disposition: fixed
    title: "Credential class in the privacy scan is case-sensitive"
  - id: IN-03
    severity: info
    disposition: deferred
    title: "The gate deadline is checked only after every step has finished"
  - id: IN-04
    severity: info
    disposition: deferred
    title: "Origin check passes when the generated shell folder is missing, and self-tests hard-code counts"
open: 0
total: 15
recorded: 2026-10-19T22:23:15.751Z
---

# Phase 190: Code Review Disposition

| Finding | Severity | Disposition | Source |
|---------|----------|-------------|--------|
| WR-01 | warning | fixed | 191 commit WR-01-06 62a71f8b3e18 |
| WR-02 | warning | deferred | SEED-024 (residual only; main claim refuted) |
| WR-03 | warning | deferred | test half: 191 commit WR-03 e8caf915737c; version guard: SEED-024 |
| WR-04 | warning | skipped | accepted as designed (190 D-07); doc and distinct cause in SEED-024 |
| WR-05 | warning | fixed | 191 commit WR-05 ead01be59282 |
| WR-06 | warning | fixed | 191 commit WR-01-06 62a71f8b3e18 (wiring test) |
| WR-07 | warning | fixed | scan-191.sh + selftest-scan-191.sh |
| WR-08 | warning | deferred | SEED-024 |
| WR-09 | warning | fixed | suite-gate-191.sh + selftest-suite-191.sh |
| WR-10 | warning | fixed | recovery-snap-191.sh + selftest-base-191.sh |
| WR-11 | warning | fixed | locate-191.sh + ensure-clone-191.sh |
| IN-01 | info | deferred | SEED-024 |
| IN-02 | info | fixed | scan-191.sh (case-insensitive classes) |
| IN-03 | info | deferred | SEED-024 |
| IN-04 | info | deferred | fail-closed check in SEED-024; hard-coded counts accepted |

Dispositions: `open` (recorded, not yet triaged), `fixed`, `skipped`, `deferred`.
Set `deferred` by hand and put the reason in the Source cell; both are preserved.
