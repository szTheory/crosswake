# Phase 23 — Deferred Items

Out-of-scope items discovered during execution; logged here per the GSD executor SCOPE BOUNDARY rule (`agents/gsd-executor.md` deviation rules) and intentionally not fixed in this phase.

## From Plan 23-02 execution (2026-05-27)

### 1. `test/mix/tasks/crosswake_doctor_test.exs` — `mix crosswake.doctor json output serializes commerce corridor fields`

- **Status:** Pre-existing failure at base ref `e7afa70` (verified by checking out base ref and rerunning the test).
- **Cause:** The test asserts every JSON finding whose `code` starts with `commerce.corridor.` has top-level keys `corridor_ref`, `role`, `denial_code`, `fallback_hint`. The new `commerce_summary` `commerce.corridor.native_rebuild_required` finding introduced in Plan 23-01 carries those fields only inside `details`, not at top level.
- **Owner:** Likely Plan 23-03 or 23-04 (downstream consumer of the commerce_summary surface — depends on whether the test contract is the desired surface or whether the new finding's schema should match the older contract).
- **Recommendation:** Either widen the JSON formatter to lift the relevant keys to top level for `commerce_summary` findings, or update this test to scope its top-level-key assertion to checks of `commerce_corridor` (not `commerce_summary`).

### 2. `test/crosswake/proof/phase{5,7,8,9}_*_test.exs` — 15 proof-lane failures

- **Status:** Pre-existing failure at base ref `e7afa70` (verified).
- **Cause:** All failures share `(UndefinedFunctionError) function CrosswakeExample.Router.__routes__/0 is undefined (module CrosswakeExample.Router is not available)`. The example-host router module is not on the compiled path inside `mix test` for the library itself.
- **Owner:** Not in scope for Phase 23. These are example-host proof lanes that historically run via the example-host verification scripts (`script/verify_phase5_example_hosts.sh`), not from the library's `mix test`.
- **Recommendation:** Either skip in library `mix test` runs (tag them `:proof` and exclude by default), or ensure the example host is compiled into the path before running. Out of scope here.
