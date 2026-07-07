---
phase: 142-release-graph-governance-contract
reviewed: 2026-07-07T16:09:31Z
depth: standard
files_reviewed: 6
files_reviewed_list:
  - .github/workflows/release-please.yml
  - script/check_release_workflow_integrity.exs
  - test/crosswake/proof/phase142_release_integrity_test.exs
  - lib/crosswake/release_status.ex
  - lib/mix/tasks/crosswake.release.status.ex
  - test/mix/tasks/crosswake_release_status_test.exs
findings:
  critical: 3
  warning: 1
  info: 0
  total: 4
status: issues_found
---

# Phase 142: Code Review Report

**Reviewed:** 2026-07-07T16:09:31Z
**Depth:** standard
**Files Reviewed:** 6
**Status:** issues_found

## Summary

Reviewed the Phase 142 release workflow, semantic workflow scanner, proof tests, release-status model, Mix task, and status tests. The release workflow itself now has the intended gates, but the guards meant to keep it that way are still bypassable: they search for policy substrings in job text instead of validating job-level YAML semantics, and they do not prove companion clean-room proof jobs actually run after the matching publish jobs. ReleaseStatus mirrors several of those weak checks and also exposes downstream proof claims too strongly for Phase 142.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: Gate Checks Pass On Inline Comments Or Decoy Text

**Severity:** BLOCKER
**File:** `script/check_release_workflow_integrity.exs:64`

**Issue:** The scanner only strips full-line comments, then `path_gate/4` and `component_gates/1` accept any occurrence of the required gate text inside the job block (`script/check_release_workflow_integrity.exs:111`, `script/check_release_workflow_integrity.exs:229`). That means a broken job-level gate can still pass if the expected string appears in an inline comment, `run:` step, `name:`, or `env:` value. I verified a fixture where `publish-hex` used `if: ${{ false }} # contains(fromJSON(needs.release-please.outputs.paths_released), '.')`; the scanner still exited 0 and reported `release.root_hex.path_gate` OK. `Crosswake.ReleaseStatus` mirrors the same substring approach for governance identity gates (`lib/crosswake/release_status.ex:222`), so operator status can also report OK for the same broken workflow.

**Fix:** Parse the workflow YAML or, at minimum, extract job-level `if:` values after removing inline comments and block scalars, then compare the actual expression for each job. Add negative fixtures for inline-comment decoys and `run:`/`env:` decoys.

```elixir
defp job_if!(jobs, job) do
  jobs
  |> job_block(job)
  |> extract_job_level_key!("if")
end

defp path_gate(jobs, id, job, path) do
  expected = "${{ contains(fromJSON(needs.release-please.outputs.paths_released), '#{path}') }}"
  check(id, job_if!(jobs, job) == expected, "#{job} must gate on exact path #{path}")
end
```

### CR-02: Clean-Room Proof Jobs Can Be Skipped Or Run Before Publish And Still Pass

**Severity:** BLOCKER
**File:** `script/check_release_workflow_integrity.exs:182`

**Issue:** `cleanup_after_publish_and_proof/1` checks that `release-as-cleanup` lists proof jobs and checks their results, but the scanner never validates each `clean-room-proof-*` job's own `needs` or `if:` expression. `component_gates/1` only checks `publish-hex-*` jobs (`script/check_release_workflow_integrity.exs:229`). A fixture with `clean-room-proof-rulestead` changed to `if: ${{ false }}` passed the scanner. A fixture removing `publish-hex-rulestead` from that proof job's `needs` also passed. In those cases a companion can publish without a real post-publish clean-room proof, while the scanner and `release.governance_cleanup_after_proof` status still report OK (`lib/crosswake/release_status.ex:249`).

**Fix:** Add explicit proof-job checks for every companion: exact per-component release gate, `needs` containing both `release-please` and the matching publish job, and no aggregate `releases_created`. Do the same for native proof jobs with exact path gates and matching native publish needs.

```elixir
defp companion_proof_gates(jobs) do
  for component <- @components do
    block = job_block(jobs, "clean-room-proof-#{component}")

    check(
      "release.#{component}.proof_gate",
      includes?(block, "needs: [release-please, publish-hex-#{component}]") and
        job_if!(jobs, "clean-room-proof-#{component}") ==
          "${{ needs.release-please.outputs.#{component}_release_created == 'true' }}",
      "clean-room-proof-#{component} must run only after its matching publish job"
    )
  end
end
```

### CR-03: PR-Only Cleanup Check Misses Direct Main Push Forms

**Severity:** BLOCKER
**File:** `script/check_release_workflow_integrity.exs:212`

**Issue:** `cleanup_pr_only/1` rejects `git push origin main` and a few `*:main` forms, but it does not reject `git push origin HEAD:refs/heads/main`. Because the same check also only requires that a branch push and `gh pr create` are present somewhere in the block, a cleanup step can both open a PR and mutate `main` directly while the scanner reports `release.cleanup.pr_only` OK. I verified that adding `git push origin HEAD:refs/heads/main` after the existing branch push still exits 0. The test only covers the simple `git push origin main` replacement (`test/crosswake/proof/phase142_release_integrity_test.exs:123`), so this bypass is untested.

**Fix:** Treat any push target resolving to `main` as forbidden, including `refs/heads/main`, and add fixtures where direct-main mutation is added in addition to the expected PR branch flow.

```elixir
direct_main_push? =
  includes?(
    block,
    ~r/\bgit\s+push\s+\S+\s+(?:HEAD|"\$branch"|\$branch)?(?::(?:refs\/heads\/)?main)?(?:\s|$)/
  ) or includes?(block, ~r/\bgit\s+push\s+\S+\s+HEAD:refs\/heads\/main(?:\s|$)/)
```

## Warnings

### WR-01: ReleaseStatus Still Overclaims Weaker Or Downstream Checks

**Severity:** WARNING
**File:** `lib/crosswake/release_status.ex:162`

**Issue:** `release.workflow_path_gates` says "root/native publish jobs use paths_released gates", but the implementation checks only the root path gate (`lib/crosswake/release_status.ex:162`). Separately, `release.cleanroom_dependency_floor` reports that the clean-room harness derives package floors and exact companion versions (`lib/crosswake/release_status.ex:172`), but that is downstream PREF scope and is only proven by substring checks in `cleanroom_script_hardened?/1` (`lib/crosswake/release_status.ex:357`). The tests only refute literal downstream requirement IDs such as `PREF-01` (`test/mix/tasks/crosswake_release_status_test.exs:48`), so semantic overclaims can still ship as long as those IDs are absent.

**Fix:** Either remove/downscope downstream PREF/MIRR/STAT checks from Phase 142 status or render them as pending/downstream evidence, not OK release-governance checks. Align `release.workflow_path_gates` with the same core path list used by governance checks or retire it in favor of `release.governance_behavioral_identity_gates`. Add tests that fail on downstream semantic claims, not just downstream requirement IDs.

---

_Reviewed: 2026-07-07T16:09:31Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
