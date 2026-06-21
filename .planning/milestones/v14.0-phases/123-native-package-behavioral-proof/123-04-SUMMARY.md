---
phase: 123-native-package-behavioral-proof
plan: "04"
subsystem: ci-gate
tags: [ci, github-actions, native, android, ios, branch-protection, ntest-04]
dependency_graph:
  requires: ["123-02", "123-03"]
  provides: ["native-behavioral-proof-ci-gate", "register-native-gate-script"]
  affects: ["branch-protection-required-checks"]
tech_stack:
  added: ["re-actors/alls-green@release/v1 (aggregator)", "register-native-gate.sh"]
  patterns: ["alls-green aggregator", "green-first registration guard", "granular PATCH endpoint"]
key_files:
  created:
    - .github/workflows/native-behavioral-proof-gate.yml
    - script/register-native-gate.sh
  modified: []
decisions:
  - "android-package-unit is merge-blocking (JVM hermetic); ios-package-unit is advisory (macOS Xcode native toolchain) — D-07 topology enforced"
  - "merge-blocking-native-behavioral-proof aggregator needs ONLY android-package-unit; iOS NOT in needs: — advisory split locked"
  - "register-native-gate.sh is a near-verbatim clone of register-contract-gate.sh with three substitutions: NEW_CHECK default, header comments, final echo"
  - "branch-protection PATCH is human/harness-gated per D-08 and v12.0 pattern; script documents and refuses to run without green aggregator on main"
metrics:
  duration: "2m"
  completed: "2026-06-20"
  tasks_completed: 2
  files_created: 2
status: complete
---

# Phase 123 Plan 04: Native Behavioral Proof CI Gate Summary

**One-liner:** Android-blocking + iOS-advisory CI gate with alls-green aggregator and green-first registration script for the native behavioral proof lane (NTEST-04).

## What Was Built

### Task 1: `.github/workflows/native-behavioral-proof-gate.yml` (commit `06e7e88`)

Three-job CI workflow mirroring the Phase-122 `contract-drift-gate.yml` topology (D-07):

| Job | Runner | Command | Status |
|-----|--------|---------|--------|
| `android-package-unit` | ubuntu-latest | `./gradlew test` in `packages/crosswake-shell-core-android` | **MERGE-BLOCKING** |
| `ios-package-unit` | macos-latest | `swift test` in `packages/crosswake-shell-core-ios` | Advisory — NOT in aggregator `needs:` |
| `merge-blocking-native-behavioral-proof` | ubuntu-latest | `re-actors/alls-green@release/v1` | **SOLE new required check** |

The aggregator's `needs:` contains ONLY `android-package-unit`. The iOS lane is deliberately excluded from the aggregator, overriding NATIVE-TESTING.md §10 (which incorrectly wanted iOS merge-blocking) — D-07 and the roadmap are authoritative on the hermetic-vs-advisory split. This override is noted in the workflow header comment.

Cache keys: Gradle keyed on `build.gradle.kts`; Swift keyed on `Package.swift`. No `erlef/setup-beam` (Gradle uses Java 17 from the ubuntu-latest runner). Permissions: `contents: read` only (T-123-13 mitigation, copied verbatim from `contract-drift-gate.yml`).

### Task 2: `script/register-native-gate.sh` (commit `5e907be`)

Near-verbatim clone of `script/register-contract-gate.sh` with three changes only:

1. `NEW_CHECK` default: `merge-blocking-native-behavioral-proof` (was `merge-blocking-contract-drift`)
2. Header comments reference `native-behavioral-proof-gate.yml` and NTEST-04 (instead of `contract-drift-gate.yml` and GUARD-02/04)
3. Final `echo` message references the new check name

All logic preserved verbatim:
- **Green-first preflight (T-123-11 mitigation):** Checks `merge-blocking-native-behavioral-proof` conclusion on `main`; exits 2 with `REFUSING (exit 2)` until the aggregator has gone green at least once. Prevents the "Expected — Waiting for status" deadlock.
- **Granular endpoint (T-123-10 mitigation):** Uses `repos/{repo}/branches/{branch}/protection/required_status_checks` — NOT the full `PUT .../protection` — so `enforce_admins` and review requirements are untouched.
- **Append-only:** `OLD_CHECK` is empty; `map(select(.context != $old))` is a no-op; `unique_by(.context)` ensures idempotency.
- **DRY_RUN=1:** Prints desired payload and exits 0 without writing.
- **Does NOT auto-toggle branch protection:** Script + documents the PATCH; the maintainer must run it out-of-band (D-08, v12.0 pattern).

Script is executable (`-rwxr-xr-x`).

### Task 3: Branch-Protection Registration (HUMAN-GATED — NOT APPLIED)

The actual `gh api -X PATCH` to register `merge-blocking-native-behavioral-proof` as a required status check is **human/harness-gated** per D-08 and the v12.0 pattern. It was NOT automated. See the checkpoint section below for exact steps.

**Status: Documented — PATCH not yet applied (correct; harness-blocked, matching Phase 122 `register-contract-gate.sh` pattern).**

## Deviations from Plan

None — plan executed exactly as written. The PATTERNS.md and CONTEXT.md were authoritative and the three-change substitution list was applied verbatim.

## Known Stubs

None.

## Threat Flags

No new threat surface beyond what was documented in the plan's `<threat_model>`. The workflow uses `contents: read` only; the registration script uses the granular `required_status_checks` endpoint.

## Human-Gated Registration (Branch Protection)

**After this plan's PR is merged and `merge-blocking-native-behavioral-proof` has gone green on `main` at least once:**

```bash
# Step 1: Review the desired payload (dry run)
DRY_RUN=1 script/register-native-gate.sh

# Step 2: Apply the registration (will refuse with exit 2 if aggregator not yet green)
script/register-native-gate.sh

# Step 3: Verify
gh api repos/szTheory/crosswake/branches/main/protection/required_status_checks | jq '{strict, checks}'
```

If the harness blocks the PATCH (historical constraint), the script and documentation are the deliverable — carry forward as a documented manual step matching the Phase 122 `register-contract-gate.sh` carried item.

## Self-Check

Files created:
- `.github/workflows/native-behavioral-proof-gate.yml` — present
- `script/register-native-gate.sh` — present, executable

Commits:
- `06e7e88` — `feat(123-04): add native-behavioral-proof-gate.yml CI gate`
- `5e907be` — `feat(123-04): add register-native-gate.sh registration script`
