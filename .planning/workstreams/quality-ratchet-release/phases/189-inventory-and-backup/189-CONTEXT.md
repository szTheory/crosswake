# Phase 189: Inventory and backup - Context

**Gathered:** 2026-10-16
**Status:** Ready for planning

<domain>
## Phase Boundary

Produce one inventory of every copy of Crosswake work that is not on GitHub `main`, classify each item by content (*on main*, *to land*, *obsolete*, or *unclassified*), back up everything that is *to land* or unclassified outside `/private/tmp` with a passing restore test, and record a disposition for each open PR (#238, #236, #210, #211, #239, #240, #241).

This phase is read-and-copy only. Nothing is deleted, and nothing in the recovery checkout changes: its HEAD, branches, stashes, worktrees and index stay as they are. No push, no PR action, and no fix work (fix work is Phase 190).

</domain>

<decisions>
## Implementation Decisions

### Backup location
- **D-01:** Backups go only in the existing sibling backup folder outside the project and outside `/private/tmp`, the same one that already holds the candidate bundles. Nothing is copied off this machine in Phase 189. The first off-machine copy is the integration-branch push in Phase 191/192, after its privacy scan. No content reaches the public repo before that scan. (User choice: "Local now, GitHub at PR".) — **Reversibility:** reversible — adding an off-machine copy later is additive.
- **D-02:** Planning files never record the backup folder's absolute path or any home path. Inventory rows use placeholders such as `<recovery-checkout>`, `<backup-root>` and `<tmp>/crosswake-phase180-impl`.

### Inventory scope
- **D-03:** The scope is Crosswake work only:
  - the candidate `<tmp>/crosswake-phase180-impl`;
  - the other `<tmp>/crosswake-*` folders: the 179/181/182 impl clones, the 179 source clone, the 178 handoff and diagnostic clones, and the ten Phase 175 folders, several of which are empty or not valid repos;
  - the recovery checkout's uncommitted changes, 4 stashes and 56 local branches;
  - the 2 extra worktrees (`crosswake-accrue-bridge` on `chore/accrue-host-command-bridge`, and `.claude/worktrees/agent-p78-*`).
  
  Folders in `/private/tmp` that belong to other projects (sigra, scrypath, gabbaboy, relyra, threadline, phase14/250/252 and others) are out of scope. Do not list, back up or touch them.
- **D-04:** Empty or broken `crosswake-*` folders (no valid HEAD, 0B) are listed with the reason "empty/no repo, nothing to keep" and classified *obsolete*. Removing them is left to Phase 193.

### Classification method
- **D-05:** Classify by content, not by name. The reference set is GitHub `main` (fetched fresh, at `d0dbdf7` or newer) plus the candidate `a53fbef`.
  - **Commits and branches:** use `git cherry` or patch-id equivalence plus a tree comparison. An item counts as *on main* only if every change it makes is already in `main`.
  - **Changes only in the candidate:** *to land* through the candidate. These need no extra landing work beyond the candidate.
  - **Uncommitted files:** compare each file's content with `main` and with the candidate.
- **D-06:** Never guess *obsolete*. An item becomes *obsolete* only with a specific, checkable reason, for example "superseded: same file content in candidate", "release-workflow scratch for consumed Phase 175 operation, outputs recorded in v23 archive", or "empty". Anything else is *unclassified*: it is backed up, and the user decides it before Phase 193 removes anything.
- **D-07:** The 73 non-planning paths in the recovery checkout get a file-by-file decision. They are mostly the Phase 175 `release_candidate` lib, scripts and tests. Each one is classified against `main` and the candidate. The ~47 planning paths are classified the same way. The v24–v26 planning records that exist only there are *to land*, through Phase 191's planning-records carry.

### Backup method (recovery checkout stays frozen)
- **D-08:** Only read-only git operations may touch the recovery checkout. Allowed: `git bundle create`, `rev-parse`, `diff`, `stash show -p`, `cat-file`, `for-each-ref`, and plain file copies or `tar`. Not allowed: `stash apply/drop`, `checkout`, `add`, `commit`, `branch`, `worktree add/remove`, and any `gc`, `prune` or `fetch` that writes the recovery checkout's refs. A fresh view of GitHub `main` comes from a separate clone, or from `gh` or `git ls-remote`.
- **D-09:** Backup set:
  - **Refs:** an all-refs bundle of the recovery checkout (branches, `refs/stash` and the worktrees' branches). The worktree checkouts each get their own uncommitted diff and untracked-file tar.
  - **Stashes:** each of the 4 stashes is exported both as a `stash show -p --include-untracked` patch and as its commit IDs captured in a bundle. Stash entries other than `stash-0` are reflog-only, so they need explicit capture. One way is a bundle built in a scratch clone from the stash commit IDs.
  - **Uncommitted work:** a tar of the 58 modified and 62 untracked files plus a `git diff HEAD` patch.
  - **Other `/private/tmp` clones:** only those holding *to land* or unclassified content beyond the candidate and the recovery checkout get a bundle (plus a tar if they have uncommitted changes).
  - **Candidate:** the existing candidate bundles are reused and re-verified, not rebuilt.
- **D-10:** Restore test for each backup, done in a scratch folder (never in a source repo):
  - Clone from the bundle or untar the archive.
  - Compare HEAD, tree IDs and ref lists; for files, compare checksums against the source.
  - Write a manifest beside the backups with a sha256 for each backup file.
  - Pass only on an exact match. Absence of an error is not a pass.

### PR dispositions (recorded only; no PR action in 189)
- **D-11:** Dependabot #210, #211, #239, #240 and #241: *redo after landing*. Rebase or recreate them on the post-merge `main`, and close any that the candidate already supersedes. The Phase 189 inventory checks whether the candidate's workflows already pin those versions.
- **D-12:** #238 (Phase 178 maintenance): decide by content. If the candidate already contains its changes, *close as superseded*. Otherwise *redo after landing*.
- **D-13:** #236 (release-please): *hold*. No release or Hex publish in v27; any release is a separate decision. Note whether landing will change its contents.

### Evidence and privacy
- **D-14:** The inventory is one Markdown table in the phase folder. It contains item, location placeholder, kind, classification, reason, backup id and restore result. Raw command output stays in phase evidence files and goes through the privacy rules (no home paths, usernames, secrets or adopter identity). A privacy grep of all new phase files must report zero hits, and it must fail if its file scope is empty.
- **D-15:** The phase verifies the frozen state. It snapshots the recovery checkout before and after: HEAD, `for-each-ref` output, `stash list` with commit IDs, `worktree list`, and the `status --porcelain` checksum. Success requires both snapshots to be identical.

### Claude's Discretion
- The exact table columns, the scratch-folder layout, and the bundle and archive file names inside the backup root.
- Whether all-refs plus per-stash capture uses one bundle or several.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Milestone scope and rules
- `.planning/workstreams/quality-ratchet-release/v27.0-SCOPE.md` — the user's choices, starting facts, the immediate candidate backup, and the boundaries
- `.planning/workstreams/quality-ratchet-release/REQUIREMENTS.md` — INV-01..03 (this phase); CLEAN-01..03 (what later depends on this inventory)
- `.planning/workstreams/quality-ratchet-release/ROADMAP.md` §"Ordering rules for v27.0" and §"Phase 189" — the no-delete and frozen-checkout rules and the success criteria
- `AGENTS.md` — the sensitive-data rules, the Workflow section, and the standing-authorization limits (no staging, commits, branch, worktree or stash changes in this checkout)

### Prior hygiene practice
- `docs/MILESTONE-BOUNDARY-HYGIENE.md` — the existing runbook for worktree, branch and PR triage
- `.planning/seeds/SEED-012*` — the repository-hygiene closeout seed folded into v27
- `.planning/workstreams/quality-ratchet-release/milestones/v26.0-ROADMAP.md`, `milestones/v25.0-ROADMAP.md` — which phases produced which candidate commits

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- The existing candidate bundles (full, plus incremental from `d0dbdf7`) in the backup root. They already pass a clone restore test (HEAD `a53fbef`, tree `f7c4d7dc`).
- The privacy scan used for planning files (home-path, username and adopter grep). Phase 190 FIX-01 makes the empty-scope case fail, and this phase must already treat an empty scope as a failure.

### Established Patterns
- Checksum manifests beside snapshots, as in `history/v26.0-before-v27-start.sha256` (7/7 verify).
- Gating commands are never piped into `tail` or `head`, and absence of output is never scored as a pass.

### Integration Points
- Phase 191 uses the *to land* list: the candidate commits plus the planning records.
- Phase 193 uses the *obsolete* and backed-up lists before it removes anything.
- Phase 192 and later use the PR dispositions.

</code_context>

<specifics>
## Specific Ideas

- Starting facts seen on 2026-10-16:
  - 16 `crosswake-*` folders in `/private/tmp`. The 179-impl clone has 2 dirty paths and the 178 diagnostic clone has 4.
  - Stashes: `stash-0`..`stash-2` on `agent-169-05-gap-closure` (planning preservation and the pre-175-12 draft), and `stash-3` (WIP on old `main` at `e3d6cbfa`).
  - The recovery checkout's own `origin/main` ref is stale, so a fresh `main` must be read without fetching into that checkout.

</specifics>

<deferred>
## Deferred Ideas

- An off-machine backup during 189 (a private cloud folder or an early GitHub backup branch). The user declined it; the Phase 191/192 push is the first off-machine copy.
- Cleaning up the `/private/tmp` folders of other projects. That work belongs to those projects, not this one.

</deferred>

---

*Phase: 189-inventory-and-backup*
*Context gathered: 2026-10-16*
