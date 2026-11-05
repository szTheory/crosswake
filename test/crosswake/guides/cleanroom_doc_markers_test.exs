defmodule Crosswake.Guides.CleanroomDocMarkersTest do
  @moduledoc """
  Network-free guard for the marked public docs (Phase 197, D-05, D-06, D-07c, D-25).

  The published-cleanroom docs leg executes the fences of `README.md` (the Integrating
  section) and `guides/install.md` against a released Crosswake. That leg needs the network,
  so it cannot run in the merge-blocking suite. This test checks the same text rules locally:
  every fence is marked, no executed block reaches into the repository, every clone-only step
  is labelled, the wiring tokens are present, one route id is used throughout, and the one
  deferred `:ios_host` block is the only block carrying `since=`.

  Each rule has a negative control that edits a copy of the real doc, asserts the copy
  differs from the original (a mutation that changes nothing would prove nothing), and
  asserts the specific violation tag appears.
  """

  use ExUnit.Case, async: true

  @readme_path "README.md"
  @install_path "guides/install.md"
  @script_path "script/verify_published_cleanroom.sh"

  @docs [readme: @readme_path, install: @install_path]

  @marker ~r/^<!-- cleanroom:(run|apply|clone|show)((?: [a-z_]+=[^ ]+)*) -->$/

  @label "*Needs a clone of the Crosswake repository; skip this if you installed from Hex.*"
  @summary_line ~s(*Steps marked "Needs a clone" are for contributors; every other step works from Hex alone.*)

  @required_tokens [
    "CrosswakeBridge",
    "--external:/crosswake/*",
    "--format=esm",
    "Crosswake.Bridge.attach()",
    ":ios_host"
  ]

  @repo_only_tokens [
    "bash script/",
    "script/verify_",
    "bin/see-it-run.sh",
    "mix crosswake.doctor --native-checks"
  ]

  @ios_host_since "0.2.12"

  # --- the real docs ------------------------------------------------------------------

  describe "the real docs" do
    test "pass every rule" do
      for {file, path} <- @docs do
        assert violations(file, File.read!(path)) == [], "#{path} has marker violations"
      end
    end

    test "are not vacuous: enough fences, enough repo-only occurrences, one :ios_host block" do
      readme = File.read!(@readme_path)
      install = File.read!(@install_path)

      assert length(fences(scope(:install, install))) >= 10
      assert length(fences(scope(:readme, readme))) >= 8

      for {file, text} <- [readme: readme, install: install] do
        assert repo_only_occurrences(text) >= 3,
               "#{file}: the repo-only token list matched fewer than 3 places"

        ios_blocks =
          text
          |> scope_for(file)
          |> fences()
          |> Enum.filter(&String.contains?(&1.body, ":ios_host"))

        assert [%{attrs: %{"since" => @ios_host_since}}] = ios_blocks
      end
    end

    test "marker ids are unique across both files" do
      ids =
        for {file, path} <- @docs,
            fence <- fences(scope(file, File.read!(path))),
            fence.id != nil,
            do: fence.id

      assert ids != []
      assert ids == Enum.uniq(ids), "duplicate marker ids: #{inspect(ids -- Enum.uniq(ids))}"
    end

    test "DOCS_EXECUTED_FLOOR equals the executed blocks plus one harness compile per file" do
      floor = read_floor()

      executed =
        for {file, path} <- @docs,
            fence <- fences(scope(file, File.read!(path))),
            fence.kind in ["run", "apply"],
            not Map.has_key?(fence.attrs, "since"),
            reduce: 0 do
          acc -> acc + 1
        end

      expected = executed + length(@docs)

      assert floor > 1, "DOCS_EXECUTED_FLOOR is still the placeholder"

      assert floor == expected,
             "DOCS_EXECUTED_FLOOR=#{floor} but the docs hold #{executed} run/apply blocks " <>
               "without since= plus #{length(@docs)} harness compiles (#{expected}). " <>
               "Update DOCS_EXECUTED_FLOOR in #{@script_path} to #{expected} after confirming " <>
               "the docs leg's executed= count for the new text."
    end
  end

  # --- negative controls --------------------------------------------------------------

  describe "negative controls" do
    test "a stripped marker is an unmarked fence" do
      for {file, id} <- [install: "install", readme: "readme-install"] do
        original = File.read!(path(file))

        mutated =
          mutate!(original, &String.replace(&1, "<!-- cleanroom:run id=#{id} -->\n", ""))

        assert :unmarked_fence in tags(violations(file, mutated))
      end
    end

    test "a run block that reaches into the repository is a repo-only run" do
      for file <- [:readme, :install] do
        mutated =
          mutate!(
            File.read!(path(file)),
            &String.replace(&1, "mix deps.get\n```", "mix deps.get\nbash script/verify_x.sh\n```",
              global: false
            )
          )

        assert :repo_only_run in tags(violations(file, mutated))
      end
    end

    test "a clone block without its italic label is a clone label violation" do
      for file <- [:readme, :install] do
        mutated =
          mutate!(
            File.read!(path(file)),
            &String.replace(
              &1,
              "bash script/verify_phase5_example_hosts.sh\n```\n\n" <> @label,
              "bash script/verify_phase5_example_hosts.sh\n```",
              global: false
            )
          )

        assert :clone_label in tags(violations(file, mutated))
      end
    end

    test "a removed required token is reported for that file" do
      for file <- [:readme, :install], token <- @required_tokens do
        mutated = mutate!(File.read!(path(file)), &String.replace(&1, token, "REMOVED"))

        assert {:required_token, file, token} in violations(file, mutated),
               "removing #{token} from #{file} was not reported"
      end
    end

    test "a diverging route id is a route id consistency violation" do
      for file <- [:readme, :install] do
        mutated =
          mutate!(
            File.read!(path(file)),
            &String.replace(
              &1,
              ~s(entry_route_id: "study-session"),
              ~s(entry_route_id: "other-session")
            )
          )

        assert :route_id_consistency in tags(violations(file, mutated))
      end
    end

    test "an unlabeled repo-only list item is reported (install quick list)" do
      original = File.read!(@install_path)

      for item <- [
            "`bash script/verify_phase5_example_hosts.sh` (needs a clone)",
            "`mix crosswake.doctor --native-checks` (needs a clone)"
          ] do
        mutated =
          mutate!(
            original,
            &String.replace(&1, item, String.replace(item, " (needs a clone)", ""))
          )

        assert :unlabeled_repo_only in tags(violations(:install, mutated)),
               "removing the label from #{item} was not reported"
      end
    end

    test "an unlabeled repo-only bullet is reported (README proof and support posture)" do
      original = File.read!(@readme_path)

      mutated =
        mutate!(
          original,
          &String.replace(
            &1,
            "is the primary checked-in proof lane (needs a clone).",
            "is the primary checked-in proof lane."
          )
        )

      assert :unlabeled_repo_only in tags(violations(:readme, mutated))
    end

    test "an unlabeled repo-only fence outside the marked scope is reported (bin/see-it-run.sh)" do
      mutated =
        mutate!(
          File.read!(@readme_path),
          &String.replace(&1, "bin/see-it-run.sh\n```\n\n" <> @label, "bin/see-it-run.sh\n```",
            global: false
          )
        )

      assert :unlabeled_repo_only in tags(violations(:readme, mutated))
    end

    test "since=0.2.12 moved off the ios-host block is an ios_host since violation" do
      for {file, id} <- [install: "ios-host", readme: "readme-ios-host"] do
        original = File.read!(path(file))

        removed =
          mutate!(
            original,
            &String.replace(&1, "mode=append since=#{@ios_host_since} -->", "mode=append -->")
          )

        assert :ios_host_since in tags(violations(file, removed)), "#{id}: removal not reported"
      end
    end

    test "since=0.2.12 on any other block is an ios_host since violation" do
      for file <- [:readme, :install] do
        mutated =
          mutate!(
            File.read!(path(file)),
            &String.replace(&1, "mode=js-hook -->", "mode=js-hook since=#{@ios_host_since} -->")
          )

        assert :ios_host_since in tags(violations(file, mutated))
      end
    end

    test "a missing Needs-a-clone summary line is reported" do
      for file <- [:readme, :install] do
        mutated = mutate!(File.read!(path(file)), &String.replace(&1, @summary_line, ""))

        assert :summary_line in tags(violations(file, mutated))
      end
    end

    test "a floor above or below the docs would be caught by the equality rule" do
      # The equality assertion in the real-docs test is the guard; this control proves the
      # count it compares against moves when a run block is stripped of its marker's kind.
      install = File.read!(@install_path)

      mutated =
        mutate!(
          install,
          &String.replace(&1, "<!-- cleanroom:run id=deps -->", "<!-- cleanroom:show -->")
        )

      assert executed_blocks(:install, mutated) == executed_blocks(:install, install) - 1
    end
  end

  # --- parsing and rules --------------------------------------------------------------

  defp path(file), do: Keyword.fetch!(@docs, file)

  defp read_floor do
    script = File.read!(@script_path)

    case Regex.run(~r/^DOCS_EXECUTED_FLOOR=(\d+)$/m, script) do
      [_, n] -> String.to_integer(n)
      nil -> flunk("DOCS_EXECUTED_FLOOR=<n> not found in #{@script_path}")
    end
  end

  defp tags(violations), do: Enum.map(violations, &elem(&1, 0))

  defp mutate!(text, fun) do
    mutated = fun.(text)

    if mutated == text do
      raise "the mutation changed nothing; the control would assert nothing"
    end

    mutated
  end

  defp executed_blocks(file, text) do
    file
    |> scope(text)
    |> fences()
    |> Enum.count(&(&1.kind in ["run", "apply"] and not Map.has_key?(&1.attrs, "since")))
  end

  defp scope(:readme, text),
    do: section_between(text, "### Integrating Crosswake", "### Contributing or maintaining")

  defp scope(:install, text), do: text

  defp scope_for(text, file), do: scope(file, text)

  defp section_between(contents, start_heading, next_heading) do
    [_, rest] = String.split(contents, start_heading, parts: 2)
    [section | _] = String.split(rest, next_heading, parts: 2)
    section
  end

  defp split_lines(text),
    do: text |> String.split("\n") |> Enum.map(&String.trim_trailing(&1, "\r"))

  # Same fence rule as strip_fences/1 in script/check_release_doc_version_literals.exs: a
  # trimmed line that starts with three backticks toggles the fence.
  defp fence_spans(lines) do
    {spans, open} =
      lines
      |> Enum.with_index()
      |> Enum.reduce({[], nil}, fn {line, index}, {spans, open} ->
        if line |> String.trim_leading() |> String.starts_with?("```") do
          case open do
            nil -> {spans, index}
            opened -> {[{opened, index} | spans], nil}
          end
        else
          {spans, open}
        end
      end)

    if open != nil, do: raise("unclosed fence opened at line #{open + 1}")

    Enum.reverse(spans)
  end

  defp nonblank_before(lines, index) do
    lines |> Enum.take(index) |> Enum.reverse() |> Enum.find(&(String.trim(&1) != ""))
  end

  defp nonblank_after(lines, index) do
    lines |> Enum.drop(index + 1) |> Enum.find(&(String.trim(&1) != ""))
  end

  defp fences(text) do
    lines = split_lines(text)

    for {open, close} <- fence_spans(lines) do
      marker = nonblank_before(lines, open)

      {kind, attrs} =
        case marker && Regex.run(@marker, marker) do
          [_, kind, attr_string] ->
            attrs =
              ~r/ ([a-z_]+)=([^ ]+)/
              |> Regex.scan(attr_string, capture: :all_but_first)
              |> Map.new(fn [key, value] -> {key, value} end)

            {kind, attrs}

          _ ->
            {nil, %{}}
        end

      %{
        kind: kind,
        attrs: attrs,
        id: Map.get(attrs, "id"),
        marker: marker,
        body: lines |> Enum.slice((open + 1)..(close - 1)//1) |> Enum.join("\n"),
        after: nonblank_after(lines, close),
        line: open + 1
      }
    end
  end

  # Returns a list of tagged tuples {tag, file, detail}; [] means the doc passes.
  defp violations(file, text) do
    scoped = fences(scope(file, text))
    executable = Enum.filter(scoped, &(&1.kind in ["run", "apply"]))
    union = Enum.map_join(executable, "\n", & &1.body)

    marker_violations(file, scoped) ++
      token_violations(file, union) ++
      since_violations(file, scoped) ++
      route_id_violations(file, union) ++
      repo_only_violations(file, text) ++
      summary_violations(file, text)
  end

  defp marker_violations(file, fences) do
    Enum.flat_map(fences, fn fence ->
      cond do
        fence.kind == nil ->
          [{:unmarked_fence, file, "line #{fence.line}"}]

        fence.kind == "run" and
            Enum.any?(["script/", "bash script", "examples/"], &String.contains?(fence.body, &1)) ->
          [{:repo_only_run, file, fence.id}]

        fence.kind == "clone" and fence.after != @label ->
          [{:clone_label, file, fence.id}]

        true ->
          []
      end
    end)
  end

  defp token_violations(file, union) do
    for token <- @required_tokens,
        not String.contains?(union, token),
        do: {:required_token, file, token}
  end

  # D-04 amendment: only the block that carries `:ios_host` may carry `since=`, and it must
  # carry exactly the version that first reads it.
  defp since_violations(file, fences) do
    Enum.flat_map(fences, fn fence ->
      ios? = String.contains?(fence.body, ":ios_host")
      since = Map.get(fence.attrs, "since")

      cond do
        ios? and since != @ios_host_since -> [{:ios_host_since, file, fence.id}]
        not ios? and since != nil -> [{:ios_host_since, file, fence.id}]
        true -> []
      end
    end)
  end

  defp route_id_violations(file, union) do
    route_ids = Regex.scan(~r/crosswake: \[id: "([^"]+)"/, union, capture: :all_but_first)
    assign_ids = Regex.scan(~r/crosswake_route_id: "([^"]+)"/, union, capture: :all_but_first)
    entry_ids = Regex.scan(~r/entry_route_id: "([^"]+)"/, union, capture: :all_but_first)

    all = List.flatten([route_ids, assign_ids, entry_ids])

    if route_ids == [] or assign_ids == [] or entry_ids == [] or length(Enum.uniq(all)) != 1 do
      [{:route_id_consistency, file, Enum.uniq(all)}]
    else
      []
    end
  end

  defp summary_violations(file, text) do
    if String.contains?(text, @summary_line), do: [], else: [{:summary_line, file, nil}]
  end

  # W-1 / D-06: evaluated over the whole file, not only the marked scope.
  defp repo_only_violations(file, text) do
    lines = split_lines(text)

    in_fence =
      for {open, close} <- fence_spans(lines), i <- open..close, into: MapSet.new(), do: i

    prose =
      for {line, index} <- Enum.with_index(lines),
          not MapSet.member?(in_fence, index),
          repo_only?(line),
          not labeled?(lines, index),
          do: {:unlabeled_repo_only, file, String.trim(line)}

    fenced =
      for fence <- fences(text),
          repo_only?(fence.body),
          fence.after != @label,
          do: {:unlabeled_repo_only, file, "fence at line #{fence.line}"}

    prose ++ fenced
  end

  defp repo_only_occurrences(text) do
    lines = split_lines(text)

    in_fence =
      for {open, close} <- fence_spans(lines), i <- open..close, into: MapSet.new(), do: i

    prose =
      Enum.count(Enum.with_index(lines), fn {line, index} ->
        not MapSet.member?(in_fence, index) and repo_only?(line)
      end)

    prose + Enum.count(fences(text), &repo_only?(&1.body))
  end

  defp repo_only?(text), do: Enum.any?(@repo_only_tokens, &String.contains?(text, &1))

  # The D-06 summary line says "Needs a clone" but is a global statement, not a label for the
  # line below it, so it never counts as one.
  defp label_text?(line) do
    line != @summary_line and String.contains?(String.downcase(line), "needs a clone")
  end

  defp labeled?(lines, index) do
    line = Enum.at(lines, index)

    cond do
      label_text?(line) ->
        true

      list_item?(line) ->
        case lead_in(lines, index) do
          nil -> false
          lead_in -> label_text?(lead_in)
        end

      true ->
        case nonblank_before(lines, index) do
          nil -> false
          previous -> label_text?(previous)
        end
    end
  end

  defp list_item?(line), do: Regex.match?(~r/^\s*(?:[-*]|\d+\.)\s/, line)

  # The first line above a list that is neither a list item nor blank.
  defp lead_in(lines, index) do
    lines
    |> Enum.take(index)
    |> Enum.reverse()
    |> Enum.find(&(not list_item?(&1) and String.trim(&1) != ""))
  end
end
