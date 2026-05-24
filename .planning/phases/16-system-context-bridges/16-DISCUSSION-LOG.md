# Phase 16: System Context Bridges (Deep Link, Permissions Status) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in `16-CONTEXT.md` — this log preserves the alternatives considered.

**Date:** 2026-05-20
**Phase:** 16-system-context-bridges
**Areas discussed:** deep_link exposure model, deep_link route declaration posture, permissions.status family scope, permissions.status reply shape

---

## Deep-link exposure model

| Option | Description | Selected |
|--------|-------------|----------|
| Inbound shell activation only | Keep `deep_link` limited to app-entry normalization and manifest-first shell activation | ✓ |
| Inbound + outbound bridge command | Add route-local command authority for opening links/routes in the same phase | |
| Inbound now, outbound helpers later | Keep activation narrow now and add Phoenix-side ergonomics later if needed | |

**User's choice:** Delegated to agent synthesis; selected inbound shell activation only.
**Notes:** Recommendation aligned with existing shell contract, Phoenix URL idioms, Hotwire Native path configuration, and Crosswake’s anti-plugin-bus stance.

---

## Deep-link route declaration posture

| Option | Description | Selected |
|--------|-------------|----------|
| Explicit per-route entry metadata | Deep-link entry is opt-in route policy derived into manifest truth | ✓ |
| Ambient deep-linkability | All manifest routes become externally enterable once shell activation exists | |
| Explicit metadata with scope defaults | Keep opt-in semantics while allowing inherited defaults plus overrides | ✓ |

**User's choice:** Delegated to agent synthesis; selected explicit route-level metadata with default-deny semantics and optional scope defaults.
**Notes:** The important locked choice is explicit entry policy. Scope defaults are acceptable only as an ergonomic layer over an explicit opt-in model.

---

## `permissions.status` family scope

| Option | Description | Selected |
|--------|-------------|----------|
| Broad generic OS snapshot | Expose a wide app-level permission status surface | |
| Narrow point-of-need subset | Expose only read-only statuses aligned to immediate capability prerequisites | ✓ |
| Narrow public API with internal extensible registry | Ship a disciplined public surface while keeping an internal growth path | ✓ |

**User's choice:** Delegated to agent synthesis; selected narrow point-of-need public scope with room for internal registry growth.
**Notes:** Keeps support truth honest and avoids turning Phase 16 into a generic permission broker.

---

## `permissions.status` reply shape

| Option | Description | Selected |
|--------|-------------|----------|
| Tiny enum only | Minimal common enum with no structured nuance | |
| Small normalized enum + optional detail | Stable primary contract plus secondary platform facts when known | ✓ |
| Rich platform-specific primary contract | High-fidelity public payloads per platform/family | |

**User's choice:** Delegated to agent synthesis; selected small normalized primary status with optional detail.
**Notes:** Chosen for Elixir pattern-matching ergonomics, stable docs/versioning, and honest treatment of platform divergence.

---

## the agent's Discretion

- Exact route-policy field names for explicit deep-link entry metadata
- Exact normalized permission-status enum names
- Exact secondary detail payload shape
- Exact internal registry design for mapping permission aliases to capability prerequisites
- Exact doctor/support wording and denial copy

## Deferred Ideas

- Future outbound deep-link ergonomics as Phoenix-side helpers or a separately named family
- Future permission-request flows and broader app-wide permission orchestration
- Future richer platform-specific detail surfaces if support truth, doctor posture, and proof lanes mature enough to justify them
