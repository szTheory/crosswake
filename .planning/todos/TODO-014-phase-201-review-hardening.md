---
id: TODO-014
title: Phase 201 review hardening - companion exclusion coverage, provenance line source, AGENTS contract negatives
status: open
created: 2026-11-09
severity: low
surfaced_by: Phase 201 code review (201-REVIEW.md) and Nyquist audit (201-VALIDATION.md)
relates_to: REL-09, Phase 201
---

# Small hardening items from the Phase 201 review

None of these changes a verdict today; each makes a future regression fail in CI instead of in a release run.

1. WR-01: parameterize the "different build_env changes no digest" test over all five companions and add
   an unlisted-name and near-miss-name control. A probe test for the unlisted-name claim passed on
   origin/main during the audit; its source is recorded in 201-VALIDATION.md.
2. WR-02: have `inspect_metadata!/3` return the validated build_env version, derive the log's digested
   yes/no from one shared helper, and keep `provenance_line/1` inside the module's ArgumentError contract.
3. WR-03: add `refute`s for the superseded gate wording to `agents_contract_test.exs`.
4. IN-01..IN-05: see 201-REVIEW.md; take them in the same PR if cheap.

## Reopen when

The next change touches `Artifact.inspect_metadata!/3` or the AGENTS.md approvals text.
