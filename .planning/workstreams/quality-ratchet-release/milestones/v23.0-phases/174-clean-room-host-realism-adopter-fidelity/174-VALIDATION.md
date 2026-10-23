---
phase: "174"
slug: "clean-room-host-realism-adopter-fidelity"
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-09-25"
---

# Phase 174 — Validation Strategy

> Reconstructed after execution. All 18 plan tasks include automated verification; no human-only
> behavior remains for this infrastructure phase.

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit / Mix and Node.js built-in `node:test` |
| **Config file** | `mix.exs`; root `package.json` |
| **Quick run command** | `mix test test/crosswake/proof/phase174_matrix_install_order_test.exs --max-cases 1` |
| **Full suite command** | `npm test` plus the phase's focused ExUnit suites and shell contract guard |
| **Estimated runtime** | ~30 seconds for `npm test`; clean-room matrix evidence is an invocation-owned artifact proof taking several minutes |

## Sampling Rate

- **After every task commit:** Run the task's automated verification block. The main `.git` was
  read-only in this session, so no main-repository task commits were created.
- **After every plan wave:** Run focused Phase 174 ExUnit tests and the unchanged doctor contract guard.
- **Before `$gsd-verify-work`:** Full JavaScript regression and phase verification must be green.
- **Max feedback latency:** ~30 seconds for repository tests; the clean-room proof is intentionally longer.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 174-01-01 | 01 | 1 | ROOM-01/02/04 | T-174-01..05 | Doctor remains unchanged; literal marker roster | integration | `bash script/verify_companion_cleanroom.sh crosswake_rindle 0.1.0 rindle Rindle` | ✅ | ✅ green |
| 174-02-01 | 02 | 1 | ROOM-06 | T-174-06..09 | Pinned doctor source and call-site identity | integration | `bash script/assert_manifest_contract_unchanged.sh` | ✅ | ✅ green |
| 174-03-01 | 03 | 1 | FID-01 | T-174-10..14 | Non-pass outcomes fail closed; no adopter identifiers | unit | `mix test test/mix/tasks/crosswake.proof_lane.physical_iphone_test.exs --max-cases 1` | ✅ | ✅ green |
| 174-03-02 | 03 | 1 | FID-01 | T-174-10..14 | Decision and disposition remain explicit | other | `174-FID-01-DISPOSITION.md` disposition assertions | ✅ | ✅ green |
| 174-03-03 | 03 | 1 | FID-01 | T-174-10..14 | Report completeness and outcome classification | unit | Focused physical-iPhone ExUnit tests | ✅ | ✅ green |
| 174-04-01 | 04 | 2 | ROOM-03/04 | T-174-15..19 | Rehearsal matches the read-only clean-room lane | integration | Workflow contract tests and exact recorded job-level run | ✅ | ✅ green |
| 174-04-02 | 04 | 2 | ROOM-03/04 | T-174-15..19 | Lane roster and marker parity are non-empty | unit | `mix test test/crosswake/proof/phase174_cleanroom_lane_parity_test.exs --max-cases 1` | ✅ | ✅ green |
| 174-04-03 | 04 | 2 | ROOM-03/04 | T-174-15..19 | Real post-merge run is recorded at job level | other | Inspect run `35366337182` and `evidence/174-rindle-ci-run.log` | ✅ | ✅ green |
| 174-05-01 | 05 | 3 | ROOM-05 | T-174-20..24 | Findings cite separate real runs and mechanisms | other | Inspect Phase 174 findings and captured run logs | ✅ | ✅ green |
| 174-05-02 | 05 | 3 | ROOM-05 | T-174-20..24 | Findings roster is literal and missing findings fail | unit | `mix test test/crosswake/proof/phase174_companion_findings_test.exs --max-cases 1` | ✅ | ✅ green |
| 174-05-03 | 05 | 3 | ROOM-05 | T-174-20..24 | Red runs do not weaken contracts | integration | `bash script/assert_manifest_contract_unchanged.sh` | ✅ | ✅ green |
| 174-06-01 | 06 | 4 | ROOM-01..06/FID-01 | T-174-25..28 | Every check and disposition is recorded | unit | `mix test test/crosswake/proof test/mix/tasks/crosswake.proof_lane --max-cases 1` | ✅ | ✅ green |
| 174-06-02 | 06 | 4 | ROOM-01..06/FID-01 | T-174-25..28 | Requirement claims link to evidence | other | Inspect `174-NON-VACUITY.md` disposition table | ✅ | ✅ green |
| 174-07-01 | 07 | 5 | ROOM-02 | T-174-29/30/32 | Actual installer and doctor run fail-closed in order | integration | `bash -n script/verify_companion_cleanroom.sh`; captured run log | ✅ | ✅ green |
| 174-07-02 | 07 | 5 | ROOM-02 | T-174-29/31 | Candidate-local artifact authority, clean paths, and safe evidence | integration | Captured `evidence/174-matrix-install-local-run.log`; evaluator shape guards | ✅ | ✅ green |
| 174-07-03 | 07 | 5 | ROOM-02 | T-174-30/32 | Literal ten-pair order; missing, unknown-mode, empty, and reversed evidence goes red | unit | `mix test test/crosswake/proof/phase174_matrix_install_order_test.exs --max-cases 1` (9 tests) | ✅ | ✅ green |

## Wave 0 Requirements

Existing Mix, ExUnit, and Node test infrastructure covers all phase requirements. No setup changes
were required.

## Manual-Only Verifications

All Phase 174 behaviors have automated verification or recorded authoritative job-level evidence.

## Validation Sign-Off

- [x] All tasks have automated verification
- [x] Sampling continuity: no three consecutive tasks without automated verification
- [x] Wave 0 covers all missing references
- [x] No watch-mode flags
- [x] Feedback latency is bounded for repository tests
- [x] `nyquist_compliant: true`

**Approval:** validated 2026-09-25
