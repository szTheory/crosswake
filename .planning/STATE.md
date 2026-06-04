---
gsd_state_version: 1.0
milestone: v4.0
milestone_name: Production Shell Runtime Line
status: planning
last_updated: "2026-06-04T07:10:30.103Z"
last_activity: 2026-06-04
progress:
  total_phases: 6
  completed_phases: 1
  total_plans: 6
  completed_plans: 6
  percent: 17
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-06-03)

**Core value:** Make runtime boundaries explicit so Phoenix teams can ship credible mobile apps without hiding the tradeoffs between LiveView, offline, and native ownership.
**Current focus:** Phase 65 — diagnostic export seam (elixir)

## Current Position

Phase: 65
Plan: Not started
Status: Ready to plan
Last activity: 2026-06-04

Progress: [██████████] 100%

## v4.0 Roadmap (Phases 64-69)

Contracts-first, proof-always build order (converged across all four research tracks):

1. **Phase 64** — Runtime-Line Policy Contract & Support-Truth Taxonomy (RLINE-01..05): lock OTA-safe vs. rebuild change classification, `:jvm_hermetic` vs. `:device_verified` taxonomy, compatibility matrix, Android promotion criteria — derived from existing `native_runtime_version` axis, no native code, no new manifest field.
2. **Phase 65** — Diagnostic Export Seam (Elixir) (DIAG-01..04): redaction allowlist + typed envelope before any native export code; fire-and-forget HTTP seam, not a bridge command.
3. **Phase 66** — Generator Templates & Xcode 26 CI Fix (TMPL-01..04, AVER-05): host-owned iOS/Android permission/entitlement + runtime-line templates with `ADOPT:` markers, placeholder/drift doctor checks, iOS CI on Xcode 26 SDK.
4. **Phase 67** — Native Shell Implementation & Android JVM Hermetic Proof (AVER-01, AVER-02): iOS + Android shells mirror contracts/templates, Android toolchain bumps (minSdk 30, compileSdk/targetSdk 35), merge-blocking JVM proof. Android stays `:verification_required`.
5. **Phase 68** — Android Verification Closure & Device-UAT (AVER-03, AVER-04): advisory emulator lane + capability-parity-locked device-UAT checklist with CI-provable/device-advisory/provider-advisory columns.
6. **Phase 69** — Docs-Contract Parity Gate, Android Promotion & Closeout (PROOF-01..03): merge-blocking manifest↔shell↔guide↔doctor parity gate, guides parity-locked to live truth, Android promotion only if criteria pass, `mix closeout.verify`.

## Performance Metrics

**Velocity:**

- Total plans completed: 152 (v1.0–v3.8 Phase 58, plus Phase 59-61)
- v3.9: 5 phases, 17 plans, 12 tasks — shipped 2026-06-03
- v3.8: 5 phases, 19 plans, 42 tasks — shipped 2026-06-02
- v3.7: 2 phases, 7 plans — shipped 2026-06-01
- v3.6: 6 phases, 15 plans — shipped 2026-06-01
- v3.4: 5 phases, 8 plans, 8 tasks — shipped in a single day (2026-05-29)

**Recent Trend:** Positive — v3.3 through v3.9 all closed with deterministic proof, audit evidence, and explicit support truth in place.

## Accumulated Context

### Roadmap Evolution

- v4.0 roadmapped 2026-06-03 as Production Shell Runtime Line with Phases 64-69 (continuing numbering from v3.9's Phase 63). 21/21 requirements mapped, 0 unmapped. Build order is contracts-and-support-truth first, diagnostics seam, generator templates + Xcode 26 fix, native shell + JVM hermetic proof, Android verification closure + device-UAT, then docs-contract parity gate + Android promotion + closeout.
- Phase 48.1 inserted after Phase 48: Close gap: ADPT-01/ADPT-02 — provider facade paywall swap-target contract (URGENT)
- v3.7 archived under `.planning/milestones/v3.7-*` with phase directories in `.planning/milestones/v3.7-phases/`.
- v3.8 archived under `.planning/milestones/v3.8-*` with phase directories in `.planning/milestones/v3.8-phases/`.
- v3.9 archived under `.planning/milestones/v3.9-*` with phase directories in `.planning/milestones/v3.9-phases/`.

### Decisions

Decisions are logged in PROJECT.md Key Decisions table and `.planning/MILESTONE-ARC.md`.

- [Milestone v4.0]: Rebuild/OTA policy derives from the existing `native_runtime_version` axis — NO new manifest schema field (would force a `manifest_schema_version` bump and break deployed shells).
- [Milestone v4.0]: Diagnostics export is a fire-and-forget HTTP seam (the Chimeway pattern), NOT a bounded-bridge command — preserves the low-frequency bridge thesis.
- [Milestone v4.0]: Support truth distinguishes `:jvm_hermetic` from `:device_verified`; Android stays `:verification_required` until the final docs-contract gate + promotion criteria pass. Android JVM/emulator evidence is CI-only (no local Java runtime).
- [Milestone v4.0]: Shells stay checked-in proof artifacts in `examples/`, not standalone publishable packages (arc non-goal). Hermetic proof merge-blocking; emulator/device/provider proof advisory with explicit promotion criteria.
- [Milestone v3.9]: Chimeway notification work is companion-first with a narrow core route-policy hook; token/open evidence stays non-authoritative, backend binding and RouteGate decide, and provider/device delivery proof remains advisory.
- [Phase 58]: Full Sigra machinery is shipped as backend-owned auth/session contracts with sanitized telemetry, support/operator truth, security closeout, and hermetic proof; provider/device auth proof remains advisory.
- [Phase 53]: Closeout verification uses `Crosswake.Planning.CloseoutVerifier` and `mix closeout.verify` as the deterministic REL-01 gate.
- [Phase 64-06]: Removed @rebuild_matrix_rows "2.x" entry (evidence_tier: :device_verified) — the 2.x band does not exist; re-introduction requires passing the validate_rebuild_matrix_evidence/2 gate added to validate/1 pipe.
- [Phase 64-06]: Reverted finding_policy.ex :verification_required severity to :error (WR-04 gap closed); hermetic proof tests use rescue Mix.Error inside capture_io blocks (Phase 52 pattern) rather than severity relaxation. RLINE-04 SATISFIED.

### Pending Todos

- Draft Nyquist VALIDATION.md ledgers for v3.9 Phases 59, 60, 62, and 63 remain bookkeeping gaps (routed to Phase 64 per v3.9 closeout).
- Deferred from v3.3: Clean up ExDoc hidden-type warnings (HEX-03 zero-warnings clause). Low priority.

### Blockers/Concerns

- Android JVM/emulator evidence continues to require CI (no local Java runtime) — Android stays `:verification_required` until v4.0 promotion criteria pass.
- v4.0 #1 risk is support-truth dishonesty: never claim JVM-CI evidence as device-verified; lock `:jvm_hermetic` vs. `:device_verified` taxonomy in Phase 64 before populating any matrix.
- Three-surface drift (manifest / shell native files / docs): the docs-contract parity test (Phase 69, PROOF-01) must lock manifest↔shell↔guide↔doctor; the canonical compatibility record is library-owned, not docs-owned.
- Platform-policy hard gates: Apple Xcode 26 SDK mandate (since 2026-04-28), OTA Guideline 2.5.2, `PrivacyInfo.xcprivacy`, Google Play `targetSdkVersion ≥ 35`, SafetyNet dead (use Play Integrity with CI debug-provider escape hatch).
- Diagnostics export is the likeliest PII/token leak vector: reuse the v3.9 Chimeway/Sigra redaction allowlist; define and test the allowlist (Phase 65) before any export code.

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 260603-nzr | Fix recurring validation-ledger debt — closeout gate teeth + cleared backlog (v3.8/v3.9 ledgers signed, v3.6 accept-closed) + un-brittled requirements.state. closeout.verify green, 746 tests pass. | 2026-06-03 | f59b06d | [260603-nzr-tighten-validation-ledger-closeout-gate](./quick/260603-nzr-tighten-validation-ledger-closeout-gate/) |
| Phase 64 P06 | 406 | 3 tasks | 6 files |

## Deferred Items

| Category | Item | Status | Deferred At |
|----------|------|--------|-------------|
| Validation | Draft Nyquist VALIDATION.md ledgers for v3.9 Phases 59, 60, 62, 63 | Routed to Phase 64 per v3.9 closeout | 2026-06-03 |
| Commerce | RevenueCat provider adapter | Deferred beyond first StoreKit/Play Billing adapter shape | 2026-06-01 |
| Docs | ExDoc zero-warnings clause (HEX-03) | Deferred | 2026-05-29 |
| CI | Retroactive SHA-pinning of pre-v3.3 proof workflows | Deferred | 2026-05-27 |
| Device Proof | Promote emulator/device lane to merge-blocking (DPROOF-01) | v2 — deferred until promotion criteria repeatedly met | 2026-06-03 |
| Device Proof | Firebase Test Lab device-matrix advisory lane (DPROOF-02) | v2 — deferred | 2026-06-03 |
| Shell | Standalone publishable shell packages (SHELL-01) | v2 — arc non-goal until release choreography ready | 2026-06-03 |

## Session Continuity

Last session: 2026-06-04T07:10:30.096Z
Stopped at: Phase 65 context gathered

## Operator Next Steps

- Plan the first v4.0 phase with `/gsd:plan-phase 64`
