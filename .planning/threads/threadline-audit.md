# Threadline Audit Capstone

**Context:** Evaluated 2026-06-05 post-v4.1.
**Status:** RESOLVED by v7.0 — historical thread retained for evidence; future visual operator surface is deferred to DASH-01 `crosswake_dashboard`.

Crosswake has solved the structural problem of routing Elixir to native mobile shells and has proven this across all major SaaS archetypes (commerce, notifications, auth, media, offline). 

The critical missing piece is day-2 operational viability. A unified "Threadline"—a distributed correlation ID and audit trail spanning the native shell, bridge, Phoenix router, and DB—is required to make the split-brain state machines supportable in production.

## The Approach
1. **Telemetry & Logger Metadata:** Intercept `X-Crosswake-Thread-Id` at the plug layer (`Crosswake.Plug.Threadline`). Inject it into Logger metadata and emit rich Telemetry spans at every boundary crossing (manifest syncs, commerce validation, step-ups). This avoids database bloat.
2. **Opt-in Ecto Ledger:** Provide an opt-in `mix crosswake.gen.audit` generator for critical state boundaries (auth handoffs, commerce receipts).
3. **Operator UX:** Consider a LiveDashboard plugin so operators can search a user ID and see the exact sequence of Native -> Bridge -> Server events in a single view.

This is a foundational wedge. It is not diminishing returns.
