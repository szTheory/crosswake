---
phase: 179
iteration: 2
findings_in_scope: 4
fixed: 4
skipped: 0
status: all_fixed
---

# Phase 179 — Follow-up Code Review Fixes

The review of `492eb79` confirmed the original eight findings fixed and identified CR-08 / WR-02 / WR-03 / WR-04. Its report is preserved as `179-REVIEW-SECOND.md`. All implementation below is in the qualified independent candidate. Final HEAD: `96e5a63efab657f89f3ac84d5b1d84ff5da5d822`; tree: `0514b6244ec814c1d0701d580b04651f70f57019`.

## Fixed Issues

### CR-08: [BLOCKER] Proof project migration can overwrite a concurrent host edit

**Commit:** `c76a13b`

Migration uses the generation/recovery lifecycle lock, rejects pending journal states, retains its preview input and re-reads it immediately before replacement. It verifies the staged temporary bytes too. A host edit or conflicting leftover temporary yields a bounded conflict and preserves the host edit and temporary evidence. The descriptor-safe read boundary returns bounded missing/unsafe/unsupported-project causes.

### WR-02: [WARNING] Version-1 proof recovery journals are accepted but cannot be recovered

**Commit:** `c76a13b`

Legacy journals recover only when the current file is the recorded prior state (including recorded absence). An unknown published value cannot be inferred without a desired snapshot; recovery returns the explicit legacy-reconciliation denial and preserves all evidence. Decoder errors never propagate raw journal content.

### WR-03: [WARNING] A crash between stage and pending writes leaves an unrecoverable proof update

**Commit:** `c76a13b`

Stage-only journals are recognized. Current bytes must match their recorded prior/desired state, and every next/restore temporary must match its recorded role before any restoration. Recognized temporaries are cleaned after restoration; foreign edits remain blocked and preserved. Generation, check and migration share the same interruption checks.

### WR-04: [WARNING] The caller timeout is shorter than the checker’s valid total runtime

**Commit:** `96e5a63`

The Mix caller passes one 150-second total budget to the checker and uses an absolute deadline with 30 seconds of shutdown grace. Each sequential Xcode query receives at most the remaining total budget; expired cells do not launch children and return an allowlisted timeout cause. The same budget is available through the existing checker CLI for the production caller; no host identity/config DSL is added.

## Verification and process evidence

- Qualified recovery fixture: **9 tests / 9 semantic failures** before production repair, then all passed. The first attempt failed in setup because the host directory was missing; those initial failures are not RED evidence. `04d1405` introduced tests and the valid Node RED; `641a008` qualifies the recovery fixture before the production fix.
- Four additional typed-boundary negatives failed before their error-shape correction: malformed journal, unsupported project, unsafe path and missing project. Their source bytes remain private; reports retain only causes/counts.
- Combined focused recovery, maintained proof, graph, managed-output, ledger and frozen-guard suites: **79 tests, 0 failures**.
- Pinned Node settings suite: **6 tests, 0 failures**, including actual manual/automatic matrices and reformatted variable-masked proof migration, plus the bounded slow-child deadline control. The deadline control failed before the deadline fix.
- Compilation with warnings as errors, formatting and Git whitespace checks passed. Ledger remains **235** with all prior **231** keys and **52** frozen guards preserved.

Final independent security/code re-audits and broad proof remain pending on this commit. Earlier missing-output unknowns and missing Plan03/CR06 test-first evidence remain disclosed; no retrospective cause or RED is claimed.
