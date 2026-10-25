---
phase: 175-rehearsal-and-publish
plan: 35
subsystem: release-candidate
tags: [release-evidence, github, hex, authorization]
requires: [REL-17]
provides: [fresh-live-evidence-capture, stage-bound-hex-provenance, read-only-release-status]
affects: [175-36, 175-37, 175-38, 175-39, 175-40, 175-41]
tech-stack:
  added: []
  patterns: [bounded-live-adapter, retained-response-digests, fail-closed-status]
key-files:
  created:
    - lib/crosswake/release_candidate/evidence_live.ex
    - test/crosswake/release_candidate/evidence_live_test.exs
  modified:
    - lib/crosswake/release_candidate/evidence_gate.ex
    - lib/mix/tasks/crosswake.release.gate.ex
    - lib/crosswake/release_status.ex
    - script/release_candidate/require_release_evidence.sh
    - test/crosswake/release_candidate/evidence_gate_test.exs
    - test/mix/tasks/crosswake_release_status_test.exs
decisions:
  - Every gate call captures current remote evidence and retains bounded source bytes before parsing.
  - Pre-merge authorization and post-merge provenance use distinct capture stages.
  - Release status remains read-only and cannot authorize from a READY FOR APPROVAL receipt.
patterns-established:
  - Inject remote transport and Git ancestry functions for deterministic failure-mutation tests.
  - Bind condition facts to private source paths and SHA-256 digests, including the exact Hex response.
requirements-completed: []
duration: 42m
completed: 2026-09-26
---

# Plan 175-35: Fresh REL-17 Evidence Capture Summary

The live evidence adapter now fetches current GitHub, Git, and Hex facts for each gate invocation. It exhausts and reconciles REST pagination, rejects unsuccessful or incomplete responses, binds candidate and post-merge identities to the operation, and retains bounded response bytes in private files before parsing. The pure evidence gate verifies source digests and stage-specific provenance, including the exact nonempty Hex registry body and matching release row.

The publisher evidence seam requires fresh capture selectors and an authorization input on every invocation; it no longer accepts a cached envelope as a live verdict. The existing status command exposes a safe read-only authorization projection, reports missing evidence as BLOCKED with a fresh-evidence next step, and does not treat a receipt as permission.

## Verification

- `MIX_ENV=test mix test test/crosswake/release_candidate/evidence_live_test.exs test/crosswake/release_candidate/evidence_gate_test.exs test/mix/tasks/crosswake_release_status_test.exs --max-cases 1` — passed, 31 tests, 0 failures.
- `mix format --check-formatted` on changed Elixir source and test files — passed.
- `bash -n script/release_candidate/require_release_evidence.sh` — passed.
- `git diff --check` on scoped changes — passed.
- No live network reads or publication actions were performed.

## Outcome

The implementation and its focused tests are committed as `5c042f4c`. REL-17 remains an open shared requirement until the dependent workflow-wiring and gate plans complete.
