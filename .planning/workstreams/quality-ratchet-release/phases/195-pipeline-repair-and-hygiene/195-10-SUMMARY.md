---
phase: 195-pipeline-repair-and-hygiene
plan: 10
subsystem: repo-hygiene
tags: [hygiene, root-allowlist, guard, setup-guide, privacy]
requires:
  - phase: 195-09
    provides: PR2 landed, canary green on main
provides:
  - "test/crosswake/repository_root_allowlist_test.exs: merge-blocking delta-only root allowlist and .bundle guard"
  - "13 root scratch files and crosswake-checkpoint-24c8389.bundle no longer tracked"
  - "SETUP.md moved to docs/SETUP.md with personal contact details removed"
affects: [195-11, 195-12]
requirements-completed: [HYG-01]
actuals:
  tokens: 40000
  tasks: 2
  commits: 3
  plan_head_before: 0b28e6d69767045bbd37c737068bd84c77ba86d4
  plan_head_after: 6c9fa4b5b9148eb25b6003c965a961dc608ab2cc
completed: 2026-10-26
status: complete
---

# Phase 195 Plan 10: Root hygiene and root allowlist guard Summary

**The repository root now carries 15 allowlisted files; a root-allowlist test, proven red at HEAD (14 findings) and proven to fail on a live scratch root file and a live `.bundle`, keeps it that way.**

Branch `chore/root-hygiene-and-cleanroom` (local only, nothing pushed). Commits: f3e83c74 (carried plan 09 evidence), 1e4beb4c (removals plus guard), 6c9fa4b5 (SETUP.md move). `commits: 3` is measured from origin/main 0b28e6d.

## Results

- Bundle provenance: `git bundle verify` rc 0, 1 head (24c8389), `on_origin_main yes`, `bundle: heads 1 on_origin_main 1`. The `git rm` gate command exited 0 before removal. The bundle string stays in `@known_excluded_binary_paths` in first_adopter_context.ex (count 1).
- Reference check: none of the 13 scratch files is referenced outside itself (`git grep` outside .planning); gen_manifest.exs kept (read by the phase69 test) and allowlisted with that reason.
- Guard: RED at HEAD rc 2 with exactly 14 violations (13 scratch files plus bundle); green after removal rc 0. Class `delta_only_blocking`, findings_on_origin_main 14, findings_on_branch 0.
- Live controls: intent-to-add `zz-root-control.txt` gave rc 2 and the log named it; intent-to-add `docs/zz-control.bundle` gave rc 2 and the log named it; clean rerun rc 0. Controls removed, tree clean.
- Floor: the live test asserts `>= 10` root entries. Root entries 15 equals allowlist entries 15.
- docs/SETUP.md: 4 email-shaped occurrences/lines removed (count only), no email-shaped string remains, relative links none to fix, privacy-193.sh rc 0. Root references to SETUP.md in `script/ci_docs_allowlist.json` and the two phase165 tests dropped.
- Verification: `mix test test/crosswake/planning test/crosswake/proof/phase69_docs_contract_parity_test.exs` rc 0; full `mix test` rc 0 (2776 tests, 0 failures, 75 excluded); `mix crosswake.docs.sync --check` rc 0; `elixir script/inventory_collection_assertions.exs --check` rc 0 (243 sites). Privacy scan on all changed content files rc 0.

## Deviations from Plan

**1. [Rule 3 - Blocking] Collection-assertion ledger regenerated.** Removing the `"SETUP.md"` line from phase165_ci_policy_test.exs shifted two classified sites by one line (:127 -> :126, :153 -> :152), failing 4 Phase170 ledger tests in the first full run. Ran `--emit-snapshot` and committed script/collection_assertion_ledger.json (2 rows, line numbers and rationale line references only); full suite then rc 0. Committed in 6c9fa4b5.

**2. [Rule 1 - Bug] Privacy scan hit on docs/SETUP.md.** The `pem file` pattern matched a literal PGP private key block header in a comment (line 120). Reworded the comment to describe the BEGIN/END lines without the literal header; scan then rc 0.

**3.** A first `git add` in Task 2 failed on the already-moved `SETUP.md` pathspec, so the commit was initially made with only the rename staged; amended (local, unpushed) to include the rest. No effect on the result.

## Known Stubs

None.

## Threat Flags

None.

## Self-Check: PASSED

Created/moved files exist, commits f3e83c74, 1e4beb4c, 6c9fa4b5 are ancestors of HEAD, both task verify blocks exit 0.
