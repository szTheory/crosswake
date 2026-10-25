---
phase: 175-rehearsal-and-publish
plan: 20
status: halted_partial
completed: 2026-09-24
requirements-completed: []
---

# Phase 175 Plan 20 — Partial ordinary release, safely halted

The exact Gate 2 authorization was received and durably bound. PR #201 merged once through normal protection at `f3827d0bf4131badd96d04d924f9faca2789d284`. The single ordinary Release Please run `36035737504` ended `failure`: core Hex succeeded; iOS and Maven core publish jobs failed; exact-public proof and clean-room jobs were skipped. Direct reads confirm Hex 0.2.4 is present, iOS `main` remains at the expected split from the rehearsal baseline but `v0.2.4` is absent, and Maven's exact 0.2.4 POM returns 404. The iOS script failed before pushing because `mix` was unavailable; the Maven script rejected the new merge at its stale Phase 168 identity guard before Gradle ran.

No publish retry or recovery was performed. No Maven deployment was started because the script failed its identity guard before Gradle. The remaining Phase 175-21 same-run proof precondition was not met, so execution halted here with an honest PARTIAL record. A new, distinct approval is required before any iOS or Maven recovery/publication write.

Evidence: `175-FRESH-PUBLISH-LEG-2-0.2.4.md`, `evidence/175-fresh-core-release-run-0.2.4.json`, and `evidence/175-fresh-core-registry-0.2.4.json`.
