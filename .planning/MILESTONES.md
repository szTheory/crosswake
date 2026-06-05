# Project Milestones: Crosswake

## v4.1 Multi-SaaS Archetype Proof Lanes (Shipped: 2026-06-05)

**Phases completed:** 6 phases, 13 plans

**Key accomplishments:**

- Proved an end-to-end subscription SaaS commerce corridor using mock storefront adapters, ensuring entitlement projections are strictly backend-promoted.
- Validated a notification-driven workflow, verifying Chimeway push-token binding connects cleanly with Sigra session state and RouteGate enforces auth checks on deep-links without silent fallbacks.
- Verified a media/evidence capture workflow using Rindle reconciliation to recover from degraded network failures, keeping local capture signals non-authoritative.
- Proved an auth-sensitive admin workflow by triggering Sigra step-up ceremonies, ensuring native shell session persistence requires handoff tickets for administrative routes.
- Proved an offline/draft recovery workflow that enforces explicit `:cached_read_only` and `:local_first` policies, rejecting generic universal sync abstractions.
- Ensured all E2E archetype proofs run hermetically in CI without requiring manual device verification.

**Verification:** Milestone closeout (`.planning/milestones/v4.1-CLOSEOUT.md`) passed all checks, enforced by `mix closeout.verify`.

**Archive:**

- `.planning/milestones/v4.1-ROADMAP.md`
- `.planning/milestones/v4.1-REQUIREMENTS.md`
- `.planning/milestones/v4.1-CLOSEOUT.md`

---

## v4.0 Production Shell Runtime Line (Shipped: 2026-06-04)

**Phases completed:** 6 phases, 18 plans

**Key accomplishments:**

- Established the Runtime-Line Policy Contract and Support-Truth Taxonomy.
- Shipped the Diagnostic Export Seam in Elixir.
- Fixed Xcode 26 CI and updated Generator Templates.
- Implemented Native Shells with Android JVM Hermetic Proof.
- Reached Android Verification Closure and Device-UAT.
- Executed the Docs-Contract Parity Gate, Android Promotion, and Closeout.

**Verification:** Milestone closeout (`.planning/milestones/v4.0-CLOSEOUT.md`) completed.

**Archive:**

- `.planning/milestones/v4.0-MILESTONE-AUDIT.md`
- `.planning/milestones/v4.0-CLOSEOUT.md`

---

## v3.9 Chimeway Notification Seam (Shipped: 2026-06-03)

**Phases completed:** 5 phases, 17 plans, 12 tasks

**Key accomplishments:**

- Chimeway contract-only companion entrypoint with provider-neutral token evidence and backend-owned token binding contracts (TOKN-01/02); raw bridge token evidence redacts into Chimeway contracts and is excluded from telemetry, fixtures, denials, and docs
- Host-owned Phoenix registry for binding, rotation, logout/session revocation, permission loss, provider invalidation, and staleness pruning via `Ecto.Multi` with safe audit rows and post-commit telemetry (TOKN-03)
- Notification-open resolver that routes opens through manifest-known route ids, `RouteGate` with `activation_source: :notification`, and Sigra session-authority/step-up reuse — failing closed with stable denial codes for expired/replayed/revoked/route-mismatched/binding-mismatched/unsupported-action/policy-denied opens and no silent fallback (OPEN-01/02/03)
- Operator truth: doctor, operator inspection, support matrix, fixtures, and guides distinguish token-binding/open-routing readiness from APNs/FCM delivery support, backed by stable low-cardinality telemetry that forbids raw tokens, payloads, route params, and PII (DIAG-01/02)
- Merge-blocking hermetic proof covering token contracts, binding/revocation lifecycle, open resolution, Sigra route gating, denial sanitization, support/docs parity, and telemetry redaction (PROOF-01)
- APNs/FCM device delivery, real token issuance, provider credentials, notification-tray behavior, and console metrics kept advisory with explicit promotion criteria; closeout verifies 10/10 requirements mapped and no surface implies first-party push delivery (PROOF-02, REL-01)

**Verification:** Milestone closeout (`.planning/milestones/v3.9-CLOSEOUT.md`) passed all checks — project state, roadmap parity, requirements state, phase verification, SUMMARY frontmatter, thread/seed disposition, release continuity, and support-claim parity all `complete`; validation ledgers `deferred_with_reason`. Closeout enforced by `mix closeout.verify`.

**Known tech debt:** Draft Nyquist VALIDATION.md ledgers for Phases 59, 60, 62, and 63 remain bookkeeping gaps (routed to Phase 64); merge-blocking ExUnit proof and `closeout.verify` cover shipped public support truth.

**Archive:**

- `.planning/milestones/v3.9-ROADMAP.md`
- `.planning/milestones/v3.9-REQUIREMENTS.md`
- `.planning/milestones/v3.9-CLOSEOUT.md`

---

## v3.8 Full Sigra Auth and Session Machinery (Shipped: 2026-06-02)

**Phases completed:** 5 phases, 19 plans, 42 tasks

**Key accomplishments:**

- Backend-owned Sigra session authority contract with canonical auth.step_up denial subcodes and sanitized shell details
- Route-local auth_posture validation and manifest serialization for remembered/cached auth weakening
- Pure Sigra route-auth evaluator wired into RouteGate with canonical fail-closed denial codes
- Session-authority auth posture surfaced through doctor, publish readiness, support matrix, and operator inspection
- Guides, support matrix, release-boundary docs, and proof fixtures now reflect Sigra session-authority route evaluation
- Pure Sigra handoff contracts with backend-authority projection and canonical auth.handoff denial proof
- Ecto-backed one-time Sigra handoff tickets with Phoenix.Token locators, atomic redemption, audit evidence, and host-owned session renewal instructions
- Sigra handoff contract/server-record machinery is now reflected in doctor, support matrix, operator inspection, guides, fixtures, and proof without claiming later auth flows.
- Pure Sigra step-up intent contracts with backend authority projection requirements and canonical intent denial subcodes
- Ecto-backed step-up intent issue and one-time consume flow with backend authority projection and host session renewal instructions
- Shared Sigra ceremony core with Plug and LiveView adapters that fail closed into the same host-issued challenge flow
- Canonical support and docs truth for shipped Sigra step-up intent plus Plug/LiveView ceremony without auth-return overclaims
- Provider-neutral route-local auth-return policy and manifest serialization
- Pure evidence-only auth-return contracts with semantic validation and denial vocabulary
- Example-host server-record proof for auth-return replay, audit, and backend promotion authority
- Public and operator truth for shipped auth-return boundaries without provider/device overclaims
- Stable Sigra auth telemetry and two-axis auth truth now flow through diagnostics, support, operator inspection, and guides.
- Phase 58 security closeout now has a machine-checkable STRIDE ledger and deterministic security-only verifier gate.
- Phase 58 now has CI parity for merge-blocking auth closeout proof and advisory provider/device proof.

**Verification:** Milestone audit satisfied 16/16 requirements, 5/5 phases, 10/10 integration checks, and 5/5 E2E flows. Audit evidence included `mix compile --warnings-as-errors`, security-only closeout verification, and 115 focused proof/support/operator/docs tests with 0 failures.

**Known tech debt:** Nyquist validation ledgers for Phases 54-58 remain stale or partial and are tracked in `STATE.md` Deferred Items.

**Archive:**

- `.planning/milestones/v3.8-ROADMAP.md`
- `.planning/milestones/v3.8-REQUIREMENTS.md`
- `.planning/milestones/v3.8-MILESTONE-AUDIT.md`
- `.planning/milestones/v3.8-phases/`

---

## v3.7 Commerce Provider Adapters (Shipped: 2026-06-01)

**Phases completed:** 2 phases, 7 plans, 17 tasks

**Key accomplishments:**

- Shipped first-party StoreKit and Play Billing companion seams that normalize provider evidence into backend-owned reconciliation contracts without granting device-local entitlement authority.
- Added shared provider evidence and purchase/restore result contracts, preserving provider-specific lineage while keeping entitlement truth backend-projected.
- Wired the example-host paywall through a behaviour-backed storefront adapter contract so the mock remains default and StoreKit/Play Billing provider facades are explicit swap targets.
- Updated support matrix, operator inspection, doctor readiness, commerce guidance, changelog posture, and proof fixtures so provider seams are shipped while provider/device proof remains advisory.
- Closed the milestone-audit blocker with tagged LiveView storefront result handling and merge-blocking proof for the configured provider facade path.

**Verification:** Milestone audit passed 3/3 requirements, 2/2 phases, 10/10 integration checks, and 4/4 E2E flows. Phase 48.1 proof ran 69 focused tests with 0 failures.

**Archive:**

- `.planning/milestones/v3.7-ROADMAP.md`
- `.planning/milestones/v3.7-REQUIREMENTS.md`
- `.planning/milestones/v3.7-MILESTONE-AUDIT.md`
- `.planning/milestones/v3.7-phases/`

---

## v3.5 First-Party Companions (Shipped: 2026-05-31)

**Phases completed:** 10 phases, 22 plans, 40 tasks

**Key accomplishments:**

- Locked the shared `Crosswake.Companion` seam: six-callback behaviour, typed state, fail-closed optional dependency diagnostics, companion telemetry, and in-tree `lib/crosswake/companions/<name>/` convention.
- Shipped the Rulestead gating seam end-to-end: route-policy `gated_by`, manifest binding, local-snapshot runtime evaluation, `:gate_denied`/`:kill_switch_active` denials, doctor/support truth, hermetic/advisory proof, and `/gating` mock example.
- Shipped the Rindle media seam and mock proof: typed upload grant/capture evidence/media object contracts, backend-owned reconciliation, stable idempotency, queued-not-committed semantics, pure-Elixir `/media/proof` lane, and hermetic/advisory proof split.
- Shipped Sigra contract-only auth truth: backend-owned `AuthContext` and `SessionAuthorityLane`, route predicates (`auth_min_level`, `requires_recent_auth`), fail-closed `:step_up_required` denials, and doctor/support truth without claiming deferred Sigra machinery.
- Published `guides/companions.md` as the canonical companion guide and locked it with semantic docs-contract tests against live support matrix, denial vocabulary, and doctor findings.

**Verification:** Milestone audit passed 15/15 requirements; Phase 44 focused proof passed 27 tests; Phase 47 guide/proof passed 12 tests; hermetic suite passed 455 tests with 44 excluded.

**Archive:**

- `.planning/milestones/v3.5-ROADMAP.md`
- `.planning/milestones/v3.5-REQUIREMENTS.md`
- `.planning/milestones/v3.5-MILESTONE-AUDIT.md`
- `.planning/milestones/v3.5-phases/`

---

## v3.4 Commerce Archetype Proof (Shipped: 2026-05-29)

**Phases completed:** 5 phases, 8 plans, 8 tasks

**Key accomplishments:**

- Declared three `:subscription_default` corridor routes (paywall_entry live + purchase/restore_intent post) in `examples/phoenix_host` with canonical `crosswake.commerce` DSL, plus a manifest-introspection proof test confirming correct role_ownership (Phase 33).
- Established the `phase34-proof.yml` two-job CI split — a hermetic merge-blocking lane (`--exclude requires_example_host`) and an advisory `continue-on-error` lane carrying the 4-condition `promotion_path` (Phase 33).
- Built `CrosswakeExample.Commerce.MockStorefront` as a pure-Elixir, provider-neutral evidence emitter (`simulate_purchase/2`, `simulate_restore/2`) documented as the StoreKit/Play Billing swap target, with a hermetic replay/idempotency proof (stable `entry_id` identity, not transient `correlation_id`) and a provider-vocabulary fence (Phase 34).
- Wired the data layer — MockBackend verification-gap bridge, CorridorController POST seams, and PubSub supervision — into a four-state `PaywallEntryLive` LiveView with fail-closed `:stale` mount, exhaustive `case` dispatch to four named components, and dev scenario drivers consuming real `derived_state/1` derivation (Phase 35).
- Added the merge-blocking hermetic `phase34_paywall_corridor_proof_test.exs` driving the full lane (`ingest_evidence/2` → `project_snapshot/2` → `derived_state/1`), asserting all four states, the `:pending` → `:granted` transition, and the mock-boundary fence (`authority_mutation_allowed_from_evidence?/1 == false`), with a hermeticity self-scan guard (Phase 36).
- Added an end-to-end Paywall Corridor Walkthrough to `guides/commerce.md` (anchor-only, `provider: "mock"` callout, proof citation) and locked it to the shipped example via a hybrid string-presence + `function_exported?/3` docs-contract test in `commerce_test.exs`, preserving the phase23 three-layer + four-non-claims fences (Phase 37).

**Highlights:** All 14 requirements validated; milestone audit PASSED (14/14 req · 5/5 phase · 7/7 integration · 2/2 E2E flows). Zero provider-SDK code; zero new dependencies; reused the shipped v3.2 commerce contracts and Phase-21 reconciliation modules. 352 full-suite tests green.

---

## v3.3 Release Readiness (Shipped: 2026-05-29)

**Phases completed:** 6 phases, 11 plans, 5 tasks

**Key accomplishments:**

- Added canonical Apache-2.0 LICENSE file to repo root to back the hex package `:licenses` declaration.
- Replaced placeholder metadata in mix.exs with canonical szTheory block, introducing `@source_url` single source of truth and an explicit `:files` allowlist.
- Automated Hex releases via release-please with SHA-pinned Actions and Dependabot updates

---

## v3.2 Commerce And Entitlement Seams (Shipped: 2026-05-27)

**Phases completed:** 6 phases, 18 plans, 38 tasks

**Key accomplishments:**

- Crosswake now compiles explicit provider-neutral route commerce corridor declarations into a canonical manifest registry with strict referential validation and additive schema compatibility coverage.
- Crosswake now publishes synchronized commerce corridor support truth across support matrix, doctor output, and public guides with canonical fail-closed denial vocabulary.
- Provider-neutral entitlement snapshot lanes now encode authority, access, reconciliation, freshness, effective window, and evidence metadata as explicit typed contracts with non-granting reconciliation semantics.
- Bounded reconciliation evidence ingestion now stays non-authoritative by contract, with explicit fail-closed mappings and nested provider-vocabulary rejection in core validation paths.
- Published explicit entitlement lane semantics and synchronized renderer-generated support truth so stale or pending evidence states remain non-authoritative across public guidance and test-locked outputs.
- Closed the ENTL-03 verification gap by enforcing canonical evidence-source vocabulary fail-closed in both snapshot construction and reconciliation ingestion paths.
- Doctor now emits a typed commerce_summary surface with proof-class-labeled findings, derived from canonical support-matrix metadata, and fails closed on stale/unknown entitlement snapshots.
- Commerce corridor support truth now carries canonical prerequisite_classes, structured rebuild_requirement, and proof_class metadata; renderer emits three new columns; guides are byte-identical to canonical source and lock the advisory-cannot-redefine non-claim mechanically.
- Commerce guide is now a layered docs hub (support truth → advisory reviewer playbooks → explicit non-claims) with App Store and Play Store reviewer notes templates anchored to canonical SupportMatrix accessors and 8 new docs-contract tests that mechanically lock the layered structure, advisory boundary callouts, non-claims naming (StoreKit, Play Billing, device-local authority, offline replay), reviewer metadata columns (owner/proof_class/failure_posture/rebuild_requirement), canonical denial codes in fallback language, and reviewer corridor-role parity against `SupportMatrix.commerce_corridors/0`.
- Hermetic merge-blocking Phase 23 commerce support proof lane (14 tests) plus a two-job CI workflow that splits the required hermetic gate from the scheduled-only advisory provider/storefront/simulator/device lane, with a documented four-condition advisory-to-merge-blocking promotion path surfaced both in the workflow YAML and at runtime via a new `promotion_path` detail on advisory doctor findings.
- Deleted the contradictory trailing sentence from `20-VERIFICATION.md:63`, leaving the accurate Phase 20 final determination at line 61 as the sole conclusion.
- Hardened `summary_frontmatter_test.exs` with four edits (WR-01 third test, WR-02 helper raise, IN-01 `@requirements_path`, IN-02 `[xX ]`) and created both Phase 25 SUMMARYs in one atomic commit, closing all four advisory items from `24-REVIEW.md`.

---

## v2.0 Adopter Stress Profiles (Shipped: 2026-05-19)

**Delivered:** Three adopter-shaped exemplar lanes that pressure-tested the v1 Crosswake substrate and turned the resulting proof, diagnostics, and support posture into public product truth.

**Phases completed:** 6-10 (16 plans total)

**Key accomplishments:**

- Published a locked adopter-profile matrix and one shared example-host contract for realistic Crosswake app shapes.
- Proved a Phoenix-owned SaaS approvals lane with host-owned auth and one bounded haptics seam.
- Proved a selective-native claims-evidence corridor with one explicit `:native_screen` route plus route-local pack and transfer seams.
- Proved a local-first study flow with an append-only journal, sync endpoint, offline-island session, and cached read-only history lane.
- Hardened doctor diagnostics, per-profile verification scripts, CI, and support guidance around the rough edges exposed by the exemplars.

**Stats:**

- 86 files changed
- 6,640 insertions and 124 deletions
- 5 phases, 16 plans, 33 tasks
- 3 days from first seed to shipped milestone

**Git range:** `7f87976` → `45b7ea8`

**What's next:** Define the next milestone around Phoenix-first native capabilities, commerce support, and first-party companion seams without collapsing the route-policy thesis into a generic plugin surface.

---

## v3.0 Capability Contract And Packaging (Shipped: 2026-05-20)

**Delivered:** Capability taxonomy, package-boundary policy, commerce seam vocabulary, and proof/support truth that prepared Crosswake for native capability breadth without widening runtime ownership.

**Phases completed:** 11-14 (12 plans total)

**Key accomplishments:**

- Published capability-family taxonomy and route-owner decision rules.
- Classified `core`, `companion`, `example/docs-only`, and deferred surfaces with release and rebuild rules.
- Defined Phoenix-facing commerce and entitlement seams that keep entitlement truth backend-owned.
- Extended doctor, support-matrix, and proof-lane posture for future capability claims.

**Archive:**

- `.planning/milestones/v3.0-ROADMAP.md`
- `.planning/milestones/v3.0-REQUIREMENTS.md`

---

## v3.1 Native Capabilities and Bridge Expansion (Shipped: 2026-05-27)

**Delivered:** The first official low-frequency native capability families across Crosswake's bounded bridge contract, with route-local enforcement, support truth, and CI-backed proof.

**Phases completed:** 15-18 (16 plans total)

**Key accomplishments:**

- Implemented `haptics`, `share`, and `app_info` as base bounded bridge families across host and native shell surfaces.
- Added deep-link activation truth plus `permissions.status` as a read-only, notifications-scoped system-context bridge.
- Added `notification_token` and `file_picker` as asynchronous user-prompted capability families with provider-tagged evidence and transfer-bound staged handles.
- Canonicalized family-first route capability validation while preserving command-aware bridge lookup and the transfer-backed `file_picker` exception.
- Split support-matrix truth into baseline platform support, proof status, and capability-family posture.
- Added the dedicated `Phase 18 Proof` GitHub Actions lane and made it pass across Elixir proof slices, checked-in iOS shell proof, and Android JVM BridgeChannel proof.

**Verification:**

- `bash script/verify_phase18_contract.sh` — 48 tests, 0 failures.
- `mix test` — 184 tests, 0 failures.
- GitHub Actions `Phase 18 Proof` run `26498172516` — passed in 6m34s.

**Known deferred items at close:** 3 human-UAT checks from Phase 15 remain acknowledged and deferred in `STATE.md`.

**Archive:**

- `.planning/milestones/v3.1-ROADMAP.md`
- `.planning/milestones/v3.1-REQUIREMENTS.md`

**What's next:** Start the next milestone with `$gsd-new-milestone`; the strategic arc currently points toward commerce and entitlement seams or the next operator/companion slice.

---
