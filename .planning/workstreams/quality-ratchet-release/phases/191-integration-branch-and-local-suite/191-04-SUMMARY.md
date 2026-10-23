---
phase: 191-integration-branch-and-local-suite
plan: 04
status: complete
commits: 0
requirements-completed: []
---

# Phase 191 Plan 04: History privacy scanner and candidate dry run Summary

The scanner now exists, proves itself on planted cases, and has already scanned the 94 candidate commits. It checked every added line, file, path, author identity, commit message and tag for personal values (home-folder paths, temp-folder paths, the account name, email addresses outside an allow list) and for secrets (token, key and credential shapes, plus gitleaks 8.30.1). Its self-test passes 31 of 31 planted controls. Per the user's decision A-14 (2026-10-22) the private adopter-term list was dropped, so the adopter check is skipped and the scan says so: `scan: adopter_check skipped_by_user A-14`.

## Dry run over the candidate range (94 commits)

- commits 94, added_lines 36204, text_blobs 392, paths 1138, identities 188
- gitleaks_findings 0, history_sensitive 0 (no real secret anywhere in the candidate history)
- blocking_final 3, history_personal 0 (all three are personal values in files that are still in the candidate tree)
- Result: A-14 pass criteria met (94 / 0 / 0). The scan itself reports `hits` until Plan 05's PRIVACY commit replaces the three values; Plan 05 then re-runs it and must show blocking_final 0.

Fix list (`191-EVIDENCE/privacy-fix-list-191.txt`, paths only, 3 lines):
- home_path: 1 (the example host config file)
- user_name: 1 (same file)
- email: 1 (an iOS host config test; not a noreply address; looks like a test placeholder host, not a real person's address)

Evidence: `191-EVIDENCE/scan-candidate-dryrun-191.txt`, `191-EVIDENCE/selftest-scan-191.out` (unchanged).

## Deviations from Plan

- [A-14] Task 3 denylist steps skipped entirely: no terms load, no term-check-191.txt, no denylist hash.
- [Rule 3] scan-191.sh refused to run with zero terms, so it gained one opt-in: `SCAN191_ADOPTER_SKIP=A-14` skips the adopter class and prints the skip line. Without it, zero terms still exits 2 (control S15). Self-test re-run: 31 of 31, output identical, stored file unchanged.
- The blocking_final result is not zero, so the plan's original "clean" requirement is replaced by A-14 (fix list now, Plan 05 fixes later).
- The scanner prints only fingerprints, so file paths were located by a separate read-only pass over the changed files in the candidate tree; the email path is inferred from the scanner's allow list (the only changed file with a non-allowed domain).
- No commits were made (frozen checkout); the candidate was not modified.

## Self-Check: PASSED
