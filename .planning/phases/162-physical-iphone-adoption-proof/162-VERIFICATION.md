---
phase: 162-physical-iphone-adoption-proof
verified: 2026-08-26T17:56:46Z
status: gaps_found
score: 6/7 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 0/5
  gaps_closed:
    - "A digest-bound, source-bound physical evidence record and completion marker now exist."
  gaps_remaining:
    - "The free-form answer value is discarded; the claimed free-form persistence and relaunch proof is false."
    - "The advisory physical-report serialization script has no executable real-project success path."
  regressions:
    - "The prior unpromoted support row is now promoted despite the failed free-form behavior."
gaps:
  - truth: "The offline study route queues selected and free-form answers, survives kill/relaunch, reconnects, and reconciles exactly once until its outbox is empty."
    status: failed
    reason: "The physical iOS UI accepts free-form text but calls a no-argument adapter method; that adapter persists only a boolean marker and relaunch reads only that marker. The XCUITest therefore passes after discarding the value."
    artifacts:
      - path: "examples/phoenix_host/native/ios/CrosswakeProofLane/ProofLaneApp.swift"
        issue: "The draft is cleared after a no-content submit call."
      - path: "examples/phoenix_host/native/ios/CrosswakeProofLane/ProofLaneDriver.swift"
        issue: "The adapter stores and rehydrates only a boolean free-form marker."
      - path: "examples/phoenix_host/native/ios/CrosswakeProofLaneUITests/ProofLaneUITests.swift"
        issue: "The device test checks status labels, not recoverability of the submitted value or an integrity marker derived from it."
    missing:
      - "Pass the value to a scope-partitioned local journal and prove on relaunch that the same value, or a test-only non-exported integrity marker derived from it, is recoverable before emitting passed assertions."
  - truth: "The advisory physical-report serialization gate has an executable real-project success path."
    status: failed
    reason: "The script runs a simulator test whose generated adapter factory returns nil; its device report is unavailable. The subsequent join accepts only all-passed device entries. The passing ExUnit test stubs both xcodebuild and mix, so it does not execute the parser/join semantics."
    artifacts:
      - path: "script/verify_physical_iphone_report_contract.sh"
        issue: "It joins an unavailable simulator report as an all-passed physical report."
      - path: "priv/templates/crosswake/proof_lane/ios/CrosswakeProofLaneTests/ProofLaneContractTests.swift.eex"
        issue: "The selected contract-mode test invokes PhysicalIphoneSequence with nil adapter."
      - path: "test/crosswake/proof_lane/physical_iphone_report_contract_script_test.exs"
        issue: "Its positive case replaces the real join with shell grep stubs."
    missing:
      - "Validate the simulator envelope without an all-passed physical join, or use an explicitly serialization-only passed adapter and add an integration test that executes the real Elixir join."
---

# Phase 162: Physical-iPhone Adoption Proof Verification Report

**Phase Goal:** Prove the ten-step first-adopter offline study exit test on one physical iPhone and publish only the narrow one-flow/one-runtime support truth.
**Verified:** 2026-08-26T17:56:46Z
**Status:** gaps_found
**Re-verification:** Yes — after evidence promotion and Phase 162 Plans 09–11.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | A physical iPhone installs one verified pronunciation pack and plays audio while offline. | ✓ VERIFIED | The checked physical record includes the closed pack/audio assertion; the physical adapter verifies asset bytes before offline playback. |
| 2 | Selected and free-form answers are queued, survive kill/relaunch, reconnect, and reconcile exactly once. | ✗ FAILED | CR-01 confirmed: the free-form value never reaches persistence; only a boolean marker survives. This is not free-form mutation persistence. |
| 3 | Rejected/conflict outcomes are visible and recoverable; no silent last-write-wins path exists. | ✓ VERIFIED | Targeted Phoenix authority tests (8) and the focused browser recovery test (1) passed; the physical record includes the corresponding closed assertions. |
| 4 | Logout and account switching prevent cross-scope replay. | ✓ VERIFIED | The backend-authority producer exercises the account fence and the checked record carries its owner-scoped assertion. |
| 5 | A host flag denies entry and replay server-side without dropping queued work. | ✓ VERIFIED | Targeted Phoenix authority tests passed and the checked record contains the independent entry/replay assertions. |
| 6 | Durable evidence is redacted to the allowed schema and source-bound. | ✓ VERIFIED | `Evidence.check/2` passed: canonical JSON, digest marker, regular-file allowlist, exact schema, source digest, and physical record validation all passed. |
| 7 | Public support wording is limited to one first-adopter flow on the recorded iOS runtime line and excludes prohibited breadth. | ✓ VERIFIED | Renderer parity passed; the generated row limits the claim and explicitly excludes Android, background/generic sync, generic storage, multiple islands, simulator substitution, and every-iPhone coverage. |

**Score:** 6/7 truths verified (0 present, behavior-unverified).

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `evidence/physical_iphone/` | Complete redacted, digest-bound physical record | ✓ VERIFIED | Exactly the record and marker are present; source-bound `Evidence.check/2` passes. `Evidence.check/1` correctly returns `PL-EVIDENCE-HASH-SOURCE` because canonical source bytes are intentionally absent. |
| iOS study UI and adapter | Persist actual selected and free-form mutations across relaunch | ✗ FAILED | The selected/free-form path persists flags only; CR-01 is directly observable in the real app and test. |
| Phoenix authority producer | Backend replay, recovery, scope fence, and disablement authority | ✓ VERIFIED | Eight targeted ExUnit tests passed. |
| `verify_physical_iphone_report_contract.sh` | Advisory serialization validation | ✗ FAILED | CR-02 confirmed; a real generated simulator report is unavailable and cannot satisfy the script's all-passed join. |
| Support renderer and guide | Narrow one-flow/one-runtime public truth | ✓ VERIFIED | Byte-for-byte guide/renderer parity passed. |

### Key Link Verification

| From | To | Via | Status | Details |
| ---- | --- | --- | --- | --- |
| Free-form UI field | Local persistence adapter | Submit handler | ✗ NOT WIRED | The input is not an argument to the adapter, so its content cannot flow to persistence. |
| Physical XCUITest | Evidence report | Closed assertion envelope | ⚠️ PARTIAL | It emits passed free-form/relaunch assertions after checking labels backed by the marker, not the submitted content. |
| Evidence record | Canonical source | `Evidence.check/2` | ✓ WIRED | Authorized source-bound validation succeeds; no claim is made that `check/1` passes. |
| Advisory simulator report | Elixir parser/join | Script’s final `mix run` | ✗ NOT WIRED | Actual simulator output is unavailable; test stubs mask the real join. |
| Support model | Public guide | Renderer | ✓ WIRED | Deterministic parity command returned true. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| -------- | ------------- | ------ | ------------------ | ------ |
| Free-form study flow | Draft text | iOS text field | No — it is cleared after a no-argument call; only a boolean is stored | ✗ HOLLOW |
| Physical evidence | Closed assertion list | Device/backend reports and canonical source | Yes for schema/digest/provenance contract; insufficient to repair the false free-form behavior | ✓ FLOWING, LIMITED |
| Support row | Canonical support matrix | Renderer | Yes | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| Authorized evidence validation | `Evidence.check/2` with the canonical physical source | `:ok` | ✓ PASS |
| Unbound evidence validation | `Evidence.check/1` | `PL-EVIDENCE-HASH-SOURCE` | ✓ EXPECTED FAIL-CLOSED |
| Focused Phase 162 contracts | Focused `mix test` command from validation ledger | 132 tests, 0 failures | ✓ PASS — does not exercise CR-01/CR-02 real semantics |
| Phoenix authority | Targeted example-host ExUnit tests | 8 tests, 0 failures | ✓ PASS |
| Recovery UI | Targeted Chromium Playwright test | 1 passed | ✓ PASS |
| Current physical readiness | `mix crosswake.proof_lane.physical_iphone --readiness --json` | blocked closed outcomes; no device action taken | ✓ PASS — fail-closed readiness, not a replacement device run |
| Broad privacy scanner | `mix crosswake.adoption_context.scan` | non-passing on the known marker extension and pre-existing binary | ? NOT USED AS PASS AUTHORITY |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| ----------- | ----------- | ----------- | ------ | -------- |
| DEVICE-01 | 162 plans | Verified pack installation and offline audio | ✓ SATISFIED | Checked record plus real pack adapter’s byte/integrity and offline-playback path. |
| DEVICE-02 | 162 plans | Selected/free-form queue, relaunch, reconnect, exactly-once drain | ✗ BLOCKED | Free-form content is discarded and therefore cannot be queued, rehydrated, or reconciled. |
| DEVICE-03 | 162 plans | Visible recoverable rejected/conflict outcomes | ✓ SATISFIED | Phoenix authority and browser recovery tests pass; asserted in checked record. |
| DEVICE-04 | 162 plans | No cross-scope replay on logout/account switch | ✓ SATISFIED | Independent backend authority test coverage and owner-scoped record assertion. |
| DEVICE-05 | 162 plans | Server-side entry/replay disablement retaining queued work | ✓ SATISFIED | Independent authority test coverage and checked record assertions. |
| DEVICE-06 | 162 plans | Dated redacted artifact | ✓ SATISFIED | Evidence-specific privacy proof is sufficient: closed schema/scans, canonicalization, marker integrity, directory allowlist, and supplied-source digest pass. The broad scanner is explicitly non-passing and was not misreported. |
| DEVICE-07 | 162 plans | Narrow one-flow/one-runtime support claim | ✓ SATISFIED | Generated guide stays within all required non-claims. |

All seven DEVICE requirements are declared by Phase 162 plans; none is orphaned. The completion marks in `REQUIREMENTS.md` are not accepted as proof and conflict with the failed DEVICE-02 implementation.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| `ProofLaneApp.swift` | 115–116 | Input-free mutation call followed by draft clearing | 🛑 BLOCKER | Represents discarded free-form content as saved. |
| `ProofLaneDriver.swift` | 301–305 | Boolean marker substituted for content persistence | 🛑 BLOCKER | Falsifies the free-form relaunch claim. |
| `physical_iphone_report_contract_script_test.exs` | 38–49 | `xcodebuild` and `mix` replaced by grep-only stubs | 🛑 BLOCKER | Masks non-executable advisory success path. |

### Gaps Summary

CR-01 and CR-02 are both confirmed from the final tree. The promoted, source-bound evidence record is structurally and privacy-valid under the authorized `Evidence.check/2` model, and the public wording is correctly narrow. Neither fact proves the missing free-form persistence invariant.

This is an escalation gate: do not treat the current DEVICE-02 completion mark or support-row promotion as earned until the value is journaled and rehydrated without exposing it in evidence, and until the advisory serialization path either becomes executable or is truthfully narrowed to envelope validation.

---

_Verified: 2026-08-26T17:56:46Z_
_Verifier: the agent (gsd-verifier)_
