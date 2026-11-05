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
    %{read: &File.read/1, exists?: &File.exists?/1, run: &system_run/2, scan: & &1}
  end

  @doc "The single subprocess seam: `{:ok, out}` or `{:error, reason_atom}`, never stderr text."
  def system_run(cmd, args) do
    case System.cmd(cmd, args, stderr_to_stdout: true) do
      {out, 0} -> {:ok, out}
      {_discarded, _status} -> {:error, :exit_status}
    end
  rescue
    ErlangError -> {:error, :missing_binary}
    _ -> {:error, :exception}
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

    render(
      [{:unverified, "docs.warnings UNVERIFIED reason=not_measured"}] ++
        links_lines ++ leaks_lines
    )
  end

  @doc "Joins counter lines, appends the report-only banner and derives the exit code."
  def render([]), do: {2, ["docs.report UNVERIFIED reason=not_measured", @only]}

  def render(lines) do
    code = if Enum.any?(lines, &match?({:unverified, _}, &1)), do: 2, else: 0
    {code, Enum.map(lines, fn {_kind, text} -> text end) ++ [@only]}
  end

  defp unverified(counter, reason), do: {:unverified, "#{counter} UNVERIFIED reason=#{reason}"}

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

  # --- links: filled by the link counter -------------------------------------------------

  defp links(_scope, _detail?), do: [{:unverified, "docs.links UNVERIFIED reason=not_measured"}]

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
