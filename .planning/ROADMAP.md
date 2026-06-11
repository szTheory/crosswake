# Roadmap: Crosswake

## Phases

- [ ] **Phase 99: Real Network-Toggling E2E Tests** - Verify offline sync loop via browser network toggling
- [ ] **Phase 100: Storage Budget Enforcement** - Enforce and handle storage quotas gracefully
- [ ] **Phase 101: Offline UI Consolidation & Polish** - Generate a brand-aligned, host-owned offline controller

## Phase Details

### Phase 99: Real Network-Toggling E2E Tests
**Goal**: The offline sync reconciliation loop is verified via realistic browser network toggling rather than mocked localStorage.
**Depends on**: Nothing
**Requirements**: SYNC-01, SYNC-02, SYNC-03
**Success Criteria** (what must be TRUE):
  1. E2E test suite toggles network offline using `page.context().setOffline(true)`.
  2. The E2E test suite asserts that records created while offline successfully sync to Ecto when the network reconnects.
  3. The test suite correctly bypasses or handles localhost service worker caching to ensure deterministic test runs.
**Plans**: TBD

### Phase 100: Storage Budget Enforcement
**Goal**: Offline storage limits are explicitly tracked and gracefully handled at runtime to avoid silent browser eviction.
**Depends on**: Phase 99
**Requirements**: BDGT-01, BDGT-02, BDGT-03
**Success Criteria** (what must be TRUE):
  1. The `StudySessionIsland` contract enforces an explicit `:storage_budget` parameter.
  2. The offline UI visually or programmatically warns the user before browser storage quotas are exceeded using `navigator.storage.estimate()`.
  3. The offline UI elegantly catches OS-level `QuotaExceededError` during IndexedDB writes without crashing.
**Plans**: TBD

### Phase 101: Offline UI Consolidation & Polish
**Goal**: A brand-aligned, host-owned offline UI is generated without dragging in heavy JS frameworks or LiveView websocket logic.
**Depends on**: Phase 100
**Requirements**: OFFC-01, OFFC-02, BRND-01, BRND-02
**Success Criteria** (what must be TRUE):
  1. Developers can successfully scaffold the UI using the `mix crosswake.gen.offline_ui` generator.
  2. The generated offline UI functions correctly without any LiveView websocket connection attempts.
  3. The offline UI renders with Crosswake Brand Book tokens (e.g., Wake Green) using only HTML and Tailwind.
  4. The UI displays explicit microcopy (e.g., "Available offline", "Pending server confirmation") based on current sync state.
**Plans**: TBD
**UI hint**: yes

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 99. Real Network-Toggling E2E Tests | 0/TBD | Not started | - |
| 100. Storage Budget Enforcement | 0/TBD | Not started | - |
| 101. Offline UI Consolidation & Polish | 0/TBD | Not started | - |
