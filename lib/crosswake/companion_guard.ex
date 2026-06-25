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

  ## Plan 03 note

  The `check_source/1` and `check_ensure_loaded_placement/1` functions contain
  placeholder bodies in this plan (Plan 01). **Plan 03 implements the full AST
  walk logic.** Search for "Plan 03 implements AST logic" to find the injection
  sites.
  """


  # Hardcoded frozen set — one entry per extraction phase.
  # DO NOT derive from path: deps (core names no companion; D-13).
  @extracted_companions MapSet.new([
    # Phase 130: rulestead adapter extracted
    Crosswake.Companions.Rulestead
  ])

  @doc """
  Returns the frozen MapSet of extracted companion modules.

  One entry per extraction phase. To add a module, add it here AND in the same
  PR that removes the source from `lib/` — the reviewer sees the intentional
  shape change (D-13).
  """
  @spec extracted_companions() :: MapSet.t()
  def extracted_companions, do: @extracted_companions

  @doc """
  Checks whether `source_string` (Elixir source code) contains a static
  alias or reference to any extracted companion module.

  Returns `:ok` if no violations found, or `{:violation, list}` with the
  offending AST nodes.

  ## Plan 03 note

  **Plan 03 implements AST logic** (EXTRACT-03). Currently returns `:ok`
  unconditionally as a placeholder.
  """
  @spec check_source(String.t()) :: :ok | {:violation, list()}
  def check_source(_source_string) do
    # Plan 03 implements AST logic: Code.string_to_quoted/2 + Macro.prewalk/3
    # detecting {:__aliases__, _, [:Crosswake, :Companions, :Rulestead]} nodes.
    # Placeholder body — returns no violations until Plan 03 wires the AST walk.
    {:ok_placeholder, []}
    |> case do
      {:ok_placeholder, []} -> :ok
      {:violation, nodes} -> {:violation, nodes}
    end
  end

  @doc """
  Checks whether all `Code.ensure_loaded?` calls in `source_string` appear
  inside function bodies (`def`/`defp`/`defmacro`), never at module-eval time.

  Returns `:ok` if placement is correct, or `{:violation, list}` with the
  offending AST nodes.

  ## Plan 03 note

  **Plan 03 implements AST logic** (EXTRACT-04). Currently returns `:ok`
  unconditionally as a placeholder.
  """
  @spec check_ensure_loaded_placement(String.t()) :: :ok | {:violation, list()}
  def check_ensure_loaded_placement(_source_string) do
    # Plan 03 implements AST logic: AST prune-then-walk pattern (D-16).
    # Collect def/defp/defmacro body subtrees, then walk for Code.ensure_loaded? nodes.
    # A Code.ensure_loaded? node OUTSIDE a function body = violation.
    # Belt: raw regex for non-indented occurrence as escalation signal.
    # Placeholder body — returns no violations until Plan 03 wires the AST walk.
    {:ok_placeholder, []}
    |> case do
      {:ok_placeholder, []} -> :ok
      {:violation, nodes} -> {:violation, nodes}
    end
  end

  @doc """
  Walks all `lib/**/*.ex` files in the current working directory and raises if
  any file contains a static reference to an extracted companion module.

  Uses `Path.wildcard/1` from `File.cwd!()`. The assertion failure message
  is a `stable_id_message/7` with posture `:merge_blocking`.

  ## Plan 03 note

  **Plan 03 implements AST logic** (EXTRACT-03). Currently this function
  iterates files but delegates to the stub `check_source/1`.
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

  ## Plan 03 note

  **Plan 03 implements AST logic** (EXTRACT-04). Currently this function
  iterates files but delegates to the stub `check_ensure_loaded_placement/1`.
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
                "hint=move Code.ensure_loaded? inside a def/defp/defmacro body (EXTRACT-04) " <>
                "posture=merge_blocking"
      end
    end

    :ok
  end
end
