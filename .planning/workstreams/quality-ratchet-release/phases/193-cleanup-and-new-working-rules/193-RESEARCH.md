# Phase 193: Cleanup and new working rules - Research

**Researched:** 2026-10-23
**Domain:** local git/checkout retirement, backup re-verification, PR landing of planning records, working-rule rewrite, fail-closed final check (bash + git + gh)
**Confidence:** HIGH on live facts and script interfaces (read this session); MEDIUM on the recommended plan split (judgement); the open questions below need a planner decision.
**Mode:** strictly read-only. No git write in `<recovery-checkout>`, nothing deleted or moved, nothing written in `<tmp>` or `<backup-root>`. Scratch work went only to the session scratchpad. Placeholders used throughout: `<home>`, `<tmp>`, `<backup-root>`, `<recovery-checkout>`, `<owner>`.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Governing rules carried forward (do not re-ask)**
- **D-01:** "The backup is the keep" (189 answers). Removing an item means removing its *source* copy after its backup re-verifies. `<backup-root>` is not deleted in v27; it is reviewed at the v28 boundary at the earliest. Restored items are never searched to reidentify the adopter.
- **D-02:** Every merge to `main` uses a merge commit. No squash, rebase-merge, force push or admin bypass (191 D-03, 192 D-04). The 191 privacy scanner runs on the exact head before every push, and the push refuses unless the scan HEAD equals the push HEAD with exit 0 (191 D-22). Each merge waits for a plain-language `allow`/`hold` shown with the PR link and head. The answer binds internally to that head and is void if the head changes (192 D-07). CI red -> fix forward with a new commit, then rescan (192 D-06).
- **D-03:** Until the swap in D-09, the recovery checkout still gets no git write. Phase 193 files are written there only as plain files, and this discussion's own commit step is skipped for that reason. They reach `main` through PR 1 or PR 2.

**Sequence (the whole phase, in order; each step fails closed)**
- **D-04:** The order is fixed:
  1. **Preflight.** Re-verify `<backup-root>`: check the 189 script hashes (`189-SCRIPTS.sha256`), then re-run the 189 manifest and restore checks. Compare the recovery checkout with `189-SNAPSHOT-AFTER.txt` (HEAD, refs, stash list, worktree list, status checksum). An unexpected difference means: back up that difference, then re-verify. The known difference is the plain-file planning records written in 190-193.
  2. **Post-189 backup (D-07).**
  3. **Fresh clone.** Clone `origin/main` to a sibling (`<home>/projects/crosswake-clean-main`). Check that HEAD equals the fetched `main`, the tree is clean and the remote URL is right. Set repo-local `user.email` to the noreply address main already uses.
  4. **PR 1** from the clone (D-11).
  5. **Copy forward and prove** (D-08).
  6. **Swap** (D-09). Then end the session.
  7. **New session in the swapped checkout.** One removal gate (D-12), then removals (D-13).
  8. **Working rules** (D-15..D-18) and **PR 2** (D-11).
  9. **Final check** after PR 2 merges (D-19).
  - **Reversibility:** reversible up to step 7; one-way from the removals (the backup is then the only copy).

**Backups for work made after Phase 189**
- **D-05:** Before anything is removed, these items are confirmed on `main` (fresh fetch, `merge-base --is-ancestor` with the exit code checked directly): the integration clone's `land/v25-v27` (`9f33c071`), `candidate-src` and `carry-trial-3`, and the durable candidate's `candidate` (`2faf15a2`). Ancestry is checked against a freshly fetched `origin/main`, never against a sibling clone's own stale `origin/main` (`d0dbdf7b`).
- **D-06:** `carry-trial` (`28a48db7`) and `carry-trial-2` (`dd3bdf5f`) are NOT on `main`, and no 189 bundle holds them. Every other unmerged local ref in the two sibling clones is in the same situation.
- **D-07:** One new bundle, `<backup-root>/integration-191-trials.bundle`, holds those refs (prefix `^origin/main`) plus `land/v25-v27` and `candidate-src`. It passes `git bundle verify`, a restore into a scratch folder with tip comparison, and a sha256 line appended to a new sums file beside SHA256SUMS. The durable candidate's stray `crosswake-checkpoint-*.bundle` file is mapped to a 189 row or hashed in the same step. No other new backup is made.

**Retiring the checkout (CLEAN-01)**
- **D-08:** **Copy forward from the backups, not from the live old folder.** That proves the backups usable.
  - The local editor and agent settings come from ignored-keep.tar (allowlist only; 189 group 8).
  - The env files come from env-local.tar (mode 0600; 189 group 9).
  - Caches (`deps/`, `_build/`, `node_modules/`, DerivedData) are rebuilt, not copied.
  - The records give counts and pass/fail only, never file names or contents of env files.
  - Proof: hashes and modes match the tar listing; `mix deps.get` and `mix compile --warnings-as-errors` exit 0 (exit codes checked directly, never through a pipe); `git status --porcelain` is empty.
- **D-09:** **Swap by renaming folders, so the path survives.** Claude Code's per-project memory and history are keyed on the absolute path, so a new path would silently lose them.
  - From `<home>/projects`, one script renames `crosswake` to `crosswake-recovery-retired`, then `crosswake-clean-main` to `crosswake`.
  - If the second rename fails, the script renames the first back and verifies.
  - No destructive git command runs on the old repository: no stash drop, `branch -D`, `worktree remove` or `clean`. Stashes, the 56 branches, reflogs and worktree metadata go away when the retired folder is deleted (D-13).
  - **Reversibility:** reversible - two renames back.
- **D-10:** **The session ends after the swap.** The running session's working folder is the one being renamed, so the plan stops at a handoff after the swap. That handoff names the exact next command. Restarting the session is the one unavoidable human action. The new session re-runs the D-08 proof in the swapped checkout and confirms the Claude memory index is visible.

**Landing the records (two PRs)**
- **D-11:** Two PRs from branches off `main`. A third PR just to record "it passed" is not allowed.
  - **PR 1** (`docs/192-post-sync-records`, from the fresh clone). It carries the 192 records written after the sync: the 192 evidence, summaries, VERIFICATION.md and final scan record, plus the updated 191-REVIEW-DISPOSITION.md (192 inputs R-2, D-03). It also carries the Phase 193 CONTEXT and DISCUSSION-LOG. It lands *before* retirement, so the old checkout is never the only copy of them.
    - The carry follows 191's rules: computed by content against `main`; recovery wins for planning paths; home paths redacted as `<home>` (191 D-21); a manifest records both hashes per file.
  - **PR 2** (`chore/193-cleanup-records`, from the swapped checkout). It carries the working-rule changes, the removal ledger, SEED-025, the PR disposition table, 193 summaries and 193-VERIFICATION.md.
  - 193-VERIFICATION.md records the final check as run on PR 2's head. It states plainly that the post-merge rerun is reported in the handoff and kept as a receipt in `<backup-root>`, and that the script reproduces it.
- **D-12:** **One removal gate.** It is a single plain-language `allow`/`hold`, shown in the new session after D-10's proof and before the first deletion. It lists:
  - each item to delete (temp folders, both extra worktrees, the two sibling clones, the retired checkout);
  - the backup re-verify result and the copy-forward result;
  - the counts now versus the 189 snapshot;
  - the statement that `<backup-root>` stays.

  The choice applies only to that displayed list. `hold` stops with nothing deleted. Everything before this gate is reversible and needs no prompt (AGENTS.md: a fresh decision only for a genuinely new irreversible operation). The user never copies hashes.

**Removal (CLEAN-02)**
- **D-13:** Removal is a plain folder delete gated per item. An item is removed only if every check below passes:
  - (a) it has a row in the frozen 189 inventory or in the D-07 record;
  - (b) its backup file exists and its sha256 matches the sums file;
  - (c) for git items, `git bundle verify` passes and every ref tip is in a verified bundle or is an ancestor of the fetched `origin/main`;
  - (d) for a worktree or clone, its dirty paths are in its dirty tar (or it is clean);
  - (e) for a temp folder, its file list is a subset of its tar listing.

  A failed item is kept, with a ledger row "kept: <cause>", and the run continues. The whole run stops only if `<backup-root>` itself fails to verify. A re-run records "already absent" rather than an error.
  - Order: `/private/tmp` crosswake entries -> `../crosswake-accrue-bridge` (its 14 patch-unique commits must be in refs-all.bundle) -> the integration clone -> the durable candidate clone -> `crosswake-recovery-retired` last. The `.claude/worktrees/agent-p78-*` worktree goes with the retired folder.
  - Only Crosswake entries are touched. Other projects' `/private/tmp` folders are never listed or touched (189 D-03).
- **D-14:** What remains, with its reason:
  - `<backup-root>`: the keep, until the v28 review;
  - the swapped `main` checkout;
  - any item a gate check refused, with its cause.

  Nothing else is expected. The ledger is `193-REMOVAL-LEDGER.md`. It uses placeholders only (`<home>`, `<tmp>`, `<backup-root>`, `<recovery-checkout>`) and has columns row id | kind | location | backup + sha256 match | ref check | action | result | reason if kept, plus a header with expected / removed / kept counts. Its generating script lives in `phases/193-*/scripts/` with its own sha256.

**Working rules (CLEAN-04)**
- **D-15:** **AGENTS.md.** Main's AGENTS.md is the base. The durable recovery-only rules land in condensed form with phase names removed:
  - Kept and generalized: the one-use `allow`/`hold` gate. It covers merges to `main`, merging release PR #236, any Hex/Maven/iOS publish, tags and remote branch deletion. Local commits and feature-branch pushes need no gate.
  - Kept: the GSD handoff rule, the plain-language status rule, one active handoff per workstream, and autonomy for local planning, diagnosis, implementation and checks with no per-step prompts.
  - Kept: the irreversible-operation rule (a fresh decision only for a genuinely new irreversible operation; never transfer consumed approval; never retry uncertain delivery; frustration is not permission).
  - Kept: the workflow-credential lesson (a local read with a privileged CLI credential does not prove workflow access).
  - Condensed: "no command eligible" to one sentence; superseded routes retire as not executed; adapters are tested against real dependency output, not invented fixtures.
  - **Dropped:** the Phase 175 standing authorization, the "Lessons from the Phase175 approval loop" header, the "repair-only pushes" clause and the duplicate "explain outcome first" bullet.
- **D-16:** **New "How changes land" section in AGENTS.md:**
  - work in the one `main` checkout, branching from current `origin/main` as `<type>/<topic>` (conventional prefixes that release-please reads);
  - worktrees are allowed for parallel agent runs, never as a home for candidate state under `/tmp`;
  - every change goes through a PR with "Crosswake CI" green on the head;
  - merge commit only;
  - say which commit CI actually ran on (GitHub's synthetic merge commit);
  - run the privacy scan before every push, and rescan after any new commit;
  - when CI is red, fix forward tied to the observed cause;
  - before retrying a write, read and reconcile.
- **D-17:** **Other active guidance.** Only the active sections are rewritten; history stays verbatim (191 D-08).
  - STATE.md: Current Position, Exact Next Action and Operator Next Steps. A "Superseded 2026-10-2x: frozen recovery checkout rules" line goes into the handoff history.
  - ROADMAP.md: "Ordering rules for v27.0" gets a one-line note: "v27.0 only; superseded by AGENTS.md 'How changes land' after Phase 193". It is not rewritten.
  - `.planning/PROJECT.md`: the "Current stage" line (around line 75) that says the recovery checkout stays frozen.
  - No global find-and-replace. Phase evidence and v25/v26 closeout text are left alone. Public guides need no edit; their "frozen" mentions are unrelated.
- **D-18:** **No new enforcement test or CI lane** for the wording. Branch protection already enforces the real contract (required check, no force push, no admin bypass). This follows "promote checks only when they protect a recurring contract" and "measure a check's findings before making it merge-blocking".

**Final check (CLEAN-03)**
- **D-19:** One dependency-free script (`bash`, `git`, `gh`), `phases/193-*/scripts/final-check-193.sh`, with `--self-test`. It asserts:
  - (1) `git status --porcelain` is empty in `<recovery-checkout>` and HEAD equals the fetched `origin/main`;
  - (2) the latest required "Crosswake CI" run on the current `main` SHA concluded success;
  - (3) the count of open PRs from `gh pr list --json` equals the count of rows in the disposition table, and every number matches;
  - (4) a fresh `/private/tmp` listing shows zero `crosswake*` entries, or each remaining one maps to a verified backup row;
  - (5) the ledger has one row per expected item, with the expected count read from the frozen 189 listing plus the D-07 record and asserted > 0.

  It fails closed: if gh fails, or its output is empty or unparseable, the check fails. Zero open PRs passes only when the JSON parsed and gh exited 0. Every check captures into variables and tests exit codes directly; nothing is piped into `tail`. The self-test feeds a dirty tree, red CI, a PR with no disposition, empty gh output, an empty ledger and a leftover temp folder. Each must fail, and a clean fixture must pass. Pattern: the 189/191 phase-scripts and their self-tests.

**PR dispositions and follow-ups**
- **D-20:** Dispositions are recorded only. Phase 193 merges no PR except its own two. Each row cites the head SHA it saw.
  - #236: hold (no release in v27).
  - #238: redo after landing. Its 8 files still differ from `main` and it touches the assertion ledgers that 191/192 changed, so GitHub's MERGEABLE flag is not enough evidence.
  - #239, #240, #241: green; merge only as a separate decision, with a SHA-pin provenance check (main pins actions by SHA).
  - #210: hold; Crosswake CI fails on its head.
  - #211: hold; no Crosswake CI result on its head.
- **D-21:** The Phase 192 review residue becomes **SEED-025 "Phase 192 review residue"**, following SEED-024. It has a "done looks like" for each of:
  - WR-01: the CI failure-tail masking misses some credential shapes. Its trigger is ranked first because it is a credential-leak gap.
  - WR-02: twin owner checks and a nil os_pid.
  - WR-03: Xcode-only tests run nowhere in CI.
  - IN-01 and IN-02.
  - The missing example-host full-suite CI lane (191 D-14).

  One line goes into REQUIREMENTS.md Future Requirements. No code changes in 193.

### Claude's Discretion
- Script names inside `phases/193-*/scripts/`, the ledger header layout, and PR titles and descriptions (plain language, linking the verification).
- Whether D-04 steps 1-3 are one plan or several, provided the order and fail-closed checks hold.
- After the phase: update Claude memory. Replace the stale `project_crosswake_state.md` (v20) with a pointer to the workstream STATE. Trim the stale "UNPUBLISHED v17.0" statements in `project_crosswake_core_first_publish.md`. Re-verify the worktree and dispatch-isolation entries under the new flow. Memory is not a planning record and is not part of the PRs.

### Deferred Ideas (OUT OF SCOPE)
- SEED-025 contents (D-21): WR-01..03, IN-01/02, the example-host CI lane.
- Merging the green Dependabot PRs #239-#241 after a SHA-pin provenance check; investigating #210's CI failure and #211's missing CI.
- Redoing #238 on the current `main` if its doc edits are still wanted.
- A short "How changes land" section in CONTRIBUTING.md for human contributors. CLEAN-04 names only AGENTS.md and STATE.
- Reviewing and possibly deleting `<backup-root>` at the v28 boundary.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CLEAN-01 | After landing, the recovery checkout is retired and replaced by a clean `main` checkout, only after its *to land* work is on `main` and everything else is backed up. | Preflight (section "Preflight reality check"), post-189 backup design, PR 1 delta list, copy-forward gap (workstream runtime files), swap/handoff split, new-session guard. |
| CLEAN-02 | Landed or obsolete stashes, extra worktrees and local branches are removed after backup. Anything that remains has a stated reason. | 189 row/backup-id structure, tmp-entry-map gap for 190-192 run folders, ordering hazard on env files, per-item gate design, ledger. |
| CLEAN-03 | Final check: `main` checkout `git status` clean; `main` CI green; every open PR has a disposition; no `/private/tmp` folder is the only copy of anything. | CI-semantics finding (Crosswake CI runs on `pull_request` only), PR drift table, pre-merge vs post-merge modes, validation architecture. |
| CLEAN-04 | AGENTS.md and the workstream STATE replace the "candidate in `/private/tmp`, frozen recovery checkout" rules with the normal flow: branch from `main`, then open a PR. | Exact anchors in AGENTS.md, STATE.md, ROADMAP.md, PROJECT.md; SEED/REQUIREMENTS anchors. |
</phase_requirements>

## Summary

The decisions are coherent and implementable, but five facts that CONTEXT does not mention change how the plans must be written. (1) The 189 and 191/192 scripts are **not reusable as-is after the removals**: the 189 `lib-189.sh locate` step requires a temp folder that no longer exists, `reconcile-189.sh` and `verify-189.sh --full` need run-folder files that were never kept, and every 192 script (`common-192.sh`) sources `<tmp>/crosswake-phase191-run/env-191.sh` and calls `locate-191.sh`, which needs the durable candidate clone. D-13 deletes all of those. Reuse means: call the standalone tools (`scan-191.sh`, `carry-191.sh`, `privacy-192.sh`, `git-pinned-191.sh`, `manifest-189.sh`/`restore-189.sh` from a hash-checked scratch copy) and fork the 192 push/merge-gate logic into parameterized 193 copies. (2) "Crosswake CI" is triggered only by `pull_request`; there is **no** Crosswake CI run on any `main` SHA, so D-19 check (2) as worded can never pass. It must resolve the PR that produced the `main` tip and read the required check on that PR head. (3) Twelve `<tmp>` entries exist now; only one (`crosswake-phase179-hex`) has a 189 row. Eleven entries created in 190/191 (including two run folders of roughly 555 MB and 282 MB) have no row and no backup, so D-13(a)/(e) would keep all of them and CLEAN-03 (4) would fail. (4) The workstream `config.json` (untracked, not ignored) and `state.json` (tracked in the recovery branch only) are absent from `origin/main`; a fresh clone will not have them, and D-08's copy-forward list omits them. (5) Open-PR facts drifted: every Dependabot head moved, #211 now has a failing Crosswake CI (not "no result"), and #236 and #210 fail the same proof jobs.

Everything else in CONTEXT checks out against live state: `origin/main` is still `d12aed75`, 4 stashes, 56 local branches, 2 extra worktrees (3 listed), 122 uncommitted paths, 12 crosswake `<tmp>` entries, the seven open PRs, `9f33c071`, `2faf15a2` and `carry-trial-3` are ancestors of `origin/main`, and `carry-trial` / `carry-trial-2` are not.

**Primary recommendation:** Split the phase into two execute units separated by the swap (plans 01-04 in the recovery session, plans 05-07 in the swapped checkout), write all new 193 scripts as standalone copies (no `locate`, no `<tmp>` run folder, no durable-candidate dependency), add one explicit decision for the 11 un-inventoried `<tmp>` entries and for the workstream runtime files, and redefine D-19 check (2) as "Crosswake CI success on the head of the PR that produced `main`'s tip".

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Backup re-verification | Local scripts reading `<backup-root>` | - | Pure file hashing and `git bundle` restore into scratch; no network |
| Landing records (PR 1, PR 2) | GitHub (PR, branch protection, required check) | Local scripts (scan, carry, push gate) | The remote enforces CI and merge rules; local scripts only prepare and bind the head |
| Checkout swap | Local OS (folder renames) | Shell script with rollback | Absolute path must survive for Claude memory |
| Removal | Local OS (folder delete) gated per item | Backup verifier | Irreversible; gate on verified backup |
| Working rules | Docs in git (AGENTS.md, STATE, ROADMAP, PROJECT) | - | Prose only (D-18: no enforcement test) |
| Final check | Local script reading git + `gh` | GitHub API | Mixes local state and remote CI/PR state |

## Standard Stack

No external packages are installed in this phase. Everything is bash, git, shasum, tar, gh, jq, gitleaks and the repo's own scripts.

### Core
| Tool | Version (this session) | Purpose | Why Standard |
|------|------------------------|---------|--------------|
| bash | 5.2.37 (zsh 5.9 is the login shell) | Phase scripts | 189/191/192 pattern; scripts are `#!/usr/bin/env bash` or `#!/bin/sh` |
| git | 2.41.0 | All repo operations; `git subtree`-free | Pinned helper `git-pinned-191.sh` exists |
| gh | 2.101.0 | PR/CI reads and the two merges | Used by 192 |
| jq | 1.7.1-apple | JSON parse in `ci-poll-192.sh` | Already a 192 dependency |
| gitleaks | 8.30.1 (exact version is enforced by `scan-191.sh`) | Privacy scan | `scan-191.sh` fails closed on any other version |
| shasum | 6.02 | sha256 manifests | `shasum -a 256 -c` is the check form everywhere |
| node | v26.10.0 | `node --test` JS tests only if a gate needs them | Not needed for 193 scripts |
| mix / Erlang | Erlang/OTP 27 present | D-08 proof (`mix deps.get`, `mix compile --warnings-as-errors`) | Network needed for `deps.get` |

[VERIFIED: tool versions printed by `command -v` and `--version` this session]

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Forked 193 push/merge-gate scripts | Parameterizing the 192 scripts in place | 192 scripts are frozen history with recorded hashes in 192 evidence; editing them rewrites evidence. Copy-paste matches the project pattern ("copy-paste over a shared dependency"). |
| Re-running `reconcile-189.sh` | `shasum -c` of every sums file plus targeted `restore-189.sh` runs | `reconcile-189.sh` needs files that no longer exist (see Pitfall 2). |

**Package Legitimacy Audit:** No external packages are installed by this phase. Nothing to audit. Packages removed: none. Packages flagged: none.

**Installation:** none.

## Live Facts Re-verified (2026-10-23, read-only)

| Fact (CONTEXT `<specifics>`) | Live result | Drift |
|------------------------------|-------------|-------|
| `origin/main` = `d12aed75` | `git ls-remote origin refs/heads/main` -> `d12aed7567b6bddc6800806e4269e0e87bcd4aac`; the local remote-tracking ref is identical (fetched during 192) | none |
| 122 uncommitted paths | `git status --porcelain` -> 122 lines | none |
| 4 stashes | 4 | none |
| 56 local branches | 56 | none |
| 2 extra worktrees | `git worktree list` shows 3 entries (main + `<home>/projects/crosswake-accrue-bridge` + `.claude/worktrees/agent-p78-*`) | none |
| 12 `crosswake*` entries in `<tmp>` | 12: `crosswake-191-locate.out`, `crosswake-phase179-hex`, `crosswake-phase190-run`, `crosswake-phase191-run`, `crosswake-plan02-190.*`, `-plan04-190.*`, `-plan07-190.*`, five `-plan10-190.*` | none |
| Siblings | `crosswake-accrue-bridge`, `crosswake-candidate-backup`, `crosswake-candidate-durable`, `crosswake-integration-191` | none. `crosswake-accrue-bridge` is a **linked worktree of the recovery repo** (shares its `.git`: 56 branches, 4 stashes listed from it), not a separate clone. |
| Open PRs #210, #211, #236, #238, #239, #240, #241 | same seven | **head SHAs and CI moved** (table below) |
| `HEAD` of recovery | `d0f3e2f1` (matches `189-SNAPSHOT-AFTER.txt`) | none |
| Total refs | 192 now vs `refs_count: 174` in the after-snapshot | **+18**: 17 tags and `refs/remotes/origin/main`/`origin/HEAD`/`pr/238` fetched during 191/192. All are remote-published, so no unique content. The preflight must classify them (published on the remote), not back them up. |

**D-05/D-06 ancestry (checked in the recovery repo's object store against its up-to-date `origin/main`):** `9f33c071`, `2faf15a2` and `carry-trial-3` (`0dff1f22`, ancestor of `land/v25-v27`) are ancestors of `origin/main` (`merge-base --is-ancestor` rc 0 each). `28a48db7` and `dd3bdf5f` are **not even present** in the recovery object store, confirming they exist only in `crosswake-integration-191`. [VERIFIED: git commands this session]

Sibling clone state: `crosswake-integration-191` HEAD `9f33c071` on `land/v25-v27`, clean, 6 local branches (`candidate-src`, `carry-trial`, `carry-trial-2`, `carry-trial-3`, `land/v25-v27`, `main`=`d0dbdf7b`), 0 stashes. `crosswake-candidate-durable` HEAD `2faf15a2` on `candidate`, clean, 2 branches (`candidate`, `main`), plus the loose file `crosswake-checkpoint-24c8389.bundle` (complete history, HEAD `24c8389d`). That file's sha256 appears in **no** `SHA256SUMS*` file (grep found nothing), so D-07's "map or hash it" is a real task.

### Open PR drift since 189 / D-20

| PR | Head at 189 | Head now | Crosswake CI now | mergeStateStatus | D-20 text still true? |
|----|-------------|----------|------------------|------------------|-----------------------|
| 236 release | `03ff058a` | `ed81c6e0` | FAILURE (hex-page-proof, proof-requires-example-host, phase130/132/34/41/43/45 proofs) | BLOCKED, 0 behind | hold: yes. Add "CI fails on head". |
| 238 | `3e8a4b26` | `3e8a4b26` (same) | SUCCESS (old run) | BEHIND by 118 commits | redo after landing: yes (8 files, head unchanged) |
| 239 | `8deefad4` | `c064db79` | SUCCESS | CLEAN | yes |
| 240 | `525137ba` | `e26fe524` | SUCCESS | CLEAN | yes |
| 241 | `80f57f6f` | `0e794279` | SUCCESS (plus SKIPPED full-proof) | CLEAN | yes |
| 210 | `e094d4f9` | `b2668e5e` | FAILURE (same 8 proof jobs as #236) | BLOCKED, 0 behind | yes |
| 211 | `9a1126e5` | `79c426f6` | FAILURE (same 8 plus `e2e-proof` CANCELLED) | BLOCKED, 0 behind | **No.** D-20 says "no Crosswake CI result on its head"; a result now exists and it failed. Reword the row. |

Observation for the disposition reasons (not a decision): #210, #211 and #236 are 0 commits behind `main` and fail the same proof jobs while #239-#241 (also current) pass, so the cause is probably tied to what those three PRs change (action pins / release content), not to `main`. The failure cause was not read; do not state one in the table. [VERIFIED: `gh pr list`/`gh pr view`/`gh api compare` this session]

Because Dependabot rebases heads, the table must record "head seen" per row and the final check must compare **PR numbers**, with head drift reported as information only (otherwise the check is flaky for a reason unrelated to the phase).

## Preflight reality check (D-04 step 1)

What can and cannot be re-run, from reading the scripts:

| Check | Re-runnable now? | How |
|-------|------------------|-----|
| 189 script hashes | **Yes** | From the 189 phase folder: `shasum -a 256 -c 189-SCRIPTS.sha256` -> rc 0 today (22 lines, names are `scripts/<name>.sh`). `[VERIFIED]` |
| All backup sums | **Yes** | In `<backup-root>/inventory-189/`: `shasum -a 256 -c <file>` for `SHA256SUMS` (167 lines), `SHA256SUMS.02` (2), `.03` (8), `.04` (13), `.05` (5), `.06` (1), `.07` (3), `.08` (123), `.11` (2), `.13` (7), `.cr01` (2): all rc 0 today. `SHA256SUMS.13.run1` is a retained blocked-run file; skip it or treat as informational. |
| `env-local.tar`/`.files` mode | **Yes** | Both are mode 600 today. |
| `lib-189.sh locate` (writes `env-189.sh`) | **No** | `_locate` requires `<tmp>/crosswake-phase180-impl` to exist (hardcoded `cand=`); that folder is gone, so it exits 1 "candidate missing". It also writes `env-189.sh` **into the scripts folder** (`RUNS=$_LIB_DIR`), which would dirty the tree (`env-189.sh` is not gitignored: `git check-ignore` rc 1). |
| `manifest-189.sh` | Writes, not checks | `manifest-189.sh NAME FILE...` generates `$MANIFEST_OUT/NAME` with `sha256  name` lines (names relative to the output folder; `../x` allowed). It sources `env-189.sh` from its own folder. "Re-run the manifest" can only mean `shasum -c`, or generating the new D-07 sums file. |
| `restore-189.sh ARTIFACT KIND EXPECTFILE` | **Yes, with a hand-written env and a scratch copy** | See interface below. Needs `RESTORE_PLAN=NN`; honours `RESTORE_RUNS` and `RESTORE_OUT`. Expectation files exist on disk for: bundle (`refs-all.reflist`, `tmp-commits.expect`), tarfiles (`<name>.files`, lines `sha mode path`; first line `sensitive` for env), headpatch (`worktree-*.expect`). The **stash** kind needs a 4-line expectation (id, tree, parent, untracked lines) that only lived in the lost registry; it is not needed for D-13 because the stashes are inside `refs-all.bundle`. |
| `reconcile-189.sh` | **No** | Reads `$RUNS/tmp-gitdirs.tsv`, `$RUNS/restore-registry-0[2-8].tsv`, `$RUNS/tmp-tips.tsv` (run-folder files not in the repo or backup), and hardcodes counts (78 non-planning rows, 248 lost-found, 7 PR rows, 4 stashes). Its result is already recorded in `189-EVIDENCE/reconcile.txt` and `reconcile-11.txt`. |
| `verify-189.sh --quick` | **No (by design fails)** | Compares a fresh snapshot to `189-SNAPSHOT-BEFORE.txt`, which differs on purpose now. |
| `verify-189.sh --full` | **No** | Loops `$RUNS/restore-registry-NN.tsv`; with none it prints "FAIL no registered restores". |
| Compare to `189-SNAPSHOT-AFTER.txt` | **Partly** | HEAD, stash count, worktree count match. `refs_count` differs by +18 (explained above). The status digest cannot match: planning files changed in 190-193. `snapshot-189.sh` itself needs `env-189.sh`. |

**Recommended preflight implementation:** a new standalone `preflight-193.sh` that (1) checks the 189 script hashes, (2) runs `shasum -c` for every sums file with an expected-line-count table, (3) copies `189-*/scripts/` to a scratch folder outside the repo and outside `crosswake*` (for example a `mktemp -d` under the per-user `$TMPDIR`, not `<tmp>`), re-checks the copy against `189-SCRIPTS.sha256` there, writes a hand-made `env-189.sh` (`REC`, `BR`, `OUT`, `CAND`, `RUNS`, `PD`, `PARENT`, `ORIGIN_URL`, all `export`ed; `CAND` can point at the scratch folder because only `verify-candidate-189.sh` uses it), and then runs `restore-189.sh` for the artifacts that the D-13 gates depend on (below), (4) diffs ref names/ids of the recovery repo against `refs-all.reflist` and classifies every extra ref as "published on the remote" (ancestor of, or equal to, a fetched remote ref) or "unexpected -> back it up first", (5) compares HEAD, stash ids (`stash_0..3` in the after-snapshot), worktree heads.

Artifacts to restore-verify (kinds): `refs-all.bundle` (bundle, expect `refs-all.reflist`), `tmp-commits.bundle` (bundle, `tmp-commits.expect`), `ignored-keep.tar` and `env-local.tar` (tarfiles, `.files`), every tar that a D-13(e) gate relies on (`tmp-*.tar`, `worktree-*.tar`; 59 tarfiles in `restore-08.tsv`), headpatch for the two worktrees. `189-EVIDENCE/restore-NN.tsv` lists artifact | kind | result | detail (60 rows in `-08`, 6 in `-04`, 3 in `-07`, 2 in `-05`, 4 stash in `-03`, 1 bundle in `-02`).

### 189 script interfaces (exact)

- **`189-SCRIPTS.sha256`**: 22 lines, format `<64-hex>  scripts/<name>` (two spaces). Verified with `shasum -a 256 -c 189-SCRIPTS.sha256` run from the 189 phase folder. The 22 files are `assemble-inventory, backup-dirty, backup-env, backup-ignored, backup-refs, backup-tmp, classify-dirty/reflog/refs/stash/tmp, export-stash, lib, manifest, prs, reconcile, restore, scan-privacy, selftest, snapshot, verify, verify-candidate` (all `-189.sh`). [VERIFIED: file read]
- **`lib-189.sh`**: sourced library. Run `bash lib-189.sh locate` once to write `env-189.sh` (exits 1 on failure, 2 on bad usage). Provides `gr REPO VERB ARGS` (read-only git allowlist: rev-parse, symbolic-ref, for-each-ref, log, rev-list, cherry, show, cat-file, ls-tree, ls-files, merge-base, diff, status with `--porcelain`, hash-object without `-w`, `stash list|show`, `worktree list`, `config --get`, `remote get-url`; anything else exits 3), `gs DIR VERB` (any verb except push/send-pack/receive-pack/worktree/submodule/clone, but DIR must be under `$RUNS` or a `<tmp>/cw189-selftest.*` fixture), `gclone SRC DST OPTS` (same confinement), `ghr` (gh reads: `pr view`, `pr list`, `repo view`, `api`; write flags refused), `ph` and `san` (placeholder and identity sanitisers; `san` needs `ORIGIN_URL` and `git user.name`), `regen_check PATH`. It builds an at-sign from an octal escape (project rule: no literal at-sign in 189 scripts).
- **`manifest-189.sh NAME FILE...`**: `. $HERE/env-189.sh`; writes `${MANIFEST_OUT:-$OUT}/NAME`; refuses fewer than 2 args (exit 2), bad NAME (exit 2), missing output folder or file (exit 1); prints `manifest NAME: N lines`; exit 0.
- **`restore-189.sh ARTIFACT KIND EXPECTFILE`**: needs `RESTORE_PLAN=NN`; absolute ARTIFACT or one relative to `${RESTORE_OUT:-$OUT}`; scratch under `${RESTORE_RUNS:-$RUNS}/restore/<name>.XXXXXX`; prints `restore <name>: pass` (exit 0) or `restore <name>: fail <closed-word reason>` (exit 1), usage error exit 3; sensitive tars are deleted after the check. **Kind `bundle` runs `git bundle verify` in an empty bare repo**, so it only passes for bundles with complete history (see D-07 pitfall). Also appends/replaces a line in `restore-registry-NN.tsv` in the runs folder.
- **`reconcile-189.sh`**: `check <name>: ok|FAIL <detail>` per check, last line `reconcile-189: ok|FAIL`, exit 0 / 1 / 3. Not re-runnable (above).
- **Self-test:** `selftest-189.sh` (313 lines); fixtures under `<tmp>/cw189-selftest.*`.

### 189 inventory row and backup-id structure

`189-INVENTORY.md`: a markdown table with 9 cells per row: `| ID | Item | Location | Kind | Count | Class | Reason | Backup | Restore |` (awk cells 2..10). Rows start `| R-` or `| C-`; 259 rows plus 7 PR rows (`| <number> |`). Class is one of `on main`, `to land`, `obsolete`, `unclassified`. ID families and counts: `R-BR-001..056` (56), `R-STASH-0..3` (4), `R-REFLOG-MAIN|CAND|OTHER` (3), `R-REFS-REMOTES|TAGS|GSD|TMP|STASH` (5), `R-WT-1` (agent-p78 worktree) and `R-WT-2` (accrue-bridge worktree), `R-ENV`, `R-IGN-REGEN-*` (6 regenerable) and `R-IGN-KEEP`, `R-LOST-FOUND` (248, "remove in Phase 193"), `R-NP-*` (78), `R-PL-*` (46), `R-TMP-*` (55), `C-CAND`. Row ids that matter for gates:

- Backup column names the artifact (for example `refs-all.bundle (refs/reflog-backup/*)`, `worktree-agent-p78.tar + worktree-agent-p78.patch`, `env-local.tar (restricted archive, mode 0600)`, `ignored-keep.tar`); the Restore column says `<artifact>: pass (restore-NN.tsv)`.
- `189-EVIDENCE/tmp-entry-map.tsv`: `<tmp-entry-name>\t<row id>` for the 159 entries present at 189 time (row ids `R-TMP-001..055` or `R-TMP-LOOSE-KEEP`). **This is the mapping D-13(a) should use for `<tmp>` entries.** `tmp-listing-before.txt` is the same entries with a `count 159` header. `tmp-repos.tsv` has per-repo columns (head, shallow, refs, stash, unique commits, dirty, class, captured refs).
- `R-LOST-FOUND` (the `.git/lost-found` folder, 248 objects) and the regenerable `R-IGN-REGEN-*` rows say "none needed"; they leave with the retired folder and need no backup check.

### SHA256SUMS layout

`<backup-root>/inventory-189/` holds 177 entries: 73 `.tar`, 69 `.files`, 7 `.patch`, 4 `.expect`, 3 `.bundle` (`refs-all`, `tmp-commits`, `candidate-a53fbef-connected`), 3 `.tsv`, 3 `.excluded`, plus `refs-all.reflist`, `RESTORE-RESULTS.txt` and the sums files. Sums files are standard `shasum -a 256` output, two spaces, names **relative to `inventory-189/`** (`../candidate-a53fbef.bundle` style names are allowed for the two bundles that sit in `<backup-root>/` itself: `candidate-a53fbef.bundle`, `candidate-a53fbef-full.bundle`). The per-plan files `SHA256SUMS.02..08` match the glob `SHA256SUMS.[0-9][0-9]` that `verify-189.sh --quick` loops; **`SHA256SUMS.193` (three digits) would not match that glob**, which is a feature: the new D-07 sums file will not disturb any 189 script. Recommended: `<backup-root>/inventory-189/SHA256SUMS.193` with names such as `../integration-191-trials.bundle`, generated with `manifest-189.sh` (`MANIFEST_OUT` override) or an equivalent two-line `shasum` call, and verified with `(cd inventory-189 && shasum -a 256 -c SHA256SUMS.193)` plus an expected-line-count assertion (an empty sums file passes `shasum -c`; the 189 scripts guard this with `total > 0`).

### Which post-189 `<tmp>` entries have no row (gap)

The 12 current entries versus the 189 map: only `crosswake-phase179-hex` is mapped (`R-TMP-038`; backup `tmp-crosswake-phase179-hex.tar` + `.files`; 29 files; not a repo). The other 11 were created in Phases 190-191 (`crosswake-phase190-run` 282 MB, `crosswake-phase191-run` 555 MB with 485 top-level entries including `p192/`, `cut*.d`, `dryrun.d`, `sync.d`, `fin-*`, CI json, and the transient `env-191.sh`; one-file `crosswake-plan*-190.*` folders; `crosswake-191-locate.out`, 11 bytes). They have **no 189 row, no tar, no sums**. Under D-13(a)+(e) every one would be "kept: no inventory row", and D-19 check (4) would then require each remaining one to "map to a verified backup row", which does not exist. See Open Question OQ-1.

## Architecture Patterns

### System Architecture Diagram

```
 SESSION 1 (recovery checkout, plain-file writes only, no git write)
 ┌──────────────────────────────────────────────────────────────────────────┐
 │ 193-01 scripts + selftests (phase folder only)                           │
 │ 193-02 preflight ──> post-189 backup (bundle + tmp-run tar + sums)       │
 │            │              │                                              │
 │            ▼              ▼                                              │
 │      verify <backup-root>/inventory-189 (shasum -c, restore matrix)      │
 │ 193-03 fresh clone of origin/main ──> carry manifest (recovery vs clone) │
 │        ──> apply on branch docs/192-post-sync-records ──> scan-191.sh    │
 │        ──> push (feature branch, no gate) ──> PR 1 ──> CI on PR head     │
 │        ──> GATE A: allow/hold merge PR 1 ──> merge commit ──> refetch    │
 │ 193-04 copy-forward from backups (settings, env, workstream runtime)     │
 │        ──> proof (hashes/modes, mix deps.get, compile -Werror, status)   │
 │        ──> swap script (2 renames, rollback) ──> HANDOFF ──> SESSION ENDS│
 └──────────────────────────────────────────────────────────────────────────┘
                              (human: restart session)
 SESSION 2 (swapped checkout at the original path)
 ┌──────────────────────────────────────────────────────────────────────────┐
 │ 193-05 guard (right folder? HEAD==origin/main? retired folder present?)  │
 │        ──> re-prove D-08 ──> late-record sweep (retired -> working tree) │
 │        ──> GATE B: allow/hold removal list ──> per-item D-13 gates       │
 │        ──> removals (tmp, accrue-bridge, integration, durable, retired)  │
 │        ──> 193-REMOVAL-LEDGER.md                                         │
 │ 193-06 working rules: AGENTS.md, STATE, ROADMAP note, PROJECT, SEED-025, │
 │        REQUIREMENTS line, PR disposition table                           │
 │ 193-07 branch chore/193-cleanup-records ──> scan ──> push ──> PR 2       │
 │        ──> final-check-193.sh (pre-merge mode on PR head)                │
 │        ──> GATE C: allow/hold merge PR 2 ──> merge ──> post-merge check  │
 │        ──> receipt copied to <backup-root> ──> memory update (outside PR)│
 └──────────────────────────────────────────────────────────────────────────┘
```

### Recommended Plan Split (session-boundary hazard, item 7)

Make the swap the **last task of the last plan of execute unit 1**, and make the first task of unit 2 a guard. Suggested plans and waves (names are discretionary):

| Plan | Where it runs | Content | Human gate |
|------|---------------|---------|-----------|
| 193-01 | recovery session | All new scripts and self-tests in `phases/193-*/scripts/` plus `193-SCRIPTS.sha256`: `preflight-193.sh`, `backup-post189-193.sh`, `land-gate-193.sh` (fork of the 192 push/merge-gate, parameterized), `copyforward-193.sh`, `swap-193.sh`, `guard-swapped-193.sh`, `remove-193.sh` (ledger generator), `final-check-193.sh`. Run every `--self-test`. | none |
| 193-02 | recovery | Preflight (D-04.1) and post-189 backup (D-04.2, D-05..07). Record `193-POST189-RECORD.md` (new row ids). | none |
| 193-03 | recovery | Fresh clone, carry manifest, scan, push of `docs/192-post-sync-records`, open PR 1, wait for CI | **Gate A** (`checkpoint:decision`): merge PR 1 |
| 193-04 | recovery | Merge PR 1 via gate; refetch; copy-forward into the clone and prove; write the handoff; run `swap-193.sh`; stop. Declare a `checkpoint:human-action` at the end ("restart in the swapped checkout"), so an executor cannot continue. | human action: restart |
| 193-05 | **new session** | Guard; re-prove D-08; late-record sweep; **Gate B**; D-13 removals; ledger | **Gate B** (`checkpoint:decision`): removal list |
| 193-06 | new session | Working rules and SEED-025 and PR disposition table (CLEAN-04, D-20, D-21) | none |
| 193-07 | new session | Branch, scan, push, PR 2, final check (pre-merge), **Gate C**, merge, post-merge final check, receipt, VERIFICATION | **Gate C** (`checkpoint:decision`): merge PR 2 |

Why the guard matters: after the swap, `<home>/projects/crosswake` is the clean clone. A resumed executor must not run unit-2 tasks in the wrong folder. `guard-swapped-193.sh` should assert (each with its exit code tested directly): the toplevel is the expected path, `git rev-parse HEAD` equals the fetched `origin/main`, `<home>/projects/crosswake-recovery-retired` exists (or the "already removed" ledger state), and the working tree is clean apart from the copy-forwarded ignored files.

**Handoff content must travel with the swap.** The swapped checkout contains `main` plus PR 1, so the **Exact Next Action in STATE.md at the PR 1 cut** is what the new session reads. Therefore the STATE.md carried in PR 1 must already say "after the swap, run `<exact command>` in the swapped checkout" (the plans 05-07 are carried by PR 1 too, because the carry bucket `phases/1@(89|90|91|92|93)-*` takes every differing file under phase 193). Records written **after** the PR 1 cut (193-02..04 SUMMARY files, evidence) exist only in the retired folder; `193-05` must run a late-record sweep with `carry-191.sh manifest` (source = the retired folder, base = the new checkout) and apply the delta as plain files to ride PR 2. Add that sweep as a precondition (f) of removing the retired folder: delta against `main` + working tree must be empty or recorded.

The exact next command is a project-level question: AGENTS.md says to name the exact GSD command from the workstream STATE; the executor invocation for a partial phase is not something this research could verify. [ASSUMED] that `$gsd-execute-phase 193 --ws quality-ratchet-release` with a wave argument or plan filter exists; the safe pattern is plan-level `depends_on` plus the `checkpoint:human-action` and the guard, which does not depend on any flag.

### Pattern: standalone phase script with `--self-test`
**What:** one bash script, fixed `label:`-style output, no paths or file contents printed, `umask 077`, exit 0/1/2 (pass / check failed / scope or input error), a `--self-test` that builds throwaway fixtures under a prefix and proves each failure case fails (the 191 scripts print one label per control and exit 0 only when `controls N of N as expected`).
**When to use:** every new 193 script.
**Source:** `scan-191.sh`, `selftest-scan-191.sh` (>= 26 controls), `selftest-carry-191.sh`, `privacy-192.sh`.

### Anti-Patterns to Avoid
- **Sourcing `<tmp>/crosswake-phase191-run/env-191.sh` or calling `locate-191.sh` from any 193 script.** Both disappear in D-13. `common-192.sh` line 9 does exactly this.
- **Creating run folders or fixtures named `crosswake*` under `<tmp>` and leaving them.** `scan-191.sh` makes `<tmp>/crosswake-scan-191.XXXXXX` and removes it on exit; the 191/192 self-tests use `<tmp>/crosswake-selftest-*`. A killed run leaves a `crosswake*` entry that D-19 check (4) will see. Give 193 scratch a non-`crosswake` prefix and run check (4) after the last self-test.
- **Piping a check into `tail`/`head`** (project rule; D-19 already says so). Capture into a variable, test `$?`.
- **Treating an empty `shasum -c` input as pass.** Assert the line count.
- **Writing `env-189.sh` into the 189 scripts folder** in the clean clone (dirties the tree).

## Reusable-script interfaces (items 2)

### 191 scripts (`phases/191-*/scripts/`)

| Script | Usage | Output / exit | Env / hardcodes | Reusable after D-13? |
|--------|-------|---------------|-----------------|----------------------|
| `scan-191.sh` | `scan-191.sh REPO BASE HEAD [PRESERVED_HEAD]` or `--term-check` | `scan:` labels only; exit 0 clean, 1 hits, 2 scope/tool error | Requires gitleaks exactly `8.30.1` and no `.gitleaks*` file in the repo; scratch `<tmp>/crosswake-scan-191.XXXXXX` (self-removing); reads triage file `../191-EVIDENCE/scan-triage-191.tsv` relative to the script (so the **clone must contain 191**, which it does); adopter-term check runs only if `CROSSWAKE_PRIVATE_ADOPTER_TERMS` is set, otherwise `SCAN191_ADOPTER_SKIP=A-14` records `adopter_check skipped_by_user A-14` | **Yes, standalone.** Pass `SCAN191_ADOPTER_SKIP=A-14` the way `finalize-191.sh` does (that is the standing user decision; `denylist-pointer` does not exist in the 191 run folder today, so no denylist is available). Omit the 4th argument for 193 (it was the candidate head in 191). |
| `terms-191.sh` | source after setting `DENY` | exports `CROSSWAKE_PRIVATE_ADOPTER_TERMS`; refuses a denylist inside the repo or `<tmp>` | `DENY` came from `env-191.sh` | Not needed while A-14 stands |
| `selftest-scan-191.sh [--tracer]` | | exit 0 only if `TOTAL >= 26` controls pass | fixtures `<tmp>/crosswake-selftest-scan-191.*` | Yes, standalone |
| `carry-191.sh` | `manifest [--sync] SRC_TOP BASE_REPO BASE_REV TABLE EXCL OUT`; `apply REPO MANIFEST BUCKET`; `commit-bucket REPO MANIFEST BUCKET MSGFILE`; `verify REPO BASE_REV MANIFEST FLOOR_FILE` | `carry:` labels; exit 0 pass, 1 failed, 2 scope/input (`carry: empty delta` is exit 2 in manifest mode) | Table `carry-table-191.tsv` (bucket patterns; `phases/1@(89|90|91|92|93)-*` is already in the `v27.0` bucket) and exclusions `carry-exclusions-191.tsv` (excludes workstream `config.json`, `state.json`, `milestone.lock`); redacts `<home>`, `<tmp>`, `<user>`, and `$NN` -> `${NN}` for rows marked `dollar` | **Yes, standalone** (`git-pinned-191.sh` only). The `dollar` rows cover 189-06/08/11 PLAN and 191 `*.md`, **not** 192/193 `*.md`; run `manifest` first and add table rows for any 192/193 file that holds a `$NN` pattern (the verify step reports it). |
| `carry-floor-191.sh` | `SRC BASE_REPO BASE_REV EXCL INVENTORY OUTDIR` | `floor.txt`, `floor-n`; exit 0 / 2 | independent count of the delta from path sets | Yes. Note `finalize-191.sh` passes `189-INVENTORY.md` as `INVENTORY`. |
| `selftest-carry-191.sh [--tracer]` | | `selftest-carry: controls N of N as expected` | fixtures `<tmp>/crosswake-selftest-carry-191.*` | Yes |
| `git-pinned-191.sh` | source; defines `g REPO args...` | pinned env and `-c` pins | none | Yes |
| `locate-191.sh`, `ensure-clone-191.sh`, `finalize-191.sh`, `suite-gate-191.sh`, `recovery-tree-191.sh`, `selftest-base-191.sh` | | | Hardcode `<tmp>/crosswake-phase191-run`; `locate` needs the durable candidate clone and a unique backup root with the two candidate bundles | **No** after D-13 |

`finalize-191.sh --check-binding` demonstrates the **scan binding format**: a file with lines `head <sha40>`, `main <sha40>`, `preserved <sha40>`, `scan_exit 0`, `adopter_check ...`, then the `scan:` lines; the push refuses unless `head` equals the clone HEAD, `main` equals the pinned base and `scan_exit 0`. Fork this as `scan-bind-193.sh` that writes a binding with `head`, `base` and `scan_exit`, and a push gate that checks it (D-02 / 191 D-22).

### 192 scripts (`phases/192-*/scripts/`)

| Script | Interface | Hardcoded / env-dependent | Verdict |
|--------|-----------|---------------------------|---------|
| `push-192.sh` | `--dry-run` or `--push` (exactly one argument) | `IC`, `BRANCH`, `MAIN_SHA`, `PUSH_REF=refs/heads/land/v25-v27` from `env-191.sh`; calls `finalize-191.sh --check-binding`; run folder `$R191/p192`; uses `gh auth git-credential` as the helper; a push is one attempt, never repeated; records `push-192.txt` lines (`mode .. head .. main .. remote_before .. remote_after .. result ..`) and refuses on `main moved`, `main not in head`, `not fast-forward`, `remote unreadable`; prints `push:` labels; exit 0/1/2. Local file differs from `origin/main`'s copy (blob `cc3ad82`). | Fork, do not call. Logic worth copying: live `ls-remote` read before and after, ancestry check, `already_delivered` idempotence. |
| `merge-gate-192.sh` | `propose PR` / `answer allow|hold` / `merge` / `status`; exit 0 pass, 1 refused/voided, 2 scope, 3 delivery uncertain | binding file `192-EVIDENCE/binding/merge-binding-192.txt`; `REPO_SLUG`, `CI_CHECK="Crosswake CI"`, `CI_APP=15368` in `common-192.sh` | Fork. The required check is `{context: "Crosswake CI", app_id: 15368}` with `strict: true` (read live: `required_status_checks` -> `{"checks":[{"app_id":15368,"context":"Crosswake CI"}],"strict":true}`). |
| `ci-poll-192.sh` | `required` / `check SHA` / `wait PR SHA MAX_POLLS`; exit 0 / 1 / 2 / 3 pending | reads protection via `gh api repos/<owner>/crosswake/branches/main/protection/required_status_checks`; selects the check run by name + app + head sha, highest id | Fork the selection logic. |
| `postmerge-192.sh` | `baseline tracer|before|after` / `verify [MAX_POLLS]` | package list for Hex/Maven/iOS checks | Not needed for docs-only PRs; optional read of "no release, no tag" |
| `privacy-192.sh FILE...` | exit 0 clean, 1 hits, 2 no input / tool error; `privacy: hit CLASS file K` (K is the 1-based argument index) | self-test hooks refused unless `SELFTEST_192=1` | **Reusable standalone** for PR bodies and the new evidence files. |
| `common-192.sh` | sourced | `. <tmp>/crosswake-phase191-run/env-191.sh` after `locate-191.sh` | **Do not source after D-13.** |
| `selftest-*-192.sh`, `gh-shim-192.sh` | `selftest-push-192.sh` sources `env-191.sh` | | The ci/merge/postmerge/privacy self-tests source `common-192.sh` (privacy does not). They will **fail once the run folder is gone**. The 193 regression gate must therefore not re-run the 192 push/ci/merge self-tests after D-13; run them in 193-01 (before) and record the result, and fork them with the forks. |

Hardcoded phase numbers that matter: `191`/`192` in file names, `PUSH_REF`, `BRANCH=land/v25-v27`, `MAIN_SHA=d0dbdf7b...`, `CAND_HEAD`, `BASE_A53`, `MERGE_BASE` (all in `locate-191.sh`), the exclusion table, and `/private/tmp/crosswake-phase191-run`. A fork needs: repo dir, branch name, expected base SHA read live from `ls-remote` (not pinned), and a run folder outside `crosswake*`.

### Ordering hazards from `<tmp>` env files (item 2)

1. `common-192.sh` / `selftest-push-192.sh` / `finalize-191.sh` / `ensure-clone-191.sh`: need `env-191.sh` and, through `locate-191.sh`, the durable candidate clone and the backup root. Anything in 193 that calls them **after** removal step 1 or 3 fails closed with "locate failed". Mitigation: forks, and do all 191/192-script use before D-13.
2. `scan-191.sh` is safe, but its triage file lives in the repo (`191-EVIDENCE/scan-triage-191.tsv`), which exists in any clone that has Phase 191 merged. Check it is on `main` before relying on it: it is (the 191 records were carried by PR #242); the content differs between recovery and `main` (blob `082034c` on main), so PR 1's carry updates it and the PR 2 scan runs with the updated triage. Fine, but note the order: **PR 1 must merge before the PR 2 scan** so the triage file is the updated one.
3. `denylist-pointer`: absent today. No adopter denylist is in play. If the user later wants the adopter-term check back, `terms-191.sh` needs a `DENY` path that is not in the repo or `<tmp>`; the pointer lived only in `<tmp>/crosswake-phase191-run`. Not blocking.
4. `env-189.sh`: does not exist; creating it in the 189 scripts folder dirties the tree (see preflight).

## PR 1 content (item 4, computed by content against the existing `origin/main` ref)

`origin/main` ref in the recovery repo equals the live remote tip (`d12aed75`), so the comparison is current. Method: for every file under `phases/189-* .. 193-*` and the v27.0-bucket planning files, compare `git hash-object --no-filters <file>` with `git rev-parse origin/main:<path>`. This is a raw-bytes comparison; the real carry compares after the redaction transform, so the `dollar` PLAN files (189-06, 08, 11) show as different here because main holds the redacted copy, and the carry will not list them.

**Planning files that differ (or are absent on main), excluding the transform-only cases:**

- Phase 191 (11 raw differences; the carry will confirm which are real): `191-EVIDENCE/heads-191.txt`, `scan-191.txt`, `scan-triage-191.tsv`, `suite-SYNC.txt`, `suite-root-SYNC.txt`, `191-RESEARCH.md`, `191-REVIEW-DISPOSITION.md` differ from main; `191-EVIDENCE/suite-LAND-FIX.txt` is **absent** on main (the only 191 file local-only). D-11 names only `191-REVIEW-DISPOSITION.md`; the carry will take all of these (it works by content), which is correct (191 D-08: records verbatim). `191-integration-branch-and-local-suite` has 127 local files vs 126 on main.
- Phase 192: local has 93 files, main has 47. **Absent on main (46):** `192-06-SUMMARY.md`, `192-07-SUMMARY.md`, `192-08-SUMMARY.md`, `192-09-SUMMARY.md`, `192-10-SUMMARY.md`, `192-06-BLOCKED.run1.md`, `192-07-BLOCKED.run1.md`, `192-08-BLOCKED.run1..4.md`, `192-10-BLOCKED.run1.md`, `192-REVIEW.md`, `192-REVIEW-DISPOSITION.md`, `192-VERIFICATION.md`, and 32 files under `192-EVIDENCE/` (including `binding/merge-binding-192.txt`, `answer-192.txt`, `merge-192.txt`, `postmerge-192.txt`, `phase-gate-192.txt`, `open-prs-*`, `privacy-07..10-192.txt`, `recovery-after-192.txt`, `selftest-ci-09-192.out`, `selftest-merge-09-192.out`, ...). **Different content:** `192-EVIDENCE/push-192.txt` (blob `7e3ab35` on main) and `scripts/push-192.sh` (blob `cc3ad82` on main). Note `push-192.sh` is a script whose recorded hash may appear in 192 evidence; the carry replaces main's copy with the final one (recovery wins), which is the intended result.
- Phase 193: `193-CONTEXT.md`, `193-DISCUSSION-LOG.md` (plus `193-RESEARCH.md`, plans, `193-VALIDATION.md`, `193-PATTERNS.md` if written before the cut: the bucket pattern is the whole phase, so the carry takes them too. This is a superset of D-11's list. Recommendation: accept it; the alternative is an exclusions row, which adds machinery for no benefit.)
- Phase 189: nothing real (117 of 117 files equal main except the three transform-only PLANs).
- Phase 190: all 58 equal.
- Workstream files that differ from `main`: `STATE.md` (22+/22- lines), `ROADMAP.md` (13+/15-), `REQUIREMENTS.md` (4+/4-), `.continue-here.md` (4+/4-). These carry the 191/192 completion status. **D-11's PR 1 list does not name them but the v27.0 bucket includes them**, and main's copies are stale (main's `.continue-here.md` still says last completed phase 190; ROADMAP progress table says 191 and 192 "Executed, verification pending"). They must ride PR 1 so the swapped checkout's STATE tells the truth. `PROJECT.md`, `RETROSPECTIVE.md`, `WINDOWS.md`, `config.json`, `MILESTONES.md`, `.verification-ledger.json`, `PHASE175-STANDING-AUTHORIZATION.md` are byte-identical to main. All seeds equal main (SEED-020..024 present on main).
- Not carried (A-2 exclusion): workstream `config.json` (untracked in the recovery repo, **not** gitignored, absent on main), `state.json` (tracked in the recovery branch, absent on main, differs by 38 inserted lines), `milestone.lock` (does not exist now).

Do not assume the PR 1 file list is final: records written between this research and the cut (plans, summaries) change it. The planner should make the **carry manifest the source of truth** and assert, with `carry-191.sh verify`, that nothing under the bucket is left out (the 191 `verify` + `carry-floor-191.sh` pair is the independent completeness check). Because the carry compares by content, re-running it after any late edit is cheap and idempotent.

**AGENTS.md is not in the carry table** (and is not a planning path); PR 1 does not touch it. D-15/D-16 edit it in PR 2 from main's copy.

## Exact edit anchors for CLEAN-04 (items 5, 6)

### AGENTS.md
`git diff origin/main -- AGENTS.md` -> 1 file, +41/-5. Hunks:
- `@@ -49,6 +49,9 @@` adds the "For a just-displayed, one-use approval gate, accept a plain-language `allow` or `hold` ..." bullet (3 lines) in "Working Rules". Keep and generalize (D-15).
- `@@ -72,11 +75,20 @@` replaces the 3-line "For the active quality lane, read the current phase ... `$gsd-discuss-phase`" / "Use `$gsd-plan-phase` ... only when discussion is intentionally skipped" bullets with: the GSD handoff bullet, the "no command eligible" bullet, and a longer active-quality-lane bullet. Keep handoff, condense "no command eligible" to one sentence.
- `@@ -92,3 +104,27 @@` appends: the plain-language status bullet (keep), the `## Lessons from the Phase175 approval loop` section (drop header, keep the durable bullets), the `## Standing authorization — quality-ratchet-release Phase175` section (drop entirely), and the final "Before a release merge, check the workflow credential permissions ..." bullet (keep the first sentence pair; drop "Repair-only pushes must remain proposal-only ..." per D-15). Also drop the second "Explain the outcome and next action first ..." duplicate.
- Main's AGENTS.md already lacks all of the above. PR 2 starts from `git show origin/main:AGENTS.md` and adds the condensed rules plus the new `## How changes land` section (D-16).

### STATE.md (workstream)
Active sections to rewrite (D-17): `## Current Position` (line 27: Phase 193 ... "Ready to plan"), `## Exact Next Action` (line 36; the "Phase 193 inputs:" paragraph at about line 44-48 is part of it), `## Operator Next Steps` (line 185). `### Handoff history` begins at line 46 (add the "Superseded 2026-10-2x: frozen recovery checkout rules" line there; leave existing lines verbatim). `## Session` at 179 carries `Stopped at` / `Resume file`. The STATE.md in the recovery checkout will change during planning/execution; re-read the line numbers at edit time.

### ROADMAP.md (workstream)
`### Ordering rules for v27.0` at line 22; the rule bullets run lines 24-29 (the two rules that matter are "The recovery checkout stays frozen through Phase 192" and "The protection on the recovery checkout lifts only in Phase 193 ..."). Add the one-line note `v27.0 only; superseded by AGENTS.md 'How changes land' after Phase 193` directly under the heading (line 23), do not rewrite. Phase 193 detail begins at line 204 (`### Phase 193: Cleanup and new working rules`; `**Plans**: TBD` at about line 220; progress table row `| 193. ... | 0/TBD | Not started | - |`).

### `.planning/PROJECT.md`
Line 75: `**Current stage:** Last completed phase 188. v27.0 Land and Clean Up started 2026-10-16; Phase 189 (Inventory and backup) is next for discussion. The candidate is backed up outside `/private/tmp`; the recovery checkout stays frozen through Phase 192. See [STATE](workstreams/quality-ratchet-release/STATE.md).` It is stale beyond the "frozen" wording (it says Phase 189 is next). Rewrite the whole line to the true stage at PR 2 time (for example "Last completed phase 192; Phase 193 closing; work lands through PRs from `main`"). PROJECT.md is byte-identical to main, so this edit belongs to PR 2.

### REQUIREMENTS.md (workstream)
`## Future Requirements` at line 69 holds two bullets (lines 71-72: Nyquist status of phases 184-188; remaining v26 debt). Add one bullet pointing to SEED-025. CLEAN-01..04 are lines 60-67 (checkboxes `[ ]`); the traceability table rows at lines 102-105 are `Pending`. REQUIREMENTS.md differs from main by 4 lines (checkbox state for LAND-03/04), so PR 1 carries that and PR 2 flips CLEAN-01..04 only after the final check passes.

### SEED-025 format (from SEED-024)
Front matter keys: `id: SEED-024`, `title`, `status: dormant`, `severity: medium`, `trigger_when: >-` (folded multi-line), `created: 2026-10-19`, `related: [SEED-023]`. Body: `# SEED-024: <title>`, a lead paragraph, then `##` sections grouped by trigger (`## Before the next twin run`, `## Before the physical-iPhone run resumes`), each item as `- <ID>: <finding>. Done looks like <observable outcome>.`; then `## Accepted as designed` and `## Source` (links to the review and disposition files and the CONTEXT decision). SEED-025: `id: SEED-025`, `created: 2026-10-23`, `related: [SEED-023, SEED-024]`, WR-01 listed first (credential-leak gap), the other items per D-21. Each item needs a concrete "done looks like". Source: `192-REVIEW.md`, `192-REVIEW-DISPOSITION.md` (the finding text lives there; the planner/executor must read those two files, they were not re-read in this research).

## The D-07 bundle (pitfall found by running it)

D-07 asks for prefix `^origin/main`. Tested read-only in the integration clone, writing the bundle to the session scratchpad and deleting it:

- With `^d0dbdf7b` (that clone's local `main`), `git bundle create` of `carry-trial carry-trial-2 land/v25-v27 candidate-src` succeeds (about 7.9 MB) and lists all four heads, but the bundle then **requires** `d0dbdf7b`. [VERIFIED: command run this session]
- `restore-189.sh` kind `bundle` runs `git bundle verify` against an **empty** bare repo, so it fails for any bundle with a prerequisite. The D-07 "restore into a scratch folder with tip comparison" therefore cannot use the existing script on a prerequisite bundle.
- With `^origin/main` meaning the new tip (`d12aed75`), `land/v25-v27` and `candidate-src` are ancestors and are excluded, and the prerequisite `d12aed75` is not in the integration clone's object store at all, so the command fails or yields a bundle that cannot be verified there.

**Recommendation:** create the bundle with **no negative prefix** (complete history), refs `carry-trial`, `carry-trial-2`, `land/v25-v27`, `candidate-src` (and `carry-trial-3` for symmetry; it is on main and costs nothing). It is self-contained, `restore-189.sh integration-191-trials.bundle bundle <expect>` can verify it with expectation lines `complete-history` + `<sha> refs/heads/<name>` (the format `restore-189.sh` reads: first line `complete-history`, then `objectname refname`, optional `head <commit> <tree>`), and a size around the 14 MB of `candidate-a53fbef-full.bundle` is irrelevant against the 8.6 GB backup root and 459 GiB free. This is a deliberate deviation from the literal "prefix `^origin/main`" in D-07; flag it to the user in the plan summary, not as a new decision (same intent: "holds those refs, verifiable").

RESOLVED: settled by D-23 (bundle built with no negative prefix); implemented in 193-01-PLAN.md Task 2.

## Open Questions (RESOLVED)

All seven questions are settled; each carries a `RESOLVED:` line naming the decision or plan that settles it.

1. **OQ-1: the 11 un-inventoried `<tmp>` entries (the biggest gap).**
   - Known: only `crosswake-phase179-hex` has a row and tar. The other 11 (190/191 run folders and one-file plan folders, one 11-byte output file) have none. D-07 says "no other new backup is made"; D-13(a)/(e) require a row and a tar subset for each; D-19 (4) allows leftovers only if they map to a verified backup row.
   - Unclear: whether the user wants 840 MB of run scratch backed up or accepts "regenerable scratch whose results are already committed in EVIDENCE".
   - Recommendation: extend the D-07 record with rows `R-POST-TMP-NN` and make **one** tar of the run folders' **file lists plus loose non-regenerable files** (exclude `cut*.d`, `dryrun.d`, `sync.d`, `fin-*.d`, `npm10`, `work`, `compare-build`, which are re-derivable trial trees and carry the bulk), written to `<backup-root>/inventory-189/post189-tmp.tar` with `.files` and a `SHA256SUMS.193` line, restore-verified with `restore-189.sh ... tarfiles`. This still needs the user's awareness at Gate B ("listed: 12 temp entries; 11 are covered by the new tar"). The alternative (classify as obsolete with a stated reason and keep no copy) conflicts with CLEAN-03's "no `<tmp>` folder is the only copy". Make the choice explicit in the plan; do not silently add a backup.
   - RESOLVED: settled by D-22 (user choice at plan time): one small tar of file lists plus non-regenerable loose files, rows `R-POST-TMP-NN`, implemented in 193-01-PLAN.md Task 2/3 and listed at Gate B in 193-08-PLAN.md.
2. **OQ-2: workstream runtime files in the fresh clone.**
   - Known: `config.json` and `state.json` for `quality-ratchet-release` are not on `origin/main`; the carry excludes them (A-2); they exist only in the recovery checkout (`config.json` untracked and not ignored). A fresh clone has neither, and D-08 lists only settings and env files for copy-forward.
   - Unclear: whether GSD commands with `--ws quality-ratchet-release` run without them. [ASSUMED] they are needed (the A-2 note calls them "runtime authority files").
   - Recommendation: copy both (and `milestone.lock` if it exists at swap time) forward from the 189 dirty backups or, because they change every session, from the live old folder in a final pre-swap step; add them to the new checkout's `.git/info/exclude` so `git status --porcelain` stays empty honestly, and state this in the ledger. A tracked/untracked policy change is out of scope.
   - RESOLVED: research recommendation adopted; 193-03-PLAN.md (`runtime-backup`) and 193-06-PLAN.md (copy-forward of config.json/state.json/milestone.lock with `.git/info/exclude`).
3. **OQ-3: what "main CI green" means (D-19 check 2).**
   - Known: `crosswake-ci.yml` has `on: pull_request` only [VERIFIED: `.github/workflows/crosswake-ci.yml` lines 6-7 and `origin/main` copy]; `gh run list --workflow "Crosswake CI" --branch main` is empty; the runs on `d12aed75` are Release Please (success), `Cancel Obsolete Crosswake CI` (success) and `See It Run Collateral` (`completed/cancelled`; it was "advisory, still running" when 192 closed). The required check is `Crosswake CI` (app 15368, `strict: true`).
   - Recommendation: define check (2) as: resolve the PR that produced the current `main` tip with `gh api repos/<owner>/crosswake/commits/<main-sha>/pulls`, read the check runs named `Crosswake CI` (app 15368) on **that PR's head SHA** (`9f33c071` for `d12aed75`: `Crosswake CI success app=15368`, verified), require `success`, and **report separately** the main-push workflows (Release Please must be success; `See It Run Collateral` is advisory and is reported, not asserted). Fail closed if the PR lookup returns zero or more than one PR.
   - RESOLVED: settled by D-24 (check 2 = Crosswake CI, app 15368, on the head of the PR that produced main's tip; main-push workflows reported only); implemented in 193-04-PLAN.md `final-check-193.sh`.
4. **OQ-4: pre-merge versus post-merge final check (D-11 / D-19).**
   - Known: 193-VERIFICATION.md is part of PR 2, so the check is first run on PR 2's head, where the checkout is on the PR branch (HEAD != `origin/main`), and PR 2 is itself an open PR.
   - Recommendation: `final-check-193.sh --pre-merge PR_NUMBER` (HEAD must equal the PR head, `origin/main` must be an ancestor, open-PR set == disposition-table rows including a `this PR` row) and `--post-merge` (checkout on `main`, HEAD == fetched `origin/main`, PR 2 merged, open set == the seven disposition rows). Both exit 0 only on full pass; the self-test needs the extra controls "pre-merge with HEAD != PR head fails" and "post-merge with an extra open PR fails".
   - RESOLVED: settled by D-24 (`--pre-merge <PR>` and `--post-merge` modes); implemented in 193-04-PLAN.md and run in 193-10-PLAN.md.
5. **OQ-5: copy-forward allowlist for ignored-keep.tar (D-08).**
   - Known: `ignored-keep.files` holds 46066 entries, of which the agent/editor settings candidates are: `.claude/` top-level (`*.json` 1, `*.lock` 1, `.DS_Store` 1), `.claude/worktrees/*` (7: runtime), `.gsd/` (5 files), `.expert/` (626, a language-server cache), `.planning/research/.cache` (28, gitignored scratch), plus `.build` (35965), `tmp` (4729), `packages`, `deps`, `doc`, `examples`, `crosswake-0.x` folders (regenerable or test output).
   - Recommendation: allowlist = `.claude/*.json` and `.gsd/**` only (settings and agent state); exclude `.claude/worktrees/**`, `*.lock`, `.DS_Store`, `.expert/`, `.planning/research/.cache/`. Encode as an explicit pattern list in the copy script and assert the copied count (to prove a non-empty allowlist, per the "check that passes empty" rule). Do not record file names; counts only.
   - RESOLVED: research recommendation adopted; 193-03-PLAN.md `copyforward-193.sh` allowlist with a non-empty count assertion, applied in 193-06-PLAN.md.
6. **OQ-6: ordering of PR 1 and records written after its cut.** The recovery STATE.md is edited again by every later task. Recommendation: freeze it by making the PR 1 cut the **last** step that writes STATE.md in the recovery checkout, and rely on the late-record sweep in 193-05 for the rest.
   - RESOLVED: research recommendation adopted; 193-05-PLAN.md Task 1 step 1 is the last STATE.md write in the recovery checkout, and the late-record sweep is 193-07-PLAN.md Task 2.
7. **OQ-7: the Dependabot PRs.** Heads change when Dependabot rebases; recommend recording the head seen plus the date, and having the final check compare numbers only (above).
   - RESOLVED: settled by D-24 (open-PR comparison by number; #211 reworded to its observed failing CI); implemented in 193-04-PLAN.md `final-check-193.sh` check 3 and 193-09-PLAN.md Task 3.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Privacy scan of the push | a new grep | `scan-191.sh` (+ `privacy-192.sh` for PR text) | Pinned gitleaks 8.30.1, fixed labels, never prints a value, 26+ self-test controls |
| Computing the planning delta | `rsync`/`diff -r` | `carry-191.sh manifest|apply|verify` + `carry-floor-191.sh` | Handles redaction, `dollar` rows, exclusions, both-hash manifest, independent floor |
| Hash verification | custom loops | `shasum -a 256 -c` with an assertion that the line count equals the expected number | Matches 189; an empty file passes `shasum -c` silently |
| Bundle/tar restore proof | ad-hoc `tar -x` | `restore-189.sh` from a hash-checked scratch copy | Already encodes complete-history, connectivity, mode and sha checks and fails with closed reason words |
| Pinned git environment | raw `git` in scripts | `g()` from `git-pinned-191.sh` | Scrubs `GIT_*`, pins `core.*` |
| Merge gate binding | a chat reply parser | fork of `merge-gate-192.sh` (`propose` / `answer` / `merge` / `status`, binding file with public values only) | One-use, head-bound, void on head change (192 D-07) |
| Branch protection reading | hardcoded check names | read `required_status_checks` live (as `ci-poll-192.sh` does) | The contract is `{Crosswake CI, app 15368, strict}` and may change |

**Key insight:** every one of these tools exists and has a self-test; the risk in 193 is not missing tools, it is **their hidden dependencies on `<tmp>` and on sibling clones**, which D-13 deletes.

## Common Pitfalls

### Pitfall 1: scripts that source a run folder that is deleted by the removal step
**What goes wrong:** PR 2's scan, push, CI poll or final check calls a 191/192 script; `locate-191.sh` fails (durable candidate missing); the phase stalls after the one-way door.
**Why:** `common-192.sh` and 191's `finalize/ensure-clone/suite-gate` hardcode `<tmp>/crosswake-phase191-run/env-191.sh`.
**How to avoid:** 193 scripts are standalone; a static test greps every 193 script for `crosswake-phase191-run`, `locate-191`, `env-191`, `common-192` and fails if present (self-test control).
**Warning signs:** `locate:` or `common: locate failed` labels in a post-gate run.
**Also affected (found at plan check):** `privacy-192.sh` sources `common-192.sh`, which runs `locate-191.sh` (it re-creates `<tmp>/crosswake-phase191-run`) and sources its env file; `scan-191.sh` makes its scratch under `<tmp>/crosswake-scan-191.*`. RESOLVED: 193-02-PLAN.md forks a standalone `privacy-193.sh` (scratch under the session temp folder, private strings from `paths-193.sh`) and runs `scan-191.sh` only from a hash-checked relocated copy whose scratch is under the 193 run folder; every 193 privacy call uses these.

### Pitfall 2: treating 189's `reconcile`/`verify --full` as re-runnable
**What goes wrong:** the preflight reports FAIL for reasons unrelated to the backup (missing registry, changed snapshot) and the planner "fixes" the wrong thing.
**How to avoid:** use the preflight design above; keep `189-EVIDENCE/reconcile*.txt` as the historical result and check the facts it relied on (sums, restores, counts) directly.

### Pitfall 3: `shasum -c` and `tar` can pass while checking nothing
**What goes wrong:** an empty sums file, a truncated `.files` list, or a tar with zero extracted entries passes.
**How to avoid:** assert expected counts (167, 2, 8, 13, 5, 1, 3, 123, 2, 7, 2 lines; `ignored-keep.files` 46066; `env-local.files` 3) and `> 0` for every gate; give each new script a control that feeds an empty input and must fail (project lesson "absence scored as success").

### Pitfall 4: a failed CI judgement that rests on the wrong commit
**What goes wrong:** the final check says "CI green" from a run on a different SHA, or finds no run at all.
**How to avoid:** OQ-3's PR-head resolution; also state in the evidence which commit CI ran on (D-16 asks the rule to be written into AGENTS.md; follow it in the record: the check ran on the PR head, and a `pull_request` run also tests GitHub's synthetic merge commit, which is not the head).

### Pitfall 5: the new checkout is "clean" only because ignore rules hide required files
**What goes wrong:** `git status --porcelain` is empty, but GSD state files, `.claude` settings or env files are missing, or present but hidden by `.git/info/exclude`.
**How to avoid:** the copy-forward proof lists counts of copied files by category (settings, env, workstream runtime), and the final check reports `info/exclude` line count (0 or the three named runtime files), so hiding is visible.

### Pitfall 6: killed runs leave `crosswake*` entries in `<tmp>`
**What goes wrong:** D-19 check (4) fails because of a leftover scratch folder from `scan-191.sh` or a self-test.
**How to avoid:** run the final check after the last self-test; the check lists `<tmp>/crosswake*` itself and the self-test includes "leftover temp folder fails". Give 193 scratch a non-`crosswake` prefix.

### Pitfall 7: Claude Code's per-project state and the running session
**What goes wrong:** the executor keeps working in the renamed folder, or relaunches elsewhere and loses memory/history.
**How to avoid:** D-09 (rename, same absolute path), D-10 (stop, restart), the guard script, and a handoff that names the exact first command. Memory index at `<home>/.claude/projects/<path-key>/` is outside the repo and unaffected by the rename. [ASSUMED: that the key derives only from the absolute path, as CONTEXT states; not tested.]

### Pitfall 8: `crosswake-accrue-bridge` is a worktree
**What goes wrong:** deleting it as a "clone" leaves a dangling worktree record, or a planner expects its own refs.
**How to avoid:** it shares the recovery repo's refs (56 branches, 4 stashes appear in it). Gate on `worktree-accrue-bridge.tar|.patch|.expect` (dirty file count 1; row `R-WT-2`) and on `refs-all.bundle` (its 14 patch-unique commits are `R-BR-005`). Deleting the folder first and the retired checkout last (D-13 order) is fine; the stale worktree record disappears with the retired `.git`.

## Code Examples

### Hash-check with explicit count (pattern, no pipe)
```bash
# Source: phase 189 verify-189.sh (shasum -c with a total > 0 assertion)
total=$(awk 'NF{n++} END{print n+0}' "$sums") || exit 2
[ "$total" -gt 0 ] || { echo "preflight: FAIL empty sums"; exit 1; }
[ "$total" -eq "$expected" ] || { echo "preflight: FAIL line count"; exit 1; }
out=$(cd "$OUT" && shasum -a 256 -c "$sums" 2>&1); rc=$?
oks=$(printf '%s\n' "$out" | grep -c ': OK$')
[ "$rc" -eq 0 ] && [ "$oks" -eq "$total" ] || { echo "preflight: FAIL mismatch"; exit 1; }
```

### Ancestry check with the exit code read directly (D-05)
```bash
# The remote-tracking ref must come from a fresh fetch of the CHECKOUT being tested.
git -C "$CLONE" fetch --no-tags origin refs/heads/main:refs/remotes/origin/main || exit 2
tip=$(git -C "$CLONE" rev-parse refs/remotes/origin/main) || exit 2
[ "$tip" = "$(git ls-remote origin refs/heads/main | awk '{print $1}')" ] || exit 2
git -C "$CLONE" merge-base --is-ancestor "$ref_sha" "$tip"; rc=$?
case $rc in 0) echo "ancestor" ;; 1) echo "not-ancestor" ;; *) exit 2 ;; esac
```
(For a ref held only in a sibling clone, fetch that clone's object into the fresh clone first, for example `git fetch <sibling-path> <ref>:<scratch-ref>`, because `merge-base` needs both objects.)

### The CI-on-main semantics (OQ-3)
```bash
sha=$(git rev-parse HEAD)
pr=$(gh api "repos/$SLUG/commits/$sha/pulls" --jq '[.[] | select(.merged_at != null)] | if length==1 then .[0].number else empty end') || exit 2
[ -n "$pr" ] || { echo "final: FAIL no single merged PR for tip"; exit 1; }
head=$(gh pr view "$pr" --json headRefOid --jq .headRefOid) || exit 2
res=$(gh api "repos/$SLUG/commits/$head/check-runs" --jq '[.check_runs[]|select(.name=="Crosswake CI" and .app.id==15368)]|sort_by(.id)|last|.conclusion') || exit 2
[ "$res" = success ] || { echo "final: FAIL crosswake ci $res"; exit 1; }
```
[VERIFIED: the two `gh api` calls were run against `d12aed75`/`9f33c071` this session and returned PR 242 and `Crosswake CI success app=15368`; the combined snippet itself was not run]

## Runtime State Inventory (cleanup/migration phase)

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | Claude Code per-project memory and history keyed on the absolute checkout path (outside the repo); GSD workstream runtime files `config.json`, `state.json` (not on main) | Keep the path (D-09). Copy the runtime files forward (OQ-2). |
| Live service config | GitHub: branch protection (`Crosswake CI`, strict, enforce_admins true, no force push, no required reviews), repo allows merge/squash/rebase with `delete_branch_on_merge: true`; open PRs #210, #211, #236, #238-#241 | No change in 193. The PR branches `docs/192-post-sync-records` and `chore/193-cleanup-records` will be auto-deleted on merge (repo setting); do not run remote branch deletion yourself (it is behind the AGENTS gate). |
| OS-registered state | None found for `crosswake` (no launchd/cron registered by this phase's items; not exhaustively enumerated: **not verified**) | Planner: add a one-line `launchctl list` / crontab grep for `crosswake` to the removal gate evidence (counts only). |
| Secrets/env vars | 3 local environment files (`R-ENV`, count only, in `env-local.tar`, mode 600); the `gh` credential helper used by push; no denylist pointer | Restore only from `env-local.tar` (0600); never list names or contents; the tracked-dirty subset is noted in `env-counts.txt`. |
| Build artifacts / installed | `deps/`, `_build/`, `node_modules`, `.build` (35965 files), `DerivedData` in the recovery folder; other clones carry their own `deps/` | Rebuild in the clean checkout (D-08); they go with the removals. |

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| bash, zsh | scripts | yes | 5.2.37 / 5.9 | - |
| git | everything | yes | 2.41.0 | - |
| gh (authenticated read; write for PR create/merge) | PRs, final check | yes (reads worked) | 2.101.0 | - |
| jq | CI poll | yes | 1.7.1-apple | - |
| gitleaks | scan | yes | 8.30.1 (required exactly) | none (scan fails closed) |
| shasum, tar, stat (BSD) | backups | yes | 6.02 | - |
| node | JS tests (not needed for 193 scripts) | yes | v26.10.0 | - |
| mix / Erlang | D-08 proof | yes | OTP 27 | - |
| Network to hex.pm for `mix deps.get` | D-08 proof | not tested | - | none; if offline the proof cannot pass, report it, do not pass silently |
| Disk | extra backups | yes | 459 GiB free; backup root 8.6 GB | - |

BSD-specific: scripts use `stat -f %Lp`/`%u` (macOS). Do not port to GNU `stat`.

## Validation Architecture

> `workflow.nyquist_validation` is `true` in `.planning/config.json` (main's copy; the recovery copy is byte-identical).

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Phase-local bash self-tests (no ExUnit/Vitest needed); each prints one label per control and exits 0 only on `controls N of N as expected` |
| Config file | none; `193-SCRIPTS.sha256` freezes the script set (same form as `189-SCRIPTS.sha256`) |
| Quick run command | `bash <phase>/scripts/selftest-193.sh` (aggregates all 193 self-tests, runs under 30 s with local fixtures) |
| Full suite command | the above plus `bash <phase>/scripts/final-check-193.sh --post-merge` and the regression gate `selftest-scan-191.sh`, `selftest-carry-191.sh`, `selftest-privacy-192.sh` (the three standalone legacy self-tests). The 192 push/ci/merge/postmerge self-tests cannot run after D-13 (Pitfall 1): run them once in 193-01 and record, then rely on their 193 forks. |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CLEAN-01 | Backups verify before anything moves | integration | `preflight-193.sh` (exit 0; sums counts; restore matrix; ref diff classified) | Wave 0 |
| CLEAN-01 | To-land work is on `main` | integration | `ancestry-193.sh` for `9f33c071`, `2faf15a2`, `candidate-src`, `carry-trial-3` (exit 0 each) and `carry-trial`/`carry-trial-2` reported as bundle-held | Wave 0 |
| CLEAN-01 | Post-189 backup is usable | integration | `restore-189.sh integration-191-trials.bundle bundle <expect>` -> `restore ...: pass`; `shasum -c SHA256SUMS.193` with expected line count | Wave 0 |
| CLEAN-01 | Copy-forward proven | integration | `copyforward-193.sh --verify`: counts by category > 0, modes/hashes equal `.files`, `env-local` mode 600; `mix deps.get`, `mix compile --warnings-as-errors` each exit 0 (captured, not piped); `git status --porcelain` empty | Wave 0 |
| CLEAN-01 | Swap safe and reversible | unit | `swap-193.sh --self-test` (second rename failure rolls back; already-swapped is idempotent; refuses if the target exists) | Wave 0 |
| CLEAN-02 | Per-item removal gate | unit + integration | `remove-193.sh --self-test`, then `remove-193.sh --plan` (dry run printing the Gate B list) | Wave 0 |
| CLEAN-02 | Every row accounted for | integration | ledger header `expected = removed + kept`, `expected > 0`, each kept row has a cause (checked by `final-check-193.sh` check 5) | Wave 0 |
| CLEAN-03 | Clean tree, HEAD == `origin/main` | integration | `final-check-193.sh --post-merge` check 1 | Wave 0 |
| CLEAN-03 | Crosswake CI green for the tip | integration | check 2 (PR-head resolution) | Wave 0 |
| CLEAN-03 | Every open PR has a disposition | integration | check 3 (set equality of numbers; table parse `^\| [0-9]+ \|`; gh failure or empty output = FAIL) | Wave 0 |
| CLEAN-03 | No `<tmp>` sole copy | integration | check 4 (list `<tmp>/crosswake*` ; each remaining maps to a verified row) | Wave 0 |
| CLEAN-04 | Rules rewritten | integration | `grep` assertions via a one-off check script (not a permanent CI lane, per D-18): AGENTS.md contains the `How changes land` heading and none of `Standing authorization`, `Phase175`, `Repair-only pushes`; STATE `Exact Next Action` has no "frozen recovery" phrase; ROADMAP has the one-line note; PROJECT `Current stage` line has no "stays frozen"; each assertion fails on a missing file | Wave 0 |

### Self-test controls each new script needs (must fail, plus one passing control)
- `preflight-193.sh`: empty sums file; wrong expected count; one flipped byte in a copied artifact; missing `.files`; 189 script hash mismatch; extra unclassified ref; missing backup root.
- `backup-post189-193.sh`: ref set empty; bundle that fails `verify`; bundle missing a ref; sums line absent; checkpoint bundle unmapped.
- `land-gate-193.sh` (fork): scan HEAD != push HEAD; scan exit != 0; `main` moved; not fast-forward; remote unreadable; head changed after `allow` (answer void); `hold`; `answer` without `propose`; delivery uncertain (exit 3, no retry).
- `copyforward-193.sh`: empty allowlist match; wrong mode on env file; hash mismatch; file outside the allowlist copied; env file name or content in the record (privacy grep must be non-empty-scope).
- `swap-193.sh`: target exists; second rename fails (rollback verified); source missing; run twice.
- `guard-swapped-193.sh`: wrong folder; HEAD != `origin/main`; retired folder missing without the ledger saying removed.
- `remove-193.sh`: no row; sha mismatch; bundle verify failure; ref tip neither in a bundle nor an ancestor; dirty path not in the dirty tar; temp list not a subset of the tar listing; `<backup-root>` fails verify (whole run stops); re-run records "already absent"; a path outside the allowlist of crosswake entries is refused (other projects' `<tmp>` entries untouchable).
- `final-check-193.sh`: dirty tree; red CI; no single merged PR for the tip; open PR with no disposition; disposition row for a closed PR (allowed only for the merged PR 2 / #242); empty gh output; unparseable gh JSON; gh non-zero exit; empty ledger; expected count 0; leftover `<tmp>/crosswake*`; pre-merge HEAD != PR head; clean fixture passes.
- Every script: a static control that its source contains no home path, no `crosswake-phase191-run`, no `locate-191`, no `common-192`, no pipe into `tail`/`head` in a gating position.

### Sampling Rate
- **Per task commit (or per task completion in the recovery session, where there is no commit):** the task's own `--self-test` and a `bash -n` of every changed script.
- **Per plan:** the aggregate `selftest-193.sh` and `shasum -a 256 -c 193-SCRIPTS.sha256` (re-freeze the hash file after any script edit; mismatch = stop).
- **Phase gate:** `final-check-193.sh --pre-merge` on PR 2's head, then `--post-merge` after the merge; copy the post-merge output as a receipt into `<backup-root>`.
- **Sampling points inside the sequence:** after preflight; after the post-189 backup; after PR 1 merge (refetch, tip equals the merge commit); after copy-forward; immediately after the swap (guard); before Gate B (re-run preflight verify, record counts); after each removal group (ledger row written before the next group); before the PR 2 push (scan bound to HEAD); after PR 2 merge.

### Wave 0 Gaps
- [ ] All eight 193 scripts and their self-tests and `193-SCRIPTS.sha256`
- [ ] `193-POST189-RECORD.md` (new row ids for the sibling-clone refs, the checkpoint bundle, the post-189 `<tmp>` entries, the 18 published refs)
- [ ] A disposition table file (`193-PR-DISPOSITIONS.md` or a section in a record) in the format `| PR | Title | Head seen | Disposition | Reason |` so `^\| [0-9]+ \|` matches (the 189 `pr-table.md` header has 7 columns; either keep it or document the change)
- [ ] No framework install needed.

## Security Domain

`security_enforcement` is not set to false in config (absent = enabled). This phase has no application surface; the relevant controls are repository-hygiene and credential/privacy handling.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no (no auth code); but the `gh` credential helper is used for push | `gh auth git-credential` as in 192; never print credentials; AGENTS.md: a local read with a privileged CLI credential does not prove workflow access |
| V3 Session Management | no | - |
| V4 Access Control | yes (repo operations) | Branch protection (strict required check, enforce_admins true, no force push); merge commit only; no admin bypass |
| V5 Input Validation | yes | Scripts validate SHAs (`is_sha40`), refuse non-fixture hook values outside self-test, quote all paths |
| V6 Cryptography | no | `shasum -a 256` for integrity only |
| V8 Data Protection | yes | env backup mode 0600; no env file names/contents in any record; privacy scan before every push; home paths redacted (`<home>`) |
| V14 Config / supply chain | yes | gitleaks pinned to 8.30.1; Dependabot PRs merge only after a SHA-pin provenance check (D-20) |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Home path, account name or adopter identity in a published record | Information disclosure | `carry-191.sh` redaction + `scan-191.sh` + `privacy-192.sh` on PR text; adopter-term check skipped by standing user decision A-14 (no denylist exists); say so in the evidence |
| Deleting the only copy of data | Tampering / DoS | D-13 per-item gate, fail-closed, `<backup-root>` kept |
| Accidental deletion of another project's `<tmp>` folder | Tampering | allowlist of crosswake entry names; never glob `<tmp>/*`; list only `crosswake*`; refuse any path whose realpath is outside `<tmp>/crosswake*` |
| Replayed or transferred approval for a merge | Elevation of privilege | one-use `allow`/`hold`, bound to PR number and head, void on head change; no retry after uncertain delivery (exit 3) |
| Credential printed in a log or PR text | Information disclosure | fixed labels only; the open `WR-01` masking gap is in the CI failure-tail masker (SEED-025); do not paste CI failure tails into PR text or records without `privacy-192.sh` |
| Env files copied world-readable | Information disclosure | restore with mode 0600, assert with `stat -f %Lp` |

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Candidate in `<tmp>` + frozen recovery checkout (v27 ordering rules) | Single `main` checkout, branch from `origin/main`, PR with Crosswake CI, merge commit | This phase | Replaces AGENTS.md/STATE/ROADMAP/PROJECT wording |
| One-off permission prompts per operation (Phase 175) | One displayed `allow`/`hold` gate per irreversible operation, bound to head | 192 D-07 | AGENTS.md generalizes it (D-15) |

**Deprecated/outdated:** the Phase 175 standing authorization (dropped); `locate-191.sh`-based tooling (frozen history); `reconcile-189.sh` (historical).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | GSD commands with `--ws quality-ratchet-release` need the workstream `config.json`/`state.json` in the checkout | Open Questions OQ-2 | If not needed, the copy-forward step is harmless extra; if needed and omitted, the new session cannot run GSD commands |
| A2 | `$gsd-execute-phase 193 --ws quality-ratchet-release` can be resumed after the swap without a wave/plan filter (or a filter exists) | Plan Split | The handoff command may need adjusting; the guard script makes a wrong resume fail safe |
| A3 | Claude Code's per-project memory key depends only on the absolute path | Pitfall 7 | If it also depends on an inode or a git-derived id, memory is lost after the swap; D-10 already requires the new session to confirm the memory index is visible |
| A4 | No launchd/cron/OS registrations embed `crosswake` paths | Runtime State Inventory | A stale registered job could point at the retired path; add the one-line check |
| A5 | The failing CI on #210/#211/#236 is specific to those PRs (not to `main`) | PR drift table | Only affects the wording of the disposition reason; the cause was not read |
| A6 | Network is available for `mix deps.get` during the D-08 proof | Environment Availability | Proof cannot pass offline |

## Sources

### Primary (HIGH confidence, read or run this session)
- `193-CONTEXT.md`, `REQUIREMENTS.md` (lines 55-72, 100-105), `ROADMAP.md` (lines 20-34, 204-232), `STATE.md` (sections at lines 27, 36, 46, 179, 185), `AGENTS.md` diff against `origin/main`, `.planning/PROJECT.md` line 75, `SEED-024`.
- 189: `lib-189.sh`, `manifest-189.sh`, `restore-189.sh`, `reconcile-189.sh`, `verify-189.sh`, `prs-189.sh` (header), `189-SCRIPTS.sha256` (checked, rc 0), `189-INVENTORY.md` (structure), `189-SNAPSHOT-AFTER.txt`, `189-EVIDENCE/{tmp-listing-before.txt,tmp-entry-map.tsv,tmp-repos.tsv,restore-*.tsv,pr-table.md}`, `189-DECISIONS-ANSWERS.md` rows 8 and 9.
- 191: `locate-191.sh`, `ensure-clone-191.sh`, `finalize-191.sh`, `scan-191.sh`, `terms-191.sh`, `carry-191.sh`, `carry-floor-191.sh`, `carry-table-191.tsv`, `carry-exclusions-191.tsv`, `git-pinned-191.sh`, self-test headers, `192-EVIDENCE/scan-191-at-LAND-FIX.txt`.
- 192: `common-192.sh`, `push-192.sh`, `merge-gate-192.sh`, `ci-poll-192.sh`, `postmerge-192.sh`, `privacy-192.sh` (headers and key logic).
- Live reads: `git ls-remote`, `git status`, `git for-each-ref`, `git worktree list`, `git stash list`, `git merge-base --is-ancestor`, `git bundle create/verify/list-heads` into the scratchpad (deleted), `shasum -a 256 -c` on all sums files, `gh pr list/view`, `gh api` (`branches/main/protection`, `required_status_checks`, `commits/<sha>/pulls`, `commits/<sha>/check-runs`, `actions/runs?head_sha=`, `compare`), `gh run list`, tool version probes, `df`, `du`.
- `.github/workflows/crosswake-ci.yml` (recovery and `origin/main` copies: `on: pull_request` only).

### Secondary / Tertiary
- None. No web research was needed; no external library is involved.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - all tools probed this session; no new packages.
- Architecture / plan split: MEDIUM - derived from the decisions and script behaviour; resume-command mechanics are assumed (A2).
- Pitfalls: HIGH - each was found by reading the script or running a read-only command.
- Open questions: all resolved (see `## Open Questions (RESOLVED)`); OQ-1 by D-22, OQ-3/OQ-4/OQ-7 by D-24, OQ-2/OQ-5/OQ-6 by adopting the recommendation.

**Research date:** 2026-10-23
**Valid until:** until `origin/main` moves or any open PR head changes (re-run the live-fact block at plan-execution time; Dependabot rebases heads routinely). The script findings are stable.

## RESEARCH COMPLETE (marker for the orchestrator)
