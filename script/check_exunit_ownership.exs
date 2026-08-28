#!/usr/bin/env elixir

defmodule Crosswake.ExUnitOwnership do
  @moduledoc false

  @default_exclusions [:advisory_only, :collateral_binaries, :engine_present]
  @example_workflow ".github/workflows/requires-example-host-gate.yml"
  @example_job "merge-blocking-requires-example-host"

  def run(root) do
    paths =
      root
      |> Path.join("test/**/*_test.exs")
      |> Path.wildcard()
      |> Enum.sort()

    if paths == [] do
      fail([
        diagnostic(
          "missing-test-tree",
          "test/**/*_test.exs",
          "no intended ExUnit files were found",
          "restore the test tree before evaluating execution ownership"
        )
      ])
    else
      analyses = Enum.map(paths, &analyze_file(&1, root))
      parse_errors = Enum.flat_map(analyses, & &1.errors)
      requires_example? = Enum.any?(analyses, &(:requires_example_host in &1.classes))
      lane_errors = if requires_example?, do: example_lane_errors(root), else: []

      ownership_errors =
        Enum.flat_map(analyses, fn analysis ->
          ownership_errors(analysis, lane_errors == [])
        end)

      errors = parse_errors ++ lane_errors ++ ownership_errors

      if errors == [] do
        IO.puts(
          "[crosswake] OK: execution classes active: default/hermetic and requires_example_host"
        )

        IO.puts("[crosswake] OK: all intended ExUnit files are owned by a merge-blocking class.")
        0
      else
        fail(errors)
      end
    end
  end

  defp analyze_file(path, root) do
    relative = Path.relative_to(path, root)

    case Code.string_to_quoted(File.read!(path), file: relative) do
      {:ok, ast} ->
        {tests, tag_errors} = collect_modules(ast, relative, [], [])

        errors =
          if tests == [] do
            [
              diagnostic(
                "no-runnable-tests",
                relative,
                "the file contains no executable ExUnit test macro",
                "add a runnable test or rename/remove the non-test *_test.exs file"
              )
            ]
          else
            tag_errors
          end

        classes = tests |> Enum.map(&classify/1) |> MapSet.new()
        %{path: relative, classes: classes, errors: errors}

      {:error, {line, error, token}} ->
        line_number = if is_integer(line), do: line, else: Keyword.get(line, :line, "unknown")

        detail =
          "Elixir parsing failed at line #{line_number}: #{format_parse_error(error, token)}"

        %{
          path: relative,
          classes: MapSet.new(),
          errors: [
            diagnostic(
              "malformed-exunit-source",
              relative,
              detail,
              "repair the Elixir syntax so executable tags and tests can be inventoried"
            )
          ]
        }
    end
  end

  defp collect_modules({:defmodule, _, [_name, body]}, path, tests, errors) do
    module_body = Keyword.get(body, :do)
    {module_tests, module_errors} = scan_module(module_body, path)
    {tests ++ module_tests, errors ++ module_errors}
  end

  defp collect_modules({:__block__, _, nodes}, path, tests, errors) do
    Enum.reduce(nodes, {tests, errors}, fn node, {acc_tests, acc_errors} ->
      collect_modules(node, path, acc_tests, acc_errors)
    end)
  end

  defp collect_modules(node, path, tests, errors) when is_tuple(node) do
    node
    |> Tuple.to_list()
    |> Enum.reduce({tests, errors}, fn child, {acc_tests, acc_errors} ->
      collect_modules(child, path, acc_tests, acc_errors)
    end)
  end

  defp collect_modules(nodes, path, tests, errors) when is_list(nodes) do
    Enum.reduce(nodes, {tests, errors}, fn node, {acc_tests, acc_errors} ->
      collect_modules(node, path, acc_tests, acc_errors)
    end)
  end

  defp collect_modules(_node, _path, tests, errors), do: {tests, errors}

  defp scan_module(body, path) do
    nodes = block_nodes(body)

    {module_tags, module_errors} =
      nodes
      |> Enum.filter(&(attribute_kind(&1) == :moduletag))
      |> merge_attributes(path)

    {tests, sequence_errors, _pending} = scan_sequence(nodes, path, module_tags, %{}, [], [])
    {tests, module_errors ++ sequence_errors}
  end

  defp scan_sequence([], _path, _inherited, pending, tests, errors) do
    {tests, errors, pending}
  end

  defp scan_sequence([node | rest], path, inherited, pending, tests, errors) do
    case attribute_kind(node) do
      :tag ->
        case attribute_tags(node) do
          {:ok, tags} ->
            scan_sequence(rest, path, inherited, Map.merge(pending, tags), tests, errors)

          {:error, detail} ->
            error =
              diagnostic(
                "dynamic-exunit-tag",
                path,
                detail,
                "replace the tag with a literal atom or keyword list"
              )

            scan_sequence(rest, path, inherited, pending, tests, errors ++ [error])
        end

      :moduletag ->
        scan_sequence(rest, path, inherited, pending, tests, errors)

      :describetag ->
        scan_sequence(rest, path, inherited, pending, tests, errors)

      nil ->
        cond do
          test_node?(node) ->
            tags = inherited |> Map.merge(pending)
            scan_sequence(rest, path, inherited, %{}, tests ++ [tags], errors)

          describe_node?(node) ->
            body = node |> elem(2) |> List.last() |> Keyword.get(:do)
            describe_nodes = block_nodes(body)

            {describe_tags, describe_errors} =
              describe_nodes
              |> Enum.filter(&(attribute_kind(&1) == :describetag))
              |> merge_attributes(path)

            {nested_tests, nested_errors, _nested_pending} =
              scan_sequence(
                describe_nodes,
                path,
                inherited |> Map.merge(pending) |> Map.merge(describe_tags),
                %{},
                [],
                []
              )

            scan_sequence(
              rest,
              path,
              inherited,
              %{},
              tests ++ nested_tests,
              errors ++ describe_errors ++ nested_errors
            )

          match?({:defmodule, _, _}, node) ->
            {nested_tests, nested_errors} = collect_modules(node, path, [], [])

            scan_sequence(
              rest,
              path,
              inherited,
              pending,
              tests ++ nested_tests,
              errors ++ nested_errors
            )

          generated_test_body = generated_test_body(node) ->
            {nested_tests, nested_errors, _nested_pending} =
              scan_sequence(
                block_nodes(generated_test_body),
                path,
                inherited |> Map.merge(pending),
                %{},
                [],
                []
              )

            scan_sequence(
              rest,
              path,
              inherited,
              %{},
              tests ++ nested_tests,
              errors ++ nested_errors
            )

          true ->
            scan_sequence(rest, path, inherited, pending, tests, errors)
        end
    end
  end

  defp merge_attributes(nodes, path) do
    Enum.reduce(nodes, {%{}, []}, fn node, {tags, errors} ->
      case attribute_tags(node) do
        {:ok, next} ->
          {Map.merge(tags, next), errors}

        {:error, detail} ->
          error =
            diagnostic(
              "dynamic-exunit-tag",
              path,
              detail,
              "replace the tag with a literal atom or keyword list"
            )

          {tags, errors ++ [error]}
      end
    end)
  end

  defp attribute_kind({:@, _, [{kind, _, _}]})
       when kind in [:tag, :moduletag, :describetag],
       do: kind

  defp attribute_kind(_), do: nil

  defp attribute_tags({:@, _, [{kind, _, [value]}]})
       when kind in [:tag, :moduletag, :describetag] do
    cond do
      is_atom(value) ->
        {:ok, %{value => true}}

      is_list(value) and Keyword.keyword?(value) and
          Enum.all?(value, fn {key, tag_value} ->
            is_atom(key) and Macro.quoted_literal?(tag_value)
          end) ->
        {:ok, Map.new(value)}

      true ->
        {:error, "#{kind} must use a literal atom or keyword list"}
    end
  end

  defp attribute_tags(_), do: {:error, "tag attribute has an unsupported executable shape"}

  defp test_node?({:test, _, args}) when is_list(args), do: true
  defp test_node?(_), do: false

  defp describe_node?({:describe, _, args}) when is_list(args) do
    case List.last(args) do
      value when is_list(value) -> Keyword.has_key?(value, :do)
      _ -> false
    end
  end

  defp describe_node?(_), do: false

  defp generated_test_body({kind, _, args}) when kind in [:for, :if, :unless] and is_list(args) do
    case List.last(args) do
      value when is_list(value) -> Keyword.get(value, :do)
      _ -> nil
    end
  end

  defp generated_test_body(_), do: nil

  defp block_nodes({:__block__, _, nodes}), do: nodes
  defp block_nodes(nil), do: []
  defp block_nodes(node), do: [node]

  defp classify(tags) do
    cond do
      Map.get(tags, :requires_example_host) == true -> :requires_example_host
      truthy?(Map.get(tags, :skip)) -> :unowned_skip
      Enum.any?(@default_exclusions, &truthy?(Map.get(tags, &1))) -> :intentional_advisory
      true -> :default_hermetic
    end
  end

  defp truthy?(value), do: value not in [nil, false]

  defp ownership_errors(%{errors: [_ | _]}, _example_lane?), do: []

  defp ownership_errors(%{path: path, classes: classes}, example_lane?) do
    owned? =
      :default_hermetic in classes or
        (:requires_example_host in classes and example_lane?)

    intended? = classes != MapSet.new([:intentional_advisory])

    if owned? or not intended? do
      []
    else
      exclusions =
        classes
        |> Enum.map(&class_label/1)
        |> Enum.sort()
        |> Enum.join(", ")

      [
        diagnostic(
          "unowned-exunit-file",
          path,
          "effective exclusion/class: #{exclusions}",
          "remove/move the exclusion or add the class to a merge-blocking lane"
        )
      ]
    end
  end

  defp class_label(:default_hermetic), do: "default/hermetic"
  defp class_label(:requires_example_host), do: "requires_example_host"
  defp class_label(:intentional_advisory), do: "advisory_only/collateral_binaries/engine_present"
  defp class_label(:unowned_skip), do: "skip"

  defp example_lane_errors(root) do
    path = Path.join(root, @example_workflow)

    with true <- File.regular?(path),
         source <- File.read!(path),
         true <- Regex.match?(~r/^\s*name:\s*#{@example_job}\s*$/m, source),
         true <-
           String.contains?(source, "script/check_example_host_isolation.sh --matrix-only") or
             String.contains?(source, "mix test --only requires_example_host") do
      []
    else
      _ ->
        [
          diagnostic(
            "missing-execution-class",
            @example_workflow,
            "the literal #{@example_job} lane or its executable selector is missing",
            "restore #{@example_job} with the requires_example_host matrix command"
          )
        ]
    end
  end

  defp diagnostic(identifier, path, detail, fix) do
    "[crosswake] FAIL: #{identifier} - #{path}: #{detail}\n" <>
      "[crosswake]   What to do next: #{fix}."
  end

  defp format_parse_error(error, token) do
    [error, token]
    |> Enum.map(fn
      value when is_binary(value) -> value
      value -> inspect(value)
    end)
    |> Enum.join(" ")
  end

  defp fail(errors) do
    errors |> Enum.sort() |> Enum.each(&IO.puts(:stderr, &1))
    1
  end
end

args = System.argv()

root =
  case args do
    [] ->
      "."

    ["--root", value] ->
      value

    _ ->
      IO.puts(:stderr, "usage: elixir script/check_exunit_ownership.exs [--root PATH]")
      System.halt(2)
  end

root
|> Path.expand()
|> Crosswake.ExUnitOwnership.run()
|> System.halt()
