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

## Milestone: v3.7 Commerce Provider Adapters

**Shipped:** 2026-06-01
**Phases:** 2 (48 and 48.1)
**Plans:** 7

### What Was Built

- First-party StoreKit and Play Billing companion seams that normalize provider evidence into `ReconciliationEvidence` while keeping entitlement authority backend-owned.
- Shared provider evidence and purchase/restore result contracts with closed provider/event/status vocabulary and explicit subject/event identity separation.
- Example-host paywall storefront adapter behaviour with mock-default behavior and explicit StoreKit/Play Billing provider facade swap targets.
- Support matrix, operator inspection, doctor readiness, commerce guidance, changelog posture, and proof fixtures that distinguish shipped provider seams from advisory provider/device proof.
- A merge-blocking hermetic Phase 48 proof lane plus advisory StoreKit/Play Billing provider visibility wiring.

### What Worked

- **Backend-authority fence held under real provider pressure** — StoreKit original transaction lineage and Play Billing purchase-token lineage feed reconciliation evidence, but neither path can grant entitlement authority without backend projection.
- **Mock-default plus provider swap target was the right adoption shape** — the example host remains runnable without provider SDKs while exposing a compiler-visible seam for StoreKit/Play Billing evidence emitters.
- **Audit-driven closure found a real integration gap** — Phase 48.1 closed the provider facade/paywall contract mismatch before milestone close rather than carrying a misleading "adapter shipped" claim.
- **Readiness truth stayed multi-axis** — support/doctor/operator outputs now say provider seams are shipped while provider sandbox/device proof remains advisory until explicit promotion criteria pass.

### What Was Inefficient

- **Milestone analyzer under-counted inserted scope** — the closeout SDK saw only Phase 48.1 in live roadmap analysis and generated `1 phase, 1 plan`; the human archive had to correct v3.7 to 2 phases and 7 plans.
- **Provider walkthrough prose is split** — the mock walkthrough remains the default guide path and provider swap-target guidance lives separately. This is accurate but less ergonomic for operators scanning for the adapter path.
- **Advisory provider lane is still scaffolded** — the workflow has credential gates and notices, not real StoreKit/Play Billing sandbox/device scripts yet. That matches ADPT-03 but should remain visible.

### Patterns Established

- **Evidence-only provider adapter seam** — provider SDK output should normalize to closed Crosswake evidence contracts and never bypass Phoenix-owned reconciliation.
- **Behaviour-backed example swap targets** — adopter examples should expose explicit behaviours for provider facades instead of encoding provider selection in LiveView params or route context.
- **Provider proof promotion criteria as product truth** — advisory lanes need runtime/readiness visibility and explicit promotion requirements, not only CI comments.

### Key Lessons

- **Run milestone audit before trusting completion labels** — the first v3.7 audit found the exact ADPT-01/ADPT-02 paywall swap-target blocker; closure was small but materially changed the shipped claim.
- **Inserted phases need closeout-aware stats** — decimal phases can fall outside naive roadmap analysis, so milestone closeout should verify scope against archived phase directories and audit files.
- **Provider adapter work should preserve mock ergonomics** — first-party adapters should make the real path available without making provider credentials mandatory for the default proof lane.

### Cost Observations

- **Session shape:** Single-day milestone on 2026-06-01, with Phase 48 plus one inserted closure phase.
- **Verification:** Milestone audit passed 3/3 requirements, 2/2 phases, 10/10 integration checks, and 4/4 E2E flows; Phase 48.1 focused proof ran 69 tests with 0 failures.
- **Closeout friction:** The close workflow needed manual correction for generated stats and roadmap collapse after the archive step.

## Milestone: v3.8 Full Sigra Auth and Session Machinery

**Shipped:** 2026-06-02
**Phases:** 5 (54-58)
**Plans:** 19

### What Was Built

- Backend-owned Sigra session authority projection with explicit state, assurance, freshness, expiry, remembered-session, revocation/version, and fail-closed route-gate semantics.
- Single-use session handoff ticket contracts and example-host server-record proof for issue, redemption, replay, revocation, expiry, audit evidence, and host session-renewal instructions.
- Server-owned step-up intent machinery with shared Plug/controller and LiveView ceremony semantics, one-time consume/cancel/revoke paths, and validated Crosswake return targets.
- Provider-neutral OAuth, passkey, and native auth-return route seams with evidence-only envelopes, replay/expiry checks, host-owned attempt records, and backend authority projection boundaries.
- Auth telemetry, denial taxonomy, doctor/support/operator truth, guides, fixtures, security closeout, and CI parity that distinguish shipped Sigra machinery from advisory provider/device proof.

### What Worked

- **Backend-owned authority held across every auth surface** — session state, handoff tickets, step-up outcomes, and auth-return events all project through backend validation instead of granting authority from shell/native/provider evidence.
- **One evaluator/denial vocabulary scaled cleanly** — route gates, handoff, step-up, auth returns, support truth, and docs all use stable auth denial/subcode semantics with sanitized shell-safe details.
- **Proof lane stayed product-shaped** — the Phase 58 proof covers contracts, route gates, replay/expiry/revocation, step-up returns, denial sanitization, telemetry/docs parity, and security-sensitive non-claims without requiring provider/device services.
- **Security closeout became machine-checkable** — the STRIDE ledger and `mix closeout.verify --security-only` make blocking auth findings explicit instead of relying on prose review.

### What Was Inefficient

- **Validation ledgers lagged behind proof** — requirements, phase verification, integration, and E2E flows passed, but Nyquist VALIDATION.md files for Phases 54-58 stayed stale/partial and kept the audit at `tech_debt`.
- **Closeout still needs manual archive polish** — the SDK created correct base archives, but ROADMAP, PROJECT, STATE, MILESTONES, and retrospective edits still needed human/agent judgment.
- **Provider/device auth proof remains intentionally advisory** — this is the right claim boundary, but it means future provider-specific OAuth/passkey work must create separate promotion criteria before support claims widen.

### Patterns Established

- **Evidence-only auth-return seam** — OAuth callbacks, passkey assertions, native deep links, and bridge events should validate as evidence and only promote authority through backend-owned session projection.
- **Shared ceremony core for Plug and LiveView** — auth flows that span controllers and LiveView should route through one core evaluator/intent lifecycle so fail-closed behavior and return validation stay consistent.
- **Security ledger as closeout input** — security-sensitive milestones should produce a dedicated closeout artifact that a deterministic verifier can check before archive.

### Key Lessons

- **Validation bookkeeping should close during phase execution** — stale VALIDATION.md ledgers create milestone-close debt even when behavior and proof are green.
- **Auth support truth needs two axes** — Crosswake should separately report shipped contract machinery and advisory provider/device evidence, because collapsing them would overstate production support.
- **Backend authority language must be repeated in every adopter-facing surface** — guides, support matrices, denials, telemetry, and examples all need to reinforce that client evidence cannot grant session authority directly.

### Cost Observations

- **Session shape:** One-day milestone on 2026-06-02, closing five phases and 19 plans.
- **Verification:** Milestone audit satisfied 16/16 requirements, 5/5 phases, 10/10 integration checks, and 5/5 E2E flows; focused proof ran 115 tests with 0 failures.
- **Closeout friction:** Nyquist ledger cleanup remains deferred tech debt even though the proof lane and milestone audit evidence are green for requirements and flows.

## Milestone: v3.9 Chimeway Notification Seam

**Shipped:** 2026-06-03
**Phases:** 5 (59-63)
**Plans:** 17

### What Was Built

- First-party in-tree Chimeway companion contract with provider-neutral notification token evidence and backend-owned token binding records spanning active/rotated/revoked/stale/invalid/permission-denied/environment-mismatched/app-identity-mismatched states.
- Host-owned Phoenix registry path for binding, rotation, logout/session revocation, permission loss, provider invalidation, and staleness pruning via `Ecto.Multi` with safe audit rows and post-commit telemetry.
- Notification-open resolver that routes opens only through manifest-known route ids and `RouteGate` with `activation_source: :notification`, reusing Sigra session authority/step-up and failing closed with stable denial codes.
- Operator-facing truth across doctor, operator inspection, support matrix, fixtures, and guides that separates token-binding/open-routing readiness from APNs/FCM delivery, plus low-cardinality telemetry that forbids raw tokens, payloads, route params, and PII.
- Merge-blocking hermetic proof lane covering the full shipped seam with APNs/FCM device delivery kept advisory under explicit, demotion-aware promotion criteria.

### What Worked

- **RouteGate reuse made OPEN-02 nearly free** — because the resolver delegates to existing `RouteGate.evaluate/4` with `activation_source: :notification`, Sigra session-authority and step-up reuse came with zero duplicated auth logic.
- **Evidence-only discipline held end to end** — `notifications.token.get` and notification taps stayed device evidence; backend binding and RouteGate decide, and no surface implies first-party push delivery.
- **Closeout-as-contract worked** — `v3.9-CLOSEOUT.md` plus `mix closeout.verify` gave a machine-checkable, multi-axis definition of "shipped" instead of prose review.
- **Raw-token redaction was proven, not asserted** — sentinel/source checks and telemetry redaction tests lock the no-raw-token boundary into merge-blocking proof.

### What Was Inefficient

- **Validation ledgers lagged again** — Nyquist VALIDATION.md ledgers for Phases 59/60/62/63 stayed draft and were deferred to Phase 64, repeating the v3.8 closeout-debt pattern.
- **SUMMARY one-liners were thin** — phases 60-63 SUMMARYs lacked clean one-liners, so the CLI-generated MILESTONES.md entry needed manual enrichment (same v3.4 lesson recurring).
- **Stale checkbox/footer drift in REQUIREMENTS.md** — OPEN-02 stayed `[ ]` despite being complete in traceability, and the file carried duplicated-footer cruft that needed manual cleanup at archive time.

### Patterns Established

- **Narrow core hook + companion seam for provider-heavy surfaces** — notification work lived in the Chimeway companion with only a minimal core route-policy/manifest hook, keeping core small while delivering real value.
- **Delegate auth-sensitive activation to the existing route gate** — new activation sources should call `RouteGate` with a typed `activation_source` rather than re-implementing auth/step-up.
- **Ship closeout as a machine-readable contract per milestone** — a frontmatter checklist verified by `closeout.verify` is the right closing gate for support-truth-sensitive milestones.

### Key Lessons

- **Close validation bookkeeping during execution** — v3.8 and now v3.9 both carried deferred Nyquist ledgers into close; this is now a recurring process gap, not a one-off.
- **Author SUMMARY one-liners at phase close** — machine-extracted milestone summaries remain drafts until SUMMARYs carry clean one-liners.
- **A new activation source is cheap when authority already lives in one evaluator** — the payoff of backend-owned RouteGate/Sigra compounds each time a new entry path (notification, deep link, future seams) reuses it.

### Cost Observations

- **Session shape:** One-day milestone on 2026-06-03, closing five phases and 17 plans.
- **Verification:** Closeout passed all support-truth checks via `mix closeout.verify`; merge-blocking hermetic proof covers the shipped seam; validation ledgers deferred with reason to Phase 64.
- **Closeout friction:** Same manual archive-polish and validation-ledger debt as v3.8 — strong candidate for a process fix before v4.0.

## Milestone: v5.0 Standalone Publishable Shell Packages

**Shipped:** 2026-06-06
**Phases:** 4
**Plans:** 11

### What Was Built
- iOS and Android core logic extracted into standalone SPM (`crosswake-shell-core-ios`) and Maven (`crosswake-shell-core-android`) libraries.
- Raw object generation replaced with unified builder and reactive state APIs (`CrosswakeShell.initialize()`, `StateFlow`, `@Published`).
- Thin dependency-driven host projects generation instead of monolithic source copying.
- Hermetic CI pipelines verifying standalone dependencies without breaking archetype proof lanes.

### What Worked
- Extracting the "eject trap" core into standalone packages effectively solves the boilerplate generated by previous iterations.
- Reactive streams mapped cleanly to `StateFlow` and `@Published`, enabling a single-entry initialization.

### What Was Inefficient
- Missing verification evidence in Phase 76 and Phase 77 resulted in validation gaps that had to be accepted as tech debt during closeout.

### Patterns Established
- Binary Core + Hosted Glue pattern as the standard for Crosswake's shell architecture moving forward.

### Key Lessons
- Acknowledging verification gaps as tech debt allows milestone progression but creates risk; ensuring `VERIFICATION.md` exists before completing phases is critical.
- Extracting boilerplate into centralized dependencies removes host friction and enforces tighter delegate boundaries.

### Cost Observations
- Session shape: 25-day milestone spanning from 2026-05-12 to 2026-06-06.
- 96 files modified (+4452, -3497 LOC), heavily focused on generator refactoring and template removal.

## Milestone: v5.1 — Adoption Evidence Demo App

**Shipped:** 2026-06-09
**Phases:** 4 | **Plans:** 8

### What Was Built
- Task 1
- Implemented native Android Flow publishers for connection state and server events, wired cleanly to Compose overlay and toast elements.
- Implemented native iOS Combine publishers for connection state and server events, wired cleanly to SwiftUI overlay and toast elements.
- Implemented RouteDelegate and capability reporting in iOS and Android shell cores with fail-closed native routing

### What Worked
- React streams in Kotlin (`StateFlow`/`SharedFlow`) and Swift (`Combine`) provided excellent ways to bridge the native UI with the shell events without tight coupling.
- Separating the `RouteDelegate` logic into the host app while maintaining a generic core implementation allowed clean testability of routing policies.

### What Was Inefficient
- N/A

### Patterns Established
- Reactive bridge observer pattern for Android/iOS, standardizing how shell state and capabilities reach native UI layers cleanly.
- `RouteDelegate` standard for custom intent mapping.

### Key Lessons
- Moving to dependencies rather than generation makes the host application structure significantly simpler, leaving only native configuration and route delegate mapping.

### Cost Observations
- Fast and focused milestone resolving to end-to-end evidence.

## Milestone: v6.0 — Adoption Evidence Demo App (Flashcard Cohort)

**Shipped:** 2026-06-09
**Phases:** 7 (84-90) | **Plans:** 9

### What Was Built
- `Crosswake.Offline.ContentPack` — strongly-typed pack struct cast at the route-policy boundary and compiled into the root manifest.
- `Crosswake.Sync.EventLog.Entry` + `mix crosswake.gen.sync` — host-owned Ecto schema and Phoenix reconciliation controller with idempotency keys.
- Flashcard demo domain (Decks/Cards/Progress, `binary_id` keys), Phoenix context, migrations, and seeds.
- Online `DeckLive.Index`/`DeckLive.Show` LiveViews under `crosswake_defaults`, plus a vanilla-JS offline study island over IndexedDB, native-shell integration, and Brand Book polish.
- Network-toggling Playwright E2E (mocked) asserting Ecto sync state post-reconnect.

### What Worked
- The offline-island/online-LiveView split mapped cleanly onto the existing route-policy DSL — packs, offline policy, and runtime mode were already expressible per route.
- TDD-first wave-0 plan (86-00) framed the domain before implementation.

### What Was Inefficient
- **The closeout gate was dishonest.** A mocked Playwright flow stood in for the real E2E, so the milestone was marked complete while the demo app did not compile — `OfflineController`/`OfflineHTML` used a non-existent `CrosswakeExampleWeb` macro module and were never wired into the router. Caught and fixed only during this archival's independent verification (`mix test` 15/15).
- Phase summaries/plans for 81-90 were left untracked in git until close — execution didn't commit its own artifacts.
- The 86-00 TDD plan's `flashcards_fixtures.ex` deliverable was never created (the context test was self-contained), leaving a dangling unexecuted plan.

### Patterns Established
- `ContentPack` casting at the policy boundary as the standard for typed offline assets.
- `binary_id` keys for any demo domain destined for offline sync.

### Key Lessons
- A mocked E2E that never builds the real app is worse than no E2E — it manufactures false confidence. Closeout gates must compile and exercise the actual artifact, or be labeled advisory.
- Run `mix compile`/`mix test` against the example host as a hard gate before marking an adoption-evidence milestone complete.

### Cost Observations
- Archival surfaced more real work (a compile break, untracked artifacts) than the closeout itself recorded.

## Cross-Milestone Trends

| Trend | Evidence | Implication |
|-------|----------|-------------|
| Binary Core architecture | v5.0 extracted generated shell logic into standalone packages | The "eject trap" is solved; future generator tasks should focus on thin UI glue and delegate injection |
| Verification gap accumulation | v5.0 shipped with Phase 76/77 lacking `VERIFICATION.md` | Verification ledgers must be treated as block-merge requirements during phase completion to prevent milestone-level tech debt |
| Proof truth is part of product surface | v3.1 closed once Phase 18 Proof passed; v3.2 closed once Phase 23 commerce proof lane + parity test were both merge-blocking | Future milestones should define proof lanes before final execution slices, and parity tests for any new traceability convention must ship with the convention |
| Runtime ownership remains the strongest guardrail | v3.1 added capabilities without generic plugin semantics; v3.2 added commerce contracts without provider adapter code in core | Continue rejecting high-frequency bridge surfaces and provider-specific code in core unless they move to native screens, offline islands, or companion/adapter milestones |
| Environment-sensitive native proof needs lane design | Android JVM proof was fast after splitting from emulator proof; v3.2 commerce proof split hermetic merge-blocking from scheduled-only advisory provider/storefront/device checks | Keep merge-blocking and advisory proof lanes separate, and surface the advisory-to-merge-blocking promotion path inside runtime diagnostics, not only CI YAML |
| Audit-driven decomposition prevents oversized phases | v3.2 Phase 22 was decomposed into 23 + 24 before execution after the milestone audit flagged scope risk | Run `/gsd:audit-milestone` early in milestone arcs to surface decomposition candidates before plans are written |
| Re-audits trump rewriting | v3.2 closure required three re-audit appends (Phase 24, milestone closure, Phase 25) rather than rewriting the original `gaps_found` audit | Treat audit files as append-only ledgers — `gaps_found` followed by closure re-audits beats overwriting the original verdict |
| Prove archetypes with mocks that share the real core | v3.4 shipped a copy-able paywall corridor with a pure-Elixir `MockStorefront` and a merge-blocking hermetic proof, both routed through the real reconciliation/projection pipeline, with zero provider-SDK code | When opening a new product archetype, mock the provider boundary only — keep the contract, reconciliation, and UI-derivation path real and proof-locked, deferring vendor SDK integration to a dedicated adapter milestone |
| CLI-generated milestone artifacts need author-time input quality | v3.4's milestone-complete CLI emitted placeholder `One-liner:` bullets into MILESTONES.md because phase SUMMARYs lacked clean one-liners | Author SUMMARY one-liners at phase close; treat machine-extracted milestone summaries as drafts to verify, not final copy |
| Companion seams need backend-authority discipline | v3.5 proved Rulestead, Rindle, and Sigra as typed, fail-closed companion surfaces while keeping device media/auth evidence non-authoritative | Future companions should start with explicit authority/evidence lanes and route-local restrictions before adding provider or native machinery |
| Audit artifacts are part of completion truth | v3.5 behavior was green, but closeout initially failed on missing Phase 44 verification, stale Phase 43 roadmap status, an open thread, and active-tree resolved UAT residue | Treat verification reports, thread closure, roadmap parity, and artifact cleanup as required product work, not administrative cleanup |
| Provider adapters must stay evidence-only | v3.7 shipped StoreKit/Play Billing seams and a paywall facade only after audit proved evidence flows into backend-owned reconciliation and grants wait for backend projection | Future provider or native adapter work should expose explicit swap targets, closed vocabularies, advisory proof posture, and authority-fence tests before widening claims |
| Auth/session machinery must stay backend-authoritative | v3.8 shipped Sigra session authority, handoff, step-up, and auth-return seams while keeping shell/native/provider events evidence-only until backend projection | Future auth/provider/native UX work should start with authority projection, denial sanitization, replay/expiry proof, and support-truth split before adding provider-specific templates |
| Backend authority compounds across entry paths | v3.9's notification-open resolver reused `RouteGate.evaluate/4` with `activation_source: :notification`, getting Sigra step-up reuse (OPEN-02) for free | New activation sources (notifications, deep links, future seams) should delegate to the existing route gate via a typed `activation_source` rather than re-implementing auth/step-up |
| Validation-ledger debt is now systemic | v3.8 and v3.9 both closed with deferred Nyquist VALIDATION.md ledgers despite green proof and requirements | Close validation bookkeeping during phase execution, or add a closeout gate that blocks on draft ledgers, before v4.0 |
| Closeout-as-contract beats prose review | v3.9 used a `CLOSEOUT.md` frontmatter checklist verified by `mix closeout.verify` as the closing gate | Support-truth-sensitive milestones should ship a machine-readable closeout contract alongside the proof lane |
