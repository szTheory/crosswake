---
gsd_state_version: 1.0
milestone: v11.0
milestone_name: Release & Distribution Truth
status: complete
last_updated: "2026-06-17T15:45:00Z"
last_activity: 2026-06-17
progress:
  total_phases: 2
  completed_phases: 2
  total_plans: 8
  completed_plans: 8
  percent: 100
---

# Project State: Crosswake

## Project Reference

See: .planning/PROJECT.md (updated 2026-06-14)

**Core value:** Replace host-owned generated shell code with standalone SPM/Maven dependencies, enforcing strict delegate-based customization to eliminate the "eject trap" and boilerplate for adopters.
**Current focus:** v11.0 COMPLETE — 0.1.2 shipped to all three registries (2026-06-17).

## Current Position

Phase: 111 (generator-rewire-clean-room-proof-release) — COMPLETE
Plan: 5 of 5 (done)
Status: RELEASED. crosswake 0.1.2 live on Hex, Maven Central (`io.github.sztheory:crosswake-shell-core-android`), and the SwiftPM mirror (`szTheory/crosswake-shell-core-ios` `v0.1.2`).
Last activity: 2026-06-17
Resume: v11.0 done — next is `/gsd:complete-milestone` (archive v11.0) then `/gsd:new-milestone`.

[████████████████████] 100% (8/8 v11.0 plans)

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
- **~~Release cut blocked (2026-06-14)~~ → RESOLVED 2026-06-17.** All 8 secrets provisioned, 4 `110-HUMAN-UAT.md` checks passed, Release PR #8 merged → **0.1.2 published to Hex + Maven Central + SwiftPM mirror**. The first live run exposed latent pipeline bugs, all fixed on main (PRs #20/#21/#22): fire-drill artifact-name assertion, missing Android auto-publish (`-PcrosswakeAutomaticRelease=true`), Central Portal poll auth/endpoint (Bearer + `/status?id=` + `/deployment/{id}`; no list endpoint), splitsh-lite version (`v1.0.1`, not assetless `v2.0.0`). `release-as` pin removed.
- **`MIRROR_PUSH_TOKEN` scope unexercised.** The splitsh-lite 404 failed before the iOS push step, so the 0.1.2 mirror was completed out-of-band via `git subtree split`. The token's `Contents: write` scope is validated by the first iOS mirror on the NEXT release; if it 403s, regenerate the fine-grained PAT.

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
| Phase 111 P05 | release checkpoint | DONE — 0.1.2 shipped (PR #8 merged 2026-06-17) | — |

## Session Continuity

Last session: 2026-06-17 (release execution)
Stopped at: v11.0 COMPLETE — 0.1.2 shipped to all three registries; post-release cleanup merged (PR #22)
Resume file: None

## Operator Next Steps

- **v11.0 is DONE.** Next: `/gsd:complete-milestone` to archive v11.0, then `/gsd:new-milestone`.
- 0.1.2 verified live: Hex `crosswake` 0.1.2; Maven Central `io.github.sztheory:crosswake-shell-core-android:0.1.2` (repo1.maven.org 200); SwiftPM mirror tag `v0.1.2` (clean, `.build` excluded). Phase 110 (3/3) and Phase 111 (5/5) both complete.
- All 4 `110-HUMAN-UAT.md` items passed; fire-drill now validates-then-drops cleanly via the corrected Central Portal API.
- The clean-room-proof jobs (PROOF-01) were SKIPPED on the 0.1.2 run because publish-ios-core failed first (splitsh 404, since fixed); they will run green on the next release. Hex+Maven were independently verified live.
- Only open item: `MIRROR_PUSH_TOKEN` scope, validated on the next iOS mirror (see Blockers).
- Mirror repo `szTheory/crosswake-shell-core-ios` now seeded: branch `main` + tag `v0.1.2`, default branch `main`, `tag-immutability` ruleset active.
