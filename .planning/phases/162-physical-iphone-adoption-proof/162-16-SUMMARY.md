---
phase: 162-physical-iphone-adoption-proof
plan: "16"
subsystem: physical-proof
tags: [physical-iphone, evidence, provenance, recovery]
requires:
  - phase: 162-15
    provides: fail-closed support withdrawal and deterministic proof contracts
provides:
  - one corrected-provenance physical transaction ledger
  - cleaned private capture and an untracked canonical evidence pair
affects: [162-17, independent-verification]
tech-stack:
  added: []
  patterns: [one-shot evidence transaction, fail-closed provenance]
key-files:
  created: []
  modified: [script/retain_physical_iphone_evidence_transaction.sh]
key-decisions:
  - "The physical code authority is the immutable ledger parent; wrapper logic is not physical authority."
requirements-completed: []
status: complete
---

# Phase 162 Plan 16: Corrected-Provenance Transaction Summary

**One corrected physical transaction completed, then retention stopped safely after a wrapper-only post-promotion provenance failure.**

## Accomplishments

- Withdrew stale authority before the single corrected transaction.
- Committed ledger `d59c9182`; its sole parent `e649e6ed` remains the physical code authority.
- The corrected record was promoted, private capture was cleaned, and the wrapper failed only after promotion because it required optional run-JSON provenance.
- Plan 17 recovered the retained pair without a second run.

## Deviations from Plan

None — the wrapper failure was the recorded terminal outcome that Plan 17 was created to recover.

## Next Phase Readiness

The retained pair is recovered under Plan 17. Independent verification remains the final authority; no additional physical attempt is authorized.

