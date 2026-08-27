---
phase: 162-physical-iphone-adoption-proof
verified: 2026-08-27T20:00:00Z
status: gaps_found
score: 1/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 6/7
  gaps_closed:
    - "The free-form value now reaches the scoped journal and the Phoenix authority path in the current code and deterministic contract tests."
    - "The physical-report serialization/parser contract now has an executable production parser/join regression."
  gaps_remaining:
    - "The sole retained physical-iPhone record was produced by code preceding the run-nonce, expected-mutation binding, and mandatory all-exit cleanup fixes."
  regressions:
    - "The support matrix again treats the stale-provenance record as device evidence."
gaps:
  - truth: "The physical-iPhone exit test proves offline answers, relaunch, exactly-once replay, recovery, account isolation, and disablement under the current provenance authority."
    status: failed
    reason: "The retained record's pinned code revision predates all three material provenance/cleanup fixes. Its digest binds the redacted report and approved canonical source, not the later host/device/Phoenix nonce-and-mutation implementation. No current-code physical run or equivalent retained provenance evidence exists."
    artifacts:
      - path: ".planning/phases/162-physical-iphone-adoption-proof/evidence/physical_iphone/proof-lane-evidence.json"
        issue: "Its commit_ref is an ancestor of the three provenance/cleanup fixes, so it cannot attest their physical execution."
      - path: "examples/phoenix_host/lib/crosswake_example/physical_iphone_proof_host.ex"
        issue: "Current host code injects and cleans provenance correctly, but deterministic tests cannot demonstrate that the retained device report used this code."
    missing:
      - "Run the standard host-owned physical-iPhone proof once with the corrected provenance path, retain its new redacted two-file record, and independently recheck the current source-bound evidence before restoring device-evidence support."
---

# Phase 162: Physical-iPhone Adoption Proof Verification Report

**Phase Goal:** Prove offline answers, offline audio, kill/relaunch persistence, exactly-once replay, conflict recovery, account isolation, and remote disablement on a physical iPhone.
**Verified:** 2026-08-27T20:00:00Z
**Status:** gaps_found
**Re-verification:** Yes — after Plans 12–15 and the final provenance/cleanup review fixes.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Verified pronunciation audio plays offline on a physical iPhone. | ✓ VERIFIED | The retained redacted physical record contains the closed pack/audio assertion, and current adapter/contract coverage remains intact. |
| 2 | Selected and free-form answers survive offline use and kill/relaunch, then reconnect and reconcile exactly once until the outbox is empty. | ✗ FAILED | Current Swift/Phoenix code and deterministic tests implement the path, but the only physical record predates the required provenance binding and cannot prove the corrected end-to-end run. |
| 3 | Reconnect applies accepted events exactly once and exposes rejection/conflict recovery. | ✗ FAILED | Current focused Phoenix authority suite and Chromium recovery test pass, but no physically executed, corrected-provenance record attests the joined device/Phoenix path. |
| 4 | Account switching, logout, and server disablement fail closed without data loss or cross-scope replay. | ✗ FAILED | Current authority code/test coverage is substantive, but the retained physical result was produced before its host/device/Phoenix proof ticket was bound and cleaned on every failure exit. |
| 5 | The public support claim remains limited to one adopter flow on one iOS runtime line. | ✗ FAILED | The wording stays narrow, but it currently promotes `device evidence` from the stale-provenance record; the claim is not earned on the current authority path. |

**Score:** 1/5 truths verified (0 present, behavior-unverified).

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `ProofLaneDriver.swift` / `ProofLaneApp.swift` | Value-carrying, scope-partitioned journal and foreground replay | ✓ VERIFIED | UI forwards a nonempty free-form string before clearing the draft; the journal stores a scoped record and replay uses the recovered record. Contract tests cover value forwarding, recovery, fencing, and redaction. |
| Phoenix proof host and authority | Single-use provenance, expected mutation binding, fail-closed replay, cleanup | ✓ VERIFIED | Current code injects the ticket inputs, accepts replay only for an active matching nonce/mutation pair, checks the persisted row, and removes run state through an idempotent cleanup callback. Focused host/authority tests passed. |
| `evidence/physical_iphone/` | Current-code, source-bound physical record | ✗ STALE PROVENANCE | Record/marker integrity and schema are valid, but the record pins a code revision from before all provenance fixes. Evidence does not cryptographically establish later code execution. |
| Support renderer and guide | Narrow support truth derived only from valid physical authority | ✗ UNWIRED AUTHORITY | Renderer parity passes, but the rendered `device evidence` row depends on the stale record rather than a corrected-path physical proof. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Free-form UI | scoped local journal | `submitFreeFormAnswerOffline(_:)` | ✓ WIRED | The actual value is passed to the adapter; draft clearing follows only a passed result. |
| Recovered journal record | Phoenix replay authority | foreground `/study/sync` transport | ✓ WIRED | Current driver carries the original scoped record and mutation ID through the existing authority route; focused Phoenix tests pass. |
| Device-run ticket | Phoenix acceptance and backend producer | matching nonce plus expected mutation ID | ✓ WIRED | `ReplayAuthority`, `PhysicalIphoneAuthority`, and run provenance require the matching active pair; stale/wrong values are negative-tested. |
| Runner exit | host provenance cleanup | required `cleanup_run` callback | ✓ WIRED | The task runs cleanup in `after`, fails closed on cleanup failure, and regressions cover malformed reports and join exits. |
| Retained physical record | corrected provenance implementation | pinned current code/run evidence | ✗ NOT WIRED | The physical record was generated before the binding and cleanup implementation existed. |
| Support row | corrected physical authority | retained evidence admission | ✗ NOT WIRED | The guide is deterministic but has no current-provenance physical input. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| iOS study flow | free-form draft / scoped record | user field → scoped Application Support journal → replay request | Yes in current code and contract coverage | ✓ FLOWING |
| Physical provenance | opaque ticket and expected mutation ID | host launch configuration → device environment → replay/session → persisted-row check | Yes in current code and focused Phoenix tests | ✓ FLOWING, NOT PHYSICALLY ATTESTED |
| Retained record | closed assertion envelope | prior device/Phoenix producers | Redacted record is structurally real, but predates current provenance | ✗ STALE |
| Support row | canonical matrix | renderer | Yes, but its device-evidence premise is stale | ✗ HOLLOW AUTHORITY |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Root compile | `mix compile --warnings-as-errors` | exit 0 | ✓ PASS |
| Template/evidence/report-task contracts | focused root `mix test` suite | 121 tests, 0 failures | ✓ PASS |
| Phoenix proof host and authority | focused example-host ExUnit suite | 21 tests, 0 failures | ✓ PASS |
| Browser rejected-work recovery | targeted Chromium Playwright test | 1 passed | ✓ PASS |
| Current physical proof | standard host-owned device run | Not run by verifier; retained run predates the corrected provenance code | ✗ REQUIRED, MISSING |

### Requirements Coverage

| Requirement | Description | Status | Evidence |
| --- | --- | --- | --- |
| DEVICE-01 | Verified pack installation and offline audio | ✓ SATISFIED | Closed device assertion in retained record; current pack contracts remain intact. |
| DEVICE-02 | Selected/free-form queue, relaunch, reconnect, exactly-once drain | ✗ BLOCKED | Fixed code is present/tested, but no corrected-provenance physical execution proves it. |
| DEVICE-03 | Visible recoverable rejection/conflict outcomes | ✗ BLOCKED | Deterministic Phoenix/browser evidence passes; joined physical proof under current provenance is absent. |
| DEVICE-04 | No cross-scope replay after logout/account switch | ✗ BLOCKED | Current authority coverage passes; physical attestation is stale. |
| DEVICE-05 | Server-side entry/replay disablement retains queued work | ✗ BLOCKED | Current authority coverage passes; physical attestation is stale. |
| DEVICE-06 | Dated redacted artifact | ✗ BLOCKED | Artifact is schema/digest-valid but cannot attest the material provenance controls now required for its authority. |
| DEVICE-07 | Narrow one-flow/one-runtime support claim | ✗ BLOCKED | Scope language is narrow, but promotion is based on the invalidated proof authority. |

No Phase 162 requirement is orphaned from plans. The completion marks in `REQUIREMENTS.md` are planning state, not verification evidence.

### Anti-Patterns Found

| File | Pattern | Severity | Impact |
| --- | --- | --- | --- |
| retained physical evidence record | code provenance predates material security/provenance fixes | 🛑 BLOCKER | A real device result cannot be treated as proof of a code path it did not execute. |
| `guides/support_matrix.md` | `device evidence` restored from that retained record | 🛑 BLOCKER | Public support is promoted without current physical authority. |
| example-host full suite | five failures in page-title/stylesheet and Chimeway migration/concurrency tests | ℹ️ INFO | Reproduced; their files/routes concern stylesheet/title and Chimeway migration/concurrency behavior, not Phase 162 proof, replay, evidence, or support wiring. Focused Phase 162 suites pass. |

### Gaps Summary

Plans 12–13 close the prior free-form and serialization defects in the current tree. The review fixes also correctly add a single-use opaque proof ticket, expected mutation binding, and all-exit cleanup; their focused regressions pass. Those facts make the old physical run insufficient rather than sufficient: its pinned code revision predates every material provenance fix, and the retained redacted report has no mechanism to prove that later code ran on the device.

This is a fail-closed escalation gate. A fresh standard host-owned physical run under the corrected provenance path is required; deterministic tests and the prior signed device artifact must not substitute for it. Until then, requirements/status and the public support row should not claim completed device evidence.

---

_Verified: 2026-08-27T20:00:00Z_
_Verifier: the agent (gsd-verifier)_
