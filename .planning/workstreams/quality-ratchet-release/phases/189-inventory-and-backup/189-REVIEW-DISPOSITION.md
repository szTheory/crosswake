---
phase: 189-inventory-and-backup
review: 189-REVIEW.md
recorded: 2026-10-18
critical: 1
warning: 15
info: 6
---

# Phase 189 code review disposition

One row per finding in 189-REVIEW.md. `open` means not yet triaged by a fix or a decision.

| Finding | Disposition | Note |
|---------|-------------|------|
| CR-01 | fixed | Inventory row R-TMP-051 (unclassified, cr01 tar, fresh restore pass in restore-11.tsv); decision group 14 lists it and its 3 commits; SHA256SUMS.cr01 folded into SHA256SUMS and SHA256SUMS.11; tmp-recheck-11.txt shows no other empty or stub temp folder holds a regular file or a git object store. |
| WR-01 | no-change-needed | every symbolic-ref read uses the read form; block WR-01 in review-checks-13.txt. |
| WR-02 | no-change-needed | run folder is outside the checkout and no scratch sits in the phase folder; block WR-02 in review-checks-13.txt. |
| WR-03 | no-change-needed | no test-only override variable is set; block WR-03 in review-checks-13.txt. |
| WR-04 | no-change-needed | the stray file is empty and absent from the checkout; block WR-04 in review-checks-13.txt. |
| WR-05 | deferred | sanitised lines cannot be re-derived; counts were reconciled from sources; scripts are not reused after Phase 189; block WR-05 in review-checks-13.txt. |
| WR-06 | no-change-needed | reflog enumeration check passed in the plan 12 full check; block WR-06 in review-checks-13.txt. |
| WR-07 | no-change-needed | every per-plan manifest exists and verifies; closing gates use the form without a plan number; block WR-07 in review-checks-13.txt. |
| WR-08 | no-change-needed | all 5 unique commits resolve in the restored bundle or the shallow git directory tars; block WR-08 in review-checks-13.txt. |
| WR-09 | no-change-needed | 29 on-main rows re-proved against main; the third rule classed 0 rows; block WR-09 in review-checks-13.txt. |
| WR-10 | no-change-needed | 0 address-like forms in phase files; script unchanged; block WR-10 in review-checks-13.txt. |
| WR-11 | no-change-needed | supplemental case-insensitive identity and credential check found 0 matches and the phase folder holds no symlink; block WR-11 in review-checks-13.txt. |
| WR-12 | fixed | stricter rules flagged 42 Gradle build-output text or config files in the checkout; they are in review-content-13.tar with a restore pass in restore-13.tsv and are named on the decision list; block WR-12 in review-checks-13.txt. |
| WR-13 | fixed | 244 non-build temp symlinks recorded in tmp-symlinks-13.tsv (backup root, restore pass); 3 empty bare repositories (0 commits, 0 references) kept in review-repos-13.tar with a restore pass; both on the decision list; block WR-13 in review-checks-13.txt. |
| WR-14 | no-change-needed | 213 to-land and unclassified rows have a pass restore for every artifact; block WR-14 in review-checks-13.txt. |
| WR-15 | no-change-needed | environment-style counts equal the recorded 3 and 0; block WR-15 in review-checks-13.txt. |
| IN-01 | deferred | dead code in one-time scripts, no effect on results; block IN-01 in review-checks-13.txt. |
| IN-02 | deferred | constants are the 2026-10-16 expectations; scripts not reused; block IN-02 in review-checks-13.txt. |
| IN-03 | no-change-needed | plan 12 compared the bundle sha256 values directly; block IN-03 in review-checks-13.txt. |
| IN-04 | deferred | 12-hex prefixes of sanitised lines; environment file contents never entered evidence; reviewed again at the Phase 191 carry scan; block IN-04 in review-checks-13.txt. |
| IN-05 | no-change-needed | exactly one remote URL equals the checkout path, the origin of the read-only mirror clone recorded by git in plan 02 (user decision 2026-10-18, decision-13.txt); the checkout is unchanged; block IN-05 in review-checks-13.txt. |
| IN-06 | deferred | applies when the redo-after-landing PRs are recreated; their dispositions already say check before recreating; block IN-06 in review-checks-13.txt. |
