# Phase 192: PR, CI and merge - Context

**Gathered:** 2026-10-23
**Status:** Ready for planning

<domain>
## Phase Boundary

Put the Phase 191 integration branch (`land/v25-v27` in `<integration-clone>`) on GitHub `main`. Steps: fix the three review warnings, rescan, push, open the PR to `main`, and get the one required check "Crosswake CI" green on the PR head. Then show the user the PR and its head commit and merge with a merge commit only after their plain-language `allow`. Finally, confirm that CI on `main` is green for the merge commit. Requirements: LAND-03 and LAND-04.

Out of bounds:
- package release and Hex publish;
- force push, protection bypass and `--admin` merge;
- any git operation in the recovery checkout, where planning files are edited as plain files only;
- deleting the trial branches, the clone or the recovery checkout, which belong to Phase 193.
</domain>

<decisions>
## Implementation Decisions

### Review warnings, fixed before the push (user choice: "Fix all 3 first")
- **D-01:** Before the push, one small commit on `land/v25-v27` fixes 191-REVIEW.md WR-01, WR-02 and WR-03:
  - **WR-01:** `test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs`. The C-locale ledger test must fail when the locale bug is present, so it can no longer pass vacuously.
  - **WR-02:** `test/crosswake/proof/phase170_vacuity_taxonomy_convention_test.exs`. A roster phase that is missing makes the test fail instead of being dropped silently.
  - **WR-03:** `scan-191.sh:197/201`. A git note that can't be read fails the scan instead of hitting `|| continue`.
- **D-02:** Locally, run only the affected tests plus the scanner self-test. Re-run the privacy scan on the new HEAD. PR CI is the full-suite judge, so `--all` is not re-run locally.
- **D-03:** IN-01 (loopback origins) and IN-02 (inline resolver copy) are not fixed here. They go to a follow-up after landing. Update 191-REVIEW-DISPOSITION.md: WR-01..03 become `fixed` with the commit, and IN-01/02 become `deferred`.

### Amendments recorded at plan-phase (orchestrator rulings, 2026-10-23)
- **D-01 amendment (plan-phase, 2026-10-23):** WR-03's fix lives in the planning scanner, so it reaches the branch through the single SYNC-2 sync commit (D-05 ordering, R-2); WR-01 and WR-02 are the one small LAND-FIX code commit. Content of D-01 is unchanged; only the commit count is two.
- **D-02 amendment (plan-phase, 2026-10-23):** the single full finalize-191.sh run that creates SYNC-2 runs its root and planning suite stages; that is the D-05 sync gate, not a discretionary local --all. LAND-FIX still runs only its affected tests plus the scanner self-test.

### Carried forward (already decided, do not re-ask)
- **D-04 (191 D-03):** merge with a merge commit, never squash or rebase-merge. No force push.
- **D-05 (191 D-22):** the push step refuses unless the recorded scan HEAD equals the push HEAD and the scan exited 0. Any new commit means a rescan. First run `finalize-191.sh` to land the post-sync planning records, then fix, then scan, then push.
- **D-06 (AGENTS.md):** if CI is red, fix forward on the branch autonomously: new commit, rescan, then push the update. Keep retries tied to the observed cause. When delivery is uncertain, read and reconcile before writing again. Ask the user only for missing credentials, an external approval, or work outside scope.
- **D-07 (LAND-04):** the merge gate shows the PR URL and the head commit in plain language. The user's `allow` or `hold` binds internally to that head only. If the head changes after `allow`, the approval is void and the user is asked again. The user never copies hashes.
- **D-08 (178 D-18/D-23):** PR CI tests GitHub's synthetic merge commit. Record which commit each check actually ran on, and don't call the PR head "merged main".

### Claude's Discretion
- PR title and description: plain language, listing the commit groups (candidate, fixes, carries, sync) and linking 191-VERIFICATION.md.
- How CI is polled and how the evidence files under `192-EVIDENCE/` are laid out.
</decisions>

<canonical_refs>
## Canonical References

- `.planning/workstreams/quality-ratchet-release/ROADMAP.md`: Phase 192 goal and success criteria
- `.planning/workstreams/quality-ratchet-release/REQUIREMENTS.md`: LAND-03, LAND-04
- `.planning/workstreams/quality-ratchet-release/phases/191-integration-branch-and-local-suite/191-CONTEXT.md`: D-03, D-20, D-22, D-23
- `.planning/workstreams/quality-ratchet-release/phases/191-integration-branch-and-local-suite/191-REVIEW.md`: WR-01..03 details
- `.planning/workstreams/quality-ratchet-release/phases/191-integration-branch-and-local-suite/191-REVIEW-DISPOSITION.md`
- `.planning/workstreams/quality-ratchet-release/phases/191-integration-branch-and-local-suite/191-VERIFICATION.md`
- `.planning/workstreams/quality-ratchet-release/phases/191-integration-branch-and-local-suite/scripts/`: `locate-191.sh`, `finalize-191.sh`, `scan-191.sh`, pinned git helper
- `.planning/workstreams/quality-ratchet-release/phases/178-clean-checkout-and-final-ci/178-CONTEXT.md`: D-17/D-18/D-23 (synthetic merge commit identity)
- `AGENTS.md`: approval-gate and standing-authorization rules
</canonical_refs>

<code_context>
## Existing Code Insights

- The integration clone is located only through `scripts/locate-191.sh`. Never record its absolute path; write `<integration-clone>`.
- All git work in the clone goes through the pinned `g()` helper.
- The 191 head is SYNC 98e0d390, 112 commits ahead of main d0dbdf7b.
- The trial branches `carry-trial*` and `candidate-src` exist in the clone. Never push them.
</code_context>

<deferred>
## Deferred Ideas

- IN-01: `usable_activation_origin?/1` accepts loopback origins. A follow-up after landing.
- IN-02: the inline copy of the evidence-path resolver can drift. A follow-up after landing.
</deferred>
