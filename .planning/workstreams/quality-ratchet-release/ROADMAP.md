# Roadmap: Quality Ratchet & Release

## Milestones

- **v27.0 Land and Clean Up** — phases 189–193; in progress (started 2026-10-16); 18 requirements. Land the v25 and v26 work on GitHub `main` with CI green, then clean up the local repository so no copy of the work can be lost. [Requirements](REQUIREMENTS.md).
- **v26.0 Harden Before Trust** — phases 184–188; planning closeout complete 2026-10-16; 18/18 requirements, 37 plans, 96 tasks; audit `tech_debt` with no blocker; twin-05 passed against the frozen candidate `a53fbef`. Product code stays in the `/private/tmp` candidate pending a separately authorized delivery. [Archive](milestones/v26.0-ROADMAP.md).
- **v25.0 iOS Host Setup & Digital Twin Proof** — phases 179–183; planning closeout complete 2026-10-15; 20/20 requirements, 32 plans, 78 tasks; re-audit `tech_debt` with no blocker. Product code stays in the `/private/tmp` candidate pending a separately authorized delivery. [Archive](milestones/v25.0-ROADMAP.md).
- **v24.0 Repository Cleanup & Maintenance** — phases 176–178; planning closeout complete 2026-10-12; 8/8 requirements, 15 plans, 28 tasks; six retained debt records. [Archive](milestones/v24.0-ROADMAP.md).
- **v23.0 Release Pipeline Repair & Proof-Lane Truth** — phases 169–175, archived with exceptions 2026-10-11; 42/43 requirements; REL-10 breached. [Archive](milestones/v23.0-ROADMAP.md).
- **v22.0 Quality Ratchet & Release Readiness** — phases 164–168, archived with overrides 2026-09-15. [Archive](milestones/v22.0-ROADMAP.md).

## Phases

### v27.0 Land and Clean Up (Phases 189–193) — in progress

- [x] **Phase 189: Inventory and backup** - Account for every copy of the work not on GitHub `main`, back it up outside `/private/tmp`, and record a disposition for every open PR (read-only; nothing is deleted) (completed 2026-10-18)
- [x] **Phase 190: Fix warnings before landing** - Fix the seven carried warnings in the candidate (or a durable clone of it) so the landed code has no check that passes while checking nothing (no twin run) (completed 2026-10-19)
- [x] **Phase 191: Integration branch and local suite** - Build one integration branch from current GitHub `main` in a separate durable clone, carrying the candidate history, the FIX commits and the v24–v27 planning records, with a clean privacy scan and a passing local suite (completed 2026-10-23)
- [x] **Phase 192: PR, CI and merge** - Open the PR, get every required CI check green, merge only after the user's plain `allow` on the displayed PR and head, and confirm `main` CI is green on the merge commit (completed 2026-10-23)
- [x] **Phase 193: Cleanup and new working rules** - Retire the recovery checkout for a clean `main` checkout, remove landed or obsolete local copies, and switch the working rules to the normal branch-and-PR flow

### Ordering rules for v27.0

v27.0 only; superseded by AGENTS.md 'How changes land' after Phase 193

- **Nothing is deleted before Phase 189's backups pass their restore test.** Phases 189–192 remove nothing: no stash, branch, worktree, clone or file.
- **The recovery checkout stays frozen through Phase 192.** In the recovery checkout there is no staging, commit, tag, branch, worktree or stash change until Phase 193. The integration branch is built in a separate durable clone, never in the recovery checkout.
- **FIX work happens in the candidate.** Phase 190 works in `<durable-candidate>` (a durable clone of the candidate, outside the temp folder), not in the temp-folder candidate, which the macOS temp cleaner will erode. No twin run is part of this milestone.
- **Push and PR creation are in scope; the merge is not pre-authorized.** Phase 192 may push the integration branch and open the PR. The merge needs a fresh plain-language `allow` from the user for the displayed PR and head commit; `hold` stops at that point. No force push, branch-protection bypass or admin merge.
- **No package release or Hex publish.** Release PR #236 only gets a disposition in Phase 189; merging or publishing it is a separate decision.
- The protection on the recovery checkout lifts only in Phase 193, and only after its *to land* work is on `main` and everything else is backed up.

## Phase Details

### Phase 189: Inventory and backup

**Goal**: The user can see, in one place, every copy of work that is not on GitHub `main`, what should happen to each one, and proof that each copy that matters can be restored from a backup outside `/private/tmp`.
**Depends on**: Nothing (first phase of v27.0)
**Requirements**: INV-01, INV-02, INV-03
**Success Criteria** (what must be TRUE):
  1. One inventory covers the candidate's commits, the recovery checkout's uncommitted code and planning files, its 4 stashes, 56 local branches and 2 extra worktrees, and the other `/private/tmp` clones; each item is marked *on main*, *to land*, *obsolete* or *unclassified* (backed up and left for the user's decision before Phase 193, per D-06) with a reason, decided by comparing content with `main`, not by name.
  2. Every item marked *to land* or not yet classified has a backup outside `/private/tmp`, and a restore test shows each backup reproduces the item exactly.
  3. PRs #238, #236 and #210, #211, #239, #240, #241 each have a recorded disposition: merge, close, redo after landing, or hold (release PR #236, per D-13).
  4. Nothing was deleted, and the recovery checkout shows no git change (same HEAD, branches, stashes and worktrees as at the start).

**Plans**: 13 plans in 9 waves (189-11 to 189-13 close the verification gap)

Plans:
**Wave 1**
- [x] 189-01-PLAN.md — frozen `<tmp>` listing and before-snapshot first; shared read-only tooling (wrappers, absolute git-directory reads, regenerable marker check, scan, restore, manifest, verify) with a 46-control selftest (wave 1)

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 189-02-PLAN.md — tracer: all recovery refs plus stash and reflog-only commits (cross-checked against `log -g`) captured, classified, bundled with complete history, restored, manifested, inventoried and scanned (wave 2)

**Wave 3** *(blocked on Wave 2 completion)*
- [x] 189-03-PLAN.md — all four stashes exported and restored; 56 branches and the other ref groups classified by content (wave 3)
- [x] 189-04-PLAN.md — 738 uncommitted paths classified file by file; uncommitted and worktree backups with restores (wave 3)
- [x] 189-05-PLAN.md — local environment files in a restricted archive with a restore test; ignored-content backup with marker-checked regenerable exclusion; lost-found row (wave 3)
- [x] 189-06-PLAN.md — every frozen `<tmp>` crosswake* entry classified, including every ref, stash entry and reflog commit of each repo (wave 3)
- [x] 189-07-PLAN.md — candidate bundles re-verified plus one connected bundle; dispositions for PRs 238, 236, 210, 211, 239, 240, 241 (wave 3)

**Wave 4** *(blocked on Wave 3 completion)*
- [x] 189-08-PLAN.md — `<tmp>` backups: self-contained commits bundle, git-directory archives for unreadable ids, and tars without regenerable output, each restore-tested (wave 4)

**Wave 5** *(blocked on Wave 4 completion)*
- [x] 189-09-PLAN.md — final inventory reconciliation, seven per-plan manifests checked, full restore rerun, complete manifest and the user's decision list (wave 5)

**Wave 6** *(blocked on Wave 5 completion)*
- [x] 189-10-PLAN.md — script copies, after-snapshot, no-deletion check, recorded scan of the planning documents, final scan, phase-folder backup and the single-command handoff (wave 6)

**Wave 7** *(gap closure; blocked on Wave 6 completion)*
- [x] 189-11-PLAN.md — tracer: CR-01 clone recorded as unclassified row R-TMP-051 with a fresh cr01 restore, SHA256SUMS.11 and reconcile; recheck of every empty and stub temp-folder row; decision group 14 with its 3 commits; SHA256SUMS.cr01 folded into SHA256SUMS (wave 7)

**Wave 8** *(gap closure; blocked on Wave 7 completion)*
- [x] 189-12-PLAN.md — tracer: durable-candidate proof, frozen-state and no-deletion recheck under the approved amendment; full restore and reconcile rerun anchored on <durable-candidate> (wave 8)

**Wave 9** *(gap closure; blocked on Wave 8 completion)*
- [x] 189-13-PLAN.md — tracer: read-only checks and dispositions for every open review finding; recorded and final scans; refreshed phase-folder backup and final manifest; single-command handoff naming <durable-candidate> (wave 9)

### Phase 190: Fix warnings before landing

**Goal**: The code about to land no longer contains the carried checks that can pass while checking nothing or report the wrong cause, and the 186 WR-01 loopback residual refuses as the owner decided.
**Depends on**: Phase 189
**Requirements**: FIX-01, FIX-02, FIX-03, FIX-04, FIX-05, FIX-06, FIX-07
**Success Criteria** (what must be TRUE):
  1. A privacy scan pointed at a scope with no files fails with a scope error instead of reporting zero hits, and every gate label has at least one self-test case that makes it fail.
  2. The run gate's shell git helper ignores user and global git configuration the same way the shared Elixir git funnel does, shown by a test that sets a misleading config and gets the same answer from both.
  3. A slow registry read is reported as a timeout, and stopping all children leaves a registry that is still alive running; for a nested host folder with no `.git` of its own, provenance does not report the enclosing repository's commit.
  4. The physical-iPhone preflight refuses with a clear reason when `Info.plist` is unreadable or `route_activation.json` is malformed, and the guard's minimum test-file count equals the real number of test files.
  5. The code FIX commits (FIX-04..07) are in `<durable-candidate>` with their tests passing, and the script FIXes (FIX-01..03) are fixed, self-tested successor scripts in the Phase 190 folder, with the Phase 188 originals left unchanged (190 D-01, D-02); no twin run was started and the recovery checkout is unchanged.

**Plans**: 10 plans in 7 waves

Plans:
**Wave 1**
- [x] 190-01-PLAN.md — tracer: filesystem-only locate step, rebuildable work clone with deps, recovery and Phase 180 records, suite gate, measured baseline with a disposition for every baseline failure (wave 1)
- [x] 190-02-PLAN.md — FIX-01: successor privacy scan that refuses empty or symlink scopes, 15-control self-test (wave 1)
- [x] 190-03-PLAN.md — FIX-03 helper: shared pinned `g()`, gate successor, the 31 Phase 188 controls ported green (wave 1)

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 190-04-PLAN.md — FIX-02: derived-coverage gate with meta-controls and eleven new failing controls, 30-of-30 label coverage (wave 2)
- [x] 190-05-PLAN.md — FIX-07: preflight refuses unreadable Info.plist or malformed route_activation.json; commit 1 in `<durable-candidate>` (wave 2)

**Wave 3** *(blocked on Wave 2 completion)*
- [x] 190-06-PLAN.md — FIX-05: shared GitPins module, provenance refuses a nested host's enclosing commit; commit 2 (wave 3)

**Wave 4** *(blocked on Wave 3 completion)*
- [x] 190-07-PLAN.md — FIX-04: registry timeout reported, a live registry (timed out or holding a surviving child) is never stopped, verdict names the timeout; commit 3 (wave 4)

**Wave 5** *(blocked on Wave 4 completion)*
- [x] 190-08-PLAN.md — FIX-03 proof: shell helper vs Elixir funnel under a misleading global config, 188 helper negative control, drift check (wave 5)

**Wave 6** *(blocked on Wave 5 completion)*
- [x] 190-09-PLAN.md — FIX-06: last FIX commit, pin = count measured by a separate command, guard shown failing one above it (wave 6)

**Wave 7** *(blocked on Wave 6 completion)*
- [x] 190-10-PLAN.md — phase gate, baseline dispositions for Phase 191, 188 disposition pointers and out-of-scope lines for the four non-gate `g()` copies, handoff (wave 7)

### Phase 191: Integration branch and local suite

**Goal**: One integration branch, cut from current GitHub `main` in a separate durable clone, holds everything that should land and passes the full local suite with no silent exclusions.
**Depends on**: Phase 190
**Requirements**: LAND-01, LAND-02
**Success Criteria** (what must be TRUE):
  1. The integration branch starts from the current GitHub `main` commit and contains the candidate's commits with their history preserved, the FIX commits and the v24–v27 planning records.
  2. A privacy scan of the full change against `main` finds no home-directory paths, usernames, secrets or adopter identity.
  3. The full local suite passes on the integration branch; the known failures (Swift G4, example-host G2 and G6) are each either fixed or listed with a reason, and nothing is skipped without being listed.
  4. The branch was built in a separate durable clone; the recovery checkout shows no git change.

**Plans**: 12 plans in 9 waves

Plans:
**Wave 1**
- [x] 191-01-PLAN.md — tracer: recovery before-snapshot first; pinned git with a repo argument, regenerating locate, snapshot with index/reflog/object coverage (WR-10, WR-11); fresh durable clone of GitHub main fast-forwarded to the 94 candidate commits on land/v25-v27 (wave 1)

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 191-02-PLAN.md — planning-carry tool: content manifest, path-to-milestone table, exclusions, privacy transforms, exact verify, 17 negative controls, dry run on the real trees (wave 2)
- [x] 191-03-PLAN.md — suite gate successor (WR-09): required floors, strict totals, nine stage records, UTF-8 child locale, no baseline mode, 24 controls (wave 2)
- [x] 191-04-PLAN.md — HEAD-bound four-input privacy scanner plus gitleaks (WR-07, IN-02), the user's private denylist, real-term check, clean dry run of the candidate history (wave 2)

**Wave 3** *(blocked on Wave 2 completion)*
- [x] 191-05-PLAN.md — code fixes: format-only commit, locale-independent ledger output, root G1 inverted with the ledger regenerated (wave 3)

**Wave 4** *(blocked on Wave 3 completion)*
- [x] 191-06-PLAN.md — code fixes: example-host G2/G6 and Swift G4 inverted; G3 skips justified by an export-enabled run (wave 4)

**Wave 5** *(blocked on Wave 4 completion)*
- [x] 191-07-PLAN.md — Phase 190 review fixes: WR-05 usable origin, WR-01 (+WR-06) stop-result notes, WR-03 positive control (wave 5)

**Wave 6** *(blocked on Wave 5 completion)*
- [x] 191-08-PLAN.md — adoption-scan extensions and the code-fix checkpoint; planning resolver commit and the resolver checkpoint (wave 6)
- [x] 191-09-PLAN.md — records before the cut: SEED-024, all 15 Phase 190 review dispositions, the REQUIREMENTS/PROJECT label edits (wave 6)

**Wave 7** *(blocked on Wave 6 completion)*
- [x] 191-10-PLAN.md — the planning carry: five per-milestone snapshot commits built on a trial branch, verified exactly, privacy-checked, then fast-forwarded (wave 7)

**Wave 8** *(blocked on Wave 7 completion)*
- [x] 191-11-PLAN.md — LAND-02 gate: `--all` nine stages, example host, Swift export run, exclusion audit, CI-parity commands, pin recount, dispositions (wave 8)

**Wave 9** *(blocked on Wave 8 completion)*
- [x] 191-12-PLAN.md — finalize: sync commit, HEAD-bound privacy scan, recovery and durable after-checks, history gate, one-command handoff (wave 9)

### Phase 192: PR, CI and merge

**Goal**: The v25 and v26 work is on GitHub `main`, merged with the user's explicit approval, and `main` CI is green on the merge commit.
**Depends on**: Phase 191
**Requirements**: LAND-03, LAND-04
**Success Criteria** (what must be TRUE):
  1. A PR from the integration branch to `main` is open and every required CI check on its head commit passes.
  2. The user is shown the PR and its head commit and answers `allow` or `hold` in plain language; the merge happens only after `allow`, and only for that displayed head.
  3. After the merge, CI on `main` is green for the merge commit.
  4. No package release, Hex publish, force push or protection bypass happened, and the recovery checkout still shows no git change.

**Plans**: 10 plans

Plans:

**Wave 1**
- [x] 192-01-PLAN.md — recovery baseline; push gate (bound to the scan, fixed refspec, live main check) proven by a real dry run at the SYNC head; bare-remote self-test (wave 1)

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 192-02-PLAN.md — WR-03: scanner fails closed on unreadable notes (control S33, red then green); privacy check for PR text and evidence (wave 2)
- [x] 192-03-PLAN.md — gh/curl test double from live captured shapes; CI poller (required set, check selection rule, wait with synthetic-merge evidence) (wave 2)

**Wave 3** *(blocked on Wave 2 completion)*
- [x] 192-04-PLAN.md — one-use merge gate (propose, allow/hold, merge with --match-head-commit, void and re-ask, read-back reconcile) and its self-test (wave 3)

**Wave 4** *(blocked on Wave 3 completion)*
- [x] 192-05-PLAN.md — post-merge verifier (three facts for "main green", publish jobs skipped, release/tag/Hex baselines) and its self-test (wave 4)

**Wave 5** *(blocked on Wave 4 completion)*
- [x] 192-06-PLAN.md — full finalize: the phase's one planning sync (SYNC-2), suites, checks, scan and a dry run at the sync head; no second sync (wave 5)

**Wave 6** *(blocked on Wave 5 completion)*
- [x] 192-07-PLAN.md — WR-01/WR-02 code commit (LAND-FIX), heads label, scan-only rescan, binding check and dry run at the push head; D-03 dispositions (wave 6)

**Wave 7** *(blocked on Wave 6 completion)*
- [x] 192-08-PLAN.md — record other open PRs, push, open the PR, Crosswake CI green on the exact head (fix-forward and main-moved procedures) (wave 7)

**Wave 8** *(blocked on Wave 7 completion)*
- [x] 192-09-PLAN.md — fresh real-shape self-tests, the plain-language allow/hold ask, the bound merge with a merge commit (wave 8, has the phase's one human decision)

**Wave 9** *(blocked on Wave 8 completion)*
- [x] 192-10-PLAN.md — post-merge proof (main green, nothing released, other open PRs unchanged), phase gate, handoff, recovery after-snapshot (wave 9)

### Phase 193: Cleanup and new working rules

**Goal**: The local setup is a single clean `main` checkout with nothing that exists only in `/private/tmp`, and the project's working rules describe the normal branch-from-`main`, open-a-PR flow.
**Depends on**: Phase 192
**Requirements**: CLEAN-01, CLEAN-02, CLEAN-03, CLEAN-04
**Success Criteria** (what must be TRUE):
  1. The recovery checkout is retired and replaced by a clean `main` checkout, only after its *to land* work is confirmed on `main` and everything else is confirmed backed up.
  2. Landed or obsolete stashes, extra worktrees and local branches are removed after backup; anything kept has a stated reason.
  3. A final check shows: `git status` on the `main` checkout is clean, `main` CI is green, every open PR has a disposition, and no `/private/tmp` folder is the only copy of anything.
  4. AGENTS.md and the workstream STATE no longer describe a `/private/tmp` candidate and a frozen recovery checkout; they describe branching from `main` and opening a PR.

**Plans**: 10 plans (session 1 in the recovery checkout: 01-06; the session ends after the folder swap; session 2 in the swapped checkout: 07-10)

Plans:

**Wave 1**
- [x] 193-01-PLAN.md — preflight re-verify of the 189 backups and the post-189 backup (bundle, temp tar, checkpoint file, SHA256SUMS.193, record)

**Wave 2** *(blocked on Wave 1 completion)*
- [x] 193-02-PLAN.md — fresh main clone and the standalone push/merge gate (land-gate-193.sh), real dry-run push
- [x] 193-03-PLAN.md — copy-forward, folder swap and session guard tools, real read-only stage of the backups

**Wave 3** *(blocked on Wave 2 completion)*
- [x] 193-04-PLAN.md — removal gate, final check, rules check, aggregate self-test, script hash freeze

**Wave 4** *(blocked on Wave 3 completion)*
- [x] 193-05-PLAN.md — PR 1 (192 post-sync records + 193 plans and tools), Gate A allow/hold, merge

**Wave 5** *(blocked on Wave 4 completion)*
- [x] 193-06-PLAN.md — copy-forward from backups and build proof, folder swap, session restart (human action)

**Wave 6** *(new session; blocked on Wave 5 completion)*
- [x] 193-07-PLAN.md — guard, copy-forward re-proof, memory check, late-record sweep

**Wave 7** *(blocked on Wave 6 completion)*
- [x] 193-08-PLAN.md — Gate B allow/hold for the removal list, per-item removal, ledger

**Wave 8** *(blocked on Wave 7 completion)*
- [x] 193-09-PLAN.md — AGENTS.md "How changes land", STATE/ROADMAP/PROJECT, SEED-025, PR dispositions

**Wave 9** *(blocked on Wave 8 completion)*
- [x] 193-10-PLAN.md — PR 2, pre-merge final check, Gate C allow/hold, merge, post-merge final check and receipt

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 189. Inventory and backup | 13/13 | Complete | 2026-10-18 |
| 190. Fix warnings before landing | 10/10 | Complete | 2026-10-19 |
| 191. Integration branch and local suite | 12/12 | Executed, verification pending | - |
| 192. PR, CI and merge | 10/10 | Executed, verification pending | - |
| 193. Cleanup and new working rules | 10/10 | Complete | 2026-10-24 |

<details>
<summary>v26.0 Harden Before Trust (Phases 184–188) — planning closeout 2026-10-16</summary>

- [x] Phase 184: Twin probe and safe preflight (15/15 plans) — completed 2026-10-16
- [x] Phase 185: Checks that cannot pass empty (5/5 plans) — completed 2026-10-16
- [x] Phase 186: Host seam and harness honesty (5/5 plans) — completed 2026-10-16
- [x] Phase 187: Doctor and proof fidelity (7/7 plans) — completed 2026-10-16
- [x] Phase 188: Freeze and twin-05 (5/5 plans) — completed 2026-10-16

</details>

<details>
<summary>v25.0 iOS Host Setup & Digital Twin Proof (Phases 179–183) — planning closeout 2026-10-15</summary>

- [x] Phase 179: iOS Host Setup Without Hand Patches (4/4 plans) — completed 2026-10-13
- [x] Phase 180: Bounded Digital Twin Demonstration (7/7 plans) — completed 2026-10-15
- [x] Phase 181: Core Host-Command Seam (10/10 plans) — completed 2026-10-14
- [x] Phase 182: Loopback Origin for Local iOS Host (6/6 plans) — completed 2026-10-14
- [x] Phase 183: Close gap: twin source binding fails closed on uncommitted code (5/5 plans) — completed 2026-10-15

</details>

## Exact Next Action

Next: `$gsd-audit-milestone --ws quality-ratchet-release`. Phase 193 is complete once PR 2 (#244) is merged: the recovery checkout was retired for a clean `main` checkout, 300 of 306 listed local copies were removed and 6 kept with reasons (`193-REMOVAL-LEDGER.md`), the working rules now say to branch from `main` and open a PR (AGENTS.md "How changes land"), and the final check (`final-check-193.sh`) passed before the merge question. All five v27.0 phases (189 to 193) are then complete. Details are in STATE.md and `193-VERIFICATION.md`.
