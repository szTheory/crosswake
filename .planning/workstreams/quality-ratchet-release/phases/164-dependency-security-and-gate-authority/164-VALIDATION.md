---
phase: 164
slug: dependency-security-and-gate-authority
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-08-28
---

# Phase 164 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit on Elixir 1.19.5 plus executable repository scripts |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/crosswake/proof/phase164_dependency_security_and_gate_authority_test.exs -x` |
| **Full suite command** | `mix test` plus the example-host-tagged lane after the example host is compiled in `MIX_ENV=dev` |
| **Estimated runtime** | ~180 seconds excluding the bounded multi-seed isolation matrix |

---

## Sampling Rate

- **After every task commit:** Run the focused phase-164 ExUnit file or changed detector command.
- **After every plan wave:** Run both dependency audits, detector negative controls, the tagged
  example-host class, and the complete root suite.
- **Before `$gsd-verify-work`:** Both audits and the full suite must be green, with Git clean after
  the bounded isolation matrix.
- **Max feedback latency:** 300 seconds for a focused check; long multi-seed evidence runs at wave
  boundaries only.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 164-01-01 | 01 | 1 | SEC-01, SEC-02 | T-164-04 | Both locks resolve to exact fixed current-minor versions with zero advisories | integration | `script/check_dependency_security.sh` | ❌ W0 | ⬜ pending |
| 164-01-02 | 01 | 1 | SEC-03 | T-164-04, T-164-05 | One security producer rejects an advisory-bearing fixture without leaking environment data | negative control | `mix test test/crosswake/proof/phase164_dependency_security_and_gate_authority_test.exs -x` | ❌ W0 | ⬜ pending |
| 164-02-01 | 02 | 3 | CIG-01 | T-164-01, T-164-03 | Every required context has exactly one literal producer and malformed authority fails closed against the final post-workflow-edit tree | unit + live audit | `mix test test/crosswake/proof/phase153_1_gate_integrity_test.exs -x && python3 script/list_merge_blocking_checks.py --emitters >/dev/null` | ✅ extend | ⬜ pending |
| 164-02-02 | 02 | 3 | CIG-02 | T-164-03 | Every intended root ExUnit file maps to a merge-blocking execution class | structural negative control | `script/check_exunit_ownership.exs` | ❌ W0 | ⬜ pending |
| 164-03-01 | 03 | 2 | CIG-03 | T-164-06 | Example-host setup restores exact prior env/path/process/file/database state | unit + integration | `mix test test/crosswake/proof/phase164_dependency_security_and_gate_authority_test.exs -x` | ❌ W0 | ⬜ pending |
| 164-03-02 | 03 | 2 | CIG-03 | T-164-06 | Tagged and complete suites pass for all six seed/class combinations at seeds 17, 101, and 1009 without residue | integration | `script/check_example_host_isolation.sh` | ❌ W0 | ⬜ pending |
| 164-04-01 | 04 | 2 | CIG-04 | T-164-02 | Named aggregators reject missing or unexpected leaves through exact parity | structural negative control | `mix test test/crosswake/proof/phase134_native_gate_blocking_proof_test.exs -x` | ✅ extend | ⬜ pending |
| 164-04-02 | 04 | 2 | CIG-04 | T-164-02, T-164-10 | Credential-free full result vocabulary plus missing/inverted records fail closed, and CI awaits the same outcome assertion | semantic matrix + workflow negative control | `python3 script/check_aggregator_result_semantics.py --self-test` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `script/check_dependency_security.sh` and an inactive vulnerable-lock fixture.
- [ ] `test/crosswake/proof/phase164_dependency_security_and_gate_authority_test.exs` for exact
  targets, security-producer uniqueness, negative controls, and resource restoration.
- [ ] Strict fixture support for duplicate, malformed, unnamed, dynamic, and missing workflow
  producers in `script/list_merge_blocking_checks.py`.
- [ ] `script/check_exunit_ownership.exs` with owned, unowned, comment-only, and string-only cases.
- [ ] `script/check_example_host_isolation.sh` whose unfiltered invocation runs tagged and complete classes at seeds 17, 101, and 1009 with residue checks.
- [ ] `script/check_aggregator_result_semantics.py` with the complete credential-free vocabulary, missing/inverted negative controls, and workflow outcome-assertion mode.
- [ ] Aggregator cancelled, explicit-neutral, unknown, empty, and exact missing-leaf workflow cases.

---

## Manual-Only Verifications

All implementation behaviors have automated verification. Registering the new stable dependency
security context in branch protection is intentionally deferred until its producer is green on
`main`; if repository-administration authority is unavailable then, the existing green-first
registrar becomes one explicit maintainer action rather than a verification step.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 300s for focused checks
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
