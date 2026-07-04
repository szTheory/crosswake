---
phase: 138-crosswake-chimeway-extraction
plan: 04
subsystem: infra
tags: [hex, publish, chimeway, human-gate, deferred]

requires:
  - phase: 138-03
    provides: chimeway extraction dress-rehearsal + vacuity-safe clean-room lane (sigra absent) green in-tree
provides:
  - "crosswake_chimeway published to Hex (executed in Phase 141, see 141-04)"
affects: [141-03, 141-04]

requirements-completed: [CHIME-03]

# Metrics
completed: 2026-07-04
status: complete
---

# Phase 138 Plan 04: chimeway publish gate (deferred → executed in Phase 141)

**The wave-4 human hex-publish gate for `crosswake_chimeway`. Deferred at authoring time (batched family release), executed during Phase 141 after core `0.2.0` and `crosswake_sigra` were live. `crosswake_chimeway` is LIVE on Hex.**

## Outcome

- `crosswake_chimeway` **0.1.0** is live on Hex (`mix hex.info crosswake_chimeway`), hexdocs resolves. Published via Release PR **#46** in the Phase 141 sequence (core → sigra → **chimeway** → threadline).
- Publish was deferred from Phase 138 to the core-first family release (Phase 141) — the same core-dependency blocker that stopped the first sigra attempt applied to chimeway (shared `~> 0.1` floor); resolved once core `0.2.0` published first and companion floors were bumped `~> 0.1` → `~> 0.2`.
- chimeway's clean-room proof is non-required (advisory); the harness itself had bugs fixed in-flight (#64 app-name, #67 mkdir-leaf) with one residual doctor-router issue captured as **SEED-004**. Resolvability was proven; the publish itself succeeded.

## Why this summary exists

The extraction (waves 1–3) landed green in-tree in Phase 138; the irreversible publish was re-homed to Phase 141. This record closes the 138 ledger. See `141-04-SUMMARY.md`.

---
*Deferred publish gate — executed in Phase 141. Completed: 2026-07-04*
