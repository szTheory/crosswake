# Phase 77: Reactive State & API Standardization - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-05
**Phase:** 77-Reactive State & API Standardization
**Areas discussed:** Initialization Shape, Android State Flow, Capability Delegation

---

## Initialization Shape

| Option | Description | Selected |
|--------|-------------|----------|
| Global Singleton | `CrosswakeShell.initialize()` singleton for easier access | |
| Scoped Instance | Return a scoped instance for better testability | ✓ |

**User's choice:** Scoped Instance
**Notes:** Approved AI's recommendation to use explicit scoped instances to map to Elixir processes/supervision trees, avoiding hidden global state and the "eject trap".

---

## Android State Flow

| Option | Description | Selected |
|--------|-------------|----------|
| Individual Properties | State exposed as individual `StateFlow` properties | |
| Bundled Data Class | State bundled into a single `ShellState` data class | ✓ |

**User's choice:** Bundled Data Class
**Notes:** Approved AI's recommendation to mimic LiveView's `socket.assigns` and provide atomic state updates to prevent "state tearing".

---

## Capability Delegation

| Option | Description | Selected |
|--------|-------------|----------|
| Lambda Injections | Continue using lambda injections (e.g. `hapticsHandler: (String) -> Void`) | |
| Protocol/Interface Delegates | Switch to narrow `HapticsDelegate` interfaces | ✓ |

**User's choice:** Narrow Protocol/Interface Delegates
**Notes:** Approved AI's recommendation to align with Elixir `Behaviours` and support deterministic capability negotiation at shell startup.

---

## Deferred Ideas

- Updates to the `mix crosswake.gen.shell` generator.
- E2E CI proof workflows.
