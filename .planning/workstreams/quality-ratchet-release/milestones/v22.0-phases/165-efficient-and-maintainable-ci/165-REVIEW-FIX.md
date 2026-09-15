---
phase: 165-efficient-and-maintainable-ci
fixed_at: 2026-09-09T03:20:30Z
review_path: .planning/workstreams/quality-ratchet-release/phases/165-efficient-and-maintainable-ci/165-REVIEW.md
iteration: 3
findings_in_scope: 6
fixed: 6
skipped: 0
status: all_fixed
---

# Phase 165: Code Review Fix Report

**Fixed at:** 2026-09-09T03:20:30Z
**Source review:** `.planning/workstreams/quality-ratchet-release/phases/165-efficient-and-maintainable-ci/165-REVIEW.md`
**Iteration:** 3 — hosted CI repair for PR #144 run 34305234660

**Summary:**

- Findings in scope: 6
- Fixed: 6
- Skipped: 0

## Fixed Issues

### HCI-01: Adoption scan rejected the UI-review ignore policy

**Files modified:** `lib/crosswake/planning/first_adopter_context.ex`, `test/crosswake/planning/first_adopter_context_test.exs`
**Commit:** 2cffabda
**Applied fix:** Nested `.gitignore` files are now classified as durable scannable text, including `.planning/ui-reviews/.gitignore`. The regression test proves the exact path is discovered and remains subject to private-term scanning; unknown binary paths continue to fail closed.

### HCI-02: Phase 135 registration proof asserted the retired jq implementation

**Files modified:** `test/crosswake/proof/phase135_ci_ops_proof_test.exs`
**Commit:** 6127ca71
**Applied fix:** SC5 now asserts the current idempotency contract: fail-closed normalization plus exact post-write semantic equality, rather than the retired `unique_by(.context)` implementation detail.

### HCI-03: Phase 153 parity proof required a stale checkout version comment

**Files modified:** `test/crosswake/proof/phase153_ios_mirror_unblock_test.exs`
**Commit:** 6127ca71
**Applied fix:** The parity proof retains the reviewed immutable checkout SHA and now checks its correct `v6.0.2` annotation.

### HCI-04: Mutable-action audit depended on hosted ripgrep availability

**Files modified:** `scripts/ci_monitor.cjs`, `test/crosswake/proof/phase165_ci_policy_test.exs`
**Commits:** 6127ca71, 8182d750, bccbdf87
**Applied fix:** `check-actions` now scans its explicit required-path inputs with Node's standard library, preserving exact SHA enforcement without an undeclared `rg` dependency. Positive and mutable-ref negatives prove the audit remains fail closed, and a fake failing `rg` proves it is never invoked.

### HCI-05: Registered-without-producer fixture omitted app-bound response fields

**Files modified:** `test/crosswake/proof/phase153_1_gate_integrity_test.exs`
**Commit:** 6127ca71
**Applied fix:** The temporary repository now includes the shared normalizer, and the negative response fixture supplies realistic `app_id` records with exact mirrored `contexts` before exercising the missing-producer failure.

### HCI-06: Missing-registration fixture was invalid before reaching its intended assertion

**Files modified:** `test/crosswake/proof/phase153_1_gate_integrity_test.exs`
**Commit:** 6127ca71
**Applied fix:** The negative uses a strict, app-bound, exactly mirrored registered context so the checker reaches and proves the intended local-producer-not-required failure.

## Verification

The focused tests and Phase 165 aggregate gate passed in the isolated repair worktree. The committed tree was then reverified in the main checkout after the transactional fast-forward.

- Exact failed-test set: 75 tests, 0 failures
- `mix crosswake.adoption_context.scan` — passed in the isolated clean worktree, including the tracked `.planning/ui-reviews/.gitignore`
- `script/check_phase165_efficient_ci.sh` — passed in both the isolated worktree and main checkout
- Hosted PR rerun `34306906783` — completed successfully, including all 44 proof leaves and sole `Crosswake CI` umbrella
- Phase 165 manifest self-test — exact 44 proof leaves passed; no compatibility-only authority was introduced
- Immutable action audit — 100 action uses, 0 mutable third-party references
- Required-check response normalization — strict exact mirrors and app-bound records passed; fail-closed negatives remained intact
- `node -c scripts/ci_monitor.cjs`, shell syntax checks, formatter, and `git diff --check` — passed
- Main-checkout adoption scan was not used as evidence because preserved unrelated `script/__pycache__/` runtime files are intentionally unclassified; no unrelated runtime files were removed or altered
- External branch protection and merge state were not mutated

---

_Fixed: 2026-09-09T03:20:30Z_
_Fixer: the agent (gsd-code-fixer)_
_Iteration: 3_
