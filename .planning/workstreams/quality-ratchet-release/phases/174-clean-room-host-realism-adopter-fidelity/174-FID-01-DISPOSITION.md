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

<!-- CW-REQ-B section added by Task 3 of plan 174-03. -->
