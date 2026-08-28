# Phase 160: Scoped Replay and Auth Safety - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-02
**Phase:** 160-scoped-replay-and-auth-safety
**Areas discussed:** Scope lifecycle and account switching, Replay authorization and server-side disablement, Privacy-safe auth and observability surfaces

---

## Scope Lifecycle and Account Switching

| Option | Description | Selected |
|--------|-------------|----------|
| Host-issued opaque scope plus compound partition and lifecycle fence | One shared store, scoped keys/indexes, persisted inactive/active/stopping state, monotonic epoch, and host authority mapping | ✓ |
| Deterministic keyed account digest | Derive a stable pseudonym from account context for local lookup | |
| Separate database/container per scope | Give every scope its own storage container and lifecycle | |

**User's choice:** Discuss all, research with subagents, and make one coherent recommendation so the user does not need to choose individual mechanics.

**Notes:** The selected approach prevents forgotten scope filters without turning Crosswake into an
identity/key-management or generic storage product. Deterministic digests remain linkable and
rotation-sensitive; separate containers multiply migrations, quota, orphan cleanup, and topology
leakage. The recommendation retains host ownership of issuance, mapping, encryption, retention,
and cleanup.

---

## Replay Authorization and Server-Side Disablement

| Option | Description | Selected |
|--------|-------------|----------|
| One gate snapshot per batch | Authorize/flag-check once, then bulk transact the batch | |
| Per-event admission and transaction | Re-check current scope/auth/route/flag before each ordered idempotent event transaction | ✓ |
| Serializable shared auth/flag database gate | Lock/version host control state in the same transactional system as mutations | |

**User's choice:** Delegated to the agent after research.

**Notes:** Batch snapshots are cheaper but allow later events to apply after authority changes.
Serializable shared control gives stronger ordering but creates a host control plane, operational
coupling, and scope beyond the existing `gated_by` seam. The selected bounded per-event contract
fits one study island, preserves partial progress, and makes the precise TOCTOU boundary explicit.

---

## Privacy-Safe Auth and Observability Surfaces

| Option | Description | Selected |
|--------|-------------|----------|
| Shared closed vocabulary plus per-surface allowlists | Separate sensitive wire/domain structures, normalize safe facts once, and expose only the subset each egress needs | ✓ |
| Independent typed allowlists | Give telemetry, doctor, inspection, logs, and evidence unrelated schemas | |
| Denylist/redaction of existing maps | Drop known sensitive keys from broad maps at export time | |

**User's choice:** Delegated to the agent after research.

**Notes:** Independent schemas drift and repeated denylist logic misses aliases, nested values, and
future keys. A shared closed vocabulary gives coherent semantics, while per-surface projectors avoid
turning that vocabulary into a permissive superset. Final evidence scanning remains defense in
depth. Opaque identifiers and their hashes remain sensitive.

---

## the agent's Discretion

- Exact private module/function names and normalized scope-ref shape.
- IndexedDB schema-migration mechanics and conservative batch ceiling.
- Retry/backoff timing, HTTP status details within the locked request-vs-event distinction, and
  stable safe rule identifiers.
- Test-file organization and host-owned microcopy variants consistent with the locked learner
  states and current brandbook.

## Deferred Ideas

None. Generic sync/storage, background replay, a Crosswake flag service, transactional host control
tables, dashboards, Android/device parity, auth-provider features, and broader UI remain out of
scope.
