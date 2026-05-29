---
phase: 33
slug: corridor-routes-and-ci-infrastructure
status: planned
nyquist_compliant: true
wave_0_complete: true
created: 2026-05-29
---

# Phase 33 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (mix test) |
| **Config file** | `mix.exs` / `test/test_helper.exs` (existing — no Wave 0 install) |
| **Quick run command** | `mix compile --warnings-as-errors` |
| **Full suite command** | `mix test --exclude requires_example_host` |
| **Example-host lane command** | `cd examples/phoenix_host && mix compile` then `mix test --include requires_example_host` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `mix compile --warnings-as-errors` (root) and, for router changes, `cd examples/phoenix_host && mix compile --warnings-as-errors`.
- **After every plan wave:** Run `mix test --exclude requires_example_host` (hermetic) plus `mix test test/crosswake/proof/phase33_commerce_corridor_routes_test.exs --include requires_example_host`.
- **Before `/gsd-verify-work`:** Full suite green + `phase34-proof.yml` exists and parses as valid YAML.
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 33-01-01 | 01 | 1 | PWAL-01 | T-33-01 | Compile-time commerce DSL validation | compile | `cd examples/phoenix_host && mix compile --warnings-as-errors` | ✅ | ⬜ pending |
| 33-01-02 | 01 | 1 | PWAL-01 | T-33-02 | Manifest role_ownership correctness (no runtime route hit) | manifest-introspection (ExUnit, requires_example_host) | `mix test test/crosswake/proof/phase33_commerce_corridor_routes_test.exs --include requires_example_host` | ❌ Wave 0 gap — new test file (created in this task) | ⬜ pending |
| 33-02-01 | 02 | 1 | PROOF-02 | T-33-CI-01, T-33-CI-02 | Advisory lane cannot gate merge; warnings-as-errors kept | YAML structure assertion | `test -f .github/workflows/phase34-proof.yml && grep -q 'continue-on-error: true' ... && grep -q 'mix test --exclude requires_example_host' ... && python3 -c "import yaml; yaml.safe_load(open('.github/workflows/phase34-proof.yml'))"` | ❌ Wave 0 gap — new file (created in this task) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

**Note on lane placement:** Task 33-01-02 is `@moduletag :requires_example_host` (it loads the compiled example host via `ExampleHost.load!`), so it runs in the existing example-host CI lane (phase5-proof.yml) and is intentionally EXCLUDED by the new hermetic `phase34-proof.yml` lane (`--exclude requires_example_host`). Per D-08, only the Phase 36 hermetic proof stays untagged; Phase 33's example-host-driven manifest assertion is correctly tagged. The compile gate (`mix compile --warnings-as-errors` on the example host) is what proves Success Criterion #1 inside the hermetic lane via the standing example-host build.

---

## Wave 0 Requirements

- `test/crosswake/proof/phase33_commerce_corridor_routes_test.exs` — created within Task 33-01-02 (the test and the router change ship together in Plan 01; the test asserts the manifest landing the router change produces).
- `.github/workflows/phase34-proof.yml` — created within Task 33-02-01.

*(No new test framework install needed — ExUnit + mix already present.)*

---

## Manual-Only Verifications

*All phase behaviors have automated verification (compile + manifest introspection + workflow-file YAML/grep assertions). No route is hit at runtime in Phase 33.*

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references (both new files created within their owning tasks)
- [x] No watch-mode flags
- [x] Feedback latency < 30s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** planner-signed 2026-05-29
