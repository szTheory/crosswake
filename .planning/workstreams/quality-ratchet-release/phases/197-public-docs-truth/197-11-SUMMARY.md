---
phase: 197-public-docs-truth
plan: 11
subsystem: public-docs
tags: [docs, changelog, publish-readiness, registry-truth, d-13, d-25, docs-02]

requires:
  - phase: 197-public-docs-truth
    provides: "197-10 version-free companion matrix; 197-09 fail-closed tarball audit pattern; 197-01 script/mix_test_gate.sh"
provides:
  - "CHANGELOG.md without a current-release claim, without the MILESTONE-ARC canonical paragraph, with one version-free GitHub Releases and hex.pm pointer in Published Hex truth"
  - "PublishReadiness.explicit_unpublished_candidate?/3 keyed on that pointer (published_truth_pointer?/1) instead of two version sentences"
  - "Crosswake.Doctor.PublishReadinessChangelogTest: real-repo pass plus two broken-copy controls"
  - "Crosswake.Guides.ChangelogUnreleasedWordingTest: wording, pointer and release-version-literal guards with mutation controls"
  - "197-EVIDENCE/changelog-unreleased-audit-197.txt: five bullets audited against the 0.2.11 tarball"
affects: [197-12, 197-14, 197-15]

actuals:
  tokens: 9000
  tasks: 2
  commits: 2
plan_head_before: 939925f4391a0e58b1ff5de88987c01b927d6e4a
plan_head_after: 7a139f1ebc33bf924bb3445ab8f4cacd10701374

tech-stack:
  added: []
  patterns:
    - "A readiness rule recognises an unpublished candidate by a pointer to the registry, never by a sentence that names a version"
    - "Contract-version literals (schema, bridge_protocol_version) are exempt from the release-version check only on a line naming their context"

key-files:
  created:
    - test/crosswake/doctor/publish_readiness_changelog_test.exs
    - test/crosswake/guides/changelog_unreleased_wording_test.exs
    - .planning/workstreams/quality-ratchet-release/phases/197-public-docs-truth/197-EVIDENCE/changelog-unreleased-audit-197.txt
  modified:
    - CHANGELOG.md
    - lib/crosswake/doctor/publish_readiness.ex
    - test/crosswake/proof/phase48_provider_adapter_proof_test.exs

key-decisions:
  - "The candidate rule keeps its manifest-equals-mix.exs and newest-section-less-than-version gates and replaces only the sentence match, so publish.parity still fails closed on a broken copy."
  - "No release section was added (D-13, no backfill); the section count stays 5."

requirements-completed: []

duration: 20min
completed: 2026-11-05
status: complete
---

# Phase 197 Plan 11: CHANGELOG release claims made registry-true Summary

**CHANGELOG no longer says any release is current; one version-free sentence points to GitHub Releases and hex.pm, the repository's own `publish.parity` still passes through a new pointer-keyed candidate rule, and `[Unreleased]` is guarded by wording, pointer and release-version tests with mutation controls.**

## Accomplishments

- Baseline before any edit: `publish.parity` `pass`, report status `:ready`. After the edit: `publish.parity` `pass` (same result).
- Task 1 (tracer, `6207debb`): the planning-milestones paragraph is version-free and no longer names MILESTONE-ARC. Three `[Unreleased]` bullets deleted (no new claims after the old release, the refactor already in its own section, the current published family). `Published Hex truth` has two bullets: the kept "Public readers should treat this `[Unreleased]` section..." sentence and the pointer sentence. The `[0.2.0]` closing sentence is now "Companion package versions are listed on hex.pm."
- `explicit_unpublished_candidate?/3` keeps its `with` chain (manifest readable, `.` equals mix.exs version, newest release section found, version greater than newest) and its body now calls `published_truth_pointer?/1`, which requires both links inside the `### Published Hex truth` subsection. The binding is renamed `newest_release`; `mix compile --warnings-as-errors` is clean.
- Tests: `PublishReadinessChangelogTest` has a non-vacuity precondition (manifest equals mix.exs version, greater than newest section, no own section), the real-repo pass, control 1 (pointer removed) and control 2 (pointer removed plus the two deleted sentences re-inserted); both controls fail with an error naming `[0.2.11]`. phase48 pins now name the kept sentence and the pointer sentence; both proof ids and `:merge_blocking` unchanged.
- Task 2 (`7a139f1e`): the 0.2.11 tarball was fetched (rc 0, HTTP 200), both extractions rc 0, tree check version 0.2.11 with 138 `.ex` files. All five identifiers (`host_commands`, `host_commands_legacy_manifest`, `offline_posture_not_claimed`, `git-unknown`, `ios_host`) are `not_found` in 0.2.11 `lib/`, so the four existing bullets are kept and a `Declared iOS host setup (iOS only, not released)` bullet is added with no release version. The audit file holds exactly the five expected `audit:` lines (awk verify matched=5 ok=1).
- `ChangelogUnreleasedWordingTest` (11 tests): wording, two injection controls, pointer plus two controls (removed; links moved outside the subsection), release-version literals with two controls (`0.2.12` injected; `1.2.0` on a line without `schema`), the `:ios_host` bullet, and the headings plus `[0.1.0]`.

## Task Commits

1. Task 1 (tracer): `6207debb` (docs) CHANGELOG edits, candidate rule, pins, readiness test
2. Task 2: `7a139f1e` (docs) audit evidence, `:ios_host` bullet, wording guard

## Verification Run (through `script/mix_test_gate.sh`)

- Task 1 gate 1: ran=72, failures=0, min 72: PASS. Gate 2 (doctor, phase52, phase63, closeout_verify): ran=136, failures=0, min 136: PASS.
- Task 2 gate: ran=63, failures=0, min 58: PASS.
- `mix compile --warnings-as-errors` clean; `mix format --check-formatted` clean on every changed Elixir file.
- Acceptance greps: deleted sentences 0 in CHANGELOG, `publish_readiness.ex` and phase48; `MILESTONE-ARC` 0 in CHANGELOG; pointer present in the scoped subsection; `## [` count 5 (unchanged); `.planning/config.json` absent from `origin/main..HEAD`.
- Privacy scan (`privacy-193.sh` via `bash`, absolute paths) clean before each commit. No push was made.

## Deviations from Plan

### Process

**1. Two commits.** The plan's Task 2 text names one commit message; per the one-commit-per-task protocol and the tracer gate, Task 1 carries its own commit (`docs(197-11): ...`) and Task 2 carries the plan's message.

No code deviations. Plan executed as written.

## Known Stubs

None.

## Threat Flags

None. No new endpoints, auth paths or trust-boundary schema.

## Requirements

DOCS-02 is carried by plans 12, 14 and 15 as well, so it is not marked complete here.

## Self-Check: PASSED

- FOUND: test/crosswake/doctor/publish_readiness_changelog_test.exs
- FOUND: test/crosswake/guides/changelog_unreleased_wording_test.exs
- FOUND: 197-EVIDENCE/changelog-unreleased-audit-197.txt
- FOUND commits: 6207debb, 7a139f1e
