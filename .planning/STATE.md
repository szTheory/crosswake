---
gsd_state_version: 1.0
milestone: v11.0
milestone_name: Release & Distribution Truth
status: active
last_updated: "2026-06-14T16:06:00.422Z"
last_activity: 2026-06-14
progress:
  total_phases: 2
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
  percent: 0
---

# Project State: Crosswake

## Project Reference

See: .planning/PROJECT.md (updated 2026-06-14)

**Core value:** Replace host-owned generated shell code with standalone SPM/Maven dependencies, enforcing strict delegate-based customization to eliminate the "eject trap" and boilerplate for adopters.
**Current focus:** v11.0 Release & Distribution Truth — publish native cores, lockstep-version with Hex, rewire gen.shell to published deps, prove with clean-room CI

## Current Position

Phase: 110 — Native Publish & Lockstep Infrastructure (not started)
Plan: —
Status: Roadmap defined; ready for /gsd:plan-phase 110
Last activity: 2026-06-14 — Roadmap created for v11.0

[░░░░░░░░░░░░░░░░░░░░] 0% (0/2 phases)

## Performance Metrics

**Velocity:**

- Total plans completed: 10 (v10.0)
- Average duration: —
- Total execution time: —

*Updated after each plan completion*

## Accumulated Context

### Decisions

Full decision log in PROJECT.md (Key Decisions). v10.0 milestone decisions archived there.

**v11.0 key decision (2026-06-14):** Two-phase split enforced by dependency graph — Phase 110 (publish + lockstep) must complete before Phase 111 (rewire + prove + release). You cannot clean-room-prove an unpublished dep; you must not cut Hex while gen.shell emits broken coordinates. This ordering is non-negotiable per research.

**v11.0 irreversibility notes (2026-06-14):** Maven Central releases are immutable; SwiftPM tags must not be force-moved after any adopter resolves them. Phase 110 includes mandatory dry-run and GPG verification gates before any real publish. Central Portal namespace `io.github.sztheory` must be verified before any publish config is committed.

### Pending Todos

None.

### Blockers/Concerns

- **Distribution gap (FOUNDATIONAL, surfaced 2026-06-14 assessment).** Hex publishes only `0.1.0`; ~4 months of shipped work (planning v3.4→v10.0) is uninstallable. The v5.0 standalone-package thesis is not actually distributed — the native cores have no publish config/CI and `mix crosswake.gen.shell` (default `--local false`) emits deps that don't exist (iOS `github.com/crosswake/...`, Android `dev.crosswake:shell-core-android:0.1.0`). An external adopter's generated shell won't build. This is the active v11.0 focus; see `threads/release-distribution-truth.md`.
- **Doc drift:** `MILESTONE-ARC.md` was stale (marked v7.0 "Active" though v7.0→v10.0 shipped); reconciled 2026-06-14. Watch closeout/parity verifiers that hardcode mid-flight milestones post-archival.

## Deferred Items

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| v8.0 gap | Phase 81 verification gap (human_needed, carried from v5.1) | Acknowledged | v8.0 close |
| v8.0 gap | `tighten-validation-ledger-closeout-gate` quick task | Acknowledged | v8.0 close |
| v8.0 gap | DASH-01: Surfacing offline adoption metrics | Deferred | v8.0 close |
| v8.0 gap | NTV-01: Extend storage budgets to native physical disk space | Deferred | v8.0 close |

## Session Continuity

Last session: 2026-06-14 — v11.0 roadmap created
Stopped at: Roadmap written; ready to plan Phase 110
Resume file: —

## Operator Next Steps

- Run `/gsd:plan-phase 110` to plan Phase 110: Native Publish & Lockstep Infrastructure
- Phase 110 covers PUB-01, PUB-02, PUB-03, LOCK-01, LOCK-02
- Phase 111 (Generator Rewire, Clean-Room Proof & Release) is blocked on Phase 110 completing
- PROOF-02 in Phase 111 is a graduation candidate — a permanent doctor/closeout "published-dep parity" check, structural sibling to the v10.0 brand-structural drift gate
