# Crosswake v6.0 Requirements

## Context

The strategic focus for this milestone is building the **Adoption Evidence Demo App (Flashcard Cohort)**. We are building a "bombproof" language learning/flashcard application to rigorously stress-test the `Crosswake.Offline` and `Crosswake.Sync` surfaces. This validates the "Offline Island" architecture where complex local logic (a study scheduler) runs independently while disconnected, utilizing IndexedDB and local media caching, and syncs via Ecto-backed event logs upon reconnection.

## Requirements

### Offline Substrate (`Crosswake.Offline`)
- **OFF-01** `Crosswake.Offline` provides a documented `ContentPack` standard for bundling assets and data required by an Offline Island.
- **OFF-02** `Crosswake.Offline` defines storage budgets and cleanup policies for offline data.

### Sync Substrate (`Crosswake.Sync`)
- **SYNC-01** `Crosswake.Sync` provides an `EventLog` and durable mutation queues for recording offline actions.
- **SYNC-02** `Crosswake.Sync` supports Ecto-backed reconciliation upon network reconnection.

### Demo Application (Flashcard Cohort)
- **DEMO-01** A Language Learning / Flashcard app is implemented as the exemplar for the "Offline Island" philosophy.
- **DEMO-02** The demo app correctly transitions from online LiveView (deck selection) to offline Javascript-based study session.
- **DEMO-03** The demo app aligns with the Crosswake Brand Book for aesthetics, microcopy, and accessible UI, prioritizing a best-in-class developer and user experience.

### Proof Posture (Shift-Left CI/CD)
- **PROOF-01** Network-toggled E2E tests (e.g., Playwright/Maestro) confirm study session completion without network connectivity.
- **PROOF-02** Reconnection state synchronization is verified at the database level by E2E tests.

## Out of Scope
- Full "write-once-run-anywhere" cross-platform UI.
- Native rendering of LiveView components.
- Expanding auth beyond the current scope needed for the demo app.
