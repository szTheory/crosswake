# Phase 50: Doctor Publish and Readiness Checks - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-05-31
**Phase:** 50-Doctor Publish and Readiness Checks
**Areas discussed:** publish-check scope, readiness finding derivation, output and CI contract, guardrails and remediations, ecosystem/DX synthesis

---

## Initial Selection

| Option | Description | Selected |
|--------|-------------|----------|
| All areas | Discuss publish-check scope, readiness findings, machine/human output, and anti-overclaim guardrails. | yes |
| Publish-check scope | Focus on what `--check-publish` verifies across Hex, changelog, docs/support parity, and proof posture. | included |
| Readiness findings | Focus on companion/provider/auth/notification/native-shell severities and remediations. | included |
| Output and CI contract | Focus on JSON/human shape, exit status, thresholds, and CI usage. | included |
| Guardrails and remediations | Focus on actionable hints, guide anchors, and anti-overclaim posture. | included |

**User's choice:** Discuss/consider all areas. Use subagent research for each, compare pros/cons/tradeoffs, include examples and ecosystem lessons, emphasize idiomatic Elixir/Phoenix/Plug/Ecto, great DX, and synthesize one cohesive recommendation so the user does not need to choose routine architecture details.

**Notes:** User specifically requested the `prompts/` corpus be considered where applicable.

---

## Publish-Check Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Strict local contract check | Deterministic, no network flake, strong hermetic CI fit, but cannot confirm live Hex parity. | |
| Hybrid local plus advisory remote checks | Local checks stay authoritative; remote Hex/public checks can surface real release drift without weakening hermetic CI. | yes |
| Release-pipeline-driven check | Strong provenance but couples local doctor too tightly to CI internals. | |

**User's choice:** Agent recommendation accepted by one-shot instruction.

**Notes:** Lock `--check-publish` to authoritative local checks for metadata, changelog, docs/support parity, proof posture, and verification-required surfaces. Remote checks, if added, must be advisory or explicitly enabled.

---

## Readiness Finding Derivation

| Option | Description | Selected |
|--------|-------------|----------|
| Direct doctor checks only | Fast and simple, but duplicates Phase 49 inspection/support truth. | |
| Consume inspection only | Reuses route-authoritative truth, but may overfit doctor to inspection schema. | |
| Support-matrix-only derivation | Canonical vocabulary, but too coarse for route-specific companion/auth/notification findings. | |
| Hybrid layered derivation | Compose inspection route truth, support matrix policy truth, and doctor publish/environment checks. | yes |

**User's choice:** Agent recommendation accepted by one-shot instruction.

**Notes:** Required categories: `publish_parity`, `companion_dependency_health`, `provider_adapter_readiness`, `notification_token_readiness`, `auth_session_predicate_readiness`, `native_shell_verification_gap`, `docs_support_parity`, and `proof_posture`.

---

## Output And CI Contract

| Option | Description | Selected |
|--------|-------------|----------|
| Extend doctor JSON with `publish_readiness` | Preserves one command and one machine-readable doctor contract. | yes |
| Add `--fail-on` threshold | Useful for merge-blocking vs advisory lanes if scoped. | yes, planner discretion |
| Add CI annotations/checkstyle output | Good PR UX, but should remain a rendering of canonical JSON/findings. | optional |
| Split into separate publish command | Clear but fragments DX and duplicates plumbing. | |

**User's choice:** Agent recommendation accepted by one-shot instruction.

**Notes:** JSON should include `publish_readiness.status`, `summary`, and `checks[]` with severity, result, blocking, hint, docs reference, proof class, rebuild requirement, claim scope, and details.

---

## Guardrails And Remediations

| Option | Description | Selected |
|--------|-------------|----------|
| Terse codes only | Stable for machines, weak first-run DX. | |
| Guide-linked actionable hints | Strong Elixir OSS DX, but needs docs-contract anchors. | yes |
| Generated remediation tables | Useful if strictly derived, risky if it becomes duplicate authority. | partial |
| CI annotations and summaries | Good PR feedback if not a second contract. | optional |
| Docs-contract-coupled guardrails | Strongest anti-overclaim posture. | yes |

**User's choice:** Agent recommendation accepted by one-shot instruction.

**Notes:** Findings should emit stable code/id, severity, subject, remediation, guide anchor, proof class, rebuild requirement, and claim scope. They must explicitly state deferred StoreKit/Play Billing, Sigra, Chimeway, and shell-package boundaries.

---

## Ecosystem/DX Synthesis

| Option | Description | Selected |
|--------|-------------|----------|
| Doctor as findings engine composed from inspection plus publish checks | Idiomatic Mix/Phoenix DX, preserves Phase 49 route truth, keeps one diagnostic command. | yes |
| Expand doctor monolith directly | Fast, but increases drift and readability risks. | |
| Separate readiness command | Clear but too much command surface for v3.6. | |

**User's choice:** Agent recommendation accepted by one-shot instruction.

**Notes:** Ecosystem lessons applied: Mix tasks should be boring and explicit; Django-style checks show stable ids/severity/hints; Terraform shows versioned JSON separate from human output; Kubernetes conditions warn against global boolean health; npm/GitHub Actions show useful but dangerous threshold/annotation patterns.

---

## the agent's Discretion

- Exact module layout for publish/readiness checks.
- Exact public check code names.
- Whether `--fail-on` lands in Phase 50 or is deferred.
- Whether remote Hex checks land in Phase 50, provided they remain advisory unless deterministic.
- Whether GitHub annotations land now or in Phase 52.

## Deferred Ideas

- Remote Hex/public URL checks can be deferred if deterministic behavior is not practical.
- GitHub annotations/job summaries can defer to Phase 52.
- Support-matrix/rebuild guide expansion belongs to Phase 51.
- Full docs-contract/proof locking belongs to Phase 52.
- StoreKit, Play Billing, full Sigra machinery, Chimeway delivery, and standalone shell package claims remain deferred to later milestones.
