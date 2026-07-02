---
phase: 139
slug: crosswake-threadline-extraction
status: planned
nyquist_compliant: true
wave_0_complete: false
created: 2026-07-02
---

# Phase 139 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (mix test) |
| **Config file** | `packages/crosswake_threadline/mix.exs` (created this phase) + core `mix.exs` |
| **Quick run command** | `mix test <changed proof file>` (from the relevant package root) |
| **Full suite command** | core `mix test --exclude requires_example_host` + `packages/crosswake_threadline` `mix test` + clean-room lane |
| **Estimated runtime** | ~120 seconds |

---

## Sampling Rate

- **After every task commit:** Run the changed proof/test file + `mix compile --warnings-as-errors`
- **After every plan wave:** Run the full suite for the touched package(s)
- **Before `/gsd-verify-work`:** Full suite must be green (core + crosswake_threadline + clean-room lane)
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 139-01-01 | 01 | 1 | THREAD-01, THREAD-02 | T-139-01, T-139-05 | `Crosswake.Threadline.*`, `Crosswake.Audit.Ledger`, `Crosswake.Plug.Threadline`, `Crosswake.Live.Threadline` + both mix tasks resolve from `packages/crosswake_threadline/`; namespace preserved (host wiring stable); mix.exs `files:` includes `"priv"`; NO sibling companion dep | compile + grep | `cd packages/crosswake_threadline && mix deps.get && mix compile --warnings-as-errors`; `grep -rn "Crosswake\.Threadline\|Crosswake\.Plug\.Threadline\|Crosswake\.Live\.Threadline\|Crosswake\.Audit\.Ledger" lib/` empty; `grep "crosswake_sigra\|crosswake_chimeway" packages/crosswake_threadline/mix.exs` empty | ❌ W0 | ⬜ pending |
| 139-01-02 | 01 | 1 | THREAD-01 | T-139-02 | Core decoupled atomically: `@audit_ledger_support_truth` frozen as static literals (support_matrix.ex); threadline forbidden keys absorbed into core `@baseline_forbidden_keys` (10→21); core compiles clean, no `Crosswake.Threadline.*` compile dep remains | compile + structural | `mix compile --warnings-as-errors` (repo root); `grep -n "Crosswake.Threadline.Telemetry" lib/crosswake/telemetry.ex lib/crosswake/support_matrix/support_matrix.ex` empty | ❌ W0 | ⬜ pending |
| 139-01-03 | 01 | 1 | THREAD-01 | T-139-06 | `crosswake.gen.audit` template path repointed to `Application.app_dir(:crosswake_threadline, ...)`; existing `File.exists?` fallback unchanged | structural | `grep "app_dir(:crosswake_threadline" packages/crosswake_threadline/lib/mix/tasks/crosswake.gen.audit.ex` | ❌ W0 | ⬜ pending |
| 139-02-01 | 02 | 2 | THREAD-01 | T-139-07 | Moved threadline unit tests (id/telemetry/plug/ledger + task tests) pass in package lane; any core-side test asserting `baseline_forbidden_metadata_keys` count updated 10→21 | unit | `cd packages/crosswake_threadline && mix test`; `mix test --exclude requires_example_host` (core, green) | ❌ W0 | ⬜ pending |
| 139-02-02 | 02 | 2 | THREAD-02 | T-139-03, T-139-04 | Audit handler crash-isolated: generated `gen.audit` EEX template wraps write in `try/rescue` (log error, do NOT reraise — telemetry auto-detaches a raising handler); ledger append-only + PII-free | structural + unit | `grep -n "rescue" packages/crosswake_threadline/priv/templates/crosswake/audit/*.eex`; template-render test green | ❌ W0 | ⬜ pending |
| 139-02-03 | 02 | 2 | THREAD-02 | T-139-08 | Vacuity-safe clean-room ExUnit proof: `Telemetry.event_names/0` == 3 canary, `Plug.Threadline.init([])` OK, `Audit.Ledger.actor_ref/2` returns 64-char hex; `refute :crosswake_sigra in deps` + `refute :crosswake_chimeway in deps` (proves zero-sibling-dep non-vacuously) | integration | `cd packages/crosswake_threadline && mix test test/crosswake/proof/phase139_threadline_cleanroom_test.exs` | ❌ W0 | ⬜ pending |
| 139-03-01 | 03 | 3 | THREAD-03 | T-139-09 | `crosswake_threadline` registered as independent `elixir` release-please component (NOT in `linked-versions`); one-shot `release-as` 0.1.0; example-host path dep + compat-matrix row added | structural | `python3 -c` config+manifest valid + threadline component present, NOT in linked-versions | ❌ W0 | ⬜ pending |
| 139-03-02 | 03 | 3 | THREAD-03 | T-139-10, T-139-11 | `publish-hex-threadline` (CROSSWAKE_RELEASE=1, per-component gate) + `clean-room-proof-threadline` (installs NO sigra, NO chimeway) + cleanup/alert wired; clean-room script threadline-correct (non-companion: no `enabled?/0` assertion; `event_names/0` canary) | CI/structural | `python3 -c "import yaml"` valid + grep `publish-hex-threadline`/`clean-room-proof-threadline`/`threadline_release_created`/`crosswake_threadline` | ❌ W0 | ⬜ pending |
| 139-04-01 | 04 | 4 | THREAD-03 | T-139-12, T-139-13 | Dress rehearsal green + `hex.publish --dry-run` succeeds with `files:` allowlist including `priv/` and excluding `test/` | integration | `cd packages/crosswake_threadline && mix test`; `CROSSWAKE_RELEASE=1 mix hex.publish --dry-run --yes` | ❌ W0 | ⬜ pending |
| 139-04-02 | 04 | 4 | THREAD-03 | T-139-13, T-139-14 | HUMAN go/no-go (DEFERRED to family batch): merge Release PR → publish (AFTER sigra + chimeway live) → post-publish clean-room (siblings absent) green; merge release-as-cleanup PR | manual | Human-verified (irreversible publish + cleanup) — see Manual-Only Verifications | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

> **Wave structure (4 waves — mirrors Phase 138):** threadline is the pure OBSERVER — zero compile deps on
> siblings (verified: only two provenance comment lines in `telemetry.ex:38-40`), so like chimeway it has NO
> Finding-boundary refactor. Novel-to-threadline: Wave 1 folds in an atomic core-decoupling step (two
> compile-time coupling sites — `support_matrix.ex` `@audit_ledger_support_truth` + `telemetry.ex:245`
> forbidden-keys — that Phase 136's `:companions` registry inversion did NOT cover because threadline is not a
> registry companion), and the package must ship `priv/` (EEX audit templates) in the Hex tarball. Wave 1 =
> package skeleton + move + atomic core decouple + gen.audit app_dir fix; Wave 2 = test move + handler
> hardening + clean-room proof; Wave 3 = CI/release-please wiring; Wave 4 = human publish gate (DEFERRED).

---

## Wave 0 Requirements

- [ ] `packages/crosswake_threadline/` mix project skeleton (mix.exs with `files:` incl `priv`, config, README, CHANGELOG, LICENSE) + moved `Crosswake.Threadline.*`, `Audit.Ledger`, `Plug.Threadline`, `Live.Threadline` modules + both mix tasks + `priv/templates/crosswake/audit/` EEX files
- [ ] `packages/crosswake_threadline/test/test_helper.exs` — `ExUnit.start(exclude: [:requires_example_host, :advisory_only])`
- [ ] Moved threadline unit tests (id/telemetry/plug/ledger + task tests) into package lane
- [ ] `packages/crosswake_threadline/test/crosswake/proof/phase139_threadline_cleanroom_test.exs` — vacuity-safe clean-room proof (planned Wave 0, implemented Wave 2)
- [ ] Core decoupling: freeze `@audit_ledger_support_truth` static literals + expand core `@baseline_forbidden_keys` 10→21

*If none: "Existing infrastructure covers all phase requirements."*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Irreversible `mix hex.publish` of crosswake_threadline | THREAD-03 | Irreversible external side-effect; must fire AFTER sigra + chimeway are live; DEFERRED to the batched family publish (Phase 140 close) | Human runs publish only after dry-run + clean-room lane green AND sigra/chimeway are on Hex |

*If none: "All phase behaviors have automated verification."*

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies (the two Wave-4 checkpoint:human-action tasks are the sole manual gates — irreversible publish + cleanup PR merge — documented under Manual-Only Verifications; every autonomous task carries an automated verify)
- [x] Sampling continuity: no 3 consecutive tasks without automated verify (every auto task in 139-01..03 + 139-04-01 has `<automated>`; the two human gates are consecutive but terminal and irreducibly manual)
- [x] Wave 0 covers all MISSING references (all package files, moved tests, cleanroom proof, core-decouple edits, and priv/ templates are created within the phase — Wave 1-3)
- [x] No watch-mode flags
- [x] Feedback latency < 120s (package lane + core suite ~120s per the estimate)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** draft (orchestrator, 2026-07-02) — Per-Task Verification Map is a planner-refinable draft mirroring the 138 4-wave structure; the planner MUST reconcile final task IDs against the produced PLAN.md files.
