defmodule Crosswake.ComponentTierGuard do
  @moduledoc """
  Merge-blocking structural guard for FALL-02 — "nothing UI-shaped ships
  importable from `lib/`" (Phase 155).

  This module is a plain support module (NO `use ExUnit.Case`) callable from
  the proof lane and, in the future, from `mix crosswake.doctor`. It lives in
  `lib/`, not `test/`, for the same reason `CatalogGuard` and `CompanionGuard`
  do: deleting the test must not delete the rule. The guard travels with the
  code.

  ## The names-as-strings trick (D-36) — why this file cannot self-trip

  `@banned_namespace` below is a plain STRING, split on `"."` and mapped
  through `String.to_atom/1` at compile time to build `@banned_alias_parts`.
  The banned dotted name is never written anywhere in this file as an actual
  module reference (`SomeNamespace.Child`) — only as string content. A bare
  module reference would parse to a `{:__aliases__, _, parts}` AST node, and
  if that node's parts matched the banned prefix, THIS file would trip its
  own `namespace` rule the moment it compiled. Stealing this trick from
  `companion_guard.ex:29-33` (and reusing its own comment, almost verbatim)
  is what makes a self-referential structural guard possible at all.

  ## The six rules

  Five are absence rules over every `.ex` file under `lib/`:

    * `namespace` — a bare module reference whose first two segments spell
      the banned namespace. Any OTHER alias is clean.
    * `namespace_minted` — a `Module.concat/1` or `String.to_atom/1` call
      whose LITERAL argument spells the banned namespace. A runtime-computed
      argument is out of reach for a static AST walk — documented as a
      limitation, not silently claimed as covered.
    * `component_use` — `use Phoenix.Component` or `use Phoenix.LiveComponent`
      anywhere under `lib/`. Zero occurrences today.
    * `component_dsl` — an `attr/2`, `attr/3`, `slot/1`, or `slot/2` call node
      at module body level.
    * `template_sigil` — a `~H` (`sigil_H`) AST node. Zero occurrences today.

  The sixth is the anti-vacuity twin, and it is the whole point (D-37):

    * `components_exist_in_templates` — the native-controls generator's
      templates must contain at least one real component-DSL attribute call
      AND at least one real `~H` sigil. An empty, missing, or stripped
      template directory FAILS this rule.

  Without the sixth rule, the other five prove only "this project ships no
  components" — true of a project that ships NOTHING. With it, the claim
  proven is the actual requirement: "components exist only as adopter-owned
  template text, never as an importable tier." A `.eex` template carrying EEx
  interpolation is not parseable as Elixir, so this rule uses the belt-style
  regex approach `companion_guard.ex` already establishes for the same
  not-really-Elixir problem — labelled honestly in this module as a regex
  belt, not an upgrade to AST rigor it cannot claim.

  ## The injection seam, and why it is not a loophole

  `assert_no_component_tier!/1` accepts `root:`, `lib_glob:`, and
  `template_glob:`, each defaulting to the real shipped value (mirroring
  `catalog_guard.ex:88-102`'s seam contract), so the zero-argument call —
  the one CI makes — is byte-for-byte the production gate. The seam exists so
  a fixture test can drive THIS raiser against a synthetic tree, never a
  re-composition of its predicates. Nothing is relaxed and nothing is
  skippable through the seam.

  ## No bypass

  There is no allowlist, no suppression attribute, and no environment escape.
  The `opts` keyword accepts exactly `root:`, `lib_glob:`, and
  `template_glob:` — nothing that weakens a violated rule. The only sanctioned
  exit is retirement: delete the guard and its test in a PR that also amends
  FALL-02, README, and the guides. See `failure_message/1` for the full
  five-step recipe every failure message prints.

  ## Stable failure ids

  - `proof.fall_02.no_component_tier.namespace`
  - `proof.fall_02.no_component_tier.namespace_minted`
  - `proof.fall_02.no_component_tier.component_use`
  - `proof.fall_02.no_component_tier.component_dsl`
  - `proof.fall_02.no_component_tier.template_sigil`
  - `proof.fall_02.no_component_tier.components_exist_in_templates`

  ## AST mechanism

  `Code.string_to_quoted/2` + `Macro.prewalk/3` only — stdlib, no new
  dependency, no cross-reference tooling. Mirrors `Crosswake.CompanionGuard`
  and `Crosswake.Bridge.CatalogGuard`.
  """

  # Stored as a plain STRING (not a bare module reference) so this attribute
  # definition does not itself contain a {:__aliases__} AST node — which
  # would cause component_tier_guard.ex to fail its own namespace rule
  # (self-false-positive). Mirrors companion_guard.ex:28-32 exactly.
  @banned_namespace "Crosswake.UI"
  @banned_alias_parts @banned_namespace |> String.split(".") |> Enum.map(&String.to_atom/1)

  @stable_id_prefix "proof.fall_02.no_component_tier"

  @default_lib_glob "lib/**/*.ex"
  @default_template_glob "priv/templates/crosswake/native_controls_ui/*"

  # Belt-style regex, not an AST assertion — a .eex template carrying EEx
  # interpolation is not parseable Elixir. Mirrors companion_guard.ex's belt
  # pattern used for the same reason.
  @component_dsl_belt ~r/^\s*(attr|slot)\s+:\w+/m
  @heex_sigil_belt ~r/~H"""/

  @rule_names [
    :namespace,
    :namespace_minted,
    :component_use,
    :component_dsl,
    :template_sigil,
    :components_exist_in_templates
  ]

  @doc """
  The six rule names this guard implements, in a stable order. Exposed so a
  test can assert the guard's OWN live list against an expected list, rather
  than re-declaring the six names independently and never noticing if one
  silently stops being checked.
  """
  @spec rule_names() :: [atom()]
  def rule_names, do: @rule_names

  @doc """
  Walks the real repo tree (or a fixture tree via the injection seam) and
  raises if any of the six rules is violated.

  Returns `:ok` when the tier line holds.

  ## Options — all defaulting to the real shipped values

    * `:root` — the tree `lib_glob` and `template_glob` are resolved against.
      Defaults to `File.cwd!()`.
    * `:lib_glob` — relative to `root`. Defaults to `"lib/**/*.ex"`.
    * `:template_glob` — relative to `root`. Defaults to the native-controls
      generator's template directory glob.

  `assert_no_component_tier!()` with no options is the merge-blocking gate,
  unchanged. The seam exists so a fixture test can drive THIS function
  against a synthetic tree — it never relaxes anything and never accepts a
  "skip" flag.
  """
  @spec assert_no_component_tier!(keyword()) :: :ok
  def assert_no_component_tier!(opts \\ []) do
    root = Keyword.get(opts, :root, File.cwd!())
    lib_glob = Keyword.get(opts, :lib_glob, @default_lib_glob)
    template_glob = Keyword.get(opts, :template_glob, @default_template_glob)

    lib_violations =
      root
      |> Path.join(lib_glob)
      |> Path.wildcard()
      |> Enum.flat_map(fn path ->
        case check_source(File.read!(path)) do
          :ok -> []
          {:violation, list} -> Enum.map(list, fn v -> {path, v} end)
        end
      end)

    template_violations =
      case check_templates(Path.join(root, template_glob)) do
        :ok -> []
        {:violation, list} -> Enum.map(list, fn v -> {template_glob, v} end)
      end

    case lib_violations ++ template_violations do
      [] -> :ok
      violations -> raise failure_message(violations)
    end
  end

  @doc """
  Runs the five source-level rules over `source_string` and returns the
  COMPLETE SET of violations.

  A source violating three rules reports all three — a report, not a
  short-circuit, matching `CatalogGuard.check_source/1`'s discipline: an
  assertion that stops at the first violation makes a three-violation fixture
  indistinguishable from a one-violation fixture, which is exactly how a
  structural gate degrades into a nuisance.

  Returns `:ok`, or `{:violation, [{rule_atom, node_or_detail}]}`. An empty or
  trivially small source is clean. An UNPARSEABLE source is a violation, not
  a pass — the guard fails closed, matching the sibling guards' discipline.
  """
  @spec check_source(String.t()) :: :ok | {:violation, list()}
  def check_source(source) when is_binary(source) do
    case Code.string_to_quoted(source, []) do
      {:ok, ast} ->
        violations =
          Enum.flat_map(
            [
              &namespace_violations/1,
              &namespace_minted_violations/1,
              &component_use_violations/1,
              &component_dsl_violations/1,
              &template_sigil_violations/1
            ],
            fn checker -> checker.(ast) end
          )

        wrap(violations)

      {:error, detail} ->
        {:violation, [{:unparseable_source, detail}]}
    end
  end

  @doc """
  Rule `namespace`: `:ok` unless `source` contains a bare module reference
  whose first segments spell the banned namespace.
  """
  @spec check_namespace(String.t()) :: :ok | {:violation, list()}
  def check_namespace(source), do: parse_then(source, &namespace_violations/1)

  @doc """
  Rule `namespace_minted`: `:ok` unless `source` contains a `Module.concat/1`
  or `String.to_atom/1` call whose literal argument spells the banned
  namespace. A runtime-computed argument cannot be seen by a static walk —
  this rule does not claim to cover that case.
  """
  @spec check_namespace_minted(String.t()) :: :ok | {:violation, list()}
  def check_namespace_minted(source), do: parse_then(source, &namespace_minted_violations/1)

  @doc """
  Rule `component_use`: `:ok` unless `source` contains `use Phoenix.Component`
  or `use Phoenix.LiveComponent`.
  """
  @spec check_component_use(String.t()) :: :ok | {:violation, list()}
  def check_component_use(source), do: parse_then(source, &component_use_violations/1)

  @doc """
  Rule `component_dsl`: `:ok` unless `source` contains an `attr/2`, `attr/3`,
  `slot/1`, or `slot/2` call node.
  """
  @spec check_component_dsl(String.t()) :: :ok | {:violation, list()}
  def check_component_dsl(source), do: parse_then(source, &component_dsl_violations/1)

  @doc """
  Rule `template_sigil`: `:ok` unless `source` contains a `~H` sigil node.
  """
  @spec check_template_sigil(String.t()) :: :ok | {:violation, list()}
  def check_template_sigil(source), do: parse_then(source, &template_sigil_violations/1)

  @doc """
  Rule `components_exist_in_templates` — the anti-vacuity twin (D-37).

  `:ok` only when at least one file matching `template_glob` carries a real
  component-DSL attribute call (`attr`/`slot`) AND at least one file (the same
  one or a different one) carries a real `~H` sigil. An empty, missing, or
  stripped template directory is a violation, never a vacuous pass.

  Uses a belt-style regex, not an AST assertion, because a `.eex` template
  carrying EEx interpolation is not parseable Elixir.
  """
  @spec check_templates(String.t()) :: :ok | {:violation, list()}
  def check_templates(template_glob) when is_binary(template_glob) do
    files = template_glob |> Path.wildcard() |> Enum.filter(&File.regular?/1)

    if files == [] do
      {:violation,
       [{:components_exist_in_templates, "no template files found at #{template_glob}"}]}
    else
      contents = Enum.map(files, &File.read!/1)
      has_dsl? = Enum.any?(contents, &Regex.match?(@component_dsl_belt, &1))
      has_sigil? = Enum.any?(contents, &Regex.match?(@heex_sigil_belt, &1))

      missing =
        []
        |> maybe_missing(not has_dsl?, "no attr/slot DSL call found under #{template_glob}")
        |> maybe_missing(not has_sigil?, "no ~H sigil found under #{template_glob}")

      wrap(Enum.map(missing, &{:components_exist_in_templates, &1}))
    end
  end

  defp maybe_missing(acc, true, reason), do: [reason | acc]
  defp maybe_missing(acc, false, _reason), do: acc

  # ---------------------------------------------------------------------------
  # AST predicates
  # ---------------------------------------------------------------------------

  defp parse_then(source, checker) when is_binary(source) do
    case Code.string_to_quoted(source, []) do
      {:ok, ast} -> wrap(checker.(ast))
      {:error, detail} -> {:violation, [{:unparseable_source, detail}]}
    end
  end

  defp namespace_violations(ast) do
    {_, violations} =
      Macro.prewalk(ast, [], fn
        {:__aliases__, _meta, parts} = node, acc when is_list(parts) ->
          if Enum.all?(parts, &is_atom/1) and List.starts_with?(parts, @banned_alias_parts) do
            {node, [{:namespace, node} | acc]}
          else
            {node, acc}
          end

        node, acc ->
          {node, acc}
      end)

    violations
  end

  defp namespace_minted_violations(ast) do
    {_, violations} =
      Macro.prewalk(ast, [], fn
        {{:., _, [{:__aliases__, _, [:Module]}, :concat]}, _, [arg]} = node, acc ->
          if literal_concat_spells_banned?(arg) do
            {node, [{:namespace_minted, node} | acc]}
          else
            {node, acc}
          end

        {{:., _, [{:__aliases__, _, [:String]}, :to_atom]}, _, [arg]} = node, acc ->
          if literal_binary_spells_banned?(arg) do
            {node, [{:namespace_minted, node} | acc]}
          else
            {node, acc}
          end

        node, acc ->
          {node, acc}
      end)

    violations
  end

  defp literal_concat_spells_banned?(list) when is_list(list) do
    atoms = Enum.map(list, &concat_element_atom/1)

    if Enum.any?(atoms, &is_nil/1) do
      false
    else
      List.starts_with?(atoms, @banned_alias_parts)
    end
  end

  defp literal_concat_spells_banned?(_other), do: false

  defp concat_element_atom({:__aliases__, _meta, [atom]}) when is_atom(atom), do: atom
  defp concat_element_atom(atom) when is_atom(atom) and not is_nil(atom), do: atom
  defp concat_element_atom(_other), do: nil

  defp literal_binary_spells_banned?(binary) when is_binary(binary) do
    String.starts_with?(binary, @banned_namespace) or
      String.starts_with?(binary, "Elixir." <> @banned_namespace)
  end

  defp literal_binary_spells_banned?(_other), do: false

  defp component_use_violations(ast) do
    {_, violations} =
      Macro.prewalk(ast, [], fn
        {:use, _meta, [{:__aliases__, _, [:Phoenix, :Component]} | _rest]} = node, acc ->
          {node, [{:component_use, node} | acc]}

        {:use, _meta, [{:__aliases__, _, [:Phoenix, :LiveComponent]} | _rest]} = node, acc ->
          {node, [{:component_use, node} | acc]}

        node, acc ->
          {node, acc}
      end)

    violations
  end

  defp component_dsl_violations(ast) do
    {_, violations} =
      Macro.prewalk(ast, [], fn
        {:attr, _meta, args} = node, acc when is_list(args) and length(args) in [2, 3] ->
          {node, [{:component_dsl, node} | acc]}

        {:slot, _meta, args} = node, acc when is_list(args) and length(args) in [1, 2] ->
          {node, [{:component_dsl, node} | acc]}

        node, acc ->
          {node, acc}
      end)

    violations
  end

  defp template_sigil_violations(ast) do
    {_, violations} =
      Macro.prewalk(ast, [], fn
        {:sigil_H, _meta, _args} = node, acc ->
          {node, [{:template_sigil, node} | acc]}

        node, acc ->
          {node, acc}
      end)

    violations
  end

  defp wrap([]), do: :ok
  defp wrap(violations), do: {:violation, violations}

  # ---------------------------------------------------------------------------
  # Failure message: stable id on line 1, then the path to yes
  # ---------------------------------------------------------------------------

  @doc false
  @spec failure_message(list()) :: String.t()
  def failure_message(violations) do
    [{first_path, {first_rule, first_detail}} | _] = violations

    header =
      "[#{stable_id(first_rule)}] " <>
        "subject=lib/ must ship no importable Phoenix component tier (FALL-02) " <>
        "source=Crosswake.ComponentTierGuard.assert_no_component_tier!/1 " <>
        "observed=#{inspect(first_detail)} " <>
        "path=#{first_path} " <>
        "posture=merge_blocking"

    all_lines =
      violations
      |> Enum.map(fn {path, {rule, detail}} ->
        "  - [#{stable_id(rule)}] #{rule} at #{path}: #{inspect(detail)}"
      end)
      |> Enum.join("\n")

    """
    #{header}

    Every violated rule, not just the first:
    #{all_lines}

    WHY THERE IS NO COMPONENT TIER

    FALL-02 keeps nothing UI-shaped importable from `lib/`. A generator that
    copies host-owned template text is a different thing from a library
    module a host imports and inherits future changes from — the first stays
    yours forever, the second is Crosswake quietly reaching back into your
    brand. This gate exists so that question never has to be answered by
    convention or code review discipline; it is answered structurally,
    every time, by a rule that cannot be talked around.

    THE FIVE-STEP RETIREMENT RECIPE

    A gate with a bypass is a gate that gets bypassed at 2am. There is no
    allowlist, no suppression comment, and no environment escape here. If
    FALL-02 is genuinely wrong for a case you have hit, the only sanctioned
    path is retiring the rule, in the open:

      1. Open an issue naming the anti-feature this would introduce.
      2. Amend FALL-02, plus README, plus the guides, in the SAME PR.
      3. Delete this guard and its test — never allowlist a single file.
      4. Add the newly importable module to mix.exs's groups_for_modules,
         because importable means public API.
      5. Add an "### Upgrade Impact" section describing what changes for
         every existing adopter.

    WHAT YOU PROBABLY WANT INSTEAD

    Most people who hit this gate do not actually need an importable
    component tier. Before opening that issue, check whether you want one of
    these instead:

      - Redefine a design token, if this is a styling question.
      - Run `mix crosswake.gen.native_controls_ui` and edit the file it
        writes, if this is a fallback-UI question — you own that file
        outright the moment it is generated.
      - Put the component in your own host's shared web module, if this is
        neither of the above. Naming that third path is what keeps this gate
        from getting deleted under deadline pressure instead of retired in
        the open.
    """
  end

  defp stable_id(rule), do: "#{@stable_id_prefix}.#{rule}"
end
