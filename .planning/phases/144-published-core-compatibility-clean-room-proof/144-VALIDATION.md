---
phase: 144
slug: published-core-compatibility-clean-room-proof
status: passed
nyquist_compliant: true
wave_0_complete: true
created: 2026-07-07
audited: 2026-07-08
---

# Phase 144 - Validation Strategy

> Post-execution Nyquist validation contract for Phase 144.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit bundled with Elixir/Mix 1.19.5 plus dependency-free Elixir scanner |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `elixir script/check_release_workflow_integrity.exs && mix test test/crosswake/proof/phase142_release_integrity_test.exs` |
| **Phase-focused command** | `elixir script/check_release_workflow_integrity.exs && mix test test/crosswake/proof/phase142_release_integrity_test.exs --only phase144_cleanroom && mix test test/crosswake/proof/phase142_release_integrity_test.exs --only phase144_doctor && mix test test/crosswake/proof/phase142_release_integrity_test.exs --only phase144_release_integrity && mix test test/mix/tasks/crosswake_doctor_router_test.exs` |
| **Full suite command** | `MIX_ENV=test mix verify` |
| **Estimated runtime** | ~20 seconds focused, ~45 seconds full local hermetic gate |

---

## Sampling Rate

- **After every task commit:** Run the focused command named in the task's `<verify>` block.
- **After every plan wave:** Run `elixir script/check_release_workflow_integrity.exs` plus the relevant tagged Phase 144 ExUnit group.
- **Before `/gsd:verify-work`:** Run the full Phase 144 focused command and `mix test test/crosswake/proof/phase142_release_integrity_test.exs`.
- **Max feedback latency:** ~20 seconds for targeted Phase 144 feedback.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 144-01-01 | 01 | 1 | PREF-01 | T-144-01 | Package/version input is allowlisted and semver-validated before registry or file interpolation | script unit/fixture | `mix test test/crosswake/proof/phase142_release_integrity_test.exs --only phase144_cleanroom` | yes | green |
| 144-01-02 | 01 | 1 | PREF-01 | T-144-02 | Hex metadata owns `requirements.crosswake.requirement`; lockfile selected versions are postconditions | script unit/fixture | `mix test test/crosswake/proof/phase142_release_integrity_test.exs --only phase144_cleanroom` | yes | green |
| 144-02-01 | 02 | 2 | PREF-02 | T-144-03 | Doctor loads a freshly compiled Phoenix router without starting the host app | Mix task integration | `mix test test/mix/tasks/crosswake_doctor_router_test.exs` | yes | green |
| 144-02-02 | 02 | 2 | PREF-02 | T-144-04 | Router unavailable and non-router failures produce distinct diagnostics | Mix task integration | `mix test test/mix/tasks/crosswake_doctor_router_test.exs` | yes | green |
| 144-03-01 | 03 | 3 | PREF-03 | T-144-05 | Static scanner fails release-graph, proof-order, dependency-floor, and mirror-preflight regressions | scanner + ExUnit negative fixtures | `elixir script/check_release_workflow_integrity.exs && mix test test/crosswake/proof/phase142_release_integrity_test.exs --only phase144_release_integrity` | yes | green |

---

## Requirement Coverage

| Requirement | Coverage | Automated Evidence | Status |
|-------------|----------|--------------------|--------|
| PREF-01 | Clean-room script derives `crosswake` floor from exact Hex metadata, exact-pins the companion, asserts lockfile selections, and preserves package profiles. | `release.cleanroom.*` scanner IDs; `:phase144_cleanroom` fixtures; `script/verify_companion_cleanroom.sh` shell syntax check in plan summary. | covered |
| PREF-02 | Doctor task owns app config/load readiness, accepts fresh Phoenix routers, and rejects missing/non-router modules distinctly. | `test/mix/tasks/crosswake_doctor_router_test.exs`; `release.doctor.*` scanner IDs; `:phase144_doctor` fixtures. | covered |
| PREF-03 | Merge-blocking static proof fails aggregate gates, stale floors, proof cascades/order, missing mirror preflight, native proof coupling, queue regression, and doctor masking. | `script/check_release_workflow_integrity.exs`; `:phase144_release_integrity` fixtures; full `phase142_release_integrity_test.exs`. | covered |

---

## Gap Analysis

No Phase 144 Nyquist gaps were found. All three Phase 144 requirements have targeted automated coverage and the focused checks pass.

The full root gate currently has broader-suite failures outside Phase 144:

| Command | Result | Scope |
|---------|--------|-------|
| `mix verify` | failed before root tests because the alias invoked `mix test` from `dev`; rerun with `MIX_ENV=test` per Mix's diagnostic. | Alias/environment issue, not Phase 144 coverage. |
| `MIX_ENV=test mix verify` | 963 tests, 3 failures, 61 excluded. Failures: two `test/mix/tasks/crosswake_release_status_test.exs` assertions expecting warning status where current release status reports error, and one `test/crosswake/manifest/validator_test.exs` created-vs-updated assertion. | Broader root-suite drift; Phase 144 focused commands stayed green. |

These are not moved into Manual-Only for Phase 144 because they do not cover PREF-01, PREF-02, or PREF-03. They should be handled by the owning release-status/manifest phases before treating `mix verify` as green again.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None | - | Phase 144 requirements have automated focused proof. Release-time live registry execution is handled by the guarded clean-room workflow; local validation verifies the workflow/script/test contracts without requiring live publish side effects. | - |

---

## Validation Audit 2026-07-08

| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
| Manual-only Phase 144 items | 0 |
| Focused commands run | 7 |
| Focused command failures | 0 |
| Broader-suite failures observed | 3 |

Focused commands executed:

- `elixir script/check_release_workflow_integrity.exs` - passed.
- `mix test test/crosswake/proof/phase142_release_integrity_test.exs --only phase144_cleanroom` - passed, 7 tests / 0 failures.
- `mix test test/crosswake/proof/phase142_release_integrity_test.exs --only phase144_doctor` - passed, 4 tests / 0 failures.
- `mix test test/crosswake/proof/phase142_release_integrity_test.exs --only phase144_release_integrity` - passed, 12 tests / 0 failures.
- `mix test test/mix/tasks/crosswake_doctor_router_test.exs` - passed, 3 tests / 0 failures.
- `mix test test/crosswake/proof/phase142_release_integrity_test.exs` - passed, 43 tests / 0 failures.
- `mix test test/mix/tasks/crosswake_doctor_test.exs` - passed, 7 tests / 0 failures.

Auditor spawn: skipped because the gap set was empty.

---

## Validation Sign-Off

- [x] Nyquist hook enabled for `verify:post`
- [x] State A detected: existing `144-VALIDATION.md` audited and updated
- [x] All PLAN and SUMMARY files read
- [x] Requirement-to-task map rebuilt from phase artifacts
- [x] Test infrastructure detected
- [x] Each Phase 144 requirement classified as covered
- [x] No Phase 144 gaps requiring auditor-generated tests
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** audited 2026-07-08; Phase 144 is Nyquist-compliant.
