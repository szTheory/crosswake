# v6.0 Roadmap: Adoption Evidence Demo App (Flashcard Cohort)

## Arc Structure
This milestone (v6.0) spans from Phase 84 through Phase 90.

## Phase 84: Offline Substrate Foundation
**Goal:** Define `Crosswake.Offline.ContentPack`, manifest generation, and offline route policy.
- [ ] Requirements: OFF-01
- [ ] Create `Crosswake.Offline.ContentPack` struct and behaviors.
- [ ] Update route policy definitions for offline support.

## Phase 85: Sync & Event Log Foundation
**Goal:** Define `Crosswake.Sync.EventLog`, idempotency keys, and server-side reconciliation endpoints.
- [ ] Requirements: SYNC-01, SYNC-02
- [ ] Implement `Crosswake.Sync.EventLog`.
- [ ] Create Ecto-backed reconciliation endpoint template.

## Phase 86: Flashcard Domain Setup (Demo App)
**Goal:** Scaffold the demo app, Phoenix context, Ecto schemas (Cards, Decks, Progress), and seeds.
- [ ] Requirements: DEMO-01
- [ ] Generate Phoenix core context for Flashcards.
- [ ] Create robust seeds for demo cohort.

## Phase 87: Online LiveView & Architecture
**Goal:** Build the online dashboard, course selection, and "Download Pack" UI.
- [ ] Requirements: DEMO-01, DEMO-03
- [ ] Create LiveView dashboard for deck management.
- [ ] Implement Brand Book styling for online routes.

## Phase 88: Offline Island & Local Engine
**Goal:** Implement the JS-based offline study island, IndexedDB storage, local scheduler, and event queuing.
- [ ] Requirements: DEMO-02, OFF-02
- [ ] Build offline study loop in vanilla JS / lightweight client code.
- [ ] Wire up IndexedDB caching and mutation queue.

## Phase 89: E2E Integration & UI Polish
**Goal:** Connect the offline island to the native shell, apply Brand Book CSS/UI guidelines, and polish animations/microcopy.
- [ ] Requirements: DEMO-03
- [ ] Polish UI transitions.
- [ ] Integrate closely with v5.0 standalone shell configurations.

## Phase 90: Shift-Left CI/CD & Closeout
**Goal:** Implement network-toggling E2E tests proving the offline study loop, write adoption guides, and close out the milestone.
- [ ] Requirements: PROOF-01, PROOF-02
- [ ] Write Playwright tests with network toggling.
- [ ] Assert Ecto sync state post-reconnect.
- [ ] Complete v6.0 Closeout gate.