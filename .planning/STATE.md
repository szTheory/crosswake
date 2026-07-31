---
gsd_state_version: 1.0
milestone: v21.0
milestone_name: First B2C Adopter Readiness
current_phase: 158
current_phase_name: adoption-reset-and-route-map
status: executing
stopped_at: Completed 158-02-PLAN.md
last_updated: "2026-07-31T13:55:31.213Z"
last_activity: 2026-07-31
last_activity_desc: Phase 158 execution started
progress:
  total_phases: 5
  completed_phases: 0
  total_plans: 4
  completed_plans: 2
  percent: 0
current_plan: null
---

# Project State

## Current Position

Phase: 158 (adoption-reset-and-route-map) — EXECUTING
Plan: 3 of 4
Status: Ready to execute
Last activity: 2026-07-31 — Phase 158 execution started

## Active Objective

Make the First B2C Adopter the forcing function. Crosswake is infrastructure, not a separate
business line. The milestone ends with one physical-iPhone offline study proof, not a broader
framework launch.

## Milestone Boundary

- Customer Alpha may be web-only; Crosswake has no Alpha deliverable.
- Public v1 requires iPhone, one offline mutation island, offline pronunciation media, auth
  continuity, server-side disablement, host-reusable proof, and physical-device evidence.

- Stop Crosswake work after 2026-08-18 except defects demonstrated by Phase 162.
- Reversal requires two independent active adopters or a separately funded business-line mandate.

## Next Action

Run `$gsd-execute-phase 158`. Execution follows the annotated three-wave plan in
`.planning/ROADMAP.md`; the tracer plan is
`.planning/phases/158-adoption-reset-and-route-map/158-01-PLAN.md`.

## Blockers

- The route inventory needs adopter-supplied concrete route IDs/paths, mutation actions, staleness,
  auth sensitivity, expected pronunciation-pack sizes/codecs, and fallbacks.

- Phase 162 ultimately needs a runnable adopter host, backend replay endpoint, and physical iPhone.
- The canonical historical six product-failure labels were not stored because only a privacy-safe
  proxy audit was authorized.

## Decisions

- GET-6 accepted: Crosswake is infrastructure for the First B2C Adopter.
- v20 is stopped/partial, not shipped; no v20.0 completion tag.
- Android is frozen at current generator/JVM/vector posture.
- Highest-impact framework change: host-reusable proof-lane generator.
- Offline mutation envelopes are scope-bound and sensitive by default.
- Pronunciation media uses one host-supplied foreground iOS pack adapter.
- Feature flags remain host-owned through existing `gated_by`.
- Generic sync and generic native storage non-goals remain in force.
- [Phase ?]: Route-local safety posture is represented as a closed status/value pair and never inherits from surface defaults.
- [Phase ?]: Empty or unknown-blocking inventories are explicitly blocked from promotion.
- [Phase ?]: Canonical capability rows use adoption_implication; v20_implication remains a renderer input alias for one documented compatibility window.
- [Phase ?]: Conflicting canonical and legacy implication values fail closed without echoing supplied row content.

## Deferred Items

- Phase 156 native menu/action-button planning artifacts are retained but abandoned.
- Phase 157 hardening/promotion work is not active.
- Brandbook/showcase/profile/launch polish is frozen as business-line investment.
- Android device/parity work is frozen.
- Capture/device controls, commerce productionization, dashboard, and broad offline/storage
  productization require post-proof adopter evidence.

## Privacy and Context Rules

- Durable codename: **First B2C Adopter** (`first_b2c_adopter`).
- Public guide phrase: **first adopter**.
- Never store the real adopter name, founder identity, price, geography, customer information,
  proprietary product taxonomy, or revealing links.

- Never attempt to infer or rediscover the adopter identity from git history or external sources.
- Raw answer payloads, media, transcripts, credentials, account IDs, tokens, and stable device IDs
  are forbidden from diagnostics and proof artifacts.

## Working-Tree Note

The pre-existing `.planning/config.json` modification is unrelated and must not be overwritten by
this milestone reset.

## Session

**Last session:** 2026-07-31T13:55:31.206Z
**Stopped at:** Completed 158-02-PLAN.md
**Resume file:** None

## Performance Metrics

| Plan | Duration | Tasks | Files |
|------|----------|-------|-------|
| Phase 158-adoption-reset-and-route-map P01 | 6m | 2 tasks | 3 files |
| Phase 158-adoption-reset-and-route-map P02 | 10m | 2 tasks | 5 files |
