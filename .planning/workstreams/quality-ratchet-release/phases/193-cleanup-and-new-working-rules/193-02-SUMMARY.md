---
phase: 193-cleanup-and-new-working-rules
plan: 02
subsystem: infra
tags: [clone, land-gate, privacy-check, push-gate, merge-gate]
requires:
  - phase: 193-01
    provides: paths-193.sh, the post-189 record and the five plan 01 evidence records
provides:
  - a fresh clean clone of origin/main next to the recovery checkout
  - land-gate-193.sh (scan-bind, push, open, ci-wait, propose, answer, merge, status, self-test)
  - privacy-193.sh (standalone, with self-test)
affects: [193-05, 193-08, 193-10]
requirements-completed: []
actuals:
  tokens: 14000
  tasks: 3
  commits: 0
plan_head_before: d0f3e2f1ead2046c26da5cc4b5dd62d5bfea1377
plan_head_after: d0f3e2f1ead2046c26da5cc4b5dd62d5bfea1377
status: complete
key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/193-cleanup-and-new-working-rules/scripts/land-gate-193.sh
    - .planning/workstreams/quality-ratchet-release/phases/193-cleanup-and-new-working-rules/scripts/privacy-193.sh
    - .planning/workstreams/quality-ratchet-release/phases/193-cleanup-and-new-working-rules/193-EVIDENCE/clone-193.txt
    - .planning/workstreams/quality-ratchet-release/phases/193-cleanup-and-new-working-rules/193-EVIDENCE/land-dryrun-193.txt
    - .planning/workstreams/quality-ratchet-release/phases/193-cleanup-and-new-working-rules/193-EVIDENCE/selftest-privacy-193.out
    - .planning/workstreams/quality-ratchet-release/phases/193-cleanup-and-new-working-rules/193-EVIDENCE/selftest-land-gate-193.out
    - .planning/workstreams/quality-ratchet-release/phases/193-cleanup-and-new-working-rules/193-EVIDENCE/privacy-02-193.txt
    - .planning/workstreams/quality-ratchet-release/phases/193-cleanup-and-new-working-rules/193-EVIDENCE/privacy-01-193.txt
  modified: []
key-decisions:
  - "Check-run lookup reads the raw JSON first so an empty answer is a tool error (exit 2), never 'no check yet'."
  - "propose also requires the scan binding to name the PR head with scan_exit 0, so the scanned, pushed and bound heads are one 40-hex SHA."
completed: 2026-10-24
---

# Phase 193 Plan 02: Fresh clone and the push/merge gate

A clean clone of `main` now sits next to the recovery checkout. The push and merge gate and a standalone privacy check were built and tested. A real dry-run push through the gate worked, and nothing was sent to GitHub.

## What was checked

- **Clone.** `crosswake-clean-main` is a fresh clone of origin/main. Its HEAD (`d12aed75`) equals the live remote main read at the same time. The tree is clean and its origin URL equals the recovery checkout's. The repo-local identity is the noreply address taken from the newest non-bot noreply commit on main (recorded only as `user_email noreply set`).
- **Dry-run tracer.** `land-gate-193.sh push <clone> docs/192-post-sync-records --dry-run` printed `land: dry-run ok` against the real remote through `gh auth git-credential`. No writes-log line was made and the remote branch does not exist.
- **Privacy check.** Self-test 21 of 21. Real run over this plan's two records: clean files 2. Real run over plan 01's five records: clean files 5 (the check plan 01 owed).
- **Land gate.** Self-test 51 of 51, including the clean allow-to-merge path in a fixture (one merge call with the exact argv) and the real scanner copy run in a fixture.
- **Mutation proof.** Three deliberate breaks of a copy of the gate (ignore `scan_exit`, skip the head-changed void, put a forbidden merge option in the merge command) were each caught by the self-test (50, 50 and 49 of 51). The copy was deleted.
- **No tmp entries.** The `crosswake*` names under the system temp folder are identical before and after a privacy run and after both fixture scan-binds. No `cw193-*` entry exists in the system temp root, and no `cw193-st.*` or `cw193-privacy.*` scratch is left in the session temp folder.
- **Gate commands.** Every check ran with its exit code captured directly (no pipe into tail/head).

## What was built

- `land-gate-193.sh`: scan-bind runs the 191 scanner from a hash-checked copy whose scratch prefix is rewritten on exactly two lines to a folder under the 193 run folder. It sets the A-14 adopter-term skip only for labels pr1 and pr2 and records `adopter_check skipped_by_user A-14 scope D-26 label <label>`. Push uses only `HEAD:refs/heads/BRANCH` (branch pattern `docs|chore/...`, no force, no tag, no main), once, and only with a binding that names HEAD, live main and `scan_exit 0`. Open, ci-wait (live branch-protection read, check selected by name, app 15368 and head), one-use propose/answer/merge (merge call consumed before it is made, exit 3 on an uncertain delivery, no second call) and status are all implemented.
- `privacy-193.sh`: same classes and labels as the 192 check, depends only on `paths-193.sh`, scratch in the session temp folder, refuses to run when the temp root is the system temp root.

## Deviations from Plan

**1. [Rule 1 - Fact drift] The checkout rule replaces per-task commits.** D-03 and the dispatch rule forbid any git write in the recovery checkout, so there are no task commits. `commits: 0`; `plan_head_before` and `plan_head_after` are the unchanged recovery HEAD.

**2. [Rule 2 - Missing handling] Binding checks go beyond the plan text.** `push --push` also requires the binding's `adopter_check` line for the same label; `propose` requires the scan binding to name the PR head; `open` requires the PR's head to equal the local HEAD. All three fail closed and have controls (L11, L26, L37).

**3. [Rule 3 - Blocking] Fixture paths use the resolved temp folder.** The session temp folder is a symlink on this machine, so fixtures are built from the resolved path that `paths-193.sh` uses for its fixture prefix.

**4. TDD note.** The self-tests were written together with the scripts (the checkout rule forbids a RED commit). The RED evidence is the three mutation runs above plus fail-closed controls for every refusal.

Nothing was installed, pushed, merged or opened. `STATE.md` and `ROADMAP.md` were not touched.

## Known Stubs

None.

## Self-Check: PASSED

The two scripts and the six evidence files exist; the clone head equals the live remote main and its tree is clean; the three task verification commands exit 0; the recovery HEAD is unchanged (`d0f3e2f1`).
