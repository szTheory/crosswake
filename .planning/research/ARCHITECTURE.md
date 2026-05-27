# Project Research: Architecture For v3.2 Commerce And Entitlement Seams

**Milestone:** v3.2 Commerce And Entitlement Seams
**Date:** 2026-05-27

## Existing Architecture

Crosswake already provides:

- route policy and manifest truth
- support matrix and doctor output
- bounded bridge capability registry
- native-screen declaration and activation contracts
- Phase 13 commerce contract modules and public guides
- v3.1 low-frequency bridge capability proof lanes

The next architecture increment should connect commerce vocabulary to runtime ownership and support truth without adding provider SDKs to core.

## Proposed Flow

1. Phoenix route declares a commerce corridor and required commerce capability family.
2. Phoenix renders paywall/account state from backend-owned data.
3. User action emits `purchase_intent` or `restore_intent`.
4. If the route remains Phoenix-owned, Crosswake may only issue a low-frequency semantic trigger into an explicit native/companion corridor.
5. Native or provider code returns bounded `reconciliation_evidence`.
6. Phoenix persists evidence in one host-owned reconciliation inbox.
7. Host-owned workers verify against Apple/Google/provider APIs.
8. Phoenix projects one authoritative `entitlement_snapshot`.
9. Crosswake consumers refresh against the snapshot, not device callback success.

## Integration Points

| Area | New or changed surface |
|------|------------------------|
| Route policy | Commerce corridor declarations, native-screen default rules for storefront-sensitive flows |
| Manifest | Commerce route and capability prerequisite truth |
| Commerce contracts | Snapshot/evidence vocabulary may need richer lifecycle fields |
| Doctor | Missing backend behaviour, missing adapter, unsupported route corridor, stale support matrix |
| Support matrix | Platform/provider proof classification and native rebuild posture |
| Example host | Minimal Phoenix-owned reconciliation projection and denied/fallback states |
| Native shells | Advisory or stub corridor proof only unless companion adapter work is explicitly in scope |

## Build Order

1. Freeze v3.2 commerce gates and scope so Phase 13 vocabulary is treated as prior art.
2. Expand core contract and route policy around commerce corridors.
3. Add host-owned reconciliation example and entitlement projection proof.
4. Add doctor/support-matrix/reviewer guidance.
5. Add final proof lane and update public docs.

## Architecture Risks

- Treating native purchase success as access authority would break the thesis.
- Adding StoreKit/Play Billing implementation to core would bypass the packaging ledger.
- Modeling commerce as a bridge command family rather than a backend seam would blur route ownership.
- Failing to prove denial/fallback states would make support claims aspirational.
