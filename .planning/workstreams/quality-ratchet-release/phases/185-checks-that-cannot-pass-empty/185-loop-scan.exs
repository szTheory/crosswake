# One-off, read-only loop-site scanner (Phase 185, D-07). Phase evidence only; not wired into CI.
# Usage: elixir 185-loop-scan.exs <root> <filelist> --expect <N> [--require <path>:<line>]...
# Raises (non-zero exit) unless the list holds exactly N existing files and every --require site is reported.
defmodule LoopScan do
  @core_funs [:each, :map, :reduce, :flat_map]
  @extra_funs [:all?, :any?, :filter, :reject, :with_index]
  @enum_funs @core_funs ++ @extra_funs
  @assert_names [:assert, :refute, :assert_receive, :refute_receive, :assert_raise, :assert_in_delta]

  def main(argv) do
    {root, list, expect, requires} = parse(argv)
    files = list |> File.read!() |> String.split("\n", trim: true)
    if length(files) != expect, do: raise("expected exactly #{expect} files, got #{length(files)}")

    rows =
      for f <- files do
        path = Path.join(root, f)
        unless File.regular?(path), do: raise("missing file #{f}")
        sites = path |> File.read!() |> Code.string_to_quoted!(columns: false) |> sites([])
        {f, Enum.sort_by(sites, & &1.line)}
      end

    for {f, line} <- requires do
      found = Enum.any?(rows, fn {rf, ss} -> rf == f and Enum.any?(ss, &(&1.line == line)) end)
      unless found, do: raise("required site #{f}:#{line} was not reported")
    end

    total = rows |> Enum.map(fn {_, s} -> length(s) end) |> Enum.sum()

    IO.puts("# Loop-site scan (Phase 185, D-07). Read-only AST scan; no dependency; not wired into CI.")
    IO.puts("# Command: elixir 185-loop-scan.exs <root> <filelist> --expect #{expect}" <> Enum.map_join(requires, "", fn {f, l} -> " --require #{f}:#{l}" end))
    IO.puts("# Files read: #{length(rows)} (expected #{expect}); every file present.")
    IO.puts("# Kinds: for, Enum.each, Enum.reduce, Enum.map, Enum.flat_map whose body holds assert/refute (core);")
    IO.puts("#   Enum.all?/any?/filter/reject/with_index are reported with a trailing * (extra). Piped calls: left side is the source.")
    IO.puts("# Blind spots:")
    IO.puts("#   - assertions made in helpers called from a loop body are not seen;")
    IO.puts("#   - with, Stream and Enum.all?/any? assertion shapes are not treated as loops with a floor;")
    IO.puts("#   - filter-only bodies (no assert/refute inside) are not reported;")
    IO.puts("#   - guards living in helpers or setup blocks are not seen (guard hint is textual, per test/def scope);")
    IO.puts("#   - example-host files are parsed but not run by the main suite.")

    for {f, sites} <- rows do
      IO.puts("#{f}\t#{length(sites)}")
      for s <- sites, do: IO.puts("  L#{s.line}\t#{s.kind}\tsrc=#{s.src_class}\tguard=#{s.guard}\t#{s.src}")
    end

    IO.puts("TOTAL files=#{length(rows)} sites=#{total}")
  end

  defp parse(argv), do: parse(argv, [], nil, [])
  defp parse(["--expect", n | rest], pos, _e, req), do: parse(rest, pos, String.to_integer(n), req)
  defp parse(["--require", spec | rest], pos, e, req) do
    [path, line] = String.split(spec, ":", parts: 2)
    parse(rest, pos, e, req ++ [{path, String.to_integer(line)}])
  end
  defp parse([x | rest], pos, e, req), do: parse(rest, pos ++ [x], e, req)
  defp parse([], [root, list], e, req) when is_integer(e), do: {root, list, e, req}
  defp parse([], _, _, _), do: raise("usage: <root> <filelist> --expect N [--require path:line]")

  defp sites({:__block__, _, stmts}, prior) do
    stmts |> Enum.with_index() |> Enum.flat_map(fn {st, i} -> sites(st, prior ++ Enum.take(stmts, i)) end)
  end

  defp sites({:for, m, args} = node, prior) do
    {gens, body} = split_for(args)

    here =
      if has_assert?(body) do
        enum = gens |> Enum.filter(&match?({:<-, _, _}, &1)) |> Enum.map(fn {:<-, _, [_, e]} -> e end)
        [site("for", m, enum, prior)]
      else
        []
      end

    here ++ children(node, prior)
  end

  # piped Enum call: the left side of the pipe is the enumerable
  defp sites({:|>, _, [lhs, {{:., _, [{:__aliases__, _, [:Enum]}, fun]}, m, args}]}, prior) when fun in @enum_funs do
    here = if Enum.any?(args, &has_assert?/1), do: [site(kind(fun), m, [lhs], prior)], else: []
    here ++ sites(lhs, prior) ++ sites_list(args, prior)
  end

  defp sites({{:., _, [{:__aliases__, _, [:Enum]}, fun]}, m, args} = node, prior) when fun in @enum_funs do
    here = if Enum.any?(args, &has_assert?/1), do: [site(kind(fun), m, Enum.take(args, 1), prior)], else: []
    here ++ children(node, prior)
  end

  defp sites({n, _, args} = node, _prior) when n in [:test, :def, :defp, :setup, :describe, :property] and is_list(args),
    do: children(node, [])

  defp sites(node, prior), do: children(node, prior)

  defp kind(fun) when fun in @core_funs, do: "Enum.#{fun}"
  defp kind(fun), do: "Enum.#{fun}*"

  defp children({a, _, args}, prior) when is_list(args), do: sites_list([a | args], prior)
  defp children({a, b}, prior), do: sites_list([a, b], prior)
  defp children(l, prior) when is_list(l), do: sites_list(l, prior)
  defp children(_, _), do: []
  defp sites_list(l, prior), do: Enum.flat_map(l, &sites(&1, prior))

  defp split_for(args) do
    {opts, gens} =
      case List.last(args) do
        l when is_list(l) -> {l, Enum.drop(args, -1)}
        _ -> {[], args}
      end

    {gens, Keyword.get(opts, :do) || Keyword.get(opts, :reduce) || []}
  end

  defp has_assert?(ast) do
    {_, found} =
      Macro.prewalk(ast, false, fn
        {n, _, a} = node, _ when n in @assert_names and is_list(a) -> {node, true}
        node, acc -> {node, acc}
      end)

    found
  end

  defp site(kind, m, enums, prior) do
    src = enums |> Enum.map(&Macro.to_string/1) |> Enum.join(" ; ") |> String.replace(~r/\s+/, " ") |> String.slice(0, 90)
    %{kind: kind, line: m[:line], src: src, src_class: src_class(enums), guard: guard(enums, prior)}
  end

  defp src_class(enums) do
    cond do
      Enum.all?(enums, &literal?/1) -> :literal
      Enum.all?(enums, &nonempty_list_expr?/1) -> :nonempty_list_expr
      true -> :runtime
    end
  end

  defp nonempty_list_expr?([_ | _]), do: true
  defp nonempty_list_expr?({:++, _, [a, b]}), do: nonempty_list_expr?(a) or nonempty_list_expr?(b)
  defp nonempty_list_expr?({:.., _, _}), do: true
  defp nonempty_list_expr?(_), do: false

  defp literal?(l) when is_list(l), do: Enum.all?(l, &literal?/1)
  defp literal?({:@, _, _}), do: true
  defp literal?({:sigil_w, _, _}), do: true
  defp literal?({:.., _, [a, b]}), do: literal?(a) and literal?(b)
  defp literal?({a, b}), do: literal?(a) and literal?(b)
  defp literal?(x) when is_binary(x) or is_atom(x) or is_number(x), do: true
  defp literal?({:{}, _, l}), do: literal?(l)
  defp literal?(_), do: false

  defp guard(enums, prior) do
    vars = enums |> Enum.flat_map(&vars/1) |> Enum.uniq()

    hit =
      Enum.find(prior, fn st -> has_assert?(st) and card?(st) and Enum.any?(vars, &(&1 in vars(st))) end)

    if hit, do: "candidate:L#{elem(hit, 1)[:line] || "?"}", else: "none"
  end

  defp vars(ast) do
    {_, acc} =
      Macro.prewalk(ast, [], fn
        {n, _, c} = node, a when is_atom(n) and is_atom(c) -> {node, [n | a]}
        node, a -> {node, a}
      end)

    acc
  end

  defp card?(ast) do
    Regex.match?(~r/length\(|Enum\.count|\[_ \| _\]|!= \[\]|empty\?|> 0|Enum\.at|map_size/, Macro.to_string(ast))
  end
end

LoopScan.main(System.argv())
