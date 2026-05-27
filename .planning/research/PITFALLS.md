# Project Research: Pitfalls For v3.2 Commerce And Entitlement Seams

**Milestone:** v3.2 Commerce And Entitlement Seams
**Date:** 2026-05-27

## Pitfalls

### Repeating Phase 13 Instead Of Advancing It

Phase 13 already defined the normalized commerce vocabulary and guides. v3.2 should operationalize the seam with route declarations, richer lifecycle semantics, examples, support truth, and proof.

Prevention: Treat `paywall_entry`, `purchase_intent`, `restore_intent`, `entitlement_snapshot`, and `reconciliation_evidence` as existing substrate.

### Device Success Becomes Entitlement Truth

StoreKit and Play Billing both provide native-side purchase signals, but permanent entitlement decisions should be verified and projected by the backend.

Prevention: Contract tests must prove device/provider evidence feeds reconciliation and cannot directly flip access truth.

### Provider Details Leak Into Core

Provider states are real and nuanced, but core should not expose raw StoreKit, Play Billing, or provider SDK enums as route-policy vocabulary.

Prevention: Map provider details into Crosswake-owned normalized lifecycle states at the seam boundary.

### Native Corridor Hidden Behind WebView Fallback

Digital purchase flows can require platform storefront UI, restore affordances, review notes, and native SDK behaviour. Silent web fallback is not honest support.

Prevention: Route policy and support docs must name native-screen or companion prerequisites and fail closed when missing.

### Review And Sandbox Work Is Treated As Cleanup

Commerce claims are policy-sensitive. App review notes, sandbox setup, restore paths, and test-account guidance are product surface.

Prevention: Include reviewer/storefront guidance in requirements and roadmap, with docs tests where possible.

### Proof Claims Outrun Environment Truth

Hermetic contract tests can prove semantics, but real StoreKit/Play Billing flows need simulator/device/storefront environments.

Prevention: Separate merge-blocking contract proof from advisory provider/storefront proof lanes.
