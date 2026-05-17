# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-18)

**Core value:** Make runtime boundaries explicit so Phoenix teams can ship credible mobile apps without hiding the tradeoffs between LiveView, offline, and native ownership.
**Current focus:** Phase 8 planning - turning the locked profile matrix into the Selective Native Flow exemplar lane

## Current Position

Phase: Phase 7 complete (next: Phase 8 Selective Native Flow Exemplar)
Plan: 07-01, 07-02, and 07-03 complete
Status: Phase 7 landed the shared `/saas` exemplar lane, approvals-led LiveView flow, bounded haptics proof, SaaS boundary docs, and checked-in shell-proof alignment.
Last activity: 2026-05-18 — Completed Phase 7 Phoenix SaaS Portal Exemplar

Progress: [###-------] 30%

## Performance Metrics

**Velocity:**
- Total plans completed: 18
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
- Last 5 plans: 06-01, 06-02, 07-01, 07-02, and 07-03 landed; the milestone now has a proof-backed Phoenix SaaS exemplar lane
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

### Pending Todos

None yet.

### Blockers/Concerns

- The remaining exemplar phases must keep extending the shared artifact class instead of introducing parallel sample apps or phase-specific proof harnesses.
- Selective-native work needs to keep native ownership narrow and explicit; the Phase 7 SaaS lane already proved the value of not widening bridge authority prematurely.
- Native proof remains environment-sensitive even with the current green lanes; later exemplar work should treat simulator and emulator drift as product-surface risk.

## Deferred Items

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| Integrations | First-party companion integrations remain v2 scope until the core contract is proven | Deferred | 2026-05-12 |
| Platform | Desktop packaging remains out of v1 scope | Deferred | 2026-05-12 |

## Session Continuity

Last session: 2026-05-18
Stopped at: Phase 7 is complete; next work is discussing or planning Phase 8 against the locked selective-native lane
Resume file: None
