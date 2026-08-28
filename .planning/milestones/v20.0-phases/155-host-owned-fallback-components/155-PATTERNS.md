# Phase 155: Host-Owned Fallback Components - Pattern Map

**Mapped:** 2026-07-30
**Files analyzed:** 15 (new + modified)
**Analogs found:** 15 / 15

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|--------------------|------|-----------|-----------------|----------------|
| `lib/mix/tasks/crosswake.gen.native_controls_ui.ex` | mix generator task | file-I/O (copy templates) | `lib/mix/tasks/crosswake.gen.bridge_hook.ex` (stamp/no-clobber) + `lib/mix/tasks/crosswake.gen.offline_ui.ex` (multi-file `ensure_file` loop) | exact (composite of two) |
| `priv/templates/crosswake/native_controls_ui/crosswake_fallbacks.ex.eex` | component template | request-response (HEEx render + `handle_event`) | `priv/templates/crosswake/offline_ui/*.eex` (shape) + `lib/crosswake/bridge.ex` `resolve/2` (the wiring copied inside) | role-match |
| `priv/templates/crosswake/native_controls_ui/crosswake_fallback.css.eex` | stylesheet template | transform (tokens → alias layer) | `priv/static/crosswake/offline.css` (zero theme-logic precedent) | exact |
| `lib/crosswake/component_tier_guard.ex` | structural guard | batch (AST walk over `lib/**/*.ex`) | `lib/crosswake/companion_guard.ex` + `lib/crosswake/bridge/catalog_guard.ex` | exact |
| `test/crosswake/component_tier_guard_test.exs` | test (structural proof) | batch | `test/crosswake/proof/phase154_recipe_followable_test.exs` (root: injection seam usage) | role-match |
| `lib/crosswake/bridge.ex` (MODIFIED — D-50, D-51) | service/seam | request-response | itself (existing `push/3`/`resolve/2`/`raise_undeclared_capability!/3`) | exact (in-place edit) |
| `lib/crosswake/bridge/contract.ex` or new error module (D-51 `UnknownCapabilityFamilyError`) | model (error type) | event-driven (raise) | `Crosswake.Bridge.UndeclaredCapabilityError` / `Crosswake.Bridge.NotMountedError` (`lib/crosswake/bridge.ex:1-30`) | exact |
| `test/crosswake/bridge_test.exs` (MODIFIED) | test | request-response | itself (extend existing file) | exact |
| `lib/crosswake/install/patcher.ex` (MODIFIED — D-52, D-26) | installer/patcher | file-I/O (idempotent text patch) | itself (`ensure_endpoint_block/1`, `endpoint_static_plug_block/1`) | exact (in-place edit) |
| `lib/crosswake/doctor/doctor.ex` (MODIFIED — 2 findings) | service (diagnostics) | batch | itself (`:2131-2160` stamp-drift finding pattern) | exact (in-place edit) |
| `brandbook/tokens/crosswake.tokens.json` (MODIFIED — 2 tokens) | config/data | transform | itself (existing `status`/`action` groups) | exact |
| `brandbook/tools/compile-tokens.js` (MODIFIED — `groups` array) | build tooling | transform | itself (`:67`) | exact (in-place edit) |
| `brandbook/tools/contrast.test.mjs` (MODIFIED — focus-ring pairs) | test | batch | itself (`:96-122` existing text-pair tests) | exact (in-place edit) |
| `brandbook/tools/check-consumer-drift.mjs` (MODIFIED — MANIFEST) | config/data (curated array) | batch | itself (`MANIFEST` array `:29-43`) | exact (in-place edit) |
| `examples/phoenix_host/e2e/native_controls_fallback.spec.ts` | e2e test | request-response (browser) | `examples/phoenix_host/e2e/evidence_panel.spec.ts` (compositing walk, MutationObserver invariant) + `route_tour.spec.ts` (read-from-source discipline) | exact |
| `examples/phoenix_host/lib/crosswake_example/router.ex` (MODIFIED — `/_e2e/undeclared-control`) | route | request-response | itself (`:581-593` existing `/_e2e` scope) | exact (in-place edit) |
| `examples/phoenix_host/lib/crosswake_example/e2e/*_controller.ex` (new) | controller | request-response | existing `CrosswakeExample.E2E.SyncStateController` / `NativeClaimController` (test-only controllers, same namespace) | role-match |
| `examples/phoenix_host/lib/crosswake_example/endpoint.ex` (MODIFIED — 2nd `Plug.Static`) | config | request-response (static asset) | itself (existing `/crosswake` `Plug.Static` block, `:37-45`) | exact (in-place edit) |
| `script/check-e2e-honesty.mjs` (MODIFIED — FILES array) | config/data (curated array) | batch | itself (`:55-60`) | exact (in-place edit) |

## Pattern Assignments

### `lib/mix/tasks/crosswake.gen.native_controls_ui.ex` (mix task, file-I/O)

**Analog A (stamp + no-clobber + doctor hook — the D-35-mandated shape):** `lib/mix/tasks/crosswake.gen.bridge_hook.ex`

Do **not** copy this file's "refuse by default, write only with `--eject`" flag gate — that is specific to the single-file protocol-sensitive hook. Copy only its **stamp mechanics**:

```elixir
# lib/mix/tasks/crosswake.gen.bridge_hook.ex:129-163 — the eject/no-clobber shape
defp eject(dir, relative_path) do
  destination = Path.join(dir, relative_path)

  case File.read(destination) do
    {:ok, _existing} ->
      Mix.shell().info("  reused ... (host-owned; the eject never clobbers your copy)")
      :reused

    {:error, :enoent} ->
      File.mkdir_p!(Path.dirname(destination))
      File.write!(destination, stamped_hook_source(relative_path))
      Mix.shell().info("  created ... (stamped protocol #{Contract.version()})")
      :created

    {:error, reason} ->
      Mix.raise("could not write #{destination}: #{:file.format_error(reason)}")
  end
end

defp stamped_hook_source(relative_path) do
  stamp(relative_path) <> "\n" <> hook_source()
end

defp stamp(relative_path) do
  """
  #{@stamp_prefix} protocol=#{Contract.version()}
   *
   * Host-owned copy of ... You own this file: Crosswake will never rewrite it ...
   */
  """
end

@doc false
@spec stamp_prefix() :: String.t()
def stamp_prefix, do: @stamp_prefix
```
Copy the `@template_version`-style stamp constant approach (`bump_template_version.ex` is the sibling that bumps this number; see below) and the doctor regex-parse target (`doctor.ex:2138`).

**Analog B (multi-file `ensure_file` + printed next-steps — the loop shape you actually need, since 155 copies TWO files not one):** `lib/mix/tasks/crosswake.gen.offline_ui.ex`

```elixir
# lib/mix/tasks/crosswake.gen.offline_ui.ex:19-77 — multi-file copy + printed next steps
def run(args) do
  {opts, _argv, invalid} = OptionParser.parse(args, strict: @switches)
  if invalid != [], do: Mix.raise("invalid options: #{inspect(invalid)}")

  app_module = opts[:app] || get_app_module()
  app_snake = Macro.underscore(app_module)
  dir = Path.expand(opts[:dir] || File.cwd!())
  web_dir = Path.join([dir, "lib", "#{app_snake}_web"])

  # ... build N destination paths, EEx.eval_file/2 each template, then:
  ensure_file(controller_dest, controller_content)
  ensure_file(root_layout_dest, root_layout_content)
  # ...

  Mix.shell().info("""
  ... generated successfully!

  Next steps:
  1. ...
  """)
end

defp ensure_file(path, contents) do
  File.mkdir_p!(Path.dirname(path))
  case File.read(path) do
    {:ok, _existing} -> Mix.shell().info("  reused #{Path.relative_to_cwd(path)}"); :reused
    {:error, :enoent} -> File.write!(path, contents); Mix.shell().info("  created ..."); :created
    {:error, reason} -> Mix.raise("could not create #{path}: #{:file.format_error(reason)}")
  end
end

defp get_template_path(filename) do
  path = Application.app_dir(:crosswake, "priv/templates/crosswake/offline_ui/#{filename}")
  if File.exists?(path), do: path, else: Path.join(File.cwd!(), "priv/templates/crosswake/offline_ui/#{filename}")
end
```

**Synthesis for the new task:** use Analog B's `run/1` shape (two `ensure_file` calls, one for `crosswake_fallbacks.ex`, one for `crosswake_fallback.css`), but each write must go through Analog A's **stamped** content builder (prepend `@stamp_prefix` + `@template_version` comment), and the printed next-steps block must include **D-06's three verbatim `handle_event` clauses** as copy-paste text (this is the phase's biggest DX deliverable per CONTEXT.md — do not shortchange it) plus **D-55's inert Phase-156 hand-off comment** baked into the `crosswake_fallbacks.ex.eex` template itself (not the printed output).

**Error handling:** `Mix.raise/1` on invalid options and unwritable destinations (both analogs agree).

**Doctor + drift test wiring (D-35):** reuse `bump_template_version.ex` and `test/crosswake/proof/phase134_template_version_drift_test.exs` verbatim as the version-drift mechanism — read these two files during implementation to mirror the exact `@template_version` bump-detection shape (not excerpted here; same repo, same pattern family as the stamp above).

---

### `priv/templates/crosswake/native_controls_ui/crosswake_fallbacks.ex.eex` (component template)

**Analog:** no direct HEEx-component-with-`resolve/2` analog exists yet (D-37/`component_use`/`template_sigil` are verified "zero today" in `lib/`) — this is deliberately the FIRST `Phoenix.Component`/`~H` usage in the repo, and it must live in `priv/templates/`, never `lib/`, or it self-trips `ComponentTierGuard`.

**Wiring pattern to embed (copy verbatim from `lib/crosswake/bridge.ex`):**

```elixir
# lib/crosswake/bridge.ex:270-281 — resolve/2, the compare-and-delete the template must call
# on both crosswake_fallback_answer and crosswake_fallback_dismiss (D-25):
def resolve(%Phoenix.LiveView.Socket{} = socket, ref) do
  state = fetch_state!(socket)
  case Enum.find(state.in_flight, fn {_correlation_id, entry} -> entry.ref == ref end) do
    nil -> socket
    {correlation_id, _entry} ->
      put_state(socket, %{state | in_flight: Map.delete(state.in_flight, correlation_id)})
  end
end
```
The template's generated `handle_event` clauses call `Crosswake.Bridge.resolve(socket, ref)` — **do not** invent a second dedup mechanism; D-25 forbids routing native reply and fallback click into the same event name.

**Focus trap pattern (LiveView built-in, zero JS — D-10):**
```elixir
# deps/phoenix_live_view/lib/phoenix_component.ex:3173-3181 — focus_wrap/1
def focus_wrap(assigns) do
  ~H"""
  <div id={@id} phx-hook="Phoenix.FocusWrap" {@rest}>
    <div id={"#{@id}-start"} tabindex="0" aria-hidden="true"></div>
    {render_slot(@inner_block)}
    <div id={"#{@id}-end"} tabindex="0" aria-hidden="true"></div>
  </div>
  """
end
```
Wrap both `confirm_modal/1` and `action_menu/1` bodies in `<.focus_wrap id={...}>`. No hooks-map registration needed (`Phoenix.FocusWrap` is a LiveView built-in hook name).

**Required-no-default attrs (D-58):** use `attr :title, :string, required: true` / `attr :confirm_label, :string, required: true` (standard `Phoenix.Component.attr/3` — no analog needed, this is the stdlib DSL itself; a missing value is a compile error by construction).

---

### `priv/templates/crosswake/native_controls_ui/crosswake_fallback.css.eex` (stylesheet template)

**Analog:** `priv/static/crosswake/offline.css` (referenced via `lib/mix/tasks/crosswake.gen.offline_ui.ex:97-104`'s `get_offline_css_path/0`)

**Zero-theme-logic pattern to copy exactly one line from:**
```css
/* offline.css:5-7 — the one theme line every generated CSS in this repo copies */
:root { color-scheme: light dark; }
```
Do not add `@media (prefers-color-scheme: dark)` or `[data-theme]` blocks — both are inherited for free from `tokens.css:57-117` once the file references `var(--cw-*)` through the `--cwfb-*` alias layer (D-24, exact alias table in `155-UI-SPEC.md`).

**The documented contrast trap to avoid repeating (`offline.css:61-64`):** panel background must be `--cw-surface-inset`, never `--cw-surface-raised` — `--cw-text-muted` on raised fails AA (4.11:1). This file already documents the trap; read those four lines directly before writing the new alias mapping.

**Alias-layer precedent (D-24):**
```css
/* app.css:220-224 — the in-repo precedent for a scoped alias block re-pointing to --cw-* */
--app-accent: var(--cw-runtime-liveview);
```
Per-brand overrides at `app.css:248-267`, dark variant at `app.css:487-495` — same shape, different scope name (`--cwfb-*` vs `--app-*`).

---

### `lib/crosswake/component_tier_guard.ex` (structural guard)

**Analog A (names-as-strings self-trip avoidance):** `lib/crosswake/companion_guard.ex:28-60`
```elixir
# The exact anti-self-trip trick D-36 requires for [:Crosswake, :UI]:
@extracted_companion_names [
  "Crosswake.Companions.Rulestead",
  # ...
]
@extracted_companions MapSet.new(Enum.map(@extracted_companion_names, &String.to_atom/1))
@banned_alias_parts Enum.map(@extracted_companion_names, fn name ->
  name |> String.split(".") |> Enum.map(&String.to_atom/1)
end)
```
For `ComponentTierGuard`, the banned namespace prefix `[:Crosswake, :UI]` must be constructed the same way — as a string split into atoms at runtime, never as a literal `Crosswake.UI` alias reference in the guard's own source (or the guard's own file trips its `namespace` rule).

**AST walk mechanism (both `CompanionGuard.check_source/1` and `CatalogGuard`):**
```elixir
# lib/crosswake/companion_guard.ex:94-112 — the exact prewalk shape to replicate per rule
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
Build five analogous `check_*` functions for `namespace`, `namespace_minted` (`Module.concat`/`String.to_atom` literal-argument nodes), `component_use` (alias/use referencing `Phoenix.Component`/`LiveComponent`), `component_dsl` (`attr`/`slot` call nodes), `template_sigil` (`~H` sigil AST node — `{:sigil_H, _, _}`).

**Analog B (injection seam for fixture-driven tests):** `lib/crosswake/bridge/catalog_guard.ex:88-102` (prose) and `:584` (`def assert_catalog_closed!(opts \\ [])`).
```elixir
# The seam shape: every default is the real shipped value, so the zero-arg call
# CI makes is byte-for-byte the production gate; a fixture test passes root: to
# redirect the walk at a synthetic tree without relaxing anything.
def assert_catalog_closed!(opts \\ []) do
  root = Keyword.get(opts, :root, File.cwd!())
  # ...
end
```
`ComponentTierGuard.assert_no_component_tier!/1` must take the identical `opts \\ []` / `root:` shape.

**Failure message shape (D-38, stable bracketed id + teaching heredoc):**
```elixir
# lib/crosswake/companion_guard.ex:219-229 — the exact raise-message template to follow
raise "[proof.extract_03.static_ref.#{Path.basename(path, ".ex")}] " <>
        "subject=lib/ must not statically reference an extracted companion " <>
        "source=CompanionGuard.assert_no_static_refs!/0 " <>
        "observed=found alias #{inspect(mod)} in #{path} " <>
        "path=#{path} " <>
        "hint=remove the static reference — use the :companions registry seam instead (EXTRACT-03) " <>
        "posture=merge_blocking"
```
For `ComponentTierGuard`, the bracketed id is `[proof.fall_02.no_component_tier.<rule>]`; the `hint=` field must carry D-38's five-step retirement recipe, ending with "what you probably want instead."

**Anti-vacuity twin (D-37, `components_exist_in_templates`):** no direct analog exists (`CompanionGuard`/`CatalogGuard` only assert absence, never assert presence-somewhere-else) — this rule is new territory; implement it as: walk `priv/templates/crosswake/native_controls_ui/*.eex`, assert each contains at least one `attr` call and one `~H`/HEEx marker via the same `Code.string_to_quoted/2` (note: `.eex` mixed with HEEx requires reading as text/regex for the sigil check inside a template file, since `Code.string_to_quoted/2` cannot parse a raw `.heex.eex` — use a regex belt here analogous to `CompanionGuard.check_ensure_loaded_placement/1`'s "belt" pattern at `companion_guard.ex:178-183`).

---

### `test/crosswake/component_tier_guard_test.exs`

**Analog:** `test/crosswake/proof/phase154_recipe_followable_test.exs` (drives the `root:` seam against a synthetic fixture tree — read this file directly when writing the new test; it is the canonical example of "execute the six-step recipe the guard's own failure message prints").

D-37 requires: a multi-violation fixture asserting the **set** of violated rules (not `length >= 1`); five one-rule synthetics; a positive control on real `lib/` **plus** real templates; attestation rejecting gaps **and** orphan templates.

---

### `lib/crosswake/bridge.ex` — D-50 `resolve/2` widening

**Current (to be widened):**
```elixir
# lib/crosswake/bridge.ex:526-543 — fetch_state!/1, the raiser resolve/2 must stop calling
defp fetch_state!(socket) do
  case socket.private[@private_key] do
    nil ->
      raise NotMountedError, message: "..."
    state -> state
  end
end
```
**Pattern to apply:** change `resolve/2` (currently `state = fetch_state!(socket)` at line ~272) to a private `maybe_fetch_state/1` that returns `nil` instead of raising on an unattached socket, and short-circuit `resolve/2` to `socket` unchanged when state is `nil` — symmetric with the existing "no-op when `ref` not found" branch already in the function (`lib/crosswake/bridge.ex:279-291`). Keep `push/3`/`dispatched/2` on the strict `fetch_state!/1` path (D-50 explicit: "Keep `dispatched/2` strict").

---

### D-51 `UnknownCapabilityFamilyError`

**Analog (sibling error module shape):**
```elixir
# lib/crosswake/bridge.ex:1-30 — the exact top-level-defmodule pattern to copy for the new error
defmodule Crosswake.Bridge.NotMountedError do
  @moduledoc "..."
  defexception [:message]
end

defmodule Crosswake.Bridge.UndeclaredCapabilityError do
  @moduledoc """
  ...
  Defined at the top level for the same reason as `Crosswake.Bridge.NotMountedError`
  """
  defexception [:message]
end
```
Add `Crosswake.Bridge.UnknownCapabilityFamilyError` at the same top level (NOT nested inside `defmodule Crosswake.Bridge`, per the existing comment explaining the naming-concatenation trap). Route moment (C) — `Registry.capability_command(capability_family)` returning `nil` at `lib/crosswake/bridge.ex:205-207` — into a new `raise_unknown_capability_family!/3`, modeled directly on the existing `raise_undeclared_capability!/3`:
```elixir
# lib/crosswake/bridge.ex:564-589 — the message-building shape to clone with different remediation text
defp raise_undeclared_capability!(state, socket, capability_family) do
  route = Map.get(state.manifest.routes, state.route_id)
  declared = (route && route.capabilities) || []
  {router_file, router_line} = router_location(socket, state.route_id)
  fix_line = "capabilities: #{inspect(Enum.uniq(declared ++ [capability_family]))}"
  message = "..."
  raise UndeclaredCapabilityError, message: message
end
```
The new raiser must NOT suggest adding `capabilities: [...]` (that remediation is correct for moment B, wrong/misleading for moment C per D-51) — its message should say the family is not in the bridge's known vocabulary at all.

---

### `lib/crosswake/install/patcher.ex` — D-52 marker-content reconciliation + D-26 tokens.css `Plug.Static`

**Current defect (to fix):**
```elixir
# lib/crosswake/install/patcher.ex:128-131 — never reconciles block CONTENT
defp ensure_endpoint_block(contents) do
  cond do
    String.contains?(contents, @marker_start) and String.contains?(contents, @marker_end) ->
      {:ok, contents, [:marker_reused]}
    # ...
```
**Pattern to add:** diff the marker-delimited substring against the current `endpoint_static_plug_block/1` output; if different, return a new action atom (e.g. `:marker_stale`) and either patch in place or leave it for a doctor finding (per the phase's D-40 discipline: doctor "reads a version integer... never overclaim").

**Second `Plug.Static` block precedent (already in the same file):**
```elixir
# lib/crosswake/install/patcher.ex:72-85 — endpoint_static_plug_block/1, the exact shape
# to replicate for /crosswake/tokens.css
def endpoint_static_plug_block(indentation \\ "  ") do
  [
    "#{indentation}#{@marker_start}",
    "#{indentation}plug(Plug.Static,",
    "#{indentation}  at: \"#{@static_at}\",",
    "#{indentation}  from: :crosswake,",
    "#{indentation}  gzip: false,",
    "#{indentation}  only: ~w(#{@hook_asset})",
    "#{indentation})",
    "#{indentation}#{@marker_end}"
  ] |> Enum.join("\n")
end
```
Extend `only: ~w(#{@hook_asset})` to also include `tokens.css` (both served from `:crosswake`'s own `priv/static` at the same `/crosswake` prefix — D-26 wants `/crosswake/tokens.css`, one `Plug.Static` block, not a third).

**Confirmed root cause in the example host's own endpoint (D-26's 404):**
```elixir
# examples/phoenix_host/lib/crosswake_example/endpoint.ex:17-22 — no "assets" in `only:`
plug(Plug.Static,
  at: "/",
  from: :crosswake_example,
  gzip: false,
  only: ~w(brand css offline_study.js storage_budget.test.js storage_logic.js)
)
```
This confirms `~p"/assets/tokens.css"` 404s today; D-26 fixes it by serving from `/crosswake/tokens.css` instead, never by adding `assets` to this list.

---

### `brandbook/tools/compile-tokens.js` — D-29 `groups` array

```javascript
// brandbook/tools/compile-tokens.js:67 — the line D-29 requires editing
const groups = ['surface', 'text', 'action', 'border', 'status', 'runtime'];
// MUST become:
const groups = ['surface', 'text', 'action', 'border', 'status', 'runtime', 'overlay'];
```
Alias resolution for the scrim (an 8-digit hex primitive, NOT `color-mix` per D-28) goes through the existing `resolveAlias/1` at `compile-tokens.js:22-26` unchanged — no compiler logic change needed for `--cw-status-error-fg` (a pure alias to `{primitive.white}`), only the groups-array addition and the JSON authoring.

---

### `brandbook/tools/contrast.test.mjs` — D-33 focus-ring pairs

**Analog (existing text-pair assertion shape to clone for a new UI-component-contrast class):**
```javascript
// brandbook/tools/contrast.test.mjs:107-111 — the exact assert-shape to replicate
test('contrast(stone-600, foam-50) ≈ 4.53 (PASS AA — must be >= 4.5)', () => {
  const ratio = contrast('#756D63', '#F7F1E6');
  assert.ok(Math.abs(ratio - 4.53) < 0.1, `expected ~4.53 got ${ratio.toFixed(2)}`);
  assert.ok(ratio >= 4.5, `stone-600/foam-50 must pass AA (>= 4.5), got ${ratio.toFixed(2)}`);
});
```
New tests must assert the **≥3:1** SC 1.4.11 non-text threshold (not the 4.5 text threshold) for `--cw-action-focus-ring` against both `white`/`foam-50` (light) and against dark backgrounds, both BEFORE (documenting the known-fail) and AFTER the `wake-700`/`wake-500` fix — this is the class of assertion `contrast.test.mjs` has never had (today it only tests text pairs).

---

### `brandbook/tools/check-consumer-drift.mjs` — D-34 MANIFEST additions

```javascript
// brandbook/tools/check-consumer-drift.mjs:29-43 — curated array, NOT a glob
export const MANIFEST = [
  { path: 'examples/phoenix_host/priv/static/css/app.css', type: 'css' },
  { path: 'priv/static/crosswake/offline.css', type: 'css' },
  { path: 'priv/templates/crosswake/offline_ui/offline_page.html.heex.eex', type: 'heex' },
  { path: 'priv/templates/crosswake/offline_ui/offline_root.html.heex.eex', type: 'heex' },
  { path: 'examples/phoenix_host/lib/crosswake_example_web/controllers/offline_html/index.html.heex', type: 'heex' },
];
```
Append exactly two new entries: `{ path: 'priv/templates/crosswake/native_controls_ui/crosswake_fallbacks.ex.eex', type: 'heex' }` and `{ path: 'priv/templates/crosswake/native_controls_ui/crosswake_fallback.css.eex', type: 'css' }`. Do **not** add the generated HOST files (D-34: gate proves the shipped default is clean, does not police the adopter's copy). Use literal `class="…"` only in the templates — `class={…}` dynamic bindings are this gate's documented blind spot (`:170-184`).

---

### `examples/phoenix_host/e2e/native_controls_fallback.spec.ts` (new Playwright spec)

**Analog A (compositing walk for computed contrast, and the honest-labelling docblock convention):** `examples/phoenix_host/e2e/evidence_panel.spec.ts:1-31` (docblock: MECHANICAL / PARTIAL PROXY / PROXY labels per assertion) and `:271-300` (effective-background compositing):
```typescript
// examples/phoenix_host/e2e/evidence_panel.spec.ts:283-300 — the compositing walk to reuse verbatim
const effectiveBackground = (el: Element): [number, number, number] => {
  const stack: Array<[number, number, number, number] | null> = [];
  let node: Element | null = el;
  while (node) {
    stack.push(parseRGBA(getComputedStyle(node).backgroundColor));
    node = node.parentElement;
  }
  stack.push([255, 255, 255, 1]);
  let out: [number, number, number] | null = null;
  for (let i = stack.length - 1; i >= 0; i--) {
    const c = stack[i];
    if (!c) continue;
    // ... alpha-composite bottom-up
  }
  return out!;
};
```
Reuse this function (or import it from a shared support module if one gets extracted) rather than rewriting it — D-46 explicitly calls this out as the "hard part of criterion 2" already solved.

**Analog B (docblock honest-labelling convention — copy the house style exactly):**
```typescript
// examples/phoenix_host/e2e/evidence_panel.spec.ts:4-30
/*
 * Phase 154 Plan 08, Task 2 — the six judgements that used to be a human checkpoint.
 * ...
 * HONEST LABELLING (house style — see Crosswake.Bridge.CatalogGuard's moduledoc,
 * which labels its six criteria MECHANICAL / MECHANICAL-ONLY-IN-THE-NEGATIVE /
 * HYBRID / MECHANICAL-BY-PROXY rather than letting a proxy wear a proof's badge).
 */
```
The new spec's moduledoc must open the same way, labelling A1/A2/A3 and pasting D-44's corrected criterion-3 wording verbatim, plus D-48's explicit non-claims list.

**Analog C (read-from-source discipline, never hardcode):** `examples/phoenix_host/e2e/route_tour.spec.ts:19-23` — the catalog fallback sentence must be read from `Manifest.Builder.capability_catalog/0`'s output (surfaced via a page fixture or API), never hardcoded as a literal string in the spec.

**Route constants pattern:**
```typescript
// examples/phoenix_host/e2e/evidence_panel.spec.ts:36-37
const APPROVAL_ROUTE = '/saas/approvals/approval-1';
const PANEL = '#haptics-evidence';
```
Mirror this shape for the three new route constants (A1 reuses `/saas/approvals/approval-1`, A2 is the new `/_e2e/undeclared-control`, A3 is `/bridge-proof`).

**Denial injection (doubly-nested wire shape, D-46):**
```kotlin
// packages/crosswake-shell-core-android/src/main/java/dev/crosswake/shell/core/BridgeChannel.kt:325-349
// The DOUBLY-nested shape the addInitScript harness must inject verbatim:
{
  "protocol": ..., "version": ..., "command": ..., "route_id": ...,
  "denial": {
    "command": ..., "route_id": ..., "correlation_id": ...,
    "denial": {  // <-- second, doubly-nested "denial" key
      "reason": reason, "code": reason, "message": message,
      "route_id": ..., "hint": hint
    }
  }
}
```
Use `route_tour.spec.ts:97,103,110-146`'s `page.addInitScript()` harness shape as the injection mechanism (read those lines directly during implementation — same file already does this for a different scenario).

**Pin the new spec in the honesty gate:**
```javascript
// script/check-e2e-honesty.mjs:55-60 — curated FILES array, add the new spec here in the same PR
const FILES = [
  'examples/phoenix_host/e2e/evidence_panel.spec.ts',
  'examples/phoenix_host/e2e/offline_sync.spec.ts',
  'examples/phoenix_host/e2e/route_tour.spec.ts',
  'examples/phoenix_host/e2e/support/offline_route_proof.ts',
  // ADD: 'examples/phoenix_host/e2e/native_controls_fallback.spec.ts',
];
```

---

### `examples/phoenix_host/lib/crosswake_example/router.ex` — new `/_e2e/undeclared-control` route

**Analog (existing `/_e2e` scope, exact same compile-time guard to extend, not duplicate):**
```elixir
# examples/phoenix_host/lib/crosswake_example/router.ex:581-593
if Mix.env() in [:test, :e2e] do
  scope "/_e2e", CrosswakeExample.E2E do
    pipe_through([:api])
    get("/sync-state/:client_mutation_id", SyncStateController, :show)
    post("/native-claim", NativeClaimController, :create)
    post("/showcase-reset", ShowcaseResetController, :create)
  end

  scope "/_e2e", CrosswakeExample.E2E do
    pipe_through([:api, :e2e_session])
    post("/saas-session", SaaSSessionController, :create)
  end
end
```
Add `get("/undeclared-control", UndeclaredControlController, :show)` (or a LiveView `live "/undeclared-control", UndeclaredControlLive`) inside the SAME `if Mix.env() in [:test, :e2e] do` block — do NOT add a second conditional (the existing `guard-02-prod-route-absence` CI job greps for `/_e2e` route absence in a prod compile; a second guard block risks drifting from that check's assumption).

---

### `examples/phoenix_host/lib/crosswake_example/e2e/*` (new controller/LiveView for A2)

**Analog:** the existing `CrosswakeExample.E2E.SyncStateController`/`NativeClaimController`/`ShowcaseResetController` modules referenced by the router above — read one of these directly (e.g. `SyncStateController`) for the exact module-naming and namespace convention (`CrosswakeExample.E2E.*`), then model the new controller/LiveView on it. It must render a route whose policy never declares any capability family (to trigger moment C — the `raise_unknown_capability_family!/3` server-side raise from D-51) rather than moment B.

---

## Shared Patterns

### No-clobber + stamped provenance (generator idempotency)
**Source:** `lib/mix/tasks/crosswake.gen.bridge_hook.ex:129-183` (stamp shape) + `lib/mix/tasks/crosswake.gen.offline_ui.ex:113-129` (`ensure_file/2` loop shape)
**Apply to:** `crosswake.gen.native_controls_ui.ex` and both `.eex` templates it writes.
```elixir
case File.read(destination) do
  {:ok, _existing} -> Mix.shell().info("  reused ..."); :reused
  {:error, :enoent} -> File.write!(destination, stamped_content); Mix.shell().info("  created ..."); :created
  {:error, reason} -> Mix.raise("could not write #{destination}: #{:file.format_error(reason)}")
end
```

### `lib/`-resident structural AST guard with injection seam
**Source:** `lib/crosswake/companion_guard.ex` (names-as-strings self-trip avoidance) + `lib/crosswake/bridge/catalog_guard.ex:88-102,584` (`root:` seam)
**Apply to:** `lib/crosswake/component_tier_guard.ex` and its test.
```elixir
def assert_no_component_tier!(opts \\ []) do
  root = Keyword.get(opts, :root, File.cwd!())
  # ... walk Path.wildcard(Path.join(root, "lib/**/*.ex")) ...
end
```

### Stable bracketed-id merge-blocking failure messages
**Source:** `lib/crosswake/companion_guard.ex:219-229`, `lib/crosswake/bridge/catalog_guard.ex` (six-criteria docblock labelling)
**Apply to:** `ComponentTierGuard` raises, both new bridge errors (D-50/D-51 context, though those are ArgumentError-style raises not this bracketed format — the bracketed `[crosswake.bridge.*]` prefix convention IS already used inside `bridge.ex`'s own raise messages, e.g. `[crosswake.bridge.not_mounted]`, `[crosswake.bridge.undeclared_capability]` — follow that prefix convention for the new `[crosswake.bridge.unknown_capability_family]` message).

### Curated arrays, never globs
**Source:** `brandbook/tools/check-consumer-drift.mjs:29-43` (MANIFEST), `script/check-e2e-honesty.mjs:55-60` (FILES)
**Apply to:** every new template file and every new e2e spec — both gates are silently ungated until the new path is explicitly appended to the array in the SAME PR that creates the file.

### Honest-labelling docblocks (MECHANICAL / PARTIAL PROXY / HYBRID)
**Source:** `examples/phoenix_host/e2e/evidence_panel.spec.ts:4-30`, `lib/crosswake/bridge/catalog_guard.ex`'s six-criteria section
**Apply to:** `native_controls_fallback.spec.ts`'s moduledoc (D-44's hybrid label for criterion 3; D-48's non-claims list must be pasted verbatim).

### Zero theme logic in generated CSS
**Source:** `priv/static/crosswake/offline.css:5-7` (`:root { color-scheme: light dark; }`) and its documented `:61-64` contrast trap (raised surface fails AA for muted text)
**Apply to:** `crosswake_fallback.css.eex`.

## No Analog Found

None — every file in scope has at least a role-match analog already in the repository. This phase is explicitly designed (per RESEARCH.md) to introduce zero new external dependencies and to compose entirely from already-shipped in-house mechanisms (generator stamping, structural guards, curated CI manifests, the Playwright compositing walk).

## Metadata

**Analog search scope:** `lib/mix/tasks/`, `lib/crosswake/` (bridge*, companion_guard.ex, install/patcher.ex, doctor/), `priv/templates/crosswake/`, `priv/static/crosswake/`, `brandbook/tools/`, `brandbook/tokens/`, `examples/phoenix_host/e2e/`, `examples/phoenix_host/lib/crosswake_example/` (router.ex, endpoint.ex, e2e/), `script/`, `deps/phoenix_live_view/lib/`.
**Files scanned (read in full or targeted ranges):** `crosswake.gen.bridge_hook.ex`, `crosswake.gen.offline_ui.ex`, `companion_guard.ex`, `bridge/catalog_guard.ex` (partial), `bridge.ex` (partial), `bridge/contract.ex` (partial), `install/patcher.ex`, `compile-tokens.js` (partial), `check-consumer-drift.mjs` (partial), `contrast.test.mjs` (partial), `evidence_panel.spec.ts` (partial), `router.ex` (partial), `endpoint.ex` (partial), `phoenix_component.ex` (via RESEARCH.md citation, cross-checked), 155-CONTEXT.md, 155-RESEARCH.md, 155-UI-SPEC.md.
**Pattern extraction date:** 2026-07-30
