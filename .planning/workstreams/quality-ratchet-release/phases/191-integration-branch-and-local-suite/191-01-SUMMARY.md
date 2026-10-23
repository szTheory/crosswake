---
phase: 191-integration-branch-and-local-suite
plan: 01
status: complete
requirements: [LAND-01]
commits: 0
plan_head_before: not_recorded_frozen_checkout
plan_head_after: not_recorded_frozen_checkout
actuals:
  tasks: 2
  commits: 0
---

# Phase 191 Plan 01: Recovery snapshot, pinned tools and integration clone Summary

## What I need from you (please do this while Plans 02-04 run)

Please create a small private file that lists the first adopter's identifying terms, one term per line, with file mode 0600. Put it somewhere you choose that is outside the repository, outside the integration clone, outside the durable candidate and outside the temp folder. Then tell me its location in the conversation. I will store that location only in the private run folder (through `locate-191.sh --set-denylist`) and will never write it, or the file name, into any phase file, SUMMARY or evidence. The file is never committed or copied, and I will never create, guess or read it into a record. Phase files will show only the number of terms and the line `denylist_hash recorded_locally`; the file's sha256 stays only in the run folder (A-13). Plan 04 Task 3 waits for this file.

## Result

One-liner: the recovery checkout was recorded first (git state plus working-tree bytes), pinned git, locate, snapshot and tree tools are proven by 21 labelled controls, and a separate integration clone of current GitHub main now holds the 94 candidate commits on `land/v25-v27`, builds, and passes a real test.

- Recovery checkout, git state: recorded first into `191-EVIDENCE/recovery-before-191.txt` (11 digest lines). A fresh snapshot after all work is byte-identical, and its HEAD and ref state did not change.
- Recovery checkout, working-tree bytes (A-11): `191-EVIDENCE/recovery-tree-before-191.txt` holds 81568 files in the rest digest and 10 named-record lines (one is absent: the new seed does not exist yet). Two snapshots about a minute apart were identical, so no volatile entries needed adding; the volatile list is the five planned entries.
- Self-test: `selftest-base: controls 21 of 21 as expected` (S01-S21; the plan required at least 19). Stored output equals a fresh run.
- Integration clone `<integration-clone>`: fresh pinned clone of GitHub main, outside the temp folder and the recovery checkout. Branch `land/v25-v27` at `2faf15a255f644c869d321508c4d3f3007572138`, 94 commits after main `d0dbdf7bf196cea167ced3c50cf620bf3cb2452b`, 0 merges, first-parent count 94, `a53fbef` is an ancestor, pinned status clean. Origin main still equals the recorded main, so no stop-and-replan was needed.
- Identity: repo-local noreply identity proven on both the candidate commits and main's authors (`identity noreply yes`).
- Dependencies built (root and example host), and `test/crosswake/proof_lane/provenance_test.exs` ran 14 tests, 0 failures. A second ensure-clone run printed `ensure-clone: reused`; with a stray untracked file it printed `ensure-clone: clone_diverged` and recovered to `reused` once the file was removed.
- `<durable-candidate>` is unchanged (HEAD equals the candidate head, porcelain empty).
- Both automated verifies of Tasks 1 and 2 exit 0 (run under sh).

Commit: skipped in the recovery checkout per D-23; the integration clone has no new commit yet.

## Deviations from Plan

**1. [Rule 3 - Blocking] g() splits its pinned arguments through command substitution.** The 190 helper relied on unquoted variable splitting, which fails under zsh (the shell the tool runs interactively). The 191 helper uses `$(printf '%s\n' "$VAR")` so it behaves the same in sh, bash and zsh. Self-test S08-S10 still pass.

**2. [Interpretation] "11 keys".** The snapshot has 11 lines only when packed refs and worktrees exist (the real recovery checkout has both). A repo without them prints `packed_refs absent` / `worktrees absent` variants; S01 builds a fixture with both so the exact 11-key shape is asserted.

**3. [Rule 2] Extra controls.** Added S20 (unsafe file type refused) and S21 (tracked volatile entry refused) beyond the 19 required.

**4. Locate in set-denylist mode** prints only `locate: denylist pointer set` (still regenerates env-191.sh), so the output holds a single label and no path.

**5. Commit ledger / plan_head fields.** No git write is allowed in the recovery checkout (the ledger file lives in its .git folder), and the plan makes no commit, so `commits: 0` is the legitimate docs/tooling value and the head fields are marked not recorded.

Ordering note: the root-pin guard (read-only `git rev-parse`) ran right after the recovery snapshot, not before it, as the dispatch instructions allowed.

## Known Stubs

None.

## Threat Flags

None. No new network endpoint or trust boundary beyond the plan's threat model.

## Self-Check: PASSED

Scripts (8) and evidence (4) files exist; clone head equals the recorded candidate head; verify commands exit 0.
