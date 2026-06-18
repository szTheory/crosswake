---
phase: 113
slug: honest-e2e-rewrite-compile-gate
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-18
---

# Phase 113 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Source of truth for the requirement→signal map: `113-RESEARCH.md` § Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `@playwright/test` 1.60.0 (E2E) + `mix test` / `mix compile` (Elixir) |
| **Config file** | `examples/phoenix_host/playwright.config.ts` |
| **Quick run command** | `cd examples/phoenix_host && npx playwright test e2e/offline_sync.spec.ts` |
| **Full suite command** | `cd examples/phoenix_host && npx playwright test` |
| **Compile gate command** | `cd examples/phoenix_host && MIX_ENV=test mix compile --warnings-as-errors` |
| **Estimated runtime** | ~60–120 seconds (single spec); full Playwright lane longer |

---

## Sampling Rate

- **After every task commit:** Run the quick command (single spec) for spec tasks; run the compile-gate command for Elixir/CI tasks.
- **After every plan wave:** Run the full Playwright suite (both E2E specs).
- **Before `/gsd-verify-work`:** Full suite green AND `MIX_ENV=test mix compile --warnings-as-errors` green.
- **Max feedback latency:** ~120 seconds.

---

## Per-Task Verification Map

> Populated during execution. Requirement→signal mapping is fully specified in
> `113-RESEARCH.md` § Validation Architecture (E2E-03 a–f, E2E-04 + held-out/backstop checks).

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | Status |
|---------|------|------|-------------|-----------|-------------------|--------|
| _TBD by planner_ | | | E2E-03 / E2E-04 | E2E / CI | see RESEARCH § Validation Architecture | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `examples/phoenix_host/test/support/flashcards_fixtures.ex:47` — `create_progress` → `upsert_progress` (D-04b pre-flight; gate must land green)
- [ ] `examples/phoenix_host/e2e/offline_storage.spec.ts:89` — `#btn-pass` → `#btn-good` (sibling-spec hygiene; lane is red today)
- [ ] `examples/phoenix_host/e2e/offline_sync.spec.ts` — full honest rewrite (E2E-03 a–f)
- [ ] `examples/phoenix_host/lib/crosswake_example/e2e/sync_state_controller.ex` — scoped `count` + test-only `@moduledoc`

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Compile gate fails BEFORE Playwright on a real compile break | E2E-04 | Ordering is observable only via CI log sequence | Introduce a deliberate compile error under `examples/phoenix_host/lib/`; confirm CI fails on the `mix compile` step, not the Playwright step |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
