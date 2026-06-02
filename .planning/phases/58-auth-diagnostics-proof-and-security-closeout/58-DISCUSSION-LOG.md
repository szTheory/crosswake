# Phase 58: Auth Diagnostics, Proof, And Security Closeout - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-06-02
**Phase:** 58-auth-diagnostics-proof-and-security-closeout
**Areas discussed:** Stable auth telemetry contract, support/doctor/operator truth, proof lane posture, security closeout model

---

## Stable Auth Telemetry Contract

| Option | Description | Selected |
|--------|-------------|----------|
| Fine-grained event per protocol detail | Provider/protocol-specific event names such as oauth state mismatch or passkey origin mismatch. Easy filtering, but explodes namespace and duplicates denial codes. | |
| One generic auth event | A single `[:crosswake, :auth, :event]` event with all classification in metadata. Small surface, but too opaque for Phoenix Telemetry users. | |
| Current flow/lifecycle registry | Stable session, denial, handoff, step-up, and return lifecycle events with low-cardinality metadata and forbidden secret keys. | yes |
| Audit-first telemetry | Emit audit facts through telemetry. Rich if captured, but wrong substrate for audit/replay/authority. | |
| OpenTelemetry-first clone | Bake OTel semantic conventions into core. Useful future adapter target, but premature for Sigra core. | |

**User's choice:** User asked to discuss/consider all areas with subagent research and one-shot recommendations.
**Recommendation locked:** Keep `Crosswake.Companions.Sigra.Telemetry` as the stable registry and sanitizer. Telemetry is diagnostic evidence only, not audit, lifecycle, replay, or authority truth.

---

## Support Doctor Operator Truth

| Option | Description | Selected |
|--------|-------------|----------|
| Full Sigra shipped only | Collapse support truth into one broad shipped claim. Simple but overclaims provider/device/native auth support. | |
| Verification-required only | Treat all Sigra auth routes as unshipped because hosts still verify deployment. Conservative but hides real shipped contract machinery. | |
| Contract/advisory split | Contract proof and host/provider/device readiness are separate axes. | yes |
| Provider/device capability matrix | Detailed OAuth provider/passkey/device rows. Useful after provider/device promotion, premature for Phase 58. | |

**User's choice:** User asked for all areas and cohesive recommendations.
**Recommendation locked:** Use the two-axis truth model everywhere: full Sigra contract machinery is shipped and merge-blocking proven; host readiness is verification-required; provider/device proof is advisory until promotion criteria pass.

---

## Proof Lane Posture

| Option | Description | Selected |
|--------|-------------|----------|
| One giant full suite | Make all ExUnit plus provider/device auth proof merge-blocking. High apparent confidence but flaky and overclaims support. | |
| Layered hermetic merge-blocking plus advisory provider/device | Required deterministic closeout proof plus scheduled/manual advisory provider/device lane. | yes |
| Mostly manual/security review | Manual STRIDE and ad hoc checks. Useful judgment, but weak regression and docs-contract protection. | |

**User's choice:** User asked for all areas and subagent-backed recommendations.
**Recommendation locked:** Keep `phase58-proof.yml` layered: hermetic merge-blocking auth closeout proof and advisory provider/device proof with `continue-on-error`. Advisory proof cannot promote support truth by itself.

---

## Security Closeout Model

| Option | Description | Selected |
|--------|-------------|----------|
| Lightweight checklist | Fast and easy to verify mechanically, but too close to attestation. | |
| STRIDE per surface | Good baseline, but can become generic if it only fills boxes. | |
| Bounded adversarial STRIDE plus remediation ledger | Surface-specific adversarial scenarios, controls, evidence refs, residual risk, and disposition. | yes |

**User's choice:** User asked to consider all areas deeply and produce one coherent set of recommendations.
**Recommendation locked:** Treat `58-SECURITY.md` as bounded adversarial STRIDE plus remediation ledger, while preserving the required section set that proof and verifier artifacts already expect.

---

## the agent's Discretion

- Exact guide/doctor/operator wording can be refined by planners if the two-axis truth model remains explicit.
- Exact telemetry helper APIs can be refined if event names, allowlisted metadata, forbidden metadata, and evidence-only posture remain locked.
- Exact security ledger length is planner discretion; keep it bounded, concrete, and evidence-backed.
- CI workflow parity hardening is planner discretion, with the caveat that provider/device proof must remain advisory unless promoted by explicit criteria.

## Deferred Ideas

- Provider/device proof promotion.
- Provider-specific OAuth templates.
- Passkey SDK wrappers.
- Native auth UI.
- Refresh-token helper/orchestration support.
- OpenTelemetry adapter mapping from the Sigra telemetry registry.
