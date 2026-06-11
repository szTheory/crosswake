# Phase 100: Storage Budget Enforcement - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-11
**Phase:** 100-Storage Budget Enforcement
**Areas discussed:** Budget Format (Elixir), Pre-eviction Warning (UI), Write Failure Fallback (JS)

---

## Budget Format (Elixir)

| Option | Description | Selected |
|--------|-------------|----------|
| Integer bytes | e.g. 50_000_000 | ✓ |
| Human-readable string | e.g. "50MB" | |
| Tuple | e.g. {:mb, 50} | |

**User's choice:** Synthesized by agent per user request for an optimal, cohesive recommendation based on ecosystem idioms.
**Notes:** Decided on integer bytes for the internal contract struct to match JS APIs exactly (no parsing overhead), while recommending the developer-facing generator/API accept tuples/strings for DX, parsing them before storing.

---

## Pre-eviction Warning (UI)

| Option | Description | Selected |
|--------|-------------|----------|
| Persistent banner | Show non-intrusive warning when near limits | ✓ |
| Blocking modal | Force user to acknowledge limits | |

**User's choice:** Synthesized by agent.
**Notes:** Matches the Crosswake Brand Book's emphasis on "calm, specific, actionable" and "no drama" microcopy. A banner alerts the user to `navigator.storage.estimate()` limits without breaking their flow.

---

## Write Failure Fallback (JS)

| Option | Description | Selected |
|--------|-------------|----------|
| Graceful Read-only mode | Catch QuotaExceededError and disable saves | ✓ |
| Force-abort session | Crash/abort offline session entirely | |

**User's choice:** Synthesized by agent.
**Notes:** Provides the best UX by honoring "local when useful." Users can finish reading the cached content instead of being thrown back to a blank/online-only state just because a `.put()` failed.

---

## Claude's Discretion

The exact math/threshold for "near limits" (e.g. 90% full or 5MB remaining) for the pre-eviction warning banner.

## Deferred Ideas

None