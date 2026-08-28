# Phase 154: The Control-Contract Seam - Research

**Researched:** 2026-07-29
**Domain:** Phoenix LiveView ↔ native-shell typed RPC seam (Elixir core + hand-authored JS hook + Swift/Kotlin bridge channels), plus a merge-blocking AST/attestation guard and a vocabulary migration.
**Confidence:** HIGH for code-level mechanics (all claims below were read directly from the installed dependency source or this repo's own `lib/`/`test/`/native files, or confirmed with a live `mix run` probe). MEDIUM/LOW flagged inline where CONTEXT.md's stated mechanism did not reproduce exactly as described.

<user_constraints>
## User Constraints (from CONTEXT.md)

CONTEXT.md for this phase is unusually large (77 decisions, D-01..D-77) and is the
authority for WHAT to build. It is not reproduced verbatim in full here to keep this
document navigable — the planner MUST read
`.planning/phases/154-the-control-contract-seam/154-CONTEXT.md` in full before planning,
per the phase's own instruction ("READ IT ALL, it is the authority"). What follows is the
condensed decision index plus the discretion/deferred sections verbatim, so this file is
still self-contained enough to plan from.

### Locked decision index (see 154-CONTEXT.md for full text of each)

- **Sequencing:** D-01 (154 not blocked by 153's human-gated mirror push for fire-and-forget), D-02 (iOS reply return leg must be built this phase, reaches adopters only in 156), D-03 (state support-matrix honestly: Android native replies + all-platform synthesized denials + iOS native replies in-repo-only this phase).
- **Error contract:** D-04 (outbound preflight raises; inbound stays a denial — same authorization source, direction picks the outcome), D-05 (raise is unconditional across all envs including `:prod`), D-06 (honesty not DX — a denial asserts a shell fact; an undeclared capability has none), D-07 (raise a named `Crosswake.Bridge.UndeclaredCapabilityError`), D-08 (`Phoenix.LiveView.stream_insert/3` is the "chainable fn can raise" precedent), D-09 (do NOT ship `available?/2` or `connected?/1`), D-10 (error message is a heredoc naming route id, missing family, what IS declared, view module, router file/line, the fix line, and why it raised).
- **Denial contract:** D-11 (collapse at `status`, distinguish at `reason`), D-12 (add exactly one reason `:shell_unreachable`, 13→14, with `details.failing_moment` carrying the 4 variants), D-13 (do not reuse `:unavailable_capability` for no-shell), D-14 (denials minted only in Elixir by `Shell.Denial.new/1`; JS hook reports a fact, never mints a denial — overrides API-DESIGN.md §3's draft), D-15 (`:shell_unreachable` NOT added to `Compatibility.finding_to_denial/2` — no Finding axis), D-16 (latent contract violation: shipped natives emit out-of-vocabulary reasons; land a structural test asserting native reason strings ⊆ vocabulary — fix or defer with a named seed).
- **Reply delivery/correlation/races:** D-17 (reply delivered via `handle_info/2` as `{:crosswake_bridge, ref, %Reply{}}` — verify against installed `phoenix_live_view` before locking; **RESOLVED below, see Verified Findings §1**), D-18 (Crosswake intercepts the reserved event via `attach_hook/4`, halts, sends the typed struct), D-19 (reject per-call `reply_to:` event names — Hotwire's `receivedMessage(for:)` last-message-only bug), D-20 (`correlation_id` library-internal; adopter gets opaque opt-in `ref:`, never crosses native boundary/telemetry), D-21 (one `handle_info` clause matching on `ref`; haptics needs none), D-22 (two timers: client hook primary + server backstop at `timeout+2s`, default 10s, `:infinity` allowed), D-23 (exactly-once via 3-layer compare-and-delete: hook map + `socket.private` map + per-mount epoch), D-24 (in-flight ask does NOT survive reconnect — fresh epoch, late replies drop as `:foreign_epoch`), D-25 (`Crosswake.Bridge.resolve(socket, ref)` atomic compare-and-delete — NOT API-DESIGN.md's double-answer fix, which double-fires), D-26 (`crosswake:` wire prefix, not `cw:`), D-27 (4 domain verbs only: push/reply/answer/deny), D-28 (do NOT flatten the `denial.denial` double-nest — wire-frozen until a major; flatten only in the Elixir decoder).
- **JS hook distribution:** D-29 (payload ceiling note for 156, not 154), D-30 (ship library-owned hand-authored ESM at `priv/static/crosswake.esm.js`, no build step; add a repo-root private `package.json` for bare-specifier resolution only, never published to npm), D-31 (not a component-tier violation — protocol-sensitive, not presentation), D-32 (reference host has no bundler at all — a generator writing into `assets/js/` would write into nothing), D-33 (`mix crosswake.gen.bridge_hook --eject` refuses without the flag and teaches), D-34 (reject Cordova-style shell injection of the hook logic — but keep the shells' existing fact injection of `.capabilities`/`.threadId`), D-35 (API-DESIGN.md §3's transport check has a real bug: `??` can resolve to the capabilities-only object on iOS and post into the void — shipped hook must order `webkit.messageHandlers` first AND typecheck `typeof … === "function"`), D-36 (hook-not-wired detection = server-armed two-stage ack deadline `crosswake:bridge_ack` within ~2000ms, not a mount handshake), D-37 (doctor static grep across BOTH `assets/**` and `lib/**/*.heex`, best-effort only), D-38 (3 route-tour tests: shell-absent deny, shell-present via `page.addInitScript()`, hook-unwired → server-side `hook_not_wired` denial), D-39 (module-scoped single-owner guard in the hook — `push_event` broadcasts to every mounted hook), D-40 (HRDN-01 is CSP hardening — external module needs no `unsafe-inline`), D-41 (`mix crosswake.install` patches the endpoint canonically, prints the rest).
- **Catalog-line guard:** D-42 (do NOT create a new catalog file — `Manifest.Builder.capability_catalog/0` already is it), D-43 (extend with `Crosswake.Bridge.CatalogGuard` in `lib/`, mirroring `Crosswake.CompanionGuard`'s AST technique), D-44 (label the six criteria honestly: 4 mechanical, (b) mechanical-only-in-the-negative, (e) hybrid with 155's PROOF-01), D-45 (PROOF-04 does not stop maintainers adding controls one at a time — it closes the mechanical plugin-catalog road only), D-46 (negative controls 4 ways + orphan-detection + "job not found is a failure"), D-47 (no new workflow file/required check — lands in `test/crosswake/proof/`, picked up by existing hermetic lanes).
- **CTRL-05/interaction:** D-48 (failure message keeps bracketed stable id + teaches the 6-step recipe for control #7), D-49 (CTRL-05 is ~85% already wired — missing leg is `capability_rebuild_findings/1` in doctor), D-50 (changelog leg already merge-blocking and stronger than required — add one cheap vocabulary-derivability assertion, do NOT build a diff-based release gate), D-51 (two correctness holes: `@enforce_keys` too loose + tolerant nil-rebuild construction site — **see Verified Findings §2, the described mechanism does not reproduce exactly as stated**), D-52 (`@enforce_keys [:id,:version,:rebuild,:interaction]` is the only "structurally impossible" part), D-53 (add rebuild column to `guides/capability_map.md`), D-54 (`Capability.interaction` IN for 154, 3 values: `:fire_and_forget | :device_answer | :user_answer` — share is the honesty-forcing case), D-55 (do `:interaction` now, not 156 — shares migration cost with the `:rebuild` enforce-keys fix), D-56 (encode checkable half of share-honesty rule as a ~15-line PROOF-04 guard; leave typed `Outcome` sum type to 157).
- **Vocabulary rename:** D-57 (not an API change — `legacy_ids` already fully wired, both forms already authorize), D-58 (hard-switch published vocabulary to family ids; keep `legacy_ids` accepted indefinitely; doctor advisory, no deprecation warning), D-59 (compile-time deprecation warning is mechanically impossible where it'd matter — doctor is the only honest surface), D-60 (legacy path emits a malformed manifest today — self-referential `legacy_ids` bug, **verified exactly, see Verified Findings §3**), D-61 (blast radius = one router line, `examples/phoenix_host/lib/crosswake_example/router.ex:330` — **plus e2e assertion at `route_tour.spec.ts:168`, see Verified Findings §4**), D-62 (`"haptics"` is the better public noun — route policy declares families, bridge dispatches commands), D-63 (do not break the legacy form/remove aliases).
- **HRDN-01:** D-64 (evidence panel survives, gets more honest — `bridge_dispatch`+`bridge_reply` assigns, live region), D-65 (desktop-browser-no-shell IS the demo — fail-closed thesis renders itself), D-66 (label rows "Capability (route policy)" vs "Command (wire protocol)"), D-67 (panel renders from the actual `Bridge.push/3` envelope, never hand-copied), D-68 (4 semantic fields + verdict, not raw JSON — `bridge_proof_live.ex` keeps its raw `<pre>`), D-69 (idle-state copy per brand voice), D-70 (migrate `bridge_proof_live.ex` too — same IIFE, keep its `<pre id="crosswake-bridge-payload">`), D-71 (delete `examples/phoenix_host/assets/js/app.js` — dead, wrong names, false T-89-01 claim), D-72 (amend SEED-006:71 in the same PR — its premise about an existing nav-intent seam is false), D-73 (amend, don't rewrite, Phase 149 D-07/D-12), D-74 (highest-risk edit: `route_tour.spec.ts:431-438` regex-scrapes the `<script>` being deleted — mitigate with `data-cw-envelope` attribute + `JSON.parse`), D-75 (require positive "reply arrived" assertion, not just "no timeout").
- **Sequencing:** D-76 (3 PRs in order: vocabulary+fixture fix → seam+hook+denial+guard (unit-only) → HRDN-01 migration), D-77 (scope honesty — this is materially larger than "ship push/3 and migrate haptics").

### Claude's Discretion

The user asked for a single coherent recommendation set rather than sequential questions, and
explicitly asked not to have to arbitrate. Every decision above is therefore Claude's call
from researched evidence. The items most worth a human glance before execution are D-02
(iOS return leg — touches milestone sequencing), D-16 (a structural test that fails today),
D-17 (marked one-way; also carries a verification caveat — **resolved below**), and D-77 (scope).

### Deferred Ideas (OUT OF SCOPE)

- Flattening the `denial.denial` double nest and `Bridge.Denial`'s duplicated fields — frozen until a `Contract.@version` major.
- Typed `Crosswake.Bridge.Outcome` sum type — Phase 157, alongside share's iPad-crash guard.
- Request-payload widening beyond `[String: String]` — Phase 156, wire-only `Contract.@version` bump.
- Per-capability default timeouts on the `Capability` record — Phase 156.
- `action_menu.dismiss` — Phase 156.
- `<.cw_action_menu>` / per-family HEEx wrappers — Phase 155/156; never a generic `<.cw_control type="...">` dispatcher.
- Whether `Manifest.Builder` should mint a compat capability-registry entry at all for legacy ids, vs. resolving to the family entry and recording the alias on the route — deferred.
- Fixing the natives' out-of-vocabulary denial reasons (D-16) — in 154 if affordable; otherwise defer explicitly with a named seed.

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CTRL-01 | LiveView invokes a bounded control via `Bridge.push/3`, receives a correlated typed reply | §1 (attach_hook/handle_info verification), §5 (Contract/Registry/Denial code map), Architecture Patterns |
| CTRL-02 | No-shell/old-shell/undeclared-capability collapse to one typed `Shell.Denial` | §5 (Shell.Denial current 13-reason enum), §6 (native out-of-vocabulary reasons), Common Pitfalls |
| CTRL-03 | Undeclared-capability route invocation fails loudly, names the missing declaration | §5 (Registry.lookup/4 is the single authorization source for both directions) |
| CTRL-04 | Bridge command vocabulary stays closed; host-registrable/dynamic registration structurally impossible | §7 (CompanionGuard AST precedent to mirror for CatalogGuard), §2 (capability_catalog is the existing attestation file) |
| CTRL-05 | Every control declares rebuild class; native-rebuild-required labeled in changelog/support-matrix/doctor | §2 (Capability struct + enforce_keys verification), §8 (doctor findings precedent), §9 (release_boundaries_test.exs precedent) |
| PROOF-04 | Catalog line ships as merge-blocking structural test | §7 (CompanionGuard mirror), §10 (CI lane precedent — no new workflow file) |
| HRDN-01 | AdminPilot haptics runs through `Bridge.push/3`; hand-rolled `<script>` IIFE deleted | §4 (exact migration targets verified line-by-line: approval_live.ex, bridge_proof_live.ex, router.ex, app.js, route_tour.spec.ts) |

</phase_requirements>

## Summary

This phase has no unresolved technology-selection questions — CONTEXT.md's 77 decisions
already picked every mechanism. The research value-add here is verifying those decisions
against the actual installed dependency and the actual repo files, because several of
CONTEXT.md's claims are precise engineering assertions (a LiveView lifecycle-hook
capability, a struct's default-value behavior, a self-referential list bug) that are either
exactly right or subtly off, and the planner needs to know which before writing tasks.

Three findings matter most:

1. **D-17's "verify against the installed phoenix_live_view" caveat is now resolved and
   CONFIRMED CORRECT.** `attach_hook(socket, id, :handle_event, fun)` hooks receive
   `(event, val, socket)` and MUST return `{:cont, socket}` or `{:halt, socket}` (or
   `{:halt, reply, socket}`) — there is no mechanism to rewrite `val` for the adopter's own
   `handle_event/3` clause. `{:cont, socket}` re-delivers the ORIGINAL event/params
   unchanged to the LiveView's handle_event; the hook cannot inject a typed struct that
   way. The only path that delivers a typed value to adopter code is: hook halts
   (consumes the raw wire event entirely), then `send(self(), {:crosswake_bridge, ref,
   %Reply{}})`, which the adopter receives via their own `handle_info/2`. D-17's design is
   the only one this dependency version actually supports — lock it with confidence.

2. **D-51's exact failure mechanism does not reproduce as literally stated, but the
   underlying risk category is real and the fix is still warranted.** A live probe shows
   `compatibility_capability_attrs(nil, capability_id) |> Types.new_capability/1` produces
   `rebuild: :none` today (not `nil`) — `new_capability/1`'s `Keyword.get(attrs, :rebuild,
   :none)` tolerantly defaults it, and `format_rebuild(:none)` renders `"none"`, not
   `"nil"`. What IS verified and load-bearing: `@enforce_keys` in Elixir only checks KEY
   PRESENCE in the map/keyword passed to `struct!/2`, not the value — so today's addition
   of `:rebuild` to `@enforce_keys` would NOT break `new_capability/1` (it always supplies
   the key). But adding `:interaction` WILL break every single call site of
   `new_capability/1` (raises `ArgumentError: the following keys must also be given...
   [:interaction]`) unless `new_capability/1` is updated in the same change to also
   require/supply `:interaction` for all 15 catalog entries plus the compatibility path.
   That is the real, verified blast radius the planner should size the D-51/D-54 task
   around — not the `nil`-value story as literally written.

3. **Every other major mechanical claim in CONTEXT.md was directly verified against the
   code and matches exactly**: the iOS dropped-reply gap, the doubly-nested wire denial,
   the two native out-of-vocabulary reasons, the self-referential `legacy_ids` bug for
   compatibility capabilities, the exact migration targets and their exact line numbers,
   the CompanionGuard AST-guard mechanism to mirror, the existing hermetic-CI pickup
   mechanism (no new workflow needed), and the `docs()` `groups_for_modules` regex that
   already covers any new `Crosswake.Bridge.*` submodule without an edit.

**Primary recommendation:** Build exactly what CONTEXT.md's 77 decisions specify; treat
this RESEARCH.md as the "how, precisely, against this codebase" companion — most
importantly the attach_hook/handle_info wiring (§1), the enforce_keys blast radius (§2),
and the additional coupled edit at `route_tour.spec.ts:168` that CONTEXT.md's canonical
refs list does not call out (§4).

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| `Bridge.push/3` dispatch + correlation | API/Backend (Phoenix/LiveView process) | Browser (JS hook forwards the wire event) | Authorization (`Registry.lookup/4`), correlation-id minting, timeout backstop, and denial synthesis are all server-owned per D-04/D-14/D-22; the browser only transports and acks. |
| Denial minting | API/Backend | — | D-14: denials are minted only in Elixir by `Shell.Denial.new/1`; JS reports facts only. |
| Hook-not-wired detection | API/Backend (deadline timer) + Browser (ack emission) | CDN/Static (doctor static grep is best-effort only) | D-36/D-37: the runtime deadline is authoritative; the grep is advisory. |
| JS hook wire transport | Browser | — | Forwards to `window.webkit.messageHandlers.crosswakeBridge` (iOS) or the WebViewCompat listener (Android); never makes authorization decisions. |
| Native reply delivery | Native shell binary (iOS/Android) | Browser (JS landing pad `window.crosswakeBridge.__reply`) | D-02: this phase writes the iOS Swift `replySink → evaluateJavaScript` leg; Android's `WebMessageCompat` duplex path already exists. |
| Catalog-line structural guard (PROOF-04) | Build/CI (compile-time + test-time AST walk) | — | D-43: `Crosswake.Bridge.CatalogGuard` lives in `lib/` (not test/) so doctor can also call it; runs at `mix test` time via stdlib AST parsing, no runtime cost. |
| Capability rebuild-class surfacing (CTRL-05) | API/Backend (`Manifest.Builder`, `RuntimeLine.RebuildPolicy`, doctor) | Static/Docs (CHANGELOG.md, support_matrix.md, capability_map.md) | Rebuild truth is derived once from `Capability.rebuild`, then fanned out to 3 static-doc surfaces — never re-derived per surface. |
| Showcase evidence panel (HRDN-01) | Frontend Server (LiveView render) | — | Renders directly from the `Bridge.push/3`-built envelope (D-67); no client-side JS builds denial copy. |

## Standard Stack

This phase adds **no new external dependency** (no new Hex package, no npm package). It
extends existing core modules and ships one hand-authored, dependency-free ESM JS file.

### Core (already present, verified)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `phoenix_live_view` | 1.1.30 (locked, `mix.lock`) [VERIFIED: mix.lock + installed deps/ source] | `attach_hook/4`, `push_event/3`, `Phoenix.LiveView.put_private/3` | Already the project's LiveView dependency; `attach_hook` API confirmed present and behaves as described in §1. |
| `jason` | `~> 1.4` [VERIFIED: mix.exs] | JSON encode/decode for the hook payload and manifest fixtures | Already the project's JSON library everywhere else. |
| `nimble_options` | `~> 1.1` [VERIFIED: mix.exs] | Route-policy schema validation (`Crosswake.Policy.Schema`) | Existing dependency; no new usage needed for this phase's scope. |
| `telemetry` | `~> 1.0` [VERIFIED: mix.exs] | New `[:crosswake, :bridge, ...]` events | Existing catalog module (`lib/crosswake/telemetry.ex`) to extend, not replace. |

### Supporting — none new.

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Hand-authored dependency-free ESM hook (D-30) | Publish a `@crosswake/bridge` npm package | Rejected explicitly (D-30) — opens a second registry/version axis, the exact Capacitor drift failure cited in CONTEXT.md. |
| `attach_hook(:handle_event)` + `send/2` + adopter `handle_info/2` (D-17) | Rewriting `val` in-place so adopter's own `handle_event` clause sees a typed struct | **Not possible** with the installed `phoenix_live_view` — verified in §1. `{:cont, socket}` re-delivers the untouched original params; there is no rewrite path. |

**Installation:** none — no `mix deps.get` / `npm install` changes required for this phase.

**Version verification:** `phoenix_live_view` confirmed at `1.1.30` via `mix.lock`
(`locked at 1.1.30 (phoenix_live_view) a353c51a`) [VERIFIED: mix.lock]. No package-legitimacy
audit is required (see below) because this phase introduces zero new external packages.

## Package Legitimacy Audit

**Not applicable — this phase installs no new external packages.** The JS hook (D-30) is
hand-authored, dependency-free ESM shipped from `priv/static/` inside the existing `crosswake`
Hex package; the repo-root `package.json` added for bare-specifier resolution is marked
`"private": true` and is never published to npm (D-30 explicit non-goal). No `npm view` /
`pip index` / `cargo search` calls are needed.

| Package | Registry | Age | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| — | — | — | — | — | — | No new packages this phase |

**Packages removed due to [SLOP] verdict:** none.
**Packages flagged as suspicious [SUS]:** none.

## Verified Findings (the "how, precisely" layer over CONTEXT.md's decisions)

### §1 — `attach_hook`/`handle_info` mechanics (resolves D-17's verification caveat)

Read directly from the installed dependency:
`deps/phoenix_live_view/lib/phoenix_live_view/lifecycle.ex` (via `mix.lock`-pinned
`phoenix_live_view 1.1.30`).

```elixir
# lifecycle.ex (verified source, not adapted)
def attach_hook(%Socket{} = socket, id, stage, fun)
    when stage in [:handle_async, :handle_event, :handle_info, :handle_params, :after_render] do
  # ...
end

def handle_event(event, val, %Socket{private: %{@lifecycle => lifecycle}} = socket) do
  reduce_handle_event(lifecycle.handle_event, socket, fn hook, acc ->
    hook.function.(event, val, acc)
  end)
end

defp reduce_handle_event([hook | hooks], acc, function) do
  case function.(hook, acc) do
    {:cont, %Socket{} = socket} -> reduce_handle_event(hooks, socket, function)
    {:halt, %Socket{} = socket} -> {:halt, socket}
    {:halt, reply, %Socket{} = socket} -> {:halt, reply, socket}
    other -> bad_lifecycle_response!(other, hook)
  end
end
```

**Verified conclusion:** an `attach_hook(socket, id, :handle_event, fun)` hook is called as
`fun.(event, val, socket)` and its return value controls only whether the *original,
unmodified* `event`/`val` continues to the LiveView module's own `handle_event/3` clause
(`{:cont, socket}`) or is fully consumed (`{:halt, socket}` / `{:halt, reply, socket}`).
There is **no return shape that rewrites `val`** for a `{:cont, ...}` continuation. This
makes D-17's chosen design — hook halts, `send(self(), {:crosswake_bridge, ref,
%Crosswake.Bridge.Reply{}})`, adopter's own `handle_info/2` receives the typed struct —
the *only* mechanism this LiveView version supports for delivering a typed value across
the reserved-event boundary. **Plan with confidence; no further verification spike needed
at execution time.**

Practical consequence for the plan: `Crosswake.Bridge.attach/1` (the `on_mount`/attach
callback mentioned in canonical refs' Integration Points) must call
`Phoenix.LiveView.attach_hook(socket, :crosswake_bridge, :handle_event, &__MODULE__.handle_bridge_event/3)`
at mount time, and that hook function must pattern-match the reserved event name (e.g.
`"crosswake:bridge_reply"`), decode+validate, `send(self(), {:crosswake_bridge, ref,
reply})`, and return `{:halt, socket}`. Any event name it doesn't recognize must return
`{:cont, socket}` so unrelated `phx-click`/etc. events on the same page still reach the
adopter's normal `handle_event/3`.

### §2 — `Capability` struct / `@enforce_keys` blast radius (refines D-51/D-52/D-54/D-55)

Read `lib/crosswake/manifest/types.ex` (`Capability` module) and confirmed with two live
`mix run` probes.

Current struct:
```elixir
@enforce_keys [:id, :version]
defstruct [
  :id, :version, :family, :owner, :package_class, :proof_class,
  :rebuild, :denial, :fallback, :guide,
  status: :supported, prerequisites: [], legacy_ids: []
]
```

`Types.new_capability/1` always builds a full map before calling `struct!/2`:
```elixir
rebuild: Keyword.get(attrs, :rebuild, :none),   # always present in the map, defaults :none
```

**Probe 1** — `compatibility_capability_attrs(nil, "unknown.capability") |> Types.new_capability/1`
via `mix run`:
```
rebuild value: :none
formatted rebuild: "none"
```
[VERIFIED: mix run probe against this repo's own code, 2026-07-29] — **not** `nil`/`"nil"`
as CONTEXT.md's D-51 describes. The `RebuildPolicy.classify/2` `case` statement genuinely
has no `nil` clause (only `:native_required | :companion_required | :none`), so a real
`nil` value WOULD raise `CaseClauseError` — but the construction path CONTEXT.md names does
not currently produce that `nil`. Recommend the planner note this discrepancy in the task
description (do the defensive fix anyway — it's cheap and correct — but don't describe it
as fixing an observed crash, since none reproduces via this path today).

**Probe 2** — Elixir's `@enforce_keys` semantics, confirmed structurally:
```elixir
struct!(SomeStruct, %{id: "x", version: "1.0.0", rebuild: :none})
# raises ArgumentError only if a REQUIRED KEY IS ABSENT from the map — value doesn't matter,
# even nil is accepted as long as the key is present.
```
[VERIFIED: mix run probe] This means:
- Adding `:rebuild` to `@enforce_keys` **will not** break `new_capability/1` today (the
  map already always carries a `:rebuild` key, defaulted or not).
- Adding `:interaction` to `@enforce_keys` **will** break `new_capability/1` and every one
  of its ~17 call sites (15 catalog entries + 2 compatibility-path branches) with
  `ArgumentError: the following keys must also be given when building struct Capability:
  [:interaction]`, **unless** `new_capability/1` is updated in the same change to supply
  an `:interaction` value (default or required) for every call. This is the real,
  measurable blast radius of D-54/D-55/D-52 — size the task for touching all 15
  `capability_catalog/0` entries plus both branches of `compatibility_capability_attrs/2`,
  not just the struct definition.

### §3 — Self-referential `legacy_ids` bug (confirms D-60 exactly)

Read `lib/crosswake/manifest/builder.ex:456-474`:
```elixir
defp family_capability_for(capability_id) do
  Enum.find(capability_catalog(), fn attrs ->
    capability_id in Keyword.get(attrs, :legacy_ids, [])
  end)
end

defp compatibility_capability_attrs(attrs, capability_id) do
  attrs
  |> Keyword.put(:id, capability_id)
  |> Keyword.put(:version, capability_version(capability_id))
  |> Keyword.put(:family, Keyword.fetch!(attrs, :family))
end
```
For `capability_id = "haptics.impact"`, `family_capability_for/1` finds the `"haptics"`
catalog entry (whose `legacy_ids: ["haptics.impact"]`), then `compatibility_capability_attrs/2`
overrides only `:id`/`:version`/`:family` on that SAME attrs list — the `legacy_ids:
["haptics.impact"]` key is untouched and carried through, producing a constructed
capability whose own `id` (`"haptics.impact"`) appears inside its own `legacy_ids`.
[VERIFIED: direct code read, confirms D-60's claim exactly]. Fixing this (dropping
`legacy_ids` when constructing the compatibility-path entry, or hard-switching the router
so this code path is never exercised for `"haptics.impact"` again) must land in the same
PR as the router vocabulary flip per D-60/D-76.

### §4 — Additional coupled edit not named in canonical_refs: `route_tour.spec.ts:168`

`examples/phoenix_host/e2e/route_tour.spec.ts:168` currently asserts:
```typescript
expect(router, ownerMessage('saas-approval', 'bounded haptics capability'))
  .toContain('capabilities: ["haptics.impact"]');
```
[VERIFIED: grep + read of route_tour.spec.ts] When `router.ex:330` is flipped from
`capabilities: ["haptics.impact"]` to `capabilities: ["haptics"]` per D-61/D-62, **this
assertion breaks** unless updated in the same PR. CONTEXT.md's canonical-refs list names
`route_tour.spec.ts:168,196-201,431-438` under "Migration targets," so the *line number* is
already flagged — but the text of the decisions (D-61, D-76) does not explicitly call out
that line 168 specifically must change as part of PR #1 (the vocabulary/docs PR), separate
from D-74's PR #3 concern about the haptics-payload-scraping helper at 431-438. **Flag this
explicitly for the plan:** PR #1 (vocabulary flip) must update `route_tour.spec.ts:168`'s
literal string alongside `router.ex:330`, or the merge-blocking Playwright lane goes red on
a PR that D-76 describes as "no behavior change."

### §5 — Existing `Crosswake.Bridge.*` code map (what to attach `push/3` to)

Confirmed file-by-file (all read directly, all `[VERIFIED: direct file read]`):

- `lib/crosswake/bridge/contract.ex` — `Contract.Request`/`Contract.Reply` structs,
  `@commands` closed list (10 strings today), `@version "1.1.0"`, `ok_reply/2`,
  `deny_reply/2`. `Reply.status :: :ok | :deny | :error`. New `push/3` builds a `Request`
  via `new_request/1` and must add `haptics.impact`/`haptics` to whatever the closed
  `@commands` list needs (already present).
- `lib/crosswake/bridge/registry.ex` — `Registry.lookup/4` is the **single** authorization
  source for both directions (confirms D-04): returns `{:ok, Entry.t()}` or `{:error,
  :inactive_route | :unsupported_command | :undeclared_capability}`. `capability_entry/4`
  already does exactly the `Capability` + route-declaration check `Bridge.push/3`'s raise
  path needs; no new authorization logic required, only a caller that turns `{:error,
  :undeclared_capability}` into a raise instead of (or in addition to, direction-dependent)
  a denial.
- `lib/crosswake/shell/denial.ex` — `Shell.Denial` closed `@reasons` list, currently 13
  entries ending in `:dependency_missing`. Adding `:shell_unreachable` is a one-line list
  edit plus a `@type reason ::` union edit plus (per D-12) a details-defaulting clause
  mirroring `ensure_commerce_corridor_payload/3`'s existing pattern for
  `:commerce_corridor`.
- `lib/crosswake/bridge/denial.ex` — `Bridge.Denial.to_map/1` is the exact source of the
  documented double-nest: its own `"denial"` key holds `ShellDenial.to_map(denial.denial)`,
  and this whole struct is placed AGAIN under `Contract.Reply.to_map/1`'s `"denial"` key
  — confirming the wire shape is `reply["denial"]["denial"]["reason"]` exactly as D-17/D-28
  describe. [VERIFIED]
- `lib/crosswake/manifest/types.ex` — `Capability` struct (see §2 above).
- `lib/crosswake/manifest/builder.ex` — `capability_catalog/0` (15 entries, lines
  245-453), `family_capability_for/1`, `compatibility_capability_attrs/2` (see §3 above).
- `lib/crosswake/companion_guard.ex` — the AST-guard technique to mirror for
  `CatalogGuard` (see §7).
- **No `lib/crosswake/bridge.ex` facade module currently exists** — `Crosswake.Bridge.push/3`
  is entirely new code, not an addition to an existing facade. [VERIFIED: `find` returned
  no match for `bridge.ex` outside the `bridge/` subdirectory]. This confirms D-77's
  scope-honesty point at the code level: there is no existing "mostly-there" push
  implementation to extend.

### §6 — Native side (confirms D-02, D-16, D-34, D-35 exactly)

- **iOS** (`packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/BridgeChannel.swift`):
  `replySink: (BridgeReplyEnvelope) -> Void` is called from `evaluate(_:completion:)`; the
  example host wires it as `replySink: { _ in }`
  (`examples/ios_shell_host/CrosswakeShell/LiveViewContainerViewController.swift:247`)
  [VERIFIED, exact line]. `WKUserScript(source:, injectionTime: .atDocumentStart,
  forMainFrameOnly: false)` injects `window.crosswakeBridge.capabilities` /
  `.threadId` but never `.postMessage` — confirming D-35's transport-check hazard: on iOS,
  `window.crosswakeBridge` genuinely exists (as a facts-only bag) alongside the real
  transport at `window.webkit.messageHandlers.crosswakeBridge`. Two out-of-vocabulary
  denial reasons are hardcoded in this same file: `"notification_status_unavailable"`
  (line 286) and `"notification_authorization_required"` (line 292) [VERIFIED, exact
  lines] — confirms D-16 precisely.
- **Android** (`.../BridgeChannel.kt`): `WebViewCompat.addWebMessageListener(webView,
  "crosswakeBridge", allowedOriginRules) { ... replyProxy.postMessage(reply) }` is the
  working duplex path (line ~59) [VERIFIED]. `LiveViewFragment.kt` uses
  `WebViewCompat.addDocumentStartJavaScript` to inject the same
  `window.crosswakeBridge.capabilities`/`.threadId` facts (confirms D-34's "steal one
  piece" point applies identically on both platforms). Two more out-of-vocabulary reasons
  confirmed: `"invalid_payload"` (`BridgeChannel.kt:273,284`) and a host-supplied unbounded
  `String` via `NotificationTokenDelegate.Result.Denied(reason: String, ...)`
  (`CrosswakeDelegates.kt:38`) [VERIFIED] — so D-16's structural test needs to check BOTH
  native sources, and the Kotlin `Denied.reason` field type itself (a bare `String`, not an
  enum) is why a host implementing the delegate could mint an arbitrary, unvalidated
  reason string — worth naming explicitly in the guard's failure message.

### §7 — `Crosswake.CompanionGuard` — the AST-guard precedent to mirror for `CatalogGuard`

`lib/crosswake/companion_guard.ex` [VERIFIED, full file read] uses only
`Code.string_to_quoted/2` + `Macro.prewalk/3` (no `mix xref`, no boundary lib) to detect
`{:__aliases__, _, parts}` nodes matching a frozen banned-prefix list, plus a separate
prune-then-walk pass proving `Code.ensure_loaded?` calls only appear inside `def`/`defp`
bodies. Both checks expose a pure `check_*/1` function (source string in, `:ok |
{:violation, list}` out) plus an `assert_*!/0` wrapper that walks `Path.wildcard("lib/**/*.ex")`
and raises with a stable-id-tagged message. `CatalogGuard` should follow this exact shape:
pure predicate functions callable from both the proof test AND doctor, an `assert_*!/0`
convenience wrapper, and — critically — the module lives in `lib/` (not `test/`) exactly as
D-43 specifies, which is what lets `mix crosswake.doctor` call the same checks a developer's
CI run does.

### §8 — Doctor findings precedent (`phase_66_generator_drift_findings/3`, confirms D-37)

`lib/crosswake/doctor/doctor.ex:1958-2007` [VERIFIED] already greps host-owned files
(`Info.plist`, `AndroidManifest.xml`, etc.) for drift signals and returns `check(...)`
finding structs; `native_rebuild_findings/2` (line 1273) is the existing pattern for
surfacing a per-item rebuild warning that CTRL-05's new `capability_rebuild_findings/1`
should mirror (same `check(:warning, code, subject, message, hint, details)` shape). No new
finding-aggregation mechanism is needed — just one more `defp ..._findings/1` folded into
the existing `findings ++ ... ++ phase_66_findings` accumulation at line ~161.

### §9 — `release_boundaries_test.exs` upgrade-impact machinery (confirms D-50)

`test/crosswake/guides/release_boundaries_test.exs:540-594` [VERIFIED] already enforces
exactly one `### Upgrade Impact` block per versioned CHANGELOG release, drawn from a locked
4-string vocabulary (`"docs-only"`, `"core-only/no native rebuild"`,
`"compatibility-bump only"`, `"native or companion rebuild required"`), with legend parity
against `guides/support_matrix.md`. This is already merge-blocking. D-50's ask — one cheap
assertion that the vocabulary is *derivable* from `RebuildPolicy` verdicts — is additive to
this existing test file, not a new gate.

### §10 — CI pickup mechanism (confirms D-47 — no new workflow file needed)

`.github/workflows/phase130-proof.yml` [VERIFIED] shows the exact mechanism: the
`core-hermetic-proof` job runs `mix test test/crosswake/proof/phase130_extraction_guards_test.exs`
explicitly for named files, THEN `mix test --exclude requires_example_host --exclude
advisory_only` — that broad final step runs the ENTIRE `test/` tree (minus tagged
exclusions), automatically picking up any new untagged file dropped in
`test/crosswake/proof/`. This is what makes D-47's "no new workflow file" claim true: a
`test/crosswake/proof/phase154_catalog_guard_test.exs` (or similarly named) file needs zero
CI wiring — it rides the existing broad step. `test/test_helper.exs` [VERIFIED] confirms
the default exclude list is `advisory_only`, `collateral_binaries`, `engine_present`,
`requires_example_host` — a new Bridge unit test file must NOT carry any of these tags to
run in the default hermetic lane.

### §11 — Docs registration (no `mix.exs` edit needed for new `Bridge.*` submodules)

`mix.exs:147` [VERIFIED]: `Bridge: ~r/Crosswake\.Bridge(\.|$)/` in `groups_for_modules`
already matches ANY new module under `Crosswake.Bridge.*` (e.g. `Crosswake.Bridge.CatalogGuard`,
a prospective `Crosswake.Bridge.Test` helper) by regex — no edit to `mix.exs`'s docs config
is needed when adding new Bridge submodules, unlike the "Telemetry" or "Companion Contract"
groups which use explicit module lists.

### §12 — HRDN-01 migration targets, exact current state

All read directly:
- `examples/phoenix_host/lib/crosswake_example/saas_portal/approval_live.ex` [VERIFIED,
  full file read]: `@bridge_capability_version`, `bridge_request` assign, `haptics_request/1`
  (builds the raw envelope map by hand — this is exactly the "hand-copied summary" D-67
  forbids replacing-with-more-of), `bridge_script/1` (the IIFE to delete), `<script
  :if={@bridge_request} id="crosswake-approval-haptics">`. Route policy already declares
  `capabilities: ["haptics.impact"]` at `router.ex:330`.
- `examples/phoenix_host/lib/crosswake_example/bridge_proof_live.ex` [VERIFIED]: same IIFE
  pattern (`bridge_script/1`, lines ~119-128), already uses family form `capabilities:
  ["share"]`, and its `<pre id="crosswake-bridge-payload">` is the exact node
  `route_tour.spec.ts`'s `bridgePayload()` helper `JSON.parse`s (line ~423-429) — this
  `<pre>` must be preserved per D-70/D-68.
- `examples/phoenix_host/lib/crosswake_example/layouts.ex` [VERIFIED, full file read]: the
  root layout's `<script type="module">` imports bare `/phoenix/phoenix.mjs` and
  `/phoenix_live_view/phoenix_live_view.esm.js` with **no `hooks:` option** passed to `new
  LiveSocket(...)` at all — confirms D-75's "no hooks map yet" exactly. Adding the
  Crosswake hook means both importing `priv/static/crosswake.esm.js` as a third bare
  module specifier AND adding a `hooks: {CrosswakeBridge: CrosswakeBridge}` (or similar)
  object to the `LiveSocket` constructor call.
- `examples/phoenix_host/lib/crosswake_example/endpoint.ex` [VERIFIED]: three
  `plug(Plug.Static, ..., from: :crosswake_example | :phoenix | :phoenix_live_view)`
  blocks — the pattern D-30/D-41 says to extend with a fourth `from: :crosswake` block (or
  add to the existing static-from list) so `priv/static/crosswake.esm.js` is served; no
  bundler config exists to touch.
- `examples/phoenix_host/e2e/route_tour.spec.ts` [VERIFIED, exact lines]: line 168 (see §4
  above), lines 196-201 (the post-approval haptics-payload assertions, which check
  `command`/`capability`/`route_id`/`active_route_id`/`protocol` fields — these keys must
  still be present in whatever replaces the scraped envelope), lines 431-438
  (`approvalHapticsPayload()`, the regex-scraping helper D-74 flags as highest-risk —
  confirmed it locates `#crosswake-approval-haptics`, evaluates `element.innerHTML`, and
  regexes `const payload = ("(?:\\.|[^"\\])*");` out of the script body — this whole
  function can be replaced by a `getAttribute('data-cw-envelope')` + single `JSON.parse`
  once the panel emits that attribute per D-74).
- `examples/phoenix_host/lib/crosswake_example/router.ex:330` [VERIFIED]: `live("/approvals/:id",
  ApprovalLive, crosswake: [id: "saas-approval", ..., capabilities: ["haptics.impact"], ...])`
  — the single first-party legacy declaration D-61 names.

## Architecture Patterns

### System Architecture Diagram

```
┌─────────────────────────────┐        ┌──────────────────────────────────┐
│ Adopter LiveView             │        │ Browser (JS hook, priv/static/    │
│  handle_event("approve", ...)│        │ crosswake.esm.js)                 │
│  -> Bridge.push(socket,       │        │                                    │
│       "haptics", ref: r)      │        │  addEventListener("crosswake:bridge")│
└──────────────┬───────────────┘        └───────────────┬────────────────────┘
               │ 1. Registry.lookup/4 (both directions)  │ 5. push_event("crosswake:bridge",
               │    - undeclared? -> RAISE (D-04/D-05)   │    envelope) -> phx:crosswake:bridge
               │    - declared -> build Request           │    on window
               ▼                                          ▼
┌──────────────────────────────┐        6. hook acks receipt IMMEDIATELY
│ Crosswake.Bridge.push/3       │           ("crosswake:bridge_ack") — before
│  - mints correlation_id        │           touching transport (D-36)
│  - stores {ref, epoch, deadline}
│    in socket.private (D-23)    │        7a. transport present:
│  - arms server backstop timer  │            window.webkit.messageHandlers
│    (timeout + 2s, D-22)         │            .crosswakeBridge.postMessage(...)
│  - push_event/3 to hook         │            (order-checked + typeof-checked,
└──────────────┬────────────────┘            D-35 fix) OR WebViewCompat listener (Android)
               │                        7b. no ack within ~2000ms -> synthesize
               │ 8. native shell replies    denial server-side, failing_moment:
               │    (Android: postMessage    :hook_not_wired (D-36)
               │     duplex; iOS: replySink
               │     -> evaluateJavaScript
               │     against window.crosswakeBridge
               │     .__reply, NEW this phase, D-02)
               ▼
┌──────────────────────────────┐
│ attach_hook(:handle_event)     │  9. reserved event intercepted, decoded,
│  reserved-name interceptor     │     3-layer compare-and-delete (hook map +
│  (D-18) — halts, never lets    │     socket.private map + epoch, D-23/D-24)
│  adopter's own handle_event     │     -> {:halt, socket}, send(self(),
│  see the raw wire event         │     {:crosswake_bridge, ref, %Reply{}})
└──────────────┬────────────────┘
               ▼
┌──────────────────────────────┐
│ Adopter's own handle_info/2    │  10. adopter pattern-matches on ref,
│  clause receives the typed     │      renders ok/deny — exactly one clause,
│  {:crosswake_bridge, ref,      │      not three (CTRL-02)
│   %Reply{}}                    │
└──────────────────────────────┘
```

### Recommended Project Structure

```
lib/crosswake/
├── bridge.ex                    # NEW — Crosswake.Bridge facade: push/3, resolve/2,
│                                 #   attach/1 (mount-time hook registration), raises
│                                 #   UndeclaredCapabilityError
├── bridge/
│   ├── contract.ex               # existing — extend @commands if needed, unchanged shape
│   ├── registry.ex                # existing — Registry.lookup/4 reused unchanged (D-04)
│   ├── denial.ex                   # existing — demoted to internal wire-decode envelope (D-28)
│   ├── catalog_guard.ex             # NEW — mirrors Crosswake.CompanionGuard (D-43)
│   ├── reply.ex or reply struct     # NEW (or folded into bridge.ex) — the handle_info shape (D-17)
│   └── commands/*.ex                 # existing per-capability modules, unchanged
├── shell/
│   └── denial.ex                      # existing — add :shell_unreachable (14th reason, D-12)
├── manifest/
│   ├── types.ex                        # existing — Capability gains :interaction,
│   │                                    #   @enforce_keys grows (D-51/D-52/D-54)
│   └── builder.ex                       # existing — capability_catalog/0 gains :interaction
│                                         #   per entry; compatibility_capability_attrs/2
│                                         #   fix (D-60/§3)
├── doctor/doctor.ex                      # existing — new capability_rebuild_findings/1 (D-49)
└── telemetry.ex                          # existing — new [:crosswake, :bridge, *] active events

priv/static/
└── crosswake.esm.js                       # NEW — the library-owned hook (D-30)

lib/mix/tasks/
└── crosswake.gen.bridge_hook.ex            # NEW — refuse-and-teach generator (D-33)

test/crosswake/
├── bridge/
│   ├── push_test.exs                        # NEW — unit tests for Bridge.push/3
│   ├── catalog_guard_test.exs                # NEW — unit tests for CatalogGuard predicates
│   └── ... (existing registry_test.exs, contract_test.exs, bridge_behavioral_vector_test.exs)
├── proof/
│   └── phase154_catalog_guard_test.exs        # NEW — merge-blocking PROOF-04, untagged (D-47)
└── support/
    └── bridge_test.ex or similar                # NEW — Crosswake.Bridge.Test render_hook helper (D-77)

examples/phoenix_host/
├── lib/crosswake_example/
│   ├── endpoint.ex                              # EDIT — serve priv/static/crosswake.esm.js
│   ├── layouts.ex                                # EDIT — import hook + hooks: map (D-75)
│   ├── router.ex                                  # EDIT — capabilities: ["haptics"] (D-61)
│   └── saas_portal/approval_live.ex                # EDIT — HRDN-01 migration
│   └── bridge_proof_live.ex                          # EDIT — HRDN-01 migration (D-70)
├── assets/js/app.js                                    # DELETE (D-71)
└── e2e/route_tour.spec.ts                                # EDIT — lines 168, 431-438 (§4, D-74)
```

### Pattern 1: Reserved-event interception via `attach_hook`

**What:** Crosswake owns a reserved LiveView client event name and intercepts it at the
LiveView process level before the adopter's own `handle_event/3` ever sees it.
**When to use:** Any time a library needs to inject typed, structured values into a
LiveView's message flow without asking adopters to pattern-match on raw wire JSON.
**Example:**
```elixir
# Source: deps/phoenix_live_view/lib/phoenix_live_view/lifecycle.ex (verified mechanics, §1)
def attach(socket) do
  Phoenix.LiveView.attach_hook(socket, :crosswake_bridge, :handle_event, &handle_bridge_event/3)
end

defp handle_bridge_event("crosswake:bridge_reply", raw_payload, socket) do
  # decode + validate + 3-layer compare-and-delete (D-23) + build %Reply{}
  send(self(), {:crosswake_bridge, ref, reply})
  {:halt, socket}
end

defp handle_bridge_event(_event, _payload, socket), do: {:cont, socket}
```

### Pattern 2: AST-based structural guard (`Crosswake.CompanionGuard` → `CatalogGuard`)

**What:** A pure-stdlib `Code.string_to_quoted/2` + `Macro.prewalk/3` walker that returns
`:ok | {:violation, list}`, wrapped by an `assert_*!/0` raiser for merge-blocking test use.
**When to use:** Whenever a structural invariant (no dynamic command registration, no
external SDK import, native-enum parity) must be provable without running the code.
**Example:**
```elixir
# Source: lib/crosswake/companion_guard.ex (verified, existing shipped code)
def check_source(source_string) do
  {:ok, ast} = Code.string_to_quoted(source_string, [])

  {_, violations} =
    Macro.prewalk(ast, [], fn
      {:__aliases__, _meta, parts} = node, acc ->
        if Enum.any?(@banned_alias_parts, &List.starts_with?(parts, &1)) do
          {node, [node | acc]}
        else
          {node, acc}
        end

      node, acc -> {node, acc}
    end)

  if violations == [], do: :ok, else: {:violation, violations}
end
```

### Anti-Patterns to Avoid

- **Rewriting `val` inside an `attach_hook(:handle_event)` clause and returning `{:cont,
  socket}` expecting the adopter to see the rewritten value** — verified impossible; the
  adopter always sees the original wire params on `:cont` (§1).
- **Minting a `Shell.Denial` in JS** — explicitly overridden by D-14; the shipped hook
  reports facts (`crosswake:bridge_unreachable` + a `moment`), never a denial shape.
- **A second catalog file (`priv/control_catalog.exs` or similar)** — explicitly rejected
  by D-42; `Manifest.Builder.capability_catalog/0` is already the attestation file.
- **`if available?, do: push, else: fallback`** three-way branching — explicitly rejected
  by D-09 (Expo's `isAvailableAsync` footgun).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Structural AST guard for command-vocabulary closure | A custom parser or `mix xref`-based checker | `Code.string_to_quoted/2` + `Macro.prewalk/3` mirroring `Crosswake.CompanionGuard` | The pattern is already proven in this repo (Phase 130), including the prefix-match child-module pitfall and the prune-then-walk technique. |
| Correlation/timeout/exactly-once machinery | A GenServer-based broker or a custom Registry | `Phoenix.LiveView.put_private/3` for the in-flight map, `Process.send_after/3` for the server backstop timer, and a per-mount epoch integer | `put_private/3`'s own docs designate it for exactly this (library state needing no change tracking); this is the same shape as `GenServer.call`'s caller-timer-plus-monitor and `Task.await`'s timeout-plus-demonitor-flush (both stdlib precedents, not a new abstraction). |
| Deprecation warnings for the vocabulary rename | A custom compile-time warning system | `mix crosswake.doctor` advisory (via `Policy.Warning`/`Diagnostic`, which already exist) | D-59 verified: `Policy.Validator` never runs at router macro-expansion time, and `Compiler.emit_warnings/2` is gated behind a test-only flag — there is no compile-time hook available to attach a warning to. |
| Rebuild-class doc surfacing | A new generator or diff-based release gate | Doctor's existing `check(...)` finding pattern (mirroring `native_rebuild_findings/2`) plus the already-merge-blocking `release_boundaries_test.exs` Upgrade Impact machinery | Both mechanisms already exist and are proven; `RebuildPolicy`'s own moduledoc explicitly warns `diff/2` is not a release-gate oracle. |

**Key insight:** every piece of "new machinery" this phase needs already has a proven
sibling pattern shipped somewhere in this repo (companion extraction guards, doctor
findings, changelog vocabulary gates, host-file drift grep). The risk in this phase is not
inventing something novel — it's correctly generalizing patterns that were each built for
a narrower Phase 130-152 problem into the bridge domain.

## Runtime State Inventory

This phase includes a vocabulary rename (`haptics.impact` → `haptics` as the published/taught
form) and a route-policy declaration change, which triggers the rename/migration research
protocol. All five categories were checked explicitly:

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None found. `legacy_ids` resolution happens entirely at manifest-build time (compile-time route policy → in-memory `Root.t()`); there is no database, ChromaDB collection, or persisted record keyed by the string `"haptics.impact"`. AdminPilot's persisted `approval`/`activity` rows (Ecto, per Phase 149 D-08) store approval status/decisions, not capability ids. [VERIFIED: grep for `"haptics.impact"` across `lib/` and `priv/` found only the route-policy declaration and the native command string `haptics.impact` (the wire COMMAND, which is correct and unchanged — D-62 distinguishes capability-family id from wire command).] | None — code edit only. |
| Live service config | None found. No n8n/Datadog/Tailscale/Cloudflare-style external service config references this string. The manifest is regenerated from route policy on every build; there is no separately-editable UI-owned config carrying `"haptics.impact"`. | None. |
| OS-registered state | None found. No Task Scheduler entries, pm2 process names, launchd/systemd units, or native app registrations reference the capability-id string (native shells match on the wire COMMAND `"haptics.impact"`, which is unchanged — only the manifest-level capability id/family changes). | None. |
| Secrets/env vars | None found. No SOPS keys, `.env` vars, or CI secret names reference `"haptics.impact"`. | None. |
| Build artifacts / installed packages | One found: `examples/phoenix_host/lib/crosswake_example/router.ex:330`'s compiled route-policy macro output embeds `capabilities: ["haptics.impact"]` into the compiled manifest at every build — this is not a "stale artifact" in the traditional sense (it rebuilds every time), but it IS the single first-party place the legacy string is declared rather than merely referenced, and the fixture at `examples/ios_shell_host/Fixtures/crosswake_manifest.json:141-148` [per D-60] is a **committed, checked-in JSON artifact** that must be regenerated in the same PR — this genuinely is a stale-artifact risk if the fixture-regeneration step is skipped. | Code edit (router.ex:330, per D-61) **and** committed-fixture regeneration (crosswake_manifest.json, per D-60) — both required, in the same PR. |

**Canonical question answered:** after `router.ex:330` is updated to `capabilities:
["haptics"]` and `builder.ex`'s self-referential `legacy_ids` bug is fixed, the only
runtime system that still has the old string is (a) the wire protocol's COMMAND string
`"haptics.impact"` — which is correct and permanent, not a bug (D-62) — and (b) any
already-shipped native binary's compiled `BridgeCommand` enum, which likewise correctly
keeps `hapticsImpact = "haptics.impact"` as the wire command forever (D-15/D-61 confirm
this is the wire layer, untouched).

## Common Pitfalls

### Pitfall 1: Assuming `attach_hook(:handle_event)` can rewrite adopter-visible params
**What goes wrong:** A plan or implementation tries to have the hook return `{:cont,
rewritten_socket}` expecting the adopter's `handle_event/3` to see a transformed payload.
**Why it happens:** It looks plausible from the function signature (`fun.(event, val,
socket)` — surely returning a modified socket could carry rewritten params via an assign).
**How to avoid:** Always halt (`{:halt, socket}`) and `send/2` a message for
`handle_info/2` consumption instead — verified as the only path in §1.
**Warning signs:** A `handle_event/3` clause in generated example code that pattern-matches
on `%Crosswake.Bridge.Reply{}` directly as the `val` argument — this cannot work.

### Pitfall 2: Treating the native reason strings as already-conformant to the closed vocabulary
**What goes wrong:** Building `Bridge.push/3`'s reply-parsing path assuming every inbound
`Reply.denial.reason` is one of the 14 `Shell.Denial` atoms, then crashing or
silently-passing-through an unknown string when a shipped native emits
`"notification_status_unavailable"`, `"notification_authorization_required"`,
`"invalid_payload"`, or an arbitrary host-supplied string (all four confirmed shipping
today, §6).
**Why it happens:** The vocabulary has been "closed" in the Elixir type system for a
while; nothing previously parsed inbound reason strings server-side, so the violation was
dormant.
**How to avoid:** Land D-16's structural test (native reason strings ⊆ vocabulary) BEFORE
or alongside the reply-parsing code path goes live, and decide explicitly whether to fix
the four violations in this phase or defer with a named seed — do not discover this during
execution as CONTEXT.md warns.
**Warning signs:** A reply-parsing `case` statement in `Bridge.push/3`'s reply handler that
has no catch-all / `:other` clause for unrecognized reason atoms/strings.

### Pitfall 3: Single-owner hook violation causing doubled requests
**What goes wrong:** If the hook element is accidentally mounted twice on a page (e.g. once
in the app layout and once inside a LiveComponent), `push_event/3` broadcasts to every
mounted hook, and both would forward the same request to the native shell.
**Why it happens:** `push_event` is page-global by design (confirmed in D-39); nothing
prevents a second `phx-hook="CrosswakeBridge"` element from existing.
**How to avoid:** The hook module itself must carry a module-scoped single-owner guard
(D-39) — on `mounted()`, check/set a global flag and refuse to double-register.
**Warning signs:** A route that renders both a shared layout hook AND a per-component hook
with the same `phx-hook` name.

### Pitfall 4: iOS transport-check using `??` instead of ordered + typechecked lookup
**What goes wrong:** `window.webkit?.messageHandlers?.crosswakeBridge ?? window.crosswakeBridge`
resolves to the capabilities-only facts bag on iOS whenever `messageHandlers.crosswakeBridge`
is momentarily undefined, and calling `.postMessage()` on that bag either throws or posts
into the void.
**Why it happens:** `??` only short-circuits on `null`/`undefined`, not on "wrong shape" —
and iOS deliberately pre-populates `window.crosswakeBridge` with unrelated facts before the
real transport handler is guaranteed present.
**How to avoid:** Check `webkit.messageHandlers` FIRST and explicitly `typeof x.postMessage
=== "function"` before using either candidate (D-35's fix).
**Warning signs:** Any transport-detection code that uses `??` or `||` chaining two
candidate objects without a typecheck on the specific method being called.

### Pitfall 5: Discovering the `:interaction` enforce-keys blast radius mid-execution
**What goes wrong:** Adding `:interaction` to `Capability`'s `@enforce_keys` without
updating `Types.new_capability/1` and all `capability_catalog/0` entries in the same
change breaks every capability construction call site with `ArgumentError`.
**Why it happens:** `@enforce_keys` failures are easy to miss in a plan that treats "add a
struct field" as a small, low-risk edit.
**How to avoid:** Treat the `:interaction` addition as touching `new_capability/1`'s
signature AND all 15 `capability_catalog/0` entries AND the two
`compatibility_capability_attrs/2` branches as one atomic task (§2's verified blast
radius), not a follow-on fix.
**Warning signs:** `mix compile --warnings-as-errors` (which every proof lane runs) failing
with `ArgumentError` at compile-time capability-registry construction, or a doctor/manifest
test crashing with "the following keys must also be given."

## Code Examples

### Reserved-event hook interception (verified mechanics)
```elixir
# Source: deps/phoenix_live_view/lib/phoenix_live_view/lifecycle.ex (installed 1.1.30, verified)
def attach_hook(%Socket{} = socket, id, stage, fun)
    when stage in [:handle_async, :handle_event, :handle_info, :handle_params, :after_render] do
  lifecycle = lifecycle(socket, stage)
  hook = hook!(id, stage, fun)
  # ... appends to socket.private lifecycle map; raises if `id` already attached for `stage`
end
```

### AST guard predicate + raiser split (verified, existing shipped pattern)
```elixir
# Source: lib/crosswake/companion_guard.ex (verified, existing shipped code)
@spec check_source(String.t()) :: :ok | {:violation, list()}
def check_source(source_string) do
  # pure predicate — testable with synthetic strings, no filesystem access
end

@spec assert_no_static_refs!() :: :ok
def assert_no_static_refs! do
  # walks Path.wildcard("lib/**/*.ex"), raises a stable-id-tagged message on violation
end
```

### Doctor finding accumulation pattern (verified, existing shipped code)
```elixir
# Source: lib/crosswake/doctor/doctor.ex:1273-1297 (verified)
defp native_rebuild_findings([], _opts), do: []
defp native_rebuild_findings(rebuild_requirements, opts) do
  case Keyword.get(opts, :native_rebuild_satisfied?, false) do
    true -> []
    false ->
      Enum.map(rebuild_requirements, fn requirement ->
        check(:warning, "commerce.corridor.native_rebuild_required", "commerce_summary",
          "route #{requirement.route_id} ... requires a native or companion rebuild ...",
          "rebuild the corridor's native or companion artifacts and rerun doctor ...",
          %{route_id: requirement.route_id, ...})
      end)
  end
end
```
`capability_rebuild_findings/1` (D-49's ~40-line new function) should follow this exact
`check(:warning, code, subject, message, hint, details)` shape, keyed off capabilities
whose `rebuild != :none` and that are declared on at least one route.

### Stable-id proof assertion helper (verified, existing shipped code)
```elixir
# Source: test/support/proof_assertions.ex (verified)
def stable_id_message(id, subject, source, observed, path, hint, posture) do
  """
  [#{id}] subject=#{subject} source=#{source} observed=#{observed} path=#{path} hint=#{hint} posture=#{posture}
  """
  |> String.trim()
end
```
PROOF-04's test file should use this helper for every assertion, matching the
`test/crosswake/proof/phase130_extraction_guards_test.exs` convention exactly (bracketed
stable id first for greppability, per D-48).

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| Hand-rolled `<script>` IIFE built by string interpolation, no reply path, requires `unsafe-inline`/nonce CSP | Library-owned hand-authored ESM hook via `phx-hook`, external module file, CSP-clean | This phase (HRDN-01/D-40) | Removes the last first-party CSP `unsafe-inline` need in the example host; establishes the pattern all future controls (Menu, Phase 156) build on. |
| No server-side reply parsing for inbound `Reply.denial.reason` | Server parses and validates against the closed 14-reason vocabulary | This phase (D-16's structural guard) | Surfaces a dormant contract violation (native out-of-vocabulary reasons) that was previously invisible because nothing consumed replies server-side. |

**Deprecated/outdated:** `examples/phoenix_host/assets/js/app.js` — dead code being
deleted (D-71): never served (absent from the endpoint's `Plug.Static` allowlist), wrong
handler/object names, wrong message shape, and carries a false `T-89-01` security-mitigation
claim in an evidence-first repo.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | D-51's literal claim ("`compatibility_capability_attrs(nil, id)` builds `rebuild: nil`") does not reproduce via the verified `mix run` probe (§2) — the current default is `:none`. This RESEARCH.md's recommendation (do the defensive fix anyway, but reframe the task description) is itself a judgment call, not a verified fact about what the planner should do. | §2, Verified Findings | Low — if the planner disagrees and wants to chase the literal `nil` mechanism, a fresh probe (shown in §2) will immediately confirm/refute it before any code is written; no wasted implementation effort either way. |
| A2 | The exact naming/path convention for the JS hook file (`priv/static/crosswake.esm.js` at the `priv/static/` root vs. nested under the existing `priv/static/crosswake/` convention alongside `offline.css`/`tokens.css`) is taken literally from CONTEXT.md D-30 without independent verification of a strong repo convention either way — the two existing static files DO live in a `crosswake/` subdirectory, which is a mild inconsistency with D-30's literal path. | Runtime State Inventory / Recommended Project Structure | Low — cosmetic; either path works functionally, but the planner should pick one and note the (minor) precedent mismatch rather than silently diverging from the existing `priv/static/crosswake/*.css` nesting. |

**If this table is empty:** N/A — two low-risk items logged above; both are judgment/cosmetic, not load-bearing correctness gaps.

## Open Questions

1. **Should the `:interaction` enforce-keys migration also add a safe default, or require an explicit value at every catalog entry?**
   - What we know: D-52 explicitly wants `:interaction` in `@enforce_keys` so a control without a declared interaction class is "structurally impossible" to construct — meaning `new_capability/1` should almost certainly `Keyword.fetch!(attrs, :interaction)` (raise if missing) rather than default it, mirroring how `:id` is handled today.
   - What's unclear: whether the two `compatibility_capability_attrs/2` branches (for capability ids not in the public catalog) should synthesize a sensible `:interaction` default (e.g. `:fire_and_forget` as the most conservative/least-claiming value) or also raise.
   - Recommendation: default the compatibility path to `:fire_and_forget` (least claim) rather than raising, since raising there would make an adopter's undeclared/legacy capability id crash manifest generation instead of degrading — but the planner should confirm this against D-54's honesty framing before locking it as a task.

2. **Does the doubly-nested wire denial's flattening-in-the-decoder-only rule (D-28) interact with the new reply-parsing path's D-16 vocabulary check?**
   - What we know: D-28 says flatten only in the Elixir decoder, wire stays frozen. D-16 says validate native reason strings against the vocabulary once replies are parsed server-side.
   - What's unclear: whether the D-16 vocabulary check should run against the flattened (decoded) `reason` or the raw wire `reply["denial"]["denial"]["reason"]` path — functionally the same value either way, but worth the plan stating explicitly which layer owns the check so it isn't duplicated or skipped.
   - Recommendation: run the D-16 check post-decode, on the same `Shell.Denial`-shaped struct the rest of the reply-parsing path already operates on — no new decode step needed.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Elixir | Core language | ✓ [VERIFIED: `mix.exs` `elixir: "~> 1.19"`] | 1.19.x (CI pins `1.19.5`) | — |
| `phoenix_live_view` | `attach_hook`, `push_event`, `put_private` | ✓ [VERIFIED: `mix.lock`] | 1.1.30 | — |
| `jason` | JSON codec | ✓ [VERIFIED: `mix.exs`] | `~> 1.4` | — |
| Playwright (`examples/phoenix_host/e2e/`) | D-38's 3 route-tour tests | ✓ [VERIFIED: existing `route_tour.spec.ts` suite runs today] | project-pinned | — |
| A JS bundler in the example host | Explicitly NOT required — D-32 confirms no bundler exists | N/A (by design) | — | Bare ESM `<script type="module">` imports (already the pattern, §12) |

**Missing dependencies with no fallback:** none identified.
**Missing dependencies with fallback:** none identified — this phase's scope deliberately
avoids introducing a bundler requirement (D-30/D-32).

## Validation Architecture

`workflow.nyquist_validation` is absent from `.planning/config.json` → treated as enabled.
`workflow.security_enforcement` is likewise absent → treated as enabled (see Security
Domain below).

### Test Framework
| Property | Value |
|----------|-------|
| Framework | ExUnit (core), Playwright/TypeScript (`examples/phoenix_host/e2e/`) |
| Config file | `test/test_helper.exs` (core exclude-tag logic, verified); `examples/phoenix_host/playwright.config.ts` (e2e) |
| Quick run command | `mix test test/crosswake/bridge/ test/crosswake/proof/phase154_*_test.exs` (targeted, hermetic) |
| Full suite command | `mix test --exclude requires_example_host --exclude advisory_only` (core hermetic, matches CI's `core-hermetic-proof` job exactly, §10); `cd examples/phoenix_host && npx playwright test route_tour.spec.ts` for the browser lane |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|--------------------|-------------|
| CTRL-01 | `Bridge.push/3` dispatches, correlated reply arrives via `handle_info/2` | unit | `mix test test/crosswake/bridge/push_test.exs` | ❌ Wave 0 |
| CTRL-02 | No-shell / old-shell / undeclared-capability collapse to one `Shell.Denial` shape | unit + browser | `mix test test/crosswake/shell/denial_test.exs`; Playwright shell-absent/shell-present/hook-unwired trio (D-38) | ❌ Wave 0 (denial reason addition); Playwright specs land in Phase 155 per D-38's own framing but the "hook deliberately unwired" case is THIS phase's proof of D-36 |
| CTRL-03 | Undeclared-capability route invocation raises with a named error | unit | `mix test test/crosswake/bridge/push_test.exs` (raise-path cases) | ❌ Wave 0 |
| CTRL-04 | Command vocabulary structurally closed | proof (merge-blocking) | `mix test test/crosswake/proof/phase154_catalog_guard_test.exs` | ❌ Wave 0 |
| CTRL-05 | Rebuild class surfaced in changelog/support-matrix/doctor | unit + existing guide test | `mix test test/crosswake/doctor/` (new finding); `mix test test/crosswake/guides/release_boundaries_test.exs` (existing, extend) | ❌ Wave 0 (doctor finding); ✅ existing (release_boundaries_test.exs) |
| PROOF-04 | Catalog line merge-blocking structural test, 4-way negative controls | proof (merge-blocking) | `mix test test/crosswake/proof/phase154_catalog_guard_test.exs` | ❌ Wave 0 |
| HRDN-01 | AdminPilot haptics runs through `Bridge.push/3`, IIFE deleted | browser (merge-blocking) | `cd examples/phoenix_host && npx playwright test route_tour.spec.ts` (existing file, extended assertions per D-75) | ✅ existing file, ❌ new assertions |

### Sampling Rate
- **Per task commit:** targeted `mix test` on the touched file(s) — e.g.
  `mix test test/crosswake/bridge/push_test.exs` after a `Bridge.push/3` change.
- **Per wave merge:** `mix test --exclude requires_example_host --exclude advisory_only`
  (core hermetic full suite, matches CI) plus, for HRDN-01/PR-3 waves, the Playwright
  `route_tour.spec.ts` run.
- **Phase gate:** both the core hermetic suite AND the Playwright route-tour suite green
  before `/gsd-verify-work`; per D-76's 3-PR sequencing, this likely means 3 separate
  green-gate checkpoints (vocabulary PR, seam PR, HRDN-01 PR) rather than one.

### Wave 0 Gaps
- [ ] `test/crosswake/bridge/push_test.exs` — covers CTRL-01, CTRL-03
- [ ] `test/crosswake/proof/phase154_catalog_guard_test.exs` — covers CTRL-04, PROOF-04 (mirror `phase130_extraction_guards_test.exs` structure + `ProofAssertions.stable_id_message/7`)
- [ ] `test/support/bridge_test_helpers.ex` (or `Crosswake.Bridge.Test`) — the `render_hook/3` correlation-id fabrication helper D-77 names as necessary scope, without which adopter tests (and this phase's own) cannot simulate a hook reply
- [ ] Doctor test coverage for the new `capability_rebuild_findings/1` — likely `test/crosswake/doctor/doctor_test.exs` (existing file, extend)
- [ ] Framework install: none — ExUnit and Playwright are already fully configured.

## Security Domain

`security_enforcement` absent from config → enabled. This phase's dominant domain is a new
client↔server RPC seam plus an authorization/authentication-adjacent capability
declaration, so ASVS categories V4 and V5 are directly applicable; V2/V3/V6 are not
materially touched by this phase's scope.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Out of scope — this phase does not touch login/session issuance. |
| V3 Session Management | no | Out of scope — the LiveView socket's own session/reconnect lifecycle is unchanged by this phase (D-24 explicitly keeps in-flight state non-durable across reconnects, which is itself a security-relevant "don't replay stale asks" choice, not a session-management change). |
| V4 Access Control | yes | `Registry.lookup/4` remains the single authorization source for both the raise (outbound preflight) and the denial (inbound) paths (D-04) — no new authorization surface is introduced; the existing manifest-backed allowlist is reused. |
| V5 Input Validation | yes | Every inbound wire reply/event is validated server-side before use: `Contract.Request`/`Reply` struct decoding, the new closed-vocabulary check on `reason` strings (D-16), and the reserved-event-name interception boundary (D-18) which prevents arbitrary client-sent event names from reaching adopter code unvalidated. |
| V6 Cryptography | no | Not touched — no new crypto primitive is introduced by this phase. |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Malicious/compromised WebView content spoofing a native reply (postMessage origin confusion) | Spoofing | Already enforced upstream of this phase: both native `BridgeChannel` implementations check `request.origin == session.allowedOrigin` / Android's `sourceOrigin` check before dispatch (verified in §6) — this phase's server-side reply parsing does not need to re-implement origin checking, but MUST NOT weaken it by trusting an unvalidated `origin` field from the reply path. |
| Client-sent arbitrary event name masquerading as the reserved bridge event, attempting to inject a fabricated "reply" into `handle_info/2` | Spoofing / Tampering | D-18's `attach_hook` interception decodes and validates BEFORE constructing any typed struct; the 3-layer compare-and-delete (D-23) means a `ref`/`correlation_id` that doesn't match an in-flight ask (including a foreign-epoch late reply, D-24) is dropped with telemetry, never delivered to adopter code as if legitimate. |
| Undeclared-capability probing (an attacker-controlled or buggy client attempting to invoke an unauthorized command) | Elevation of Privilege | CTRL-02/CTRL-03: undeclared capabilities either raise at the server-authoring boundary (outbound, D-04/D-05 — this can only be triggered by the app's OWN code, not a client) or resolve to `:undeclared_capability` denial (inbound, unchanged existing behavior) — no new attack surface, same `Registry.lookup/4` gate as today. |
| A rogue/duplicated hook element double-firing native side effects (e.g. two haptics taps from one user action) | Repudiation / minor DoS-of-intent | D-39's module-scoped single-owner guard in the hook itself. |

## Sources

### Primary (HIGH confidence — direct file reads and live probes against this repo/its installed dependency)
- `deps/phoenix_live_view/lib/phoenix_live_view/lifecycle.ex` (installed `phoenix_live_view 1.1.30`, pinned in `mix.lock`) — `attach_hook`/`handle_event` mechanics (§1)
- `mix run` probes against `Crosswake.Manifest.Types.new_capability/1` and a synthetic `@enforce_keys` module (§2)
- `lib/crosswake/manifest/builder.ex`, `lib/crosswake/manifest/types.ex`, `lib/crosswake/bridge/{contract,registry,denial}.ex`, `lib/crosswake/shell/denial.ex`, `lib/crosswake/companion_guard.ex`, `lib/crosswake/doctor/doctor.ex`, `lib/crosswake/telemetry.ex`, `lib/crosswake/native_escape/contract.ex`, `lib/crosswake/compatibility/compatibility.ex`
- `packages/crosswake-shell-core-ios/Sources/CrosswakeShellCore/BridgeChannel.swift`, `CrosswakeShell.swift`; `examples/ios_shell_host/CrosswakeShell/LiveViewContainerViewController.swift`
- `packages/crosswake-shell-core-android/src/main/java/dev/crosswake/shell/core/BridgeChannel.kt`, `CrosswakeDelegates.kt`; `examples/android_shell_host/.../LiveViewFragment.kt`
- `examples/phoenix_host/lib/crosswake_example/{saas_portal/approval_live.ex,bridge_proof_live.ex,router.ex,layouts.ex,endpoint.ex}`, `examples/phoenix_host/e2e/route_tour.spec.ts`
- `test/crosswake/proof/phase130_extraction_guards_test.exs`, `test/support/proof_assertions.ex`, `test/test_helper.exs`, `.github/workflows/phase130-proof.yml`
- `test/crosswake/guides/release_boundaries_test.exs`
- `.planning/seeds/SEED-006-native-navigation-shell.md`, `.planning/phases/149-saas-admin-showcase/149-CONTEXT.md`
- `mix.exs` (deps, docs config, package config)

### Secondary (MEDIUM confidence)
- None — every claim in this document was either directly read from repo/dependency source or probed live; no WebSearch was needed since this phase's mechanics are entirely internal to the already-chosen stack.

### Tertiary (LOW confidence)
- None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new dependency; existing `phoenix_live_view` version verified directly.
- Architecture: HIGH — `attach_hook`/`handle_info` mechanics verified against installed dependency source; every native-side and Elixir-side code claim verified by direct file read.
- Pitfalls: HIGH — all five pitfalls trace to a verified code read or live probe, not speculation.

**Research date:** 2026-07-29
**Valid until:** 30 days (stable — this phase's mechanics depend on `phoenix_live_view`'s
lifecycle-hook API, which is a mature, slow-moving part of that library; re-verify §1 if
`phoenix_live_view` is bumped past `1.1.x` before this phase executes).
