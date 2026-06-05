---
phase: 72
slug: media-evidence-workflow-proof
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-05
---

# Phase 72 - Validation Strategy

## Test Infrastructure

| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | `mix.exs` |
| Quick run command | `mix test test/crosswake/proof/phase72_media_evidence_workflow_proof_test.exs` |
| Full suite command | `mix compile --warnings-as-errors && mix test test/crosswake/proof/phase72_media_evidence_workflow_proof_test.exs test/crosswake/proof/phase45_rindle_mock_media_test.exs test/crosswake/proof/phase45_rindle_live_test.exs test/crosswake/companions/rindle/contracts_test.exs test/crosswake/companions/rindle/reconciliation_test.exs` |
| Estimated runtime | ~90 seconds |

## Sampling Rate

- After every task commit: run `mix test test/crosswake/proof/phase72_media_evidence_workflow_proof_test.exs` unless the task only creates CI/docs and has a narrower source assertion.
- After every plan wave: run the full suite command.
- Before `$gsd-verify-work`: full suite and targeted CI/source checks must be green.
- Max feedback latency: 120 seconds.

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 72-01-01 | 01 | 0 | MED-01, MED-02 | T-72-01 / T-72-02 | Degraded capture proof exists and local evidence cannot make media available | ExUnit | `mix test test/crosswake/proof/phase72_media_evidence_workflow_proof_test.exs` | no | pending |
| 72-01-02 | 01 | 0 | MED-01, MED-02 | T-72-03 / T-72-04 | Replay, multipart, stale grant, corrupt integrity, and direct override cases are asserted | ExUnit | `mix test test/crosswake/proof/phase72_media_evidence_workflow_proof_test.exs` | no | pending |
| 72-01-03 | 01 | 0 | MED-02 | T-72-05 | Hostile metadata is redacted and proof stays hermetic | ExUnit/source | `mix test test/crosswake/proof/phase72_media_evidence_workflow_proof_test.exs` | no | pending |
| 72-02-01 | 02 | 1 | MED-01 | T-72-01 | Queue fixture records degraded capture without production sync semantics | ExUnit | `mix test test/crosswake/proof/phase72_media_evidence_workflow_proof_test.exs` | no | pending |
| 72-02-02 | 02 | 1 | MED-01, MED-02 | T-72-02 / T-72-03 | Rindle ingestion/projection preserves backend verification boundary | ExUnit | `mix test test/crosswake/proof/phase72_media_evidence_workflow_proof_test.exs test/crosswake/proof/phase45_rindle_mock_media_test.exs` | yes | pending |
| 72-02-03 | 02 | 1 | MED-01, MED-02 | T-72-05 | LiveView proof states show degraded/recovered/scanning/available without overclaim copy | ExUnit | `mix test test/crosswake/proof/phase72_media_evidence_workflow_proof_test.exs test/crosswake/proof/phase45_rindle_live_test.exs` | yes | pending |
| 72-03-01 | 03 | 2 | MED-01, MED-02, PROOF-01 | T-72-06 | CI proof lane is hermetic and provider/device/storage lanes stay advisory | Source/CI | `grep -q "mix test test/crosswake/proof/phase72_media_evidence_workflow_proof_test.exs" .github/workflows/phase72-proof.yml` | no | pending |
| 72-03-02 | 03 | 2 | MED-01, MED-02 | T-72-06 | Public truth says simulated degradation/Rindle reconciliation, not storage/native/offline support | ExUnit/source | `mix test test/crosswake/support_matrix/support_matrix_test.exs test/crosswake/operator_inspection/operator_inspection_test.exs` | yes | pending |
| 72-03-03 | 03 | 2 | MED-01, MED-02 | T-72-06 | Guides avoid local-first, background upload, provider-storage, and native-camera overclaims | Source | `rg -n "offline uploads work|background upload guaranteed|real S3/GCS upload|native camera captured|local-first sync" guides/support_matrix.md guides/companions.md guides/user_flows.md && exit 1 || exit 0` | yes | pending |

## Wave 0 Requirements

- `test/crosswake/proof/phase72_media_evidence_workflow_proof_test.exs` - red proof contract for MED-01 and MED-02.
- Existing ExUnit infrastructure covers all phase requirements.

## Manual-Only Verifications

All Phase 72 behaviors have automated verification. Real native camera, background upload, storage provider, and device proof are explicitly deferred/advisory and must not gate this phase.

## Validation Sign-Off

- [x] All tasks have automated verify or Wave 0 dependencies.
- [x] Sampling continuity: no 3 consecutive tasks without automated verify.
- [x] Wave 0 covers all missing MED-01/MED-02 references.
- [x] No watch-mode flags.
- [x] Feedback latency target under 120 seconds.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** approved 2026-06-05

