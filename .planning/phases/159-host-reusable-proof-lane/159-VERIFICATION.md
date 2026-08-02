---
phase: 159-host-reusable-proof-lane
verified: 2026-08-02T02:50:14Z
status: gaps_found
score: 8/10 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: complete
  previous_score: 23/23
  gaps_closed: []
  gaps_remaining:
    - "Native evidence publication does not pin the destination parent or use descriptor-relative operations."
  regressions:
    - "The prior complete verdict accepted a native publisher that contradicts the declared parent-pinning containment contract."
next_action: "Repair the native evidence publisher so one held no-follow destination-parent descriptor owns reservation, publication, verification, and final synchronization; add an adversarial ancestor-replacement regression."
next_command: "mix test test/crosswake/proof_lane/evidence_test.exs"
gaps:
  - truth: "Evidence promotion is race-resistant and cannot redirect retained evidence outside the requested destination."
    status: failed
    reason: "The native publisher creates the destination and then reopens the destination and both leaves by path. A replacement of the newly created directory by an ancestor-controlled symlink between those operations redirects later writes; final-component O_NOFOLLOW does not protect an ancestor."
    artifacts:
      - path: "priv/native/crosswake_evidence_promote.c"
        issue: "The destination is created at line 95, while subsequent artifact, marker, rename, directory-open, and verification operations use destination-derived path strings at lines 96-118 instead of a held directory descriptor and *at calls."
    missing:
      - "Pin the destination parent and reserved destination with no-follow directory descriptors; perform leaf creation, verification, rename, cleanup policy, and synchronization only relative to those descriptors."
      - "Add a deterministic concurrent ancestor-replacement regression proving that no publication occurs outside the requested destination."
  - truth: "Requirements, roadmap, and state advance only when a fresh gate has closed every preserved Phase 159 integrity truth."
    status: failed
    reason: "The current planning status records Phase 159 as complete and advances to Phase 160, but the required native publication containment truth is observably absent from the final code."
    artifacts:
      - path: ".planning/phases/159-host-reusable-proof-lane/159-VERIFICATION.md"
        issue: "The prior report marked the private helper boundary verified without testing or implementing descriptor-pinned destination containment."
    missing:
      - "Re-run the complete same-tree gate and reconcile milestone status only after the native containment repair passes."
---

# Phase 159: Host-Reusable Proof Lane Verification Report

**Phase Goal:** Generate configurable host-owned browser, shell, offline-island, and physical-device proof scaffolding with non-destructive generation and privacy-safe retained evidence.

**Verified:** 2026-08-02T02:50:14Z
**Status:** gaps_found
**Re-verification:** Yes — prior complete verdict independently rechecked against the final code.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | Generation is non-destructive and supports diff/check mode. | ✓ VERIFIED | The focused 54-test gate passed; generator/config regressions cover missing-only generation and read-only inspection. |
| 2 | Existing browser tests and fixtures remain the primary web/island coverage. | ✓ VERIFIED | The generated Phoenix proof typechecks and runs through the established web-server lifecycle; its focused check passed. |
| 3 | Native proof is limited to the declared shell, replay, and pack boundaries. | ✓ VERIFIED | Template/iOS contract tests passed; unavailable prerequisites remain non-passing and accessibility runtime remains advisory. |
| 4 | Generated evidence rejects prohibited sensitive payload and identity fields. | ✓ VERIFIED | Evidence tests reject closed-schema sensitive key/value injections without echoing them. |
| 5 | A fresh unchanged-tree gate proves every preserved Phase 159 integrity contract before status advances. | ✗ FAILED | The gate passes its existing tests, but `crosswake_evidence_promote.c` does not implement the required descriptor-pinned destination containment. |
| 6 | Generated Phoenix-host proof is additive in the primary corpus. | ✓ VERIFIED | The focused Phoenix proof check passed with the existing lifecycle owner. |
| 7 | Deterministic UI overflow/accessibility contract remains covered; runtime is advisory. | ✓ VERIFIED | Template and iOS verifier cases passed in the focused suite. |
| 8 | Verification ledger uses only safe closed evidence. | ✓ VERIFIED | This report records only rule-level code behavior, counts, and relative paths. |
| 9 | Requirements, roadmap, and state advance only after all preserved truths close. | ✗ FAILED | Current planning records advance despite the failed native-containment truth. |
| 10 | Android freeze, TODO-002, unknown-blocking, and Phase 160-162 ownership remain unchanged. | ✓ VERIFIED | Current planning artifacts retain these constraints. |

**Score:** 8/10 truths verified (0 present, behavior-unverified).

## Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `priv/native/crosswake_evidence_promote.c` | Race-resistant, no-replace evidence publication | ✗ FAILED | Exists and compiles warning-clean, but destination-derived path operations after reservation can follow a replaced ancestor. |
| `lib/crosswake/proof_lane/native_promotion.ex` | Bounded native publisher invocation | ✓ VERIFIED | Builds a private helper and sends bytes/digest through the bounded Port frame; calls the C publisher. |
| `lib/crosswake/proof_lane/evidence.ex` | Typed safe evidence, source validation, and promotion seam | ⚠️ PARTIAL | The typed allowlist and reader snapshot flow are substantive and wired, but `promote/3` relies on the unsafe native containment boundary. |
| `test/crosswake/proof_lane/evidence_test.exs` | Adversarial evidence-promotion regressions | ⚠️ PARTIAL | Covers collision, later-byte replacement, marker validation, and hook failures; no test replaces a publication ancestor after directory reservation or exercises a mid-publication native fault. |
| `.planning/phases/159-host-reusable-proof-lane/159-VALIDATION.md` | Fresh safe evidence ledger | ⚠️ STALE/CONTRADICTED | It reports the native publication boundary passed, which the final C implementation contradicts. |

## Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| `Evidence.promote/3` | `NativePromotion.publish/2` | direct call after schema/privacy/source checks | ✓ WIRED | The call is present and the publisher is invoked with serialized evidence bytes. |
| `NativePromotion.publish/2` | `crosswake_evidence_promote.c` | private compiled executable and bounded Port frame | ✓ WIRED | The C source is compiled and executed by the native module. |
| Native publisher | requested evidence destination | held no-follow descriptors and descriptor-relative operations | ✗ NOT_WIRED | The implementation instead uses pathname-based `mkdir`, `open`, `rename`, and final verification after reservation. |
| Fresh verification verdict | requirements/roadmap/state | all-or-blocked reconciliation | ✗ NOT_WIRED | The current status artifacts carry the superseded complete verdict rather than this failed containment result. |

## Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| `evidence.ex` | serialized evidence bytes | validated twelve-field evidence map | Yes | ✓ FLOWING |
| `native_promotion.ex` | digest and bounded bytes frame | SHA-256 of the validated serialized bytes | Yes | ✓ FLOWING |
| native publisher | final evidence leaves | destination path supplied through the native invocation | Unsafe containment | ✗ DISCONNECTED FROM REQUIRED DIRECTORY AUTHORITY |

## Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Focused proof-lane tests | `mix test` over the five declared focused files | 54 tests, 0 failures | ✓ PASS |
| Native helper build | C11 warnings-as-errors compilation | success | ✓ PASS |
| Generated host proof and TypeScript contract | declared typecheck and Phoenix proof commands | success | ✓ PASS |
| Ancestor-replacement containment | no named regression exists; source inspection of the native path operations | vulnerable path is observable | ✗ FAIL |

## Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| PROOF-01 | 159 plans | Configurable host-owned scaffold without overwriting host files | ✓ SATISFIED | Generator/config portion of the focused gate passed. |
| PROOF-02 | 159 plans | Required closed host configuration inputs | ✓ SATISFIED | Config tests passed in the focused gate. |
| PROOF-03 | 159 plans | Preserve host browser/unit/fixture corpus; add bounded proof | ✓ SATISFIED | Generated Phoenix proof and iOS/template contracts passed. |
| PROOF-04 | 159 plans | Evidence rejects sensitive payload and identity fields | ✗ BLOCKED | Input filtering passes, but the required race-resistant retained-evidence publication boundary is missing and contradicts D-22/all-or-nothing phase must-haves. |

All Phase 159 PLAN frontmatters reference only PROOF-01 through PROOF-04; no orphaned Phase 159 requirement was found.

## Review Finding Adjudication

| Finding | Verdict | Evidence |
| --- | --- | --- |
| CR-01 — ancestor replacement redirects native evidence publication | **VALID — BLOCKER** | After reservation, the C helper constructs and uses destination-derived paths for every leaf operation. It never holds a destination-parent or destination directory descriptor, so `O_NOFOLLOW` on final leaves cannot stop a changed ancestor. This contradicts the explicit Plan 159 parent-pinning and descriptor-relative publication contract. |
| WR-01 — failed mid-publication can strand an unusable destination | **OBSERVED, NOT A SEPARATE PHASE GAP** | The helper has no cleanup path after reservation. Later Plan 159 explicitly chose a visible non-passing reservation with no advertised-destination cleanup. That behavior can block a retry at the same destination, but it is fail-closed and not a failure of the declared no-passing-partial-evidence truth. Add fault/retry coverage if retryability becomes a requirement. |

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| --- | --- | --- | --- | --- |
| `priv/native/crosswake_evidence_promote.c` | 95-118 | Path-based operations after directory reservation | 🛑 BLOCKER | An attacker controlling an ancestor replacement window can redirect publication outside the requested destination. |
| `test/crosswake/proof_lane/evidence_test.exs` | 285-313 | Concurrency checks only destination-exists collision | ⚠️ WARNING | Passing tests do not discriminate the ancestor-replacement implementation. |

## Gaps Summary

The retained-evidence publisher is wired and its normal-path tests pass, but it fails the phase’s required containment property. The code reserves a destination by pathname, then reuses pathname-based file and directory operations. A symlink substitution in the intervening window affects the ancestor path, which final-component `O_NOFOLLOW` does not defend. This is a BLOCKER because the phase explicitly promises race-resistant, non-destructive publication and the accepted implementation plan required pinned, descriptor-relative operations.

No human verification is needed: the missing containment is directly observable in the C control flow. The escalation gate is a code repair decision, not a UAT item.

---

_Verified: 2026-08-02T02:50:14Z_
_Verifier: the agent (gsd-verifier)_
