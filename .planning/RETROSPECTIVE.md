# Crosswake Retrospective

## Milestone: v3.1 Native Capabilities and Bridge Expansion

**Shipped:** 2026-05-27
**Phases:** 4
**Plans:** 16

### What Was Built

- Base bounded bridge families for `haptics`, `share`, and `app_info`.
- System-context support for deep-link activation truth and read-only `permissions.status`.
- User-prompted `notification_token` and transfer-bound `file_picker` capability families.
- Family-first policy validation, doctor posture, and support-matrix proof status for v3.1 capability truth.
- A dedicated `Phase 18 Proof` GitHub Actions lane that passed Elixir proof slices, checked-in iOS shell proof, and Android JVM BridgeChannel proof.

### What Worked

- Keeping bridge commands semantic and low-frequency preserved Crosswake's route-ownership thesis while still reducing adopter native glue.
- Splitting Phase 17 by ownership surface let Elixir contracts settle before iOS and Android shell implementation details landed.
- Moving Android JVM proof into CI was the right closure path for this workstation, which still lacks a local Java runtime.

### What Was Inefficient

- The first Phase 18 CI workflow mixed JVM proof with emulator-backed connected proof, which made the lane too slow and opaque for iteration.
- The live `REQUIREMENTS.md` had drifted from milestone reality, so v3.1 closeout had to preserve v3.0 requirements separately and reconstruct v3.1 requirements from roadmap/context truth.

### Patterns Established

- Use separate evidence classes for proof lanes: fast contract/JVM proof for merge-blocking truth, emulator or device checks only where they prove a distinct runtime claim.
- Keep support matrix truth split into baseline platform support, repository proof status, and capability-family posture.
- Treat provider/token and file-picker flows as evidence/staging seams, not device-owned backend authority.

### Key Lessons

- CI timeout budgets should match iteration needs; long native lanes should expose useful progress or be split before they become blockers.
- Human-device UAT should remain explicit proof debt rather than being silently converted into repository support claims.
- Milestone requirements need to be rotated at milestone start so closeout does not have to infer scope from roadmap artifacts.

## Milestone: v3.2 Commerce And Entitlement Seams

**Shipped:** 2026-05-27
**Phases:** 6 executed (19, 20, 21, 23, 24, 25) + 1 decomposed (22 → 23+24)
**Plans:** 18

### What Was Built

- Provider-neutral commerce route corridors with canonical `commerce.corridor.*` denial vocabulary and fail-closed activation enforcement.
- Entitlement snapshot lane taxonomy separating authority, access, reconciliation, freshness, effective window, and evidence metadata — with non-authoritative reconciliation evidence ingestion locked at runtime boundaries.
- Minimal Phoenix-owned reconciliation inbox/projection example with provider-aware idempotency (`event_key` / `subject_key`) and deterministic precedence (`stale`, `pending`, `denied`, `granted`).
- Doctor `commerce_summary` surface with `proof_class` labeled findings derived from canonical support-matrix metadata; layered reviewer/storefront guides anchored to `SupportMatrix.commerce_corridors/0` with byte-identical canonical-source assertions.
- Hermetic 14-test merge-blocking commerce proof lane + scheduled-only advisory provider lane (`phase23-proof.yml`) with `promotion_path` detail visible at runtime in doctor output.
- Machine-enforced SUMMARY frontmatter parity (`requirements-completed:`) wired into the merge-blocking CI gate, hardened in Phase 25 with presence assertion (WR-01) and malformed-shape loud-fail (WR-02).

### What Worked

- **Audit-driven decomposition** — the v3.2 milestone audit caught that Phase 22 was an oversized "support + review + proof" container; splitting into Phase 23 (runtime closure) and Phase 24 (traceability hardening) before execution kept verification scopes sharp and shipped both clean.
- **Canonical vocabulary as integration substrate** — using one `commerce.corridor.*` taxonomy across route policy, manifest, doctor, support matrix, and guides meant every consumer reads the same data, and merge-blocking parity tests catch drift mechanically.
- **Two-job CI split with runtime promotion-path visibility** — gating merges on hermetic proof while keeping the advisory lane conditional (`if: schedule || workflow_dispatch` + `continue-on-error: true`) preserved iteration speed; surfacing the four-condition advisory-to-merge-blocking promotion path inside doctor output (not only YAML comments) made the gate legible to adopters.
- **Tech-debt closure as its own phase** — Phase 25 closed the two non-blocking items flagged in the milestone-closure re-audit (Phase 20 verification text + parity test WR-01/02) in a single atomic commit, preventing them from sliding into the next milestone.
- **Re-audits as first-class artifacts** — appending re-audit sections (RECN normalization, milestone closure, Phase 25 tech-debt) to `v3.2-MILESTONE-AUDIT.md` rather than rewriting history made the gap-closure trajectory readable end-to-end.

### What Was Inefficient

- **Initial RECN traceability gap was purely artifact-shape** — Phase 21 verification was green and behavior was correct, but `requirements:` vs canonical `requirements-completed:` key mismatch flagged RECN-01/02/03 as `partial` in the audit. Two phases of work (24 + 25) closed what should have been a single Phase 21 author-time convention check.
- **Phase 22 was originally over-scoped** — bundling support truth, reviewer playbooks, and proof posture in one phase meant the audit had to flag and decompose it before execution. Pre-execution decomposition worked, but scope-fence rubrics at phase-creation time would have caught it sooner.
- **Manifest schema versioning still implicit** — corridor fields were added additively under schema `1.0.0` with no version bump or compat declaration; future provider-adapter milestones may need to formalize the schema-evolution contract.

### Patterns Established

- **Atomic test+SUMMARY commits for new traceability conventions** — when a parity test asserts a SUMMARY shape, the test edit and the first-conforming SUMMARYs must ride in the same commit, or the test will fail against its own creating PR.
- **Provider-neutrality fences are scoped, not global** — the v3.2 fence applies to canonical data (`SupportMatrix.commerce_corridors/0`) and the canonical reconciliation flow subsection of guides, but reviewer playbooks may name providers in explicitly labeled advisory callouts. Fencing the full guide would over-constrain prose.
- **`requires`/`provides` SUMMARY edges as the planning graph** — Phase 23 plans declared explicit `requires:` from earlier-plan `provides:` outputs, making the wave structure machine-readable and the cross-phase contract enforceable.
- **Hermetic proof self-test** — the Phase 23 proof lane reads its own source via `__ENV__.file` and refutes non-hermetic call shapes (`System.cmd`, `Port.open`, `:gen_tcp.X`, HTTP clients, `Code.require_file` on non-fixture paths) via regex. Hermeticity becomes a runtime invariant, not a code-review heuristic.

### Key Lessons

- **Audit re-runs are cheap and load-bearing** — three re-audit sections (RECN normalization, milestone closure, Phase 25 tech-debt) on the same `v3.2-MILESTONE-AUDIT.md` made the closure trajectory legible and let `gaps_found → satisfied` happen incrementally without rewriting history.
- **Tech-debt phase shape exists and works** — Phase 25 declared `requirements-completed: []` (the canonical zero-requirement tech-debt shape) and closed two follow-up items from the milestone-closure re-audit in a single atomic commit. Future milestones should reach for this shape rather than punting follow-ups to backlog.
- **One canonical denial vocabulary scales further than expected** — `commerce.corridor.*` denials are read by route policy, doctor, support matrix, guides, and tests without per-consumer translation layers. The taxonomy investment pays back across every surface.
- **Artifact-shape consistency is a real failure mode** — RECN-01/02/03 spent a phase as `partial` purely because the SUMMARY frontmatter used `requirements:` instead of `requirements-completed:`. Machine-readable conventions need machine-enforceable parity tests at the moment of convention adoption, not later.

### Cost Observations

- **Session shape:** Single-day intensive arc (2026-05-21 → 2026-05-27, with the bulk of execution on 2026-05-27). 121 commits over the milestone window.
- **Phase decomposition saved rework:** the audit-driven Phase 22 → 23+24 split was set up in planning context and required no executor backtrack.
- **Tech-debt phase ran fast:** Phase 25 closed both follow-up items in 2 atomic commits (`4e0ed68` doc-fix + `5ca1306` test+SUMMARY) with zero `lib/` or `examples/` changes; scope-fence held end-to-end.

## Cross-Milestone Trends

| Trend | Evidence | Implication |
|-------|----------|-------------|
| Proof truth is part of product surface | v3.1 closed once Phase 18 Proof passed; v3.2 closed once Phase 23 commerce proof lane + parity test were both merge-blocking | Future milestones should define proof lanes before final execution slices, and parity tests for any new traceability convention must ship with the convention |
| Runtime ownership remains the strongest guardrail | v3.1 added capabilities without generic plugin semantics; v3.2 added commerce contracts without provider adapter code in core | Continue rejecting high-frequency bridge surfaces and provider-specific code in core unless they move to native screens, offline islands, or companion/adapter milestones |
| Environment-sensitive native proof needs lane design | Android JVM proof was fast after splitting from emulator proof; v3.2 commerce proof split hermetic merge-blocking from scheduled-only advisory provider/storefront/device checks | Keep merge-blocking and advisory proof lanes separate, and surface the advisory-to-merge-blocking promotion path inside runtime diagnostics, not only CI YAML |
| Audit-driven decomposition prevents oversized phases | v3.2 Phase 22 was decomposed into 23 + 24 before execution after the milestone audit flagged scope risk | Run `/gsd:audit-milestone` early in milestone arcs to surface decomposition candidates before plans are written |
| Re-audits trump rewriting | v3.2 closure required three re-audit appends (Phase 24, milestone closure, Phase 25) rather than rewriting the original `gaps_found` audit | Treat audit files as append-only ledgers — `gaps_found` followed by closure re-audits beats overwriting the original verdict |
