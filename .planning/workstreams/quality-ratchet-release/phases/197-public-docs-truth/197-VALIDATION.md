---
phase: "197"
slug: public-docs-truth
status: validated
nyquist_compliant: true
wave_0_complete: true
created: "2026-11-05"
---

# Phase 197 — Validation Strategy

> Reconstructed from PLAN and SUMMARY artifacts (state B) on 2026-11-05, after the phase was verified `passed`.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit via `mix test`, wrapped by `script/mix_test_gate.sh` |
| **Config file** | `mix.exs`, `test/test_helper.exs` |
| **Quick run command** | `mix test test/crosswake/docs_report_test.exs test/crosswake/mix_test_gate_test.exs` |
| **Full suite command** | `mix test` (3134 tests, 0 failures, recorded in `197-EVIDENCE/suite-197.txt`) |
| **Estimated runtime** | ~160 s for the requirement-mapped files, 6 files |

---

## Sampling Rate

- **After every task commit:** the plan's own `script/mix_test_gate.sh --min N` command, which fails on a ran-count below the floor.
- **After every plan wave:** the plan's gate plus `mix format --check-formatted` on touched tests.
- **Before verify-work:** full suite green (recorded, 3134/0).
- **Max feedback latency:** ~160 s.

---

## Per-Task Verification Map

Granularity is per requirement and plan group. The per-task automated commands live in each PLAN's `<verify>` blocks.

| Plans | Requirement | Behavior | Test type | Automated command / file | Status |
|-------|-------------|----------|-----------|--------------------------|--------|
| 197-03 to 197-09, 197-13, 197-14, 197-15 | DOCS-01 | Install docs are executed in a clean room; every fence is marked; failure modes fail closed | unit + script stub | `test/crosswake/release/published_cleanroom_test.exs`, `test/crosswake/guides/cleanroom_doc_markers_test.exs` | ✅ green |
| 197-10, 197-11, 197-12, 197-14, 197-15 | DOCS-02 | Companion matrix, CHANGELOG, telemetry guide and Android guide carry no stale release claims | unit | `test/crosswake/proof/phase132_compat_matrix_drift_test.exs`, `test/crosswake/proof/phase142_release_integrity_test.exs` | ✅ green |
| 197-01, 197-02, 197-12, 197-13, 197-14 | DOCS-03 | Leak, link and warning counters report exact counts and fail to UNVERIFIED on bad input | unit | `test/crosswake/docs_report_test.exs`, `test/crosswake/mix_test_gate_test.exs` | ✅ green |

Last run: the six files above, 252 tests, 0 failures, 2026-11-05.

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Existing infrastructure covers all phase requirements. The gate helper and report script were created inside the phase (197-01) and are themselves under test.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Networked four-leg clean-room run against the published release | DOCS-01 | Needs network and the Hex registry. It is not run in CI. | Re-run `script/verify_published_cleanroom.sh` and expect `PASS` with `deferred=ios_host`. Recorded in `197-EVIDENCE/cleanroom-0.2.11-197.txt`. |
| `:ios_host` wiring executed against a release that reads it | DOCS-01 | 0.2.11 does not read the key. This is a named deferral. | Owned by Phase 199 SC5 (`deferred=none` against 0.2.12). |

---

## Known Warnings (non-blocking)

- `published_cleanroom_test.exs`: `@zero_ref` is read at line 533 but defined at line 574, so the compiler warns and the value is `nil` at first use. The test still asserts the specific failure line and exit code. Move the attribute above its first use.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency within the ~160 s bound
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-11-05
