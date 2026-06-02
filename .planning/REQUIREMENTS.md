# Requirements: Crosswake

**Defined:** 2026-06-01
**Milestone:** v3.8 Full Sigra Auth and Session Machinery
**Core Value:** Make runtime boundaries explicit so Phoenix teams can ship credible mobile apps without hiding the tradeoffs between LiveView, offline, and native ownership.

## v3.8 Requirements

Requirements for the current milestone. Each requirement maps to exactly one roadmap phase.

### Session Authority

- [x] **SESS-01**: A Phoenix host can model backend-owned session authority with explicit state, assurance level, auth methods, authenticated-at, idle expiry, absolute expiry, renewal horizon, remembered-session posture, and session-version/revocation fields.
- [x] **SESS-02**: Route gates evaluate session authority fail-closed for missing context, non-active state, idle expiry, absolute expiry, revocation/version mismatch, insufficient assurance, and stale recent-auth before allowing sensitive routes.
- [x] **SESS-03**: Remembered or cached auth state cannot satisfy sensitive recent-auth route predicates unless the route explicitly opts into that weaker posture.

### Handoff Tickets

- [x] **HAND-01**: A Phoenix host can issue short-lived, signed, single-use session handoff tickets whose server-side records remain the replay, revocation, expiry, and audit source of truth.
- [x] **HAND-02**: A Phoenix host can redeem a valid handoff ticket through an atomic backend flow that consumes the ticket, renews the Phoenix session, and projects a refreshed `SessionAuthorityLane`.
- [x] **HAND-03**: Missing, invalid, expired, replayed, revoked, binding-mismatched, intent-mismatched, and route-mismatched handoff tickets deny with stable auth codes and sanitized shell-safe details.

### Step-Up Ceremony

- [x] **STEP-01**: A Phoenix host can create server-owned step-up intents for routes that require stronger assurance or fresher authentication, with bounded lifecycle states and manifest-known return targets.
- [x] **STEP-02**: Plug/controller routes and LiveView `on_mount` entry points share one step-up evaluator and fail closed into the same challenge/intent flow.
- [x] **STEP-03**: Successful step-up consumes the intent, renews session/CSRF posture, refreshes backend session authority, and returns only to a validated Crosswake route target.

### Auth Return Boundaries

- [x] **RETN-01**: A Phoenix host can declare OAuth, passkey, or native auth-return boundaries as typed, route-local seams rather than provider-specific global magic.
- [x] **RETN-02**: Auth-return envelopes validate state, nonce, PKCE posture, redirect matching, link verification status, expiry, and replay posture before any backend authority promotion.
- [x] **RETN-03**: OAuth callbacks, passkey assertions, native deep links, and shell bridge events remain evidence-only until backend validation updates session authority.

### Diagnostics And Proof

- [x] **DIAG-01**: Crosswake exposes a canonical Sigra auth denial code taxonomy, safe user-facing denial messages, and rich operator/developer detail without leaking tokens, provider payloads, passkey credential IDs, or PII.
- [ ] **DIAG-02**: Crosswake emits stable `[:crosswake, :auth, ...]` telemetry events with documented low-cardinality metadata for session evaluation, denial, handoff, step-up, OAuth return, and passkey return flows.
- [ ] **DIAG-03**: Doctor, support matrix, operator inspection, guides, and docs-contract tests distinguish full Sigra machinery from provider/device advisory proof and from v3.5 contract-only truth.
- [ ] **PROOF-01**: Merge-blocking hermetic proof covers contracts, route gates, replay/expiry/revocation, step-up returns, denial sanitization, telemetry/docs parity, and security-sensitive non-claims; provider/device proof remains advisory until promotion criteria pass.

## Future Requirements

Deferred to later milestones. Tracked but not in the current roadmap.

### Provider Implementations

- **PROV-01**: Crosswake can ship first-party provider-specific OAuth examples or templates after the adapter seams prove stable.
- **PROV-02**: Crosswake can ship first-party passkey SDK wrappers after the backend-return contract and advisory device proof mature.
- **PROV-03**: Crosswake can define refresh-token rotation guidance or helper SDKs after session handoff and step-up machinery are stable.

### Native Auth UX

- **NATV-01**: Crosswake can provide richer native auth UI examples after v3.8 proves the typed return boundary without taking authority into the shell.

## Out of Scope

Explicitly excluded for v3.8. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Identity-provider-specific product templates | v3.8 needs stable adapter seams and proof posture before vendor-specific templates. |
| Direct shell/WebView token authority | Violates backend-owned session authority and increases token leakage risk. |
| WebView localStorage or sessionStorage token storage guidance | Conflicts with the security posture and Crosswake's route-boundary thesis. |
| Generic native auth UI framework | Too broad and would pull Crosswake toward universal UI framework behavior. |
| High-frequency auth bridge state streaming | Auth changes should be low-frequency semantic events, not continuous client authority. |
| Offline sensitive mutation under stale cached auth | Offline claims must stay honest; cached auth cannot authorize sensitive mutation. |
| Merge-blocking provider/device proof claims | Provider/device auth flows remain advisory until explicit promotion criteria pass. |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| SESS-01 | Phase 54 | Complete |
| SESS-02 | Phase 54 | Complete |
| SESS-03 | Phase 54 | Complete |
| HAND-01 | Phase 55 | Complete |
| HAND-02 | Phase 55 | Complete |
| HAND-03 | Phase 55 | Complete |
| STEP-01 | Phase 56 | Complete |
| STEP-02 | Phase 56 | Complete |
| STEP-03 | Phase 56 | Complete |
| RETN-01 | Phase 57 | Complete |
| RETN-02 | Phase 57 | Complete |
| RETN-03 | Phase 57 | Complete |
| DIAG-01 | Phase 54 | Complete |
| DIAG-02 | Phase 58 | Pending |
| DIAG-03 | Phase 58 | Pending |
| PROOF-01 | Phase 58 | Pending |

**Coverage:**
- v3.8 requirements: 16 total
- Mapped to phases: 16
- Unmapped: 0

---
*Requirements defined: 2026-06-01 from v3.8 research synthesis.*
*Last updated: 2026-06-02 after Phase 54 completion.*
