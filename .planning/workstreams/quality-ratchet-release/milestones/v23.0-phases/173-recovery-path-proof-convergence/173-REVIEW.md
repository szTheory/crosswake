---
phase: 173-recovery-path-proof-convergence
reviewed: 2026-09-25T16:23:42Z
depth: standard
files_reviewed: 8
files_reviewed_list:
  - script/write_publication_record.sh
  - script/assert_publication_record.sh
  - script/append_release_ledger.sh
  - .github/workflows/exact-public-proof.yml
  - .github/workflows/release-please.yml
  - .github/workflows/hex-publish.yml
  - script/check_release_workflow_integrity.exs
  - test/crosswake/proof/phase173_recovery_proof_convergence_test.exs
findings:
  critical: 0
  warning: 0
  info: 1
  total: 1
status: clean
---

# Phase 173: Code Review Report

**Reviewed:** 2026-09-25T16:23:42Z  
**Depth:** standard  
**Files reviewed:** 8  
**Status:** clean

## Summary

The publication record is emitted by one shared script and checked against trusted workflow inputs. Both callers retain `actions: read`, and both invoke the same reusable workflow. The job runs with `always()` and the record assertion is a failing step, so an absent artifact cannot turn into a skipped proof. The durable ledger writes all outcomes through a pull-request path. The credential-free fire drill points at the same proof body and has no publish dependency or registry credential.

The focused Phase 173 suite passed 65 tests. `actionlint` passed for the three involved workflows; the integrity scanner emitted 79/79 checks with 0 failures. The full suite had 5 failures associated with the current uncommitted Phase 175 worktree; those failures are recorded in `173-VERIFICATION.md` and were not changed here.

## Findings

### Info — applicability failures are outside the release ledger's current coverage

**Files:** `.github/workflows/exact-public-proof.yml`, `173-NON-VACUITY.md`  
**Observation:** If the applicability step fails before it emits `applicable=true`, the downstream `record-ledger` job does not write a row. This bounds ledger coverage for malformed recovery inputs. The limitation is already explicitly documented as WINDOWS entry #34, and the phase makes no claim that the ledger records this failure shape. It does not weaken the exact-public proof's fail-closed behavior or the Phase 173 success criteria.  
**Disposition:** Accepted as a documented, out-of-scope limitation; no change required for this phase.

## Checks

- `mix test ...publication_record_test.exs ...release_ledger_test.exs ...workflow_test.exs ...phase173_recovery_proof_convergence_test.exs --max-cases 1` — 65 tests, 0 failures.
- `actionlint .github/workflows/exact-public-proof.yml .github/workflows/release-please.yml .github/workflows/hex-publish.yml` — passed.
- `elixir script/check_release_workflow_integrity.exs` — 79/79 checks emitted, 0 failed.
- `mix format --check-formatted` — passed.
