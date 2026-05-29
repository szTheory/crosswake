---
phase: 36
slug: hermetic-proof-lane
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-29
---

# Phase 36 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> **Test-only phase:** the single deliverable (`phase34_paywall_corridor_proof_test.exs`) IS
> the validation artifact. The contract below ensures the proof fails on real corridor
> regressions rather than passing vacuously.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (built-in) |
| **Config file** | `test/test_helper.exs` (`ExUnit.start()`) |
| **Quick run command** | `mix test test/crosswake/proof/phase34_paywall_corridor_proof_test.exs` |
| **Full suite command** | `mix test --exclude requires_example_host --warnings-as-errors` |
| **Estimated runtime** | ~3 seconds (pure, no process start, no network) |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/crosswake/proof/phase34_paywall_corridor_proof_test.exs`
- **After every plan wave:** Run `mix test --exclude requires_example_host --warnings-as-errors`
- **Before `/gsd-verify-work`:** Full hermetic suite must be green AND `mix compile --warnings-as-errors` clean
- **Max feedback latency:** ~5 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 36-01-* | 01 | 1 | PROOF-01 | — | Hermetic — no network/process/native SDK reachable from the proof | unit | `mix test test/crosswake/proof/phase34_paywall_corridor_proof_test.exs` | ❌ W0 | ⬜ pending |
| 36-01-* | 01 | 1 | PROOF-03 | — | Mock evidence can never directly grant authority | unit | `mix test test/crosswake/proof/phase34_paywall_corridor_proof_test.exs` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky. Concrete task IDs are assigned by the planner; every task in the plan maps to the single proof file above.*

---

## Success Criteria → Assertion Map (anti-vacuity contract)

| SC | Behavior | Required assertion(s) | Vacuity risk | Mitigation (MUST be in the proof) |
|----|----------|-----------------------|--------------|-----------------------------------|
| SC#1 | Four derived states, distinct | One `assert derived_state(snap) == :X` per `:stale`/`:pending`/`:denied`/`:granted`, each from a **different** snapshot | `cond` `true ->` fallthrough absorbs any snapshot → all four "pass" | Each snapshot must produce exactly one state; build each with the minimal distinguishing lane fields per D-04 anchors, not a shared near-identical snapshot |
| SC#2 | `:pending → :granted` transition | `assert result.status == :awaiting_verification` (ingest) → `assert derived_state(pending_snap) == :pending` → `{:ok, projected} = project_snapshot(nil, verified)` → `assert derived_state(projected) == :granted` | `project_snapshot(nil, _)` could pass with wrong fields | Route `:granted` through the shipped `MockBackend.build_verified_snapshot/2`, not a hand-built "granted" snapshot |
| SC#3 | Mock-boundary fence (3 truths, D-06) | `assert authority_mutation_allowed_from_evidence?(evidence) == false` · `assert {:error, :unverified_reconciliation_outcome} = project_snapshot(nil, unverified)` · `refute derived_state(verification_failed_snap) == :granted` | `authority_mutation_allowed_from_evidence?/1` returns false unconditionally → assertion is a contract doc, not a branch test | Assertion message must state it documents the lib contract; the `{:error, ...}` and `refute :granted` assertions carry the real behavioral weight |
| SC#4 | `async: false`, prefixed fixtures, self-scan guard | Self-scan reads `File.read!(__ENV__.file)`; asserts `async: false` present, `@tag :requires_example_host` absent, and require_file lines match only the allowed pure-commerce modules | Guard passes vacuously if forbidden-token strings match the guard's own source, or if checks are loose `String.contains?` | Build forbidden tokens via concatenation (e.g. `"start" <> "_supervised"`) so the guard never matches itself; match require_file lines by call-form regex, not bare substring |
| SC#5 | CI hermetic job runs file cleanly | No in-proof assertion — verified by `mix test --exclude requires_example_host --warnings-as-errors` in `phase34-proof.yml` (auto-discovers untagged file) | Green locally but red in CI from warnings-as-errors | `mix compile --warnings-as-errors` must be clean; no undefined-function warnings from `Code.require_file`'d modules |

---

## Wave 0 Requirements

None — ExUnit is configured, required modules are shipped/locked, and `phase34-proof.yml`
already globs `test/crosswake/proof/` (workflow comment explicitly names the Phase 36 file).
*Existing infrastructure covers all phase requirements.*

---

## Manual-Only Verifications

*All phase behaviors have automated verification.* SC#5 (CI lane) is confirmed by the existing
`phase34-proof.yml` job running on the branch; no manual step required.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify (the single proof file) or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (none)
- [ ] No watch-mode flags
- [ ] Feedback latency < 5s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
