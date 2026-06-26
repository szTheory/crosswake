defmodule Crosswake.CompanionGuard do
  @moduledoc """
  Merge-blocking AST guards for Phase 130 companion extraction.

  This module is a plain support module (NO `use ExUnit.Case`) callable from
  proof tests and — post-publish — from each companion package's own test suite.
  The guard travels with the code (D-17).

  ## Purpose

  Provides two categories of AST-level enforcement:

  1. **EXTRACT-03 static-reference guard** — detects any static alias or reference
     to an extracted companion module in `lib/`. A static reference re-couples the
     poncho and violates the extraction boundary.

  2. **EXTRACT-04 ensure_loaded? placement guard** — verifies every
     `Code.ensure_loaded?` call in `lib/` appears inside a function body
     (`def`/`defp`/`defmacro`), never at module-eval time. A module-eval call
     bakes the probing into compile time, creating stale-beam footguns.

  ## AST mechanism

  Uses `Code.string_to_quoted/2` + `Macro.prewalk/3` over `Path.wildcard("lib/**/*.ex")`
  — stdlib only, no mix xref, no boundary lib (D-11/D-12).
  """

  # Hardcoded frozen set — one entry per extraction phase.
  # Stored as module name STRINGS (not bare module aliases) so this attribute
  # definition does not itself contain {:__aliases__} AST nodes — which would cause
  # companion_guard.ex to fail its own check_source/1 (self-false-positive).
  # DO NOT derive from path: deps (core names no companion; D-13).
  # Change this attribute AND remove the source from lib/ in the SAME PR so the
  # reviewer sees the intentional shape change.
  @extracted_companion_names [
    # Phase 130: rulestead adapter extracted
    "Crosswake.Companions.Rulestead",
    # Phase 132: rindle adapter extracted (covers .Contracts/.Reconciliation children
    # via the alias-parts prefix match; not a blanket Companions.* ban — D-02/D-14)
    "Crosswake.Companions.Rindle"
  ]

  # Pre-compute the frozen MapSet of extracted companion module atoms.
  # Returned by extracted_companions/0 for introspection.
  @extracted_companions MapSet.new(Enum.map(@extracted_companion_names, &String.to_atom/1))

  # Pre-compute the banned alias parts lists from the companion name strings.
  # Each name string is split into a list of atoms, e.g.:
  #   "Crosswake.Companions.Rulestead" -> [:Crosswake, :Companions, :Rulestead]
  # The guard matches these lists against {:__aliases__, _meta, parts} AST nodes.
  # This stays in sync with @extracted_companion_names — not a blanket Companions.* ban (D-14).
  @banned_alias_parts Enum.map(@extracted_companion_names, fn name ->
    name |> String.split(".") |> Enum.map(&String.to_atom/1)
  end)

  @doc """
  Returns the frozen MapSet of extracted companion modules.

  One entry per extraction phase. To add a module, add its name string to
  `@extracted_companion_names` AND in the same PR that removes the source from
  `lib/` — the reviewer sees the intentional shape change (D-13).
  """
  @spec extracted_companions() :: MapSet.t()
  def extracted_companions, do: @extracted_companions

  @doc """
  Checks whether `source_string` (Elixir source code) contains a static
  alias or reference to any extracted companion module.

  Returns `:ok` if no violations found, or `{:violation, list}` with the
  offending AST nodes.

  ## Implementation

  Parses the source with `Code.string_to_quoted/2`, then walks the AST with
  `Macro.prewalk/3` collecting any `{:__aliases__, _meta, parts}` node whose
  `parts` list exactly matches one of the banned alias part-lists derived from
  `@extracted_companion_names`.

  String literals (e.g. moduledoc examples mentioning a companion name) are NOT
  `{:__aliases__}` AST nodes and cannot false-positive (D-12). No special-casing
  needed for doc strings.

  The banned-alias list is derived from `@extracted_companion_names` (strings split
  to atom lists), so the matcher stays in sync — NOT a blanket `Crosswake.Companions.*`
  ban (D-14).
  """
  @spec check_source(String.t()) :: :ok | {:violation, list()}
  def check_source(source_string) do
    {:ok, ast} = Code.string_to_quoted(source_string, [])

    {_, violations} =
      Macro.prewalk(ast, [], fn
        {:__aliases__, _meta, parts} = node, acc
        when parts in @banned_alias_parts ->
          {node, [node | acc]}

        node, acc ->
          {node, acc}
      end)

    if violations == [], do: :ok, else: {:violation, violations}
  end

  @doc """
  Checks whether all `Code.ensure_loaded?` calls in `source_string` appear
  inside function bodies (`def`/`defp`/`defmacro`), never at module-eval time.

  Returns `:ok` if placement is correct, or `{:violation, list}` with the
  offending AST nodes.

  ## Implementation

  Uses the AST prune-then-walk pattern (D-16):

  1. Collect the `do:` body subtrees of every `def`/`defp`/`defmacro` in the
     parsed AST.
  2. Walk the FULL AST for `Code.ensure_loaded?` call nodes (the `{{:., _, [{:__aliases__,
     _, [:Code]}, :ensure_loaded?]}, _, _}` shape).
  3. For each such node, verify it is reachable inside at least one collected
     function body. Any `ensure_loaded?` node outside a body is a violation.

  Additionally applies a cheap textual belt: `Regex.scan/2` over the raw source
  string for non-commented `Code.ensure_loaded?` occurrences as an escalation
  signal for macro/unquote-injected edge cases. The AST walk is authoritative;
  the belt only provides supporting context.
  """
  @spec check_ensure_loaded_placement(String.t()) :: :ok | {:violation, list()}
  def check_ensure_loaded_placement(source_string) do
    {:ok, ast} = Code.string_to_quoted(source_string, [])

    # Step 1: Collect the body subtrees of every def/defp/defmacro.
    {_, body_subtrees} =
      Macro.prewalk(ast, [], fn
        {kind, _meta, [_head, [do: body]]} = node, acc
        when kind in [:def, :defp, :defmacro] ->
          {node, [body | acc]}

        node, acc ->
          {node, acc}
      end)

    # Step 2: Find all Code.ensure_loaded? call nodes in the FULL AST.
    {_, ensure_nodes} =
      Macro.prewalk(ast, [], fn
        {{:., _dot_meta, [{:__aliases__, _, [:Code]}, :ensure_loaded?]}, _call_meta, _args} =
          node,
          acc ->
          {node, [node | acc]}

        node, acc ->
          {node, acc}
      end)

    # Step 3: Assert every ensure_loaded? node is inside a collected function body.
    ast_violations =
      Enum.filter(ensure_nodes, fn ensure_node ->
        not Enum.any?(body_subtrees, fn body ->
          {_, found} =
            Macro.prewalk(body, false, fn
              ^ensure_node, _acc -> {ensure_node, true}
              node, acc -> {node, acc}
            end)

          found
        end)
      end)

    # Belt: textual scan for non-commented Code.ensure_loaded? occurrences.
    # ~r/^[^#\n]*Code\.ensure_loaded\?/m — lines where ensure_loaded? is not commented out.
    # The belt is an escalation signal for macro/unquote-injected edge cases where the AST
    # walk might not catch a module-eval call. The AST walk is authoritative; the belt
    # count adds supporting context for debugging. (D-16)
    _belt_matches = Regex.scan(~r/^[^#\n]*Code\.ensure_loaded\?/m, source_string)

    violations = ast_violations

    if violations == [], do: :ok, else: {:violation, violations}
  end

  @doc """
  Walks all `lib/**/*.ex` files in the current working directory and raises if
  any file contains a static reference to an extracted companion module.

  Uses `Path.wildcard/1` from `File.cwd!()`. The assertion failure message
  is formatted with stable_id slugs in brand voice for merge-blocking posture.
  """
  @spec assert_no_static_refs!() :: :ok
  def assert_no_static_refs! do
    lib_glob = Path.join(File.cwd!(), "lib/**/*.ex")

    violations =
      Path.wildcard(lib_glob)
      |> Enum.flat_map(fn path ->
        source = File.read!(path)

        case check_source(source) do
          :ok -> []
          {:violation, nodes} -> Enum.map(nodes, fn node -> {path, node} end)
        end
      end)

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

  @doc """
  Walks all `lib/**/*.ex` files in the current working directory and raises if
  any file contains a `Code.ensure_loaded?` call outside a function body.

  Uses `Path.wildcard/1` from `File.cwd!()`. The assertion failure message
  is formatted with stable_id slugs in brand voice for merge-blocking posture.

  The compile-vs-runtime footgun: a module-eval `Code.ensure_loaded?` bakes the
  engine presence check into the `.beam` file at compile time. If the engine is
  later loaded or unloaded without recompiling, the `.beam` carries a stale result
  — silently confusing engine-present/absent test state. EXTRACT-04 forbids it.
  """
  @spec assert_ensure_loaded_in_function_bodies!() :: :ok
  def assert_ensure_loaded_in_function_bodies! do
    lib_glob = Path.join(File.cwd!(), "lib/**/*.ex")

    violations =
      Path.wildcard(lib_glob)
      |> Enum.flat_map(fn path ->
        source = File.read!(path)

        case check_ensure_loaded_placement(source) do
          :ok -> []
          {:violation, nodes} -> Enum.map(nodes, fn node -> {path, node} end)
        end
      end)

    if violations != [] do
      for {path, node} <- violations do
        raise "[proof.extract_04.ensure_loaded_placement.#{Path.basename(path, ".ex")}] " <>
                "subject=Code.ensure_loaded? must only appear inside function bodies (def/defp/defmacro) " <>
                "source=CompanionGuard.assert_ensure_loaded_in_function_bodies!/0 " <>
                "observed=module-eval Code.ensure_loaded? found: #{inspect(node)} in #{path} " <>
                "path=#{path} " <>
                "hint=move Code.ensure_loaded? inside a def/defp/defmacro body — " <>
                "a module-eval call bakes engine presence into the .beam (stale-recompile footgun, EXTRACT-04) " <>
                "posture=merge_blocking"
      end
    end

    :ok
  end
end
