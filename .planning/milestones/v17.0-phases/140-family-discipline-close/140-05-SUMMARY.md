---
phase: 140-family-discipline-close
plan: 05
subsystem: infra
tags: [hex, publish, family, superseded, core-first]

requires:
  - phase: 140-04
    provides: COMPANION-PUBLISH-RUNBOOK.md + pipeline ready (no publish)
provides:
  - "Family publish re-homed to Phase 141 (core-first prerequisite) — sigra/chimeway/threadline all LIVE on Hex via 141-04"
affects: [141-01, 141-02, 141-03, 141-04]

requirements-completed: [FAMILY-04]

# Metrics
completed: 2026-07-04
status: complete
superseded_by: 141
---

# Phase 140 Plan 05: batched family publish — SUPERSEDED by Phase 141

**This plan's batched sequential publish (sigra → chimeway → threadline + register_required_checks.sh ship-gate) was attempted on 2026-07-03 and BLOCKED: companions depended on unpublished v17.0 core (`KeyError :code` from published core 0.1.2). The 140-05 plan/runbook omitted core-first ordering. The publish was re-homed to Phase 141, which publishes core `0.2.0` first.**

## Outcome

- **Attempt (2026-07-03):** boundary-sync PR #45 landed (origin==main, all 22 lanes green), then merging the sigra Release PR #42 → `publish-hex-sigra` FAILED at the compile step (never reached `hex.publish`): `KeyError key :code not found ... (crosswake 0.1.2) Finding.__struct__`. `release-failure-alert` fired as designed. **Nothing published.**
- **Root cause (systemic):** companions build `%Finding{code:}`; the `:code` field was added to core `Finding` in cc87362d (137-01), unpublished — Hex served core 0.1.2 (pre-`:code`). All 3 companions shared the `~> 0.1` floor → all blocked identically.
- **Recovery:** deleted the dangling `crosswake_sigra-v0.1.0` tag/release (publish failed, not on Hex), closed the auto-opened release-as-cleanup PR #48, main clean. Re-planned as **Phase 141** (core-first publish): pin core `release-as: 0.2.0`, bump companion floors `~> 0.1` → `~> 0.2`, publish core first, then sequential companions.
- **Net result (via Phase 141):** all three companions are now LIVE on Hex — sigra 0.1.1, chimeway 0.1.0, threadline 0.1.0. The `register_required_checks.sh` ship-gate ran green-first during 141 execution. FAMILY-04's "sequential, one component per PR, never batched" invariant held (in the 141 sequence).

## Why this summary exists

The FAMILY-04 execution work was moved wholesale to Phase 141 after the core-first prerequisite (FAMILY-05) was discovered. This closes the 140 ledger; the discipline deliverables (140-01..04) landed green in-tree. See `141-03-SUMMARY.md` / `141-04-SUMMARY.md`.

---
*Superseded by Phase 141 (core-first publish). Completed: 2026-07-04*
