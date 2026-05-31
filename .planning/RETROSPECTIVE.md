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

## Milestone: v3.4 Commerce Archetype Proof

**Shipped:** 2026-05-29
**Phases:** 5 (33, 34, 35, 36, 37)
**Plans:** 8

### What Was Built

- Three `:subscription_default` commerce corridor routes in `examples/phoenix_host` with canonical `crosswake.commerce` DSL, gated by the new `phase34-proof.yml` hermetic/advisory two-job CI split.
- `CrosswakeExample.Commerce.MockStorefront` — a pure-Elixir, provider-neutral evidence emitter (`simulate_purchase/2`, `simulate_restore/2`) documented as the StoreKit/Play Billing swap target, with stable `entry_id`-derived provider identity (not transient `correlation_id`).
- A four-state `PaywallEntryLive` (fail-closed `:stale` mount) wired through MockBackend + CorridorController + PubSub to the real `ingest_evidence/2` → `project_snapshot/2` → `derived_state/1` pipeline.
- A single merge-blocking hermetic proof (`phase34_paywall_corridor_proof_test.exs`) asserting all four states, the `:pending` → `:granted` transition, the mock-boundary fence, and a hermeticity self-scan guard.
- A docs-contract-locked Paywall Corridor Walkthrough in `guides/commerce.md`, anchored to shipped exports via `function_exported?/3`.

### What Worked

- **Reuse-not-rebuild guardrail held end-to-end** — the mock lane consumed the shipped v3.2 `Crosswake.Commerce.Contracts`/`Reconciliation` and the Phase-21 reconciliation modules with zero forks and zero new dependencies; the milestone audit confirmed 7/7 integration connections wired with no duplicate contract definitions.
- **One shared verify→project→derive core for proof and example** — `MockBackend.build_verified_snapshot/2` is exercised identically by `PaywallEntryLive` and the hermetic proof, so the proof tests the real construction path, not a parallel one.
- **Mocked-archetype-before-adapters sequencing** — proving the full purchase→reconciliation→entitlement→UI lane with `provider: "mock"` and a labeled swap target made the corridor copy-able now while deferring StoreKit/Play Billing risk to v3.6.
- **Docs-contract lock via `function_exported?/3`** — binding the guide walkthrough to live exports means renaming/removing an anchored example function breaks the guide test, keeping documentation honest by construction.
- **Reused hermetic-vs-advisory CI pattern** — `phase34-proof.yml` mirrored `phase23-proof.yml` directly, so the proof posture was established in Phase 33 before any proof code existed.

### What Was Inefficient

- **SUMMARY one-liner hygiene** — several phase SUMMARYs had null or literal `One-liner:` frontmatter, so the CLI-generated MILESTONES.md entry came through with placeholder bullets and had to be rewritten by hand at close.
- **Nyquist VALIDATION ledger left in draft** — phases 34–37 carried pre-execution VALIDATION.md files never finalized to `nyquist_compliant: true`; functionally covered (every phase's tests pass and VERIFICATION.md passed), but the bookkeeping is a deferred cleanup.
- **Forward-reference CSRF gap** — the P33 forward-referenced `purchase_intent`/`restore_intent` POST routes landed in a `:browser` pipeline without CSRF protection; acceptable for an example host but flagged as INFO tech-debt if the example is ever hardened toward a template.

### Patterns Established

- **Mocked archetype proof lane** — for a new product archetype, ship a pure-language mock that consumes the canonical contracts, a UI that renders the real derived state, a merge-blocking hermetic proof over the real pipeline, and a docs-contract-locked walkthrough — before any provider/vendor SDK code.
- **Provider-vocabulary fence as a test** — a source-scan test asserting forbidden provider tokens (`storekit`, `play_billing`, `revenuecat`) never appear in the mock keeps "provider-neutral" a runtime invariant, not a review convention.
- **Fail-closed UI mount** — initialize entitlement-reflecting UI to the least-privileged state (`:stale`) on mount and transition only via the authoritative message path.

### Key Lessons

- **Author SUMMARY one-liners at phase close** — the milestone-complete CLI extracts them verbatim; null/placeholder one-liners surface directly in MILESTONES.md and force manual rework.
- **A mock that shares the real core is a proof, not a stub** — routing the example and the hermetic proof through the same `build_verified_snapshot/2` made the corridor genuinely copy-able and the proof genuinely load-bearing.
- **Establish proof posture before proof code** — declaring the CI split and promotion_path in the first phase (33) meant every subsequent PR was gated correctly as it landed.

### Cost Observations

- **Session shape:** Single-day milestone (2026-05-29), executed immediately after v3.3's hex publish on the same day.
- **Zero shipped-library churn:** v3.4 added example-host code, one proof test, and docs only — no `lib/crosswake/` changes — keeping the published `crosswake 0.1.0` surface stable while proving the archetype.
- **Tooling friction:** milestone-close CLI output needed manual cleanup (MILESTONES.md placeholder bullets, STATE.md), but archival of ROADMAP/REQUIREMENTS/AUDIT worked.

## Milestone: v3.5 First-Party Companions

**Shipped:** 2026-05-31
**Phases:** 10 (38-47)
**Plans:** 22

### What Was Built

- A shared `Crosswake.Companion` behaviour with six callbacks, typed state, fail-closed optional dependency diagnostics, and companion telemetry.
- Rulestead route gating across DSL, manifest binding, runtime local-snapshot evaluation, `:gate_denied`/`:kill_switch_active` denials, doctor/support truth, hermetic/advisory proof, and guide coverage.
- Rindle media contracts and reconciliation vocabulary, plus a pure-Elixir mock media lane proving stable idempotency and backend-owned availability without an external SDK.
- Sigra contract-only auth context with backend-only authority, route auth predicates, fail-closed `:step_up_required` denials, and doctor/support truth without handoff/passkey/OAuth machinery.
- A canonical `guides/companions.md` guide parity-locked to live support matrix, denial vocabulary, and doctor finding truth.

### What Worked

- **In-tree before package extraction** — keeping Rulestead, Rindle, and Sigra contract surfaces in core let the seam pattern harden before taking on cross-package compatibility ranges.
- **Multiple companion shapes proved the seam** — route flags, media evidence, and auth contracts stressed different authority boundaries while reusing the same fail-closed companion posture.
- **Docs-contract parity became semantic** — Phase 47 checked the guide against live support/doctor/denial surfaces rather than relying on string-only prose anchors.
- **Hermetic/advisory split carried cleanly** — Rulestead and Rindle both kept optional dependencies out of merge-blocking truth while preserving dependency-present advisory paths.

### What Was Inefficient

- **Audit artifact parity lagged behavior** — Phase 44 had passing contract/reconciliation tests and SUMMARY frontmatter but no `44-VERIFICATION.md`, so the milestone audit initially had to fail closed until the verification ledger was reconstructed.
- **Roadmap status drifted for Phase 43** — Phase 43 had summaries and verification evidence but remained unchecked in `ROADMAP.md`, showing that roadmap parity needs the same closure discipline as SUMMARY frontmatter.
- **Nyquist validation ledgers remain uneven** — several v3.5 validation files stayed draft/non-Nyquist even though phase verification and tests passed.

### Patterns Established

- **Companion seam pattern** — behaviour + state + optional dependency validation + route-local restrictions + doctor/support truth + hermetic/advisory proof is now the default shape for first-party companions.
- **Backend-authority lane discipline** — Rindle media and Sigra auth both treat device/client output as evidence only until backend contracts explicitly promote it.
- **Contract-only auth milestone shape** — high-blast-radius identity work can ship useful route-policy truth without pulling in handoff, ceremony, passkeys, OAuth, or token rotation.

### Key Lessons

- **Every completed phase needs a verification report before milestone close** — behavior can be green and still fail the audit if the third traceability source is missing.
- **Close thread artifacts when their milestone ships** — the open `companion-seam-pattern` thread was real historical context, but leaving it open blocked milestone close.
- **Companion docs should cite live truth surfaces** — using exported support/doctor/denial truth in docs tests makes guide drift a compile-time problem.

### Cost Observations

- **Session shape:** Two-day milestone (2026-05-30 to 2026-05-31) with 10 phases and 22 plans.
- **Verification:** Milestone audit passed 15/15 requirements; Phase 44 focused proof passed 27 tests; Phase 47 guide/proof passed 12 tests; hermetic suite passed 455 tests with 44 excluded.
- **Closeout friction:** The close workflow needed manual remediation for a missing Phase 44 verification file, stale Phase 43 roadmap status, one open thread, and a resolved UAT marker still in the active phase tree.

## Cross-Milestone Trends

| Trend | Evidence | Implication |
|-------|----------|-------------|
| Proof truth is part of product surface | v3.1 closed once Phase 18 Proof passed; v3.2 closed once Phase 23 commerce proof lane + parity test were both merge-blocking | Future milestones should define proof lanes before final execution slices, and parity tests for any new traceability convention must ship with the convention |
| Runtime ownership remains the strongest guardrail | v3.1 added capabilities without generic plugin semantics; v3.2 added commerce contracts without provider adapter code in core | Continue rejecting high-frequency bridge surfaces and provider-specific code in core unless they move to native screens, offline islands, or companion/adapter milestones |
| Environment-sensitive native proof needs lane design | Android JVM proof was fast after splitting from emulator proof; v3.2 commerce proof split hermetic merge-blocking from scheduled-only advisory provider/storefront/device checks | Keep merge-blocking and advisory proof lanes separate, and surface the advisory-to-merge-blocking promotion path inside runtime diagnostics, not only CI YAML |
| Audit-driven decomposition prevents oversized phases | v3.2 Phase 22 was decomposed into 23 + 24 before execution after the milestone audit flagged scope risk | Run `/gsd:audit-milestone` early in milestone arcs to surface decomposition candidates before plans are written |
| Re-audits trump rewriting | v3.2 closure required three re-audit appends (Phase 24, milestone closure, Phase 25) rather than rewriting the original `gaps_found` audit | Treat audit files as append-only ledgers — `gaps_found` followed by closure re-audits beats overwriting the original verdict |
| Prove archetypes with mocks that share the real core | v3.4 shipped a copy-able paywall corridor with a pure-Elixir `MockStorefront` and a merge-blocking hermetic proof, both routed through the real reconciliation/projection pipeline, with zero provider-SDK code | When opening a new product archetype, mock the provider boundary only — keep the contract, reconciliation, and UI-derivation path real and proof-locked, deferring vendor SDK integration to a dedicated adapter milestone |
| CLI-generated milestone artifacts need author-time input quality | v3.4's milestone-complete CLI emitted placeholder `One-liner:` bullets into MILESTONES.md because phase SUMMARYs lacked clean one-liners | Author SUMMARY one-liners at phase close; treat machine-extracted milestone summaries as drafts to verify, not final copy |
| Companion seams need backend-authority discipline | v3.5 proved Rulestead, Rindle, and Sigra as typed, fail-closed companion surfaces while keeping device media/auth evidence non-authoritative | Future companions should start with explicit authority/evidence lanes and route-local restrictions before adding provider or native machinery |
| Audit artifacts are part of completion truth | v3.5 behavior was green, but closeout initially failed on missing Phase 44 verification, stale Phase 43 roadmap status, an open thread, and active-tree resolved UAT residue | Treat verification reports, thread closure, roadmap parity, and artifact cleanup as required product work, not administrative cleanup |
