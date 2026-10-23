---
phase: 175-rehearsal-and-publish
plan: 33
subsystem: release-automation
tags: [release, receipt, ios, consumer-proof, postmortem]
requires: [175-29]
provides: [exact-receipt-roster-guard, external-hex-ios-proof, incident-postmortem, interim-learnings]
affects: [release-please, ios-mirror-backfill, release-candidate-tests, quality-ratchet-roadmap]
tech-stack:
  added: []
  patterns: [exact-artifact-roster, external-mix-consumer]
key-files:
  created:
    - script/release_candidate/assert_candidate_receipt_artifact.sh
    - script/verify_ios_release_host.sh
    - test/crosswake/proof/phase175_release_recovery_test.exs
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-29-POSTMORTEM.md
    - .planning/workstreams/quality-ratchet-release/phases/175-rehearsal-and-publish/175-LEARNINGS.md
  modified:
    - .github/workflows/release-please.yml
    - test/crosswake/release_candidate/workflow_test.exs
    - script/check_release_workflow_integrity.exs
    - .planning/workstreams/quality-ratchet-release/ROADMAP.md
    - .planning/workstreams/quality-ratchet-release/STATE.md
decisions:
  - "Maven validates exactly the three files emitted by the receipt attestation before Java setup or credentials."
  - "iOS consumer proof installs the exact Hex package in an external Mix host and checks the resolved version and generated manifest."
  - "The 0.2.5 Gate 2 result stays PARTIAL; no release recovery or publication was authorized or performed."
patterns-established:
  - "Use one canonical artifact roster guard at the consumer and reject nested, missing, extra, and symlink entries."
  - "Proof of package behavior must use an external host with the same package-manager dependency topology as consumers."
requirements-completed: [REL-13, REL-14, REL-16]
duration: ~35min
completed: 2026-09-25
---

# Phase 175 Plan 33: Summary

Receipt roster producer/consumer drift now has a reusable exact three-file guard and four direct
filesystem tests. The release workflow uses that guard before Java setup, keeps all receipt
identity/digest checks, and no longer relies on globally installing a Mix archive for iOS proof.

The checked-in iOS proof creates a separate host, pins the exact released Hex version, checks the
resolved Crosswake version, compiles dependencies while running the documented generator, and
validates the generated manifest before Swift build. A local run against published 0.2.5 succeeded.

The workflow-integrity scanner was updated to understand the extracted guard and still emitted all
79 checks. The postmortem and interim lessons document the incident and shift-left controls. Stale
0.2.5-bound Plans 30–32 are superseded. MemPalace capture was skipped because its enablement gate
is disabled and no CLI/tool is configured; the GSD artifacts are the durable record.

## Verification

- `MIX_ENV=test mix test test/crosswake/proof/phase175_release_recovery_test.exs test/crosswake/release_candidate/workflow_test.exs --max-cases 1` — 30 tests, 0 failures.
- `HEX_HOME=/private/tmp/crosswake-local-hex MIX_HOME=/private/tmp/crosswake-local-mix script/verify_ios_release_host.sh --version 0.2.5 ...` — exact Hex dependency resolved at 0.2.5; shell generated and manifest parsed.
- `elixir script/check_release_workflow_integrity.exs` — 79 of 79 checks emitted; 0 failed after updating the scanner for the extracted guard.
- `actionlint .github/workflows/release-please.yml` — passed.
- `git diff --check` on owned implementation, test, and planning paths — passed.
- Gate 2 evidence remains consumed/PARTIAL; registry truth is unchanged.

## Remaining

Plan 175-29 remains PARTIAL. Any next release attempt requires a fresh candidate plan, fresh evidence,
and separate explicit authorization. No Gate 2 authorization is created by these local repairs.
