---
phase: 121
slug: canonical-contract-source
status: approved
nyquist_compliant: true
wave_0_complete: false
created: 2026-06-20
---

# Phase 121 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Derived from `121-RESEARCH.md` §Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (built into Elixir) |
| **Config file** | `test/test_helper.exs` |
| **Quick run command** | `mix test test/crosswake/compatibility/compatibility_test.exs` |
| **Full suite command** | `mix test` |
| **Estimated runtime** | ~quick: a few seconds · full: under a minute |

---

## Sampling Rate

- **After every task commit:** Run `mix test test/crosswake/compatibility/compatibility_test.exs` (fastest signal for the canonical-constant attribute change)
- **After every plan wave:** Run `mix test` (full suite)
- **Before `/gsd-verify-work`:** Full suite green **AND** `mix crosswake.contract.gen && git diff --exit-code` clean
- **Max feedback latency:** ~10 seconds (quick), under a minute (full)

---

## Per-Task Verification Map

| Req | Behavior (observable) | Test Type | Automated Command | File Exists | Status |
|-----|-----------------------|-----------|-------------------|-------------|--------|
| CANON-01 | `Manifest.Types` bridge axis resolves to `Crosswake.Bridge.Contract.version()` (no independent literal) | unit | `mix test test/crosswake/compatibility/compatibility_test.exs` | ✅ (assertion update) | ⬜ pending |
| CANON-02 | Single authoritative source per axis; `grep -rn '"bridge_protocol_version"' lib/ test/ packages/ examples/` shows one value everywhere | smoke | `grep -rn '"bridge_protocol_version"' lib/ test/ packages/ examples/` → all `1.1.0`, no stray `1.0.0` literal in source | ✅ (CI/manual) | ⬜ pending |
| CANON-03 | `mix crosswake.contract.gen` is hermetic + idempotent | integration | `mix crosswake.contract.gen && git diff --exit-code examples/ios_shell_host/Fixtures/route_activation.json examples/android_shell_host/app/src/main/assets/route_activation.json test/fixtures/bridge_contract_vectors.json` | ❌ W0 (gen task new) | ⬜ pending |
| CANON-04 | Doctor/contract surfaces report bridge protocol `1.1.0` (not `1.0.0`); behavior to 0.1.x adopters unchanged | unit | `mix test test/crosswake/doctor/doctor_test.exs test/mix/tasks/crosswake_doctor_test.exs` | ✅ (assertion update 1.0.0→1.1.0) | ⬜ pending |
| CANON-05 | `ActivationCoordinator.kt:594` has no `?: "1.0.0"` fallback; native fails closed | smoke | `grep -n '?: "1.0.0"' packages/crosswake-shell-core-android/src/main/java/dev/crosswake/shell/core/ActivationCoordinator.kt` → empty | ✅ (CI/manual) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `lib/mix/tasks/crosswake.contract.gen.ex` — does not exist yet; create the hermetic gen task (mirror `crosswake.gen.shell.ex`)
- [ ] `test/fixtures/bridge_contract_vectors.json` — emitted by the gen task (task created in W0, output committed when the task is first run)

*All existing test files already exist — they require assertion updates (`1.0.0`→`1.1.0`), not new file creation. Known drift targets from research: `compatibility_test.exs` (~5 locations), `doctor_test.exs` (~2 locations), `crosswake_doctor_test.exs` (~1 location).*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Single-value grep invariant | CANON-02 | Repo-wide invariant, not a unit assertion | Run the CANON-02 grep; confirm one value everywhere and zero hand-maintained `bridge_protocol_version` literals in `lib/` source |
| Kotlin fallback removal | CANON-05 | Native (Kotlin) not in the ExUnit suite | Run the CANON-05 grep; confirm empty result |

*These become automated drift guards in Phase 122 (generate-and-diff CI + `contract_version_parity` doctor check). In Phase 121 they are CI/manual smoke checks.*

---

## Validation Sign-Off

- [ ] All requirements have an `<automated>` verify or a Wave 0 dependency
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (gen task + vectors fixture)
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [x] `nyquist_compliant: true` set in frontmatter (plan-checker confirmed strategy compliant)

**Approval:** approved 2026-06-20 (plan-checker PASS) · `wave_0_complete` set by executor when Wave 0 lands
