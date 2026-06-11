# Requirements: Crosswake — v8.0 Offline Sync Hardening and UI Polish

**Defined:** 2026-06-11
**Core Value:** Hardening the v6.0 offline-sync capabilities by enforcing real network-toggling E2E tests, implementing advisory runtime storage budgets without heavy dependencies, and delivering a consolidated, brand-aligned `OfflineController` UI.
**North star:** `.planning/research/SUMMARY.md`

## v1 Requirements (v8.0)

### Real Network-Toggling E2E (SYNC)

- [ ] **SYNC-01**: Playwright E2E tests for the offline study island use actual network toggling (`page.context().setOffline(true)`) rather than faking `localStorage` behavior.
- [x] **SYNC-02**: The E2E tests assert the complete reconciliation loop: storing records offline in IndexedDB, coming back online, and verifying Ecto state accurately reflects the sync payload.
- [x] **SYNC-03**: The E2E Playwright configuration handles `localhost` explicitly, ensuring service workers do not leak requests masking test results.

### Offline Controller Consolidation (OFFC)

- [ ] **OFFC-01**: A `mix crosswake.gen.offline_ui` generator scaffolds a host-owned `OfflineController` and `.html.heex` template to serve the vanilla-JS offline island.
- [ ] **OFFC-02**: The generated Offline UI explicitly disconnects from the LiveView websocket lifecycle, preventing runtime errors when entirely offline.

### Storage Budget Enforcement (BDGT)

- [ ] **BDGT-01**: `Crosswake.Offline.Contracts.StudySessionIsland` exposes an explicit `:storage_budget` attribute for offline cache boundaries.
- [ ] **BDGT-02**: Runtime JavaScript checks `navigator.storage.estimate()` before downloading or unpacking new `ContentPack`s, advising the user of impending eviction before browser quotas are exceeded.
- [ ] **BDGT-03**: JS IndexedDB `put()` operations are wrapped in `try/catch` to elegantly handle OS-level `QuotaExceededError` occurrences, surfacing standard UI warnings.

### Brand Book UI Polish (BRND)

- [ ] **BRND-01**: The generated offline UI applies the Crosswake Brand Book design tokens natively via Tailwind (e.g., Wake Green, Brass) without bundling heavy JS frameworks like React or Alpine.
- [ ] **BRND-02**: The offline UI implements explicit, honest microcopy (e.g., "Available offline", "Pending server confirmation", "Draft only", "Cached read-only") for all states rather than relying on ambiguous color signals.

## v2 / Future Requirements (deferred, tracked)

### Native Disk Quotas (NTV)
- **NTV-01**: Extend storage budgets to utilize native iOS/Android bridge commands to calculate available physical disk space instead of relying solely on browser heuristics.

### Dashboard Storage Metrics (DASH)
- **DASH-01**: Surfacing offline adoption and eviction metrics to the deferred `crosswake_dashboard`.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Deep offline sync abstraction (universal CRDTs) | Out of scope. Crosswake favors explicit local-first patterns, journals, and outboxes over magic universal sync frameworks. |
| Toxiproxy or heavy external E2E proxy setups | Too much CI complexity; Playwright CDP fulfills requirements. |
| React/Alpine or other heavy JS frameworks for offline UI | Violates the lightweight "vanilla-JS island" philosophy. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| SYNC-01 | Phase 99 | Pending |
| SYNC-02 | Phase 99 | Complete |
| SYNC-03 | Phase 99 | Complete |
| OFFC-01 | Phase 101 | Pending |
| OFFC-02 | Phase 101 | Pending |
| BDGT-01 | Phase 100 | Pending |
| BDGT-02 | Phase 100 | Pending |
| BDGT-03 | Phase 100 | Pending |
| BRND-01 | Phase 101 | Pending |
| BRND-02 | Phase 101 | Pending |

---
*Requirements defined: 2026-06-11*
