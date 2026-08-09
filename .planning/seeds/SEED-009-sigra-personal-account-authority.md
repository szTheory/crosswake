---
id: SEED-009
status: planted
planted: 2026-08-08
planted_during: "v21.0 Phase 162 external physical-iPhone gate"
trigger_when: "Surface before the next Crosswake milestone that changes crosswake_sigra session authority, B2C/personal-account authentication, account switching, or a host Sigra integration; prioritize it when a real personal-account host is ready to integrate."
scope: Medium
---

# SEED-009: Make Sigra authority explicitly support personal-account sessions

## Why This Matters

A canonical B2C Sigra profile can have no organization model. Its authoritative
backend session scope must therefore represent a personal account with `org_id:
nil`, not a fabricated organization value. Crosswake must continue to decide
route authority only from a freshly backend-validated host projection, while
binding that projection to its opaque `session_ref` and `subject_ref`. An account
switch or mismatched projection must deny rather than replay work under another
account.

The work must preserve Crosswake's fail-closed posture: missing, malformed,
revoked, expired/non-active, and stale-version session authority deny explicitly.
Auth-return data, OAuth callback data, client values, raw tokens, credentials,
provider payloads, and grant flags are evidence/navigation only and cannot create
authority. Never introduce a sentinel such as `"personal"` or `"default-org"`.

## When to Surface

**Trigger:** before any milestone that changes `crosswake_sigra` authority
contracts, supports a personal-account/B2C host, or adds a real Sigra host
integration. Promote ahead of less urgent companion work once such a host is
ready, because fabricated organization scope would make the integration unsafe.

## Scope Estimate

**Medium** — a backward-compatible contract/evaluator/documentation release in
`crosswake_sigra`, with focused tests and a package release. It needs a public
type review but should not require changes to Crosswake core route ownership.

## Intended Contract and Acceptance Criteria

- `SessionAuthorityLane.org_id` and enclosing `AuthContext.org_id` accept `nil`
  to mean an explicit personal-account session; when present, `org_id` remains a
  nonblank string.
- Keep `session_ref` and `subject_ref` opaque, server-owned, nonblank references.
  A host must construct/revalidate the projection from its backend Sigra session
  immediately before Crosswake evaluation.
- Bind a projection to the current backend-validated `session_ref` plus
  `subject_ref`; subject or session mismatch fails closed, including during
  account switching and replay admission.
- Preserve explicit evaluator denials for absent/malformed context, revoked,
  expired or non-active state, and session-version mismatch.
- Return/OAuth/client data remains non-authoritative evidence. Authority and
  return transport continue to reject raw OAuth tokens, credentials, provider
  payloads, and grant/access flags; opaque reference-only evidence is acceptable.
- Add focused contract/evaluator tests for valid personal and organization
  sessions, blank organization rejection, the fail-closed states above,
  session/subject mismatch, and return evidence that cannot grant access.
- Document the public types, host revalidation obligation, account-switch
  behavior, compatibility impact, and migration/release version.

## Breadcrumbs

- `packages/crosswake_sigra/lib/crosswake/companions/sigra/contracts.ex` —
  `AuthContext` and `SessionAuthorityLane` public types and validation seam.
- `packages/crosswake_sigra/lib/crosswake/companions/sigra/evaluator.ex` —
  current fail-closed state, expiry, and version checks.
- `packages/crosswake_sigra/lib/crosswake/companions/sigra.ex` — companion
  replay-decision boundary that must remain a safe allow-or-`sigra_denied`
  projection.
- `packages/crosswake_sigra/test/crosswake/companions/sigra/contracts_test.exs`
  — focused public-contract coverage to extend.
- `packages/crosswake_sigra/README.md` — adopter-facing single-user B2C guidance;
  reconcile it with the released contract rather than claiming support early.
- `.planning/REQUIREMENTS.md` — SCOPE-05 assigns backend session-authority
  evidence to `crosswake_sigra`.
- `.planning/STATE.md` — records scoped replay and safe Sigra projection as
  current architectural decisions.

## Notes

The local source tree already contains some personal-account wording and nullable
type declarations. Activation must audit the released `crosswake_sigra` version
and every construction/evaluation path rather than treating those declarations as
proof that the end-to-end contract, account-switch binding, and tests are done.

This is an interoperability/security correction for one companion, not a reason
to broaden Crosswake into generic identity, organization, token, or OAuth
transport infrastructure.
