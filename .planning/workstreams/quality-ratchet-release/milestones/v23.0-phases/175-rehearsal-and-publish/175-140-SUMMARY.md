---
phase: 175-rehearsal-and-publish
plan: 140
subsystem: release-candidate-preflight
tags: [preflight, exact-head, approval, dry-run]
requires:
  - phase: 175-rehearsal-and-publish
    provides: Plan139's exact final-Done parser repair
provides:
  - Fresh independently audited v3 exact-head PREFLIGHT_READY receipt for attempt 9438fec143ddb1beda7168e002b2a12f
  - One-use ALLOW bound to the displayed attempt, scope, card, and collector
affects: [175-106, 175-46, 175-47, 175-48, 175-89]
requirements-completed: []
completed: 2026-10-10
status: complete
---

# Phase 175 Plan 140: Fresh Exact-Head Preflight

## Result

The user allowed the complete card for attempt `9438fec143ddb1beda7168e002b2a12f`. The choice was rebound to the unchanged scope, card, and collector after production and independent PENDING checks. The production runner ran exactly once. Its receipt passed the production terminal inspector and both independent offline Node audits.

At `2026-10-10T21:33:23.646055Z`, the exact-head preflight established that PR #219 was open, not draft, and not merged, with version `0.2.7` read from the release manifest at the validated PR head and tree. The source package split matched mirror `main`; mirror tag `v0.2.6` was absent. The mirror policy observation was complete and reported create-only tag policy; the authenticated permission check reported ADMIN and push permission TRUE. These are observations from this run, not continuing or effective release authority.

The no-write Git preview accepted exactly one row for object `424ab96ede1b92f2b751b54bce04c6e607f0f3c8` targeting `refs/tags/v0.2.6`; the row was neither force nor delete. No tag was created.

## Operation counts and audit

- 16 public API requests
- 19 Git operations
- 1 configured credential-helper check
- 3 permission checks
- 1 no-write dry-run
- 0 tag attempts and 0 CI requests
- No unknown request count

The sealed result SHA-256 is `fa0292420accd879a1b108db560f17eced8416528195432adf650421826262e2`. The independent audits confirmed the exact attempt/scope/authorization bindings, the raw card and current collector digests, ordered lifecycle events, schemas, limits, privacy-safe output, and zero tag/CI operations.

## What this does and does not establish

The checks support a fresh preflight for this candidate and exact ref. They do not authorize creating the tag. Effective write permission remains UNKNOWN, tag authority remains NONE, and the release hold remains active. Plan106 cannot run unchanged: its precondition names Plan119's receipt, not this Plan140 receipt. Plan106 and Plans46–48/89 remain held; REL-13/14/15/17 remain open; readiness remains blocked; Phase175 remains incomplete.

Plan139's local bare-repository reproduction likely explains why Plan137's parser rejected the successful Git preview. Plan137's original preview bytes were not retained, so this connection remains unconfirmed. Plan137's attempt and approval remain consumed.

## Next step

Plan a bounded reconciliation of this fresh receipt with the separate tag-creation decision gate. Do not repeat this preflight, reuse its ALLOW for a tag write, or execute Plan106 until its Plan119-specific precondition has been resolved by a reviewed plan.
