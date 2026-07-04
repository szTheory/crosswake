---
phase: 141-core-first-publish-family-release
plan: 04
subsystem: infra
tags: [hex, publish, sigra, chimeway, threadline, sequential, human-gate, irreversible]

requires:
  - phase: 141-03
    provides: "core crosswake 0.2.0 live on Hex — companions resolve ~> 0.2 against published core"
provides:
  - "crosswake_sigra 0.1.1, crosswake_chimeway 0.1.0, crosswake_threadline 0.1.0 all LIVE on Hex — the v17.0 Companion Family fully published"
affects: []

requirements-completed: [FAMILY-04]

# Metrics
completed: 2026-07-04
status: complete
---

# Phase 141 Plan 04: sequential companion publish (human-gated, irreversible)

**Published the three companions sequentially against live core 0.2.0 — sigra → chimeway → threadline, one Release PR merged at a time, never batched. The v17.0 Companion Family is FULLY PUBLISHED.**

## Outcome — all LIVE on Hex

| Package | Version | Route | Notes |
|---|---|---|---|
| `crosswake_sigra` | **0.1.1** | Release PR | `0.1.0` first attempt failed on missing `ex_doc` (docs task) → re-cut `0.1.1` |
| `crosswake_chimeway` | **0.1.0** | #46 | clean publish |
| `crosswake_threadline` | **0.1.0** | #71 (recovery) | `0.1.0` via #47 failed `--warnings-as-errors` (dead default arg `render_durable/2`); deleted dud tag, fixed via **#70**, re-cut clean `0.1.0` via **#71**; closeout **#74** stripped stale pin + deduped CHANGELOG |

- Each companion resolved `{:crosswake, "~> 0.2"}` against **published core 0.2.0** (not 0.1.2) — the real version-mismatch check the path-dep dress rehearsal could not catch.
- Sequential invariant held: sigra fully live (Hex + hexdocs) before chimeway merged; chimeway before threadline. threadline (pure observer) published LAST, proving telemetry-by-name against already-live siblings.
- Each companion's `release-as` one-shot pin was stripped after its publish (Release-As Staleness Gate PROOF-03a would otherwise block all PRs): chimeway pin via #67, threadline pin via #74.

## Deviations & follow-ups

- **Recovery deviations** (both resolved, family fully live): sigra `ex_doc` → 0.1.1; threadline dead-arg → #70 → clean 0.1.0 re-cut (#71).
- **Clean-room proof harness** (`script/verify_companion_cleanroom.sh`, non-required/advisory): a chain of bugs — app-name hyphens (#64), mkdir-leaf (#67), and an OPEN doctor-router issue (threadline Step 7). No companion clean-room proof went fully green this phase; resolvability itself was proven (threadline steps 1–6 passed). Captured as **SEED-004**.
- Redundant `chore/release-as-cleanup` PR #59 closed.

## Verification

- `mix hex.info` × 3 → sigra 0.1.1, chimeway 0.1.0, threadline 0.1.0; each hexdocs page resolves.
- With core 0.2.0 (141-03): the full v17.0 family (core + 3 companions) is LIVE on Hex.

---
*Sequential companion publish (FAMILY-04). Completed: 2026-07-04*
