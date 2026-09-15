---
phase: 164-dependency-security-and-gate-authority
verified: 2026-08-28T21:00:48Z
status: passed
score: 6/6 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 5/6
  gaps_closed:
    - "State-mutating example-host tests now remove the owned SQLite primary, WAL, and SHM resources after Repo shutdown and pass the complete retained matrix without residue."
    - "Default/hermetic ExUnit ownership now requires an explicit current broad-lane manifest and fails closed when that lane is absent."
  gaps_remaining: []
  regressions: []
unresolved_spec_probes: 14
legacy_prohibition_descriptors_checked: 11
---

# Phase 164: Dependency Security and Gate Authority Verification Report

**Phase Goal:** Maintainers can trust that patched dependencies and every required merge result fail closed through one authoritative path.
**Verified:** 2026-08-28T21:00:48Z
**Status:** passed
**Re-verification:** Yes — after Plan 164-05 gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Root and example-host dependency audits are advisory-free, and patched Phoenix, LiveView, Plug, Bandit, hpax, and both lockfiles remain inside unchanged public compatibility ranges. | ✓ VERIFIED | Fresh aggregate execution resolved both committed locks unchanged, then both independent `mix hex.audit` invocations reported zero advisories. The phase proof passed 7/7 exact-version, range, inactive-advisory, missing-input, bounded-output, and producer controls. |
| 2 | Pull requests expose one stable dependency-security result whose real and negative-control paths fail closed. | ✓ VERIFIED | The strict inventory found exactly one `merge-blocking-dependency-security` producer at `.github/workflows/dependency-security.yml`; its awaited steps run the canonical dual audit and inactive advisory fixture without suppression or branch-protection writes. |
| 3 | Every merge-blocking context has one literal producer, and every intended ExUnit file has a required execution path including `:requires_example_host`. | ✓ VERIFIED | Fresh local authority reported 88 literal producers and 27 unique merge-blocking candidates; 12 producer negative controls passed. The live AST inventory and 8/8 ownership controls passed, including independent missing-default-lane and missing-example-lane failures. |
| 4 | State-mutating tests restore exact application, code-path, process, file, and database state alone and in complete-suite execution. | ✓ VERIFIED | The WAL-mode regression passed 8/8: it observed the primary, `-wal`, and `-shm` paths while the owned Repo was alive, stopped the Repo, removed all three exact paths, preserved adversarial neighboring files byte-for-byte, and proved idempotence. Tagged and complete suites then passed at seeds 17, 101, and 1009 with no `crosswake-example-host-*` residue. |
| 5 | Required aggregators reject missing, unexpected, failed, cancelled, disallowed skipped, unknown, empty, and other non-success inputs; only explicit irrelevance is neutral. | ✓ VERIFIED | Fresh structural proof passed 10/10. The credential-free evaluator passed all 11 result classes plus missing/inverted outcome controls; no `allowed-failures` exemption exists. |
| 6 | One credential-free, dependency-safe aggregate entry point owns the complete repository-local Phase 164 check path. | ✓ VERIFIED | `script/check_phase164_dependency_security_and_gate_authority.sh` freshly completed every awaited section and ended with `PASS phase164 dependency-security-and-gate-authority`. |

**Score:** 6/6 truths verified (0 present but behavior-unverified).

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `script/check_dependency_security.sh` and inactive advisory fixture | Independent canonical audits plus a non-vacuous vulnerable-lock control | ✓ VERIFIED | Substantive, executable, workflow-wired, and freshly passed. |
| `.github/workflows/dependency-security.yml` | Sole stable dependency-security producer | ✓ VERIFIED | One literal producer; direct awaited audit/fixture steps; no failure suppression or governance write. |
| `script/list_merge_blocking_checks.py` and `script/check_required_checks_registered.sh` | Strict producer inventory and local-first bidirectional audit | ✓ VERIFIED | Malformed, dynamic, duplicate, missing, and unavailable-authority cases are executable; credential-free local authority passed. |
| `script/check_exunit_ownership.exs` and ownership proof | AST execution-class ownership with two explicit lane manifests | ✓ VERIFIED | Default/hermetic and example-host lanes are validated independently by workflow path, job, literal name, and selector; live and synthetic tests passed 8/8. |
| `test/support/example_host.ex` and lifecycle proof | Exact prior-state and owned-resource restoration | ✓ VERIFIED | Cleanup owns the unique primary path and exact `-wal`/`-shm` companions, while environment, BEAM paths, PIDs, and unowned resources retain exact ownership semantics. |
| `script/check_example_host_isolation.sh` | Fixed six-run tagged/complete matrix and residue gate | ✓ VERIFIED | Seeds 17, 101, and 1009 passed both classes; before/after temp and tracked-path snapshots matched. |
| Aggregator structural proof, local policy, and negative-control workflow | Exact leaf membership and closed result semantics | ✓ VERIFIED | 10 ExUnit tests and 5 semantic self-tests passed; every captured outcome is awaited by the retained workflow. |
| `script/check_phase164_dependency_security_and_gate_authority.sh` | Single phase-level verification authority | ✓ VERIFIED | Directly wires all specialized checks in fail-fast dependency order and freshly passed. |

### Key Link Verification

| From | To | Status | Details |
| --- | --- | --- | --- |
| Dependency-security workflow | Dual-audit script and both locks | ✓ WIRED | Direct awaited canonical and negative-control steps; one literal producer. |
| Required-context audit | Sole full producer inventory | ✓ WIRED | Local syntax/type/name/cardinality validation runs before any optional `gh` read. |
| ExUnit AST inventory | Phase 130 broad lane and dedicated example-host lane | ✓ WIRED | Both execution classes require their own current workflow/job/name/selector manifest; removing either synthetic lane fails closed. |
| `start_saas_repo!/0` | Owned Repo and SQLite cleanup callbacks | ✓ WIRED | File ownership registers before Repo ownership, so reverse `on_exit` order stops the Repo before the exact primary/WAL/SHM set is removed. |
| WAL lifecycle regression | ExampleHost ownership helper | ✓ WIRED | Real SQLite activity creates both sidecars before explicit Repo-first cleanup asserts all three paths absent. |
| Named aggregators | Exact parity proof and closed evaluator | ✓ WIRED | Structural membership and result semantics are separate executable gates. |
| Phase aggregate | All focused authorities | ✓ WIRED | Fresh execution reached and passed every child in the prescribed order. |

### Data-Flow Trace (Level 4)

N/A — this is infrastructure/CI tooling with no rendered dynamic data. Runtime inputs flow from committed locks, workflow YAML, ExUnit AST, SQLite filesystem state, and explicit result maps into executable validators rather than a UI surface.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| WAL/SHM lifecycle and unowned-resource preservation | `mix test test/crosswake/proof/phase164_example_host_isolation_test.exs` | 8 tests, 0 failures; primary/WAL/SHM observed before cleanup and absent afterward | ✓ PASS |
| Explicit default/example execution-lane authority | `elixir script/check_exunit_ownership.exs && mix test test/crosswake/proof/phase164_exunit_ownership_test.exs` | Live ownership green; 8 tests, 0 failures | ✓ PASS |
| Complete Phase 164 authority | `script/check_phase164_dependency_security_and_gate_authority.sh` | Both audits clean; 88 producers; 27 candidates; 7 + 12 + 8 + 8 + 10 + 5 focused controls green; all six matrix runs green | ✓ PASS |
| Post-run residue and worktree | `find "${TMPDIR:-/tmp}" -maxdepth 1 -name 'crosswake-example-host-*' -print; git status --short` | No owned temp paths; only intentional untracked workstream `config.json` remains | ✓ PASS |

### Probe Execution

No `probe-*.sh` files are declared by this phase. The phase-declared executable authority is the aggregate command above, which was run directly and passed.

### Requirements Coverage

| Requirement | Source Plans | Status | Evidence |
| --- | --- | --- | --- |
| SEC-01 | 164-01, 164-02 | ✓ SATISFIED | Root and example-host audits each reported zero advisories. |
| SEC-02 | 164-01, 164-02 | ✓ SATISFIED | Exact patched tuples resolved unchanged; public manifests are byte-for-byte unchanged. |
| SEC-03 | 164-01 | ✓ SATISFIED | One stable producer plus inactive advisory and missing-input negative controls. Green-first branch-protection registration remains the existing post-main governance handoff, not a second producer. |
| CIG-01 | 164-02 | ✓ SATISFIED | Strict full inventory and 12 negative controls prove literal producer cardinality and fail-closed local authority. |
| CIG-02 | 164-02, 164-05 | ✓ SATISFIED | Every intended file is AST-classified and both required lane manifests have independent missing-lane controls. |
| CIG-03 | 164-03, 164-05 | ✓ SATISFIED | Exact ownership cleanup, observed primary/WAL/SHM lifecycle, and all six tagged/complete runs leave no residue. |
| CIG-04 | 164-04 | ✓ SATISFIED | Exact leaf parity and exhaustive closed result vocabulary passed. |

All seven Phase 164 requirements are claimed by at least one plan; there are no orphaned Phase 164 requirements. Planning checkboxes for CIG-01/CIG-04 remain transition metadata for the orchestrator to mark after this verification, not missing implementation.

### Prohibitions and Scope Boundaries

The five plans retain 11 legacy scalar `flagged-unverified` prohibition descriptors. Each underlying boundary now has direct evidence: exact lock-diff/range assertions; one security producer and no registrar call; bounded audit output; one producer inventory; AST rather than lexical ownership; no retry/serialization/exclusion concealment; owned-only resource cleanup; no `allowed-failures`; and no Android, parked-adopter, runner/cache/trigger, or workflow-consolidation changes. None remains an unverified behavior in this re-verification.

All 14 `[UNRESOLVED-SPEC-PROBE]` planning rows remain present as explicit assumptions; none was silently converted into an adopter, compatibility, scheduling, or result-policy claim.

### Test Quality Audit

| Test Surface | Active | Skipped | Circular | Assertion Level | Verdict |
| --- | ---: | ---: | --- | --- | --- |
| Dependency security proof | 7 | 0 | No | Behavioral/value | Strong |
| Producer authority proof | 12 | 0 | No | Behavioral/value | Strong |
| ExUnit ownership proof | 8 | 0 | No | Behavioral/value | Strong |
| Example-host lifecycle proof | 8 | 0 | No | Behavioral/state transition | Strong |
| Aggregator structural/semantic proof | 10 + 5 | 0 | No | Behavioral/value | Strong |

No requirement-linked test is disabled, no expected result is generated circularly by the system under test, and the state-transition truth is exercised rather than inferred from symbol presence.

### Anti-Patterns Found

No unreferenced `TBD`, `FIXME`, or `XXX`, disabled requirement test, circular fixture generator, placeholder implementation, broad temp glob cleanup, retry, suite serialization, or failure exemption was found in phase-modified implementation. The `XXXXXX` strings in `mktemp` templates are runtime uniqueness masks, not debt markers.

### Decision Coverage

All 13 trackable decisions in `164-CONTEXT.md` are honored by shipped artifacts according to the repository decision-coverage gate.

### Human Verification Required

N/A — infrastructure/CI phase with no user-facing elements. All acceptance behavior, including the previous runtime cleanup failure, is directly automated.

### Gaps Summary

No blocking or human-verification gaps remain. Plan 164-05 closes the observed SQLite sidecar leak and the default-lane non-vacuity warning, and fresh current-tree execution confirms the complete Phase 164 authority path is green without residue or adjacent-scope changes.

---

_Verified: 2026-08-28T21:00:48Z_
_Verifier: Codex (gsd-verifier)_
