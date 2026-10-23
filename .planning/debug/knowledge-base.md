# GSD Debug Knowledge Base

Resolved debug sessions. Used by `gsd-debugger` to surface known-pattern hypotheses at the start of new investigations.

---

## pr-214-example-host-seed17 — async Mix task reset disrupted parallel test loading
- **Date:** 2026-09-27
- **Error patterns:** seed 17 complete-class exit 2, `unknown application: :crosswake`, valid repository files missing, paths resolving under `deps/telemetry`
- **Root cause(s):** An async release evidence test called `Mix.Task.clear()` and then `app.config`, which reran `compile` during ExUnit's parallel test loading. Dependency cwd and code-path changes made unrelated tests read the wrong tree or lose application lookup.
- **Fix:** Run `Crosswake.ReleaseCandidate.EvidenceGateTest` synchronously and document its global Mix task behavior.
- **Files changed:** `test/crosswake/release_candidate/evidence_gate_test.exs`
- **Why not caught:** The global Mix task mutation had no test ownership guard; earlier single-seed runs could pass. The three-seed example-host isolation matrix caught the intermittent complete-class failure.
- **Recurrence guard:** `test/crosswake/release_candidate/evidence_gate_test.exs` declares `async: false`; required example-host isolation CI exercises tagged and complete classes at seeds 17, 101, and 1009.
---
