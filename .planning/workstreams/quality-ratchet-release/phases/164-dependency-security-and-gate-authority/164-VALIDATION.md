---
phase: 164
slug: dependency-security-and-gate-authority
status: complete
nyquist_compliant: true
wave_0_complete: true
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
| **Quick run command** | `mix test test/crosswake/proof/phase164_dependency_security_and_gate_authority_test.exs` |
| **Phase aggregate command** | `script/check_phase164_dependency_security_and_gate_authority.sh` |
| **Full suite command** | After `MIX_ENV=dev mix deps.get && MIX_ENV=dev mix compile` in `examples/phoenix_host`: for each N in 17, 101, 1009 run `mix test --only requires_example_host --seed N` and `CROSSWAKE_INCLUDE_EXAMPLE_HOST=1 mix test --seed N` from the root |
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
| 164-01-01 | 01 | 1 | SEC-01, SEC-02 | T-164-04 | Both locks resolve to exact fixed current-minor versions with zero advisories | integration | `script/check_dependency_security.sh && mix deps.get --check-locked && (cd examples/phoenix_host && mix deps.get --check-locked) && mix test test/crosswake/proof/phase164_dependency_security_and_gate_authority_test.exs` | ✅ | ✅ green |
| 164-01-02 | 01 | 1 | SEC-03 | T-164-04, T-164-05, T-164-07 | One security producer rejects an advisory-bearing fixture without leaking environment data | negative control | `mix test test/crosswake/proof/phase164_dependency_security_and_gate_authority_test.exs` | ✅ | ✅ green |
| 164-02-01 | 02 | 3 | CIG-01 | T-164-01, T-164-03, T-164-08 | Every required context has exactly one literal producer and malformed authority fails closed against the final post-workflow-edit tree | unit + local audit | `mix test test/crosswake/proof/phase153_1_gate_integrity_test.exs && python3 script/list_merge_blocking_checks.py --emitters >/dev/null && script/check_required_checks_registered.sh --local-only` | ✅ | ✅ green |
| 164-02-02 | 02 | 3 | CIG-02 | T-164-03 | Every intended root ExUnit file maps to a merge-blocking execution class | structural negative control | `elixir script/check_exunit_ownership.exs && mix test test/crosswake/proof/phase164_exunit_ownership_test.exs` | ✅ | ✅ green |
| 164-02-03 | 02 | 3 | SEC-01, SEC-02, SEC-03, CIG-01, CIG-02, CIG-03, CIG-04 | T-164-01, T-164-02, T-164-03, T-164-04, T-164-06 | One credential-free phase entry point awaits root and example-host lock resolution before dependency audit/proof, then inventory, local audit, ownership, isolation, and aggregator proof | aggregate integration | `script/check_phase164_dependency_security_and_gate_authority.sh` | ✅ | ✅ green |
| 164-03-01 | 03 | 2 | CIG-03 | T-164-06 | Example-host setup restores exact prior env/path/process/file/database state | unit + integration | `mix test test/crosswake/proof/phase164_example_host_isolation_test.exs` | ✅ | ✅ green |
| 164-03-02 | 03 | 2 | CIG-03 | T-164-09 | Tagged and complete suites pass for all six seed/class combinations at seeds 17, 101, and 1009 without residue | integration | `script/check_example_host_isolation.sh` | ✅ | ✅ green |
| 164-04-01 | 04 | 2 | CIG-04 | T-164-02 | Named aggregators reject missing or unexpected leaves through exact parity | structural negative control | `mix test test/crosswake/proof/phase134_native_gate_blocking_proof_test.exs` | ✅ | ✅ green |
| 164-04-02 | 04 | 2 | CIG-04 | T-164-02, T-164-10 | Credential-free full result vocabulary plus missing/inverted records fail closed, and CI awaits the same outcome assertion | semantic matrix + workflow negative control | `python3 script/check_aggregator_result_semantics.py --self-test` | ✅ | ✅ green |
| 164-05-01 | 05 | 4 | CIG-03 | T-164-06, T-164-11 | An owned WAL-mode Repo exposes its primary/WAL/SHM resources, then exact owned cleanup removes all three after Repo shutdown while preserving unowned state | behavioral unit + integration | `mix test test/crosswake/proof/phase164_example_host_isolation_test.exs && script/check_example_host_isolation.sh && script/check_phase164_dependency_security_and_gate_authority.sh` | ✅ | ✅ green — 8/8 focused, 6/6 matrix, aggregate passed |
| 164-05-02 | 05 | 4 | CIG-02 | T-164-03 | Default/hermetic ownership requires an explicit existing broad-lane manifest and a missing-lane negative control without workflow changes | structural negative control | `elixir script/check_exunit_ownership.exs && mix test test/crosswake/proof/phase164_exunit_ownership_test.exs` | ✅ | ✅ green — live detector and 8/8 controls passed |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `script/check_dependency_security.sh` and an inactive vulnerable-lock fixture.
- [x] `test/crosswake/proof/phase164_dependency_security_and_gate_authority_test.exs` for exact
  targets, security-producer uniqueness, negative controls, and resource restoration.
- [x] Strict fixture support for duplicate, malformed, unnamed, dynamic, and missing workflow
  producers in `script/list_merge_blocking_checks.py`.
- [x] `script/check_exunit_ownership.exs` with owned, unowned, comment-only, and string-only cases.
- [x] `script/check_example_host_isolation.sh` whose unfiltered invocation compiles the example host in dev and runs `mix test --only requires_example_host --seed N` plus `CROSSWAKE_INCLUDE_EXAMPLE_HOST=1 mix test --seed N` for N = 17, 101, and 1009 with residue checks.
- [x] `script/check_aggregator_result_semantics.py` with the complete credential-free vocabulary, missing/inverted negative controls, and workflow outcome-assertion mode.
- [x] Aggregator cancelled, explicit-neutral, unknown, empty, and exact missing-leaf workflow cases.
- [x] `script/check_phase164_dependency_security_and_gate_authority.sh` as the credential-free aggregate entry point over every focused phase check.
- [ ] Behavioral SQLite primary/WAL/SHM creation-and-cleanup proof plus the exact six-run and aggregate rerun from Plan 164-05.
- [ ] Explicit default/hermetic lane manifest and missing-lane negative control in the existing ExUnit ownership detector/test files.

---

## Manual-Only Verifications

All implementation behaviors have automated verification. Registering the new stable dependency
security context in branch protection is intentionally deferred until its producer is green on
`main`; if repository-administration authority is unavailable then, the existing green-first
registrar becomes one explicit maintainer action rather than a verification step.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 300s for focused checks
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** passed — the credential-free aggregate completed every Phase 164 contract on 2026-08-28.
