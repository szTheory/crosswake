---
phase: 159
slug: host-reusable-proof-lane
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-07-31
validated: 2026-08-01T01:22:00Z
---

# Phase 159 — Validation Strategy

> Fresh final-tree validation for the bounded host-reusable proof lane. Native execution is a real simulator control for the scaffold, not a physical-device, replay, auth-authority, or pack claim.

## Final Automated Gate

The following command sequence passed from one unchanged final tree on 2026-08-01:

```sh
mix test test/mix/tasks/crosswake_gen_proof_lane_test.exs test/crosswake/proof_lane/config_test.exs test/crosswake/proof_lane/template_contract_test.exs test/crosswake/proof_lane/ios_verifier_test.exs test/crosswake/proof_lane/evidence_test.exs
bash script/verify_phoenix_host_proof_lane.sh
bash -n script/verify_generated_ios_shell.sh script/verify_phoenix_host_proof_lane.sh
env -u CROSSWAKE_IOS_XCODEBUILD_BIN -u CROSSWAKE_IOS_PROJECT_ROOT -u CROSSWAKE_IOS_SHIM_MODE CROSSWAKE_IOS_USE_LOCAL_CORE=1 CROSSWAKE_IOS_LAUNCH_SIMULATOR=1 bash script/verify_generated_ios_shell.sh --proof-lane
mix format --check-formatted lib/crosswake/proof_lane/*.ex test/crosswake/proof_lane/*.exs test/mix/tasks/crosswake_gen_proof_lane_test.exs
```

Observed results: 41 focused ExUnit tests passed; the Phoenix-host command type-checked and passed five Playwright tests including the real IndexedDB/reconnect/backend/idempotency flow; the generated shared scheme returned only `{"outcome":"passed","rule_id":"PL-IOS-TEST-EXECUTION","scope":"generated-proof-targets"}` after `build-for-testing` plus `test-without-building`; shell syntax and formatting passed. `COVERAGE.md` remained byte-unchanged.

## Verification Map

| Task ID | Requirement | Boundary | Automated proof | Fresh result |
| --- | --- | --- | --- | --- |
| 159-F-01 | PROOF-01 | Missing-only generation, descriptor-pinned no-follow traversal, check/diff, collision preservation | focused Mix-task suite | PASS — includes direct symlink and controlled ancestor-swap controls. |
| 159-F-02 | PROOF-02 | Closed route/storage/mutation/endpoint/router/shell normalization and non-echoing errors | focused config and template suites | PASS — malformed mutation-ID cases also reject before callbacks. |
| 159-F-03 | PROOF-03 | Existing Phoenix browser corpus plus real generated XCTest/XCUITest boundary | host Playwright command and non-mocked generated-scheme verifier | PASS — five browser tests and bundle-qualified XCTest/XCUITest completion. |
| 159-F-04 | PROOF-04 | Typed evidence, final-byte scan, no-replace promotion, and malformed lifecycle hooks | focused evidence suite | PASS — malformed return/raise/throw/exit hooks fail closed with cleanup. |
| 159-F-05 | UI backstop | Long text reflow and 44pt retry target | generated XCUITest contract coverage | PASS — included in the native focused suite and executed shared-scheme control. |

## Sampling and Scope

- The focused generator/config/template/iOS/evidence suite is the recurring deterministic contract check.
- `script/verify_phoenix_host_proof_lane.sh` remains a host-owned one-command behavioral control; its existing Playwright `webServer` remains the sole Phoenix lifecycle owner.
- The generated iOS verifier deliberately unsets injected project-root, xcodebuild, and shim overrides, selects an installed iPhone simulator, requires both test bundles, and treats Xcode, destination, build, test, or transcript-marker failure as non-zero `blocked` or `unavailable`.
- No manual approval or UAT substitutes for these results. No physical-device proof, Android work, generic sync/storage, backend auth authority, or pack implementation is validated here.

## Validation Sign-Off

- [x] Every Phase 159 task has fresh automated coverage.
- [x] The final gate covers all PROOF requirements and every former blocker/behavior-unverified item.
- [x] Adversarial filesystem, evidence-hook, and mutation-ID checks pass without outside-host writes, partial promotion, global Git/SwiftPM mutation, or sensitive output.
- [x] `COVERAGE.md` and schema files are unchanged by final validation.
- [x] `nyquist_compliant: true` reflects fresh final-tree evidence only.

**Approval:** automated final-tree gate passed; Phase 159 can be reconciled without widening its bounded scope.
