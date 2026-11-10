---
phase: 201-fix-the-exact-public-companion-digest-proof-so-a-release-run
plan: 04
subsystem: release-candidate
tags: [hex, build_env, digest, exact-public-proof, measurement, pr-merge, privacy-scan]

requires:
  - phase: 201-fix-the-exact-public-companion-digest-proof-so-a-release-run
    provides: "201-03 companions-only fix on fix/exact-public-build-env-provenance (head be335acc, four local commits)"
  - phase: 201-fix-the-exact-public-companion-digest-proof-so-a-release-run
    provides: "201-02 planning record on origin/main (PR 286) and approvals contract (PR 284)"
provides:
  - "Measured proof on the real 0.2.13 family: the old rule reproduces the defect, the fix removes it for all five companions under Hex 2.5.1 and 2.7.0, the core stays strict"
  - "Two phase-local helper scripts (inspect-family-201.sh, compare-manifests-201.sh) with recorded controls"
  - "measure-201-manifests/: every compared manifest, provenance capture and tarball sha256 list, retained in phase evidence"
  - "The fix on main: PR 287 merged as a merge commit pinned to its CI-green head (merge fdc218f9)"
affects: [201-05, 201-06, 201-07, 201-08]

actuals:
  tokens: 11400
  tasks: 3
  commits: 3

plan_head_before: "24281245bf5e8d60c878ecfa3ec3d7c27b37cc48 (main checkout, branch docs/199-release-0-2-12)"
plan_head_after: "544706fa0e931d3dbed8c475bee6ebf4fad64475 (main checkout, before this SUMMARY commit); fix branch 57024c87 and main merge fdc218f9 live in the fix repo history"
commits: 3

tech-stack:
  added: []
  patterns:
    - "Measure a release-blocking proof on the real published artifacts, with a non-vacuous compare (self, one-flip and five-entry controls) before reading any verdict"
    - "Measurement state is copied into phase evidence; scratch holds only builds and unpacked trees"
    - "Fixture contents scanned file by file because a compressed inner archive hides them from a grep-based scan"

key-files:
  created:
    - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/scripts/inspect-family-201.sh
    - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/scripts/compare-manifests-201.sh
    - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-EVIDENCE/measure-201.txt
    - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-EVIDENCE/measure-201.json
    - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-EVIDENCE/measure-201-manifests/
    - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-EVIDENCE/privacy-201.txt
    - .planning/workstreams/quality-ratchet-release/phases/201-fix-the-exact-public-companion-digest-proof-so-a-release-run/201-EVIDENCE/fix-pr-201.json
  modified: []

key-decisions:
  - "The fix was merged under the AGENTS.md standing exception: merge commit pinned with --match-head-commit to the CI-green head; no --admin, --squash, --rebase or --auto; remote branch left in place; auto-delete read false"
  - "origin/main was merged into the fix branch with a merge commit (never a rebase) before the first push, because main had moved by the planning record and the approvals PR; the merge touched only .planning and docs files"
  - "No measurement was promoted into CI or script/required_check_policy.json (PD-04); the proof stays release-blocking"

requirements-completed: [REL-09]

coverage:
  - id: D1
    description: "The public six and a fresh Hex 2.7.0 build of the same six, both inspected by the fix, match 6/6 on metadata and payload, and the provenance lines show only the core digesting build_env"
    requirement: REL-09
    verification:
      - kind: command
        ref: "201-EVIDENCE/measure-201.txt: m2 metadata_equal=6/6 payload_equal=6/6 verdict=EQUAL rc=0; m2-provenance 12 lines, build_env_digested=yes on the two crosswake lines only"
        status: pass
    human_judgment: false
  - id: D2
    description: "The defect reproduces under the unchanged rule and the local build reproduces CI: public six against the approved receipt is metadata 1/6 (core only) payload 6/6; the local Hex 2.7.0 build equals the receipt 6/6"
    requirement: REL-09
    verification:
      - kind: command
        ref: "201-EVIDENCE/measure-201.txt: m1 metadata_equal=1/6 payload_equal=6/6 rc=1 (equal package crosswake); m1b 6/6 6/6 rc=0"
        status: pass
    human_judgment: false
  - id: D3
    description: "Toolchain dependence: a Hex 2.5.1 build equals the public manifest on all five companions and all six payloads and differs on the core only (5/6); under the old rule the 2.5.1 and 2.7.0 builds differ on all six metadata digests"
    requirement: REL-09
    verification:
      - kind: command
        ref: "201-EVIDENCE/measure-201.txt: m3 metadata_equal=5/6 payload_equal=6/6 rc=1, differ package crosswake only; m3-old metadata_equal=0/6 rc=1"
        status: pass
    human_judgment: false
  - id: D4
    description: "The compare script cannot score absence as equality: self-compare rc 0, one flipped digest rc 1 with 5/6, a five-entry manifest rc 2"
    requirement: REL-09
    verification:
      - kind: command
        ref: "201-EVIDENCE/measure-201.txt: controls-self rc=0, controls-flip rc=1 metadata_equal=5/6, controls-short rc=2"
        status: pass
    human_judgment: false
  - id: D5
    description: "The fix is on main through PR 287 with Crosswake CI green on its exact head, merged as a pinned merge commit, privacy-scanned over changed files, PR body, 273 fixture files and commit messages"
    requirement: REL-09
    verification:
      - kind: command
        ref: "201-EVIDENCE/fix-pr-201.json (head 57024c87, run 42700233686 success, ran-on 76d6415f, merge fdc218f9 with second parent the head, on origin/main); privacy-201.txt (run=1 rc=0, fixture-scan total files=273 with_hits=0, messages hits=0 rc=0)"
        status: pass
    human_judgment: false
  - id: D6
    description: "The fix on a live exact-public run: the 0.2.14 release run is the first live proof, and the artifact-provenance lines in the CI logs are first seen there"
    requirement: REL-09
    human_judgment: true
    rationale: "Only a real release run exercises the hosted proof and the hosted log emission; Plans 05 and 07 read it from the 0.2.14 release PR"

duration: about 32 min (CI wait 15 min of that)
completed: 2026-11-09
status: complete
---

# Phase 201 Plan 04: Measure the fix on the real 0.2.13 family, then land it on main Summary

**On the six real 0.2.13 tarballs the old rule reproduces the false positives (metadata 1/6, payload 6/6) and the companions-only fix removes them for all five companions under both Hex 2.5.1 and 2.7.0; the core still differs when a different Hex builds it. The fix then landed on main as PR 287, a merge commit pinned to its CI-green head.**

## What was run and what decided it

| Block | Question | Output that decided it |
|---|---|---|
| controls-self / controls-flip / controls-short | Can the compare script report a false equal? | `rc=0`; `rc=1` with `metadata_equal=5/6`; `rc=2` for a five-entry file |
| m2 | Public six versus fresh Hex 2.7.0 build, both through the fix | `metadata_equal=6/6 payload_equal=6/6 verdict=EQUAL`, `rc=0` |
| m2-provenance | Does only the core digest `build_env`? | 12 lines, `build_env_digested=yes` on the two `package=crosswake` lines only |
| m1 | Does the unchanged rule reproduce the 0.2.13 defect on the public six? | `metadata_equal=1/6 payload_equal=6/6`, only `crosswake` equal, `rc=1` |
| m1b | Does the local Hex 2.7.0 build equal CI's approved receipt? | `6/6 6/6`, `rc=0` |
| m3 | Hex 2.5.1 build through the fix versus the public six | `metadata_equal=5/6 payload_equal=6/6`, only `crosswake` differs, `rc=1` |
| m3-old | Old rule, Hex 2.5.1 build versus Hex 2.7.0 build | `metadata_equal=0/6`, `rc=1` |
| m4 | Release history | four rows, plus the two CI Hex log lines `hex-2.7.0` and `hex-2.5.1` |

`measure-201.json` records `verdict: PASS`; its verify command exits 0.

The provenance lines show the mechanism on real data. The public companions print `build_env_hex=none`; the Hex 2.7.0 rebuilds print `build_env_hex=2.7.0` and `build_env_digested=no`; the core prints `2.7.0` and `yes` on both sides. A Hex 2.5.1 build writes no `build_env` at all (`build_env_hex=none` for all six, including the core), which is why the core differs there.

## Accomplishments

- Two bash 3.2 helper scripts (inspect a family with a chosen checkout's `Artifact`, compare two manifests per package) with three recorded controls before any verdict.
- M1 to M4 measured on the real family; every compared manifest, provenance capture and tarball sha256 list copied to `measure-201-manifests/` (16 files, 496K), so later plans read evidence rather than scratch.
- PR 287 (`fix/exact-public-build-env-provenance`) merged as `fdc218f9`, a merge commit whose second parent is the CI-green head `57024c87`.

## Landing the fix

- **CI ran on:** run 42700233686 on head `57024c8726cdc665de950c0490a550dd3a14b6c5`. As a pull-request run, GitHub checked out the synthetic merge commit `76d6415f9008398b9134d8a7fa37301cf10263f0` ("Merge 57024c87 into 44e2f69b"), read from the checkout step of the `e2e-proof` job log. That is not the head. origin/main was still `44e2f69b` at merge time, so the synthetic merge had the same base as the real one.
- **Result:** all jobs success, `gh pr view` reported `MERGEABLE CLEAN`. One wait, 8 reads at 2-minute intervals, 15 minutes of the 45-minute bound, result DONE. No job was re-run and no fix-forward cycle was needed.
- **Merge:** `deleteBranchOnMerge` read `false` immediately before; `gh pr merge 287 --merge --match-head-commit 57024c87...` once, rc 0, merged `2026-11-09T21:28:48Z`. `git fetch` then showed `fdc218f9` on origin/main with parents `44e2f69b` and `57024c87`. The remote branch was left in place and no remote branch was deleted.
- **PR contents:** `gh pr view 287 --json files` lists zero `.planning/` paths. The docs branch `docs/199-release-0-2-12` is not on the remote.
- **Privacy:** the five changed text paths plus the PR body (6 inputs) scanned clean (`run=1 rc=0`); the three fixtures were extracted and every file scanned one per invocation (273 files, 0 hits, so no disposition lines were needed; the scanner's self-test passed 21 of 21 and a planted home-path control returned rc 1 first); the five commit messages scanned clean (`hits=0 rc=0`). After the PR was opened no new commit was made on the fix branch, so no rescan was owed. The recorded evidence files (22) were scanned clean before the final commit.

## CI cost report (advisory)

`bash script/ci_cost_report.sh 42700233686`: **164 billable minutes** against the recorded baseline of about 250, **14.4 min wall clock** against 20 to 44, critical path `phase130-core-hermetic-proof` at 14 min, **2** jobs with a full-suite step against a baseline of about 10 (step-name heuristic). The report printed no flag, so no new duplicated full-suite run and no uncached job was surfaced; `flags: []` in `fix-pr-201.json`. This PR changes a library file and a test file, so it is a light run by nature and is not evidence that the baseline moved.

## Task Commits

All in the main checkout on `docs/199-release-0-2-12` (not pushed):

1. **Task 1 (tracer): scripts, controls and M2** - `df3a6f83`
2. **Task 2: M1, M1b, M3, M3-old, M4 and the measurement record** - `ec62ce31`
3. **Task 3: privacy evidence and the PR record** - `544706fa`

In the fix worktree: merge commit `57024c87` (origin/main into the fix branch, the only commit made there). On origin/main: merge `fdc218f9`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `hex_artifacts.sh --manifest` cannot point outside the output directory**
- **Found during:** Task 1, building the Hex 2.7.0 candidate
- **Issue:** the plan wrote the manifest to `M/cand27.artifacts.json`. All six tarballs built, then `Artifact.inspect_cli!/1` raised `candidate artifact input is invalid` at the manifest step, because `ensure_within!/2` requires the manifest to sit inside the output root.
- **Fix:** moved the failed scratch directory aside and re-ran the same build without `--manifest`, so the script writes `<output-dir>/artifacts.json`; that file is the old-rule manifest copied to `old-cand27.json`. The same form was used for the Hex 2.5.1 build. The failed first attempt wrote no manifest and its tarballs were not used; the second run's tarballs are the ones inspected.
- **Files modified:** none in the repo.
- **Commit:** none needed.

**2. [Rule 3 - Blocking] A plan verify line fails on macOS**
- **Found during:** Task 1 verification
- **Issue:** `test "$(wc -l < file)" = 6` compares `"       6"` (BSD `wc` pads with spaces) to `6`, so it exits 1 on a file with exactly six lines.
- **Fix:** checked the same fact numerically (`wc -l` printed 6 for both sha256 lists, and the `[       6]` padding was shown). The evidence is correct; only the check's string comparison was platform-sensitive. Later plans that reuse this line should compare numerically.
- **Files modified:** none.

**3. [Rule 2 - Missing critical] Scratch paths redacted in committed evidence**
- **Found during:** Task 1, before the first commit
- **Issue:** the retained manifests carry an `unpacked_root` that is an absolute scratch path containing the maintainer's home-folder slug, and one control line echoed such a path.
- **Fix:** rewrote `unpacked_root` to `<scratch>/unpacked/<package>` in the retained manifests and `<scratch>/` in `measure-201.txt`; the redacted manifests were re-compared (`m2` 6/6 EQUAL) to show no digest changed. `approved.json` and the sha256 lists were untouched. The path field is not part of any digest.
- **Files modified:** `measure-201-manifests/{m1-public,m2-public,m2-cand27,m3-cand25,old-cand25,old-cand27}.json`, `measure-201.txt`.

**4. [Rule 3 - Blocking] Scratch location**
- Scratch lived under the session scratchpad directory instead of `$TMPDIR`, because the session instructions require that location. It is still transient scratch, never read by a later plan.

**Total deviations:** 4 (2 blocking plan-instruction defects, 1 privacy redaction, 1 location). **Impact:** none on the measurement or the merge.

## Issues Encountered

- The harness moves any foreground command past 180 seconds to the background and blocks foreground `sleep`, so the CI wait was done with bounded read loops (reads every 2 minutes) and the loop's own record of each read.
- `Monitor` and `TaskStop` were not available; a duplicate wait loop was left to finish on its own.

## Authentication Gates

None.

## Known Stubs

None.

## Threat Flags

None. No new network endpoint, auth path or schema was added. The only new surface is two phase-local scripts that unpack public tarballs into a new empty scratch directory and run no code from them (T-201-06).

## Threat model status

- T-201-05: the compare script exits 2 below six entries; self, one-flip and short controls recorded; each of M2 and M3 names its per-package lines and M3 shows exactly one named difference.
- T-201-06: tarballs were only fetched with `mix hex.package fetch` (checksum-verified), copied and officially unpacked into new directories; no `mix` command ran inside an unpacked tree.
- T-201-07: privacy scans of paths, PR body, 273 fixture files and commit messages clean before the push; no `.planning/` path in the PR.
- T-201-08: merged only with CI green on the exact head, `--match-head-commit`, no bypass flag, auto-delete read false.
- T-201-30: all compared manifests, provenance captures and tarball hash lists are in `measure-201-manifests/`.

## Not verified here

- The fix on a live release run, and the `artifact-provenance` lines in hosted CI logs from `hex_artifacts.sh` and `verify_companion_cleanroom.sh`. Plans 05 and 07 read them from the 0.2.14 release PR.
- A Hex release newer than 2.7.0: none existed on 2026-11-09 (newest tag `v2.7.0`, published 2026-11-06), so `m3-latest` was not run.
- Linux builds: the local measurement is macOS arm64. Linux equality for the five companions was already shown by CI in run 42639651064 (payloads equal and the only difference was `build_env`).
- That Release Please has refreshed PR 283 onto `fdc218f9`; Plan 05 checks that the 0.2.14 head contains this merge.
- Per-job cache status in the CI cost report: the report prints no flag, and I did not inspect each job's cache step by hand.

## Next Phase Readiness

Ready for 201-05 (0.2.14 candidate capture). The merge `fdc218f9` in `fix-pr-201.json` (`merge_oid`) must be an ancestor of the 0.2.14 release PR head. The fix worktree `~/projects/crosswake-201-wt` still exists on the merged branch and is clean; the measurement worktree `crosswake-201-old-wt` was removed without `--force`. No tag, publish, release-PR merge or release workflow dispatch was done, and no remote branch was deleted.

## Self-Check: PASSED

- Scripts, measure-201.txt and .json, privacy-201.txt, fix-pr-201.json and all 16 manifest-directory files exist; every task's `<verify>` commands were re-run and pass (the one macOS `wc` line was checked numerically, see Deviation 2).
- Commits `df3a6f83`, `ec62ce31` and `544706fa` are ancestors of the docs branch head; `fdc218f9` is an ancestor of origin/main and its second parent is `57024c87`.
- `crosswake-201-wt` status prints nothing; `crosswake-201-old-wt` is not in `git worktree list`; `git ls-remote origin refs/heads/docs/199-release-0-2-12` prints nothing.

---
*Phase: 201-fix-the-exact-public-companion-digest-proof-so-a-release-run*
*Completed: 2026-11-09*
