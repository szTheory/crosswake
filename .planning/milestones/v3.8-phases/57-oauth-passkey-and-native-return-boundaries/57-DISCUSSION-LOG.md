# Phase 57: OAuth, Passkey, And Native Return Boundaries - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-06-02
**Phase:** 57-OAuth, Passkey, And Native Return Boundaries
**Areas discussed:** Route-local auth return seam, validation and authority promotion, native transport/proof posture

---

## Invocation And Research Method

The user asked to discuss all Phase 57 gray areas and explicitly requested subagent research for each area, with pros/cons/tradeoffs, idiomatic Elixir/Phoenix/Plug/Ecto fit, lessons from successful ecosystems, DX, user friendliness where applicable, project prompt corpus synthesis, and a one-shot cohesive recommendation set.

Initial `gsd-advisor-researcher` subagents failed because that installed role is pinned to a model unavailable for this account. The workflow retried with supported default subagents on the same three read-only research scopes.

---

## Route-Local Auth Return Seam

| Option | Description | Selected |
|--------|-------------|----------|
| Global provider registry | Central `oauth_providers`/provider setup keyed by vendors. Familiar but not route-local. | |
| Capability/bridge-first declaration | Treat auth returns as bridge/capability entries. Fits bridge vocabulary superficially but hides backend validation. | |
| Separate per-kind keys | `oauth_return`, `passkey_return`, `native_auth_return`. Strong typing but bloats policy and manifest shape. | |
| Minimal route-local `auth_return` | One key with `kind`, `transport`, `return_route_id`, and `validates`; deeper validation in Sigra contracts. | |
| Route-local seam plus Sigra contracts | One small route seam backed by `AuthReturn` envelope, evidence, attempt, completion, and audit contracts. | Yes |

**User's choice:** Discuss all and let the researched, cohesive recommendation drive decisions.

**Notes:** The selected shape preserves Crosswake's route-policy thesis, keeps provider names out of core route vocabulary, and matches existing code in `Policy.Schema`, `Policy.Route`, `Manifest.Types`, `Manifest.Builder`, and `Sigra.AuthReturn`.

---

## Validation And Authority Promotion

| Option | Description | Selected |
|--------|-------------|----------|
| Stateless signed returns | Phoenix.Token-style integrity and max-age without a server attempt row. Simple but weak for replay/revocation/audit. | |
| Server-backed one-time attempt rows | Host-owned Ecto records are the replay, expiry, binding, audit, and promotion source of truth. | Yes |
| Direct provider callbacks only | Provider libraries validate callbacks but callback success can be mistaken for session authority. | |
| Generic provider plugin bus | Extensible on paper but creates provider sprawl and unclear support truth. | |

**User's choice:** Discuss all and let the researched, cohesive recommendation drive decisions.

**Notes:** The selected shape mirrors Phase 55 handoff and Phase 56 step-up: signed/opaque artifacts are only locators/correlation evidence; backend records and transactions own authority promotion.

---

## Native Transport And Proof Posture

| Option | Description | Selected |
|--------|-------------|----------|
| HTTP callback route | Phoenix/backend callback route with exact redirect/callback, state/nonce/PKCE, expiry/replay, and attempt-record checks. | Yes |
| Verified HTTPS native link | Preferred sensitive native return posture using Universal Links/App Links style verification, with device proof advisory. | Yes |
| Custom scheme | Compatibility/advisory fallback; lower assurance because schemes can conflict or be intercepted. | Yes - advisory only |
| Bridge event | Internal shell evidence only; not OAuth redirect receiver, passkey authority, token transport, or route authority. | Yes - evidence only |
| Loopback HTTP | Desktop/CLI prior art, not v3.8 mobile-first support posture. | |

**User's choice:** Discuss all and let the researched, cohesive recommendation drive decisions.

**Notes:** The selected posture is verified-link-first and backend-authority-only. Merge-blocking proof covers hermetic contracts and no-authority assertions; provider/device/native proof stays advisory or deferred.

---

## the agent's Discretion

- Exact module names, example-host schema names, and support wording may be refined if Sigra namespace, route-local seam shape, and backend authority boundary remain intact.
- Exact provider evidence field names may be refined, but raw secrets/identifiers and authority fields must remain forbidden in envelopes, shell-safe details, docs fixtures, and telemetry-ready metadata.
- Example-host UX can remain contract-only or become a provider-neutral Auth Return Lab, but must not claim provider support, native auth UI, or device proof.

## Deferred Ideas

- Provider-specific OAuth templates.
- First-party passkey SDK wrappers.
- Refresh-token orchestration.
- Native auth UI.
- Merge-blocking device/provider proof.
- Phase 58 telemetry taxonomy and security closeout.
