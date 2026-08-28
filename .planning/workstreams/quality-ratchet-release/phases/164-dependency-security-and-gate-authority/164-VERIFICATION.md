---
phase: 164-dependency-security-and-gate-authority
verified: 2026-08-28T20:21:33Z
status: gaps_found
score: 5/6 must-haves verified
behavior_unverified: 0
overrides_applied: 0
unresolved_spec_probes: 14
unverified_prohibitions: 11
gaps:
  - truth: "State-mutating tests pass alone and in the complete suite without leaving changed application configuration, code paths, files, or databases behind."
    status: failed
    reason: "Fresh aggregate execution failed at seed 101 in the complete-suite class because the example-host SQLite database cleanup left persistent -wal and -shm sidecars."
    artifacts:
      - path: "test/support/example_host.ex"
        issue: "own_file!/1 removes only the primary .sqlite3 path and does not remove SQLite sidecars."
      - path: "script/check_example_host_isolation.sh"
        issue: "The residue detector correctly found crosswake-example-host-5.sqlite3-shm and failed closed."
    missing:
      - "Own and remove the SQLite .sqlite3-wal and .sqlite3-shm resources after the Repo is stopped."
      - "Add a behavioral regression test that creates SQLite sidecars and proves all database resources are absent after cleanup."
      - "Re-run the complete six seed/class matrix and the Phase 164 aggregate successfully."
---

# Phase 164: Dependency Security and Gate Authority Verification Report

**Phase Goal:** Maintainers can trust that patched dependencies and every required merge result fail closed through one authoritative path.
**Verified:** 2026-08-28T20:21:33Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Root and example-host dependency audits are advisory-free, and patched Phoenix, LiveView, Plug, Bandit, hpax, and both lockfiles remain inside unchanged public compatibility ranges. | ✓ VERIFIED | Fresh locked resolution completed for both projects; both `mix hex.audit` invocations reported zero advisories. Diff from pre-phase commit `2513653c` changes only the five named targets plus Plug Crypto 2.2.0; neither manifest changed. |
| 2 | Pull requests expose one stable dependency-security result whose real and negative-control paths fail closed. | ✓ VERIFIED | Producer inventory finds exactly one `merge-blocking-dependency-security` at `.github/workflows/dependency-security.yml`; 7 focused behavioral tests passed, including dual-audit accumulation, missing lock, bounded output, and inactive advisory fixture controls. |
| 3 | Required-context producer inventory is exact and every intended ExUnit file currently has a merge-blocking execution path, including `:requires_example_host`. | ✓ VERIFIED | Fresh local audit found 88 literal producers and 27 unique merge-blocking candidates; 12 producer negative controls and 7 AST ownership controls passed. Current broad hermetic and dedicated example-host workflows execute the two owned classes. Live branch-policy read found no registered context without a producer. |
| 4 | State-mutating tests restore exact application, code-path, process, file, and database state alone and in complete-suite execution. | ✗ FAILED | Focused lifecycle tests passed, but the authoritative aggregate failed at seed 101 / complete suite with persistent `crosswake-example-host-5.sqlite3-shm`; inspection also found the corresponding `-wal`. `own_file!/1` removes only the primary path. |
| 5 | Required aggregators reject missing, unexpected, failed, cancelled, skipped-without-irrelevance, unknown, empty, and other non-success inputs; only explicit irrelevance is neutral. | ✓ VERIFIED | Fresh structural proof passed 10/10 tests. The closed evaluator passed all 11 result classes plus missing/inverted controls; named aggregators retain exact `needs`, `if: always()`, alls-green, and `toJSON(needs)`. |
| 6 | One credential-free, dependency-safe aggregate entry point owns the complete repository-local Phase 164 check path and fails closed at the responsible child. | ✓ VERIFIED | `script/check_phase164_dependency_security_and_gate_authority.sh` is substantive and directly invokes every focused authority in order. Fresh execution stopped nonzero in `example-host-six-run-matrix` with the exact corrective command rather than proceeding green. |

**Score:** 5/6 truths verified (0 present but behavior-unverified).

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `script/check_dependency_security.sh` | Independent dual audit and inactive advisory control | ✓ VERIFIED | Substantive, executable, workflow-wired, and freshly passed. |
| `.github/workflows/dependency-security.yml` | Sole stable security producer | ✓ VERIFIED | Exactly one literal producer; no suppression or registration write. |
| `script/list_merge_blocking_checks.py` / `script/check_required_checks_registered.sh` | Strict local inventory and bidirectional policy audit | ✓ VERIFIED | Local authority passed; live read failed closed only on the expected not-yet-registered new security candidate. |
| `script/check_exunit_ownership.exs` / `phase164_exunit_ownership_test.exs` | AST ownership with negative controls | ✓ VERIFIED with warning | Current tree is owned and tests pass; see test-quality warning about the unguarded default-lane assumption. |
| `test/support/example_host.ex` | Exact owned-resource restoration | ✗ PARTIAL | Env/path/process/main-file cleanup is substantive, but SQLite sidecars escape ownership. |
| `script/check_example_host_isolation.sh` | Six-run matrix and residue gate | ✓ VERIFIED | Correctly detected the real sidecar residue and failed closed. |
| `script/check_aggregator_result_semantics.py` / aggregator workflow / structural proof | Closed aggregation semantics | ✓ VERIFIED | Local semantic matrix and exact-parity proof freshly passed. |
| `script/check_phase164_dependency_security_and_gate_authority.sh` | One credential-free phase entry point | ✓ VERIFIED | Correctly wired and fail-closed; overall run is red because CIG-03 is red. |

### Key Link Verification

| From | To | Status | Details |
| --- | --- | --- | --- |
| Dependency-security workflow | Dual-audit script and both locks | ✓ WIRED | Direct awaited steps; canonical audits and fixture assertion are separate. |
| Required-check audit | Sole producer inventory | ✓ WIRED | Full producer and candidate TSV inventories run before any `gh` read. |
| ExUnit AST inventory | Default/hermetic and example-host lanes | ✓ WIRED, ⚠ warning | Current workflows execute both classes; only the example-host lane's existence is enforced by the detector itself. |
| ExampleHost mutations | ExUnit `on_exit` cleanup | ✗ PARTIAL | Main database path is registered, but generated WAL/SHM paths are not. |
| Named aggregators | Exact-parity proof and closed evaluator | ✓ WIRED | Structural and semantic halves are both executable. |
| Phase aggregate | All focused checks | ✓ WIRED | Fresh run reached and failed in the correct isolation section. |

### Behavioral Spot-Checks and Probe Execution

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Complete Phase 164 authority | `script/check_phase164_dependency_security_and_gate_authority.sh` | Failed at seed 101 / complete: `crosswake-example-host-5.sqlite3-shm` residue; corresponding `-wal` persisted | ✗ FAIL |
| Dependency locks and audits | Aggregate dependency sections | Both locked resolutions unchanged; root/example advisories=0 | ✓ PASS |
| Producer cardinality and ownership | Aggregate inventory/ownership sections | 88 producers, 27 unique candidates; 12 + 7 tests passed | ✓ PASS |
| Aggregator membership and values | Focused ExUnit plus Python self-test | 10 ExUnit tests and 5 Python tests passed; all 11 classes exercised | ✓ PASS |
| Live branch-policy comparison | `script/check_required_checks_registered.sh` | Repository-local authority passed; only `merge-blocking-dependency-security` is not yet registered on main | Expected post-main handoff, not a product-code gap |

The two generated SQLite sidecars from this verification run were removed after their persistence was confirmed; no tracked file was changed. The pre-existing untracked workstream `config.json` was preserved.

### Requirements Coverage

| Requirement | Status | Evidence |
| --- | --- | --- |
| SEC-01 | ✓ SATISFIED | Both live audits returned zero advisories. |
| SEC-02 | ✓ SATISFIED | Exact patched tuples and unchanged manifests/other lock entries verified against the pre-phase tree. |
| SEC-03 | ✓ SATISFIED | One stable producer and passing advisory/missing-input negative controls; registration remains green-first post-main work. |
| CIG-01 | ✓ SATISFIED locally | Unique producer cardinality and registered-to-producer direction passed. The new candidate is intentionally not registered until it is green on main. |
| CIG-02 | ✓ SATISFIED currently | Live AST inventory and both execution classes exist; detector hardening warning below does not negate current execution ownership. |
| CIG-03 | ✗ BLOCKED | Complete-suite seed 101 left SQLite WAL/SHM resources. |
| CIG-04 | ✓ SATISFIED | Exact leaf parity and closed result vocabulary freshly passed. |

No Phase 164 requirement is orphaned from the four plans.

### Unresolved Spec-Probe and Prohibition Flags

All **14/14** intentionally unresolved spec-probe rows remain present and explicitly marked `[UNRESOLVED-SPEC-PROBE]`: Plan 01 has 5, Plan 02 has 7, Plan 03 has 1, and Plan 04 has 1. None was converted into an invented rule, deleted, or silently treated as resolved.

The plans also retain **11 descriptor-less `flagged-unverified` prohibitions** (3/3/3/2 by plan). Repository evidence supports their intended boundaries, but these remain non-authoritative judgment flags rather than silent passes. The residue failure directly violates the CIG-03 no-residue intent regardless of those flags.

### Scope, Privacy, and Deferred-Boundary Check

- Android: no Android path changed; generator, Maven, JVM, vector, device-proof, and parity posture remain frozen.
- Parked adopter: no `first-b2c-adopter-readiness` artifact changed and no adopter identity or payload was introduced.
- Privacy: audit/workflow output is bounded; no credentials, environment dump, raw payload, account/device identifier, or adopter fact was emitted.
- No publish: no package/tag publication or branch-protection write ran. The unchanged green-first registrar remains the explicit post-main admin handoff.
- Phase 165: existing runner, trigger, cache, concurrency, and sibling aggregator topology were not optimized or consolidated. The CIG-03 residue is explicitly Phase 164 work and is not deferred to Phase 165 or Phase 166.

### Test Quality Audit

| Test Surface | Active | Skipped | Circular | Assertion Level | Verdict |
| --- | ---: | ---: | --- | --- | --- |
| Dependency security proof | 7 | 0 | No | Behavioral/value | Strong |
| Producer authority proof | 12 | 0 | No | Behavioral/value | Strong |
| ExUnit ownership proof | 7 | 0 | No | Behavioral/value | ⚠ Warning |
| Example-host lifecycle proof | 7 | 0 | No | Behavioral | Insufficient for SQLite sidecars |
| Aggregator structural/semantic proof | 10 + 5 | 0 | No | Behavioral/value | Strong |

**Warning:** `script/check_exunit_ownership.exs` treats every ordinary test as owned whenever it classifies to `:default_hermetic`, but it only validates the dedicated example-host lane. The current tree does contain merge-blocking broad hermetic lanes, so CIG-02 is true now; however, removing those lanes would not make this detector fail. Add an explicit default/hermetic lane manifest and a missing-lane negative control when closing the phase.

### Anti-Patterns Found

No `TBD`, `FIXME`, `XXX`, disabled requirement tests, circular expected-value generator, or placeholder implementation was found in phase-modified source. The only blocker is the observed resource leak; the ownership-detector warning is non-blocking for current-tree truth.

### Decision Coverage

All 13 trackable `164-CONTEXT.md` decisions were reported honored by the repository decision-coverage gate. The runtime residue still defeats D-09/D-10's outcome despite their implementation being present.

### Human Verification Required

N/A — infrastructure/CI phase with no user-facing elements. The blocking behavior is fully automatable and was directly observed.

### Gaps Summary

Phase 164 is not complete. Dependency security, producer cardinality, current ExUnit execution ownership, and closed aggregator semantics are green, and the aggregate itself fails closed correctly. But the central state-isolation truth is false: a complete-suite run leaves SQLite WAL/SHM resources after the primary database path is removed. This is a Phase 164 blocker, not later clean-checkout work.

---

_Verified: 2026-08-28T20:21:33Z_
_Verifier: Codex (gsd-verifier)_
