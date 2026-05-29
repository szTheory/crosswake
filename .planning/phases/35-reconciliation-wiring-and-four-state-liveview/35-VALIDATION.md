---
phase: 35
slug: reconciliation-wiring-and-four-state-liveview
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-29
---

# Phase 35 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Seeded from 35-RESEARCH.md §Validation Architecture.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | ExUnit (built-in Elixir) |
| **Config file** | `test/test_helper.exs` (standard) — example host: `examples/phoenix_host/` |
| **Quick run command** | `cd examples/phoenix_host && mix compile --warnings-as-errors` |
| **Full suite command** | `mix test --exclude requires_example_host --warnings-as-errors` |
| **Estimated runtime** | ~15 seconds (compile) / ~30 seconds (full suite) |

---

## Sampling Rate

- **After every task commit:** `cd examples/phoenix_host && mix compile --warnings-as-errors`
- **After every plan wave:** `mix test --exclude requires_example_host --warnings-as-errors`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** ~30 seconds

---

## Per-Task Verification Map

| Req ID | Behavior | Test Type | Automated Command | File Exists |
|--------|----------|-----------|-------------------|-------------|
| WIRE-01 | `ingest_evidence/2` called with mock evidence → `{:ok, %{status: :awaiting_verification, ...}}` | hermetic unit (Phase 36) / compile (Phase 35) | `cd examples/phoenix_host && mix compile --warnings-as-errors` | ✅ compile / ❌ proof is Phase 36 |
| WIRE-02 | MockBackend builds verified snapshot → `project_snapshot/2` → `{:ok, projected}` | hermetic unit (Phase 36) / compile (Phase 35) | `cd examples/phoenix_host && mix compile --warnings-as-errors` | ✅ compile / ❌ proof is Phase 36 |
| STATE-01 | All four `derived_state/1` outputs reachable; UI consumes derived atom only (no raw lanes); PubSub atom-only contract | compile + manual | `cd examples/phoenix_host && mix compile --warnings-as-errors` | ✅ compile / ⚠️ rendering manual |
| PWAL-02 | `PaywallEntryLive` renders `:denied` with `PaywallEntry` (pricing + Subscribe), zero provider-SDK code | compile + manual | `cd examples/phoenix_host && mix compile --warnings-as-errors` | ✅ compile / ⚠️ rendering manual |
| D-12 | `{Phoenix.PubSub, name: CrosswakeExample.PubSub}` starts in supervision tree | compile | `cd examples/phoenix_host && mix compile --warnings-as-errors` | ❌ Wave 0 |
| D-09/D-10 | `case @derived_state` exhaustive four-branch dispatch; `:stale` structurally distinct from `:denied` | compile | `cd examples/phoenix_host && mix compile --warnings-as-errors` | ❌ Wave 0 |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky/manual*

---

## Hermetic Test Strategy (enables Phase 36)

**Synchronously/deterministically testable (the MockBackend core):**
`MockBackend.build_verified_snapshot/2` + `EntitlementProjection.project_snapshot/2` + `derived_state/1`
is pure Elixir — no process, no PubSub, no LiveView. This is precisely what Phase 36's merge-blocking
hermetic proof asserts. Phase 35 must ensure this path is callable **without a running server** (D-02),
using the `Code.require_file`-at-module-scope idiom so the proof stays **UNtagged** and runs in the
`phase34-proof.yml` `mix test --exclude requires_example_host` lane.

**LiveView-only (NOT hermetically testable — verified manually / via compile):**
- `Task` + delay async `:pending → terminal` wrapper (D-04/D-05) — process timing
- `connected?(socket)` PubSub subscribe guard — requires a LiveView socket
- HEEx rendering of the four state components — requires Phoenix rendering pipeline

**Four-state reachability (the crux — bridges `:awaiting_verification` → verified snapshot):**
- `:granted` → verified snapshot `reconciliation: :projection_refreshed, freshness: :fresh, authority: :active, access: :granted` → `project_snapshot/2` → `derived_state/1`
- `:denied` → same path with `authority: :none, access: :denied`
- `:stale` → `freshness: :stale` (stale check fires first; other lanes arbitrary)
- `:pending` → `derived_state/1` called **directly** on a `reconciliation: :awaiting_verification` snapshot — `project_snapshot/2` rejects `:awaiting_verification`, so the pending path bypasses it (mirrors real topology)

---

## Wave 0 Requirements

- [ ] `MockBackend` module created as a **plain module** callable without a server (so Phase 36's `Code.require_file` proof can reach it)
- [ ] `{Phoenix.PubSub, name: CrosswakeExample.PubSub}` added to `application.ex` children before `PaywallEntryLive` subscribes
- [ ] No new test framework — existing ExUnit + compile verification covers Phase 35

*Phase 35 does NOT create `phase34_paywall_corridor_proof_test.exs` — that is Phase 36's deliverable. Phase 35 makes it possible.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Four states render as distinct UI (color + structure) | STATE-01, D-10 | HEEx rendering needs the Phoenix pipeline / browser | Run example host (`cd examples/phoenix_host && mix phx.server`), visit `/commerce/paywall`, use dev scenario buttons to drive each of the four states; confirm `:stale` shows no pricing/Subscribe |
| Async `:pending → :granted` transition observable | WIRE-01/02, D-04 | Process-timing dependent | Click "Subscribe"; observe `:pending` panel, then terminal state after the mock delay |

---

## Validation Sign-Off

- [ ] All tasks have an automated verify (compile or test) or a Wave 0 dependency
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers MockBackend-as-plain-module + PubSub-in-supervision-tree
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
