# Phase 36: Hermetic Proof Lane - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-29
**Phase:** 36-Hermetic Proof Lane
**Areas discussed:** Hermeticity mechanism (SC#4 contradiction), Mock-boundary fence assertion (SC#3 imprecision)

Advisor mode (calibration `minimal_decisive`, `opinionated`): two decisive recommendations
presented for confirmation because both reinterpret *locked* roadmap success criteria. Lower-
stakes mechanical choices (transition modeling, inline builders, self-scan guard pattern set,
inline evidence values) were decided by Claude per the user's profile and recorded as
Claude's Discretion / D-03/D-05/D-07 rather than bounced back.

---

## Hermeticity mechanism (SC#4 contradiction)

| Option | Description | Selected |
|--------|-------------|----------|
| require_file pure modules (idiom) | Follow phase21/34: `Code.require_file` the PURE example-host commerce modules at module scope; self-scan guard forbids require_file of example-host *runtime* paths only (live/endpoint/application/router/repo) + no process start/network. Tests the REAL shipped code; matches MockBackend moduledoc + precedent. | ✓ |
| Inline copies, zero require_file | Take SC#4 literally: inline Phase36-prefixed copies of the projection logic, require_file nothing. Self-contained but tests a COPY, not the real code; contradicts the Phase 35 design. | |

**User's choice:** require_file pure modules (idiom)
**Notes:** Locks D-01/D-02/D-03. SC#4's literal "no example-host require_file" is reinterpreted
as "no example-host *runtime*-path require_file" and flagged for the verifier (mirrors Phase 35
D-08). The self-scan guard enforces the runtime-path fence structurally by reading the proof's
own source.

---

## Mock-boundary fence assertion (SC#3 imprecision)

| Option | Description | Selected |
|--------|-------------|----------|
| Assert the two/three real truths | (1) `authority_mutation_allowed_from_evidence?/1 == false`; (2) `project_snapshot/2` rejects UNVERIFIED states (`:awaiting_verification`) with `{:error, :unverified_reconciliation_outcome}`; (3) a verified-but-non-refreshed state (`:verification_failed`) does NOT derive `:granted`. Faithful to shipped code. | ✓ |
| Assert SC#3 literally | Assert `project_snapshot` rejects ALL non-`:projection_refreshed` states. Factually wrong — code accepts four verified states; assertion would fail or codify a false claim. | |

**User's choice:** Assert the two/three real truths
**Notes:** Locks D-06. SC#3's literal wording is reinterpreted to distinguish the *verification
gate* (4 accepted states) from the *grant requirement* (`:projection_refreshed` only) and
flagged for the verifier.

---

## Claude's Discretion

- Transition modeling (D-05): ingest → `:awaiting_verification` status as the `:pending` origin,
  then `MockBackend.build_verified_snapshot/2` → `project_snapshot/2` → `:granted` (same runtime
  core, no 2-arity monotonic path).
- Inline `Phase34`-prefixed snapshot/evidence builders in the proof file (D-07), mirroring
  phase21 helpers — no cross-test-file require_file/alias.
- Self-scan guard concrete regex/substring set (D-03); inline-helper signatures.
- Inline evidence field values + `group_id` (anchored to `@subscription_entry_id
  "sub_pro_monthly"`); `:denied` snapshot's specific non-granting lane combination.
- Describe/test naming and assertion messages.

## Deferred Ideas

- ROADMAP SC#3 / SC#4 rewording to match D-02/D-06 (suggest via `/gsd-phase` before verification).
- `guides/commerce.md` walkthrough + docs-contract lock — Phase 37.
- StoreKit / Play Billing real adapters + merge-blocking graduation — v3.6 (AF-01).
- ExDoc zero-warnings cleanup (HEX-03) — deferred, unrelated.
