# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-19)

**Core value:** Make runtime boundaries explicit so Phoenix teams can ship credible mobile apps without hiding the tradeoffs between LiveView, offline, and native ownership.
**Current focus:** Milestone `v3.0 Capability Contract And Packaging`, starting with Phase 11: Capability Taxonomy And Contract Rubric.

## Current Position

Phase: 11
Plan: N/A
Status: Milestone initialized
Last activity: 2026-05-19 — Milestone `v3.0 Capability Contract And Packaging` started

Progress: [----------] 0%

## Performance Metrics

**Velocity:**
- Total plans completed: 19
- Average duration: n/a
- Total execution time: n/a

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 1. Route Policy Foundation | 4 | n/a | n/a |
| 2. Manifest Truth And Compatibility | 4 | n/a | n/a |
| 3. Native Shell Boot And Bounded Bridge | 0 | n/a | n/a |
| 4. Honest Offline Contract | 0 | n/a | n/a |

**Recent Trend:**
- Last milestone shipped: v2.0 Adopter Stress Profiles on 2026-05-19
- Current milestone opened: v3.0 Capability Contract And Packaging on 2026-05-19
- Trend: Positive

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- Phase 1-5 roadmap follows the route-policy thesis instead of splitting work by models, APIs, and UI layers.
- Shell, bridge, offline, and pack work are staged after manifest and compatibility truth to avoid support dishonesty.
- Phase 2 now establishes canonical manifest, compatibility, doctor, and support-doc truth that Phase 3 shell work must consume rather than re-specify.
- Phase 3 executed as six plans: activation and denial contract, generator and fixtures, iOS shell, Android shell, bounded bridge, then doctor/docs/proof wiring.
- Phase 3 doctor/docs/support truth originally held `verification required` until both generated-project proof hooks passed; Phase 5 proof lanes and support publication closed that gap.
- The Android generated shell now self-bootstraps Gradle instead of depending on a missing wrapper jar.
- Phase 4 proves one narrow offline story only: explicit cached read-only hydration plus one study-session offline island with append-only journal durability, explicit replay outcomes, and route-local diagnostics.
- Phase 4 support posture is split intentionally: repo-local offline contract surfaces are supported by `script/verify_offline_contract.sh`, and generated shell runtime support is now backed by the generated-shell proof hooks and checked-in example hosts.
- Phase 5 pack lifecycle remains intentionally narrow: install, verify, availability, stale, invalidation, and failure semantics only, without widening into generic asset management.
- Pack activation now accepts both legacy installed-version strings and typed inventory records so generated shell work can adopt lifecycle truth incrementally.
- Pack lifecycle denials continue to reuse `pack_incompatible` instead of adding a second pack-specific failure vocabulary.
- Generated shells now block route activation on explicit required-pack UI and foreground-first install or invalidation actions instead of going straight to pack denial.
- Transfer seams now stay route-local and semantic, and the manifest owns their typed declaration truth before any bridge command or shell execution is added.
- Phase 5 transfer work intentionally stops at declaration and manifest truth in 05-04; command exposure and native execution stay deferred to later plans.
- Phase 5 bridge transfer command exposure is derived from manifest-declared route seams only and remains bounded to explicit semantic commands instead of generic file or URL authority.
- Phase 5 now exposes one public native escape hatch only: `:native_screen` media capture with explicit local staging and explicit transfer handoff metadata.
- Generated shells open declared native capture routes directly and keep non-capture fallback fail-closed instead of drifting into generic bounded-web upload behavior.
- Generated shells now execute `transfer.import`, `transfer.export`, `transfer.download`, and `transfer.upload.prepare` only through route-local transfer coordinators backed by manifest-declared seams.
- Native capture handoff is now manifest-derived and explicit on both platforms; staged local media still does not imply upload completion.
- Phase 6 now fixes the public adopter vocabulary around `Phoenix SaaS Portal`, `Selective Native Flow`, and `Local-First Study Flow`, and requires later exemplar phases to extend one shared example-host artifact class.
- Phase 7 now proves one authenticated Phoenix SaaS companion lane inside the shared example host: five `/saas` routes, host-owned auth, one guarded approval action, and one bounded haptics confirmation seam.
- The checked-in iOS and Android proof hosts now boot the SaaS approval route as part of the public artifact class instead of staying pinned to older library-only activation truth.
- Android shell activation now matches dynamic manifest paths for deep links so routes like `/saas/approvals/:id` resolve correctly instead of failing closed as inactive.
- Phase 9 offline route policy metadata was changed from `:island` to `:local_first` to align with framework definitions during API implementation.
- The 09-03 StudySessionLive implements the offline island pattern by accumulating an in-memory outbox payload to mock client progression before triggering a manual simulated sync.
- Post-`v2.0` capability expansion is now sequenced as contracts-first work: taxonomy, packaging, commerce seams, and support truth land before broader native or companion breadth.

### Pending Todos

- Start Phase 11 discussion or planning.

### Blockers/Concerns

- Native proof remains environment-sensitive even with the current green lanes; future capability expansion should keep simulator and emulator drift visible as product-surface risk.
- Capability and commerce breadth must preserve explicit route ownership and typed, low-frequency bridge contracts.
- Companion package and release-boundary decisions now directly affect future support claims, rebuild expectations, and proof posture.

## Deferred Items

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| Integrations | First-party companion integrations remain deferred until the current contract and packaging milestone lands | Deferred | 2026-05-19 |
| Platform | Desktop packaging remains out of the near-term arc | Deferred | 2026-05-19 |

## Session Continuity

Last session: 2026-05-19
Stopped at: Milestone initialized. Next command is `$gsd-discuss-phase 11` or `$gsd-plan-phase 11`.
Resume file: None
