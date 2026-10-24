# Phase 193: Cleanup and new working rules - Context

**Gathered:** 2026-10-23
**Status:** Ready for planning
**How decided:** The user asked for a fan-out research pass and one coherent set of recommendations to follow ("one-shot a perfect set of recommendations so i dont have to think"). Four research agents covered working rules, records and PRs, checkout retirement, and removal order. Claude synthesized the decisions below. No preference interview was held. The Phase 189 answers (189-DECISIONS-ANSWERS.md) already settle *what* is removed. This phase decides *how*, *in what order* and *with what proof*.

<domain>
## Phase Boundary

The local setup ends as one clean `main` checkout at the same path as today's recovery checkout (`<recovery-checkout>`). Nothing exists only in `/private/tmp`. The project's active working rules describe branch-from-`main`, open-a-PR. Requirements: CLEAN-01, CLEAN-02, CLEAN-03, CLEAN-04.

In scope: landing the Phase 192 post-sync records and the Phase 193 records through ordinary PRs; one new backup for refs made after Phase 189; copying settings forward; removing the temp folders, extra worktrees, sibling clones and the retired checkout; rewriting the active guidance; the final check.

Out of scope: any code fix (the Phase 192 review residue goes to a seed); merging Dependabot PRs, #238 or release PR #236; any release, tag or Hex publish; GitHub-side branch cleanup; deleting `<backup-root>`.
</domain>

<decisions>
## Implementation Decisions

### Governing rules carried forward (do not re-ask)
- **D-01:** "The backup is the keep" (189 answers). Removing an item means removing its *source* copy after its backup re-verifies. `<backup-root>` is not deleted in v27; it is reviewed at the v28 boundary at the earliest. Restored items are never searched to reidentify the adopter.
- **D-02:** Every merge to `main` uses a merge commit. No squash, rebase-merge, force push or admin bypass (191 D-03, 192 D-04). The 191 privacy scanner runs on the exact head before every push, and the push refuses unless the scan HEAD equals the push HEAD with exit 0 (191 D-22). Each merge waits for a plain-language `allow`/`hold` shown with the PR link and head. The answer binds internally to that head and is void if the head changes (192 D-07). CI red → fix forward with a new commit, then rescan (192 D-06).
- **D-03:** Until the swap in D-09, the recovery checkout still gets no git write. Phase 193 files are written there only as plain files, and this discussion's own commit step is skipped for that reason. They reach `main` through PR 1 or PR 2.

### Sequence (the whole phase, in order; each step fails closed)
- **D-04:** The order is fixed:
  1. **Preflight.** Re-verify `<backup-root>`: check the 189 script hashes (`189-SCRIPTS.sha256`), then re-run the 189 manifest and restore checks. Compare the recovery checkout with `189-SNAPSHOT-AFTER.txt` (HEAD, refs, stash list, worktree list, status checksum). An unexpected difference means: back up that difference, then re-verify. The known difference is the plain-file planning records written in 190–193.
  2. **Post-189 backup (D-07).**
  3. **Fresh clone.** Clone `origin/main` to a sibling (`<home>/projects/crosswake-clean-main`). Check that HEAD equals the fetched `main`, the tree is clean and the remote URL is right. Set repo-local `user.email` to the noreply address main already uses.
  4. **PR 1** from the clone (D-11).
  5. **Copy forward and prove** (D-08).
  6. **Swap** (D-09). Then end the session.
  7. **New session in the swapped checkout.** One removal gate (D-12), then removals (D-13).
  8. **Working rules** (D-15..D-18) and **PR 2** (D-11).
  9. **Final check** after PR 2 merges (D-19).
  — **Reversibility:** reversible up to step 7; one-way from the removals (the backup is then the only copy).

### Backups for work made after Phase 189
- **D-05:** Before anything is removed, these items are confirmed on `main` (fresh fetch, `merge-base --is-ancestor` with the exit code checked directly): the integration clone's `land/v25-v27` (`9f33c071`), `candidate-src` and `carry-trial-3`, and the durable candidate's `candidate` (`2faf15a2`). Ancestry is checked against a freshly fetched `origin/main`, never against a sibling clone's own stale `origin/main` (`d0dbdf7b`).
- **D-06:** `carry-trial` (`28a48db7`) and `carry-trial-2` (`dd3bdf5f`) are NOT on `main`, and no 189 bundle holds them. Every other unmerged local ref in the two sibling clones is in the same situation.
- **D-07:** One new bundle, `<backup-root>/integration-191-trials.bundle`, holds those refs (prefix `^origin/main`) plus `land/v25-v27` and `candidate-src`. It passes `git bundle verify`, a restore into a scratch folder with tip comparison, and a sha256 line appended to a new sums file beside SHA256SUMS. The durable candidate's stray `crosswake-checkpoint-*.bundle` file is mapped to a 189 row or hashed in the same step. No other new backup is made.

### Retiring the checkout (CLEAN-01)
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
  - — **Reversibility:** reversible — two renames back.
- **D-10:** **The session ends after the swap.** The running session's working folder is the one being renamed, so the plan stops at a handoff after the swap. That handoff names the exact next command. Restarting the session is the one unavoidable human action. The new session re-runs the D-08 proof in the swapped checkout and confirms the Claude memory index is visible.

### Landing the records (two PRs)
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

### Removal (CLEAN-02)
- **D-13:** Removal is a plain folder delete gated per item. An item is removed only if every check below passes:
  - (a) it has a row in the frozen 189 inventory or in the D-07 record;
  - (b) its backup file exists and its sha256 matches the sums file;
  - (c) for git items, `git bundle verify` passes and every ref tip is in a verified bundle or is an ancestor of the fetched `origin/main`;
  - (d) for a worktree or clone, its dirty paths are in its dirty tar (or it is clean);
  - (e) for a temp folder, its file list is a subset of its tar listing.

  A failed item is kept, with a ledger row "kept: <cause>", and the run continues. The whole run stops only if `<backup-root>` itself fails to verify. A re-run records "already absent" rather than an error.
  - Order: `/private/tmp` crosswake entries → `../crosswake-accrue-bridge` (its 14 patch-unique commits must be in refs-all.bundle) → the integration clone → the durable candidate clone → `crosswake-recovery-retired` last. The `.claude/worktrees/agent-p78-*` worktree goes with the retired folder.
  - Only Crosswake entries are touched. Other projects' `/private/tmp` folders are never listed or touched (189 D-03).
- **D-14:** What remains, with its reason:
  - `<backup-root>`: the keep, until the v28 review;
  - the swapped `main` checkout;
  - any item a gate check refused, with its cause.

  Nothing else is expected. The ledger is `193-REMOVAL-LEDGER.md`. It uses placeholders only (`<home>`, `<tmp>`, `<backup-root>`, `<recovery-checkout>`) and has columns row id | kind | location | backup + sha256 match | ref check | action | result | reason if kept, plus a header with expected / removed / kept counts. Its generating script lives in `phases/193-*/scripts/` with its own sha256.

### Working rules (CLEAN-04)
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

### Final check (CLEAN-03)
- **D-19:** One dependency-free script (`bash`, `git`, `gh`), `phases/193-*/scripts/final-check-193.sh`, with `--self-test`. It asserts:
  - (1) `git status --porcelain` is empty in `<recovery-checkout>` and HEAD equals the fetched `origin/main`;
  - (2) the latest required "Crosswake CI" run on the current `main` SHA concluded success;
  - (3) the count of open PRs from `gh pr list --json` equals the count of rows in the disposition table, and every number matches;
  - (4) a fresh `/private/tmp` listing shows zero `crosswake*` entries, or each remaining one maps to a verified backup row;
  - (5) the ledger has one row per expected item, with the expected count read from the frozen 189 listing plus the D-07 record and asserted > 0.

  It fails closed: if gh fails, or its output is empty or unparseable, the check fails. Zero open PRs passes only when the JSON parsed and gh exited 0. Every check captures into variables and tests exit codes directly; nothing is piped into `tail`. The self-test feeds a dirty tree, red CI, a PR with no disposition, empty gh output, an empty ledger and a leftover temp folder. Each must fail, and a clean fixture must pass. Pattern: the 189/191 phase-scripts and their self-tests.

### PR dispositions and follow-ups
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

### Planning-time amendments (2026-10-23, after 193-RESEARCH.md)
- **D-22:** The 11 un-inventoried `crosswake*` folders in `<tmp>` (made in Phases 190–191) get **one small tar**: their file lists plus the non-regenerable loose files, excluding re-derivable trial trees (RESEARCH OQ-1 exclusion list). Rows `R-POST-TMP-NN` extend the D-07 record; the tar is hashed into `SHA256SUMS.193`, restore-tested, and listed at the D-12 removal gate. User chose this at plan time; it amends D-07's "no other new backup".
- **D-23:** D-07's bundle is built with **no negative prefix** (complete history), because a prerequisite bundle cannot pass `restore-189.sh`'s empty-repo verify. Same intent: holds those refs, verifiable.
- **D-24:** D-19 check (2) "main CI green" means: the "Crosswake CI" check (app 15368) on the head of the merged PR that produced the current `main` tip concluded success (the workflow runs on `pull_request` only). Main-push workflows are reported, not asserted. The final check has `--pre-merge <PR>` and `--post-merge` modes (RESEARCH OQ-3/OQ-4). Open-PR comparison is by number (OQ-7); #211's row is reworded to its observed failing CI.

- **D-25:** **D-11 amended (user-approved 2026-10-23):** PR 1 carries the whole Phase 193 folder as of the PR 1 cut (CONTEXT, DISCUSSION-LOG, RESEARCH, PATTERNS, VALIDATION, the ten plans, scripts and their hash freeze, the post-189 record, evidence, summaries 01–04) plus the STATE/ROADMAP/REQUIREMENTS/.continue-here handoff. Reason: the swapped checkout is a fresh clone of `main`, so the post-swap plans and the scripts they hash-check must already be on `main`, and the old checkout must never be their only copy. The Gate A prompt lists every path in two groups (the original D-11 set, then the extras). PR 2 keeps the rest of D-11's list.
- **D-26:** **A-14 extended to Phase 193 (user-approved 2026-10-23):** the privacy scan's private-name (adopter-term) check stays skipped under A-14 for the PR 1 and PR 2 pushes, because no term list is supplied. The skip stays recorded in every scan binding; every other scan check (home paths, tokens, credential shapes) still runs and still blocks.
- **D-27:** D-04 step 1's "status checksum" comparison is done path by path with blob hashes, because `189-SNAPSHOT-AFTER.txt` has no single status key. This is at least as strict, and the 193-01 SUMMARY records the substitution.

### Claude's Discretion
- Script names inside `phases/193-*/scripts/`, the ledger header layout, and PR titles and descriptions (plain language, linking the verification).
- Whether D-04 steps 1–3 are one plan or several, provided the order and fail-closed checks hold.
- After the phase: update Claude memory. Replace the stale `project_crosswake_state.md` (v20) with a pointer to the workstream STATE. Trim the stale "UNPUBLISHED v17.0" statements in `project_crosswake_core_first_publish.md`. Re-verify the worktree and dispatch-isolation entries under the new flow. Memory is not a planning record and is not part of the PRs.
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements and roadmap
- `.planning/workstreams/quality-ratchet-release/REQUIREMENTS.md` — CLEAN-01..04, Out of Scope, Future Requirements
- `.planning/workstreams/quality-ratchet-release/ROADMAP.md` — Phase 193 success criteria; "Ordering rules for v27.0"
- `.planning/workstreams/quality-ratchet-release/STATE.md` — "Exact Next Action" and the "Phase 193 inputs" list

### What gets removed and the backups
- `.planning/workstreams/quality-ratchet-release/phases/189-inventory-and-backup/189-DECISIONS-ANSWERS.md` — governing rule, all 14 groups, the four proofs required before removal
- `.planning/workstreams/quality-ratchet-release/phases/189-inventory-and-backup/189-CONTEXT.md` — D-02 placeholders, D-03 scope (other projects untouched), D-08 read-only rules, D-10 restore test, D-14 privacy grep, D-15 snapshots
- `.planning/workstreams/quality-ratchet-release/phases/189-inventory-and-backup/189-INVENTORY.md` — row ids and backup ids
- `.planning/workstreams/quality-ratchet-release/phases/189-inventory-and-backup/189-SNAPSHOT-AFTER.txt` — baseline for the preflight comparison
- `.planning/workstreams/quality-ratchet-release/phases/189-inventory-and-backup/scripts/` and `189-SCRIPTS.sha256` — manifest, restore and reconcile scripts to re-run

### Landing rules
- `.planning/workstreams/quality-ratchet-release/phases/191-integration-branch-and-local-suite/191-CONTEXT.md` — D-03 merge commit, D-08 records verbatim, D-14 no example-host CI lane, D-18/D-21/D-22 scanner, redaction and binding
- `.planning/workstreams/quality-ratchet-release/phases/192-pr-ci-and-merge/192-CONTEXT.md` — D-06 fix forward, D-07 allow gate, D-08 which commit CI ran on
- `.planning/workstreams/quality-ratchet-release/phases/192-pr-ci-and-merge/192-REVIEW.md` and `192-REVIEW-DISPOSITION.md` — residue for SEED-025
- `.planning/workstreams/quality-ratchet-release/phases/191-integration-branch-and-local-suite/scripts/` — the privacy scanner and carry-completeness scripts to reuse

### Working rules
- `AGENTS.md` (recovery copy) versus `git show origin/main:AGENTS.md` — the +41/-5 diff that D-15 dispositions
- `.planning/PROJECT.md` — "Current stage" line
- `.planning/seeds/` — SEED-024 format for SEED-025
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- 189 `scripts/` (`lib-189.sh`, `manifest-189.sh`, `restore-189.sh`, `reconcile-189.sh`): backup re-verify and restore tests.
- 191 privacy scanner and carry-completeness script, each with a self-test: PR 1 and PR 2 scans and the PR 1 carry manifest.
- `script/phase_evidence_path.{py,sh}`: live-or-archived path resolution.

### Established Patterns
- Dependency-free phase scripts (bash, git, shasum, gh) with a `--self-test` that proves each failure case fails. Copy-paste over a shared dependency.
- Placeholders in every record; no home paths; the privacy grep fails on an empty scope.
- Blocked plans are named `NN-BLOCKED.runN.md`, never `NN-SUMMARY.md`.

### Integration Points
- `.gitignore` already ignores `/.claude/`, `/_build/`, `/deps/`, `**/node_modules/` and `**/DerivedData/`, so copied-forward settings never show in `git status`.
- Claude Code memory at `<home>/.claude/projects/-Users-<user>-projects-crosswake/` is outside the checkout and keyed on its path. D-09 keeps it working with no action.
</code_context>

<specifics>
## Specific Ideas

- Live facts on 2026-10-23 (read-only):
  - `origin/main` = `d12aed75`;
  - the recovery checkout has 122 uncommitted paths, 4 stashes, 56 local branches and 2 extra worktrees;
  - 12 `crosswake*` entries in `/private/tmp`;
  - siblings: `crosswake-accrue-bridge`, `crosswake-candidate-backup` (the backup root), `crosswake-candidate-durable`, `crosswake-integration-191`;
  - open PRs: #210, #211, #236, #238, #239, #240, #241.
- The user's guiding preference: zero recurring human intervention. The only human touchpoints are the session restart after the swap and the three plain-language gates (PR 1 merge, removal, PR 2 merge).
</specifics>

<deferred>
## Deferred Ideas

- SEED-025 contents (D-21): WR-01..03, IN-01/02, the example-host CI lane.
- Merging the green Dependabot PRs #239–#241 after a SHA-pin provenance check; investigating #210's CI failure and #211's missing CI.
- Redoing #238 on the current `main` if its doc edits are still wanted.
- A short "How changes land" section in CONTRIBUTING.md for human contributors. CLEAN-04 names only AGENTS.md and STATE.
- Reviewing and possibly deleting `<backup-root>` at the v28 boundary.
</deferred>

---

*Phase: 193-cleanup-and-new-working-rules*
*Context gathered: 2026-10-23*
