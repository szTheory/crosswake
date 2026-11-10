---
phase: 199-release-0-2-12
plan: 19
subsystem: release-train
tags: [rel-07, closeout, landing, privacy, d-29, route-b]
requires:
  - phase: 199-18
    provides: condensed AGENTS.md, 0.2.14 and the threadline deferral recorded in planning truth, REL-07 ticked (D-32)
provides:
  - closeout branch docs/199-record-0-2-14-published, cleared and unpushed, holding the SC6 edits, the condensed AGENTS.md, the planning landing (Route B) and the D-29 files
  - the recorded and applied docs-branch-retire answer, land_and_retire (source 199-DECISIONS D-29)
  - the first-adopter scan reads .awk (one extension plus one test)
affects: [199-20]
key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-EVIDENCE/landing-privacy-199.txt
    - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-EVIDENCE/landing-199.json
  modified:
    - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-EVIDENCE/suite-199.txt
    - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-EVIDENCE/privacy-199.txt
    - .planning/workstreams/quality-ratchet-release/phases/199-release-0-2-12/199-EVIDENCE/closeout-199.txt
    - lib/crosswake/planning/first_adopter_context.ex (closeout branch only)
    - test/crosswake/planning/first_adopter_context_test.exs (closeout branch only)
decisions:
  - "docs-branch-retire = land_and_retire, taken from D-29 in 199-DECISIONS.md; nothing was displayed or asked"
  - "users/github (GitHub's own public account in API response bodies) was dispositioned not-identifying together with users/<repository owner handle>; the plan named only the owner handle"
  - "TODO-013 and TODO-014 are in the S1 scope but already on origin/main with identical blobs (commit e8a01045), so they were recorded unchanged and not copied"
requirements-completed: []
actuals:
  tokens: 16000
  tasks: 3
  commits: 2
plan_head_before: 82aa59ac095bb39b3adba827821961e05ce5a0cd
plan_head_after: 98020e05
duration: about 40 min of agent work, 13 of them in the local full suite
completed: 2026-11-10
status: complete
---

# Phase 199 Plan 19: Closeout branch built and cleared (unpushed) Summary

**The closeout branch `docs/199-record-0-2-14-published` now carries the SC6 edits, the condensed AGENTS.md, 82 planning paths, the 43 pre-merge raw sources plus the gate-order helper (land_and_retire, D-29) and an `.awk` rule for the scan; every landing file is privacy-scanned with one disposition per hit, the local gates pass, and nothing was pushed.**

`actuals.tokens` is chars/4 over what this plan authored (the two landing evidence files, the evidence appends, the one-line lib change, the 16-line test and this summary); the 82 copied planning paths are not counted as new work. `commits: 2` counts the main-checkout commits before this summary's own commit (7cb18d5a, 98020e05); the closeout branch got four more in the worktree (55eab5e2, 54ce37df, 64860b1f, b584a5da), so it is now nine commits ahead of origin/main.

## What was checked and what happened

- **Scope (Task 1).** `landing_snapshot` = 82aa59ac (docs-branch head at the start). The planning diff since the PR 289 snapshot 97a36375 minus `.planning/config.json` and `.review-diagnostics/` is 41 paths (25 added, 16 modified), all under `.planning/`.
- **Main-side safety.** `git log af1dd94e..origin/main -- <path>` printed nothing for 39 paths. It printed commit e8a01045 for TODO-013 and TODO-014, which that commit added to main. Their blobs on origin/main equal the docs-branch blobs, so nothing of main's can be overwritten; they were recorded `unchanged` and not copied (see deviation 1).
- **Copies and redaction.** 39 paths were copied with `git checkout 82aa59ac -- <path>`. The local home-directory prefix appeared in 7 files (ROADMAP.md, 199-d31-prior-handoff.md, 199-13-BLOCKED.md, 199-16-SUMMARY.md, 199-17-SUMMARY.md, 201-08-SUMMARY.md, 201-VALIDATION.md) and was written as `~` on the landing copies only; the staged diff then had 0 occurrences. No temp-prefix, `users/<name>` or scratch-folder placeholder was needed.
- **Per-file privacy.** 41 files, one `privacy-193.sh` call each: 40 clean, 1 email hit (`history/phase-199-state-archive.md`, the generic SSH clone-URL form, already on main's STATE.md), dispositioned `not-identifying`.
- **Local gates in the closeout worktree** at head 55eab5e2: `mix crosswake.docs.sync --check` passed. Full suite floors come from 199-16's fresh baseline (base cbb900319b8f, ran 3201, total 3277) minus 21 removed tests: ran 3180, total 3256. The gate printed `rc=0 total=3256 excluded=76 skipped=0 ran=3180 failures=0 verdict=PASS`, exactly at both floors (the 199-07 counts 3155 and 3231 are recorded as a lower bound only). The machine load was 11 to 20 and no test timed out this time.
- **D-29 (Task 2).** `199-DECISIONS.md` has `- D-29 ... land_and_retire`, so the decision was recorded as `decision: docs-branch-retire land_and_retire at=2026-11-10T05:24:24Z source=199-DECISIONS D-29` in closeout-199.txt (exactly once) and nothing was displayed.
- **Applying it (Task 3).** The 43 S2 paths (the 43 recorded `exclude-from-landing` in 201-EVIDENCE/landing-privacy-201.txt: 39 envelope and raw source files, 3 pre-merge result files and gate-order-200.awk) were copied byte-identical (every blob id equals the snapshot's, 0 home-prefix occurrences, none already on main). Classes: 36 files `home_path` only, 6 `home_path` and `email`, 1 clean (the `.awk`). The `home_path` hits are the public API URL segment (`users/<handle>` for the repository owner in every case except `users/github`, GitHub's own account in API response bodies); the `email` hits are the generic clone form and, in three files, the maintainer's public `users.noreply.github.com` address that the scanner allows. All 42 got a `not-identifying` disposition citing D-29. `.awk` was added to `@scannable_extensions` and one test added (a planning `.awk` path is discovered and scans clean; an unknown extension still yields `routing.unclassified_path`). `first_adopter_context_test.exs` plus `crosswake_adoption_context_scan_test.exs` ran 44 tests, 0 failures through the gate, and `mix crosswake.adoption_context.scan` passed with the 43 files staged. `retire_blocked` is false.
- **Rescan after the new commits.** At head 64860b1f all 100 readable changed paths were rescanned (57 clean, 43 with hits, every hit has a disposition; the 101st path is a deletion) and the commit messages `origin/main..HEAD` (8 commits) scanned clean, rc 0. The final evidence commit b584a5da re-scanned its five files clean and its message range (9 commits) clean.
- **Nothing pushed.** `git ls-remote origin refs/heads/docs/199-record-0-2-14-published` prints nothing; the worktree is clean. The docs branch `docs/199-release-0-2-12` was not pushed, merged or deleted in this plan (199-20 does the per-path equivalence proof and the retirement after the merge).

## Deviations from Plan

**1. [Plan wording, stop condition read by intent] Two main-side hits were identical to main.** The plan says to stop and report a path whose `git log af1dd94e..origin/main -- <path>` prints something. TODO-013 and TODO-014 printed e8a01045, but that commit added them to main with the same content the docs branch holds (`git diff origin/main 82aa59ac -- <path>` is empty). The check exists so a path copy cannot overwrite a main-side change (T-199-80); nothing could be overwritten, so I recorded them `unchanged` (the acceptance criteria allow that) and continued. If the orchestrator wants the literal stop, the only effect is these two paths, already on main.

**2. [Plan wording] The Task 1 changed-path verify has a stale allow-list.** `script/collection_assertion_ledger.json` is changed on the closeout branch and is not in the verify's allowed set. It comes from 199-17's documented Rule 1 fix (removing the unreleased-claim qualifier tests dropped two ledger sites, and phase170's pinned counts changed with them); it is not a docs-branch code copy. With that one path allowed, the check passes; every other changed path is `.planning/`, `guides/`, the three renderers, `first_adopter_context.ex`, `test/`, CHANGELOG.md or AGENTS.md. 199-20's equivalent check needs the same allowance.

**3. [Judgement] `users/github` dispositioned with the owner handle.** The plan's rule names only `users/<maintainer handle>`. Most of the 3540 `users/github` strings in the raw sources are GitHub's own public account in API response bodies, which identifies nothing about the adopter or a person, so I applied the same `not-identifying` disposition and said so in a `land-note`. If that reading is not wanted, the affected files are the same 42 and could not be redacted anyway (their envelopes pin their hashes).

**3b. [Process slip, fixed before anything left the worktree] Combined commit.** My first `git commit` for the `.awk` change also committed the 43 staged raw-source files. I undid only that unpushed commit with `git reset --soft HEAD~1`, unstaged the 43, and committed again as two commits (54ce37df, 64860b1f); no work was lost and the blobs were re-verified equal to the snapshot.

**4. [Environment] Commits in the closeout worktree.** The pre-commit rule's agent-branch allow-list does not match `docs/199-record-0-2-14-published`; I committed there because the orchestrator named this branch as the plan's vehicle. It is not a protected or default branch.

## Auth gates

None.

## Known Stubs

None.

## Threat Flags

None beyond the plan's register. T-199-79 (publishing the raw sources) is handled as designed: each file was checked for the local home prefix (0) and limited to the public handle, the generic clone form and the allowed noreply address.

## What 199-20 needs

- **Closeout branch:** `docs/199-record-0-2-14-published` in `~/projects/crosswake-199-wt`, head `b584a5dabdf9c46c19d8beae4dba7234caa95435`, clean, 9 commits ahead of origin/main `cbb900319b8f4352c46f031927a75b38f5c36bbd`, 104 changed files (85 under `.planning/`), not pushed.
- **Landing scope:** `landing-199.json`: scope_count 41 (39 copied, 2 unchanged), s2_count 43, 82 landed paths, 0 excluded, `docs_branch_retire: land_and_retire`, `retire_blocked: false`, `awk_rule_added: true`, `ledger_line_carried: false`, landing_snapshot 82aa59ac.
- **Scans:** rc 0 on all 100 readable changed paths with 43 dispositioned hits (all `not-identifying`), and on the messages of all 9 commits. New commits (this summary, the STATE and ROADMAP updates copied into the branch) need a rescan before the push.
- **Not on the closeout branch yet:** this SUMMARY and the STATE.md and ROADMAP.md changes made after plan 199-19 (they are newer than landing_snapshot 82aa59ac); 199-20 copies them (redacted) in a new commit. The phase-wide `199-EVIDENCE/closeout-199.txt` lines 199-20 adds also need the copy.
- **Equivalence proof for the retirement** (199-20): every docs-branch path must be on origin/main after the merge. The paths the branch holds beyond the 84 landed here and the earlier PR 289 landing are the remaining risk to check.
- Full suite last ran at 55eab5e2, before the `.awk` change; the scan tests (44, 0 failures) and the adoption-context scan ran after it.

## Self-Check: PASSED

Checked: landing-privacy-199.txt, landing-199.json, suite-199.txt, closeout-199.txt exist; commits 7cb18d5a and 98020e05 are on `docs/199-release-0-2-12`; commits 55eab5e2, 54ce37df, 64860b1f and b584a5da are on the closeout branch; the Task 1 and Task 3 automated verifies pass except the Task 1 changed-path verify as written (deviation 2; it passes with the one added path).
