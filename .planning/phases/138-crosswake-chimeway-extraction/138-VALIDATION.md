---
phase: 138
slug: crosswake-chimeway-extraction
status: planned
nyquist_compliant: true
wave_0_complete: false
created: 2026-07-02
---

# Phase 138 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (mix test) |
| **Config file** | `packages/crosswake_chimeway/mix.exs` (created this phase) + core `mix.exs` |
| **Quick run command** | `mix test <changed proof file>` (from the relevant package root) |
| **Full suite command** | core `mix test` + `packages/crosswake_chimeway` `mix test` + clean-room lane |
| **Estimated runtime** | ~120 seconds |

---

## Sampling Rate

- **After every task commit:** Run the changed proof/test file
- **After every plan wave:** Run the full suite for the touched package(s)
- **Before `/gsd-verify-work`:** Full suite must be green (core + crosswake_chimeway + clean-room lane)
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 138-01-01 | 01 | 1 | CHIME-01, CHIME-02 | T-138-01, T-138-03 | `Crosswake.Companions.Chimeway.*` (6 modules + facade) resolve from `packages/crosswake_chimeway/`; mix.exs has NO `crosswake_sigra` dep; `auth_context :: map()` guard note present; namespace preserved | compile + grep | `cd packages/crosswake_chimeway && mix deps.get && mix compile --warnings-as-errors`; `grep -rl Crosswake.Companions.Chimeway lib/` empty; `grep -c crosswake_sigra packages/crosswake_chimeway/mix.exs` == 0 | ❌ W0 | ⬜ pending |
| 138-01-02 | 01 | 1 | CHIME-01 | T-138-02 | `StubChimewayAbsentCompanion` compiles with NO `auth_authority?/0` (notification-only); core suite green post-extraction | unit | `mix test --exclude requires_example_host --exclude engine_present` | ❌ W0 | ⬜ pending |
| 138-02-01 | 02 | 2 | CHIME-01 | T-138-06, T-138-07 | 5 chimeway unit tests + facade test move to package; phase59 SPLIT (notification_support_truth/0 stays non-vacuous in core, 4 tests move) | unit | `cd packages/crosswake_chimeway && mix test test/crosswake/companions/ test/crosswake/proof/phase59_chimeway_contract_test.exs`; `mix test test/crosswake/proof/phase59_chimeway_support_truth_test.exs` | ❌ W0 | ⬜ pending |
| 138-02-02 | 02 | 2 | CHIME-01, CHIME-02 | T-138-05 | phase71 moves from sigra pkg → chimeway pkg with `{:crosswake_sigra, path:, only: :test}` (real AuthContext integration proof; test-only, never shipped) | integration | `cd packages/crosswake_chimeway && mix deps.get && mix test test/crosswake/proof/phase71_notification_workflow_proof_test.exs` | ❌ W0 | ⬜ pending |
| 138-02-03 | 02 | 2 | CHIME-02 | T-138-04 | clean-room proof: chimeway registered → telemetry events in `Crosswake.Telemetry.events/0` + forbidden keys in attach-time `handler.config[:forbidden_keys]` (A2 corrected — no phantom aggregator); NOT an auth authority; no runtime sigra dep | integration | `cd packages/crosswake_chimeway && mix test test/crosswake/proof/phase138_chimeway_cleanroom_test.exs` | ❌ W0 | ⬜ pending |
| 138-03-01 | 03 | 3 | CHIME-02, CHIME-03 | T-138-11 | `verify_companion_cleanroom.sh` no-engine smoke is chimeway-correct: `assert enabled?(%{})` (defaults true, NOT refute) + non-empty `Telemetry.event_names/0` == 10 canary (vacuity-safe, sigra absent) | script | `bash -n script/verify_companion_cleanroom.sh`; `grep -q crosswake_chimeway ... && grep -q event_names ...` | ❌ W0 | ⬜ pending |
| 138-03-02 | 03 | 3 | CHIME-03 | T-138-08 | crosswake_chimeway registered as independent `elixir` release-please component (NOT linked-versions), one-shot release-as 0.1.0; example-host path dep + compat-matrix row added | structural | `python3 -c "import json; ..."` config+manifest valid + chimeway component present | ❌ W0 | ⬜ pending |
| 138-03-03 | 03 | 3 | CHIME-03 | T-138-09, T-138-12 | publish-hex-chimeway (CROSSWAKE_RELEASE=1, per-component gate) + clean-room-proof-chimeway (no-engine, sigra absent) + cleanup/alert wired | CI/structural | `python3 -c "import yaml; ..."` valid + grep publish-hex-chimeway/clean-room-proof-chimeway/chimeway_release_created/strip_release_as.py crosswake_chimeway | ❌ W0 | ⬜ pending |
| 138-04-01 | 04 | 4 | CHIME-03 | T-138-13, T-138-14 | dress rehearsal green + `hex.publish --dry-run` succeeds with files: allowlist excluding test/ (test-only sigra dep NOT shipped) | integration | `cd packages/crosswake_chimeway && mix test`; `mix test --exclude requires_example_host --exclude engine_present` | ❌ W0 | ⬜ pending |
| 138-04-02 | 04 | 4 | CHIME-03 | T-138-13, T-138-15 | HUMAN go/no-go: merge Release PR → publish → post-publish clean-room (sigra absent) green; merge release-as-cleanup PR | manual | Human-verified (irreversible publish + cleanup) — see Manual-Only Verifications | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

> **Wave structure (4 waves — sigra's 5 minus the collapsed Finding-boundary wave):** chimeway has NO
> Finding-boundary refactor (resolver.ex uses `Crosswake.Shell.Denial` directly, a core type — no D-138-A
> analog to sigra's D-137-A), so Phase 137's waves 1-2 (core-side + sigra-internal Finding work) collapse
> away. Wave 1 = package skeleton + move + stub; Wave 2 = test move/split + phase71 move + cleanroom proof;
> Wave 3 = CI wiring; Wave 4 = human publish gate.

---

## Wave 0 Requirements

- [ ] `packages/crosswake_chimeway/` mix project + moved `Crosswake.Companions.Chimeway.*` modules
- [ ] Moved proof tests (phase71 → chimeway package; phase59 core/package split)
- [ ] Patched `verify_companion_cleanroom.sh` chimeway assertion (`enabled?(%{})` defaults true → `assert`, plus non-empty `forbidden_metadata_keys/0` canary to keep the lane vacuity-safe)

*If none: "Existing infrastructure covers all phase requirements."*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Irreversible `mix hex.publish` of crosswake_chimeway | CHIME-03 | Irreversible external side-effect (human go-gate, mirrors 137 wave 5) | Human runs publish only after dry-run + clean-room lane green |

*If none: "All phase behaviors have automated verification."*

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies (the two Wave-4 checkpoint:human-action tasks are the sole manual gates — irreversible publish + cleanup PR merge — documented under Manual-Only Verifications; every autonomous task carries an automated verify)
- [x] Sampling continuity: no 3 consecutive tasks without automated verify (every auto task in 138-01..03 + 138-04-01 has `<automated>`; the two human gates are consecutive but terminal and irreducibly manual)
- [x] Wave 0 covers all MISSING references (all package files, moved/split tests, cleanroom proof, and the cleanroom-script chimeway patch are created within the phase — Wave 1-3)
- [x] No watch-mode flags
- [x] Feedback latency < 120s (package lane + core suite ~120s per the estimate)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved (planner, 2026-07-02) — Per-Task Verification Map updated to the final 10 task IDs (138-01-01..138-04-02).
