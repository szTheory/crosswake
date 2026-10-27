defmodule Crosswake.CompileStructure do
  @moduledoc false
  @mix_version "1.19.5"

  def main(args) do
    try do
      {opts, rest, invalid} = OptionParser.parse(args, strict: [root: :string, mode: :string])
      require!(rest == [] and invalid == [], :invalid_arguments)
      mode = Keyword.get(opts, :mode, "enforce")
      require!(mode in ["report", "enforce"], :invalid_arguments)
      root = Path.expand(Keyword.get(opts, :root, "."))
      cap = baseline!()
      Mix.start()
      result = collect(root, cap)

      findings =
        for {key, category} <- [
              compile: "compile_cycle",
              compile_connected: "compile_connected_cycle",
              all: "cycle_limit"
            ],
            result.exits[key] != 0 do
          %{file: hd(result.files), category: category, count: result.counts[key]}
        end

      report = %{
        schema_version: 1,
        guard: "compile",
        scanned_files: result.files,
        counts: %{
          files: length(result.files),
          compile_cycles: result.counts.compile,
          compile_connected_cycles: result.counts.compile_connected,
          all_cycles: result.counts.all
        },
        findings: findings
      }

      IO.puts(
        "compile_structure sources=#{length(result.files)} modules=#{result.modules} manifest_sources=#{result.sources} cap=#{cap}"
      )

      IO.puts(
        "compile_structure compile_exit=#{result.exits.compile} compile_connected_exit=#{result.exits.compile_connected} all_exit=#{result.exits.all}"
      )

      IO.puts("PHASE196_REPORT " <> json(report))
      if findings == [], do: 0, else: 1
    rescue
      # Project configuration and pinned manifest APIs are executable dependency
      # boundaries. Their arbitrary exception data must not become proof output.
      _error ->
        IO.puts("compile_structure refused=operational_failure")
        2
    catch
      {:compile_structure, reason} ->
        IO.puts("compile_structure refused=#{reason}")
        2
    end
  end

  # All graph evidence starts with a successful real force compile. Graph commands
  # cannot silently repair missing or stale manifests because they use --no-compile.
  def collect(root, cap) when is_integer(cap) and cap >= 0 do
    require!(System.version() == @mix_version, :unsupported_mix_version)
    files = discover!(root)
    before = hashes!(root, files)
    require!(command(root, ["compile", "--force", "--warnings-as-errors"]) == 0, :compile_failed)
    require!(hashes!(root, discover!(root)) == before, :source_changed)
    coverage = coverage!(root)

    gates = [
      compile: {"compile", 0},
      compile_connected: {"compile-connected", 0},
      all: {nil, cap}
    ]

    exits = Map.new(gates, fn {key, {label, limit}} -> {key, threshold(root, label, limit)} end)

    counts =
      Map.new(gates, fn {key, {label, _}} -> {key, measure(root, label, length(files))} end)

    require!(coverage!(root) == coverage and hashes!(root, files) == before, :source_changed)
    Map.merge(coverage, %{exits: exits, counts: counts})
  end

  def threshold(root, label, cap) when is_integer(cap) and cap >= 0 do
    args = ["xref", "graph", "--no-compile", "--format", "cycles"]
    args = if label, do: args ++ ["--label", label], else: args
    status = command(root, args ++ ["--fail-above", Integer.to_string(cap)])
    require!(status in [0, 1], :xref_failed)
    status
  end

  # Find the first accepted integer using Mix's threshold exits; no SCC or text
  # interpretation. A successful bound distinguishes threshold failure from an
  # operational exit1, and the source count bounds the number of cycles.
  def measure(root, label, bound) when is_integer(bound) and bound > 0 do
    require!(threshold(root, label, bound) == 0, :xref_failed)
    binary_threshold(root, label, 0, bound)
  end

  defp binary_threshold(_root, _label, n, n), do: n

  defp binary_threshold(root, label, low, high) do
    mid = div(low + high, 2)

    if threshold(root, label, mid) == 0,
      do: binary_threshold(root, label, low, mid),
      else: binary_threshold(root, label, mid + 1, high)
  end

  def coverage!(root) do
    require!(System.version() == @mix_version, :unsupported_mix_version)

    Mix.Project.in_project(:compile_structure_probe, root, fn _ ->
      Mix.env(:test)
      path = Path.join(Mix.Project.manifest_path(), "compile.elixir")
      require!(File.regular?(path), :manifest_missing)
      require!(match?({:ok, _}, File.read(path)), :manifest_unreadable)
      # Pinned internal adapter: Mix 1.19.5 returns maps or {[], []} on failure.
      {modules, sources} = Mix.Compilers.Elixir.read_manifest(path)

      require!(
        is_map(modules) and map_size(modules) > 0 and is_map(sources) and map_size(sources) > 0,
        :manifest_malformed
      )

      expected = discover!(root)
      normalized = Enum.map(sources, fn {file, record} -> {normalize!(root, file), record} end)

      actual =
        normalized
        |> Enum.map(&elem(&1, 0))
        |> Enum.filter(&String.starts_with?(&1, "lib/"))
        |> Enum.sort()

      require!(actual == expected, :source_coverage)

      for {file, record} <- normalized do
        validate_source!(root, file, record, modules)
      end

      for {module, record} <- modules do
        require!(
          is_atom(module) and is_tuple(record) and tuple_size(record) == 6 and
            elem(record, 0) == :module,
          :manifest_malformed
        )

        require!(is_list(elem(record, 2)) and elem(record, 2) != [], :manifest_malformed)
        require!(Enum.all?(elem(record, 2), &Map.has_key?(sources, &1)), :source_coverage)
        beam = Path.join(Mix.Project.compile_path(), Atom.to_string(module) <> ".beam")
        require!(File.regular?(beam), :manifest_stale)
      end

      %{files: expected, modules: map_size(modules), sources: map_size(sources)}
    end)
  end

  defp validate_source!(root, file, record, modules) do
    require!(
      is_tuple(record) and tuple_size(record) == 12 and elem(record, 0) == :source,
      :manifest_malformed
    )

    require!(is_list(elem(record, 11)), :manifest_malformed)
    require!(Enum.all?(elem(record, 11), &Map.has_key?(modules, &1)), :source_coverage)

    bytes =
      case File.read(Path.join(root, file)) do
        {:ok, bytes} -> bytes
        _ -> refuse(:manifest_stale)
      end

    algorithm = if :erlang.system_info(:wordsize) == 8, do: :blake2b, else: :blake2s

    require!(
      byte_size(bytes) == elem(record, 1) and :crypto.hash(algorithm, bytes) == elem(record, 3),
      :manifest_stale
    )
  end

  def discover!(root) do
    files = walk!(Path.join(root, "lib"), root) |> Enum.sort()
    require!(files != [], :scope_empty)

    require!(
      files ==
        Path.wildcard(Path.join(root, "lib/**/*.ex"))
        |> Enum.map(&Path.relative_to(&1, root))
        |> Enum.sort(),
      :source_coverage
    )

    files
  end

  defp walk!(dir, root) do
    entries =
      case File.ls(dir) do
        {:ok, entries} -> entries
        _ -> refuse(:source_read_failed)
      end

    Enum.flat_map(entries, fn entry ->
      path = Path.join(dir, entry)

      case File.lstat(path) do
        {:ok, %{type: :directory}} ->
          walk!(path, root)

        {:ok, %{type: :regular}} ->
          if Path.extname(path) == ".ex", do: [Path.relative_to(path, root)], else: []

        _ ->
          refuse(:source_read_failed)
      end
    end)
  end

  defp normalize!(root, file) when is_binary(file) do
    expanded = Path.expand(file, root)
    relative = Path.relative_to(expanded, root)

    require!(
      Path.type(relative) != :absolute and relative != ".." and
        not String.starts_with?(relative, "../"),
      :source_coverage
    )

    relative
  end

  defp normalize!(_, _), do: refuse(:manifest_malformed)

  defp hashes!(root, files) do
    Map.new(files, fn file ->
      case File.read(Path.join(root, file)) do
        {:ok, bytes} -> {file, :crypto.hash(:sha256, bytes)}
        _ -> refuse(:source_read_failed)
      end
    end)
  end

  defp command(root, args) do
    # Tool output may contain extension exceptions or host paths; only closed
    # status/count diagnostics leave this boundary.
    try do
      {_, status} =
        System.cmd("mix", args, cd: root, env: [{"MIX_ENV", "test"}], stderr_to_stdout: true)

      status
    rescue
      _error in ErlangError -> refuse(:process_unavailable)
    end
  end

  defp baseline! do
    {cap, _} = Code.eval_file(Path.join(__DIR__, "fixtures/compile_cycle_baseline.exs"))
    require!(is_integer(cap) and cap >= 0, :invalid_baseline)
    cap
  end

  defp require!(true, _), do: :ok
  defp require!(_, reason), do: refuse(reason)
  defp refuse(reason), do: throw({:compile_structure, reason})

  # Dependency-free JSON for the fixed report schema; paths are encoded through
  # the OTP JSON encoder so quotes, newlines and non-ASCII names stay data.
  defp json(value), do: value |> json_value() |> :json.encode() |> IO.iodata_to_binary()

  defp json_value(value) when is_map(value),
    do: Map.new(value, fn {k, v} -> {to_string(k), json_value(v)} end)

  defp json_value(value) when is_list(value), do: Enum.map(value, &json_value/1)
  defp json_value(value) when is_atom(value), do: Atom.to_string(value)
  defp json_value(value), do: value
end

if System.get_env("CROSSWAKE_COMPILE_STRUCTURE_LIBRARY") != "1" do
  System.halt(Crosswake.CompileStructure.main(System.argv()))
end
