# Phase 10 Context: Cross-Profile Hardening, Proof, And Guidance

## Goal
Crosswake hardens the core and support posture based on the pressure revealed by the three exemplar profiles (Phases 7, 8, and 9). This phase is about locking the contract for v1.0, not expanding it.

## Key Architectural Decisions

These decisions were reached via deep research against Elixir OSS DNA, Crosswake's brand identity, and ecosystem lessons (React Native, LiveView Native, Capacitor):

### 1. Isolated Proof Lanes (Install Truth = Product Truth)
Proof lanes will be **isolated, per-profile verification scripts**. 
We will not build a monolithic "kitchen sink" test app. Instead, we will use hermetic scripts (e.g., `script/verify_saas_profile.sh`, `script/verify_local_first.sh`) that generate a clean Phoenix host, install Crosswake, configure the specific route policy for that profile, and prove the boundary. This perfectly mirrors the adopter's "first hour" experience.

### 2. Native Compilation Strategy
We will **compile native shells only for a single flagship "example host."**
To avoid CI combinatorial explosion and preserve maintainer sanity, we will aggressively unit test the manifest and code generation for *all* adopter profiles using Elixir `ExUnit` tests. However, we will configure one merge-blocking CI lane that executes a full `xcodebuild` and `./gradlew build` strictly against a flagship `examples/` host app to prove the core native boundary (the bridge and manifest loading) is structurally sound.

### 3. The "Honest Boundary" Documentation Hybrid
We will not maintain a centralized `ROUGH_EDGES.md` graveyard. Instead, we use a hybrid approach:
*   **Localized Prose:** Every feature guide will have a dedicated **"Boundary Warnings & Rough Edges"** section at the bottom, providing nuanced prose exactly where the developer is looking during implementation.
*   **Generated Matrix:** We will maintain a `Crosswake.SupportMatrix` module that generates a high-level `guides/support_matrix.md` dashboard for evaluating tech leads. This matrix will not contain nuanced prose, but will link directly to the localized Boundary Warnings in the guides.

### 4. Strict Stabilization Scope (No API Expansion)
Phase 10 is a **Contract Locking Phase**.
If the exemplars (Phases 7-9) expose architectural gaps, those gaps represent the *exact* boundaries of the v1.0 substrate. We will not expand the Elixir API or bloat the `RoutePolicy` DSL to paper over them. 
Instead, we will:
*   Upgrade `mix crosswake.doctor` to catch these failure states and warn loudly.
*   Document the gaps as explicit boundaries in the guides.
*   Ensure the proof lanes validate the fallback to native escape hatches.
*   "Public contract honesty beats breadth."
