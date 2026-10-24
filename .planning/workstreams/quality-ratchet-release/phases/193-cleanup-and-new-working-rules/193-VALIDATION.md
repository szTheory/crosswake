---
phase: "193"
slug: "cleanup-and-new-working-rules"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-23"
---

# Phase 193 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Phase-local bash self-tests (`--self-test` mode in every 193 script; one label per control; exit 0 only on `selftest <name>: controls N of N as expected` with N at or above the script's floor). No ExUnit or Vitest change. |
| **Config file** | none; `193-SCRIPTS.sha256` freezes the 12-script set (189 format, `<64-hex>  scripts/<name>`) |
| **Quick run command** | `bash .planning/workstreams/quality-ratchet-release/phases/193-cleanup-and-new-working-rules/scripts/selftest-193.sh` (expects `selftest-193: scripts 10 of 10 pass`) |
| **Full suite command** | the quick run, then `final-check-193.sh --pre-merge <PR 2>` on PR 2's head and `final-check-193.sh --post-merge` after the merge, plus the legacy standalone self-tests `selftest-scan-191.sh` and `selftest-carry-191.sh` (recorded once in plan 04; the 192 privacy self-test is not run, because it re-creates the backed-up `<tmp>` 191 run folder, D-13(e); `privacy-193.sh --self-test` in the quick run covers the privacy check) |
| **Estimated runtime** | quick run about 60 s (local fixtures); final check about 30 s (git + gh reads) |

Verify commands are written for the tool shell (zsh): no `set -- $VAR` word splitting, no unmatched globs; self-test lines are checked with awk field comparisons; every exit code is captured directly and never hidden behind a pipe.

---

## Sampling Rate

- **After every task (no commit in the recovery checkout or on local main):** that task's `--self-test` and `bash -n` of every changed script.
- **After every plan:** `selftest-193.sh` (from plan 04 on) and `shasum -a 256 -c 193-SCRIPTS.sha256` (12 lines); any script edit re-freezes the hash file.
- **Sampling points inside the sequence:** after preflight (01 T1); after the post-189 backup (01 T3, preflight re-run); the pre-swap removal plan (04 T1); after the sweep (07 T2, handoff hashes); the dirty refresh right before the Gate B list (08 T1); after the PR 1 merge (05 T3, clone equals live main); after copy-forward (06 T1); right after the swap (06 T2 `guard where`); at session-2 start (07 T1 `guard full`); before Gate B (08 T1, preflight inside `remove plan`); after each removal item (ledger row written before the next); before each PR 2 push (scan bound to HEAD); after the PR 2 merge (`--post-merge`).
- **Before `/gsd-verify-work`:** 193-VERIFICATION.md is written inside PR 2 (D-11); the post-merge receipt is in `<backup-root>/receipts-193/`.
- **Max feedback latency:** 120 seconds for local checks; CI waits are bounded by `ci-wait ... 90` polls.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 193-01-01 | 01 | 1 | CLEAN-01 | T-193-01, T-193-02 | backups re-verified; recovery read only through g() | integration | `preflight-193.sh --self-test` (>= 10, incl. swapped/absent recovery layouts) + `preflight-193.sh run` -> `preflight: result pass`; restore lines name archives only | ❌ W0 | ⬜ pending |
| 193-01-02 | 01 | 1 | CLEAN-02 | T-193-02, T-193-04 | refuse overwrite; crosswake-only temp listing | unit | `backup-post189-193.sh --self-test` (>= 12 controls, incl. two `dirty-refresh` controls) | ❌ W0 | ⬜ pending |
| 193-01-03 | 01 | 1 | CLEAN-01, CLEAN-02 | T-193-02, T-193-03 | complete-history bundle restores; tars mode 600; no 191/192 run-folder tool runs after the tmp tar (D-13(e)) | integration | `backup: result pass`; post-backup preflight `difference 0`; 11 R-POST-TMP rows; record has no home path (the privacy check of these 5 records moved to 193-02-02) | ❌ W0 | ⬜ pending |
| 193-02-01 | 02 | 2 | CLEAN-01 | T-193-07, T-193-08 | dry-run push writes nothing | integration | clone-193.txt five lines; `land: dry-run ok`; clone HEAD = live main; status empty | ❌ W0 | ⬜ pending |
| 193-02-02 | 02 | 2 | CLEAN-01 | T-193-08, T-193-40 | privacy gate needs no 191/192 run folder and makes no `<tmp>/crosswake*` entry | unit | `privacy-193.sh --self-test` (>= 14 controls, incl. static no-run-folder and before/after `crosswake*` name-set controls) + real run `privacy: clean files 2`; plan 01's five records `privacy: clean files 5` in privacy-01-193.txt; no `cw193-*` in `<tmp>` | ❌ W0 | ⬜ pending |
| 193-02-03 | 02 | 2 | CLEAN-01 | T-193-05, T-193-06, T-193-07, T-193-40 | scan-bound push from a relocated scanner copy; D-26 skip scoped to pr1/pr2; one-use head-bound merge | unit | `land-gate-193.sh --self-test` (>= 20 controls); source has no 191/192 run-folder, 192 privacy or `<tmp>` literal; names privacy-193 and `scope D-26` | ❌ W0 | ⬜ pending |
| 193-03-01 | 03 | 2 | CLEAN-01 | T-193-09, T-193-12 | env mode 600; counts only; stage deleted | integration | `copyforward-193.sh --self-test` (>= 11) + real `stage` -> `result pass`, counts > 0; `stage`, `apply` and `verify` each print `copyforward: settings S env E runtime R` (the line plans 06/07 parse from verify output) | ❌ W0 | ⬜ pending |
| 193-03-02 | 03 | 2 | CLEAN-01 | T-193-10, T-193-11 | rollback on failed rename; session identity | unit | `swap-193.sh --self-test` (>= 6), `guard-swapped-193.sh --self-test` (>= 10), real `where` = recovery | ❌ W0 | ⬜ pending |
| 193-04-01 | 04 | 3 | CLEAN-02 | T-193-13, T-193-14, T-193-16 | per-item gates; allowlist; list-hash binding | unit + integration | `remove-193.sh --self-test` (>= 20) + real `plan --pre-swap` (items = pass + kept; `bridge_commits patch_unique 14 in_refs_all_bundle 14`; recovery (d)/(f) `pending`); self-test controls for the post-swap bridge read (explicit `--git-dir=<REC>/.git/worktrees/crosswake-accrue-bridge --work-tree=<bridge>`; missing entry -> `kept: bridge_gitdir_unresolved`) | ❌ W0 | ⬜ pending |
| 193-04-02 | 04 | 3 | CLEAN-03, CLEAN-04 | T-193-15 | fail closed on empty/failed gh reads | unit + live probe | `final-check-193.sh --self-test` (>= 20), `rules-check-193.sh --self-test` (>= 14, incl. 16 D-16 phrase checks scoped to the How changes land section), `--check 2` live = pass | ❌ W0 | ⬜ pending |
| 193-04-03 | 04 | 3 | CLEAN-03 | T-193-15 | no leftover crosswake fixtures | integration | `selftest-193.sh` -> 10 of 10; 193-SCRIPTS.sha256 12 lines; legacy 2 rc 0 (scan-191, carry-191) and no `privacy-192` legacy line; no `<tmp>` leftovers | ❌ W0 | ⬜ pending |
| 193-05-01 | 05 | 4 | CLEAN-01 | T-193-17, T-193-19 | redaction + scan bound to pushed head | integration | STATE names post-swap command; `land: ci success`; binding proposed at head; privacy clean; `pr1-fileset-193.txt` d11 + extra totals match (D-25 amendment of D-11 listed at Gate A); scan binding has `scope D-26 label pr1` | ✅ scripts | ⬜ pending |
| 193-05-02 | 05 | 4 | CLEAN-01 | T-193-18 | Gate A allow/hold bound to head | checkpoint:decision | n/a (user's one word; bound by land-gate) | n/a | ⬜ pending |
| 193-05-03 | 05 | 4 | CLEAN-01 | T-193-18, T-193-20 | one merge call; no forbidden options | integration | merge record `result merged`; one `pr_merge`; PR MERGED; clone on live main, clean | ✅ scripts | ⬜ pending |
| 193-06-01 | 06 | 5 | CLEAN-01 | T-193-21 | env mode 600; status empty | integration | preflight pass with 193b; copy-forward apply/verify pass, counts > 0; deps.get and compile -Werror rc 0 | ✅ scripts | ⬜ pending |
| 193-06-02 | 06 | 5 | CLEAN-01 | T-193-22, T-193-23 | swap reversible; no writes after | integration | `guard where` = swapped from the original path; swap record `swap done`; clean-main absent | ✅ scripts | ⬜ pending |
| 193-06-03 | 06 | 5 | CLEAN-01 | T-193-22 | session restart only | checkpoint:human-action | verified by plan 07 `guard full` | n/a | ⬜ pending |
| 193-07-01 | 07 | 6 | CLEAN-01 | T-193-24 | right folder before any action | integration | scripts hash; `guard: full pass`; reverify pass; build rc 0; memory index files > 0; main = live main | ✅ scripts | ⬜ pending |
| 193-07-02 | 07 | 6 | CLEAN-01, CLEAN-02 | T-193-25, T-193-26, T-193-27 | no record left only in the retired folder | integration | sweep `result complete`; four `handoff` lines equal or preserved (preserved copy sha256 = retired sha256); 05/06 SUMMARY + swap record present; privacy clean; no commit on main | ✅ scripts | ⬜ pending |
| 193-08-01 | 08 | 7 | CLEAN-02 | T-193-28, T-193-29 | list produced by the deleting code after re-verify | integration | `dirty-refresh` pass (+ R-POST-DIRTYR row when archived); retired item `gates pass`, no `pending`; bridge 14 of 14; `item R-WT-2` line present with no `bridge_gitdir_unresolved` (gate (d) read post-swap through the retired worktree entry); four handoff lines; gate list lines; binding proposed with list hash, mode 600; OS counts; privacy clean | ✅ scripts | ⬜ pending |
| 193-08-02 | 08 | 7 | CLEAN-02 | T-193-29 | Gate B allow/hold bound to list | checkpoint:decision | n/a | n/a | ⬜ pending |
| 193-08-03 | 08 | 7 | CLEAN-02, CLEAN-03 | T-193-28, T-193-30, T-193-31 | backup root intact; ledger complete | integration | ledger expected = removed + kept > 0; `final: check 4 pass`, `final: check 5 pass`; backup root present; post-removal privacy-193 run clean with `tmp_crosswake_before` = `tmp_crosswake_after` | ✅ scripts | ⬜ pending |
| 193-09-01 | 09 | 8 | CLEAN-04 | T-193-32, T-193-33 | no standing approval survives | integration | AGENTS.md heading + all 16 D-16 phrases inside the section + exactly 16 `rules: d16` pass lines (output and exit code captured separately, rc intentionally not asserted at this task) + no dropped phrases + main sections; planning/hex-page tests rc 0 | ✅ scripts | ⬜ pending |
| 193-09-02 | 09 | 8 | CLEAN-04 | T-193-34 | history verbatim | integration | ROADMAP note exact; STATE supersession line; SEED-025 WR-01 first, 6 done-looks-like; the single PROJECT `**Current stage:**` line has no `stays frozen` (Android platform line unchanged) | ✅ scripts | ⬜ pending |
| 193-09-03 | 09 | 8 | CLEAN-03, CLEAN-04 | T-193-33 | dispositions recorded only | integration | `rules: result pass`; table rows = open count; #211 failing CI; #236 hold; privacy clean | ✅ scripts | ⬜ pending |
| 193-10-01 | 10 | 9 | CLEAN-03 | T-193-35, T-193-37, T-193-38 | expected paths only; scan bound | integration | branch; pr2 number; `--pre-merge` on C1 pass; scan binding head = HEAD with `scope D-26 label pr2`; status empty; main untouched; no `<tmp>/crosswake-scan-191.*` | ✅ scripts | ⬜ pending |
| 193-10-02 | 10 | 9 | CLEAN-01..04 | T-193-35, T-193-37 | rescan after new commit | integration | VERIFICATION + SUMMARY present; 4 CLEAN boxes; rules pass; `--pre-merge` on C2 pass; bindings at HEAD | ✅ scripts | ⬜ pending |
| 193-10-03 | 10 | 9 | CLEAN-03, CLEAN-04 | T-193-36 | Gate C allow/hold bound to head | checkpoint:decision | n/a | n/a | ⬜ pending |
| 193-10-04 | 10 | 9 | CLEAN-03 | T-193-36, T-193-37, T-193-39 | no writes after merge | integration | one merge; on main at live tip; status empty; `--post-merge` pass; receipts sums verify; scratch removed | ✅ scripts | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `scripts/paths-193.sh`, `preflight-193.sh`, `backup-post189-193.sh` (plan 01)
- [ ] `scripts/privacy-193.sh`, `scripts/land-gate-193.sh` (plan 02)
- [ ] `scripts/copyforward-193.sh`, `swap-193.sh`, `guard-swapped-193.sh` (plan 03)
- [ ] `scripts/remove-193.sh`, `final-check-193.sh`, `rules-check-193.sh`, `selftest-193.sh`, `193-SCRIPTS.sha256` (plan 04)
- [ ] `193-POST189-RECORD.md` (plan 01), `193-PR-DISPOSITIONS.md` (plan 09), `193-REMOVAL-LEDGER.md` (plan 08)
- No framework install needed.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Restart the session after the folder swap | CLEAN-01 | The running session's working folder is renamed (D-10); only the user can open a new session | Close the session; open a new one in `<home>/projects/crosswake`; run `$gsd-execute-phase 193 --ws quality-ratchet-release`. Plan 07's guard verifies the result automatically. |

The three `allow`/`hold` gates (PR 1 merge, removal, PR 2 merge) are decisions, not verifications; every claim around them is checked automatically.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or are checkpoints
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (completed by plans 01-04)
- [x] No watch-mode flags
- [x] Feedback latency < 120s for local checks
- [ ] `nyquist_compliant: true` set in frontmatter (set by validate-phase after execution)

**Approval:** pending
