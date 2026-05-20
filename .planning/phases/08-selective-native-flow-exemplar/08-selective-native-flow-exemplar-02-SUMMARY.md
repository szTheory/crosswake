---
phase: 08-selective-native-flow-exemplar
plan: 02
subsystem: selective-native-flow
requirements-completed: [NATIVE-01, NATIVE-02]
completed: 2026-05-18
---

# Phase 8 - Plan 02 Summary

## Objective Completed
Implemented the product-shaped selective-native flow on top of the Phase 8 lane skeleton.

## Tasks Completed
1. **Built the Phoenix-owned queue, detail, and review surfaces**: Implemented Phoenix-owned LiveViews for `claims`, `claim` detail, and `submission_review`. The flow explicitly uses claim detail as the jump-off point to native capture, and review as the location for inspection before upload. Distinct data states ("staged", "uploaded") are preserved in UI copy and interactions.
2. **Moved native capture onto the nested route with route-local pack and transfer seams**: Removed the old top-level `/camera` route and recontextualized the capture step onto `/native/claims/:id/capture`. Updated the router so this capture route alone declares the `:camera` capability, the required media pack, native screen runtime ownership, and the `transfer.upload.prepare` seam. Proof tests were updated and pass, verifying the single native route constraint.

## Output
- The `examples/phoenix_host/lib/crosswake_example/router.ex` configures the selective-native capture correctly, without spreading capabilities to surrounding routes.
- LiveViews `ClaimsLive`, `ClaimLive`, `ClaimCaptureLive`, and `SubmissionReviewLive` implemented.
- Added specific tests checking that the capture route includes exactly `[:camera]` capabilities, required packs, and upload intent transfers.
