---
phase: 162-physical-iphone-adoption-proof
verified: 2026-08-04T23:50:46Z
status: gaps_found
score: 0/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 0/5
  gaps_closed:
    - "Production CLI now accepts --run --promote --json and reaches checked no-replace evidence orchestration through a configured host adapter."
    - "Owner-free Swift/Phoenix report envelopes now parse in trusted slots and join with contract-derived ownership."
    - "Phoenix removes fabricated promotion and exercises RouteGate entry denial separately from replay admission."
  gaps_remaining:
    - "No physical-iPhone artifact proves the required device flow."
    - "The generated Swift driver does not short-circuit after a failed prerequisite."
    - "The public physical-report validator raises on non-map list entries."
  regressions: []
gaps:
  - truth: "A dated, redacted physical-iPhone artifact proves verified offline audio, offline answer persistence, relaunch, exactly-once replay, recovery, scope fencing, and remote disablement."
    status: failed
    reason: "Repository-default production execution correctly stops at PI-PREFLIGHT-INVENTORY because TODO-002, an eligible configured host, signed controls, and a selected physical iPhone are absent. No physical artifact or completion marker exists. Synthetic and simulator evidence cannot satisfy DEVICE-01 through DEVICE-06."
    artifacts:
      - path: ".planning/phases/162-physical-iphone-adoption-proof/evidence/physical_iphone/proof-lane-evidence.json"
        issue: "Absent; required physical proof has not occurred."
      - path: "guides/support_matrix.md"
        issue: "Correctly retains physical-iPhone offline study as verification required with no shipped support claim."
    missing:
      - "After code gaps below are fixed, provide the eligible sanitized route row, configured signed host/backend adapters and controls, verified media adapter, and selected physical iPhone; then run mix crosswake.proof_lane.physical_iphone --run --promote --json and verify Evidence.check/2 on its fixed destination."
  - truth: "A failed physical-device prerequisite causes no later mutation, replay, or recovery operation."
    status: failed
    reason: "PhysicalIphoneSequence.run invokes every adapter method even after a blocked or unavailable pack, audio, entry, selected-answer, or free-form-answer result. combine/2 changes only the report outcome, so a known-invalid device run can still submit/replay real host work."
    artifacts:
      - path: "priv/templates/crosswake/proof_lane/ios/ProofLaneDriver.swift.eex"
        issue: "Lines 115-120 eagerly call later adapter operations instead of short-circuiting at prerequisite failure; no fake-adapter regression test asserts that later calls are absent."
    missing:
      - "Short-circuit each failed prerequisite, emit blocked/unavailable observations for unrun assertions, and add per-step fake-adapter tests proving no subsequent method is called."
  - truth: "Malformed physical-report input fails closed with a stable rule rather than crashing evidence validation."
    status: failed
    reason: "PhysicalIphoneContract.validate_report([nil]) raises BadMapError at Map.get/2 rather than returning {:error, \"PI-ASSERTIONS-COMPLETE\"}. Evidence.decode_physical_run_contract/1 calls this public validator, so malformed integration input can crash the evidence path."
    artifacts:
      - path: "lib/crosswake/proof_lane/physical_iphone_contract.ex"
        issue: "Line 48 maps Map.get/2 over unvalidated list entries."
      - path: "lib/crosswake/proof_lane/evidence.ex"
        issue: "Line 626 relies on validate_report/1 as its closed physical-report validation boundary."
    missing:
      - "Validate entry maps before reading :id and add regression cases for [nil], [:bad], and malformed maps through both validate_report/1 and Evidence.build/1."
---

# Phase 162: Physical-iPhone Adoption Proof Verification Report

**Phase Goal:** Prove offline answers, offline audio, kill/relaunch persistence, exactly-once replay, conflict recovery, account isolation, and remote disablement on a physical iPhone.
**Verified:** 2026-08-04T23:50:46Z
**Status:** gaps_found
**Re-verification:** Yes — after Plan 162-06 gap closure.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Verified pronunciation audio plays offline. | ✗ FAILED | No eligible physical host/device run or promoted artifact exists; default promoting command blocks at `PI-PREFLIGHT-INVENTORY`. |
| 2 | Selected and free-form answers survive offline use and kill/relaunch. | ✗ FAILED | No physical execution exists. Moreover, the generated driver keeps invoking submissions/relaunch after an earlier failed prerequisite. |
| 3 | Reconnect applies accepted events exactly once and exposes rejection/conflict recovery. | ✗ FAILED | Phoenix fixture passes synthetically, but no joined device/backend physical candidate has been produced; failed device prerequisites can still reach replay. |
| 4 | Account switching, logout, and server disablement fail closed without losing or crossing data. | ✗ FAILED | The independent Phoenix gate fixture passes, but no physical proof exists and a blocked device sequence can continue into mutating operations. |
| 5 | The support claim remains one adopter flow on one iOS runtime line. | ✗ FAILED | Current guide is appropriately narrow and unpromoted; the required resulting, evidence-backed physical support claim has not been earned. |

**Score:** 0/5 truths verified (0 present, behavior-unverified).

## Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `physical_iphone_preflight.ex` | Ordered fail-closed prerequisite gate | ✓ VERIFIED | `check/1` blocks default configuration before runner work; CLI emitted only `PI-PREFLIGHT-INVENTORY`. |
| `crosswake.proof_lane.physical_iphone.ex` | Closed host-loaded run/promotion orchestration | ✓ VERIFIED | Parses trusted report slots, joins exact subsets, invokes evidence promotion/check only after ready preflight. Focused suite passed. |
| `physical_iphone_host.ex` | Closed configured host adapter boundary | ✓ VERIFIED | Requires the five callback exports and wraps callback failure without echoing values. |
| `ProofLaneDriver.swift.eex` | Safe physical device sequence | ✗ STUB/WIRING GAP | Substantive template, but not fail-closed: later host operations still occur after a failed prerequisite. |
| `physical_iphone_contract.ex` | Stable report validation | ✗ STUB/WIRING GAP | Valid ordinary reports, but crashes on malformed list entries used by an evidence caller. |
| physical evidence artifact | Dated, redacted completion proof | ✗ MISSING | Correctly absent until real prerequisites and a physical run exist. |
| `guides/support_matrix.md` | Narrow evidence-backed support truth | ✓ HONEST CURRENT STATE | States verification required/no shipped support claim; it cannot fulfill DEVICE-07 yet. |

## Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Mix production task | `PhysicalIphonePreflight.check/1` | ready preflight before runner | ✓ WIRED | `run_with/2` calls preflight before `invoke_runner/2`. |
| Mix production task | configured host reports → `Evidence.promote/3` → `Evidence.check/2` | `--run --promote --json` | ✓ WIRED | Plan 162-06 added host loader, parsing/join, promotion, and post-publication check. |
| Generated Swift sequence | later adapter mutations/replay | ordered prerequisite gating | ✗ NOT WIRED | No conditional short circuit between calls at lines 115-120. |
| Physical report decoder | closed evidence validator | `validate_report/1` | ✗ NOT WIRED SAFELY | Decoder calls a validator that raises on `[nil]`, not a stable denial. |
| Phoenix entry assertion | `RouteGate.evaluate/4` | independent route-entry gate | ✓ WIRED | Fixture uses `RouteGate.evaluate/4`; replay denial separately calls `SyncController.sync_events/4`. |

## Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Mix physical task | device/backend reports | Configured host callbacks after preflight | No in-repo eligible host configured | ⚠️ EXTERNALLY BLOCKED |
| Evidence publication | canonical physical candidate | Parsed trusted producer slots + joined candidate | No physical candidate has been produced | ⚠️ EXTERNALLY BLOCKED |
| Swift device sequence | adapter operations | Host-supplied physical adapter | Can proceed after failed prerequisite | ✗ UNSAFE FLOW |

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Core preflight/report/evidence/template contracts | `mix test test/crosswake/proof_lane/physical_iphone_preflight_test.exs test/mix/tasks/crosswake.proof_lane.physical_iphone_test.exs test/crosswake/proof_lane/evidence_test.exs test/crosswake/proof_lane/template_contract_test.exs --max-failures 1` | 51 tests, 0 failures | ✓ PASS — does not cover CR-01/WR-01. |
| Phoenix authority checks | `cd examples/phoenix_host && MIX_ENV=test mix test ...physical_iphone_authority_test.exs ...replay_auth_test.exs ...sync_controller_test.exs --max-failures 1` | 8 tests, 0 failures | ✓ PASS — synthetic backend authority only. |
| Default promoting command blocks without artifact | `mix crosswake.proof_lane.physical_iphone --run --promote --json` | exit 2; only `{"outcome":"blocked","rule_id":"PI-PREFLIGHT-INVENTORY"}`; artifact absent | ✓ PASS — expected external gate. |
| Malformed report denial | `mix run -e '...validate_report([nil])'` | exit 1; `BadMapError` | ✗ FAIL (WR-01). |
| Generated Swift serialization gate | `bash script/verify_physical_iphone_report_contract.sh` | No successful result captured in this environment; it requires local Xcode/simulator execution and cannot replace physical evidence. | ? SKIP |

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| DEVICE-01 | 162-01, 03, 05, 06 | Physical verified pack/audio offline | ✗ BLOCKED | No physical host/device/artifact. |
| DEVICE-02 | 162-01, 02, 03, 06 | Offline answers, relaunch, exactly-once | ✗ BLOCKED | No physical proof; CR-01 permits later mutations after failure. |
| DEVICE-03 | 162-01, 02, 04, 06 | Visible retained rejection/conflict recovery | ✗ BLOCKED | Phoenix synthetic coverage exists, but no physical proof. |
| DEVICE-04 | 162-01, 02, 03, 06 | Logout/account-switch scope isolation | ✗ BLOCKED | Phoenix fixture exists, but no physical proof. |
| DEVICE-05 | 162-01, 02, 03, 06 | Independent server entry/replay disablement | ✗ BLOCKED | Independent fixture passes, but physical flow is unproved and unsafe after failed prerequisites. |
| DEVICE-06 | 162-01, 03, 05, 06 | Dated redacted artifact | ✗ BLOCKED | No dated artifact; malformed report input crashes the evidence validation route. |
| DEVICE-07 | 162-01, 05, 06 | Narrow one-flow/iOS support claim | ✗ BLOCKED | Guide honestly remains verification-required instead of the required evidence-backed claim. |

No orphaned Phase 162 requirements: every DEVICE-01 through DEVICE-07 is declared in at least one plan.

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `ProofLaneDriver.swift.eex` | 115-120 | Eager adapter calls after a blocked/unavailable prerequisite | 🛑 BLOCKER (CR-01) | A known-invalid proof attempt can still mutate/replay host data. |
| `physical_iphone_contract.ex` | 48 | `Map.get/2` over unconstrained report entries | 🛑 BLOCKER (WR-01) | Untrusted malformed input raises rather than failing closed; evidence path relies on it. |

No unreferenced `TBD`, `FIXME`, or `XXX` markers were found in inspected Phase 162 implementation files.

## Gaps Summary

The previous production-wiring gaps are closed: the current code has a configured host boundary, canonical report parsing/joining, evidence-owned promotion, and independent Phoenix entry/replay authority checks. Those repairs do not achieve the phase outcome because no eligible physical run exists.

More importantly, CR-01 is a direct fail-closed violation: the physical driver continues making real host calls after a prerequisite has already made the run invalid. WR-01 is also material rather than cosmetic because the public validator is used by the evidence decoder and crashes on malformed integration input. Both must be fixed before exposing an eligible host to the production command.

**Next action:** close CR-01 and WR-01 with the specified negative tests; then, when external prerequisites are genuinely available, run:

`mix crosswake.proof_lane.physical_iphone --run --promote --json`

Require `{"outcome":"passed", ...}`, then run `Crosswake.ProofLane.Evidence.check/2` against the fixed physical evidence destination before changing support truth.

---

_Verified: 2026-08-04T23:50:46Z_
_Verifier: the agent (gsd-verifier)_
