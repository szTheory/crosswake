---
phase: 122-drift-guards
plan: "03"
subsystem: ci-gates
status: complete
tags: [ci, github-actions, drift-guard, branch-protection, GUARD-02, GUARD-04]
completed_date: "2026-06-20"
duration: "2m"
tasks_completed: 2
files_changed: 2
requirements: [GUARD-02, GUARD-04]

dependency_graph:
  requires: [122-01]
  provides: [GUARD-02, GUARD-04]
  affects: [branch-protection, CI, contract-drift-gate]

tech_stack:
  added: []
  patterns:
    - "re-actors/alls-green aggregator topology (Option-C per D-09)"
    - "green-first preflight + granular required_status_checks PATCH (v12.0 idiom)"
    - "git add -A + git diff --cached --exit-code staged-diff gate (T-122-07 mitigation)"

key_files:
  created:
    - .github/workflows/contract-drift-gate.yml
    - script/register-contract-gate.sh
  modified: []

decisions:
  - "Purpose-named gate per domain (contract-drift-gate.yml) — NOT folded into offline-sync-e2e-gate.yml; matches D-09 v12.0 idiom"
  - "guard-02-generate-and-diff uses git add -A + git diff --cached --exit-code (never bare git diff --exit-code) to catch newly-emitted untracked generated files (T-122-07 mitigation)"
  - "OLD_CHECK is empty in register-contract-gate.sh (no prior check to drop — PATCH only appends, never removes existing required checks)"
  - "merge-blocking-contract-drift is the sole new required check; native-toolchain checks remain advisory (hermetic-vs-advisory split)"
  - "green-first preflight checks the aggregator job's conclusion, not a sibling job (D-11)"

metrics:
  duration: "2m"
  completed_date: "2026-06-20"
---

# Phase 122 Plan 03: Contract Drift Gate CI — GUARD-02 and GUARD-04

One-liner: Purpose-named contract-drift-gate.yml with two hermetic Elixir sibling jobs (drift test + staged generate-and-diff) under a single re-actors/alls-green aggregator, plus a green-first granular-PATCH registration script.

## What Was Built

### Task 1 — `.github/workflows/contract-drift-gate.yml` (commit b910ecd)

A new dedicated CI workflow named "Contract Drift Gate" (purpose-named per D-09). Contains three jobs:

**guard-01-contract-drift-test:** Runs the GUARD-01 ExUnit drift test file (`test/crosswake/contract/contract_drift_test.exs`) as its own isolated job so its red/green dot is purpose-named, not buried in a generic `mix test` result (D-10). Pure Elixir, no native toolchain. Pinned via `.tool-versions` / `version-type: strict` (erlang 27.3 / elixir 1.19.5-otp-27). MIX_ENV=test.

**guard-02-generate-and-diff:** Runs `mix crosswake.contract.gen` then stages all output with `git add -A` and gates on `git diff --cached --exit-code`. On failure emits a `::error::` annotation naming the fix command and shows `git diff --cached --stat`. MUST use `--cached` (not a bare `git diff --exit-code`) so newly-emitted untracked generated files are caught and cannot spuriously pass (T-122-07 mitigation). A code comment explicitly documents the gen task's sorted-key/write_if_changed determinism invariant so it is not accidentally removed.

**merge-blocking-contract-drift:** The sole new required check. Uses `re-actors/alls-green@release/v1` with `needs` both sibling jobs and `if: always()`. Neither sibling invokes Xcode or Gradle.

The workflow header documents the out-of-band registration ordering (merge → aggregator green on main → run registration script) and the equivalent `gh api` one-liner for auditability.

### Task 2 — `script/register-contract-gate.sh` (commit 03d62de)

A near-verbatim clone of `script/register-e2e-gate.sh` (v12.0 idiom) with these substitutions:

- `NEW_CHECK` defaults to `merge-blocking-contract-drift`
- `OLD_CHECK` is empty (no prior check to drop; `map(select(.context != $old))` is a no-op — the PATCH only appends, never removes existing required checks)
- Header comment documents that this is the sole new required check, native checks remain advisory

Preserved from the original:
- **Green-first preflight** (T-122-09 mitigation): refuses with `exit 2` until `merge-blocking-contract-drift` has at least one successful run on BRANCH. Checks the AGGREGATOR job's conclusion via `commits/${BRANCH}/check-runs`, not a sibling (D-11).
- **Granular PATCH endpoint** (`required_status_checks`, not full PUT `.../protection`): preserves `enforce_admins` and review requirements untouched (T-122-08 mitigation).
- **`unique_by(.context)`** for idempotency; reads live `strict` value.
- **`DRY_RUN=1`**: prints desired JSON and exits 0 without writing.
- Executable (`chmod +x`).
- Header documents maintainer-run / harness-blocked constraint — script + document, do NOT auto-toggle.

## Verification Results

Both verify commands pass:
- `contract-drift-gate.yml OK` (node verify script: all job names present, `git add -A`, `git diff --cached --exit-code`, `re-actors/alls-green`, no bare diff)
- `register-contract-gate.sh OK` (bash -n parses clean, all required patterns present, executable)

## Deviations from Plan

None — plan executed exactly as written.

## Threat Mitigations Delivered

| Threat ID | Mitigation |
|-----------|-----------|
| T-122-07 | guard-02 stages with git add -A then git diff --cached --exit-code; untracked generated outputs cannot pass spuriously |
| T-122-08 | granular required_status_checks PATCH endpoint only; enforce_admins/reviews untouched; maintainer-run/documented/not auto-toggled |
| T-122-09 | green-first preflight refuses (exit 2) until aggregator has gone green on main at least once |
| T-122-10 | both sibling jobs are pure-Elixir/hermetic (no Xcode/Gradle); native checks stay advisory |

## User Setup Item (out-of-band, human/maintainer step)

The branch-protection PATCH is harness-blocked in this environment. After `contract-drift-gate.yml` is merged and `merge-blocking-contract-drift` goes green on main:

```bash
script/register-contract-gate.sh
```

This is documented in the script header and the workflow's top-of-file comment block. Do NOT run it automatically or via the harness.

## Known Stubs

None.

## Threat Flags

None — no new network endpoints, auth paths, or schema changes introduced.

## Self-Check: PASSED

- `.github/workflows/contract-drift-gate.yml` exists: FOUND
- `script/register-contract-gate.sh` exists: FOUND
- Task 1 commit b910ecd: FOUND
- Task 2 commit 03d62de: FOUND
