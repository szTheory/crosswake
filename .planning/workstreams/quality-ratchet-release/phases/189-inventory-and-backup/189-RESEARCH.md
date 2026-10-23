# Phase 189: Inventory and backup - Research

**Researched:** 2026-10-16
**Domain:** read-only git forensics, git bundle/tar backup with restore tests, frozen-checkout verification
**Confidence:** HIGH for counts and mechanics (all measured this session); MEDIUM for classification of the 24 branches and the recovery-only code (content comparison done, semantic review not done)

Provenance used below: `[VERIFIED: command]` = run this session against real data; `[ASSUMED]` = not verified here.
Placeholders: `<recovery-checkout>`, `<backup-root>` (the existing sibling folder that holds the candidate bundles; its path is deliberately not written here), `<tmp>` (the system temp root), `<scratch>` (research scratch space).

<user_constraints>
## User Constraints (from 189-CONTEXT.md)

The 15 locked decisions D-01..D-15 live in `189-CONTEXT.md` and are binding. They are summarized, not copied verbatim, because this file must itself pass the phase privacy scan (the scan's credential class flags several ordinary words that appear in CONTEXT.md). The planner must read CONTEXT.md directly.

- D-01/D-02: backups only in the existing sibling `<backup-root>`; nothing off-machine; planning files use placeholders, never absolute or home paths.
- D-03/D-04: scope is Crosswake work only (candidate, other `<tmp>` Crosswake items, recovery checkout changes/stashes/branches, 2 extra worktrees); empty or broken folders are listed as "empty/no repo, nothing to keep" and classed obsolete; no removal in 189.
- D-05/D-06/D-07: classify by content against fresh GitHub `main` plus candidate `a53fbef`; obsolete only with a specific checkable reason, otherwise unclassified (backed up); file-by-file for the non-planning paths, same method for planning paths.
- D-08/D-09/D-10: read-only git only against the recovery checkout; backup set = all-refs bundle, 4 stash exports (patch + commit ids), uncommitted tar + `git diff HEAD` patch, bundles/tars for other `<tmp>` clones only if they hold unique content, reuse and re-verify the candidate bundles; restore test in a scratch folder, exact-match comparison, sha256 manifest.
- D-11/D-12/D-13: PR dispositions recorded only (dependabot = redo after landing or close if superseded; 238 = decide by content; 236 = hold; note whether landing changes it).
- D-14/D-15: one Markdown inventory table; privacy grep of all new phase files, zero hits, must fail on empty scope; before/after snapshot of the frozen checkout must be identical.

### Claude's Discretion
Table columns, scratch layout, bundle/archive file names inside `<backup-root>`, one bundle or several.

### Deferred Ideas (OUT OF SCOPE)
Off-machine backup during 189; cleanup of other projects' folders under `<tmp>`.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| INV-01 | One inventory of every copy of work not on `main`, classified by content | Sections "Measured inventory", Q3-Q8 tables, classification method |
| INV-02 | Everything to-land or unclassified backed up outside `<tmp>` with passing restore test | "Backup plan", "Restore tests", stash capture method |
| INV-03 | Disposition recorded for PRs 238, 236, 210, 211, 239, 240, 241 | "PR dispositions" |
</phase_requirements>

## Summary

The inventory is much larger than the starting facts in CONTEXT.md and the milestone scope state. Corrections measured this session `[VERIFIED: git/ls/gh, 2026-10-16]`:

1. GitHub `main` is `d0dbdf7bf196cea167ced3c50cf620bf3cb2452b`. The candidate is `a53fbef70d20e6ee49f1ebd2ee783c991f95a7b4`: 0 behind, 90 ahead of that `main`. Both unchanged from the scope facts.
2. The recovery checkout has 740 dirty paths when untracked directories are expanded (`--untracked-files=all`): 58 modified + 682 untracked. The "62 untracked" figure is the collapsed view (directories count as one). Planning: 662 paths (13 modified, 649 untracked). Non-planning: 78 paths with expansion (45 modified, 33 untracked); 73 in the collapsed view. All 740 total only ~14.7 MB, no symlinks, no file over 1 MB, 12 executable files, no odd characters in names.
3. `<tmp>` has 159 Crosswake-named entries (81 directories, 78 loose files), not 16 folders. Eight are valid repos at top level, 12 more valid repos are nested inside other folders, and 8 further `.git` stubs are broken (no valid HEAD), and the glob `crosswake-*` misses three names (`crosswake` + space-named checker folder, `crosswake176-*`, `crosswake178-*`). Use the glob `crosswake*`.
4. The existing "full" candidate bundle is NOT a connected full history. The candidate is a shallow clone (boundary at `d0dbdf7`); a clone from the full bundle has the 90 candidate commits and `main`'s tip, but `git fsck` reports a broken link from `d0dbdf7` to its parent. HEAD and tree restore correctly (`a53fbef`, tree `f7c4d7dc1a86f251c3ba845d3cde8d4c770ae729`), and the incremental bundle verifies. The restore test for the candidate must therefore use `rev-list d0dbdf7..HEAD` (90) and tree equality, never `fsck` or an unbounded `rev-list`.
5. Four stashes, each with an untracked-files third parent. `refs/stash` bundles only stash 0; the others are reflog-only and are not ancestors of stash 0. A local `git clone --mirror` of the recovery checkout copies the whole object directory (reflog-only objects included), which makes a read-only, complete capture straightforward.
6. A real source of risk: a first-pass `git fsck --lost-found` run by this research wrote `.git/lost-found/` (248 small files) inside the recovery checkout. See "Safety incident" below. Nothing in the D-15 snapshot (HEAD, refs, stash list, worktrees, porcelain) changed.

**Primary recommendation:** Build every backup from a scratch `git clone --mirror --no-hardlinks` of the recovery checkout (a pure read), add explicit refs for the four stash commits inside the scratch mirror, bundle with `--all`, tar the dirty file list with a verified file manifest, restore every artifact into a scratch folder, and gate on exact-match comparisons plus a sha256 manifest in `<backup-root>`. Keep the D-15 snapshot to refs/HEAD/stash/worktrees plus two porcelain digests, with the phase-189 folder excluded from the expanded one.

## Safety incident (disclosed)

While probing for unreachable objects, this research ran `git fsck --lost-found --no-reflogs` in the recovery checkout. That command writes dangling-object ids into `.git/lost-found/` (222 files under `commit/`, 26 under `other/`, all created at the same minute). It does not touch refs, HEAD, the index, stashes, worktrees or any tracked/untracked working file. The D-15 snapshot taken afterwards was byte-identical to the one taken before (`[VERIFIED: snap script run twice, plus after]`). Index modification time was unchanged. The directory did not exist before (every file in it is new). Cleanup is a decision for the caller: the exact reversal is removing that one directory. The plan must NOT run `fsck`, `gc`, `prune` or `count-objects`-style commands that can write. Add `fsck` and `--lost-found` to the planner's forbidden-command list for the recovery checkout. `[VERIFIED: find over .git, this session]`

## Architectural Responsibility Map

Not a multi-tier application phase; the equivalent is "who owns each artifact".

| Capability | Primary owner | Secondary | Rationale |
|------------|---------------|-----------|-----------|
| Inventory table (item, location, kind, class, reason, backup id, restore result) | Phase folder (git-tracked later via Phase 191 carry) | none | Human-readable evidence, placeholders only |
| Backups (bundles, tars, patches, manifest) | `<backup-root>` (outside the repo, outside `<tmp>`) | none | D-01 |
| Raw command output | Phase folder evidence files, after privacy scan | scratch during run | D-14 |
| Run scripts | Scratch run folder, then byte-copied into phase `scripts/` with a sha256 list | none | Phase 188 precedent |
| Frozen-state proof | Before/after snapshot files in the phase folder | none | D-15 |

## Standard Stack

No new packages. Everything is git plus POSIX tools already on the machine.

| Tool | Version | Purpose | Notes |
|------|---------|---------|-------|
| git | 2.41.0 `[VERIFIED: git --version]` | cherry, merge-tree --write-tree, bundle, clone --mirror, hash-object | merge-tree `--write-tree` needs 2.38+ (present) |
| gh | present `[VERIFIED: gh repo view, gh pr view, gh api]` | PR data, GitHub commit existence | read-only calls only |
| bsdtar 3.5.3 `[VERIFIED: tar --version]` | uncommitted-work archives | set `COPYFILE_DISABLE=1` to avoid AppleDouble `._*` entries |
| shasum -a 256 | system | manifest | `shasum -a 256 -c` verifies |

Package Legitimacy Audit: not applicable, no external packages installed.

## Measured inventory (answers to Q1-Q8)

### Q1 Fresh main and candidate
- `git ls-remote <github-url> refs/heads/main` returned `d0dbdf7bf196cea167ced3c50cf620bf3cb2452b`; a fresh bare clone's `main` matched. `[VERIFIED: ls-remote + clone]`
- Candidate: `rev-list --left-right --count d0dbdf7...HEAD` = `0	90` in `<tmp>/crosswake-phase180-impl`; detached HEAD; `.git/shallow` lists `d0dbdf7`. Its `origin` points at `<tmp>/crosswake-phase179-impl`. `[VERIFIED]`
- The recovery HEAD `d0f3e2f1` is not an ancestor of `main`: 91 commits only in `main`, 249 only in the recovery lineage, merge-base `52345b48`. `[VERIFIED]`

### Q2 Existing candidate bundles
Location: `<backup-root>` (a sibling of the project folder, found by listing the project's parent; v27.0-SCOPE.md deliberately does not record it). Contents: `candidate-a53fbef-full.bundle` (about 14.3 MB) and `candidate-a53fbef.bundle` (about 0.49 MB). No manifest file exists there yet. `[VERIFIED: ls]`
- `git bundle verify` must be run inside any repository (outside one it fails with "need a repository to verify a bundle"). From a scratch bare repo: full bundle "is okay", lists `a53fbef...` as `HEAD`; incremental "is okay" and requires `d0dbdf7bf196cea167ced3c50cf620bf3cb2452b`. `[VERIFIED]`
- Recorded restore test: v27.0-SCOPE.md records a clone from the full bundle reproducing HEAD `a53fbef` and tree `f7c4d7dc`. Re-run this session: clone succeeds, HEAD `a53fbef70d20e6ee49f1ebd2ee783c991f95a7b4`, tree `f7c4d7dc1a86f251c3ba845d3cde8d4c770ae729`, `rev-list d0dbdf7b..HEAD` = 90. `fsck --connectivity-only` in the restored clone fails ("broken link ... missing commit 2dbde2d9..."), because of the shallow boundary. `[VERIFIED]`
- Recommendation: re-verify both bundles with D-10 checks as written but with the bounded rev-list. Because the "full" bundle is not self-contained, ADD (do not replace) one connected candidate bundle built in a scratch clone: fresh bare clone of GitHub `main` with the candidate commits fetched in, then `git bundle create ... <candidate-sha>`. This slightly extends D-09's "reuse, not rebuilt" and is justified by the fsck finding. Mark this as a planner decision.

### Q3 Recovery checkout dirty paths
Method `[VERIFIED]`: `git --no-optional-locks status --porcelain=v1 --untracked-files=all`; each path's working file hashed with `git hash-object` (no `-w`) and compared with `rev-parse <ref>:<path>` in a scratch repo holding GitHub `main`, the candidate, and the recovery HEAD (objects fetched from the recovery checkout into scratch; this writes only scratch).

| Group | Paths | Modified | Untracked |
|-------|-------|----------|-----------|
| Total (expanded) | 740 | 58 | 682 |
| Total (collapsed, default mode) | 121 | 58 | 63 |
| Planning (under `.planning/`) | 662 | 13 | 649 |
| Non-planning, expanded | 78 | 45 | 33 |
| Non-planning, collapsed | 73 | 45 | 28 |

Non-planning buckets (78 paths):

| Bucket | Modified | Untracked | Meaning |
|--------|----------|-----------|---------|
| Identical to both `main` and candidate | 1 | 3 | on main (the 4 files: one evidence_live source, `policy_read` source and its test, one iOS release-host script) |
| Differs from both | 29 | 0 | needs per-file review; sub-split: 23 where `main` equals candidate but both differ from the recovery HEAD, 4 where HEAD equals `main` equals candidate (a pure uncommitted edit), 2 where all three differ |
| Absent from both `main` and candidate | 15 | 30 | recovery-only Phase 175 release_candidate sources/scripts/tests (tracked-modified 15; untracked 30 including 6 scratch files under `.tmp/plan85`) |

Planning buckets (662 paths): 0 identical to `main` or candidate; 11 modified differ (PROJECT, RETROSPECTIVE, WINDOWS, config, 2 seeds, verification ledger, MILESTONES, REQUIREMENTS, ROADMAP, STATE); 2 modified and 649 untracked are absent from both. All 662 are "to land" or unclassified, none "on main". Heavy review is therefore limited to about 29 + 45 non-planning files; the 649 untracked planning files are whole directories (phases 176-188, milestone archives v24-v26, history snapshots, research) and classify as a group per directory.

Ignored content (not in porcelain): top-level ignored entries total several GB (`.build` 2.7 GB, `tmp` 0.48 GB, `.expert` 0.23 GB, `.claude` 0.13 GB, plus `_build`, `deps`, node_modules). One local-only environment file exists and must never be copied, listed with contents, or hashed into evidence. Candidates worth keeping because they are not regenerable: `.claude/settings.local.json` and the worker json/log files beside the extra worktree, one locally-excluded prompt document, `.planning/research/.cache`. Recommendation: record an ignored-entries list (name + size only) in the inventory as one row group, classify build caches as obsolete with reason "regenerable build/test output", back up the few small non-regenerable files by explicit allow-list, and put the rest into the user's decision list. `[VERIFIED: ls-files --others --ignored --directory + du]`

### Q4 Stashes
`git --no-optional-locks stash list --format='%gd %H %s'` `[VERIFIED]`:

| Index | Commit | Subject (short) | Parents | Untracked 3rd parent |
|-------|--------|-----------------|---------|-----------------------|
| 0 | 5c36ccd89f9e9be6654f31b74dd0674379e47cfb | planning preservation, PR-branch retry (on agent-169-05-gap-closure) | d1c679dd, 81601bc1 | f711c8eb (15 files) |
| 1 | 66d71ea49c52e6ea37e207c4b2128d7273ae8ec9 | planning preservation, PR-branch (same branch) | d1c679dd, 8c90997d | 5bacf6a6 (15 files) |
| 2 | 5690640d3d332efbe5f4db932f5925784f9bc6c0 | pre-175-12 authoritative draft | a061c024, f53cfff2 | 587f36ab (2 files) |
| 3 | d77f0beae43cb45b28148b3192c5b5643720d387 | WIP on `main` at `e3d6cbfa` (merge of PR 62) | e3d6cbfa, 14179f7a | ec4b866a (83 files) |

- `refs/stash` has a single ref; its reflog lists the four ids. Stashes 1-3 are NOT ancestors of stash 0 (`merge-base --is-ancestor` false for each), so `git bundle create x.bundle refs/stash` captures stash 0 only. `[VERIFIED]`
- All four have a third parent (untracked files). Plain `git stash show -p` omits it; use `--include-untracked` (git 2.41 supports it), or equivalently `git diff <sha>^1 <sha>` for tracked changes and `git show <sha>^3` for untracked files.
- Tested safe capture: a scratch bare repo ran `git fetch <recovery-checkout> <commit-sha>` for each of the four ids (protocol v2, default; no `allowAnySHA1InWant` setting needed), then `update-ref refs/stash-backup/<n> <sha>` and `git bundle create <out> --all`. Bundle verified; `clone --mirror` from it restored all four refs with identical ids and the third-parent tree (83 files for stash 3). Source refs, index modification time and snapshot digests were unchanged. `[VERIFIED]`
- Simplest, equally verified route: `git clone --mirror --no-hardlinks <recovery-checkout> <scratch>/mirror.git` (a local clone copies the entire object directory). It reproduced all 174 refs exactly (diff empty) and contained every one of the 2897 distinct reflog-reachable commit ids (0 missing), including stashes 1-3 and their untracked parents. Then in the mirror: `update-ref refs/stash-backup/<n> <stash-sha>` from the recorded list, `git bundle create <out> --all`. Total mirror size about 131 MB. `[VERIFIED]` Fall back to the per-sha fetch if the mirror is ever incomplete.
- Refs in the recovery checkout: 56 heads, 56 remote-tracking, 59 tags, 1 `refs/gsd/*`, 1 `refs/tmp/*`, 1 `refs/stash` (174 total). `--all` captures every namespace; verify the restored list equals this list plus 4 stash-backup refs.

### Q5 Branches (56 local heads)
Method `[VERIFIED]`: all heads fetched into a scratch repo; per branch `merge-base --is-ancestor`, `git cherry main <branch>` (patch-id), and `git merge-tree --write-tree main <branch>` (result tree compared with `main`'s tree = content already contained).

| Class | Count |
|-------|-------|
| Ancestor of `main` (fully contained) | 23 |
| Patch-equivalent to `main` (every commit has a patch-id twin) | 7 |
| Merge into `main` yields `main`'s tree (content contained, patch-ids differ) | 2 (`fix/align-companion-core-constraints`, `fix/remove-stale-rulestead-release-as`) |
| Has commits not in `main` | 24 |
| Ancestor of or equal to candidate beyond `main` | 0 (the candidate contains none of these) |
| Total | 56 |

The 7 patch-equivalent: `chore/v15-coll01-advisory-deferred`, `chore/v15-milestone-archive`, `feat/sigra-personal-session-release`, `fix/hex-publish-clean-release`, `fix/sigra-cleanroom-default`, `phase-175-receipt-assembly`, `test/pack-store-waiter-clarity`.

The 24 with unique commits (commits ahead of `main` / patch-unique commits; none is content-contained and none overlaps the candidate): `agent-169-05-gap-closure` 56/46; `agent-169-05-gap-closure-pr` 5/5; `archive/v21-parked-pre-reconcile-20260828` 179/56; `backup/pre-179-local-main` 3/3; `chore/accrue-host-command-bridge` 14/14 (also a worktree); `chore/first-adopter-guidance-cleanup` 1/1; `chore/sync-main-20260805` 746/746; `chore/track-110-patterns` 1/1; `docs/alpha-reference-host-seed` 41/2; `docs/seed-007-ci-cd-performance` 2/1; `docs/sigra-personal-account-authority-seed` 1/1; `feat/iphone-rehearsal-handoff` 3/3; `fix/hex-registry-cache` 2/2; `fix/release-rollup-dependencies-pr` 2/2; `gsd/phase-168-0-2-1-release-candidate-readiness` 3/3; `gsd/phase-175-evidence-execution` 4/4; `local/main-pre-remote-sync-20260808` 738/738; `main` (local) 9/5; `phase-174-clean-room-host-realism` 28/28; `phase-175-ios-tag-repair` 2/2; `recovery/phase-175-orchestrator-2026-09-27` 249/233; `release-please--branches--main--components--crosswake_sigra` 2/2; `resume/chimeway-notification-physical-proof` 3/3; `worktree-agent-p78-20261004T153017` 141/127.

Classification guidance (D-06): the 30 contained branches (23 + 7... plus the 2 content-equal) may be classed "on main" with the specific reason ("ancestor of main", "every commit patch-equivalent in main", "merge result equals main tree"). The 24 stay unclassified: patch-id differences can also come from squash merges, so a squash-merged old branch looks "unique" here. Do not guess obsolete; they are covered by the all-refs bundle, and the user decides before Phase 193. A cheap extra signal the planner may add: for the small branches, `git diff --stat main...<branch>` size and whether the touched files exist on `main`.

### Q6 Extra worktrees
`git --no-optional-locks worktree list --porcelain` `[VERIFIED]`:

| Worktree | HEAD | Branch | Dirty paths | Commits vs main / candidate |
|----------|------|--------|-------------|------------------------------|
| `<recovery-checkout>/.claude/worktrees/agent-p78-20261004T153017` | 0c050084 | `worktree-agent-p78-20261004T153017` | 10 modified, all planning (PROJECT, REQUIREMENTS, ROADMAP, STATE, Phase 175 plan/context/patterns/research docs and others); about 110 MB on disk | 141 ahead of `main`, 127 patch-unique, same vs candidate |
| `<project-parent>/crosswake-accrue-bridge` (sibling of the project) | 789175f2 | `chore/accrue-host-command-bridge` | 1 modified (`.planning/config.json`); about 289 MB on disk (build output) | 14 ahead, 14 patch-unique, same vs candidate |

Both branches are in the all-refs bundle. Each worktree needs its own `diff HEAD` patch plus a tar of its dirty files (11 files total). Status calls on worktrees must also use `--no-optional-locks`. Also note: the worktree-local `HEAD`/index files live in `.git/worktrees/*` and are not captured by a bundle (they are recreatable).

### Q7 `<tmp>` Crosswake items
Counts `[VERIFIED: ls, find, git]`: `crosswake*` has 159 entries: 81 directories and 78 loose files (75 matching `crosswake-*` at about 11.6 MB, plus the `crosswake176-*`/`crosswake178-*` files and a space-named checker folder). Loose files are scripts, json, logs, a tar; the 1.7 GB `crosswake-phase180-run` holds prior-phase scripts and run output; `crosswake-178-toolchain` is 3.6 GB of installed tooling.

Valid repos (top-level and nested) and their position relative to `main`, the candidate and every recovery ref and stash:

| Folder | HEAD | Dirty | Commits not elsewhere | Verdict |
|--------|------|-------|------------------------|---------|
| `crosswake-phase180-impl` (candidate) | a53fbef | 0 | 0 (it is the reference) | to land (existing bundles) |
| `crosswake-phase179-impl` | 96e5a63e | 41 untracked planning files (2 collapsed) | 0; all 31 commits already in candidate by patch-id | commits on candidate; of the 41 files, 38 are byte-identical to files in the recovery checkout, 1 differs, 2 are absent there: unclassified until diffed |
| `crosswake-phase179-source` | d0dbdf7 | 0 | 0 (equals `main`) | on main |
| `crosswake-phase181-impl` | 12f84cd9 | 0 | 0 (57 patch-unique vs `main`, all in candidate) | on candidate |
| `crosswake-phase182-impl` | da53c54d | 0 | 0 (74 vs `main`, all in candidate) | on candidate |
| `crosswake-178-diagnostic-clone` | f2d8875e | 4 modified (release gate, release receipt, one native-lane proof test, one test support file) | 2: `3e8a4b26` (the head of PR 238, on GitHub) and `f2d8875e` (GitHub's PR merge ref) | 4 modified files differ from `main`, candidate, and the recovery checkout: unclassified, tar + diff |
| `crosswake-178-handoff.WKuxnb-delivery` and `-proof` | 5923a679 | 0 | 1 each: `5923a679` "qualify maintenance candidate" is NOT on GitHub (`gh api` returns not found) | unclassified; bundle once |
| `crosswake-177-source/crosswake` | d0dbdf7 | 6 modified | 0 | 5 of 6 equal PR 238 head files, 1 differs: unclassified, diff + tar |
| `crosswake-178-handoff.WKuxnb/repair-clone.*` | 5923a679 | 3 modified | 1 (same commit) | 3 of 3 equal PR 238 head files; commit as above |
| `crosswake-178-gates-*/repo` (6) | 3e8a4b26, f2d8875e, 5923a679 | 26-72 each (planning files) | PR 238 head / merge ref / the local-only commit | gate-run working copies; planning dirty content unclassified |
| `crosswake-178-regression-epoch-*/crosswake` | f2d8875e | 1824 (1811 untracked planning, 11 modified) | 2 (as above) | unclassified (large untracked planning set) |
| `crosswake-178-index-diagnosis/*/` (3 nested repos) | 3e8a4b26 | 0 | PR 238 head | on GitHub (PR ref); nothing to keep beyond the PR |
| Broken `.git` stubs (8): `phase175-chimeway011-shallow-proof`, `-exact-public-candidate-source`, `-exact-public-source`, `-matrix-installer-tracked-check`, `-pr230-tracked-check`, `-pr233-tracked-check`, `-release-source-20261011`, `public-ios-packages/checkouts/...` | no valid HEAD | n/a | n/a | not repos; a few contain plain files (up to 64 MB for the exact-public candidate source and 13 MB for the Chimeway proof) |
| `crosswake-phase175-*` non-repos | n/a | n/a | n/a | 50 entries; about 23 are empty (0 files); the rest are small release-evidence copies (under 2.4 MB each except two source copies); release-workflow scratch of consumed Phase 175 operations |
| `crosswake-v24/v25-*` previews and others | n/a | n/a | n/a | planning previews/scratch: unclassified unless matched by content to an archived v24/v25 record |
| `crosswake-phase180-run` (1.7 GB) | n/a | n/a | n/a | scripts/outputs of Phases 180-188; the scripts were byte-copied into phase folders (`188-SCRIPTS.sha256` pattern); outputs: unclassified |

Method note: unique-commit counts come from `rev-list <head> --not <GitHub main> <candidate> <all recovery refs, tags, gsd/tmp refs and the four stash commits>`. The bundle-worthy repo content outside the candidate is small: the local-only commit `5923a679`, and the dirty trees of the 178/177 clones. The empty/no-repo folders qualify for D-04 ("empty/no repo, nothing to keep", obsolete). Folders with files but no repo cannot be classified by git; classify by content-hash comparison against the candidate/recovery tree where they are source copies, otherwise leave unclassified and tar them (the large ones, `-toolchain`, `-index-diagnosis`, `-177-source` and `-phase180-run`, should get a per-file manifest of hashes instead of a full tar: a decision for the planner, flagged because tarring about 5 GB into the backup root may be undesirable).

Freeze the `<tmp>` enumeration at the start (write the `crosswake*` listing to the evidence folder first) and exclude this phase's own scratch folder by name, otherwise the inventory changes under itself.

### Q8 PR dispositions
`gh pr view` fields for each PR plus a scratch fetch of each `refs/pull/<n>/head` (read-only); `merge-tree --write-tree` of each PR head onto the candidate `[VERIFIED]`. All seven PRs are OPEN and MERGEABLE.

| PR | Head | Changes | Contained in candidate? | Disposition (recommended) |
|----|------|---------|--------------------------|---------------------------|
| 238 "Maintain release guides and assertion references" | 3e8a4b26 (base `main`) | 8 files: README, 2 docs, assertion ledger and remediation json, 3 tests (net about +160/-30 lines) | No. The candidate does not carry these edits: 7 files are unchanged in the candidate relative to the PR base, and the ledger json is edited by both; the PR merges onto the candidate with no conflict (exit 0), result tree differs from the candidate's tree | Redo after landing (D-12 rule: not contained). The ledger json needs a content review at redo time since both sides edit it |
| 236 "chore: release main" | 03ff058a (3 behind `main`) | 11 files, version bump 0.2.11 -> 0.2.12 in manifest, `mix.exs`, README, example manifests, android build files | Candidate leaves these files untouched; merges cleanly | Hold (D-13). Landing 90 commits changes what release-please computes (new commits and changelog); its contents will be regenerated rather than merged as-is. Record "no release in v27" |
| 210 checkout 7.0.0 -> 7.0.1 | e094d4f9 (3 behind) | 16 workflow files | Candidate pins equal `main`'s pins; PR files untouched in candidate | Redo after landing; note that `main` already carries the 7.0.1 commit id in many places (45 uses of `3d3c42e5...` commented `v7`), so a rebase will shrink or empty it: check before recreating, close if empty |
| 211 setup-beam 1.24.0 -> 1.24.1 | 9a1126e5 (3 behind) | 9 workflow files | Candidate pins equal `main`'s (27 uses at 1.24.0, 10 already at the 1.24.1 commit id) | Redo after landing; same shrink check |
| 239 setup-node 7.0.0 -> 7.1.0 | 8deefad4 (current base) | 3 workflow files | Candidate pins equal `main`'s (14 at the `v7` pin, 2 at `v7.0.0`) | Redo after landing |
| 240 upload-artifact 7.0.1 -> 7.0.2 | 525137ba | 8 workflow files | Candidate pins equal `main`'s (17 uses of `v7.0.1`) | Redo after landing |
| 241 download-artifact 8.0.1 -> 8.0.2 | 80f57f6f | 1 workflow file | Candidate pins equal `main`'s (2 uses of `v8`) | Redo after landing |

None of the five dependabot PRs is superseded by the candidate (candidate workflow files and pins equal `main` for every action involved; the candidate's workflow changes are in other files). The 5 PRs touch `crosswake-ci.yml` in many places; a rebase conflict is possible only if Phase 190 edits the same lines (not checked).

## Architecture Patterns

### Evidence flow
```
GitHub main (fresh bare clone, scratch)  --+
candidate (<tmp> clone, read-only)  -------+--> scratch comparison repo
recovery checkout (read-only git only) ----+     (objects fetched IN, never out)
<tmp> Crosswake items (read-only git/ls) --+              |
                                                          v
                     classify (D-05/D-06) --> inventory table + evidence files
                                                          |
   scratch mirror of recovery --> bundle --all --> <backup-root>
   file lists (porcelain -uall) --> tar + diff HEAD patch --> <backup-root>
   stash commit ids --> update-ref in scratch mirror --> in the same bundle + patches
                                                          |
   <backup-root> artifacts --> restore into scratch --> exact-match compare
                                                          |
   sha256 manifest in <backup-root> --> shasum -c --> PASS/FAIL per artifact
   frozen snapshot before and after --> diff --> must be identical
   privacy scan (non-empty scope, zero hits) --> phase folder files only
```

### Recommended layout (Q11)
- Run folder (scripts, scratch, raw output): `<tmp>/crosswake-phase189-run`, matching the Phase 180/188 precedent. Because it matches the `crosswake*` glob, freeze the enumeration before creating it and list it as "this phase's own scratch, excluded".
- Backups: `<backup-root>/inventory-189/` subfolder (new), keeping the two existing candidate bundles untouched at the top level. Files: `refs-all.bundle` (recovery all-refs plus the 4 stash-backup refs), `stash-<n>.patch` (4), `uncommitted-recovery.tar`, `uncommitted-recovery-diff-HEAD.patch`, `worktree-<name>.tar` and `.patch` (2), `tmp-<name>.bundle` / `.tar` for items with unique content, `candidate-connected.bundle` (optional, see Q2), `SHA256SUMS`, and `RESTORE-RESULTS.txt` (placeholders only).
- Phase folder (git-tracked later via the planning carry): `189-INVENTORY.md` (the one table), `189-EVIDENCE/` (privacy-scanned raw output), `scripts/` (byte copies with `189-SCRIPTS.sha256`), `189-SNAPSHOT-BEFORE.txt` and `189-SNAPSHOT-AFTER.txt`, `189-PR-DISPOSITIONS.md` (may be a section of the inventory).
- Never write absolute paths into any file under the phase folder; the scripts take the real paths from environment variables set in the run shell.

## Don't Hand-Roll

| Problem | Don't build | Use instead | Why |
|---------|-------------|-------------|-----|
| "Is this commit already on main?" | name or date heuristics | `git cherry`, ancestor check, `merge-tree --write-tree` result-tree equality | content-based per D-05; squash merges defeat date/name logic |
| Capture reflog-only stashes | custom reflog parsing | scratch `clone --mirror` + `update-ref` + `bundle --all` | verified to reproduce ids exactly |
| Archive integrity | ad hoc "tar t succeeded" | `shasum -a 256 -c` manifest plus extract-and-compare | absence of error is not a pass (AGENTS.md) |
| Privacy scan | new grep | copy of the Phase 188 `scan-privacy-188.sh` plus the two additions below | already fails on empty list/missing list |
| Frozen-state proof | `git status` eyeballing | the snapshot script below | deterministic digests |

## Frozen-state snapshot (Q9, D-15)

Exact read-only command set `[VERIFIED: script run three times, digests identical, index mtime unchanged]`. Every git call uses `--no-optional-locks` (and `GIT_OPTIONAL_LOCKS=0`), which suppresses the opportunistic index refresh that a plain `git status` performs:

```bash
g() { GIT_OPTIONAL_LOCKS=0 git --no-optional-locks -C "$RECOVERY" "$@"; }
g rev-parse HEAD ; g symbolic-ref -q HEAD
g for-each-ref --format='%(objectname) %(refname)' | LC_ALL=C sort | shasum -a 256
g stash list --format='%gd %H %s'            | shasum -a 256   # also record the count (4)
g worktree list --porcelain                  | shasum -a 256
g status --porcelain=v1                      | LC_ALL=C sort | shasum -a 256   # collapsed
g status --porcelain=v1 --untracked-files=all | grep -v -F -e "$PHASE189_UNTRACKED_PREFIX" | LC_ALL=C sort | shasum -a 256
```
Pitfall found while testing: the exclusion must use fixed-string matching (`grep -v -F -e`, prefix value `?? .planning/workstreams/quality-ratchet-release/phases/189-`); a basic-regex `\?\?` does not match on the macOS grep, the filter silently excludes nothing, and the digest then changes as soon as a phase file is added. Assert the excluded-line count is greater than zero in the snapshot output.

Plus per-extra-worktree: HEAD, branch, `status --porcelain=v1 -uall` digest.

Treatment of the phase's own folder (the Q11 interaction):
- Phase-189 files are new untracked files inside the already-untracked `phases/` directory. In default (collapsed) mode that directory is already one entry (`?? .planning/workstreams/quality-ratchet-release/phases/`), so creating or editing files under it does NOT change `status --porcelain`. This digest is the primary D-15 check.
- In expanded mode every new phase-189 file adds a line. Filter out lines for the phase-189 directory by prefix (`?? .planning/workstreams/quality-ratchet-release/phases/189-`), say so in the snapshot header, and keep the filter identical in both snapshots.
- Porcelain v1 shows only status letters, not content. Editing an already-modified file (STATE, ROADMAP, REQUIREMENTS, state.json, handoff notes) does not change it. To prove those did not change by accident, add a content digest over the 78 non-planning dirty paths (`git hash-object` over the file list, no `-w`), and exclude the workstream handoff files that GSD updates during the phase from any content digest (STATE.md, ROADMAP.md, REQUIREMENTS.md, state.json, `.continue-here.md`, MILESTONES.md, the verification ledger), stating the exclusion list in the snapshot header.
- Ordering matters for the backups: the tar of uncommitted work captures files at one moment. Handoff files edited later will drift from the backup, so record each backed-up file's sha256 at tar time and compare the restore against that recorded value (and against the live source only for files not on the volatile list). Decide whether the phase-189 folder is itself backed up (recommended: one small late tar of the finished phase folder, after the "after" snapshot), because it exists only in the frozen checkout.

## Backup plan (INV-02)

1. Enumerate and freeze: `crosswake*` listing under `<tmp>`, the six read-only git listings, porcelain `-z` file lists.
2. Recovery refs: `git clone --mirror --no-hardlinks` into scratch; add refs for the four stash commits; `git bundle create refs-all.bundle --all` from the mirror; record the sorted ref list.
3. Stash exports: for each stash id, a tracked patch (`git show <id>` or `diff <id>^1 <id>`) and the untracked parent's file list plus a tar of its tree (`git archive <id>^3`), all run in the scratch mirror.
4. Uncommitted work: file list from `status --porcelain=v1 -z --untracked-files=all` (read-only), tar with `COPYFILE_DISABLE=1` and an explicit list, a `git diff HEAD --binary` patch (about 1.3 MB for 58 files), a manifest of sha256 and octal mode per file taken from the source in the same run. Include a deletion list (none observed: all 58 tracked changes are modifications).
5. Extra worktrees: one tar plus one `diff HEAD --binary` patch each (11 files total).
6. Other `<tmp>` items: bundle `5923a679` once; tar (or per-file hash manifest for the multi-GB ones) the dirty content of the 178/177 clones; unclassified loose files as one small tar (about 11.6 MB); empty and broken entries recorded as obsolete rows only.
7. Candidate: re-verify the two existing bundles; optionally add the connected bundle.
8. Ignored files: allow-list only (see Q3); never the local environment file.
9. Manifest: `SHA256SUMS` over every artifact in `inventory-189/` and the two existing candidate bundles.

## Restore tests (D-10, exact match only)

| Artifact | Restore | Pass condition |
|----------|---------|----------------|
| `refs-all.bundle` | `git bundle verify` inside a scratch repo; `clone --mirror` from the bundle | sorted `for-each-ref` (objectname + refname) equals the recorded list (174 refs) plus 4 stash-backup refs; recovery HEAD commit and its tree id match the source; each stash commit and its third-parent tree id match |
| Stash patches | `git apply --check` on a scratch checkout of the stash base, then apply | resulting tree id equals the stash commit's tree id; untracked tar file hashes equal the source's third-parent blob ids |
| Uncommitted tar | extract into scratch | file count equals list count (740 minus excluded phase-189 entries); every file's sha256 equals the manifest value taken at tar time; modes equal; no `._*` entries; no symlinks |
| `diff HEAD` patch | scratch checkout of `d0f3e2f1` from the restored bundle, `git apply` | each of the 58 files hashes equal to the source file hashes |
| Worktree tar/patch | same as above, base = that worktree's HEAD | same |
| Other bundles | `bundle verify` + clone | HEAD id equals source HEAD; bounded rev-list count matches |
| Candidate bundles | verify; clone full bundle | HEAD `a53fbef...`, tree `f7c4d7dc...`, `rev-list d0dbdf7..HEAD` = 90; do NOT use `fsck` or an unbounded `rev-list` on the shallow-derived full bundle |
| Manifest | `shasum -a 256 -c SHA256SUMS` in `<backup-root>/inventory-189` | all OK, line count equals artifact count |

Restore is always in a fresh scratch folder, never inside a source repository; delete scratch afterwards only if a later phase permits (deletion in 189 is limited to scratch folders created by this phase).

## Privacy scan (Q10, D-14)

A reusable script exists: `phases/188-freeze-and-twin-05/scripts/scan-privacy-188.sh` (takes one file whose lines are files or directories). Behavior measured with a copy in scratch `[VERIFIED]`:
- Empty list file: prints "scan: empty list", exit 2. Missing list: exit 2. Blank-line-only list: exit 2. Hit: exit 1. Clean: exit 0.
- Classes: a home-directory path shape, the actual home directory string, temp-dir path, uuid-shaped strings, two credential-like words (case-sensitive), the at-sign character anywhere, the OS username as a whole word, a router-module-name shape, and a doctor-key shape.
- Gap 1: a directory entry that contains zero files is accepted: output "files 0, hits 0", exit 0. That is an empty scope passing. A 189 wrapper must additionally require the reported file count to equal the expected count (and be non-zero).
- Gap 2: the git user name and the GitHub owner name are not scanned. Add them as fixed-string checks in a 189 copy (kept as byte copy with a changed filename, not an edit in place). The adopter identity cannot be added as a pattern without recording it; keep the structural rule (no names, links, prices) and review the table by eye for revealing links.
- Consequences for writing the inventory: the at-sign class means stash identifiers must be written `stash-0` ... `stash-3`, never with the reflog notation; the credential-word class means avoiding the two flagged words (see the script's pattern list) and any longer form of them in every phase file, including branch names and PR titles copied into the table; uuid-shaped strings (8-4-4-4-12 hex) must not appear (full 40-hex commit ids are fine); use `<owner>/<repo>` for the GitHub slug; never name the backup root.
- The scan creates its scratch under a `<tmp>/crosswake-scan-188-03.*` directory and removes it on exit. That name matches the Crosswake glob; either enumerate before running it or make the 189 copy use a different scratch prefix (recommended).
- Gate command shape (never piped; capture exit code directly): `sh scan-privacy-189.sh <list-file>; rc=$?` with `rc` 0 required AND the printed "files N" equal to the number of lines in the expected file list.

## Common Pitfalls

1. Plain `git status` refreshes the index. Use `--no-optional-locks` (and `GIT_OPTIONAL_LOCKS=0`) on every call, including inside extra worktrees. Verified: index modification time unchanged after many status calls with the flag.
2. Other "read-only looking" commands write: `git fsck --lost-found` writes `.git/lost-found` (happened in this research), `git gc`, `git prune`, `git count-objects` is safe but `fsck` is not. Allow-list commands in scripts; reject everything else.
3. Fetching FROM the recovery checkout INTO a scratch repo is a read of the source. Fetching INTO the recovery checkout (even `ls-remote`-style updates of its remote refs) is forbidden. `ls-remote <github-url>` is safe.
4. `git bundle verify` needs a repository around it; run it from a scratch bare repo.
5. Bundle of `refs/stash` captures stash 0 only; stashes 1-3 and every untracked third parent are reflog-only. Capture by commit id (verified).
6. Shallow-derived "full" candidate bundle is not connected; do not claim it as a full-history backup, do not run fsck on its restore.
7. Collapsed vs expanded porcelain: 121 vs 740 paths. Tar and patch from the expanded list; count checks must state which mode.
8. macOS tar adds AppleDouble `._*` files unless `COPYFILE_DISABLE=1`; compare modes (octal) and use `-T` with an explicit list; there are no symlinks now, but assert none.
9. zsh does not word-split unquoted variables; run the scripts under `bash` (a shebang plus `bash script`) to avoid silent empty arguments. Several first attempts in this research failed that way.
10. Branch classification by patch-id alone mislabels squash-merged branches as unique; by tree-merge alone mislabels partially-merged ones. Report both columns and classify only when one gives a specific reason.
11. Worktrees: a bundle does not include worktree-local HEAD or index; the dirty files need the separate tar. Worktree-local `git status` also needs `--no-optional-locks`.
12. The scan flags at-signs and two credential words; a table row such as a stash reference or a mirror-related phrase will fail the zero-hit gate. Write sanitized identifiers.
13. Large unrelated directories (`.build`, `_build`, `deps`, `node_modules`, `tmp`) are ignored files, not in porcelain; a tar built from `git ls-files --others` without `--exclude-standard` would balloon to GB. Build the list from porcelain only.
14. The phase-189 folder and the workstream handoff files change during the phase; see the snapshot and backup-timing rules above.
15. Never pipe a gating command into `tail` or `head`; capture `$?` immediately.

## Validation Architecture

> `workflow.nyquist_validation` was not read as `false` (key not examined as disabled); treated as enabled.

### Test framework
| Property | Value |
|----------|-------|
| Framework | Plain bash assertion scripts (no new dependency); Phase 188 `selftest-*.sh` shell self-tests are the local precedent |
| Config file | none; scripts live in the phase `scripts/` folder |
| Quick run | `bash scripts/verify-189.sh --quick` (manifest verify plus snapshot compare, under a minute) |
| Full run | `bash scripts/verify-189.sh --full` (adds restore of every artifact and the inventory-count reconciliation) |

### Success criteria to automated check
| Criterion | Check | Exact-match assertion |
|-----------|-------|-----------------------|
| INV inventory complete | recompute counts from sources and compare with table rows | 740 (or the then-current) dirty paths = sum of rows or row groups; 56 branches; 4 stashes; 2 extra worktrees; 20 valid plus 8 broken repo-like entries and every `crosswake*` entry under `<tmp>` listed or group-listed; each row has class in {on main, to land, obsolete, unclassified} and a non-empty reason; zero rows with obsolete lacking a specific reason |
| Fresh main | `ls-remote` equals the SHA recorded in the table | equal, and `main` is a known ancestor or equal of the recorded value |
| Classification reproducible | re-run the bucket script on the recorded lists | bucket counts equal the table (45/33 non-planning, 13/649 planning, 56 branches in 23/7/2/24) |
| Backups restore | restore tests above | every row "pass" requires equality, never "no error" |
| Manifest | `shasum -a 256 -c` | every line OK; number of lines equals the number of backup files |
| Candidate bundles | verify + bounded checks | HEAD, tree id, 90 count |
| PR dispositions | table has exactly the 7 PRs, each with one of {redo after landing, close as superseded, hold} plus a reason | count 7; disposition for 236 equals hold |
| Frozen state | run snapshot before and after, `diff` | zero differences in every digest; before taken before any phase action, after taken last |
| Privacy | scan wrapper | exit 0, files count equals expected non-zero count, zero hits; negative controls: empty list exits non-zero; a planted home-path line in a control file exits non-zero |
| No deletions | listing digest of `<backup-root>` pre-existing files and of all `<tmp>` Crosswake entries (name + size) before and after | pre-existing entries unchanged (only additions in `<backup-root>/inventory-189` and the phase scratch) |

### Sampling
- Per task: manifest verify and the relevant restore.
- Phase gate: full run green, plus before/after snapshot equality, before `/gsd-verify-work`.

### Wave 0 gaps
- [ ] `scripts/snapshot-189.sh` (frozen-state digests, read-only, `bash`).
- [ ] `scripts/classify-189.sh` (bucket counts with scratch comparison repo).
- [ ] `scripts/scan-privacy-189.sh` (copy of the 188 scan with the extra fixed-string checks, a different scratch prefix, and a files-count assertion).
- [ ] `scripts/verify-189.sh` (restore and manifest assertions).
- [ ] Self-test with negative controls for the scan wrapper and for the snapshot diff (a deliberately changed scratch repo must produce a difference).

## Security Domain

No application security surface; the controls are data-handling controls.

| Concern | Control |
|---------|---------|
| Offline-mutation or adopter data appearing in evidence | privacy scan with non-empty-scope assertion; placeholders only; no raw environment file ever copied or hashed |
| Backups outside the repo containing sensitive working files | local only (D-01); the uncommitted tar can hold the same material as the working tree; keep default restrictive file mode (umask 077) on backup artifacts `[ASSUMED]` |
| Accidental write to the frozen checkout | command allow-list, `--no-optional-locks`, before/after snapshot; no `fsck`, `gc`, `prune`, `fetch` into it |
| Accidental GitHub write | read-only `gh` calls only; no comments, closes or pushes |
| Integrity | sha256 manifest and exact-match restore |

## Environment Availability

| Dependency | Required by | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| git | everything | yes | 2.41.0 | none needed |
| gh (authenticated) | PR data, commit existence | yes | present | `git ls-remote` plus `refs/pull/<n>/head` fetch into scratch |
| bsdtar | archives | yes | 3.5.3 | none needed |
| shasum | manifest | yes | system | `openssl dgst -sha256` |
| bash | scripts | yes | system | do not rely on zsh word-splitting |
| Free disk for `<backup-root>` | bundle (about 110 MB), tars (about 15 MB), mirror scratch (about 130 MB) | not measured | n/a | planner should add a free-space precheck; multi-GB `<tmp>` toolchain folders must not be tarred without an explicit decision |

## Assumptions Log

| # | Claim | Section | Risk if wrong |
|---|-------|---------|---------------|
| A1 | Backup artifacts should use restrictive permissions (umask 077) | Security | Low; only affects local readability |
| A2 | The two extra non-regenerable ignored files (local settings/worker logs, one excluded prompt doc) are worth backing up | Q3 | Low; user decides at Phase 193 |
| A3 | Large no-repo `<tmp>` folders (toolchain, index-diagnosis, phase180-run) need a hash manifest only, not a full tar | Q7 | Medium; if the user wants full copies, backup size grows to several GB |
| A4 | Classifying the 30 contained branches as "on main" is acceptable under D-05 using ancestor / patch-equivalence / merge-tree equality | Q5 | Low |
| A5 | `workflow.nyquist_validation` is enabled | Validation | Low |
| A6 | Disk space is sufficient in `<backup-root>` | Environment | Medium; unmeasured |

## Open Questions (RESOLVED)

1. **Remove the `lost-found` directory this research created?**
   - Known: 248 files, created by this research, nothing else changed.
   - Unclear: whether the caller wants an exact reversal now (a write to the frozen checkout) or to leave it until Phase 193.
   - Recommendation: caller decides; if reversed, do it before the "before" snapshot so the record is clean, and note it in the snapshot header.
   - RESOLVED: lost-found stays in place and is counted in both snapshots; it is one inventory row R-LOST-FOUND, class obsolete ("created by Phase 189 research ... remove in Phase 193"); removal happens in Phase 193 (plan 189-05).
2. **Add the connected candidate bundle?** The existing "full" bundle is shallow-bounded. Recommendation: add one (no cost beyond about the pack size); keep existing ones.
   - RESOLVED: yes; candidate-a53fbef-connected.bundle is added in inventory-189 and proven complete; the two existing bundles are reused unchanged (plan 189-07).
3. **Full tar vs hash manifest for the multi-GB `<tmp>` folders** (A3). Recommendation: hash manifest, and tar only small or unique ones.
   - RESOLVED: unclassified `<tmp>` content is tarred minus regenerable build, dependency and toolchain content; every excluded file is listed with sha256, size and reason in a `.excluded` manifest; purely regenerable folders get only the manifest (plans 189-06 and 189-08).
4. **Back up the finished phase-189 folder itself?** It exists only in the frozen checkout. Recommendation: one late tar after the after-snapshot, recorded in the manifest.
   - RESOLVED: yes; one late phase-folder tar after the after-snapshot, restored and listed in SHA256SUMS (plan 189-09).
5. **Branch review depth for the 24 unique-commit branches.** Recommendation: inventory as unclassified (all-refs bundle covers them) and let the user decide before Phase 193; optional cheap size/touch-set columns.
   - RESOLVED: branches with unique commits stay unclassified, are covered by refs-all.bundle, carry a diffstat column, and go on the user's decision list before Phase 193 (plans 189-03 and 189-09).

## Sources

### Primary (measured this session, HIGH)
- Read-only git against the recovery checkout, candidate, `<tmp>` repos; fresh bare clone of GitHub `main`; scratch repos for comparisons and the bundle/restore toy tests.
- `gh pr view`, `gh api` read calls for the seven PRs and commit existence.
- `189-CONTEXT.md`, `v27.0-SCOPE.md`, `AGENTS.md`, Phase 188 scan and freeze scripts (read in full).

### Secondary / Tertiary
- None; no web sources needed.

## Metadata

**Confidence breakdown:** counts and mechanics HIGH (measured); classification of branches and recovery-only code MEDIUM (content-level, not semantic); size and disk estimates MEDIUM.
**Research date:** 2026-10-16
**Valid until:** until any of: GitHub `main` moves, a new `<tmp>` Crosswake folder appears, or any recovery-checkout ref/stash changes; re-run the snapshot to check.
