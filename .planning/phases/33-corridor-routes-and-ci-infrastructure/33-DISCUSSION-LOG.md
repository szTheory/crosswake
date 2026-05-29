# Phase 33: Corridor Routes And CI Infrastructure - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-29
**Phase:** 33-Corridor Routes And CI Infrastructure
**Areas discussed:** Corridor route shape, Route target when LiveView absent, CI test topology

---

## Corridor Route Shape (purchase_intent / restore_intent route type)

| Option | Description | Selected |
|--------|-------------|----------|
| POST controller routes | `post /commerce/purchase` + `post /commerce/restore` → CorridorController (forward-ref). Honest: backend seam a native screen/companion POSTs evidence to, matching `:native_or_companion_required`. Lands both roles in manifest. | ✓ |
| All three as live routes | Declare purchase/restore as `live` routes too. Simplest, but misrepresents native-owned corridors as Phoenix-owned screens, contradicting the runtime-ownership thesis. | |

**User's choice:** POST controller routes (recommended).
**Notes:** `paywall_entry` stays a `live` route (Phoenix-owned). In the mock lane these POST routes are declaration artifacts — Phase 35 drives purchase via a LiveView `handle_event`, not these HTTP routes — but they put the full corridor role topology into the manifest and show the honest native→backend seam.

---

## Route Target When LiveView Absent

| Option | Description | Selected |
|--------|-------------|----------|
| Forward-reference (no stub) | Point routes at `PaywallEntryLive` / `CorridorController` which land in Phase 35; rely on Phoenix AST compilation + `@compile {:no_warn_undefined}`. | ✓ |
| Throwaway stub modules | Write temporary stub modules so routes resolve at runtime in Phase 33. | |

**User's choice:** Lock as described — forward-reference, no stub.
**Notes:** Router compiles (quoted AST), no Phase-33 test hits the routes, manifest builder reads route policy not target modules. Add forward-refs to `@compile {:no_warn_undefined, ...}`.

---

## CI Test Topology (`phase34-proof.yml`)

| Option | Description | Selected |
|--------|-------------|----------|
| require_file + tag semantics (phase23-mirrored) | `requires_example_host` tags only server/integration tests; hermetic proof stays untagged, pulls example modules via `Code.require_file`; hermetic job runs `mix compile --warnings-as-errors` + `mix test --exclude requires_example_host` from repo root; advisory job = phase23-style placeholders. | ✓ |
| Adjust | Change route-target or CI-topology defaults before locking. | |

**User's choice:** Lock both as described.
**Notes:** Matches locked STATE proof-isolation discipline (async: false, Phase34-prefixed fixtures, Code.require_file at module scope, mirrors phase21/phase23). Workflow filename stays `phase34-proof.yml` (locked by PROOF-02), named for the proof surface it gates.

---

## Claude's Discretion

- Exact `/commerce` sub-paths, pipeline reuse, controller/LiveView module names.
- Whether the hermetic job lists the Phase 36 proof file explicitly (phase23 style) or relies on the broad `mix test` run.
- Reconciling `corridor:` atom-vs-string form against `schema.ex` `validate_commerce_declaration` during planning.

## Deferred Ideas

- `CrosswakeExample.PubSub` not started in `application.ex` — add before Phase 35 LiveView wiring (STATE todo), not Phase 33.
- `CorridorController` action bodies — Phase 35 wiring.
- Verification simulation shape (inline vs context fn) — Phase 35 todo.
- Retroactive SHA-pinning of pre-v3.3 proof workflows — deferred (STATE).
