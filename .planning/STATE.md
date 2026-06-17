---
gsd_state_version: 1.0
milestone: v12.0
milestone_name: CI Honesty & Real-E2E Sweep
status: executing
last_updated: "2026-06-17T21:56:09.630Z"
last_activity: 2026-06-17 -- Phase 112 execution started
progress:
  total_phases: 4
  completed_phases: 0
  total_plans: 2
  completed_plans: 0
  percent: 0
---

# Project State: Crosswake

## Project Reference

See: .planning/PROJECT.md (updated 2026-06-17)

**Core value:** Replace host-owned generated shell code with standalone SPM/Maven dependencies, enforcing strict delegate-based customization to eliminate the "eject trap" and boilerplate for adopters.
**Current focus:** Phase 112 — real-offline-outbox-flush

## Current Position

Phase: 112 (real-offline-outbox-flush) — EXECUTING
Plan: 1 of 2
Status: Executing Phase 112
Last activity: 2026-06-17 -- Phase 112 execution started

**Progress bar:** Phase 0/4 complete · Plan 0/TBD complete

## Performance Metrics

**Velocity:**

- Total plans completed: 13 (v10.0) + 8 (v11.0) = 21 across last two milestones
- Average duration: —
- Total execution time: —

*Updated after each plan completion*

## Accumulated Context

### Decisions

Full decision log in PROJECT.md (Key Decisions). v11.0 milestone decisions archived there.

**v12.0 key decisions (2026-06-17, locked by research):**

- Offline-sync reconnect flush is triggered by `window 'online'` event on the existing socketless `/offline` island — no migration to a LiveView route. The island is socketless by design (`put_root_layout(false)`); migrating would delete the proof the library exists to provide.
- The vestigial `StudySessionLive` `sync_outbox` mock is removed entirely, not relabeled as a manual-sync affordance. Labeling it "Manual Sync" would misrepresent the mechanism (server-side Elixir list, not client IndexedDB outbox) — a fresh dishonesty.
- Phase ordering is fixed: 112 (app change) → 113 (test rewrite + compile gate) → 114 (merge-blocking gate + permanent guard). Phase 115 (closeout/ledger/doc track) is independent and parallelizable but must complete before milestone close. Within Phase 115: GATE-02 must precede DEBT-01.
- `setOffline(false)` does NOT fire the browser `online` event — the test must explicitly `dispatchEvent(new Event('online'))` after calling `setOffline(false)` to trigger the app's reconnect handler.

**v11.0 key decision (2026-06-14):** Two-phase split enforced by dependency graph — Phase 110 (publish + lockstep) must complete before Phase 111 (rewire + prove + release). You cannot clean-room-prove an unpublished dep; you must not cut Hex while gen.shell emits broken coordinates. This ordering is non-negotiable per research.

### Pending Todos

None.

### Blockers/Concerns

- **~~Distribution gap (FOUNDATIONAL)~~ → RESOLVED by v11.0 (2026-06-17).** The v5.0 standalone-package thesis is now actually distributed: `crosswake 0.1.2` is live on Hex, Maven Central (`io.github.sztheory:crosswake-shell-core-android`), and the SwiftPM mirror (`szTheory/crosswake-shell-core-ios` `v0.1.2`); `gen.shell` emits resolvable, version-matched coordinates, proven by a clean-room CI lane and guarded by the `generator_coordinate_parity` check.
- **Doc drift (watch, ongoing):** Closeout/parity verifiers that hardcode the mid-flight milestone break post-archival — derive from frontmatter + search archived paths. `MILESTONE-ARC.md` reconciled 2026-06-14.
- **`MIRROR_PUSH_TOKEN` scope unexercised (carried open item).** The splitsh-lite 404 failed before the iOS push step, so the 0.1.2 mirror was completed out-of-band via `git subtree split`. The token's `Contents: write` scope is validated by the first iOS mirror on the NEXT release; if it 403s, regenerate the fine-grained PAT.
- **Branch-protection toggle (watch, Phase 114).** Registering `merge-blocking-offline-sync-e2e` as a required status check requires a `gh api ... PATCH`. Historical constraint: this has been harness-blocked in this environment (human step). Phase 114 ships the scripted/documented path; if toggle fails CI, the `script/register-e2e-gate.sh` carries the exact command. Must run green on `main` at least once before registration.

## Deferred Items

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| v8.0 gap | Phase 81 verification gap (human_needed, carried from v5.1) | Acknowledged | v8.0 close |
| v8.0 gap | DASH-01: Surfacing offline adoption metrics | Deferred to post-v12.0 | v8.0 close |
| v8.0 gap | NTV-01: Extend storage budgets to native physical disk space | Deferred to post-v12.0 | v8.0 close |
| v11.0 close | Quick task `tighten-validation-ledger-closeout-gate` (= LEDG-01 / DEBT-01) | Active — Phase 115 | v11.0 close |
| v11.0 close | Phase 110 `110-HUMAN-UAT.md` audit flag | Resolved — status `passed`, 0 pending scenarios (false positive) | v11.0 close |
| v11.0 close | Phase 110 `110-VERIFICATION.md` [human_needed] | Acknowledged — the human items were the 4 deferred UAT checks, all passed when 0.1.2 shipped live | v11.0 close |

## Session Continuity

Last session: 2026-06-17T21:38:52.803Z
Stopped at: Phase 112 context gathered
Resume file: .planning/phases/112-real-offline-outbox-flush/112-CONTEXT.md

## Operator Next Steps

- Plan Phase 112 with `/gsd:plan-phase 112`
- Phase 115 (closeout track) can be planned and executed in parallel with 112-114 — it is disjoint from the demo-app/E2E files
