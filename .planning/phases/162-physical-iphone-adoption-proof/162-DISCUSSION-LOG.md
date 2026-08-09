# Phase 162: Physical-iPhone Adoption Proof - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-04
**Phase:** 162-physical-iphone-adoption-proof
**Areas discussed:** Exit-test orchestration, Evidence artifact shape, Host/adopter handoff gate, Recovery proof

---

## Exit-test orchestration

| Option | Description | Selected |
|---|---|---|
| Sequential host-owned proof lane | Extend the existing generated proof lane with a physical-device driver and independent Phoenix assertions. | ✓ |
| UI-only device test | Treat visible status and local XCUITest assertions as full replay/auth proof. | |
| Generic replication/proof service | Build broad sync/device infrastructure for this run. | |

**User's choice:** Lock the research-backed recommendation.
**Notes:** The selected direction preserves Phoenix/Ecto authority and exercises the full offline-to-replay path without resetting storage during relaunch.

---

## Evidence artifact shape

| Option | Description | Selected |
|---|---|---|
| Typed physical-device evidence | Per-assertion closed outcomes, a `physical_iphone` device class, strict allowlist, final-byte scan, and atomic publication. | ✓ |
| Aggregate simulator-style artifact | Reuse aggregate output or XCUITest result bundles without device distinction. | |
| Retained media/device-farm output | Use screenshots, video, logs, attachments, or permanent device CI. | |

**User's choice:** Lock the research-backed recommendation.
**Notes:** Promotion evidence is limited to closed metadata and approved hashes; raw artifacts are ephemeral.

---

## Host/adopter handoff gate

| Option | Description | Selected |
|---|---|---|
| Stable preflight gate | Require validated TODO-002 input, signed host, physical device, isolated adapter, and backend controls before the run. | ✓ |
| Partial run | Start with unavailable prerequisites and infer missing route/device facts. | |
| Broaden the framework | Replace host-specific setup with a new generic fixture/control platform. | |

**User's choice:** Lock the research-backed recommendation.
**Notes:** Missing prerequisites yield a stable blocked outcome and cannot promote support truth.

---

## Recovery proof

| Option | Description | Selected |
|---|---|---|
| Task-oriented explicit recovery | Preserve retained work; distinguish saved, syncing, needs-attention, and paused states. | ✓ |
| Generic sync failure/retry | Collapse rejection, conflict, auth, and disablement into one retryable state. | |
| Silent fallback | Last-write-wins, queue deletion, online-only fallback, or hidden account switch. | |

**User's choice:** Lock the research-backed recommendation.
**Notes:** Learner surfaces hide backend mechanics and use standard accessible iOS affordances; host policy remains authoritative.

---

## the agent's Discretion

- Choose exact module/type names, stable identifiers, fixture mechanics, and evidence-schema encoding while preserving all locked scope, privacy, and authority boundaries.

## Deferred Ideas

- Generic sync, generic conflict resolution, device farms, retained media evidence, permanent device CI, Android expansion, background replay, and native confirmation remain out of scope.
