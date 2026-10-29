defmodule Crosswake.AbsenceCollectionAST do
  @moduledoc false
  @projects ~w(chimeway rindle rulestead sigra threadline)

  # This is a bounded lexical analysis, not an evaluator. Facts never escape a
  # branch/closure, and a binding invalidates every fact containing that name.
  def analyze(source, file) do
    case Code.string_to_quoted(source) do
      {:ok, ast} ->
        state = %{
          file: file,
          context: [],
          attrs: %{},
          safe: MapSet.new(),
          glob: MapSet.new(),
          findings: []
        }

        {_, state} = visit(ast, state)

        state.findings
        |> Enum.frequencies()
        |> Enum.sort()
        |> Enum.map(fn {id, count} -> Map.put(id, :count, count) end)

      {:error, _} ->
        [
          %{
            file: file,
            category: "parse_error",
            context: "source",
            expression: "unparseable",
            count: 1
          }
        ]
    end
  end

  def normalize(ast),
    do:
      ast
      |> Macro.prewalk(fn
        {a, m, b} when is_list(m) -> {a, [], b}
        x -> x
      end)
      |> inspect(limit: :infinity, printable_limit: :infinity)

  defp key(ast), do: normalize(ast)
  defp fact(ast, s), do: MapSet.member?(s.safe, key(ast)) or literal?(ast, s.attrs)
  defp literal?([_ | _], _), do: true
  defp literal?({:@, _, [{name, _, _}]}, attrs), do: Map.get(attrs, name, false)
  defp literal?(_, _), do: false

  defp glob?(ast, s) do
    {_, found} =
      Macro.prewalk(ast, false, fn node, acc ->
        {node,
         acc or MapSet.member?(s.glob, key(node)) or
           match?({{:., _, [{:__aliases__, _, [:Path]}, :wildcard]}, _, _}, node)}
      end)

    found
  end

  defp add(s, category, expression) do
    id = %{
      file: s.file,
      context: Enum.join(s.context, "/"),
      category: category,
      expression: :crypto.hash(:sha256, key(expression)) |> Base.encode16(case: :lower)
    }

    %{s | findings: [id | s.findings]}
  end

  defp scoped(ast, s, context \\ nil) do
    child = if context, do: %{s | context: s.context ++ [context]}, else: s
    {_, child} = visit(ast, child)
    {ast, %{s | findings: child.findings}}
  end

  defp visit({:quote, _, _} = ast, s), do: {ast, s}

  defp visit({:defmodule, _, [name, body]} = ast, s) do
    scoped(Keyword.get(body, :do), %{s | attrs: %{}}, "module " <> Macro.to_string(name))
    |> then(fn {_, child} -> {ast, %{s | findings: child.findings}} end)
  end

  defp visit({kind, _, [head, body]} = ast, s)
       when kind in [:def, :defp, :defmacro, :defmacrop] do
    scoped(
      body,
      %{s | safe: MapSet.new(), glob: MapSet.new()},
      Atom.to_string(kind) <> " " <> Macro.to_string(head)
    )
    |> then(fn {_, child} -> {ast, %{s | findings: child.findings}} end)
  end

  defp visit({kind, _, [name | args]} = ast, s) when kind in [:test, :property, :describe] do
    scoped(args, s, Atom.to_string(kind) <> " " <> Macro.to_string(name))
    |> then(fn {_, child} -> {ast, %{s | findings: child.findings}} end)
  end

  defp visit({:@, _, [{name, _, [value]}]} = ast, s),
    do: {ast, %{s | attrs: Map.put(s.attrs, name, literal?(value, s.attrs))}}

  defp visit({:=, _, [lhs, rhs]} = ast, s) do
    {_, s} = visit(rhs, s)
    safe = fact(rhs, s)
    glob = glob?(rhs, s)
    vars = variables(lhs)
    s = %{s | safe: invalidate(s.safe, vars), glob: invalidate(s.glob, vars)}
    s = if safe, do: %{s | safe: MapSet.put(s.safe, key(lhs))}, else: s
    s = if glob, do: %{s | glob: MapSet.put(s.glob, key(lhs))}, else: s
    {ast, s}
  end

  defp visit({:__block__, _, nodes} = ast, s),
    do: {ast, Enum.reduce(nodes, s, fn node, st -> elem(visit(node, st), 1) end)}

  defp visit({:->, _, [patterns, body]} = ast, s) do
    names = variables(patterns)
    local = %{s | safe: invalidate(s.safe, names), glob: invalidate(s.glob, names)}
    {_, child} = scoped(body, local)
    {ast, %{s | findings: child.findings}}
  end

  defp visit({:with, _, args} = ast, s) do
    names =
      Enum.flat_map(args, fn
        {:<-, _, [pattern, _]} -> variables(pattern)
        _ -> []
      end)

    local = %{s | safe: invalidate(s.safe, names), glob: invalidate(s.glob, names)}
    {_, child} = scoped(args, local)
    {ast, %{s | findings: child.findings}}
  end

  defp visit({kind, _, args} = ast, s)
       when kind in [:if, :unless, :case, :cond, :try, :receive, :fn] do
    # Each branch starts with only facts established before the branch.
    {ast,
     Enum.reduce(args, s, fn branch, acc ->
       {_, child} = scoped(branch, s)
       %{acc | findings: child.findings ++ (acc.findings -- s.findings)}
     end)}
  end

  defp visit({:for, _, args} = ast, s) do
    generators = Enum.filter(args, &match?({:<-, _, _}, &1))

    s =
      Enum.reduce(generators, s, fn {:<-, _, [_, collection]}, st ->
        if glob?(collection, s) and not fact(collection, s),
          do: add(st, "glob_without_count", ast),
          else: st
      end)

    names = Enum.flat_map(generators, fn {:<-, _, [pattern, _]} -> variables(pattern) end)
    local = %{s | safe: invalidate(s.safe, names), glob: invalidate(s.glob, names)}
    {_, child} = scoped(args, local)
    {ast, %{s | findings: child.findings}}
  end

  defp visit({kind, _, [expr | _]} = ast, s) when kind in [:assert, :refute] do
    s = if kind == :assert and expr == true, do: add(s, "literal_true", ast), else: s

    s =
      case universal(expr, kind) do
        nil -> s
        collection -> if fact(collection, s), do: s, else: add(s, "unsafe_collection", ast)
      end

    # Analyze nested closures for their own assertions, without borrowing facts
    # from them. A positive assertion becomes evidence only for later siblings.
    {_, s} = visit(expr, s)

    s =
      case positive(expr, kind) do
        nil -> s
        collection -> %{s | safe: MapSet.put(s.safe, key(collection))}
      end

    {ast, s}
  end

  defp visit(list, s) when is_list(list) do
    {list, Enum.reduce(list, s, fn node, st -> elem(visit(node, st), 1) end)}
  end

  defp visit({a, b}, s) do
    # Keyword branch bodies are independent; do/else must never share facts.
    if a in [:do, :else, :rescue, :catch, :after], do: scoped(b, s), else: visit([a, b], s)
  end

  defp visit({_name, _meta, args} = ast, s) when is_list(args), do: {ast, elem(visit(args, s), 1)}
  defp visit(ast, s), do: {ast, s}

  defp universal({{:., _, [{:__aliases__, _, [:Enum]}, fun]}, _, [collection | _]}, kind)
       when (fun == :all? and kind == :assert) or (fun == :any? and kind == :refute),
       do: collection

  defp universal({:|>, _, [collection, {{:., _, [{:__aliases__, _, [:Enum]}, fun]}, _, _}]}, kind)
       when (fun == :all? and kind == :assert) or (fun == :any? and kind == :refute),
       do: collection

  defp universal(_, _), do: nil
  defp positive({op, _, [collection, []]}, :assert) when op in [:!=, :!==], do: collection
  defp positive({op, _, [collection, []]}, :refute) when op in [:==, :===], do: collection
  defp positive({:=, _, [[_ | _], collection]}, :assert), do: collection

  defp positive({op, _, [count, n]}, :assert) when is_integer(n) do
    if (op in [:>, :!=, :!==] and n == 0) or (op in [:>=, :==, :===] and n > 0),
      do: counted(count),
      else: nil
  end

  defp positive(_, _), do: nil
  defp counted({:length, _, [collection]}), do: collection
  defp counted({{:., _, [{:__aliases__, _, [:Enum]}, :count]}, _, [collection]}), do: collection
  defp counted(_), do: nil

  defp variables(ast) do
    {_, vars} =
      Macro.prewalk(ast, [], fn
        {name, _, context} = node, acc
        when is_atom(name) and (is_atom(context) or is_nil(context)) ->
          {node, [Atom.to_string(name) | acc]}

        node, acc ->
          {node, acc}
      end)

    vars
  end

  defp invalidate(facts, vars),
    do:
      MapSet.reject(facts, fn text ->
        Enum.any?(vars, &Regex.match?(~r/\b#{Regex.escape(&1)}\b/, text))
      end)

  def scan(root, opts) do
    scopes = ["test" | Enum.map(@projects, &"packages/crosswake_#{&1}/test")]

    results =
      Enum.map(scopes, fn base ->
        actual =
          Path.wildcard(Path.join(root, base <> "/**/*.exs"))
          |> Enum.filter(&File.regular?/1)
          |> Enum.sort()

        expected =
          walk(Path.join(root, base))
          |> Enum.filter(&String.ends_with?(&1, ".exs"))
          |> Enum.sort()

        min = if base == "test", do: Keyword.get(opts, :min_test_files, 253), else: 1

        errors =
          cond do
            expected == [] -> [error(base <> "/test_helper.exs", "scope_empty")]
            actual != expected -> [error(Path.relative_to(hd(expected), root), "scope_mismatch")]
            length(actual) < min -> [error(Path.relative_to(hd(actual), root), "scope_mismatch")]
            true -> []
          end

        {actual, errors}
      end)

    files = results |> Enum.flat_map(&elem(&1, 0)) |> Enum.uniq() |> Enum.sort()
    errors = Enum.flat_map(results, &elem(&1, 1))

    findings =
      Enum.flat_map(files, fn path ->
        file = Path.relative_to(path, root)

        with {:ok, stat} <- File.stat(path),
             true <- Bitwise.band(stat.mode, 0o444) != 0,
             {:ok, source} <- File.read(path) do
          analyze(source, file)
        else
          _ -> [error(file, "read_error")]
        end
      end)

    {files, Enum.sort_by(errors ++ findings, &{&1.file, &1.context, &1.expression, &1.category})}
  end

  defp error(file, category),
    do: %{file: file, category: category, context: "source", expression: category, count: 1}

  defp walk(dir) do
    case File.ls(dir) do
      {:ok, names} ->
        Enum.flat_map(names, fn name ->
          path = Path.join(dir, name)

          case File.lstat(path) do
            {:ok, %{type: :directory}} -> walk(path)
            {:ok, %{type: :regular}} -> [path]
            _ -> [path]
          end
        end)

      _ ->
        []
    end
  end

  def delta(findings, baseline) do
    actual = Map.new(findings, &{Map.drop(&1, [:count]), &1.count})
    expected = Map.new(baseline, &{Map.drop(&1, [:count, :reason]), &1.count})

    valid =
      Enum.all?(baseline, fn entry ->
        is_integer(entry.count) and entry.count > 0 and is_binary(entry.reason) and
          entry.reason != ""
      end) and map_size(expected) == length(baseline)

    changes =
      for id <-
            Enum.sort_by(
              Enum.uniq(Map.keys(actual) ++ Map.keys(expected)),
              &{&1.file, &1.context, &1.expression, &1.category}
            ),
          Map.get(actual, id, 0) != Map.get(expected, id, 0) do
        {if(Map.get(actual, id, 0) > Map.get(expected, id, 0),
           do: "new_or_increased",
           else: "stale_baseline"
         ), id, Map.get(actual, id, 0), Map.get(expected, id, 0)}
      end

    {valid, changes}
  end

  # Standalone Elixir has no project dependencies in the actual-main capsule.
  def json(value) when is_map(value),
    do:
      "{" <>
        Enum.map_join(Enum.sort(value), ",", fn {k, v} -> json(to_string(k)) <> ":" <> json(v) end) <>
        "}"

  def json(value) when is_list(value), do: "[" <> Enum.map_join(value, ",", &json/1) <> "]"
  def json(value) when is_integer(value), do: Integer.to_string(value)

  def json(value) when is_binary(value),
    do:
      "\"" <>
        (value
         |> String.replace("\\", "\\\\")
         |> String.replace("\"", "\\\"")
         |> String.replace("\n", "\\n")
         |> String.replace("\r", "\\r")
         |> String.replace("\t", "\\t")) <> "\""
end
