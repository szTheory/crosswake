---
phase: "189"
slug: "inventory-and-backup"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-10-16"
---

# Phase 189 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution. Derived from `189-RESEARCH.md` § Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Plain shell assertion scripts with negative controls (Phase 188 `selftest-*.sh` precedent); no new dependency |
| **Config file** | none; scripts live in `<tmp>/crosswake-phase189-run` and are byte-copied into `scripts/` of this phase with a sha256 list |
| **Quick run command** | `verify-189.sh --quick` (manifest verify plus snapshot compare) |
| **Full suite command** | `verify-189.sh --full` (adds every restore test and the inventory-count reconciliation) |
| **Estimated runtime** | ~120 seconds (full) |

---

## Sampling Rate

- **After every task:** the task's own restore check and manifest verify
- **After every plan wave:** `verify-189.sh --quick`
- **Before `/gsd-verify-work`:** `verify-189.sh --full` green, before/after snapshot identical, privacy scan zero hits with a non-zero file count
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

Short form of each task's `<automated>` command (full commands and `<fails_when>` are in the PLAN files). Every command captures exit status and compares exact counts; none pipes a gating command into `tail`/`head` for its status.

| Task | Plan | Wave | Requirement | Automated check (short form) | Status |
|------|------|------|-------------|------------------------------|--------|
| 189-01-T1 | 01 | 1 | D-15, D-14 | `snapshot-189.sh` before = rerun from a non-repo cwd; refs 174, stash 4, lost-found 248; reflog ids = independent `log -g --all` count, both > 0 (absolute git dir); backup-root rule header; frozen listing count = raw lines; `scan-privacy-189.sh --expect 3` hits 0 | ⬜ pending |
| 189-01-T2 | 01 | 1 | D-08, D-10, D-14 | `selftest-189.sh` = 46 of 46 (adds N08-N10 backup-root and cwd controls, W09-W10 absolute git dir controls, M01-M04 regenerable markers); no scratch left; OUT absent; snapshot unchanged; `verify-189.sh --quick --plan NN` spec writes RUNS/snap-now-NN.txt and checks only SHA256SUMS.02 + own SHA256SUMS.NN; snapshot log -g temp file via mktemp | ⬜ pending |
| 189-02-T1 | 02 | 2 | INV-01, INV-02 | `verify-189.sh --quick` ok; reflog ids = log -g count > 0; stash 4 = 4; reflog-only R > 0; refs-all.reflist = 174 + 4 stash-backup + R reflog-backup; restore-02 1 pass; registry-02 1 line; scan --expect 5 | ⬜ pending |
| 189-02-T2 | 02 | 2 | INV-01 | reflog-only.tsv 6 columns × R; on main only by ancestry or patch-equivalence with matching paths; R-REFLOG rows sum to R; none obsolete; verify --quick | ⬜ pending |
| 189-03-T1 | 03 | 3 | INV-01, INV-02 | (all wave-3 verifies use `verify-189.sh --quick --plan NN`: own snapshot file, only 02 + own manifest) RUNS/expect mode 700 with 4 expectations; `shasum -c SHA256SUMS.03` 8 OK; restore-03 4 pass; registry-03 4 lines; 4 R-STASH rows in on main / to land / unclassified | ⬜ pending |
| 189-03-T2 | 03 | 3 | INV-01 | branch classes recounted = ref-counts.txt (always); patch-equivalent on main only with paths_match_main; at d0dbdf7: 23 ancestor, 0 to land, ≥ 24 unclassified, both merge-tree branches on main; namespaces sum 174; every Class in the four classes; scan --expect 8 | ⬜ pending |
| 189-04-T1 | 04 | 3 | INV-01 | dirty-buckets total = snapshot expanded count; env_excluded = independent untracked env recount; env_tracked_dirty = independent tracked-dirty env recount (kept in rows/tar; 0 live); rows sum = total − env_excluded; obsolete reasons checkable; verify --quick --plan 04 | ⬜ pending |
| 189-04-T2 | 04 | 3 | INV-02 | free-space precheck; manifest and tar counts = total − env_excluded; diff-HEAD 58; restore-04 6 pass; registry-04 6; `SHA256SUMS.04` 13 OK; scan --expect 4 | ⬜ pending |
| 189-05-T1 | 05 | 3 | INV-02 | env-counts parts = total; tracked_dirty ≤ total and ≥ independent tracked-dirty recount (tracked-and-dirty env files archived, only tracked-and-clean skipped); R-ENV unclassified; env-local.tar/.files mode 600; sensitive restore pass; no 64-hex or env path in PD | ⬜ pending |
| 189-05-T2 | 05 | 3 | INV-01, INV-02 | `SHA256SUMS.05` 5 (or 3) OK; obsolete ignored reasons only regen_check marker kinds; no env path in keep manifest; R-LOST-FOUND 248 obsolete; ignored-keep restore pass; scan --expect 4 | ⬜ pending |
| 189-06-T1 | 06 | 3 | INV-01 | tmp-repos 22 columns; per repo stash and reflog counts = stash list and log -g counts; independent sum > 0; unique/stash/unreadable never obsolete; shallow repos never fetched (captured_refs "-", boundary > 0, shallow + archived reason); non-shallow captured_refs = source ref count per repo; tmp-gitdirs.tsv = shallow + unreadable + zero-ref repos (absolute paths, boundary on shallow lines); no shallow tip in tmp-tips.tsv; cmp.git non-shallow; tmpitem total = captured sum; verify --quick --plan 06 | ⬜ pending |
| 189-06-T2 | 06 | 3 | INV-01 | entry map = frozen count; C-CAND once; every Class in the four classes; obsolete reasons in 4 forms; gitdir-tar planned when needed and on the candidate entry; R-TMP-COMMITS Count = distinct tmp-unique ids; `SHA256SUMS.06` 1 OK; scan --expect 4 | ⬜ pending |
| 189-07-T1 | 07 | 3 | INV-01, INV-02 | ahead/behind derived from fresh main (behind 0, ahead 90 at d0dbdf7); candidate-check keys exact; candidate HEAD a53fbef; `SHA256SUMS.07` 3 OK; restore-07 3 pass; C-CAND Count = ahead | ⬜ pending |
| 189-07-T2 | 07 | 3 | INV-03 | 7 PR rows, one allowed disposition each, 236 hold; pr-facts 7 OPEN; scan --expect 6 | ⬜ pending |
| 189-08-T1 | 08 | 4 | INV-02 | scratch-08 mode 700; b.git non-shallow; no tip from a shallow repo; tmp-commits.expect complete-history, refs = distinct tips; restore pass; unique_present N of N (N > 0) = fetched ids in tmp-unique.tsv | ⬜ pending |
| 189-08-T2 | 08 | 4 | INV-02 | `SHA256SUMS.08` covers every tmp-* file of plan 08 (not tmp-entries-full.tsv); tmp-gitdirs lines = independent recount (shallow + unreadable + zero-ref) ≥ shallow count; gitdir restores = tmp-gitdirs lines; candidate gitdir tar pass; every unclassified/to-land R-TMP row names an existing artifact with pass/see; .excluded reasons regen kinds, disjoint from .files; no env path; scan --expect 2 | ⬜ pending |
| 189-09-T1 | 09 | 5 | INV-01..03 | 7 per-plan manifests (02..08) exist non-empty before containment; `reconcile-189.sh` ok incl. tmp_ref_capture and tmp_gitdir_routing; env manifests allow only tracked-dirty env paths = env_tracked_dirty; registry total = pass total; `verify-189.sh --full` ok; `SHA256SUMS` = file count + 2, all OK | ⬜ pending |
| 189-09-T2 | 09 | 5 | D-06 | decision list names every unclassified row ID; scan hits 0; nothing staged | ⬜ pending |
| 189-10-T1 | 10 | 6 | D-15 | 22 scripts byte-equal and listed; after = before snapshot; no-deletion 3 × yes; HEAD unchanged | ⬜ pending |
| 189-10-T2 | 10 | 6 | D-14 | (executor prose avoids credential-class substrings) predoc-scan.txt records 10 class counts (home/user/gituser/owner 0); no stash reflog notation in any phase file; final scan files = independent count, hits 0; phase tar restore pass; `SHA256SUMS` all OK | ⬜ pending |
| 189-10-T3 | 10 | 6 | handoff | exactly one GSD command (`$gsd-discuss-phase 190 --ws quality-ratchet-release`) per Exact Next Action; 10 plan lines ticked; no home/backup-root/user/owner strings; verify --quick ok; nothing staged | ⬜ pending |

Phase-level criteria the map covers:

| Criterion | Requirement | Check | Exact-match assertion |
|-----------|-------------|-------|-----------------------|
| Inventory complete | INV-01 | recount sources and compare with table rows | dirty paths, 56 branches, 4 stashes, 2 worktrees, every `<tmp>/crosswake*` entry listed or group-listed; every row has a class and a non-empty reason; no *obsolete* row without a specific reason |
| Classification reproducible | INV-01 | re-run the bucket script | bucket counts equal the table |
| Backups restore | INV-02 | restore into scratch, compare | HEAD, tree ids, ref lists, file checksums equal; "no error" is never a pass |
| Manifest | INV-02 | `shasum -a 256 -c` | every line OK; line count equals backup file count |
| Candidate bundles | INV-02 | verify inside a repo, clone, compare | HEAD `a53fbef`, tree `f7c4d7dc`, `rev-list d0dbdf7..HEAD` = 90 |
| PR dispositions | INV-03 | table check | exactly 7 PRs, each one disposition with reason; #236 = hold |
| Frozen state | D-15 | before/after snapshot `diff` | zero differences |
| Privacy | D-14 | scan wrapper | exit 0, files count equals expected non-zero count, 0 hits; empty list and planted home path both fail |
| No deletions | ordering rule | listing digest of pre-existing `<backup-root>` and `<tmp>` Crosswake entries | unchanged; only additions |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Ticked at execution, not at planning.

- [ ] `lib-189.sh` — read-only wrappers (gr, gs with the fetch-from exception, gclone, ghr), reflog_ids, ph/san, locate (created by plan 01)
- [ ] `snapshot-189.sh` — read-only frozen-state digests (plan 01)
- [ ] `scan-privacy-189.sh` — 188 scan plus git user/owner fixed strings, different scratch prefix, empty-directory refusal, `--expect` files-count assertion (plan 01)
- [ ] `restore-189.sh` and `manifest-189.sh` — exact-match restores (bundle with complete-history, stash, tarfiles with sensitive mode, headpatch) recorded in per-plan `restore-registry-NN.tsv`; sha256 manifests (plan 01)
- [ ] `verify-189.sh` — `--quick` (plan 01; fails with zero manifests) and `--full` (plan 09)
- [ ] `lib-189.sh` `gitdir_abs` (absolute `--path-format=absolute --git-common-dir`) and `regen_check` (content markers for regenerable folders) (plan 01)
- [ ] `selftest-189.sh` — 46 negative controls for the scan, snapshot, wrappers, absolute git directory, restore, manifest, verify and regenerable markers (plan 01)
- [ ] Classification scripts: `classify-reflog-189.sh` (plan 02), `classify-stash-189.sh` and `classify-refs-189.sh` (plan 03), `classify-dirty-189.sh` (plan 04), `classify-tmp-189.sh` (plan 06), `reconcile-189.sh` (plan 09)

---

## Manual-Only Verifications

All phase behaviors have automated verification. Classifying *unclassified* items is a user decision before Phase 193, not a verification step.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
