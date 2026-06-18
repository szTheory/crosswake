# Crosswake Adoption Guide: Flashcard Demo App Architecture

This guide details the architecture of the Flashcard Demo App and provides step-by-step instructions for adopting the Crosswake offline-sync architecture in your own projects.

> For the definitive install sequence, see [guides/install.md](install.md).

## Architecture Overview

The demo app demonstrates the `Crosswake.Offline` island philosophy. It is built as a Language Learning / Flashcard app, intentionally chosen to rigorously stress-test offline scenarios and eventual consistency.

### Key Components:

1.  **Phoenix Host (Backend)**: Uses Ecto to manage the truth state of the application.
2.  **Crosswake Native Shell (Frontend)**: standalone SPM/Maven dependencies injected into the iOS/Android apps.
3.  **App-owned offline island**: The current verified proof uses island JavaScript, IndexedDB outbox storage, reconnect-triggered `flushOutbox`, `/study/sync`, and Phoenix/Ecto reconciliation. The bridge is not the offline mutation authority.

## Adopting the Offline-Sync Architecture

To implement this architecture in your own app, follow these steps:

### 1. Integrate the Crosswake Shell

Generate the shell as a thin, host-owned wrapper that your team reviews and owns after scaffolding. Its native dependencies resolve from published registries — SwiftPM `github.com/szTheory/crosswake-shell-core-ios` for iOS and Maven Central `io.github.sztheory:crosswake-shell-core-android` for Android — rather than vendored or monorepo-local paths. The "eject trap" is eliminated by publishing the reusable core logic as package-manager dependencies, not by avoiding the generator.

### 2. Configure Offline Mutations

Current verified proof is app-owned IndexedDB outbox plus reconnect-triggered
Phoenix/Ecto reconciliation. The full adoption rewrite is owned by Phase 118;
until then, do not treat the bridge as a mutation queue or sync engine.

### 3. Handle Sync Reconnection

Ensure your Phoenix host's endpoints can receive and validate batched offline payloads. The backend must enforce sync state validation post-reconnection to reject invalid operations (tampering mitigation).

When the client reconnects:
1.  The client transmits the offline mutation log.
2.  The Ecto sync endpoint processes the log.
3.  The client receives confirmation and updates its local state.

### 4. End-to-End Verification

Implement network-toggling E2E tests (like Playwright) in your CI/CD pipeline to simulate offline states and explicitly assert that your truth state is synchronized post-reconnect.
