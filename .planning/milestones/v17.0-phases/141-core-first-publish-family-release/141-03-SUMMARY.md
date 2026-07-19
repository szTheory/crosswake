---
phase: 141-core-first-publish-family-release
plan: 03
subsystem: infra
tags: [hex, publish, core, release-please, release-as, human-gate, irreversible]

requires:
  - phase: 141-01
    provides: "core release-as 0.2.0 pin + runbook core-first Step 0"
  - phase: 141-02
    provides: "companion crosswake_dep() floors bumped ~> 0.1 → ~> 0.2 + compat-matrix cells"
  - phase: 141-05
    provides: "release-please extra-files drift registration (8 version-metadata files auto-bump 0.1.2→0.2.0)"
provides:
  - "core crosswake 0.2.0 LIVE on Hex + hexdocs + Android Maven — the v17.0 decoupling API, published BEFORE any companion"
affects: [141-04]

requirements-completed: [FAMILY-05, FAMILY-04]

# Metrics
completed: 2026-07-04
status: complete
---

# Phase 141 Plan 03: publish core 0.2.0 FIRST (human-gated, irreversible)

**Published core `crosswake` `0.2.0` — the v17.0 decoupling API (`Finding.{code,details}`, `:auth` clause, `:companions` registry) — to Hex BEFORE any companion. This is the load-bearing FAMILY-05 prerequisite that unblocks the whole family.**

## Outcome

- `crosswake` **0.2.0** is LIVE on Hex (`mix hex.info crosswake` → 0.2.0), `hexdocs.pm/crosswake/0.2.0` resolves, and the Android Maven core artifact published. The original `KeyError :code`-on-unpublished-core blocker is definitively resolved — companions now resolve `{:crosswake, "~> 0.2"}` against published core carrying the `:code` field.
- **release-as pin (141-01):** release-please would have computed core `0.1.3` (pre-major patch bumping: `bump-minor-pre-major:false` + `bump-patch-for-minor-pre-major:true`), not `0.2.0`. A `release-as: "0.2.0"` pin on the `.` component forced the intended minor — safe/auditable vs. fabricating a `feat!`. Pin stripped post-release (staleness gate hygiene).
- **Prep landed first:** Wave 1 (release-as pin + `~> 0.2` floors + matrix cells + extra-files drift registration) merged to origin/main with all 22 merge-blocking lanes green; the v17.0 `merge-blocking-*` lanes were registered required via `register_required_checks.sh` green-first, with `publish-hex-*` / `clean-room-proof-*` deliberately excluded.
- **Known deviation → follow-up:** the iOS SwiftPM mirror push failed with 403 (`MIRROR_PUSH_TOKEN` lacks push scope to the split repo) — Hex + Android Maven core published fine, iOS `0.2.0` tag NOT mirrored. Non-blocking for the Hex companion family. Captured as **SEED-003** (user owns the token).

## Verification

- `mix hex.info crosswake` → `0.2.0`; hexdocs 200.
- Ordering invariant held: core published strictly BEFORE the first companion (141-04).

---
*Core-first publish (FAMILY-05). Completed: 2026-07-04*
