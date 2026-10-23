---
phase: 191-integration-branch-and-local-suite
reviewed: 2026-10-23T00:00:00Z
depth: standard
files_reviewed: 27
files_reviewed_list:
  - test/crosswake/guides/native_shell_upgrade_test.exs
  - script/inventory_collection_assertions.exs
  - test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs
  - script/collection_assertion_ledger.json
  - test/crosswake/proof/phase180_twin_feasibility_test.exs
  - examples/phoenix_host/config/config.exs
  - test/crosswake/shell/ios_host_config_test.exs
  - examples/phoenix_host/test/crosswake_example/phase180_twin_feasibility_test.exs
  - packages/crosswake-shell-core-ios/Tests/CrosswakeShellCoreTests/Phase180TwinFeasibilityTests.swift
  - lib/crosswake/proof_lane/physical_iphone_preflight.ex
  - lib/crosswake/shell/ios_host_origin_mode.ex
  - test/mix/tasks/crosswake.proof_lane.physical_iphone_test.exs
  - lib/mix/tasks/crosswake.proof_lane.verify_twin.ex
  - test/mix/tasks/crosswake_proof_lane_verify_twin_test.exs
  - test/crosswake/proof_lane/provenance_test.exs
  - lib/crosswake/planning/first_adopter_context.ex
  - test/crosswake/planning/first_adopter_context_test.exs
  - script/check_release_workflow_integrity.exs
  - test/crosswake/proof/phase170_vacuity_taxonomy_convention_test.exs
  - test/crosswake/proof/phase174_cleanroom_host_realism_test.exs
  - test/crosswake/proof/phase174_cleanroom_lane_parity_test.exs
  - test/crosswake/proof/phase174_companion_findings_test.exs
  - test/crosswake/proof/phase175_runbook_ancestry_test.exs
  - test/mix/tasks/crosswake_doctor_router_test.exs
  - .planning/workstreams/quality-ratchet-release/phases/191-integration-branch-and-local-suite/scripts/scan-191.sh
  - .planning/workstreams/quality-ratchet-release/phases/191-integration-branch-and-local-suite/scripts/suite-gate-191.sh
  - .planning/workstreams/quality-ratchet-release/phases/191-integration-branch-and-local-suite/scripts/carry-191.sh
findings:
  critical: 0
  warning: 3
  info: 2
  total: 5
status: issues_found
---

# Phase 191: Code Review Report

**Reviewed:** 2026-10-23
**Depth:** standard
**Files Reviewed:** 27 (12 code commits in `<integration-clone>`; the phase scripts were only grepped for fail-open patterns, not read line by line)
**Status:** issues_found

## Summary

No bugs in the production changes. The preflight origin check, the twin stop annotations, the adoption-scan extensions, the example host path change and the privacy substitutions all trace correctly. The weaknesses are in the new tests and one scan helper, where a check can pass without asserting what it claims to. That is this project's recurring defect.

## Warnings

### WR-01: Locale-independence test does not detect the bug it was added for

**File:** `test/crosswake/proof/phase170_vacuous_assertion_ledger_test.exs` (new "D-12 locale independence" test, about line 484)
**Issue:** The test runs `--emit-snapshot` under the C locale and asserts only exit code 0 and that `JSON.decode(output)` returns `{:ok, %{"rows" => _}}`. Before the fix, `IO.write` in the C locale escaped non-ASCII text. Escaped output is still valid JSON, so this test can pass on the unfixed code. It also never compares against the committed ledger bytes, which is what the gate actually checks.
**Fix:** Assert the property that failed. Either compare `output` byte for byte with a UTF-8-locale run, or assert that decoded rationale text contains a known non-ASCII character from the committed ledger.
```elixir
assert String.valid?(output)
assert output =~ "—"   # or any non-ASCII character present in the committed ledger
```
Also, `emit_bytes/1` in `script/inventory_collection_assertions.exs` ignores the return of `:io.setopts/2`. Pattern-match it with `:ok = ...` so an unsupported device fails loudly.

### WR-02: Vacuity-convention test silently drops missing roster phases

**File:** `test/crosswake/proof/phase170_vacuity_taxonomy_convention_test.exs` (`phase_dirs_with_verification/0`, and the findings-floor test)
**Issue:** The roster is a closed list of 7 phases, but `Enum.filter(&File.dir?/1)` quietly removes any phase that resolves to nothing, and the floor only requires `>= 1` examined directory. If 6 of 7 phase folders vanish, the test still passes while examining almost nothing. The added `assert length(@v23_phases) == 7` checks a literal list against its own length and proves nothing.
**Fix:** Assert that every roster entry resolves to a directory, then drop the tautology.
```elixir
dirs = Enum.map(@v23_phases, &Crosswake.Test.PhaseEvidencePath.resolve(@workstream, &1))
assert Enum.all?(dirs, &File.dir?/1)
```
Keep the "has a VERIFICATION.md" filter only for the examined subset, and assert the expected examined count.

### WR-03: Privacy scanner skips unreadable git notes without failing

**File:** `.planning/workstreams/quality-ratchet-release/phases/191-integration-branch-and-local-suite/scripts/scan-191.sh:201` (also `:197`)
**Issue:** Every other read in the scanner ends in `|| fail ...` (exit 2, never a clean pass). The notes path does not. `cat-file blob "$no" ... || continue` skips an unreadable note body, and `notes list ... || : > notes.ref` treats a failed listing as no notes. A note that cannot be read is therefore never scanned and the scan can still report clean.
**Fix:** Distinguish "no notes ref" from a failure. Use `fail "cat-file failed"` for the `cat-file` on line 201. For line 197, check `git rev-parse --verify --quiet refs/notes/commits` first and `fail` only when notes exist and the listing errors.

## Info

### IN-01: `usable_activation_origin?/1` accepts any well-formed http(s) origin

**File:** `lib/crosswake/shell/ios_host_origin_mode.ex:~190`
**Issue:** The helper returns true for loopback hosts and for origins carrying a path or query, because `canonical_origin/1` only normalizes scheme, host and port. This is correct only if `origin_refusal/1` rejects loopback separately, as the commit message implies. I did not trace that ordering. Confirm it, and ideally add a test with a loopback origin in `route_activation.json` under a production declaration.
**Fix:** Add the loopback case to `@unusable_activation_bodies` or to a sibling test.

### IN-02: Inline copy of the evidence-path resolver can drift

**File:** `script/check_release_workflow_integrity.exs:~1673`
**Issue:** `resolve_phase_evidence/2` duplicates `Crosswake.Test.PhaseEvidencePath.resolve/2` because `test/support` is not loaded by the script. Nothing ties the two together, so a future change to one will not reach the other.
**Fix:** Add a one-line test that runs both against the same fixture layout and asserts equal results, or move the resolver into a shared file that both can load.

---

_Reviewed: 2026-10-23_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
