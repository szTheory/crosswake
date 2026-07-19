defmodule Crosswake.Guides.ArchitectureCodeWalkthroughTest do
  use ExUnit.Case, async: true

  @architecture_path "guides/architecture.md"
  @walkthrough_path "guides/code-walkthrough.md"

  @architecture_headings [
    "## Opening promise",
    "## Crosswake in one picture",
    "## Vocabulary for the trip",
    "## Journey 1: a route becomes shared runtime truth",
    "## Journey 2: activation chooses an owner or stops",
    "## A bounded bridge is not a second application runtime",
    "## Offline, packs, transfers, commerce, and auth hang from ownership",
    "## The package family preserves optionality",
    "## Support truth is part of the runtime contract",
    "## Module atlas",
    "## Code-reading routes",
    "## Changing Crosswake safely",
    "## Where to go next"
  ]

  @documented_exports [
    {Crosswake.Policy.Compiler, :compile, 2},
    {Crosswake.Manifest, :compile, 2},
    {Crosswake.Shell.Activation, :resolve, 2},
    {Crosswake.Compatibility.RouteGate, :evaluate, 4},
    {Crosswake.Bridge.Contract, :version, 0},
    {Crosswake.Bridge.Contract, :new_request, 1},
    {Crosswake.Bridge.Registry, :lookup, 4},
    {Crosswake.Doctor, :run, 1}
  ]

  test "ExDoc preserves the start path and existing group taxonomy" do
    docs = Crosswake.MixProject.project()[:docs]
    extras = docs[:extras]
    groups = docs[:groups_for_extras]

    assert Enum.take(extras, 4) == [
             "README.md",
             "guides/see_it_run.md",
             @architecture_path,
             @walkthrough_path
           ]

    assert Enum.take(groups[:Start], 6) == [
             "README.md",
             "guides/see_it_run.md",
             @architecture_path,
             @walkthrough_path,
             "guides/route_policy.md",
             "guides/install.md"
           ]

    assert Keyword.keys(groups) == [
             :Start,
             :Adopt,
             :"Runtime Owners",
             :Truth,
             :Telemetry,
             :"Extension Authors",
             :"Advanced/Companions"
           ]

    assert docs[:main] == "readme"
  end

  test "README places each guide in its reader lane and guide map" do
    readme = File.read!("README.md")
    evaluating = section_between(readme, "### Evaluating Crosswake", "### Integrating Crosswake")

    maintaining =
      section_between(readme, "### Contributing or maintaining", "## Architecture at a glance")

    guide_map = section_between(readme, "## Guide map", "## Current baseline")

    assert evaluating =~ "[guides/architecture.md](guides/architecture.md)"
    refute evaluating =~ "guides/code-walkthrough.md"

    assert maintaining =~ "[guides/code-walkthrough.md](guides/code-walkthrough.md)"
    refute maintaining =~ "guides/architecture.md"

    assert guide_map =~ "[guides/architecture.md](guides/architecture.md)"
    assert guide_map =~ "[guides/code-walkthrough.md](guides/code-walkthrough.md)"
  end

  test "architecture keeps the required journey and four accessible diagrams" do
    architecture = File.read!(@architecture_path)

    positions =
      Enum.map(@architecture_headings, fn heading ->
        case :binary.match(architecture, heading) do
          {position, _length} ->
            position

          :nomatch ->
            flunk("#{@architecture_path} is missing required heading #{inspect(heading)}")
        end
      end)

    assert positions == Enum.sort(positions),
           "architecture headings must remain in the required outside-in order"

    diagrams = fenced_blocks(architecture, "mermaid")
    assert length(diagrams) == 4

    Enum.with_index(diagrams, 1)
    |> Enum.each(fn {diagram, index} ->
      assert diagram =~ "accTitle:", "Mermaid diagram #{index} is missing accTitle"
      assert diagram =~ "accDescr:", "Mermaid diagram #{index} is missing accDescr"
    end)
  end

  test "walkthrough keeps a bounded representative trail and parseable Elixir" do
    walkthrough = File.read!(@walkthrough_path)

    excerpts =
      Enum.flat_map(["elixir", "swift", "kotlin"], fn language ->
        fenced_blocks(walkthrough, language)
      end)

    assert length(excerpts) in 12..18
    assert fenced_blocks(walkthrough, "swift") != []
    assert fenced_blocks(walkthrough, "kotlin") != []

    walkthrough
    |> fenced_blocks("elixir")
    |> Enum.with_index(1)
    |> Enum.each(fn {block, index} ->
      assert {:ok, _ast} = Code.string_to_quoted(block),
             "Elixir walkthrough block #{index} must remain parseable"
    end)
  end

  test "documented architectural exports still exist" do
    walkthrough = File.read!(@walkthrough_path)

    Enum.each(@documented_exports, fn {module, function, arity} ->
      module_name = inspect(module)

      assert walkthrough =~ module_name,
             "walkthrough must name #{module_name} for #{function}/#{arity}"

      assert walkthrough =~ Atom.to_string(function),
             "walkthrough must name #{module_name}.#{function}/#{arity}"

      assert Code.ensure_loaded?(module), "expected #{module_name} to load"

      assert function_exported?(module, function, arity),
             "documented export #{module_name}.#{function}/#{arity} no longer exists"
    end)
  end

  test "guide navigation is mutual and source references are portable" do
    architecture = File.read!(@architecture_path)
    walkthrough = File.read!(@walkthrough_path)

    assert architecture =~ "[Code walkthrough](code-walkthrough.md)"
    assert walkthrough =~ "[Architecture guide](architecture.md)"

    for {path, contents} <- [
          {@architecture_path, architecture},
          {@walkthrough_path, walkthrough}
        ] do
      refute contents =~ ~r{/(?:Users|home|tmp)/}, "#{path} exposes a machine-local path"
      refute contents =~ ~r{github\.com/[^\s)]+/blob/}, "#{path} exposes a GitHub blob link"
      refute contents =~ ~r/#L\d+/, "#{path} exposes a brittle line anchor"
    end
  end

  test "docs configure the canonical favicon and failure-safe themed Mermaid hooks" do
    docs = Crosswake.MixProject.project()[:docs]
    head = docs[:before_closing_head_tag].(:html)
    body = docs[:before_closing_body_tag].(:html)

    assert docs[:logo] == "brandbook/logo/crosswake-mark.svg"
    assert docs[:favicon] == "brandbook/logo/favicon.svg"
    assert File.exists?(docs[:favicon])

    assert head =~ "https://cdn.jsdelivr.net/npm/mermaid@11.15.0/dist/mermaid.min.js"

    assert head =~
             "sha384-yQ4mmBBT+vhTAwjFH0toJXNYJ6O4usWnt6EPIdWwrRvx2V/n5lXuDZQwQFeSFydF"

    assert head =~ ~s(integrity="sha384-)
    assert head =~ ~s(crossorigin="anonymous")
    assert head =~ ".crosswake-mermaid"

    assert body =~ ~s(securityLevel: "strict")
    assert body =~ "startOnLoad: false"
    assert body =~ "flowchart: {htmlLabels: false}"
    assert body =~ "window.addEventListener(\"exdoc:loaded\""
    assert body =~ "new MutationObserver"
    assert body =~ "classList.contains(\"dark\")"
    assert body =~ "controller.queue"
    assert body =~ "if (output) output.remove()"
    assert body =~ "source.hidden = false"
    assert body =~ "source.hidden = true"
    assert body =~ "console.warn"

    assert docs[:before_closing_head_tag].(:epub) == ""
    assert docs[:before_closing_body_tag].(:epub) == ""
  end

  defp fenced_blocks(contents, language) do
    Regex.scan(~r/^```#{Regex.escape(language)}\r?\n(.*?)^```\s*$/ms, contents,
      capture: :all_but_first
    )
    |> List.flatten()
  end

  defp section_between(contents, start_heading, next_heading) do
    [_, rest] = String.split(contents, start_heading, parts: 2)
    [section | _] = String.split(rest, next_heading, parts: 2)
    section
  end
end
