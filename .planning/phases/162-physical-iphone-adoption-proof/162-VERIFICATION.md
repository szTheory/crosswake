---
phase: 162-physical-iphone-adoption-proof
verified: 2026-08-04T22:02:38Z
status: gaps_found
score: 0/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "A dated, redacted physical-iPhone artifact proves the ten-step first-adopter exit test."
    status: failed
    reason: "No physical artifact exists, and the sole production command rejects --promote and never invokes Evidence.promote/3."
    artifacts:
      - path: "lib/mix/tasks/crosswake.proof_lane.physical_iphone.ex"
        issue: "@switches omits :promote; run/1 supplies no host configuration or report providers; no Evidence.promote/3 call exists."
      - path: ".planning/phases/162-physical-iphone-adoption-proof/evidence/physical_iphone/proof-lane-evidence.json"
        issue: "Missing; expected while external preflight is blocked, but no future eligible run can publish it through the current command."
    missing:
      - "Wire a closed host-owned configuration and --run --promote path to report production, Evidence.promote/3, Evidence.check/2, and no-replace publication."
  - truth: "Device-local and Phoenix authority reports join into one canonical physical-proof candidate."
    status: failed
    reason: "Generated Swift/Phoenix producers emit envelopes/entries without owner values, while the Mix join accepts only owner-tagged bare lists; no parser bridges the contracts."
    artifacts:
      - path: "priv/templates/crosswake/proof_lane/ios/ProofLaneDriver.swift.eex"
        issue: "PhysicalIphoneDeviceReport emits schema_version/device_class/assertions whose entries have id/outcome only."
      - path: "priv/templates/crosswake/proof_lane/test/crosswake_proof_lane_test.exs.eex"
        issue: "backend_authority_report/0 emits id/outcome only."
      - path: "lib/mix/tasks/crosswake.proof_lane.physical_iphone.ex"
        issue: "report_from/3 requires a list and join_reports/3 requires :owner, so generated reports cannot be consumed."
    missing:
      - "Define and parse one canonical serialized envelope; derive ownership from PhysicalIphoneContract rather than trusting producer input."
  - truth: "Phoenix independently proves replay, recovery, scope fencing, and entry/replay disablement without fabricating evidence authority."
    status: failed
    reason: "The fixture reports PI-REDACTED-PROMOTION as passed without evidence validation/publication, and its entry-disablement check calls the same replay endpoint as replay-disablement."
    artifacts:
      - path: "examples/phoenix_host/test/crosswake_example/local_first/physical_iphone_authority_test.exs"
        issue: "run/0 unconditionally maps PI-REDACTED-PROMOTION to passed after replay callbacks; entry_disablement/0 and replay_disablement/0 both invoke SyncController.sync_events/4 with feature denial."
    missing:
      - "Produce redacted-promotion only after real evidence build/promotion/check, and independently exercise the actual route-entry gate."
  - truth: "The physical-iPhone proof executes verified offline audio, offline selected/free-form answers, kill/relaunch persistence, exactly-once replay, conflict recovery, account isolation, and server disablement."
    status: failed
    reason: "The required signed host/device/route prerequisites are absent and no artifact or device run exists; simulation and synthetic unit callbacks cannot substitute."
    artifacts:
      - path: ".planning/todos/TODO-002-first-b2c-adopter-route-inputs.md"
        issue: "No eligible validated sanitized route row is available."
      - path: ".planning/phases/162-physical-iphone-adoption-proof/evidence/physical_iphone/proof-lane-evidence.json"
        issue: "Absent; no dated device evidence or completion marker is present."
    missing:
      - "After repairing the production path, supply the eligible route row, current generated lane, signed host/backend adapters and controls, and selected physical iPhone; then run and verify the promotion command."
  - truth: "The support claim is limited to one adopter flow on one iOS runtime line."
    status: failed
    reason: "The support matrix correctly remains verification-required/no shipped support claim because physical promotion did not occur; therefore the requested resulting support claim has not been earned."
    artifacts:
      - path: "guides/support_matrix.md"
        issue: "States physical-iPhone offline study is verification required and has no shipped support claim."
    missing:
      - "Publish the narrow claim only after a complete verified physical artifact exists."
---

# Phase 162: Physical-iPhone Adoption Proof Verification Report

**Phase Goal:** Prove offline answers, offline audio, kill/relaunch persistence, exactly-once replay, conflict recovery, account isolation, and remote disablement on a physical iPhone.

**Verified:** 2026-08-04T22:02:38Z  
**Status:** gaps_found — phase goal not achieved.  
**Re-verification:** No — initial verification.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Verified pronunciation audio plays offline. | ✗ FAILED | Generated Swift has an adapter protocol, but no signed physical host adapter/run or dated artifact exists. The required preflight returns `PI-PREFLIGHT-INVENTORY`. |
| 2 | Selected and free-form answers survive offline use and kill/relaunch. | ✗ FAILED | The sequence is a generated observation protocol only. No physical execution or evidence proves the transition. |
| 3 | Reconnect applies accepted events exactly once and exposes rejection/conflict recovery. | ✗ FAILED | Synthetic Phoenix fixture passes, but its result cannot be consumed by the Mix task's owner-required report join; no physical/backend joined candidate exists. |
| 4 | Logout, account switching, and server disablement fail closed without loss or cross-scope replay. | ✗ FAILED | The fixture exercises scope/logout replay fences, but entry disablement is not tested independently: both disablement functions call `SyncController.sync_events/4`. |
| 5 | The support claim remains one adopter flow on one iOS runtime line. | ✗ FAILED | The guide honestly retains `verification required` and "no shipped support claim" because no promoted physical evidence exists. |

**Score:** 0/5 truths verified (0 present, behavior-unverified).

## Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `physical_iphone_contract.ex` | Closed device/runtime/assertion vocabulary | ✓ VERIFIED | Substantive fixed ten-ID manifest, ownership and runtime-line validation. |
| `physical_iphone_preflight.ex` | Fail-closed prerequisite gate | ✓ VERIFIED | Ordered callbacks fail closed; direct CLI returns only a stable blocked object for unavailable inventory. |
| `crosswake.proof_lane.physical_iphone.ex` | Production run and promotion entry point | ✗ STUB/WIRING GAP | Unit-injectable join exists, but `run/1` passes `[]`, omits `--promote`, and does not call evidence promotion. |
| Generated Swift/Phoenix reports | Canonical owner-disjoint report producers | ✗ UNWIRED | Their serialized output does not meet the Mix join's list-plus-owner input contract. |
| `evidence/physical_iphone/proof-lane-evidence.json` | Dated redacted artifact and completion marker | ✗ MISSING | Correctly absent while prerequisites are unavailable; current production wiring could not create it even after they are supplied. |
| `guides/support_matrix.md` | Narrow post-promotion support claim | ✓ HONEST CURRENT STATE | Correctly says verification-required/no shipped support claim; it does not fulfill the phase outcome. |

## Key Link Verification

| From | To | Status | Details |
| --- | --- | --- | --- |
| Production Mix task | Preflight | ✓ WIRED | `run_with/2` calls `PhysicalIphonePreflight.check/1` before its injected runner. |
| Production Mix task | Host configuration/report providers | ✗ NOT WIRED | `run/1` calls `run_with(args, [])`; no config provider or concrete host seam is loaded. |
| Generated Swift/Phoenix report | Mix candidate join | ✗ NOT WIRED | Producers omit `owner` and use report envelopes; consumer accepts owner-tagged bare lists only. |
| Mix candidate | `Evidence.promote/3` / `Evidence.check/2` | ✗ NOT WIRED | No `:promote` switch or evidence call exists; `--run --promote --json` returns `PI-COMMAND-OPTIONS`. |
| Phoenix entry-disablement assertion | Actual route-entry gate | ✗ NOT WIRED | `entry_disablement/0` calls the replay endpoint, same as `replay_disablement/0`. |

## Data-Flow Trace (Level 4)

| Artifact | Data | Source | Status |
| --- | --- | --- | --- |
| Physical Mix task | Device/backend reports | Synthetic test callbacks only; production `run/1` supplies none | ✗ DISCONNECTED |
| Evidence promotion | Physical candidate | No caller reaches `Evidence.promote/3` | ✗ DISCONNECTED |
| Support matrix | Physical evidence | No dated record exists; guide remains unpromoted | ✓ HONESTLY BLOCKED |

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Contract/preflight/join/evidence unit coverage | `mix test test/crosswake/proof_lane/physical_iphone_preflight_test.exs test/mix/tasks/crosswake.proof_lane.physical_iphone_test.exs test/crosswake/proof_lane/evidence_test.exs --max-failures 1` | 36 tests, 0 failures | ✓ PASS — synthetic contracts only |
| Example Phoenix authority fixture | `(cd examples/phoenix_host && MIX_ENV=test mix test test/crosswake_example/local_first/physical_iphone_authority_test.exs --max-failures 1)` | 1 test, 0 failures | ⚠️ MISLEADING COVERAGE — it does not test actual entry gating or promotion |
| Expected unavailable preflight | `mix crosswake.proof_lane.physical_iphone --preflight-only --json` | exit 2; `{"outcome":"blocked","rule_id":"PI-PREFLIGHT-INVENTORY"}` | ✓ PASS — expected external block |
| Required production promotion command | `mix crosswake.proof_lane.physical_iphone --run --promote --json` | exit 2; `{"outcome":"blocked","rule_id":"PI-COMMAND-OPTIONS"}` | ✗ FAIL — implementation defect |

## Requirements Coverage

| Requirement | Status | Evidence |
| --- | --- | --- |
| DEVICE-01 | ✗ BLOCKED | No physical pack/audio artifact; only generated adapter contract. |
| DEVICE-02 | ✗ BLOCKED | No physical uninterrupted flow; report producer/consumer contracts disagree. |
| DEVICE-03 | ✗ BLOCKED | No joined physical evidence; Phoenix recovery fixture is synthetic. |
| DEVICE-04 | ✗ BLOCKED | No physical proof; account fencing unit fixture does not establish device flow. |
| DEVICE-05 | ✗ BLOCKED | Entry gate is not independently tested and proof cannot run/promote. |
| DEVICE-06 | ✗ BLOCKED | Evidence validator is substantive, but no dated artifact exists and production does not invoke promotion. |
| DEVICE-07 | ✗ BLOCKED | Guide is intentionally unpromoted; resulting narrow claim has not been produced. |

No orphaned Phase 162 requirements were found: all DEVICE-01 through DEVICE-07 are declared by the plans.

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- |
| `lib/mix/tasks/crosswake.proof_lane.physical_iphone.ex` | 7, 10-11, 52-59 | Missing `--promote`, empty production options, no evidence call | 🛑 BLOCKER | Eligible hosts cannot run/publish proof. |
| `priv/templates/crosswake/proof_lane/ios/ProofLaneDriver.swift.eex` | 74-88 | Report omits owner required by consumer | 🛑 BLOCKER | Generated device report cannot join. |
| `priv/templates/crosswake/proof_lane/test/crosswake_proof_lane_test.exs.eex` | 98-124 | Fabricated all-passed backend report incl. promotion | 🛑 BLOCKER | Backend can assert promotion without evidence. |
| `examples/phoenix_host/test/crosswake_example/local_first/physical_iphone_authority_test.exs` | 133-159 | Entry and replay disablement use identical replay call | 🛑 BLOCKER | DEVICE-05 entry path remains unproved. |

No unreferenced `TBD`/`FIXME`/`XXX` debt markers were found in the inspected implementation files.

## Escalation Gate: Remediation Paths

The absent sanitized route row, signed host/backend, required adapters, and selected physical iPhone are valid external prerequisites. They explain why the preflight currently blocks and do **not** by themselves count as an implementation defect. However, four independent implementation defects would still prevent a truthful run after those prerequisites arrive.

1. Repair the production path first: accept `--promote` only with `--run`, load a closed host-owned configuration, obtain real reports, call `Evidence.promote/3`, then `Evidence.check/2`; add an end-to-end synthetic host integration test for one publication.
2. Define one report envelope shared by generated Swift, generated Phoenix, and the Mix task. Parse/validate schema and class; derive assertion ownership from `PhysicalIphoneContract`.
3. Remove Phoenix ownership of `PI-REDACTED-PROMOTION`; make it the result of successful evidence build, promotion, and final scan only. Test actual route entry independently from replay denial.
4. Once the code path is repaired, provide the external prerequisites and run the exact required physical command. Inspect the published artifact and only then update support truth/validation sealing.

The first three are code-gap closure work. The fourth is a later external execution gate; no later roadmap phase specifically defers these Phase 162 requirements.

---

_Verified: 2026-08-04T22:02:38Z_  
_Verifier: the agent (gsd-verifier)_
