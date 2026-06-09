# Phase 92: Server Propagation — Plug + LiveView - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-09
**Phase:** 92-server-propagation-plug-liveview
**Mode:** advisor (`minimal_decisive` tier, opinionated profile) — parallel sonnet research per area, single decisive recommendation each
**Areas discussed:** Request span lifecycle, LiveView on_mount parity, Zero-dep UUID minting, Response-header echo & opts

---

## Request span lifecycle (the Plug)

| Option | Description | Selected |
|--------|-------------|----------|
| `:start` + `register_before_send` (Plug.Telemetry idiom), local `try/rescue` for own-work `:exception` | Emit `:start` in `call/2`, stash monotonic time, `register_before_send` emits `:stop` with real duration; `:exception` scoped to plug's own minting | ✓ |
| Literal `:telemetry.span/3` wrapping the plug body | Auto-emits the triplet but `:stop` fires at ~µs (before response sent) — dishonest duration | |

**User's choice:** Create context (accepted recommendation).
**Notes:** D-07's "span/3 triplet" reconciled as event-name *shape*, not a literal `span/3` call. `:exception` honestly scoped to own-plug failures only — a function plug cannot catch downstream raises (those unwind past `register_before_send`); `Phoenix.Router` owns `[:phoenix, :router_dispatch, :exception]`. Flagged the boundary for an inline comment + the Phase 96 guide.

---

## LiveView on_mount parity

| Option | Description | Selected |
|--------|-------------|----------|
| Read-only, metadata-only, no telemetry | Guard `connected?/1`, read `_crosswake_thread_id` connect param, set `Logger.metadata`; absent param → `{:cont, socket}` no-op | ✓ |
| Mint-on-absent (parity with Plug) | Generate a UUID fallback when connect param missing | |

**User's choice:** Create context (accepted recommendation).
**Notes:** Plug is the sole mint authority (PROP-01); minting in `on_mount` would create a phantom thread_id divorced from the Plug-minted id. PROP-03 says "reads," not "reads or mints." No mount telemetry event declared (D-08). Absence valid until Phase 93 supplies the connect param.

---

## Zero-dep UUID minting

| Option | Description | Selected |
|--------|-------------|----------|
| Hand-rolled RFC-4122 v4 in shared `Crosswake.Threadline.Id` | `:crypto.strong_rand_bytes(16)` + version/variant bits + hex format (~12 LOC) | ✓ |
| Reuse a transitive UUID generator | None exists — Plug.RequestId's is private+non-UUID; PLV's is a `defp` we don't own | |

**User's choice:** Create context (accepted recommendation).
**Notes:** Verified against Plug 1.19 / LiveView 1.1 source — no public UUID in the transitive graph. Hand-rolled is the only honest zero-dep path; satisfies "mints a UUID" while honoring Phase 91 D-02's opaque-string wire contract.

---

## Response-header echo & opts

| Option | Description | Selected |
|--------|-------------|----------|
| `put_resp_header` in `call/2`; three `nimble_options` keys | Echo immediately (id known synchronously, mirrors Plug.RequestId); opts `:header_name`, `:logger_metadata_key`, `:telemetry_prefix` | ✓ |
| `register_before_send` echo + maximal opts (`:mint`, `:assign_as`) | Adds ordering risk + config surface nobody requested | |

**User's choice:** Create context (accepted recommendation). Flagged as the only new public-API surface in the phase; user opted not to revisit.
**Notes:** `put_resp_header` replaces deterministically (no clobber/duplicate). Mint toggle rejected as a category error (a never-mint plug is a different plug). Header name exposed as an option despite being LOCKED — costs zero, mirrors `Plug.RequestId`.

## Claude's Discretion

Module/function file layout, exact telemetry call wiring shape, test organization, whether `Threadline.Id` exposes more than `generate/0`, the precise `nimble_options` schema literal, and the exact Hex version bump (minor, additive) — left to research/planning.

## Deferred Ideas

None — discussion stayed within phase scope. No scope creep surfaced; `todo.match-phase 92` returned 0 matches.
