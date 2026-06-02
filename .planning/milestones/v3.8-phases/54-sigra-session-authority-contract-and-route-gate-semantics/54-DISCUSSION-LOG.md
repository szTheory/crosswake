# Phase 54: Sigra Session Authority Contract And Route-Gate Semantics - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-01
**Phase:** 54-Sigra Session Authority Contract And Route-Gate Semantics
**Areas discussed:** Session authority shape, Route-gate failure semantics, Remembered and cached auth posture, Evaluator boundary

---

## Session Authority Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Token-claims-first gate | JWT/OIDC/provider claims drive RouteGate with minimal backend projection. Simple and stateless, but weak immediate revocation and drifts from backend-authority thesis. | |
| Stateful session row as sole authority | Gate always reads a backend session record. Strong revocation and expiry semantics, but couples all route gates to a session store. | |
| Hybrid backend projection plus bounded envelopes | Backend-projected `SessionAuthorityLane` is authority; tickets/intents/provider returns are evidence until backend promotion. | ✓ |

**User's choice:** The user asked the agent to research all areas with subagents and synthesize the best cohesive recommendation.
**Notes:** Chosen recommendation aligns with Crosswake's evidence-vs-authority posture, Phoenix/Plug server-session idioms, OWASP lifecycle guidance, and future Phase 55-57 envelope work.

---

## Route-Gate Failure Semantics

| Option | Description | Selected |
|--------|-------------|----------|
| One shell reason plus typed auth codes | Preserve `:step_up_required` while adding stable `auth.step_up.*` codes and allowlisted details. | ✓ |
| Broader shell-level auth denial reasons | Add reasons such as `:auth_missing`, `:auth_revoked`, `:auth_stale`. More glanceable, but higher public compatibility churn. | |
| Hybrid internal taxonomy only | Keep shell reason stable, add richer doctor/telemetry taxonomy, and defer shell expansion. | |

**User's choice:** The user delegated decision synthesis to the agent.
**Notes:** Recommendation preserves Phase 46/47 docs-contract truth, follows OWASP generic-user-error guidance, and avoids widening the shell API before handoff, ceremony, and return boundaries are proven.

---

## Remembered And Cached Auth Posture

| Option | Description | Selected |
|--------|-------------|----------|
| Explicit route posture enum | Add route-local values such as `:strict_recent`, `:remembered_ok`, and `:cached_read_only_ok`. Manifest-visible and fail-closed. | ✓ |
| Split booleans and TTLs | `allow_remembered_auth`, `allow_cached_auth`, TTL fields. Granular but footgun-prone. | |
| Sensitivity profile defaults only | Drive posture from `security` profile with overrides. Secure by default, but risks hidden behavior unless resolved policy is very visible. | |

**User's choice:** The user asked for a perfect cohesive recommendation, not a choice menu.
**Notes:** Recommendation uses explicit route posture while still allowing `security` to inform strict defaults. Cached auth must require read-only/degraded proof and fail closed when mutation or sensitive semantics are present.

---

## Evaluator Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| RouteGate only | Harden `RouteGate.evaluate/4` directly and leave Plug/LiveView reuse to Phase 56. Tight scope, but risks duplicated future logic. | |
| Thin reusable evaluator seam, no ceremony | Add a pure Sigra evaluator called by RouteGate and reusable by future Plug/LiveView wrappers. | ✓ |
| Full auth-session evaluator plus step-up skeleton | Shape challenge/intent/session-renewal orchestration now. Maximum reuse, but pulls Phase 56 into Phase 54. | |

**User's choice:** The user delegated final recommendation to the agent.
**Notes:** Recommendation creates the reusable decision core now while explicitly deferring step-up intent lifecycle, redirects, LiveView halts, Phoenix session renewal, and CSRF handling to Phase 56.

---

## the agent's Discretion

- Exact module names for the Sigra evaluator and result structs.
- Exact enum and denial code names, if the semantics remain stable, low-cardinality, and docs-contractable.
- Exact backward-compatible migration path from Phase 46 `mfa_level`/`auth_age` fields to richer `assurance_level`/timestamp-derived freshness.
- Exact proof file names and test grouping.

## Deferred Ideas

- Phase 55: single-use handoff tickets and backend redemption.
- Phase 56: step-up ceremony, Plug/controller and LiveView return flow, Phoenix session/CSRF renewal.
- Phase 57: OAuth, passkey, native deep-link, and shell bridge auth-return boundaries.
- Phase 58: full auth telemetry, docs-contract closeout, and security review.
