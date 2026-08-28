# Phase 154: The Control-Contract Seam - Pattern Map

**Mapped:** 2026-07-29
**Files analyzed:** 20 (new + modified)
**Analogs found:** 20 / 20 (all files have at least a role-match analog; several have exact matches, since RESEARCH.md already did precise line-level verification)

This phase is unusual: CONTEXT.md (77 decisions) and RESEARCH.md already pinned every
mechanism and verified it against the installed dependency and this repo's own source. This
PATTERNS.md exists to hand the planner copy-pasteable excerpts, not to re-derive design —
treat RESEARCH.md §1–§12 as the authoritative "how, precisely" companion to this file.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/crosswake/bridge.ex` (NEW facade: `push/3`, `resolve/2`, `attach/1`) | service/controller (LiveView-process RPC facade) | request-response + event-driven (async reply) | `lib/crosswake/bridge/registry.ex` + `lib/crosswake/bridge/contract.ex` (composition, no single facade precedent exists — confirmed no `bridge.ex` outside `bridge/` today) | role-match (new architecture, composed from siblings) |
| `lib/crosswake/bridge/catalog_guard.ex` (NEW) | utility (AST structural guard, lives in `lib/`) | transform (source string → violation list) | `lib/crosswake/companion_guard.ex` | exact |
| `lib/crosswake/shell/denial.ex` (EDIT: add `:shell_unreachable`, 14th reason) | model (closed enum + constructor) | CRUD (struct construction with reason-scoped defaulting) | itself — `Shell.Denial.new/1` + `ensure_commerce_corridor_payload/3` is the precedent for the new reason's details-defaulting clause | exact |
| `lib/crosswake/bridge/contract.ex` (EDIT: no structural change expected, `@commands` likely unchanged since `haptics.impact` already present) | model (Request/Reply structs) | transform (struct ↔ map) | itself | exact |
| `lib/crosswake/bridge/registry.ex` (EDIT: reused unchanged per D-04, `lookup/4` becomes dual-direction authorization source) | service (authorization lookup) | CRUD (read-only manifest lookup) | itself | exact |
| `lib/crosswake/bridge/denial.ex` (EDIT: moduledoc note demoting it to internal wire envelope, D-28) | model (wire-decode envelope) | transform | itself | exact |
| `lib/crosswake/manifest/types.ex` (`Capability` struct — EDIT: `@enforce_keys` gains `:rebuild`, `:interaction`; new `:interaction` field) | model | CRUD (struct/enforce_keys) | itself; sibling struct pattern `RouteEntry`/`PackEntry` etc. in same file for `@enforce_keys` + `@type` style | exact |
| `lib/crosswake/manifest/builder.ex` (`capability_catalog/0` EDIT: add `:interaction` to all 15 entries; `compatibility_capability_attrs/2` EDIT: fix self-referential `legacy_ids` + `:rebuild` nil-default fix) | service (compile-time literal builder) | batch (15-entry literal transform) | itself | exact |
| `lib/crosswake/doctor/doctor.ex` (`capability_rebuild_findings/1` NEW ~40 lines + wiring into the findings accumulation) | service (findings aggregator) | batch/transform | `native_rebuild_findings/2` (doctor.ex:1273-1297) | exact |
| `test/crosswake/proof/phase154_catalog_guard_test.exs` (NEW, merge-blocking, untagged) | test (proof/structural gate) | batch (walks `lib/**/*.ex`, asserts vocabulary closure) | `test/crosswake/proof/phase130_extraction_guards_test.exs` | exact |
| `test/crosswake/bridge/push_test.exs` (NEW) | test (unit) | request-response | `test/crosswake/bridge/registry_test.exs` / `contract_test.exs` (existing, not read in this pass but confirmed present by RESEARCH.md §5) | role-match |
| `test/crosswake/bridge/catalog_guard_test.exs` (NEW) | test (unit, predicate-level) | transform | `CompanionGuard`'s own non-vacuity test pattern in `phase130_extraction_guards_test.exs` (synthetic violating/valid source strings) | exact |
| `test/support/bridge_test_helpers.ex` or `Crosswake.Bridge.Test` (NEW — `render_hook/3` correlation-id fabrication helper) | utility (test support) | transform | `test/support/proof_assertions.ex` (support-module shape: `@moduledoc false`, pure helper functions, no `use ExUnit.Case`) | role-match |
| `priv/static/crosswake.esm.js` (NEW, hand-authored ESM hook) | component (client-side, protocol-sensitive, not presentation) | event-driven (postMessage transport + ack/deadline) | none in-repo (no existing JS hook shipped by core) — nearest analog is the **IIFE being replaced** (`approval_live.ex`'s `bridge_script/1`) for the transport-detection logic to fix (D-35), plus native `BridgeChannel.swift`/`.kt` for the wire shape it must speak | no analog (new client surface); see "No Analog Found" |
| `lib/mix/tasks/crosswake.gen.bridge_hook.ex` (NEW — refuse-and-teach generator) | utility (mix task) | transform (prints instructions, no file write without `--eject`) | `lib/mix/tasks/crosswake.gen.offline_ui.ex` (explicitly named as the generator this phase does **NOT** mirror the copy-behavior of, per D-31 — but its mix-task scaffolding/option-parsing shape is still the closest existing task) | role-match (behavior deliberately differs) |
| `examples/phoenix_host/lib/crosswake_example/router.ex:330` (EDIT: `capabilities: ["haptics.impact"]` → `["haptics"]`) | route/config | CRUD (declarative) | itself; line 253 (`capabilities: ["share"]`) is the in-file precedent for the family-id form | exact |
| `examples/phoenix_host/lib/crosswake_example/saas_portal/approval_live.ex` (EDIT: HRDN-01 migration) | controller (LiveView) | request-response + event-driven | `examples/phoenix_host/lib/crosswake_example/bridge_proof_live.ex` (near-identical sibling IIFE/pattern, D-70 migrates both together) | exact |
| `examples/phoenix_host/lib/crosswake_example/bridge_proof_live.ex` (EDIT: HRDN-01 migration, D-70) | controller (LiveView) | request-response + event-driven | `approval_live.ex` (same IIFE pattern, mutual analog) | exact |
| `examples/phoenix_host/lib/crosswake_example/layouts.ex` (EDIT: add hook import + `hooks:` map to `LiveSocket`) | config (root layout) | — | itself (no-bundler bare-ESM `<script type="module">` import pattern already shown for `phoenix.mjs`/`phoenix_live_view.esm.js`) | exact |
| `examples/phoenix_host/lib/crosswake_example/endpoint.ex` (EDIT: add 4th `Plug.Static` block for `priv/static/crosswake.esm.js`) | config (endpoint) | file-I/O (static serving) | itself (3 existing `Plug.Static ... from: :dep_name` blocks) | exact |
| `examples/phoenix_host/assets/js/app.js` (DELETE, D-71) | component (dead code) | — | — | delete, no analog needed |
| `examples/phoenix_host/e2e/route_tour.spec.ts` (EDIT: lines 168, 196-201, 431-438 + new hook-unwired test, D-38/D-74) | test (e2e/Playwright) | event-driven (browser) | itself (existing `bridgePayload()`/`approvalHapticsPayload()` helpers are the direct precedent for the `data-cw-envelope` + `JSON.parse` replacement) | exact |
| `.planning/seeds/SEED-006-native-navigation-shell.md:71` (amend, D-72) | doc | — | — | doc-only, no code analog |
| `.planning/phases/149-saas-admin-showcase/149-CONTEXT.md` (amend D-07/D-12, D-73) | doc | — | — | doc-only, no code analog |

## Pattern Assignments

### `lib/crosswake/bridge/catalog_guard.ex` (utility, transform) — mirrors `CompanionGuard` exactly

**Analog:** `lib/crosswake/companion_guard.ex` (full file read, 277 lines)

**Moduledoc / framing pattern:**
```elixir
defmodule Crosswake.CompanionGuard do
  @moduledoc """
  Merge-blocking AST guards for Phase 130 companion extraction.

  This module is a plain support module (NO `use ExUnit.Case`) callable from
  proof tests and — post-publish — from each companion package's own test suite.
  The guard travels with the code (D-17).
  ...
  """
```
`CatalogGuard` should open the same way, naming D-43 instead of D-17, and stating it lives
in `lib/` (not `test/`) specifically so `mix crosswake.doctor` can call the same predicates.

**Pure predicate + AST walk pattern (the core technique, verbatim reusable shape):**
```elixir
@spec check_source(String.t()) :: :ok | {:violation, list()}
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

      node, acc ->
        {node, acc}
    end)

  if violations == [], do: :ok, else: {:violation, violations}
end
```
For `CatalogGuard`, this same `Code.string_to_quoted/2` + `Macro.prewalk/3` shape should back
each of D-44's mechanical sub-checks: `@commands` is a literal (walk for a `{:@, _, [{:commands, ...}]}` node whose value is a literal list, not built via `++`/`Enum`/interpolation), no `register_*` function defined anywhere in `lib/crosswake/bridge/**`, no `apply/3` call, no atom-minting (`String.to_atom/1` outside a frozen allowlist) in the bridge tree.

**Prune-then-walk pattern (for a multi-step structural assertion, e.g. native-enum-parity check):**
```elixir
# Step 1: collect subtrees, Step 2: find target nodes, Step 3: assert containment
{_, body_subtrees} = Macro.prewalk(ast, [], fn ... end)
{_, ensure_nodes} = Macro.prewalk(ast, [], fn ... end)
ast_violations = Enum.filter(ensure_nodes, fn node -> not Enum.any?(body_subtrees, ...) end)
```
Use this exact shape for D-44(d)'s native-enum-parity sub-assertion: find the Swift/Kotlin
`BridgeCommand` enum block (D-46: "job not found is a failure, not a pass" — carry forward
Phase 134's guard) and assert every entry has a corresponding `Contract.@commands` string,
and vice versa.

**Raiser wrapper pattern (stable-id message construction, exact shape to copy):**
```elixir
@spec assert_no_static_refs!() :: :ok
def assert_no_static_refs! do
  lib_files = Path.wildcard(Path.join(File.cwd!(), "lib/**/*.ex"))
  ...
  violations = ...

  if violations != [] do
    for {path, mod} <- violations do
      raise "[proof.extract_03.static_ref.#{Path.basename(path, ".ex")}] " <>
              "subject=lib/ must not statically reference an extracted companion " <>
              "source=CompanionGuard.assert_no_static_refs!/0 " <>
              "observed=found alias #{inspect(mod)} in #{path} " <>
              "path=#{path} " <>
              "hint=remove the static reference — use the :companions registry seam instead (EXTRACT-03) " <>
              "posture=merge_blocking"
    end
  end

  :ok
end
```
`CatalogGuard.assert_catalog_closed!/0` (or similarly named) should use this exact
`[stable.id] subject=... source=... observed=... path=... hint=... posture=merge_blocking`
shape, but per D-48 the failure message must ALSO append a teaching heredoc naming which of
the six criteria failed, why the closed vocabulary exists (Cordova precedent), the six-step
recipe for adding control #7, and the closing brand-voice line: *"This gate does not exist to
stop control #7. It exists to make control #7 look exactly like controls #1-6."*

---

### `test/crosswake/proof/phase154_catalog_guard_test.exs` (proof test) — mirrors `phase130_extraction_guards_test.exs`

**Analog:** `test/crosswake/proof/phase130_extraction_guards_test.exs` (full file, 271 lines) + `test/support/proof_assertions.ex` (full file, 96 lines)

**File-level framing (moduledoc + use + aliases, copy this shape exactly):**
```elixir
defmodule Crosswake.Proof.Phase130ExtractionGuardsTest do
  @moduledoc """
  Merge-blocking proof lane for Phase 130 EXTRACT-01/03/04.
  ...
  Runs UNTAGGED. async: true (read-only source/config). Must NOT carry
  :requires_example_host or :engine_present tags (D-18).
  """

  use ExUnit.Case, async: true

  alias Crosswake.TestSupport.ProofAssertions
  alias Crosswake.CompanionGuard
```
`Phase154CatalogGuardTest` should state D-47 (no new workflow file — picked up by the existing
hermetic lane) instead of D-18, but the `async: true`, untagged, `ProofAssertions` +
`CatalogGuard` alias shape is identical.

**`stable_id_message/7` helper (the exact function signature to call, from `proof_assertions.ex`):**
```elixir
def stable_id_message(id, subject, source, observed, path, hint, posture) do
  """
  [#{id}] subject=#{subject} source=#{source} observed=#{observed} path=#{path} hint=#{hint} posture=#{posture}
  """
  |> String.trim()
end
```
Every assertion in `phase154_catalog_guard_test.exs` should call this with 7 positional args
exactly as `phase130_extraction_guards_test.exs` does — do not hand-roll a different message
format.

**Non-vacuity test pattern (synthetic violating input, exact shape to replicate per D-46):**
```elixir
test "CompanionGuard.check_source/1 detects Crosswake.Companions.Rulestead alias — non-vacuity (EXTRACT-03)" do
  violating = "alias Crosswake.Companions.Rulestead"

  assert {:violation, _} = CompanionGuard.check_source(violating),
         ProofAssertions.stable_id_message(
           "proof.extract_03.non_vacuity.rulestead_detected",
           "check_source/1 must detect Crosswake.Companions.Rulestead alias",
           "CompanionGuard.check_source/1",
           "check_source returned :ok for violating input — guard is not implemented yet",
           "lib/crosswake/companion_guard.ex",
           "Plan 03 must implement AST walk to detect {:__aliases__, _, [:Crosswake, :Companions, :Rulestead]} (EXTRACT-03)",
           :merge_blocking
         )
end
```
D-46 requires FOUR kinds of negative control for CatalogGuard: (1) a multi-violation fixture
reporting all violated criteria at once, not just the first; (2) one inline synthetic per
sub-assertion (mirror the above per criterion); (3) a positive control on real shipped code
(mirror the `route_gate.ex` "NOT flagged" test below); (4) an orphan-detection check.

**Positive-control-on-real-code pattern (proves no false positives on shipped source):**
```elixir
test "A real core file (route_gate.ex) is NOT flagged by check_source/1 — ..." do
  route_gate_source = File.read!(Path.join(File.cwd!(), "lib/crosswake/compatibility/route_gate.ex"))

  assert :ok = CompanionGuard.check_source(route_gate_source),
         ProofAssertions.stable_id_message(...)
end
```
Use `lib/crosswake/manifest/builder.ex` (the actual `capability_catalog/0` source) as the
real-file positive control for `CatalogGuard`.

**Trailing hermetic-lane self-assertion (must always be the LAST test in the file):**
```elixir
test "hermetic lane guard: this proof file carries no @moduletag (D-18)" do
  source = File.read!(__ENV__.file)

  refute Regex.match?(~r/^\s*@moduletag\s+:/m, source),
         "Phase 130 extraction guards proof file must not carry @moduletag: tags — it runs untagged (D-18)"
end
```
Copy this verbatim (renaming the D-reference to D-47) as the last test in
`phase154_catalog_guard_test.exs` — it is what makes D-47's "no new workflow file" claim
self-verifying.

---

### `lib/crosswake/doctor/doctor.ex` — `capability_rebuild_findings/1` (NEW)

**Analog:** `native_rebuild_findings/2` at `lib/crosswake/doctor/doctor.ex:1273-1297`, and the `check/6` helper at line 1947.

**The exact finding-emission shape to mirror:**
```elixir
defp native_rebuild_findings([], _opts), do: []

defp native_rebuild_findings(rebuild_requirements, opts) do
  case Keyword.get(opts, :native_rebuild_satisfied?, false) do
    true ->
      []

    false ->
      Enum.map(rebuild_requirements, fn requirement ->
        check(
          :warning,
          "commerce.corridor.native_rebuild_required",
          "commerce_summary",
          "route #{requirement.route_id} corridor #{requirement.corridor_ref} (#{requirement.role}) requires a native or companion rebuild before commerce support can advance",
          "rebuild the corridor's native or companion artifacts and rerun doctor with native_rebuild_satisfied?: true after the corresponding proof lane passes",
          %{
            route_id: requirement.route_id,
            corridor_ref: requirement.corridor_ref,
            role: requirement.role,
            proof_class: "merge_blocking"
          }
        )
      end)
  end
end
```

**The `check/6` builder it calls:**
```elixir
defp check(severity, code, check_name, message, hint, details \\ %{}) do
  %Check{
    severity: severity,
    code: code,
    check: check_name,
    message: message,
    hint: hint,
    details: details
  }
end
```

`capability_rebuild_findings/1` (D-49, ~40 lines) should follow this exact
`check(:warning, code, subject, message, hint, details)` shape, keyed off capabilities whose
`rebuild != :none` declared on at least one active route, with a code like
`"bridge.capability.native_rebuild_required"`. Wire it into the accumulation list the same
way `phase_66_generator_drift_findings` is folded in near doctor.ex line ~161:
```elixir
phase_66_findings = phase_66_generator_drift_findings(manifest, cwd, opts)
...
findings = findings ++ ... ++ phase_66_findings
```
Add `capability_rebuild_findings(manifest)` (or similar) to this same accumulation chain —
no new aggregation mechanism needed.

---

### `lib/crosswake/manifest/types.ex` — `Capability` struct edits (D-51/D-52/D-54)

**Analog:** the struct itself, current shape:
```elixir
defmodule Capability do
  @moduledoc false

  @enforce_keys [:id, :version]
  defstruct [
    :id, :version, :family, :owner, :package_class, :proof_class,
    :rebuild, :denial, :fallback, :guide,
    status: :supported, prerequisites: [], legacy_ids: []
  ]

  @type status :: :supported | :verification_required | :unsupported
  @type owner :: :bounded_bridge | :native_screen | :backend_seam | :activation | :defer
  @type package_class :: :core | :companion | :example_docs_only | :defer
  @type proof_class :: :merge_blocking | :advisory
  @type rebuild :: :none | :native_required | :companion_required
  ...
end
```
Target shape: `@enforce_keys [:id, :version, :rebuild, :interaction]`, add `interaction` to
`defstruct`, add `@type interaction :: :fire_and_forget | :device_answer | :user_answer`, add
`interaction: interaction()` to `@type t ::`.

**VERIFIED BLAST RADIUS (RESEARCH.md §2, do not undersize this task):** adding `:rebuild` to
`@enforce_keys` is a no-op today (the map always carries the key via
`Keyword.get(attrs, :rebuild, :none)` in `new_capability/1`). Adding `:interaction` **will**
break `new_capability/1` and all ~17 call sites (15 `capability_catalog/0` entries + 2
`compatibility_capability_attrs/2` branches) with `ArgumentError` unless `new_capability/1`
itself is updated in the same change to require/supply `:interaction`. Treat "add
`:interaction` to the struct" and "update `new_capability/1` + all 15 catalog entries + both
compatibility branches" as one atomic task — this is the sizing note RESEARCH.md's Pitfall 5
exists to prevent.

---

### `lib/crosswake/manifest/builder.ex` — `capability_catalog/0` entries (add `:interaction`) + `compatibility_capability_attrs/2` fix

**Analog:** the catalog itself (245-455) — per-entry keyword-list shape to extend:
```elixir
[
  id: "haptics",
  family: "haptics",
  owner: :bounded_bridge,
  package_class: :core,
  proof_class: :merge_blocking,
  rebuild: :none,
  prerequisites: ["declared route capability", "bounded bridge support"],
  denial: "undeclared_capability",
  fallback: "Phoenix route continues without native confirmation feedback",
  guide: "guides/bridge.md#bounded-bridge",
  legacy_ids: ["haptics.impact"]
],
```
Add `interaction: :fire_and_forget` (haptics is the D-54 honesty case — it returns no
payload). Note the `"haptics"` catalog entry with `legacy_ids: ["haptics.impact"]` is
**already the family-form entry the router migration (D-61) targets** — confirms no new
catalog entry is needed, only the router declaration flips to reference it directly instead
of via the legacy alias.

**The self-referential `legacy_ids` bug (D-60, VERIFIED exact) — the fix site:**
```elixir
defp family_capability_for(capability_id) do
  Enum.find(capability_catalog(), fn attrs ->
    capability_id in Keyword.get(attrs, :legacy_ids, [])
  end)
end

defp compatibility_capability_attrs(nil, capability_id) do
  [
    id: capability_id,
    version: capability_version(capability_id)
  ]
end

defp compatibility_capability_attrs(attrs, capability_id) do
  attrs
  |> Keyword.put(:id, capability_id)
  |> Keyword.put(:version, capability_version(capability_id))
  |> Keyword.put(:family, Keyword.fetch!(attrs, :family))
end
```
Fix: this second clause must `Keyword.delete(attrs, :legacy_ids)` (or similarly drop it)
before returning, since the constructed compatibility-path capability's own `id` currently
survives inside its own `legacy_ids` list.

**The `nil`-rebuild tolerant-default site (D-51, `Types.new_capability/1`, confirmed present):**
```elixir
rebuild: Keyword.get(attrs, :rebuild, :none),   # always present in the map, defaults :none
```
RESEARCH.md's live probe shows this produces `:none` today, not `nil` as D-51 literally
claims — still land the defensive fail-closed default (recommend `:native_required` per
D-51's stated intent, not `:none`) but describe the task as "harden the default," not "fix an
observed crash."

---

### JS hook transport-check fix (D-35) — the exact bug to NOT reproduce

**Analog (the bug, currently shipping in the IIFE being replaced):** `examples/phoenix_host/lib/crosswake_example/saas_portal/approval_live.ex:224-237` and the byte-identical sibling in `bridge_proof_live.ex:119-130`:
```elixir
defp bridge_script(request) do
  payload = Jason.encode!(request)

  """
  (() => {
    const payload = #{Jason.encode!(payload)};
    if (window.webkit?.messageHandlers?.crosswakeBridge) {
      window.webkit.messageHandlers.crosswakeBridge.postMessage(payload);
    } else if (window.crosswakeBridge?.postMessage) {
      window.crosswakeBridge.postMessage(payload);
    }
  })();
  """
end
```
This IIFE actually gets the ORDER right already (`webkit.messageHandlers` first) but only
checks `?.postMessage` truthiness, not `typeof === "function"`. The NEW `priv/static/crosswake.esm.js` hook must additionally typecheck:
```javascript
function findTransport() {
  const wk = window.webkit?.messageHandlers?.crosswakeBridge;
  if (wk && typeof wk.postMessage === "function") return wk;
  const android = window.crosswakeBridge;
  if (android && typeof android.postMessage === "function") return android;
  return null;
}
```
D-35's exact hazard: `window.crosswakeBridge` on iOS is a facts-only bag
(`.capabilities`/`.threadId`, no `.postMessage`) injected at document-start — `??` chaining
without a typecheck can resolve to it and silently post into the void. Add a unit test for
exactly this shape (a stub `window.crosswakeBridge = {capabilities: {...}}` with no
`postMessage`, asserting the hook does NOT call anything on it).

---

### `examples/phoenix_host/lib/crosswake_example/saas_portal/approval_live.ex` — HRDN-01 migration target

**Analog:** the file itself (full read, 238 lines) — this IS the file being migrated, and `bridge_proof_live.ex` is its migration sibling (D-70, same IIFE, migrate both together).

**Current hand-built envelope (`haptics_request/1`) — D-67 forbids "more hand-copying," must instead render straight from whatever `Bridge.push/3` returns:**
```elixir
defp haptics_request(approval_id) do
  %{
    "protocol" => @bridge_protocol,
    "version" => @bridge_capability_version,
    "command" => "haptics.impact",
    "capability" => "haptics.impact",
    "route_id" => @bridge_route_id,
    "active_route_id" => @bridge_route_id,
    "origin" => @shell_origin,
    "native_runtime_version" => "1.0.0",
    "correlation_id" => "approval-haptics-#{approval_id}",
    "capabilities" => %{"haptics.impact" => @bridge_capability_version},
    "installed_packs" => %{},
    "payload" => %{"style" => "light"}
  }
end
```
Post-migration this whole function is replaced by a call to `Crosswake.Bridge.push(socket, "haptics", payload: %{"style" => "light"})` inside the `{:ok, approved}` branch of `handle_event("approve", ...)` (D-73: after the context commits, strengthening not rewriting the Phase 149 contract).

**Current evidence-panel `<dl>` rendering from `@bridge_request` (D-64 keeps this shape, splits into `bridge_dispatch` + `bridge_reply`):**
```heex
<dl :if={@bridge_request}>
  <dt>Command</dt>
  <dd>{@bridge_request["command"]}</dd>
  <dt>Capability</dt>
  <dd>{@bridge_request["capability"]}</dd>
  <dt>Route</dt>
  <dd>{@bridge_request["route_id"]}</dd>
  <dt>Correlation</dt>
  <dd>{@bridge_request["correlation_id"]}</dd>
</dl>
```
Migration adds a Reply row (`role="status" aria-live="polite" aria-atomic="true"`) per D-64,
relabels rows per D-66 ("Capability (route policy)" vs "Command (wire protocol)"), and emits
`data-cw-envelope={Jason.encode!(...)}` on the enclosing `<section>` per D-74's mitigation for
the e2e helper below.

**The IIFE to delete entirely (D-40 CSP hardening, D-71-adjacent):**
```heex
<script :if={@bridge_request} id="crosswake-approval-haptics">
  <%= Phoenix.HTML.raw(bridge_script(@bridge_request)) %>
</script>
```
Deleted along with `defp bridge_script/1`. No replacement `<script>` tag — the hook element
(`phx-hook="CrosswakeBridge"`) lives once in the layout per D-30/D-39, not per-LiveView.

---

### `examples/phoenix_host/e2e/route_tour.spec.ts` — the required-check assertions to update

**Analog:** the file itself, exact lines verified.

**Line ~168 (VERIFIED must change in PR #1, not called out by name in CONTEXT.md's decision text — RESEARCH.md §4 flags this explicitly):**
```typescript
expect(router, ownerMessage('saas-approval', 'bounded haptics capability'))
  .toContain('capabilities: ["haptics.impact"]');
```
Must become `.toContain('capabilities: ["haptics"]')` in the SAME PR as `router.ex:330`'s
flip, or the vocabulary PR (D-76 PR #1, described as "no behavior change") breaks this
required check.

**Lines ~196-201 (post-approval haptics assertions — these key names must survive the migration unchanged):**
```typescript
const hapticsPayload = await approvalHapticsPayload(page);
expect(hapticsPayload.command, ...).toBe('haptics.impact');
expect(hapticsPayload.capability, ...).toBe('haptics.impact');
expect(hapticsPayload.route_id, ...).toBe('saas-approval');
expect(hapticsPayload.active_route_id, ...).toBe('saas-approval');
expect(hapticsPayload.protocol, ...).toBe('crosswake.bridge');
```
Note: `hapticsPayload.capability` stays `'haptics.impact'` — that's the WIRE COMMAND
(unchanged, D-62), not the route-policy capability id (which becomes `"haptics"`). Do not
conflate the two when updating this block.

**Lines ~431-438 — the highest-risk single edit in the phase (D-74), current regex-scrape:**
```typescript
async function approvalHapticsPayload(page: Page) {
  const script = page.locator('#crosswake-approval-haptics');
  await expect(script, ownerMessage('saas-approval', 'post-success haptics script')).toHaveCount(1);
  const source = await script.evaluate((element) => element.innerHTML);
  const match = source.match(/const payload = ("(?:\\.|[^"\\])*");/);
  expect(match?.[1], ownerMessage('saas-approval', 'post-success haptics payload source')).toBeTruthy();
  return JSON.parse(JSON.parse(match![1]));
}
```
This locates the `<script>` tag being DELETED. Mitigation (already decided, D-74): the panel
emits `data-cw-envelope={Jason.encode!(...)}` on its `<section>`, and this helper becomes:
```typescript
async function approvalHapticsPayload(page: Page) {
  const section = page.locator('[data-cw-envelope]').first(); // scope to the haptics panel
  await expect(section, ownerMessage('saas-approval', 'post-success haptics envelope')).toHaveCount(1);
  const raw = await section.getAttribute('data-cw-envelope');
  expect(raw, ownerMessage('saas-approval', 'post-success haptics envelope attr')).toBeTruthy();
  return JSON.parse(raw!);
}
```
The sibling helper for `bridge_proof_live.ex`'s `#crosswake-bridge-payload` `<pre>` (lines
~423-429) is UNCHANGED — D-70/D-68 explicitly preserve that raw `<pre>` surface.

---

### `examples/phoenix_host/lib/crosswake_example/layouts.ex` — hook wiring target

**Analog:** the file itself (full read, 39 lines) — confirms D-75 exactly: no `hooks:` option passed today.

**Current `<script type="module">` block (the bare-ESM-import precedent to extend):**
```heex
<script type="module">
  import {Socket} from "/phoenix/phoenix.mjs";
  import {LiveSocket} from "/phoenix_live_view/phoenix_live_view.esm.js";

  const csrfToken = document.querySelector("meta[name='csrf-token']")?.getAttribute("content");
  const params = csrfToken ? {_csrf_token: csrfToken} : {};
  const liveSocket = new LiveSocket("/live", Socket, {params});
  liveSocket.connect();
  window.liveSocket = liveSocket;
</script>
```
Migration adds a third bare import (`import {CrosswakeBridge} from "/crosswake/crosswake.esm.js";` or similar, matching wherever `endpoint.ex`'s new `Plug.Static` mounts it) and passes
`hooks: {CrosswakeBridge}` (or equivalent) into the `LiveSocket` constructor's options object,
alongside `params`.

---

### `examples/phoenix_host/lib/crosswake_example/endpoint.ex` — static-serving target

**Analog:** the three existing `Plug.Static` blocks (lines 18-37, verbatim):
```elixir
plug(Plug.Static,
  at: "/",
  from: :crosswake_example,
  gzip: false,
  only: ~w(brand css offline_study.js storage_budget.test.js storage_logic.js)
)

plug(Plug.Static,
  at: "/phoenix",
  from: :phoenix,
  gzip: false,
  only: ~w(phoenix.mjs)
)

plug(Plug.Static,
  at: "/phoenix_live_view",
  from: :phoenix_live_view,
  gzip: false,
  only: ~w(phoenix_live_view.esm.js)
)
```
Add a fourth block: `plug(Plug.Static, at: "/crosswake", from: :crosswake, gzip: false, only: ~w(crosswake.esm.js))` (path must match wherever `priv/static/` places the file and whatever `layouts.ex`'s import path names — keep these three things — `priv/static/` location, this `Plug.Static` block, and the `layouts.ex` import path — consistent in the same PR).

## Shared Patterns

### Stable-id proof-assertion message format
**Source:** `test/support/proof_assertions.ex:8-13` (`stable_id_message/7`)
**Apply to:** every new assertion in `test/crosswake/proof/phase154_catalog_guard_test.exs`, and any unit test wanting the same greppable-bracket convention.
```elixir
def stable_id_message(id, subject, source, observed, path, hint, posture) do
  """
  [#{id}] subject=#{subject} source=#{source} observed=#{observed} path=#{path} hint=#{hint} posture=#{posture}
  """
  |> String.trim()
end
```

### AST-guard pure-predicate + raiser split
**Source:** `lib/crosswake/companion_guard.ex` (`check_source/1` + `assert_no_static_refs!/0`)
**Apply to:** `Crosswake.Bridge.CatalogGuard` — every mechanical criterion in D-44 should expose a pure `check_*/1` (testable with synthetic strings, callable from doctor) plus one `assert_*!/0` merge-blocking wrapper.

### Doctor finding accumulation
**Source:** `lib/crosswake/doctor/doctor.ex:1273-1297` (`native_rebuild_findings/2`) + `check/6` at line 1947, plus the accumulation chain near line ~161.
**Apply to:** `capability_rebuild_findings/1` — same `check(:warning, code, subject, message, hint, details)` shape, folded into the existing `findings ++ ...` chain, no new aggregation mechanism.

### Authorization single-source-of-truth
**Source:** `lib/crosswake/bridge/registry.ex` — `Registry.lookup/4`, `{:error, :inactive_route | :unsupported_command | :undeclared_capability}`.
**Apply to:** `Crosswake.Bridge.push/3`'s raise path (turn `{:error, :undeclared_capability}` into `UndeclaredCapabilityError` outbound) and the existing inbound denial path — same function, direction picks the outcome (D-04). No new authorization logic anywhere in this phase.

### Reserved-event interception via `attach_hook`
**Source:** verified directly against installed `phoenix_live_view 1.1.30` (`deps/phoenix_live_view/lib/phoenix_live_view/lifecycle.ex`), not an in-repo file — see RESEARCH.md §1 for the full verified mechanics and the only-supported-shape conclusion.
**Apply to:** `Crosswake.Bridge.attach/1` — `attach_hook(socket, :crosswake_bridge, :handle_event, &handle_bridge_event/3)`, hook halts + `send(self(), {:crosswake_bridge, ref, %Reply{}})` for recognized events, `{:cont, socket}` for everything else.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `priv/static/crosswake.esm.js` | component (client JS hook) | event-driven | No existing library-owned JS asset ships from this repo's `priv/static/` today (the two existing static files are CSS: `offline.css`/`tokens.css` per RESEARCH.md's Assumptions Log A2). Build fresh per D-30/D-34/D-35/D-36/D-39, using the native `BridgeChannel.swift`/`.kt` wire shape and the IIFE-being-replaced's transport-check bug (D-35) as the two things to get right. |
| `lib/mix/tasks/crosswake.gen.bridge_hook.ex` | mix task (refuse-and-teach) | transform | No existing "refuses without a flag and prints instructions" task in this repo — `crosswake.gen.offline_ui.ex` is the nearest sibling but is explicitly the copy-behavior D-31 rejects mirroring. Build the refusal/teaching text fresh, informed by D-33's spec. |
| `lib/crosswake/bridge.ex` (new facade) | service | request-response + event-driven | Confirmed no existing facade module exists outside `bridge/` subdirectory (RESEARCH.md §5, `find` returned no match). Compose from `Registry.lookup/4`, `Contract.new_request/1`, `Shell.Denial.new/1`, and the new `attach_hook` pattern — no single existing file to copy wholesale. |

## Metadata

**Analog search scope:** `lib/crosswake/**`, `test/crosswake/**`, `test/support/**`, `examples/phoenix_host/lib/**`, `examples/phoenix_host/e2e/**`, `examples/phoenix_host/assets/**`, native `packages/crosswake-shell-core-{ios,android}/**` (read via RESEARCH.md's prior verification, not re-read here).
**Files scanned directly in this pass:** `lib/crosswake/companion_guard.ex`, `test/crosswake/proof/phase130_extraction_guards_test.exs`, `test/support/proof_assertions.ex`, `lib/crosswake/bridge/contract.ex`, `lib/crosswake/bridge/registry.ex`, `lib/crosswake/shell/denial.ex`, `lib/crosswake/bridge/denial.ex`, `lib/crosswake/manifest/types.ex` (Capability + siblings), `lib/crosswake/manifest/builder.ex` (catalog + compatibility_capability_attrs), `lib/crosswake/doctor/doctor.ex` (native_rebuild_findings + check/6), `examples/phoenix_host/lib/crosswake_example/saas_portal/approval_live.ex`, `examples/phoenix_host/lib/crosswake_example/bridge_proof_live.ex` (excerpt), `examples/phoenix_host/lib/crosswake_example/layouts.ex`, `examples/phoenix_host/lib/crosswake_example/endpoint.ex`, `examples/phoenix_host/lib/crosswake_example/router.ex` (grep), `examples/phoenix_host/e2e/route_tour.spec.ts` (targeted sections).
**Pattern extraction date:** 2026-07-29

---

*Phase: 154-the-control-contract-seam*
