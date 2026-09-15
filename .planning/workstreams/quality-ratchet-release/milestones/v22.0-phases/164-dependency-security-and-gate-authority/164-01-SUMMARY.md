---
phase: 164-dependency-security-and-gate-authority
plan: "01"
subsystem: infra
tags: [hex, dependency-security, github-actions, exunit, fail-closed]

requires: []
provides:
  - Exact patched root and example-host Hex lock authorities inside unchanged public ranges
  - One bounded fail-closed command for independent canonical audits and an inactive negative control
  - One literal merge-blocking-dependency-security pull-request result producer
affects: [164-gate-authority, 165-ci-efficiency, 168-release-readiness]

actuals:
  tokens: 8714
  tasks: 2
  commits: 6

tech-stack:
  added: []
  patterns:
    - Independent canonical audits with accumulated failure status and sanitized output
    - Inactive advisory fixture separated from canonical lock authority
    - Literal one-job required-result producer with post-main registration handoff

key-files:
  created:
    - script/check_dependency_security.sh
    - test/fixtures/security/advisory-bearing.lock
    - test/crosswake/proof/phase164_dependency_security_and_gate_authority_test.exs
    - .github/workflows/dependency-security.yml
  modified:
    - mix.lock
    - examples/phoenix_host/mix.lock

key-decisions:
  - "Retained the existing public compatibility declarations and constrained lock changes to the five prescribed targets plus Plug Crypto 2.2.0."
  - "Kept the advisory negative control inactive and deterministic instead of replacing either canonical lock."
  - "Deferred branch-protection registration until merge-blocking-dependency-security has produced a green result on main."

patterns-established:
  - "Dual-audit authority: run both supported projects even after one failure, then return the accumulated nonzero status."
  - "Bounded security diagnostics: disclose only project, lock path, affected package, and corrective command."

requirements-completed: [SEC-01, SEC-02, SEC-03]

coverage:
  - id: D1
    description: "Both supported locks resolve to the exact patched current-minor set inside unchanged public compatibility ranges."
    requirement: SEC-02
    verification:
      - kind: integration
        ref: "mix deps.get --check-locked && (cd examples/phoenix_host && mix deps.get --check-locked)"
        status: pass
      - kind: unit
        ref: "test/crosswake/proof/phase164_dependency_security_and_gate_authority_test.exs#canonical locks resolve the exact patched targets inside unchanged public ranges"
        status: pass
    human_judgment: false
  - id: D2
    description: "One credential-free command independently audits both canonical locks and proves a known advisory is rejected with bounded output."
    requirement: SEC-01
    verification:
      - kind: integration
        ref: "script/check_dependency_security.sh && script/check_dependency_security.sh --assert-vulnerable-fixture test/fixtures/security/advisory-bearing.lock"
        status: pass
      - kind: unit
        ref: "test/crosswake/proof/phase164_dependency_security_and_gate_authority_test.exs"
        status: pass
    human_judgment: false
  - id: D3
    description: "Pull requests expose exactly one literal merge-blocking-dependency-security producer that awaits both audit paths."
    requirement: SEC-03
    verification:
      - kind: unit
        ref: "test/crosswake/proof/phase164_dependency_security_and_gate_authority_test.exs#one literal workflow job is the sole dependency-security result producer"
        status: pass
      - kind: other
        ref: "python3 script/list_merge_blocking_checks.py --emitters"
        status: pass
    human_judgment: false

duration: 7 min
completed: 2026-08-28
status: complete
---

# Phase 164 Plan 01: Dependency Security Tracer Summary

**Patched Phoenix/LiveView/Plug/Bandit/hpax locks now pass independent Hex audits through one fail-closed command and one literal merge-blocking result.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-08-28T19:27:05Z
- **Completed:** 2026-08-28T19:34:35Z
- **Tasks:** 2
- **Files modified:** 6 implementation files, plus summary and validation metadata

## Accomplishments

- Resolved Phoenix 1.8.13, Phoenix LiveView 1.1.33, Plug 1.19.5, Bandit 1.12.5, hpax 1.0.4, and required Plug Crypto 2.2.0 without changing public manifests or unrelated lock entries.
- Added a Bash-3.2-compatible audit command that runs root and example-host audits independently, accumulates failures, rejects missing or empty authority, and emits bounded remediation records.
- Added an inactive advisory-bearing lock and seven-test phase proof covering exact lock identity, audit non-vacuity, privacy-safe output, missing input, script portability, and workflow producer authority.
- Added the sole literal `merge-blocking-dependency-security` producer without branch-protection mutation or Phase-165 topology work.

## Task Commits

1. **Task 1 RED:** `ca61a61d` — failing dependency-security contract and inactive fixture
2. **Task 1 GREEN:** `b7e8155c` — constrained lock remediation and fail-closed dual audit
3. **Task 2 RED:** `74162bb3` — failing single-producer workflow contract
4. **Task 2 GREEN:** `36c297c3` — one literal dependency-security workflow producer
5. **GREEN refactor:** `b32c7f0f` — repository formatting for the phase proof

## Files Created/Modified

- `mix.lock` — patched root dependency tuples only.
- `examples/phoenix_host/mix.lock` — patched example-host dependency tuples only.
- `script/check_dependency_security.sh` — canonical dual-audit and explicit fixture-assertion modes.
- `test/fixtures/security/advisory-bearing.lock` — inactive package-metadata-only negative control.
- `test/crosswake/proof/phase164_dependency_security_and_gate_authority_test.exs` — hermetic lock, audit, privacy, and producer proof.
- `.github/workflows/dependency-security.yml` — one stable merge-blocking security result.

## Decisions Made

- Public Phoenix, LiveView, Plug, and Bandit ranges remain byte-for-byte unchanged; exact lock identity carries this remediation.
- Canonical audit failures never print raw Hex or environment output; the command reduces results to a bounded package/path/remediation contract.
- Branch protection remains untouched. After the new context is green on `main`, the existing green-first registrar remains the only administration path.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The first constrained resolver pass refreshed unrelated compatible transitives. The prescribed collateral pins were applied during resolution, restoring Phoenix PubSub, WebSock Adapter, Decimal, and Elixir Make to their prior versions before manifests were restored. The final diff contains only the allowed lock keys.
- Local Hex emitted an expired-session warning but continued credential-free as designed; both audits and locked dependency checks passed.

## TDD Gate Compliance

- RED commits: `ca61a61d`, `74162bb3`
- GREEN commits: `b7e8155c`, `36c297c3`
- GREEN refactor: `b32c7f0f`

## Known Stubs

None.

## User Setup Required

None for repository verification. Governance follow-up remains post-main: after the new context is green on `main`, an authorized maintainer may use the existing green-first `script/register_required_checks.sh` path.

## Next Phase Readiness

- SEC-01, SEC-02, and SEC-03 are executable and green.
- Plans 164-02 through 164-04 can build gate inventory, state isolation, and aggregator semantics on this trusted dependency-security tracer.

## Self-Check: PASSED

- All four created implementation artifacts and the summary exist on disk.
- All five TDD task/refactor commits are present in repository history.
- The final plan verification passed with both audits clean, the vulnerable fixture rejected, both locks coherent, seven ExUnit tests green, and exactly one security producer.

---
*Phase: 164-dependency-security-and-gate-authority*
*Completed: 2026-08-28*
