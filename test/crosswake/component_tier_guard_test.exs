defmodule Crosswake.ComponentTierGuardTest do
  @moduledoc """
  Four controls proving `Crosswake.ComponentTierGuard`'s six FALL-02 rules
  actually have teeth (D-37, D-46).

  Every fixture tree is built under a per-test `System.tmp_dir!/0` directory
  with `on_exit` cleanup, and driven through the `root:` seam —
  `ComponentTierGuard.assert_no_component_tier!(root: fixture_root)` — the
  REAL raiser, never a re-composed predicate, mirroring
  `test/crosswake/proof/phase154_recipe_followable_test.exs`'s discipline.
  Every fixture-driven test below passes `root:` explicitly; nothing here
  ever calls the underlying `check_*` predicates directly and hopes the
  composition matches the raiser's.

  Runs UNTAGGED and repo-root-only (D-39): CI's hermetic step excludes the
  example-host-only tag, so a tagged test would drop into the single serial
  lane capped at one case. This file carries no such tag, so it rides the
  five-lane hermetic parallelism instead.

  ## The mutation control (not a permanent test here)

  The plan's mutation control — stripping the DSL attribute calls from the
  REAL shipped `priv/templates/crosswake/native_controls_ui/crosswake_fallbacks.ex.eex`
  and confirming `Control 3` goes RED — was run once by hand during Plan
  155-05's execution and is recorded in `155-05-SUMMARY.md`, not encoded as a
  permanent automated test. Mutating a real shipped file at test-suite runtime
  would race with every other async test reading that same file (including
  `Control 3` itself), which is exactly the kind of flakiness a hermetic test
  suite must not introduce. The synthetic Control 4b fixture below exercises
  the identical code path (`components_exist_in_templates` against a
  marker-free template directory) safely and repeatably.
  """

  use ExUnit.Case, async: true

  alias Crosswake.ComponentTierGuard

  @expected_rule_names ~w(
    namespace
    namespace_minted
    component_use
    component_dsl
    template_sigil
    components_exist_in_templates
  )a

  # ---------------------------------------------------------------------------
  # Control 1 — multi-violation fixture: the SET of violated rules, not a count
  # ---------------------------------------------------------------------------

  describe "Control 1 — a multi-violation fixture reports the SET of violated rules" do
    test "a source violating namespace, component_use, and template_sigil at once reports all three — never just the first" do
      root = new_root()
      build_fixture(root, multi_violation_source())

      assert {:error, message} = run_guard(root: root)

      violated = message |> violation_lines() |> extract_rule_ids()

      # A `length >= 1` assertion would pass even if five of six rules had
      # silently stopped working. Pin the exact count AND the exact set.
      assert length(violated) == 3

      assert MapSet.new(violated) ==
               MapSet.new(["namespace", "component_use", "template_sigil"]),
             "expected exactly {namespace, component_use, template_sigil}, got #{inspect(violated)}"
    end
  end

  # ---------------------------------------------------------------------------
  # Control 2 — five one-rule synthetics, each raising with exactly its own id
  # ---------------------------------------------------------------------------

  describe "Control 2 — five one-rule synthetics" do
    test "namespace alone raises [proof.fall_02.no_component_tier.namespace] and nothing else" do
      assert_single_rule_violation(namespace_only_source(), "namespace")
    end

    test "namespace_minted alone raises [proof.fall_02.no_component_tier.namespace_minted] and nothing else" do
      assert_single_rule_violation(namespace_minted_only_source(), "namespace_minted")
    end

    test "component_use alone raises [proof.fall_02.no_component_tier.component_use] and nothing else" do
      assert_single_rule_violation(component_use_only_source(), "component_use")
    end

    test "component_dsl alone raises [proof.fall_02.no_component_tier.component_dsl] and nothing else" do
      assert_single_rule_violation(component_dsl_only_source(), "component_dsl")
    end

    test "template_sigil alone raises [proof.fall_02.no_component_tier.template_sigil] and nothing else" do
      assert_single_rule_violation(template_sigil_only_source(), "template_sigil")
    end
  end

  # ---------------------------------------------------------------------------
  # Control 3 — positive control: the real repo, unmocked, zero options
  # ---------------------------------------------------------------------------

  describe "Control 3 — positive control on the real shipped tree" do
    test "assert_no_component_tier!() with no options returns :ok against the real repo" do
      # The shipped zero-arity call — the one CI makes. Exercises both the
      # real lib/ tree and the real native-controls template directory. This
      # is the case that would go RED if a later phase actually shipped an
      # importable component tier.
      assert ComponentTierGuard.assert_no_component_tier!() == :ok
    end
  end

  # ---------------------------------------------------------------------------
  # Control 4a — attestation: a silently-dropped rule is caught
  # ---------------------------------------------------------------------------

  describe "Control 4a — attestation: the guard's live rule list matches the expected six" do
    test "ComponentTierGuard.rule_names/0 equals the expected six rule names" do
      live = MapSet.new(ComponentTierGuard.rule_names())
      expected = MapSet.new(@expected_rule_names)

      assert live == expected,
             "guard's live rule list diverged from the expected six — " <>
               "live=#{inspect(Enum.sort(live))} expected=#{inspect(Enum.sort(expected))}"

      assert length(ComponentTierGuard.rule_names()) == 6
    end
  end

  # ---------------------------------------------------------------------------
  # Control 4b — attestation: an orphan template fails the anti-vacuity twin
  # ---------------------------------------------------------------------------

  describe "Control 4b — attestation: an orphan template directory fails the twin" do
    test "a template directory whose files carry NEITHER a DSL call NOR a HEEx sigil fails components_exist_in_templates" do
      root = new_root()

      write_file(
        root,
        "lib/fixture/clean.ex",
        lines(["defmodule Fixture.Clean do", "  def hi, do: :ok", "end"])
      )

      write_file(
        root,
        "priv/templates/crosswake/native_controls_ui/plain.ex.eex",
        orphan_template_source()
      )

      assert {:error, message} = run_guard(root: root)
      assert message =~ "components_exist_in_templates"

      violated = message |> violation_lines() |> extract_rule_ids()

      # This is the difference D-37 exists to prove: a rule set that only
      # asserts absence would call this fixture clean, because it contains no
      # banned namespace, no use Phoenix.Component, and no ~H sigil anywhere.
      # It has NO real component either — the twin is what tells those two
      # trees apart. Two lines are expected: neither the DSL marker nor the
      # sigil marker was found, and the guard reports both missing reasons
      # rather than short-circuiting on the first.
      assert violated == ["components_exist_in_templates", "components_exist_in_templates"]
      assert MapSet.new(violated) == MapSet.new(["components_exist_in_templates"])
    end
  end

  # ---------------------------------------------------------------------------
  # Fixture construction
  # ---------------------------------------------------------------------------

  defp new_root do
    root =
      Path.join(
        System.tmp_dir!(),
        "cw-component-tier-guard-#{System.unique_integer([:positive])}"
      )

    File.mkdir_p!(root)
    on_exit(fn -> File.rm_rf!(root) end)
    root
  end

  defp write_file(root, relative, contents) do
    path = Path.join(root, relative)
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, contents)
    path
  end

  # A fixture root with `lib_source` at lib/fixture/violation.ex and a VALID
  # template alongside it, so `components_exist_in_templates` never joins the
  # violation set of a test that is only trying to isolate an absence rule.
  defp build_fixture(root, lib_source) do
    write_file(root, "lib/fixture/violation.ex", lib_source)

    write_file(
      root,
      "priv/templates/crosswake/native_controls_ui/valid.ex.eex",
      valid_template_source()
    )
  end

  defp assert_single_rule_violation(lib_source, expected_rule) do
    root = new_root()
    build_fixture(root, lib_source)

    assert {:error, message} = run_guard(root: root)

    violated = message |> violation_lines() |> extract_rule_ids()

    assert violated == [expected_rule],
           "expected exactly [#{expected_rule}], got #{inspect(violated)}"
  end

  # Runs the REAL raiser with `opts` and returns `:ok` or `{:error, message}` —
  # the raiser's own text, so every assertion above is made against what a
  # developer would actually read.
  defp run_guard(opts) do
    ComponentTierGuard.assert_no_component_tier!(opts)
  rescue
    error in RuntimeError -> {:error, Exception.message(error)}
  end

  # The "Every violated rule, not just the first:" block, and nothing else.
  # The surrounding prose (WHY THERE IS NO COMPONENT TIER, the retirement
  # recipe) mentions rule-shaped words unconditionally, so any per-rule
  # assertion must be scoped to this slice.
  defp violation_lines(message) do
    message
    |> String.split("Every violated rule, not just the first:\n", parts: 2)
    |> List.last()
    |> String.split("\n\nWHY THERE IS NO COMPONENT TIER", parts: 2)
    |> hd()
    |> String.split("\n", trim: true)
  end

  defp extract_rule_ids(lines) do
    Enum.map(lines, fn line ->
      [_, id] = Regex.run(~r/\[proof\.fall_02\.no_component_tier\.(\w+)\]/, line)
      id
    end)
  end

  defp lines(list), do: Enum.join(list, "\n") <> "\n"

  # ---------------------------------------------------------------------------
  # Synthetic sources — each built from a line list, never a raw heredoc, so a
  # nested `~H"""`/`"""` sequence cannot be mistaken for the outer heredoc's
  # own terminator.
  # ---------------------------------------------------------------------------

  # Violates namespace (Crosswake.UI.* alias), component_use, AND
  # template_sigil — deliberately NOT namespace_minted or component_dsl, so
  # Control 1's expected set is exactly these three.
  defp multi_violation_source do
    lines([
      "defmodule Crosswake.UI.Bogus do",
      "  use Phoenix.Component",
      "",
      "  def render(assigns) do",
      "    ~H\"\"\"",
      "    <div></div>",
      "    \"\"\"",
      "  end",
      "end"
    ])
  end

  defp namespace_only_source do
    lines([
      "defmodule Crosswake.UI.Widget do",
      "  def hello, do: :world",
      "end"
    ])
  end

  # Module.concat/1 with a literal atom list spelling the banned namespace.
  # Atom literals (`:Crosswake`, `:UI`) are NOT {:__aliases__} nodes, so this
  # does not also trip the `namespace` rule.
  defp namespace_minted_only_source do
    lines([
      "defmodule Fixture.NamespaceMinted do",
      "  def go, do: Module.concat([:Crosswake, :UI])",
      "end"
    ])
  end

  defp component_use_only_source do
    lines([
      "defmodule Fixture.ComponentUse do",
      "  use Phoenix.Component",
      "end"
    ])
  end

  defp component_dsl_only_source do
    lines([
      "defmodule Fixture.ComponentDsl do",
      "  attr :id, :string, required: true",
      "end"
    ])
  end

  defp template_sigil_only_source do
    lines([
      "defmodule Fixture.TemplateSigil do",
      "  def render(assigns) do",
      "    ~H\"\"\"",
      "    <div></div>",
      "    \"\"\"",
      "  end",
      "end"
    ])
  end

  # A REAL component-DSL attribute call AND a REAL HEEx sigil, so the twin
  # sees a genuine positive marker and does not itself become a violation
  # whenever it accompanies an absence-rule-only fixture above.
  defp valid_template_source do
    lines([
      "defmodule Fixture.ValidTemplate do",
      "  use Phoenix.Component",
      "",
      "  attr :id, :string, required: true",
      "",
      "  def widget(assigns) do",
      "    ~H\"\"\"",
      "    <div id={@id}></div>",
      "    \"\"\"",
      "  end",
      "end"
    ])
  end

  # Structurally valid Elixir, but carries NEITHER a DSL attribute call NOR a
  # HEEx sigil — the fixture Control 4b needs to prove the twin is not
  # vacuous: a rule set that only asserts absence would call this tree clean.
  defp orphan_template_source do
    lines([
      "defmodule Fixture.OrphanTemplate do",
      "  def hi, do: :ok",
      "end"
    ])
  end
end
