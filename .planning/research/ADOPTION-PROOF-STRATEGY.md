# Adoption Evidence Demo App Strategy

## Synthesis of User Prompt & Existing Research
The user requested a milestone focused on "core functionality" proving that the "guts of it works 100% with great DX" through "real adoption proof". The user specifically mentioned wanting "real apps (each with their own realistic brand within the context of a realistic 'cohort' app...)" and wants to stress-test "offline mode support all of that on the happy path and intermediate/advanced use cases." 

The goal is to shift-left CI/CD and create a "bombproof" demo app.

## Cohort Analysis

1. **Health/Fitness App**
   - *Pros*: Good use of offline syncing for workouts. Brand guidelines map well.
   - *Cons*: Syncing a workout log is standard, but doesn't necessarily stress a complex UI in an offline state (usually just a timer and a save button).

2. **Field Service App**
   - *Pros*: Classic offline-first use case. Requires syncing complex datasets (work orders, forms).
   - *Cons*: Visually less engaging for a demo. High complexity in form building might distract from Crosswake's core value.

3. **Language Learning / Flashcard App**
   - *Pros*: Perfect fit for the "Offline Island" philosophy. Users download a "Content Pack" (deck of cards, audio, images), disconnect, run a highly interactive local JS/IndexedDB study session (spaced repetition scheduler), and upon reconnection, sync their progress events back to the server.
   - *Cons*: Requires building a local JS scheduler.

## Recommendation

We strongly recommend building the **Language Learning / Flashcard App**. 

It perfectly aligns with the requirement to stress-test the library making it "bombproof" for offline mode. It forces us to build and prove `Crosswake.Offline` (manifest generation, storage budgets, content packs) and `Crosswake.Sync` (event logs, durable mutation queues, Ecto-backed reconciliation). It demonstrates exactly why Crosswake's "per-route runtime ownership" is superior: the deck selection is LiveView (online), but the actual study loop is an Offline Island running locally without WebSocket dependency.

## Milestone Goals
1. **Ship `Crosswake.Offline`:** Implement Content Packs, Manifest Generation, and Storage Budgets.
2. **Ship `Crosswake.Sync`:** Implement durable Event Logs, Mutation Queues, and Ecto-backed Reconciliation.
3. **Build the Flashcard Cohort App:** Create a polished, brand-aligned demo app utilizing LiveView (online) and an Offline Island (study loop).
4. **Shift-Left CI/CD Verification:** Implement automated E2E tests (Playwright/Maestro) that physically disconnect the network, complete a study session, reconnect, and verify Ecto state.