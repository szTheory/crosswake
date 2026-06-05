# Phase 74: Offline/Draft Recovery Proof - Research

**Researched:** 2025-01-20
**Domain:** Offline Route Enforcement, Local-First Sync, Hermetic Validation
**Confidence:** HIGH

## Summary
Crosswake intentionally restricts offline functionality to specific boundaries to avoid the pitfalls of a "universal sync" engine. Routes are distinctly categorized via the policy compiler as `:unavailable`, `:cached_read_only`, or `:local_first`. `:live_view` routes cannot claim `:local_first` support. 

To fulfill OFF-01 and OFF-02, this phase requires creating a Phase Proof (similar to Phase 70's commerce proof). The proof must interact with the `local_first` examples (e.g., `CrosswakeExample.LocalFirst.Study`, `SyncController`) and the Crosswake compiler logic to verify that draft recovery behaves as a localized mutation (offline island) while respecting degraded read-only caching for other application areas.

**Primary recommendation:** Implement an ExUnit proof in `test/crosswake/proof/phase74_offline_draft_recovery_proof_test.exs` that tests draft ingestion mechanisms, and verifies Crosswake compiler constraints rejecting `:local_first` on `:live_view` routes.

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| OFF-01 | Prove an offline/draft recovery workflow, enforcing explicit `:cached_read_only` and `:local_first` offline policies. | Assert `Crosswake.Policy.Compiler` validation logic enforces these boundaries, preventing bleed between the two. |
| OFF-02 | Stay honest about local-first limits, rejecting generic universal sync claims and verifying degraded caching behavior. | Prove that `:live_view` is forcefully rejected by the compiler if marked `:local_first`. |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Offline Boundary Enforcement | Backend Compiler | Manifest JSON | Crosswake compiler rejects local_first on live_view routes, guaranteeing shell client compliance |
| Study Session Draft Ingestion | API / Backend | Offline Island Client | Client device journals work locally; `SyncController` reconciles it when online. |
| Degraded History caching | Client / Manifest | Backend (LiveView) | Client serves cached reads; backend remains completely unaware of offline client states. |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| ExUnit | ~> 1.15 | Proof execution | Standard Elixir test framework in this project |
| Ecto | ~> 3.10 | Draft mutation parsing | Core to Elixir data transformation and used in `ReviewEvent` |

## Environment Availability

Step 2.6: SKIPPED (no external dependencies identified, Elixir codebase only)

## Architecture Patterns

### Recommended Project Structure
```text
test/crosswake/proof/
└── phase74_offline_draft_recovery_proof_test.exs
examples/phoenix_host/lib/crosswake_example/local_first/
├── study.ex
├── study_session_live.ex
└── sync_controller.ex
```

### Pattern 1: Offline Island Route Definition
**What:** Declaring exactly one localized flow as a true offline island, rather than trying to support offline everywhere.
**When to use:** When users need robust local offline work capabilities on a specific workflow.
**Example:**
```elixir
# In a Crosswake Policy Ex module
route "/study-session",
  runtime: :offline_island,
  offline: :local_first
  
route "/study-history",
  runtime: :live_view,
  offline: :cached_read_only
```

### Anti-Patterns to Avoid
- **Generic Universal Sync:** Avoid simulating an app-wide CRDT or state synchronization engine. The design relies on specific controllers (`SyncController`) taking in explicit grouped events from localized islands.
- **Bleeding Limits:** Trying to apply `local_first` to standard `:live_view` routes. This destroys the mental model of having clearly defined boundaries for native apps wrapping a Phoenix server.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Application-wide Offline state | Universal sync layer | Route-local Offline Policies | Most Phoenix applications are heavily server-reliant; trying to make a LiveView app entirely local-first creates unmaintainable complexity. Restrict offline features to strictly isolated offline islands. |

## Common Pitfalls

### Pitfall 1: Leaking `local_first` into `live_view`
**What goes wrong:** A developer tries to mark a `live_view` route as `:local_first`.
**Why it happens:** Misunderstanding the scope. Hoping for offline writes without building a native/island UI.
**How to avoid:** The proof test must explicitly assert that `Crosswake.Policy.Compiler` rejects `runtime: :live_view` paired with `offline: :local_first`.

### Pitfall 2: Heavy Database Coupling in the Proof Test
**What goes wrong:** The proof fails due to needing a running `Repo` or database sandbox while importing `examples/phoenix_host/lib/crosswake_example/local_first/study.ex`.
**Why it happens:** The example modules (like `Study.ex`) perform `Repo.transaction` during their sync function, but Proof tests typically run unit-level validations.
**How to avoid:** Verify compiler constraints at a pure level. When verifying the `SyncController` or `Study` logic, either utilize a mock backend, or structure the test carefully using ExUnit's Sandbox if required by the test's scope. 

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit |
| Config file | none — see Wave 0 |
| Quick run command | `mix test test/crosswake/proof/phase74_offline_draft_recovery_proof_test.exs` |
| Full suite command | `mix test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| OFF-01 | Accepts isolated offline/draft sync mutations and enforces policies | unit | `mix test test/crosswake/proof/phase74_offline_draft_recovery_proof_test.exs` | ❌ Wave 0 |
| OFF-02 | Rejects `:local_first` on `:live_view` routes | unit | `mix test test/crosswake/proof/phase74_offline_draft_recovery_proof_test.exs` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `mix test test/crosswake/proof/phase74_offline_draft_recovery_proof_test.exs`
- **Per wave merge:** `mix test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `test/crosswake/proof/phase74_offline_draft_recovery_proof_test.exs` — covers OFF-01 and OFF-02

## Sources
### Primary (HIGH confidence)
- `guides/offline.md` - Crosswake offline limits documentation
- `lib/crosswake/policy/validator.ex` - Enforcement of route/offline pairing
- `examples/phoenix_host/lib/crosswake_example/local_first/study.ex` - Isolated sync implementation

## Metadata
**Confidence breakdown:**
- Standard stack: HIGH - ExUnit is standard for Crosswake phase proofs.
- Architecture: HIGH - Crosswake compiler constraints govern `offline` behavior, enforced heavily across `lib/crosswake/policy`.
- Pitfalls: HIGH - Validated directly from `guides/offline.md` boundaries.

**Research date:** 2025-01-20
**Valid until:** 30 days
