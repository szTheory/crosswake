---
phase: "168"
slug: "0-2-1-release-candidate-readiness"
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-09-12"
---

# Phase 168 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit on pinned Elixir, Node built-in test runner, shell syntax checks, `actionlint`, and the existing structural release scanner |
| **Config file** | `mix.exs`, `test/test_helper.exs`, `.github/workflows/crosswake-ci.yml` |
| **Quick run command** | `mix test test/crosswake/release_candidate test/mix/tasks/crosswake_release_candidate_test.exs` |
| **Full suite command** | `bash script/verify_repository.sh --all` |
| **Estimated runtime** | Established during Wave 0; phase evidence records the bounded runtime |

---

## Sampling Rate

- **After every task commit:** Run the narrow ExUnit, Node, script, or workflow check for the touched seam.
- **After every plan wave:** Run the release-candidate ExUnit set, Phase 167 Node fixtures, release workflow integrity scanner, and relevant shell/workflow linters.
- **Before `$gsd-verify-work`:** `bash script/verify_repository.sh --all`, the exact-head candidate workflow, and the credentialed mirror dry-run must be green without public mutation.
- **Max feedback latency:** Keep task-local checks narrow; record observed latency during Wave 0 rather than inventing a bound before the exact toolchain is restored.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 168-TBD-REL01 | TBD | TBD | REL-01 | T-168-04 / T-168-05 | Candidate payload paths stay isolated and each companion lane proves a non-vacuous positive and negative contract | integration + fixture | `mix test test/crosswake/release_candidate/cleanroom_test.exs` | ❌ W0 | ⬜ pending |
| 168-TBD-REL02 | TBD | TBD | REL-02 | T-168-03 / T-168-06 | Mirror state is complete, credential use is explicit, normal publication is fast-forward-only, and recovery authority stays separate | unit + script integration | `mix test test/crosswake/release_candidate/mirror_test.exs` | ❌ W0 | ⬜ pending |
| 168-TBD-REL03 | TBD | TBD | REL-03 | T-168-01 / T-168-04 | Linked coordinates, independent companion floors, package metadata, SwiftPM, Gradle, and workflow declarations cannot drift silently | unit + structural | `mix test test/crosswake/release_candidate/coordinate_test.exs && elixir script/check_release_workflow_integrity.exs` | ❌ W0 (candidate test); scanner exists | ⬜ pending |
| 168-TBD-REL04 | TBD | TBD | REL-04 | T-168-01 / T-168-02 / T-168-05 | Exact candidate identity is immutable, deterministic, payload-bound, and privacy-safe; changed inputs yield `STALE` | unit + integration | `mix test test/crosswake/release_candidate test/mix/tasks/crosswake_release_candidate_test.exs` | ❌ W0 | ⬜ pending |
| 168-TBD-REL05 | TBD | TBD | REL-05 | T-168-01 / T-168-06 / T-168-07 | No preapproval mutation occurs; one exact approval gates linked publication; partial public state remains explicit and recoverable | unit + workflow structural | `actionlint .github/workflows/release-please.yml .github/workflows/ios-mirror-backfill.yml .github/workflows/crosswake-ci.yml && elixir script/check_release_workflow_integrity.exs` | Existing tools; ❌ new fixtures | ⬜ pending |
| 168-TBD-PREREQ | TBD | 0 | D-01, D-02 | T-168-01 / T-168-03 | The five Phase 167 blobs and the complete PR-comment connection are exact before candidate authority is consumed | Node/Python fixture | `node --test test/js/phase167_pr_dispositions.test.mjs` | ✅ base suite; ❌ pagination fixtures | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Restore the exact pinned Erlang `27.3` / Elixir `1.19.5-otp-27` execution environment before using local Mix output as evidence.
- [ ] Restore or regenerate `.planning/workstreams/quality-ratchet-release/milestone.lock`, or correct its canonical path, so the existing Phase 167 Node suite no longer fails with `ENOENT`.
- [ ] Add cursor-complete pagination fixtures covering more than 100 comments, missing/invalid/non-advancing cursors, and page-fetch errors.
- [ ] Add canonical candidate-receipt fixtures covering every D-04 identity mutation and privacy canaries.
- [ ] Add candidate-local Hex tarball fixtures covering metadata, file lists, checksums, floors, path escape, and public-vs-candidate digest controls.
- [ ] Add four-mode mirror fixtures covering exact baseline, unreachable/conflicting refs, ancestry, dry-run permission, atomic-push support, and recovery-only lease behavior.
- [ ] Add five clean-room profile fixtures with two-install isolation and a deliberate negative control per lane.
- [ ] Extend the existing CI leaf/ownership manifests and release workflow scanner; do not add a separate workflow family.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Merge the refreshed, fully receipt-bound Release Please PR #57 head | REL-05 | This is the single irreversible maintainer approval for the linked 0.2.1 release unit | Review the deterministic candidate dossier in `READY FOR APPROVAL`, confirm the exact head/tree/base and zero preapproval mutations, then explicitly approve the exact-head merge once |

All credentials and external approvals remain bounded setup or trust actions. Automated assertions evaluate mirror authority, candidate identity, package proofs, publication results, and evidence integrity.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency is measured and bounded in execution evidence
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
