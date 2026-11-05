#!/usr/bin/env elixir

# Report-only public docs checker: how many internal-planning leaks and broken relative
# links sit in the files ExDoc ships (the `extras:` list in mix.exs).
#
# Absence is never success: a read that failed, an empty scope, or a scan that touched
# fewer files than the parsed extras is UNVERIFIED, never a clean zero. This is not a
# required check and is not referenced by any workflow; the fixture-based ExUnit file is
# its only CI exposure.
#
# Exit codes: 0 it ran, 2 UNVERIFIED (which wins). Never 1.
# Output carries fixed reason atoms only; exception text and file contents are never
# printed, except `--detail` lines taken from the shipped public docs themselves.
defmodule Crosswake.DocsReport do
  @allowlist_path "script/docs_leak_allowlist.json"
  @usage "usage: script/docs-report [--root DIR] [--detail]"
  @only "docs-report: REPORT-ONLY (not a required check)"

  def main(argv) do
    {opts, _rest, invalid} =
      OptionParser.parse(argv, strict: [root: :string, detail: :boolean, help: :boolean])

    cond do
      opts[:help] ->
        IO.puts(@usage)
        0

      invalid != [] ->
        IO.puts(@usage)
        2

      true ->
        {code, lines} = run(Keyword.get(opts, :root, File.cwd!()), deps(), detail: opts[:detail])
        Enum.each(lines, &IO.puts/1)
        code
    end
  end

  @doc "The default external seams: reads, existence, subprocesses, and the scan scope."
  def deps do
    %{read: &File.read/1, exists?: &File.exists?/1, run: &system_run/3, scan: & &1}
  end

  @doc "The single subprocess seam: `{output, exit_status}`; a missing binary is `{\"\", 127}`."
  def system_run(cmd, args, opts) do
    System.cmd(cmd, args, opts)
  rescue
    _ -> {"", 127}
  end

  @doc "Runs every counter over `root`; returns `{exit_code, lines}`."
  def run(root, deps, opts \\ []) do
    detail? = Keyword.get(opts, :detail, false) == true
    root = Path.expand(root)

    {links_lines, leaks_lines} =
      case scope(root, deps) do
        {:error, reason} ->
          {[unverified("docs.links", reason)], [unverified("docs.leaks", reason)]}

        {:ok, scope} ->
          {links(scope, detail?), leaks(root, scope, deps, detail?)}
      end

    render(warnings(root, deps, detail?) ++ links_lines ++ leaks_lines)
  end

  @doc "Joins counter lines, appends the report-only banner and derives the exit code."
  def render([]), do: {2, ["docs.report UNVERIFIED reason=not_measured", @only]}

  def render(lines) do
    code = if Enum.any?(lines, &match?({:unverified, _}, &1)), do: 2, else: 0
    {code, Enum.map(lines, fn {_kind, text} -> text end) ++ [@only]}
  end

  defp unverified(counter, reason), do: {:unverified, "#{counter} UNVERIFIED reason=#{reason}"}

  # --- warnings: `mix docs` in the dev env (ex_doc is a dev-only dependency) ------------------

  @doc """
  Runs `mix docs` through the `run` seam and counts its `warning:` blocks; returns report
  lines. Never passes `--warnings-as-errors`. A non-zero exit or a missing `doc/index.html`
  is UNVERIFIED, never `total=0`: a docs build that did not produce docs measured nothing.
  """
  def warnings(root, deps, detail?) do
    with {:ok, extras} <- extras(root, deps),
         {output, 0} <- deps.run.("mix", ["docs"], docs_opts(root)),
         true <- deps.exists?.(Path.join([root, "doc", "index.html"])) do
      hits = warning_locations(output)
      total = length(hits)
      in_extras = Enum.filter(hits, &(&1 in extras))

      summary = {:ok, "docs.warnings total=#{total} extras=#{length(in_extras)}"}

      detail =
        if detail? do
          for file <- in_extras, do: {:ok, "docs.warnings.hit file=#{file}"}
        else
          []
        end

      [summary | detail]
    else
      {:error, reason} -> [unverified("docs.warnings", reason)]
      {_output, _status} -> [unverified("docs.warnings", :mix_docs_failed)]
      false -> [unverified("docs.warnings", :no_doc_index)]
    end
  end

  defp docs_opts(root), do: [cd: root, env: [{"MIX_ENV", "dev"}], stderr_to_stdout: true]

  # One entry per `warning:` line: the file named by its location line (`└─ <file>:<n>`, the
  # first such line before the next warning), or `nil` when the block names none. ExDoc 0.40
  # prints the location as `└─ guides/x.md:44: (file)` or `└─ (pkg 1.2.3) lib/x.ex:28: Mod.fun/3`.
  defp warning_locations(output) do
    output
    |> String.split("\n")
    |> Enum.chunk_while(
      nil,
      fn line, current ->
        if warning_line?(line),
          do: {:cont, current, [line]},
          else: {:cont, current && [line | current]}
      end,
      fn
        nil -> {:cont, nil}
        current -> {:cont, current, nil}
      end
    )
    |> Enum.reject(&is_nil/1)
    |> Enum.map(&block_file/1)
  end

  defp warning_line?(line), do: line |> String.trim_leading() |> String.starts_with?("warning:")

  defp block_file(reversed_block) do
    reversed_block
    |> Enum.reverse()
    |> tl()
    |> Enum.find_value(fn line ->
      case Regex.run(~r/^\s*└─\s.*?([^\s()]+):[0-9]+/u, line, capture: :all_but_first) do
        [file] -> file
        _ -> nil
      end
    end)
  end

  # --- scope: the `.md` files listed in mix.exs `extras:` ---------------------------------

  @doc "Parses the `extras:` list inside `docs/0` of `<root>/mix.exs` without evaluating it."
  def extras(root, deps) do
    with {:ok, source} <- deps.read.(Path.join(root, "mix.exs")),
         {:ok, ast} <- Code.string_to_quoted(source),
         [_ | _] = list <- docs_extras(ast) do
      {:ok, list}
    else
      _ -> {:error, :no_extras}
    end
  end

  defp docs_extras(ast) do
    {_, bodies} =
      Macro.prewalk(ast, [], fn
        {kind, _, [{:docs, _, args}, body]} = node, acc
        when kind in [:def, :defp] and args in [nil, []] ->
          {node, [body | acc]}

        node, acc ->
          {node, acc}
      end)

    bodies |> Enum.reverse() |> Enum.find_value([], &keyword_extras/1)
  end

  defp keyword_extras(body) do
    {_, found} =
      Macro.prewalk(body, nil, fn
        {:extras, list} = node, nil when is_list(list) ->
          if Enum.all?(list, &is_binary/1), do: {node, list}, else: {node, nil}

        node, acc ->
          {node, acc}
      end)

    found
  end

  # Returns `{:ok, %{root:, extras:, files: [{relative, stripped_contents}]}}` or
  # `{:error, reason}`. Every listed `.md` file must be read, and the scanned list must not
  # be shorter than the parsed one.
  defp scope(root, deps) do
    with {:ok, extras} <- extras(root, deps),
         [_ | _] = md <- Enum.filter(extras, &String.ends_with?(&1, ".md")),
         scanned = deps.scan.(md),
         :ok <- scan_floor(md, scanned),
         {:ok, files} <- read_all(root, scanned, deps) do
      {:ok, %{root: root, extras: extras, files: files}}
    else
      {:error, reason} -> {:error, reason}
      _ -> {:error, :no_extras}
    end
  end

  defp scan_floor(md, scanned) do
    if length(scanned) < length(md), do: {:error, :scan_floor}, else: :ok
  end

  defp read_all(root, scanned, deps) do
    Enum.reduce_while(scanned, {:ok, []}, fn file, {:ok, acc} ->
      case deps.read.(Path.join(root, file)) do
        {:ok, contents} -> {:cont, {:ok, [{file, strip_fences(contents)} | acc]}}
        _ -> {:halt, {:error, :unreadable_extra}}
      end
    end)
    |> case do
      {:ok, files} -> {:ok, Enum.reverse(files)}
      error -> error
    end
  end

  # Replace fenced-code lines with an empty string, tracking open/closed state across lines
  # that begin with three backticks (same state machine as
  # script/check_release_doc_version_literals.exs): a command example in a fenced block is
  # a reproduction, not a claim the document makes.
  defp strip_fences(contents) do
    {stripped, _} =
      contents
      |> String.split("\n")
      |> Enum.map_reduce(false, fn line, inside? ->
        fence? = line |> String.trim_leading() |> String.starts_with?("```")

        cond do
          fence? -> {"", not inside?}
          inside? -> {"", inside?}
          true -> {line, inside?}
        end
      end)

    Enum.join(stripped, "\n")
  end

  # --- links: relative `.md` links and `#anchors` over the shipped extras ---------------------

  @doc "Counts broken relative links over the scoped files; returns report lines."
  def links(scope, detail?) do
    slugs = Map.new(scope.files, fn {file, text} -> {file, heading_slugs(text)} end)
    extras = MapSet.new(scope.extras)

    results =
      for {file, text} <- scope.files,
          target <- link_targets(text),
          result = check_link(target, file, scope, extras, slugs),
          result != :skip,
          do: {file, target, result}

    broken = for {file, target, :broken} <- results, do: {file, target}

    summary =
      {:ok,
       "docs.links broken=#{length(broken)} checked=#{length(results)} " <>
         "files=#{length(scope.files)}"}

    detail =
      if detail? do
        for {file, target} <- broken, do: {:ok, "docs.links.broken file=#{file} target=#{target}"}
      else
        []
      end

    [summary | detail]
  end

  defp link_targets(text) do
    ~r/\]\(([^)\s]+)(?:\s+"[^"]*")?\)/
    |> Regex.scan(text, capture: :all_but_first)
    |> List.flatten()
  end

  # `:skip` (not a checked link), `:ok` or `:broken`.
  defp check_link(target, file, scope, extras, slugs) do
    if Regex.match?(~r/^[a-zA-Z][a-zA-Z0-9+.\-]*:/, target) do
      :skip
    else
      {path, anchor} = split_anchor(target)
      check_path(path, anchor, file, scope, extras, slugs)
    end
  end

  defp split_anchor(target) do
    case String.split(target, "#", parts: 2) do
      [path, anchor] -> {path, anchor}
      [path] -> {path, nil}
    end
  end

  defp check_path("", nil, _file, _scope, _extras, _slugs), do: :skip
  defp check_path("", "", _file, _scope, _extras, _slugs), do: :skip

  defp check_path("", anchor, file, _scope, _extras, slugs),
    do: if(MapSet.member?(slugs[file], anchor), do: :ok, else: :broken)

  defp check_path(path, anchor, file, scope, extras, slugs) do
    relative = resolve(scope.root, file, path)

    cond do
      not (String.ends_with?(path, ".md") or unshipped_root?(relative)) -> :skip
      not MapSet.member?(extras, relative) -> :broken
      anchor in [nil, ""] -> :ok
      MapSet.member?(Map.get(slugs, relative, MapSet.new()), anchor) -> :ok
      true -> :broken
    end
  end

  defp resolve(root, file, path) do
    path
    |> Path.expand(Path.dirname(Path.join(root, file)))
    |> Path.relative_to(root)
  end

  defp unshipped_root?(relative),
    do: String.starts_with?(relative, "lib/") or String.starts_with?(relative, ".planning/")

  # GitHub heading-slug rule: lowercase, drop everything but letters, digits, spaces, hyphens
  # and underscores, spaces to hyphens, duplicate slugs suffixed -1, -2 in document order.
  # ExDoc's own slugger differs in places; those differences are recorded, not reconciled.
  defp heading_slugs(text) do
    text
    |> String.split("\n")
    |> Enum.flat_map(fn line ->
      case Regex.run(~r/^ {0,3}[#]{1,6}[ \t]+(.+?)[ \t]*$/, line, capture: :all_but_first) do
        [heading] -> [heading |> String.replace(~r/[ \t]+[#]+$/, "") |> slug_base()]
        _ -> []
      end
    end)
    |> Enum.map_reduce(%{}, fn slug, seen ->
      n = Map.get(seen, slug, 0)
      {if(n == 0, do: slug, else: "#{slug}-#{n}"), Map.put(seen, slug, n + 1)}
    end)
    |> elem(0)
    |> MapSet.new()
  end

  defp slug_base(heading) do
    heading
    |> then(&Regex.replace(~r/!?\[([^\]]*)\]\([^)]*\)/, &1, "\\1"))
    |> String.replace(["`", "*"], "")
    |> then(&Regex.replace(~r/(?<![\p{L}\p{N}])_(.+?)_(?![\p{L}\p{N}])/u, &1, "\\1"))
    |> String.downcase()
    |> then(&Regex.replace(~r/[^\p{L}\p{N} _-]/u, &1, ""))
    |> String.replace(" ", "-")
  end

  # --- leaks ---------------------------------------------------------------------------------

  defp semver, do: ~r/\b\d+\.\d+\.\d+\b/

  defp patterns do
    [
      {"phase", ~r/\bPhase [0-9]+/},
      {"todo", ~r/\bTODO-[0-9]+/},
      {"decision", ~r/\bD-[0-9]{2}/},
      {"seed", ~r/\bSEED-[0-9]+/},
      {"milestone", ~r/\bv[12][0-9](\.[0-9]+)?\b/}
    ]
  end

  @doc "Counts leaks over the scoped files; returns report lines."
  def leaks(root, scope, deps, detail?) do
    case load_allowlist(root, deps) do
      {:error, reason} ->
        [unverified("docs.leaks", reason)]

      {:ok, entries} ->
        hits = Enum.flat_map(scope.files, fn {file, text} -> file_hits(file, text) end)
        {kept, allowlisted, stale} = apply_allowlist(hits, entries)

        summary =
          {:ok,
           "docs.leaks hits=#{length(kept)} allowlisted=#{allowlisted} " <>
             "stale_allowlist=#{stale} files=#{length(scope.files)}"}

        detail =
          if detail? do
            for {file, pattern, text} <- kept,
                do: {:ok, "docs.leaks.hit file=#{file} pattern=#{pattern} text=#{text}"}
          else
            []
          end

        [summary | detail]
    end
  end

  defp file_hits(file, contents) do
    contents
    |> String.split("\n")
    |> Enum.flat_map(fn line ->
      blanked =
        Regex.replace(semver(), line, fn match -> String.duplicate(" ", String.length(match)) end)

      Enum.flat_map(patterns(), fn {label, regex} ->
        count = length(Regex.scan(regex, blanked))
        List.duplicate({file, label, normalize(line)}, count)
      end)
    end)
  end

  defp normalize(line), do: line |> String.split() |> Enum.join(" ")

  defp apply_allowlist(hits, entries) do
    matches = fn {file, _pattern, text}, entry ->
      entry["file"] == file and entry["text"] == text
    end

    kept = Enum.reject(hits, fn hit -> Enum.any?(entries, &matches.(hit, &1)) end)
    stale = Enum.count(entries, fn entry -> not Enum.any?(hits, &matches.(&1, entry)) end)
    {kept, length(hits) - length(kept), stale}
  end

  defp load_allowlist(root, deps) do
    path = Path.join(root, @allowlist_path)

    with true <- deps.exists?.(path),
         {:ok, body} <- deps.read.(path),
         {:ok, decoded} <- JSON.decode(body) do
      validate_allowlist(decoded)
    else
      _ -> {:error, :allowlist_unreadable}
    end
  end

  defp validate_allowlist(%{"schema_version" => 1, "entries" => entries})
       when is_list(entries) do
    if Enum.all?(entries, &valid_entry?/1),
      do: {:ok, entries},
      else: {:error, :allowlist_invalid}
  end

  defp validate_allowlist(_other), do: {:error, :allowlist_invalid}

  defp valid_entry?(%{"file" => file, "text" => text, "reason" => reason} = entry)
       when map_size(entry) == 3,
       do: Enum.all?([file, text, reason], &(is_binary(&1) and &1 != ""))

  defp valid_entry?(_other), do: false
end

unless Process.get(:crosswake_docs_report_library),
  do: System.halt(Crosswake.DocsReport.main(System.argv()))
