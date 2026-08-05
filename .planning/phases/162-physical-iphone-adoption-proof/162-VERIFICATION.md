---
phase: 162-physical-iphone-adoption-proof
verified: 2026-08-05T02:46:02Z
status: gaps_found
score: 0/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 0/5
  gaps_closed:
    - "The physical Swift sequence now stops after the first blocked or unavailable prerequisite and tests the forbidden later calls."
    - "Malformed physical report entries now return PI-ASSERTIONS-COMPLETE and Evidence.build/1 fails closed."
    - "The advisory join now requires actual Phoenix producer stdout; it no longer writes a fabricated backend-success envelope."
    - "Required study-status XCUITests now fail with PL-STUDY-STATUS-HOST-ADAPTER when their host composition is absent."
    - "Recovery navigation now requires a Phoenix-approved capability and fixed approved route, not merely same-origin syntax."
  gaps_remaining:
    - "No dated physical-iPhone evidence artifact proves the required flow."
  regressions: []
gaps:
  - truth: "A dated, redacted physical-iPhone artifact proves verified offline audio, offline answer persistence, relaunch, exactly-once replay, recovery, scope fencing, and remote disablement."
    status: failed
    reason: "The repository contains no physical evidence record or completion marker. The production command exits 2 at PI-PREFLIGHT-INVENTORY because TODO-002, an eligible configured host/backend, required adapters, and a selected physical iPhone are absent. Simulator, browser, fixture, and advisory-report results cannot satisfy DEVICE-01 through DEVICE-06."
    artifacts:
      - path: ".planning/phases/162-physical-iphone-adoption-proof/evidence/physical_iphone/proof-lane-evidence.json"
        issue: "Missing; no actual physical-device run has produced a promotable record."
      - path: "guides/support_matrix.md"
        issue: "Correctly retains physical-iPhone offline study as verification required rather than claiming shipped support."
    missing:
      - "An eligible sanitized TODO-002 route row, signed/configured host and backend authority adapters, verified media adapter, selected physical iPhone, and one successful mix crosswake.proof_lane.physical_iphone --run --promote --json execution followed by Evidence.check/2 on the fixed destination."
---

# Phase 162: Physical-iPhone Adoption Proof Verification Report

**Phase Goal:** Prove offline answers, offline audio, kill/relaunch persistence, exactly-once replay, conflict recovery, account isolation, and remote disablement on a physical iPhone.
**Verified:** 2026-08-05T02:46:02Z
**Status:** gaps_found
**Re-verification:** Yes — after Plans 162-07 and 162-08 gap closure.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Verified pronunciation audio plays offline. | ✗ FAILED | No physical iPhone report or promoted evidence exists. The default production command blocks before runner work. |
| 2 | Selected and free-form answers survive offline use and kill/relaunch. | ✗ FAILED | The generated sequence is guarded and tested, but no qualifying physical-device run proves the state transition. |
| 3 | Reconnect applies accepted events exactly once and exposes rejection/conflict recovery. | ✗ FAILED | Phoenix authority fixture and browser recovery test pass, but neither is a joined physical-device/backend proof artifact. |
| 4 | Account switching, logout, and server disablement fail closed without losing or crossing data. | ✗ FAILED | Independent authority tests pass, but no qualifying physical proof demonstrates the full route on a selected device. |
| 5 | The support claim remains one adopter flow on one iOS runtime line. | ✗ FAILED | The guide is correctly unpromoted (`verification required`), not the required evidence-backed resulting support claim. |

**Score:** 0/5 truths verified (0 present, behavior-unverified).

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `physical_iphone_contract.ex` + `physical_iphone_preflight.ex` | Closed physical-only contract and ordered preflight | ✓ VERIFIED | 162-01 artifacts are substantive and `run_with/2` calls preflight before any runner invocation. |
| Physical Mix task + `physical_iphone_host.ex` | Host-loaded production orchestration | ✓ VERIFIED | Trusted report parsing/joining and `Evidence.promote/3` → `Evidence.check/2` are wired after ready preflight. |
| `ProofLaneDriver.swift.eex` | Ordered, fail-closed device sequence | ✓ VERIFIED | Every awaited adapter operation is followed by a guard; terminal reports mark later observations without invoking later host work. |
| `PhysicalIphoneContract.validate_report/1` | Total non-echoing report validation | ✓ VERIFIED | Exact atom-key shape is checked before `Map.fetch!`; malformed entries return `PI-ASSERTIONS-COMPLETE`. |
| Phoenix authority template + fixture | Independent replay/idempotency/entry/replay-gate proof | ✓ VERIFIED | Host callback producer is separate from device output; first-party fixture exercises `SyncController` and `RouteGate`. |
| Advisory script | Exact device/Phoenix byte join without promotion | ✓ VERIFIED | Requires a non-empty successful producer, captures it unchanged into `BACKEND_REPORT_FILE`, then parses and joins it. |
| Study-status XCUITests | Required host-composition accessibility checks | ✓ VERIFIED | Missing or invalid `CROSSWAKE_PROOF_LANE_STUDY_HOST_ADAPTER` calls `XCTFail("PL-STUDY-STATUS-HOST-ADAPTER")`. |
| Recovery surface | Phoenix-approved bounded recovery route only | ✓ VERIFIED | Default capability is unavailable; browser permits only approved `/saved-answers`, not same-origin input alone. |
| `evidence/physical_iphone/proof-lane-evidence.json` + `.complete` | Dated redacted physical proof | ✗ MISSING | No candidate exists anywhere in the Phase 162 evidence destination. This absence is correct until the external gate is met, but the goal is therefore unachieved. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Mix task | `PhysicalIphonePreflight.check/1` | `run_with/2` | ✓ WIRED | Preflight is evaluated at task line 47 before runner work. |
| Physical host callbacks | report parser/join | trusted `:device_local` / `:backend_authority` slots | ✓ WIRED | Owner is derived from the contract, not report bytes. |
| Complete candidate | evidence publication | `Evidence.promote/3` then `Evidence.check/2` | ✓ WIRED | Calls occur only after canonical parse/join and ready preflight. |
| Swift sequence | host adapter operations | ordered `guard` after each `await` | ✓ WIRED | No later call follows an unsuccessful prerequisite. |
| Advisory script | Phoenix producer | exact stdout → `BACKEND_REPORT_FILE` → public parser | ✓ WIRED | Script fails on unset, failing, silent, malformed, incomplete, or wrong-slot producer output. |
| Phoenix recovery capability | browser CTA | controller data attributes → `validatedRecoveryDestination()` | ✓ WIRED | Capability must be `approved_saved_answers`; URL validation also pins the fixed path. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Physical Mix task | device/backend reports | Configured host callbacks after preflight | No eligible host is configured in this repository | ⚠️ EXTERNALLY BLOCKED |
| Evidence promotion | canonical physical candidate | Complete joined reports plus approved hashes | No physical candidate exists | ⚠️ EXTERNALLY BLOCKED |
| Recovery CTA | recovery capability | Phoenix `OfflineController` | Default is deliberately `unavailable`; unapproved URLs do not flow through | ✓ FAIL-CLOSED |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| 162-07/08 contract, evidence, template, and script regressions | `mix test ...physical_iphone_preflight... physical_iphone... evidence... template_contract... physical_iphone_report_contract_script... --max-failures 1` | 57 tests, 0 failures | ✓ PASS |
| Independent Phoenix authority and recovery route | Phoenix authority/router tests + one Playwright recovery spec | 8 ExUnit + 1 Playwright, all passed | ✓ PASS |
| Support truth remains unpromoted | support-matrix/renderer suite | 71 tests, 0 failures | ✓ PASS |
| Production physical promotion | `mix crosswake.proof_lane.physical_iphone --run --promote --json` | exit 2; only `{"outcome":"blocked","rule_id":"PI-PREFLIGHT-INVENTORY"}` | ✓ PASS — expected fail-closed external gate |

### Requirements Coverage

| Requirement | Status | Evidence |
| --- | --- | --- |
| DEVICE-01 | ✗ BLOCKED | No selected physical iPhone/offline-audio artifact. |
| DEVICE-02 | ✗ BLOCKED | No physical offline/relaunch/replay artifact. |
| DEVICE-03 | ✗ BLOCKED | Synthetic Phoenix/browser recovery coverage is not device evidence. |
| DEVICE-04 | ✗ BLOCKED | Synthetic scope-fence coverage is not a full physical route proof. |
| DEVICE-05 | ✗ BLOCKED | Independent entry/replay denial passes, but physical evidence is absent. |
| DEVICE-06 | ✗ BLOCKED | Required dated redacted record and completion marker are absent. |
| DEVICE-07 | ✗ BLOCKED | Guide honestly stays `verification required`; no resulting support claim is earned. |

All DEVICE requirements are declared by one or more Phase 162 plans; no orphaned Phase 162 requirements were found. Their `Pending` status in `REQUIREMENTS.md` remains correct.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `test/crosswake/proof_lane/physical_iphone_report_contract_script_test.exs` | 38-49 | Positive shell test replaces `mix` with a grep-only shim, so that test itself does not execute the actual Elixir parser/join. | ⚠️ WARNING | It proves producer bytes are passed to the seam, but not the complete production parse/join. Other focused task tests cover parser/join behavior; the physical promotion path remains externally blocked regardless. |

The only Phase-owned TODO marker references formal follow-up `TODO-002`; no unreferenced `TBD`, `FIXME`, or `XXX` debt markers were found.

## Gaps Summary

Plans 162-07 and 162-08 close the prior implementation and review gaps: prerequisite short-circuiting, malformed-report totality, real Phoenix producer bytes, required accessibility composition, and server-owned recovery navigation all have direct code and targeted test evidence. The phase still fails its goal-backward test because its roadmap contract is a **dated physical-iPhone artifact**, not proof infrastructure.

This is an external escalation gate, not a reason to change requirement or support status. Obtain TODO-002’s eligible route input, the signed/configured host/backend and media adapters, and a selected physical iPhone. Then run:

`mix crosswake.proof_lane.physical_iphone --run --promote --json`

Require a passed result, verify `Evidence.check/2` against the fixed evidence destination, then re-verify before changing DEVICE statuses or support truth.

---

_Verified: 2026-08-05T02:46:02Z_
_Verifier: the agent (gsd-verifier)_
