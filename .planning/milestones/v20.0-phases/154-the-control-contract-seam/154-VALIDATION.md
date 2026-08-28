---
phase: 154
slug: the-control-contract-seam
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-29
---

# Phase 154 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Seeded by `/gsd-plan-phase` from `154-RESEARCH.md` § Validation Architecture.
> Task-ID rows are filled in by `/gsd-validate-phase` once plans exist.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (core), Playwright/TypeScript (`examples/phoenix_host/e2e/`) |
| **Config file** | `test/test_helper.exs` (core exclude-tag logic); `examples/phoenix_host/playwright.config.ts` (e2e) |
| **Quick run command** | `mix test test/crosswake/bridge/ test/crosswake/proof/phase154_*_test.exs` |
| **Full suite command** | `mix test --exclude requires_example_host --exclude advisory_only` (matches CI `core-hermetic-proof`); `cd examples/phoenix_host && npx playwright test route_tour.spec.ts` (browser lane) |
| **Estimated runtime** | ~30s core hermetic; ~90s Playwright route tour |

---

## Sampling Rate

- **After every task commit:** Run the targeted `mix test` for the touched file(s) — e.g. `mix test test/crosswake/bridge/push_test.exs` after a `Bridge.push/3` change.
- **After every plan wave:** Run `mix test --exclude requires_example_host --exclude advisory_only`; for the HRDN-01 wave also run `cd examples/phoenix_host && npx playwright test route_tour.spec.ts`.
- **Before `/gsd-verify-work`:** Both the core hermetic suite AND the Playwright route-tour suite green. Per D-76's 3-PR sequencing this means 3 green-gate checkpoints (vocabulary PR, seam PR, HRDN-01 PR), not one.
- **Max feedback latency:** 30 seconds (core); 120 seconds (browser lane).

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| TBD | TBD | TBD | CTRL-01 | — | `Bridge.push/3` dispatches only declared capabilities; reply correlated by opaque ref | unit | `mix test test/crosswake/bridge/push_test.exs` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | CTRL-02 | T-154-denial-shape | No-shell / old-shell / undeclared all collapse to one `Crosswake.Shell.Denial` shape — no branch leaks shell internals to the adopter | unit | `mix test test/crosswake/shell/denial_test.exs` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | CTRL-03 | — | Undeclared-capability invocation raises loudly and names the missing route declaration (fails closed, never silent no-op) | unit | `mix test test/crosswake/bridge/push_test.exs` (raise-path cases) | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | CTRL-04 | T-154-vocab-drift | Host-registrable / dynamic controls cannot enter the catalog | proof (merge-blocking) | `mix test test/crosswake/proof/phase154_catalog_guard_test.exs` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | CTRL-05 | — | Rebuild class visible in changelog, support matrix, and doctor guidance | unit | `mix test test/crosswake/doctor/`; `mix test test/crosswake/guides/release_boundaries_test.exs` | ❌ W0 (doctor); ✅ existing (guides) | ⬜ pending |
| TBD | TBD | TBD | PROOF-04 | T-154-vocab-drift | Catalog line is merge-blocking with 4-way negative controls | proof (merge-blocking) | `mix test test/crosswake/proof/phase154_catalog_guard_test.exs` | ❌ W0 | ⬜ pending |
| TBD | TBD | TBD | HRDN-01 | — | AdminPilot haptics runs through `Bridge.push/3`; hand-rolled `<script>` IIFE is gone | browser (merge-blocking) | `cd examples/phoenix_host && npx playwright test route_tour.spec.ts` | ✅ file exists, ❌ new assertions | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/crosswake/bridge/push_test.exs` — stubs for CTRL-01, CTRL-03
- [ ] `test/crosswake/shell/denial_test.exs` — stubs for CTRL-02 (one-shape denial across all three failure modes)
- [ ] `test/crosswake/proof/phase154_catalog_guard_test.exs` — stubs for CTRL-04, PROOF-04 (mirror `phase130_extraction_guards_test.exs` structure + `ProofAssertions.stable_id_message/7`)
- [ ] `test/support/bridge_test_helpers.ex` (or `Crosswake.Bridge.Test`) — the `render_hook/3` correlation-id fabrication helper D-77 names as necessary scope; without it neither adopter tests nor this phase's own tests can simulate a hook reply
- [ ] `test/crosswake/doctor/doctor_test.exs` — extend for the new `capability_rebuild_findings/1` (CTRL-05)
- [ ] Framework install: **none** — ExUnit and Playwright are already fully configured.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Real haptic feedback fires on a physical iOS device | HRDN-01 | Taptic Engine output is not observable from any automated harness — the simulator has no haptics hardware | Run the AdminPilot showcase route on a physical iPhone against a dev shell build; tap the haptics affordance; confirm a physical tap is felt and the evidence panel shows the correlated reply. |

*All other phase behaviors have automated verification.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s (core) / < 120s (browser)
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
