---
phase: 159
slug: host-reusable-proof-lane
status: validated
nyquist_compliant: true
wave_15_complete: true
created: 2026-07-31
validated: 2026-08-02T02:00:00Z
---

# Phase 159 — Final Same-Tree Validation

> Fresh post-159-22/post-159-23 deterministic validation. Native accessibility-size execution remains advisory and does not promote a device-support claim.

## Observed Complete Gate

The unchanged repaired tree passed the following gate on the current Linux platform:

```sh
mix test test/mix/tasks/crosswake_gen_proof_lane_test.exs test/crosswake/proof_lane/config_test.exs test/crosswake/proof_lane/template_contract_test.exs test/crosswake/proof_lane/ios_verifier_test.exs test/crosswake/proof_lane/evidence_test.exs
cc -std=c11 -O2 -Wall -Wextra -Werror -o /tmp/crosswake-evidence-promote-159-24 priv/native/crosswake_evidence_promote.c
cc -std=c11 -O2 -Wall -Wextra -Werror -o /tmp/crosswake-proof-lane-fs-159-24 priv/native/crosswake_proof_lane_fs.c
npm --prefix examples/phoenix_host run typecheck:offline-route-proof
bash script/verify_phoenix_host_proof_lane.sh
bash -n script/verify_generated_ios_shell.sh script/verify_phoenix_host_proof_lane.sh
mix format --check-formatted lib/crosswake/proof_lane/*.ex test/crosswake/proof_lane/*.exs test/mix/tasks/crosswake_gen_proof_lane_test.exs
```

The focused ExUnit command passed 51 tests. The isolated Phoenix proof typechecked and executed one generated Playwright test through the existing Phoenix lifecycle. Both native helpers compiled warning-clean; shell syntax and formatter checks passed.

## Publication and Evidence Boundaries

Focused controls passed for exact 64-byte SHA-256 marker shape, approved digest matching, mutations after readback/before marker, after marker/before helper success, and after promotion. They also cover interruption, replacement, incomplete recovery, anti-echo, source-path absence, and no advertised-directory cleanup.

Generator controls passed for bounded input framing, former-stage-decoy irrelevance, fault-before-publication, pre/post-publication barriers, collision winner preservation, no final-leaf cleanup, and repeated missing-only generation. On the current Linux platform, the controls exercised ordinary-unprivileged O_TMPFILE publication through a verified `proc/self/fd` descriptor path and reject the privileged empty-path form. Darwin's already-unlinked-fd clone path remains a source-controlled alternative rather than a claimed current-platform result.

## Preserved Contracts

| Boundary | Observed result |
| --- | --- |
| PROOF-01 host ownership and collision safety | PASS |
| PROOF-02 closed configuration and pre-write endpoint rejection | PASS |
| PROOF-03 primary browser corpus plus generated host proof | PASS |
| PROOF-04 privacy-safe digest-bound retained evidence | PASS |
| D-14 label/target contract | PASS-CONTRACT; native runtime advisory `not_run` |
| Android, TODO-002, adopter-instance state, and Phase 160–162 ownership | PRESERVED |
| external API surface | PRESERVED: none |

Protected before/after SHA-256 values are identical: `.planning/config.json` `de08e6a97eedb77d5b7bb23c1193c1e4aab126508e8cd26ea029e824f3391ab8`; `COVERAGE.md` `812faa33f005443b3c46f7c9fc355e63a3052b05d457c5d780349c81d848a552`.

## Privacy and Scope

This ledger retains only commands, counts, stable behavior names, safe relative paths, platform class, and closed outcomes. It retains no raw child output, host values, canonical bytes, payloads, identities, credentials, tokens, media, transcripts, traces, screenshots, xcresults, or absolute temporary paths.

**Approval:** every deterministic and current-platform requirement passed. Phase 159 is verified complete without widening support, device, Android, replay/auth, pack/audio, or generic-sync/storage claims.
