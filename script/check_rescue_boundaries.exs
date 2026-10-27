defmodule Crosswake.RescueBoundaries do
  @moduledoc false
  @families ~w(bridge policy router offline manifest compatibility)
  @boundary_file "lib/crosswake/compatibility/route_gate.ex"

  def main(args) do
    {opts, rest, invalid} =
      OptionParser.parse(args, strict: [root: :string, mode: :string, exceptions: :string])

    if rest != [] or invalid != [] or
         Keyword.get(opts, :mode, "report") not in ["report", "enforce"] do
      IO.puts("rescue_boundaries refused=invalid_arguments")
      2
    else
      root = Path.expand(Keyword.get(opts, :root, "."))

      records =
        Keyword.get(
          opts,
          :exceptions,
          Path.join(__DIR__, "fixtures/rescue_boundary_exceptions.exs")
        )

      report = scan(root, records)

      IO.puts(
        "rescue_boundaries files=#{report.counts.files} rescues=#{report.counts.rescues} exceptions=#{report.counts.exceptions} findings=#{length(report.findings)}"
      )

      IO.puts(
        "PHASE196_REPORT " <> (report |> json_value() |> :json.encode() |> IO.iodata_to_binary())
      )

      if report.findings == [], do: 0, else: 1
    end
  end

  def scan(root, records_path) do
    {independent, discovery_errors} = walk(root, "lib/crosswake")
    files = Enum.filter(independent, &subject?/1) |> Enum.sort()

    globbed =
      Enum.flat_map(@families, fn family ->
        base = "lib/crosswake/#{family}"

        Enum.filter([base <> ".ex"], &File.exists?(Path.join(root, &1))) ++
          (Path.wildcard(Path.join(root, base <> "/**/*.ex"), match_dot: true)
           |> Enum.map(&Path.relative_to(&1, root)))
      end)
      |> Enum.sort()

    scope_errors =
      cond do
        files == [] ->
          [finding("lib/crosswake", "scope_empty")]

        files != globbed ->
          [finding("lib/crosswake", "scope_mismatch")]

        true ->
          for family <- @families,
              not Enum.any?(files, &family?(&1, family)),
              do: finding("lib/crosswake/#{family}", "scope_mismatch")
      end

    {records, record_errors} = records(records_path)

    {sites, parse_errors} =
      Enum.reduce(files, {[], []}, fn file, {sites, errors} ->
        case read_ast(Path.join(root, file)) do
          {:ok, ast} -> {sites ++ visit(ast, %{file: file, module: nil, function: nil}), errors}
          {:error, reason} -> {sites, errors ++ [finding(file, reason)]}
        end
      end)

    broad = Enum.filter(sites, &(&1.kind == :broad))
    matches = for site <- broad, record <- records, matches?(site, record), do: {site, record}

    unmatched =
      Enum.filter(sites, fn site ->
        site.kind == :wildcard or
          (site.kind == :broad and Enum.count(matches, fn {s, _} -> s == site end) != 1)
      end)

    stale =
      Enum.filter(records, fn record -> Enum.count(matches, fn {_, r} -> r == record end) != 1 end)

    findings =
      discovery_errors ++
        scope_errors ++
        record_errors ++
        parse_errors ++
        Enum.map(unmatched, &finding(&1.file, "broad_rescue")) ++
        Enum.map(stale, fn _ -> finding(@boundary_file, "rescue_exception_mismatch") end)

    %{
      schema_version: 1,
      guard: "rescue",
      scanned_files: files,
      counts: %{files: length(files), rescues: length(sites), exceptions: length(matches)},
      findings: findings
    }
  end

  defp subject?(file), do: Enum.any?(@families, &family?(file, &1))

  defp family?(file, family),
    do:
      file == "lib/crosswake/#{family}.ex" or
        (String.starts_with?(file, "lib/crosswake/#{family}/") and String.ends_with?(file, ".ex"))

  defp walk(root, relative) do
    case File.ls(Path.join(root, relative)) do
      {:ok, names} ->
        Enum.reduce(Enum.sort(names), {[], []}, fn name, {files, errors} ->
          child = Path.join(relative, name)

          case File.lstat(Path.join(root, child)) do
            {:ok, %{type: :directory}} ->
              {nested, failures} = walk(root, child)
              {files ++ nested, errors ++ failures}

            {:ok, %{type: :regular}} ->
              {files ++ [child], errors}

            _ ->
              {files, errors ++ [finding(child, "read_error")]}
          end
        end)

      {:error, _} ->
        {[], [finding(relative, "read_error")]}
    end
  end

  defp read_ast(path) do
    with {:ok, %{type: :regular}} <- File.lstat(path), {:ok, bytes} <- File.read(path) do
      case Code.string_to_quoted(bytes) do
        {:ok, ast} -> {:ok, ast}
        {:error, _} -> {:error, "parse_error"}
      end
    else
      _ -> {:error, "read_error"}
    end
  rescue
    _error in [ArgumentError, UnicodeConversionError] -> {:error, "parse_error"}
  end

  defp records(path) do
    with {:ok, ast} <- read_ast(path),
         true <- Macro.quoted_literal?(ast),
         {records, []} <- Code.eval_quoted(ast),
         true <- is_list(records),
         true <- length(records) == 2,
         true <- Enum.all?(records, &valid_record?/1),
         true <- length(Enum.uniq(records)) == 2 do
      {Enum.map(records, &Map.update!(&1, :clause, fn clause -> normalize_clause(clause) end)),
       []}
    else
      _ -> {[], [finding(@boundary_file, "rescue_exception_mismatch")]}
    end
  end

  defp valid_record?(record) when is_map(record) do
    Enum.sort(Map.keys(record)) == [:call, :clause, :file, :function, :module] and
      Enum.all?(Map.values(record), &(is_binary(&1) and String.trim(&1) != "")) and
      record.file == "lib/crosswake/compatibility/route_gate.ex" and
      record.module == "Crosswake.Compatibility.RouteGate" and
      {record.function, record.call} in [
        {"check_dependencies/2", "companion.validate_dependency()"},
        {"prepend_auth_evaluation_denials/4",
         "authority.evaluate_auth(route, auth_context, opts)"}
      ] and normalize_clause(record.clause) != :invalid
  end

  defp valid_record?(_), do: false

  defp normalize_clause(source) do
    case Code.string_to_quoted("fn " <> source <> " end") do
      {:ok, {:fn, _, [clause]}} -> normalized(clause)
      _ -> :invalid
    end
  end

  defp visit({:defmodule, _, [{:__aliases__, _, names}, body]}, context) do
    name = Enum.map_join(names, ".", &Atom.to_string/1)

    module =
      if context.module && not String.starts_with?(name, context.module <> "."),
        do: context.module <> "." <> name,
        else: name

    visit(body, %{context | module: module})
  end

  defp visit({kind, _, [head, body]}, context)
       when kind in [:def, :defp, :defmacro, :defmacrop] do
    {name, args} = function_head(head)
    visit(body, %{context | function: "#{name}/#{length(args)}"})
  end

  defp visit(list, context) when is_list(list) do
    # Both implicit function rescues and explicit try blocks use this keyword shape.
    if Keyword.keyword?(list) and Keyword.has_key?(list, :rescue) do
      protected = calls(Keyword.get(list, :do))

      sites =
        for {:->, _, [[pattern], body]} = clause <- Keyword.fetch!(list, :rescue) do
          Map.merge(context, %{
            kind: rescue_kind(pattern, body),
            clause: normalized(clause),
            calls: protected
          })
        end

      sites ++
        Enum.flat_map(Keyword.delete(list, :rescue), &visit(&1, context)) ++
        Enum.flat_map(Keyword.fetch!(list, :rescue), fn {:->, _, [_, body]} ->
          visit(body, context)
        end)
    else
      Enum.flat_map(list, &visit(&1, context))
    end
  end

  defp visit(tuple, context) when is_tuple(tuple),
    do: tuple |> Tuple.to_list() |> Enum.flat_map(&visit(&1, context))

  defp visit(_, _), do: []

  defp function_head({:when, _, [head | _]}), do: function_head(head)
  defp function_head({name, _, args}) when is_atom(name), do: {name, args || []}
  defp function_head({name, _, args}), do: {normalized(name), args || []}
  defp rescue_kind({:_, _, _}, _), do: :wildcard
  defp rescue_kind({:__aliases__, _, _}, _), do: :finite

  defp rescue_kind({:in, _, [_variable, classes]}, _) when is_list(classes) and classes != [] do
    if Enum.all?(classes, &match?({:__aliases__, _, _}, &1)), do: :finite, else: :broad
  end

  defp rescue_kind(
         {name, _, context},
         {:reraise, _, [{name, _, context}, {:__STACKTRACE__, _, _}]}
       )
       when is_atom(name), do: :reraise

  defp rescue_kind(_, _), do: :broad

  defp calls(ast) do
    {_, calls} =
      Macro.prewalk(ast, [], fn
        {{:., _, [_receiver, _name]}, _, args} = node, acc when is_list(args) ->
          {node, [normalized(node) | acc]}

        node, acc ->
          {node, acc}
      end)

    calls
  end

  defp matches?(site, record),
    do:
      site.file == record.file and site.module == record.module and
        site.function == record.function and site.clause == record.clause and
        record.call in site.calls

  defp normalized(ast),
    do:
      ast
      |> Macro.prewalk(fn
        {name, metadata, args} when is_list(metadata) -> {name, [], args}
        node -> node
      end)
      |> Macro.to_string()

  defp finding(file, category), do: %{file: file, category: category, count: 1}

  defp json_value(map) when is_map(map),
    do: Map.new(map, fn {k, v} -> {to_string(k), json_value(v)} end)

  defp json_value(list) when is_list(list), do: Enum.map(list, &json_value/1)
  defp json_value(atom) when is_atom(atom), do: Atom.to_string(atom)
  defp json_value(value), do: value
end

if System.get_env("CROSSWAKE_RESCUE_BOUNDARIES_LIBRARY") != "1" do
  System.halt(Crosswake.RescueBoundaries.main(System.argv()))
end
