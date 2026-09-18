---
phase: 174-clean-room-host-realism-adopter-fidelity
plan: 03
requirement: FID-01
seed: SEED-014
date: 2026-09-18
---

# FID-01 Disposition Record

Records the decided disposition for each of SEED-014's two high-severity items, per FID-01's
schema: "closed, with a passing check demonstrating the close, or an explicit recorded deferral
reason in-repo."

## CW-REQ-A — no haptics assertion in `PhysicalIphoneContract`

- **Disposition:** `defer-with-reason`
- **Decided:** Task 1 of plan 174-03, a blocking `checkpoint:decision`.
- **Reason:** `PhysicalIphoneContract` is a closed, ordered, versioned vocabulary:
  `validate_report/1` rejects ids outside it and `join_reports/3` requires exact set equality
  including ordinal position. Adding a CW-REQ-A assertion to the contract therefore hard-rejects
  any out-of-tree producer still emitting the previous id set, and that break would land at
  publish — which is exactly what Phase 175 is. Shipping a breaking contract change inside the
  milestone whose exit criterion is proving the release pipeline would mean the release being
  proved is also the release that breaks the adopter's producer. The adopter is not blocked
  today: they already run a host-owned three-layer haptics gate, so the cost of deferring is a
  dual gate, not a missing capability.
- **Reopen trigger:** revisit CW-REQ-A once the v23.0 release pipeline has been proven
  end-to-end (i.e. after Phase 175 publishes), so the contract-vocabulary change can ship in a
  release whose pipeline is already known-good rather than in the one being proved.
- **Date:** 2026-09-18
- **Evidence of no source change:** `git diff --name-only HEAD -- lib/` is empty for the commit
  that recorded this disposition — no source file under `lib/` was touched.
- **Recorded also in:** `.planning/seeds/SEED-014-proof-lane-and-doctor-fidelity.md`, CW-REQ-A
  section, dated disposition line.

## CW-REQ-B — the runner cannot say "ran, and found a real defect"

- **Disposition:** closed
- **Evidence:** `mix test test/mix/tasks --max-cases 1` — 140 tests, 0 failures.
- **What shipped:**
  - `Mix.Tasks.Crosswake.ProofLane.PhysicalIphone.exit_status_for/1` — an explicit `case`
    classifier over known rule ids with an explicit catch-all clause. `"PI-REPORT-OUTCOME"` (the
    `join_reports/3` rule that fires only for a validated, complete, correctly-owned,
    correctly-ordered report carrying a non-passing outcome) maps to `1`. Every other known rule
    id, and the catch-all for any unrecognised one, maps to `2`.
  - `handle_result/1` — routes every one of the module's `System.halt` call sites (3 sites,
    unchanged in count before and after) through the classifier and attaches an
    `exit_classification` field (`"refuted"` / `"could_not_run"`) to the emitted JSON for every
    non-passing outcome. A passing run emits no such field and triggers no halt (implicit exit
    `0`).
  - A bug fix in `join_reports/3`: its completeness check compared the full report against the
    expected set with every entry's outcome forced to `:passed`, so a report with any non-passing
    outcome was misclassified as `PI-REPORT-COMPLETE` before the outcome rule could ever fire —
    `PI-REPORT-OUTCOME` was dead code. The completeness check now compares only `[:id, :owner]`
    positionally; a separate, pre-existing check still fires `PI-REPORT-OUTCOME` when any entry's
    outcome is not `:passed`.
  - Five separately named tests in
    `test/mix/tasks/crosswake.proof_lane.physical_iphone_test.exs`: refuted-outcome exits 1;
    no-report (bad envelope) exits 2; blocked readiness exits 2; a fully passing run halts on
    nothing; an unrecognised rule id falls through the explicit catch-all to 2.
- **Documentation:** no exit-status documentation existed anywhere in the repo for this task
  before this change (checked `guides/`, `docs/`, and repo-root `*.md`). Created one: a
  `@moduledoc` on `Mix.Tasks.Crosswake.ProofLane.PhysicalIphone` stating the full 0/1/2 contract
  and noting it is unrelated to `Crosswake.ReleaseStatus`'s distinct exit `3` (Phase 169).
- **Date:** 2026-09-18
- **Recorded also in:** `.planning/seeds/SEED-014-proof-lane-and-doctor-fidelity.md`, CW-REQ-B
  section, dated disposition line.
