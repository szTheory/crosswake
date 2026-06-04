---
phase: 65
slug: diagnostic-export-seam-elixir
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-06-04
validated: 2026-06-04
---

# Phase 65 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (Elixir / Mix) |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/crosswake/proof/phase65_diagnostic_export_seam_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~0.4s wall (proof lane, post-compile); ~0.1s ExUnit-reported |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/crosswake/proof/phase65_diagnostic_export_seam_test.exs`
- **After every plan wave:** Run `mix test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** < 5 seconds (single-file proof lane)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 65-01-01 | 01 | 1 | DIAG-01, DIAG-02 | T-65-01 / T-65-NET | Behaviour-only `@callback export/1` (no HTTP dep, not a bridge command); Envelope enforce-keys 7 locked fields + closed enums; NativeDiagnostic = `[:source, :exit_reason]` only (no raw_payload/open map) | unit | `mix test test/crosswake/shell/diagnostic_export_test.exs` | ✅ | ✅ green |
| 65-01-02 | 01 | 1 | DIAG-03 | T-65-02 / T-65-03 | `sanitize/1` fail-closed: rejects forbidden key, unexpected key, out-of-enum, non-map; `forbidden_keys/0` (19-key) ⟂ `allowed_keys/0`; `to_map/1` stringify + nil-reject, no `@derive` | unit | `mix test test/crosswake/shell/diagnostic_export_test.exs` | ✅ | ✅ green |
| 65-02-01 | 02 | 2 | DIAG-04 | T-65-05 / — | `@diagnostic_export_support_truth` mirrors notification truth shape; `delivery_supported: false`; 3 deferred atoms; `authority_source: :host_configured_endpoint`; posture "not a crash-reporting service" | unit | `mix test test/crosswake/support_matrix/support_matrix_test.exs` | ✅ | ✅ green |
| 65-02-02 | 02 | 2 | DIAG-04 | T-65-06 / — | One unconditional `:advisory` finding `diagnostic_export.contract_shipped`; message excludes "crash-reporting service"; details carry host-owned-endpoint + deferred posture | unit | `mix test test/crosswake/doctor/doctor_test.exs` | ✅ | ✅ green |
| 65-03-01 | 03 | 3 | DIAG-02 | T-65-11 / — | Six canonical axis fixtures generated from `new_envelope!/1 + to_map/1` (never hand-authored); one per layer × exit-reason | fixture | `mix test test/crosswake/proof/phase65_diagnostic_export_seam_test.exs` | ✅ | ✅ green |
| 65-03-02 | 03 | 3 | DIAG-01, DIAG-02, DIAG-03, DIAG-04 | T-65-07/08/09/10/SC | Merge-blocking hermetic proof lane: no `diagnostics.*` bridge command, no HTTP-client dep (mix.exs + source), forbidden⟂allowed over all 19 keys + nested CR-01 guards, support-truth + non-overclaiming doctor finding | proof (integration) | `mix test test/crosswake/proof/phase65_diagnostic_export_seam_test.exs` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

**Coverage confirmed 2026-06-04:**
- `diagnostic_export_test.exs` — 21 tests, 0 failures
- `support_matrix_test.exs` — 41 tests, 0 failures
- `doctor_test.exs` — 29 tests, 0 failures
- `phase65_diagnostic_export_seam_test.exs` — 34 tests, 0 failures (merge-blocking gate)

---

## Wave 0 Requirements

*Existing infrastructure covers all phase requirements.* ExUnit (Mix) is the established test framework; no new framework install, no shared-fixture scaffolding, and no test stubs were required. All four DIAG requirements were built TDD (RED commit → GREEN commit per task), so every requirement had a failing automated test before implementation.

---

## Manual-Only Verifications

*All phase behaviors have automated verification.*

Per the 65-VERIFICATION.md "Human Verification Required" section: none. The merge-blocking proof lane (`phase65_diagnostic_export_seam_test.exs`) is the authoritative gate for all four DIAG requirements; every observable truth (17/17) is verifiable programmatically. The network transport (HTTP POST) is intentionally out of Phase 65 scope (behaviour-only seam, deferred to Phase 67), so there is no transport behavior to manually exercise.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references — no MISSING references (none)
- [x] No watch-mode flags
- [x] Feedback latency < 5s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-06-04

---

## Validation Audit 2026-06-04

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |

**Notes:** Reconstructed from phase artifacts (3 SUMMARY files + 65-VERIFICATION.md). The pre-existing VALIDATION.md was an unfilled template (placeholder `{N}`/`REQ-{XX}` rows, `nyquist_compliant: false`) authored at plan time and never completed during execution. All four DIAG requirements were verified COVERED with green automated tests — no MISSING or PARTIAL gaps, so no gsd-nyquist-auditor spawn was required. Test reality re-confirmed live during this audit (125 phase-related tests passing across 4 files). The 3 pre-existing `MilestoneTransitionResetTest` failures noted in the summaries are unrelated to Phase 65 (assert superseded v3.9 milestone state) and out of scope.
