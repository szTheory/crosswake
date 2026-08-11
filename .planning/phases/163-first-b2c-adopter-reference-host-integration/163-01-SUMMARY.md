---
phase: 163-first-b2c-adopter-reference-host-integration
plan: 01
subsystem: physical-iphone-reference-host
tags: [phoenix, ios, offline-study, replay, evidence]
key-files:
  created:
    - examples/phoenix_host/lib/crosswake_example/physical_iphone_proof_host.ex
    - examples/phoenix_host/lib/crosswake_example/local_first/physical_iphone_authority.ex
    - examples/phoenix_host/native/ios/CrosswakeProofLane/Resources/ReferenceLearningBundle/manifest.json
  modified:
    - lib/mix/tasks/crosswake.proof_lane.physical_iphone.ex
    - priv/templates/crosswake/proof_lane/test/crosswake_proof_lane_test.exs.eex
requirements-completed: [ALPHA-01, ALPHA-02, ALPHA-03, ALPHA-04]
metrics:
  tasks: 3
  tests: 82
---

# Phase 163 Plan 01: Reference Host Integration Summary

The Phoenix example is now the bounded First B2C Adopter reference host for the existing physical
proof lane. It owns one exact manifest/image/audio bundle, one persisted offline study island, one
independent backend-authority producer, one physical XCUITest producer, and one canonical evidence
input callback. No Android, background sync, generic native storage, or generic sync scope was
added.

## Commits

| Task | Commit | Description |
| --- | --- | --- |
| 1–3 | `04ef40cf` | Generate the lane and add the bounded device/backend/evidence producers |
| 3 | `a06f1348` | Accept the team selected in the generated Xcode project as a signing source |

## Verification

- Core physical preflight/report/evidence suite: 60 tests, 0 failures.
- Host authority, generated contract, and local-first suite: 22 tests, 0 failures.
- Generated browser reference-host proof: `PL-BROWSER-REFERENCE-HOST-PASSED`.
- Generated iOS behavior/serialization proof: `PI-SIMULATOR-CONTRACT-PASSED` (advisory only).
- Live physical readiness: all checks ready except `PI-PREFLIGHT-SIGNING`.
- Physical evidence destination: absent; promotion was not invoked.

## Deviations

- Replaced the generated opaque pronunciation fixture as the reference-host authority with a real
  verified AIFF asset plus exact manifest and image bytes. The original generated fixture remains
  untouched for its generic template contract.
- Fixed configured host-authority module loading and suppressed normal host startup logging so the
  production JSON command remains machine-readable after compilation.

## Self-Check: PASSED

All automatable Phase 163 criteria passed. Apple signing remains an external Phase 162 preflight
gate and is not a Phase 163 implementation defect.
