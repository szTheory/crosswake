---
gsd_state_version: 1.0
milestone: v11.0
milestone_name: Release & Distribution Truth
status: executing
last_updated: "2026-06-14T23:03:34Z"
last_activity: 2026-06-14
progress:
  total_phases: 2
  completed_phases: 1
  total_plans: 8
  completed_plans: 7
  percent: 88
---

# Project State: Crosswake

## Project Reference

See: .planning/PROJECT.md (updated 2026-06-14)

**Core value:** Replace host-owned generated shell code with standalone SPM/Maven dependencies, enforcing strict delegate-based customization to eliminate the "eject trap" and boilerplate for adopters.
**Current focus:** Phase 111 — generator-rewire-clean-room-proof-release

## Current Position

Phase: 111 (generator-rewire-clean-room-proof-release) — EXECUTING
Plan: 5 of 5
Status: Release PR ready; blocked before publish
Last activity: 2026-06-14
Resume: /gsd:execute-phase 111. Release PR #8 now targets 0.1.2 and bumps `.release-please-manifest.json`, `mix.exs`, and `packages/crosswake-shell-core-android/build.gradle.kts`; do not merge it until the missing publish secrets and Phase 110 human-UAT items are complete.

[██████████████████░░] 88% (7/8 v11.0 plans)

## Performance Metrics

**Velocity:**

- Total plans completed: 13 (v10.0)
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
- **Release cut blocked (2026-06-14):** Release PR #8 is ready for the coordinated 0.1.2 cut, but `gh secret list --repo szTheory/crosswake` shows only `HEX_API_KEY` and `RELEASE_PLEASE_TOKEN`. Missing: `MIRROR_PUSH_TOKEN`, `ORG_GRADLE_PROJECT_mavenCentralUsername`, `ORG_GRADLE_PROJECT_mavenCentralPassword`, `ORG_GRADLE_PROJECT_signingInMemoryKey`, `ORG_GRADLE_PROJECT_signingInMemoryKeyId`, `ORG_GRADLE_PROJECT_signingInMemoryKeyPassword`. Do not merge Release PR #8 until these are set and the 4 `110-HUMAN-UAT.md` checks pass; Maven Central versions are immutable.

## Deferred Items

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| v8.0 gap | Phase 81 verification gap (human_needed, carried from v5.1) | Acknowledged | v8.0 close |
| v8.0 gap | `tighten-validation-ledger-closeout-gate` quick task | Acknowledged | v8.0 close |
| v8.0 gap | DASH-01: Surfacing offline adoption metrics | Deferred | v8.0 close |
| v8.0 gap | NTV-01: Extend storage budgets to native physical disk space | Deferred | v8.0 close |
| Phase 111 P01 | 5 min | 2 tasks | 4 files |
| Phase 111 P03 | 15 min | 2 tasks | 12 files |
| Phase 111 P02 | 6 min | 2 tasks | 4 files |
| Phase 111 P04 | 4 min | 2 tasks | 1 file |
| Phase 111 P05 | release checkpoint | PR #8 ready | blocked on secrets/UAT |

## Session Continuity

Last session: 2026-06-14T23:03:34Z
Stopped at: 111-05 release checkpoint — Release PR #8 ready, not merged
Resume file: None

## Operator Next Steps

- Phase 110 COMPLETE (3/3 plans, 8/8 must-haves; 2 verification blockers found & fixed inline).
- Continue Phase 111 with 111-05 after credentials are provisioned: merge Release PR #8, observe Hex/iOS/Android publish jobs plus clean-room proof jobs, then remove `release-as`.
- Provision the 6 missing secrets named above per `SETUP.md`, then exercise the 4 `110-HUMAN-UAT.md` items (android-publish-fire-drill + lockstep-truth dispatch lanes, GPG keyserver upload, Sonatype namespace verify).
- Release PR #8 is the real coordinated Hex 0.1.2 cut (REL-01, last); it currently has the correct lockstep diff across `.release-please-manifest.json`, `mix.exs`, and Android `build.gradle.kts`.
- PROOF-02 completed in Phase 111 Plan 02 — `generator_coordinate_parity` is now a permanent publish-readiness guard and plain `mix test` tripwire.
- PROOF-01 completed in Phase 111 Plan 04 — clean-room proof jobs are wired in `release-please.yml`; first live green run waits for the 0.1.2 cut.
- Automated setup completed during 111-05: `szTheory/crosswake-shell-core-ios` was created as an empty public mirror repo and tag immutability ruleset `tag-immutability` was applied.
