# Phase 151: Subscription Learning Showcase - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-07-11
**Phase:** 151-Subscription Learning Showcase
**Areas discussed:** LearnLoop primary workflow, Offline study integration, Entitlement/paywall pressure, Fixture and progress model

---

## User Direction

The user selected all gray areas and requested a one-shot, research-backed recommendation pass. The instruction was to use subagents, consider pros/cons/tradeoffs and examples for each approach, apply idiomatic Elixir/Plug/Ecto/Phoenix guidance, consider lessons and footguns from successful libraries/apps in adjacent ecosystems, emphasize developer ergonomics and user-friendly UX, apply relevant local prompt research, and produce cohesive recommendations that support Crosswake's goals.

Four `gsd-advisor-researcher` subagents were spawned:

- LearnLoop primary workflow
- Offline study integration
- Entitlement/paywall pressure
- Fixture/progress model and UI/UX direction

The main agent also reviewed local planning artifacts, current code, relevant prompt research, and official/current ecosystem sources.

---

## LearnLoop Primary Workflow

| Option | Description | Selected |
|--------|-------------|----------|
| Course catalog -> course detail -> lesson -> offline study -> progress/history | Familiar LMS path and strong learning JTBD, but entitlement pressure can feel bolted on and the lane can drift into generic LMS scope. | |
| Subscription dashboard -> gated course -> paywall -> offline study | Foregrounds entitlement pressure, but starts with monetization and risks overclaiming live storefront support. | |
| Blended dashboard -> course/pack detail -> gated lesson/paywall pressure -> offline study -> sync/progress history | Product-first learner home that covers courses, lessons, packs, progress, subscription state, offline island, outbox, reconciliation, and support truth in one journey. | yes |

**User's choice:** User asked the agent to recommend after considering all.
**Notes:** Recommendation is the blended workflow because it satisfies LEARN-01 through LEARN-04 without turning the lane into a broad LMS or a commerce-first demo.

---

## Offline Study Integration

| Option | Description | Selected |
|--------|-------------|----------|
| Keep `/offline` canonical and build LearnLoop shell around it | Lowest churn and preserves current Playwright proof, but leaves the primary lane proof-first instead of product-first. | |
| Product-first `/learnloop/*` routes preserving real IndexedDB/outbox behavior | Matches Phase 149/150 product-lane precedent while preserving true local-first mutation. | yes |
| Use `/study/session` and `/study/history` as primary routes and leave `/offline` legacy | Close to existing route metadata, but current `/study/session` is a LiveView simulation and is not honest as the core offline island. | |

**User's choice:** User asked for coherent recommendation.
**Notes:** Recommendation is to make `/learnloop/*` primary and keep the actual study session socketless and browser-owned. `/offline` can remain a proof alias or implementation source. Current `/study/session` should not be promoted unless converted.

---

## Entitlement/Paywall Pressure

| Option | Description | Selected |
|--------|-------------|----------|
| Lightweight background status badges only | Low scope, but too passive for LEARN-03 and weak capability-map evidence. | |
| Gated lesson/paywall moment inside learning flow | Strong product moment, but can imply live storefront support unless copy is strict. | |
| Full mocked subscription panel with all states | Strong contract inspection, but too diagnostics-first and risks pulling Phase 151 into future commerce scope. | |
| Blended gated lesson plus compact backend-owned entitlement diagnostics | Shows learner friction, keeps backend authority explicit, reuses existing projection vocabulary, and preserves commerce scope boundaries. | yes |

**User's choice:** User asked for recommendation.
**Notes:** Recommendation is blended gated lesson plus compact diagnostics. Primary states: granted, pending, stale, denied. Copy must avoid implying live StoreKit/Play Billing/RevenueCat support.

---

## Fixture and Progress Model

| Option | Description | Selected |
|--------|-------------|----------|
| Deterministic maps/read contexts only, persist existing review/sync events | Lowest scope and preserves reset truth, but LearnLoop could feel thin. | |
| Narrow persisted learner progress/subscription evidence | Matches Phase 149/150, supports refresh-proof evidence, and keeps broad catalog data deterministic. | yes |
| Broad Ecto schemas for courses/lessons/packs/learners/progress/subscription | Most LMS-like, but overbuilds Phase 151 and risks generic product gravity. | |

**User's choice:** User asked for recommendation.
**Notes:** Recommendation is deterministic course/lesson/pack/learner breadth plus narrow persisted evidence: existing review events, progress projection, and at most a narrow mocked entitlement snapshot/event if needed.

---

## Research Notes

- Phoenix contexts guide: contexts centralize data access and validation instead of scattering logic across controllers and LiveViews.
- Ecto.Multi docs: useful for multi-operation transactions and introspection, but ordinary control flow is simpler for most single-operation cases.
- LiveViewTest docs: fast `phx-` event tests are appropriate for LiveView-owned shell routes.
- Android offline-first docs: true offline starts at the data layer, needs a local data source, and must be usable without reliable network.
- Hotwire Native path configuration: route/path behavior is a proven mobile-web pattern; Crosswake should keep Phoenix route policy authoritative.
- Google Play Billing docs: verify purchases on a secure backend before granting entitlements; pending purchases must not grant access.
- Apple StoreKit/App Store Server API docs: transaction/subscription truth is signed/backend-visible and should feed support and entitlement projection.
- Duolingo/Moodle references: course paths, right-next-lesson flow, progress visibility, and completion state are familiar learning UX patterns.

---

## Claude's Discretion

- Exact module names and whether to wrap or refactor `/offline` into `/learnloop/study/session`.
- Exact route names if Phoenix constraints suggest a smaller route set.
- Whether `/learnloop/sync` aliases `/study/sync` or the route tour keeps posting to `/study/sync`.
- Whether narrow entitlement evidence needs persistence or can stay mocked/projection-only.
- Exact UI copy/layout, provided the product-first lane and offline/entitlement truth are preserved.

## Deferred Ideas

- Broad LMS/course-authoring/admin features.
- Native SQLite, native study screen, native media/audio/video packs, storage-budget productization, and background sync.
- Production StoreKit, Play Billing, RevenueCat, Accrue, or other live commerce adapters.
- Device-local entitlement authority and offline purchase replay.
- Multi-device conflict review, generic sync helpers, `crosswake_dashboard`, and Phase 152 capability-map work.
