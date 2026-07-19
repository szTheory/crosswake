---
phase: 139-crosswake-threadline-extraction
plan: 04
subsystem: infra
tags: [hex, publish, threadline, observer, human-gate, deferred]

requires:
  - phase: 139-03
    provides: threadline extraction dress-rehearsal + clean-room lane (both siblings absent) green in-tree
provides:
  - "crosswake_threadline published to Hex LAST as the pure observer (executed in Phase 141, see 141-04)"
affects: [141-03, 141-04]

requirements-completed: [THREAD-03]

# Metrics
completed: 2026-07-04
status: complete
---

# Phase 139 Plan 04: threadline publish gate (deferred → executed in Phase 141)

**The wave-4 human hex-publish gate for `crosswake_threadline`, the FINAL companion (pure observer, telemetry-by-name, zero compile deps on siblings). Deferred at authoring time, executed LAST during Phase 141 after core + sigra + chimeway were live. `crosswake_threadline` is LIVE on Hex.**

## Outcome

- `crosswake_threadline` **0.1.0** is live on Hex (`mix hex.info crosswake_threadline`), hexdocs resolves. Published last in the Phase 141 sequence, proving telemetry-by-name against already-live siblings.
- **Recovery deviation:** the first threadline publish (Release PR #47) failed at the `--warnings-as-errors` compile step on a dead default arg `render_durable/2`. Nothing reached Hex. Per user choice (clean `0.1.0`, not `0.1.1`): deleted the dud `crosswake_threadline-v0.1.0` tag + GH release, merged the warning fix **#70**, release-please re-cut a fresh `0.1.0` Release PR **#71**, which published clean. Closeout **#74** stripped the now-stale `release-as` pin and deduped the CHANGELOG.
- threadline's clean-room proof (non-required/advisory) hit the same doctor-router harness issue → **SEED-004**; steps 1–6 passed, resolvability proven.

## Why this summary exists

The extraction (waves 1–3) landed green in-tree in Phase 139 (see `139-VERIFICATION.md`); the irreversible publish was re-homed to Phase 141. This closes the 139 ledger. See `141-04-SUMMARY.md`.

---
*Deferred publish gate — executed in Phase 141. Completed: 2026-07-04*
