defmodule Crosswake.RuntimeDependencies do
  @moduledoc false
  @roster [
    {"mix.exs", "crosswake"},
    {"packages/crosswake_chimeway/mix.exs", "crosswake_chimeway"},
    {"packages/crosswake_rindle/mix.exs", "crosswake_rindle"},
    {"packages/crosswake_rulestead/mix.exs", "crosswake_rulestead"},
    {"packages/crosswake_sigra/mix.exs", "crosswake_sigra"},
    {"packages/crosswake_threadline/mix.exs", "crosswake_threadline"}
  ]

  def main(args) do
    {opts, rest, invalid} =
      OptionParser.parse(args, strict: [root: :string, mode: :string, baseline: :string])

    if rest != [] or invalid != [] or
         Keyword.get(opts, :mode, "report") not in ["report", "enforce"] do
      IO.puts("runtime_dependencies refused=invalid_arguments")
      2
    else
      root = Path.expand(Keyword.get(opts, :root, "."))

      baseline =
        Keyword.get(
          opts,
          :baseline,
          Path.join(__DIR__, "fixtures/runtime_dependency_baseline.exs")
        )

      {report, executions} = scan(root, baseline)
      IO.puts("PHASE196_REPORT " <> json(report))
      IO.puts("RUNTIME_DEPENDENCY_EXECUTIONS " <> json(executions))
      if report.findings == [], do: 0, else: 1
    end
  end

  def scan(root, baseline) do
    {files, discovery_errors} = discover(root)
    {entries, baseline_errors} = baseline(baseline)
    expected = Enum.map(@roster, &elem(&1, 0))
    roster_errors = if files == expected, do: [], else: [finding("mix.exs", "project_roster")]

    {executions, evaluation_errors} =
      if roster_errors == [] and discovery_errors == [] do
        Enum.reduce(@roster, {[], []}, fn {file, app}, acc ->
          Enum.reduce(["local", "release"], acc, fn branch, {executions, errors} ->
            case evaluate(root, file, app, branch) do
              {:ok, result} -> {executions ++ [Map.put(result, "file", file)], errors}
              :error -> {executions, errors ++ [finding(file, "guard_failure")]}
            end
          end)
        end)
      else
        {[], []}
      end

    identities = Enum.map(executions, & &1["execution_id"])
    ids_unique = length(Enum.uniq(identities)) == length(identities)
    identity_errors = if ids_unique, do: [], else: [finding("mix.exs", "guard_failure")]

    differences =
      if baseline_errors == [] do
        Enum.flat_map(executions, fn execution ->
          compare(execution, Map.fetch!(entries, execution["file"]))
        end)
      else
        []
      end

    findings =
      discovery_errors ++
        roster_errors ++ baseline_errors ++ evaluation_errors ++ identity_errors ++ differences

    declarations = Enum.flat_map(executions, & &1["declarations"])

    report = %{
      schema_version: 1,
      guard: "dependencies",
      scanned_files: files,
      counts: %{
        files: length(files),
        projects: length(files),
        branches: 2,
        executions: length(executions),
        declarations: length(declarations),
        dependencies: Enum.count(declarations, &retained?/1)
      },
      findings: findings
    }

    {report, executions}
  end

  defp discover(root) do
    with {:ok, %{type: :regular}} <- File.lstat(Path.join(root, "mix.exs")),
         {:ok, %{type: :directory}} <- File.lstat(Path.join(root, "packages")),
         {:ok, names} <- File.ls(Path.join(root, "packages")) do
      Enum.reduce(Enum.sort(names), {["mix.exs"], []}, fn name, {files, errors} ->
        if String.starts_with?(name, "crosswake_") do
          directory = Path.join([root, "packages", name])
          file = "packages/#{name}/mix.exs"

          case {File.lstat(directory), File.lstat(Path.join(root, file))} do
            {{:ok, %{type: :directory}}, {:ok, %{type: :regular}}} -> {files ++ [file], errors}
            {{:ok, %{type: :directory}}, {:error, :enoent}} -> {files, errors}
            _ -> {files, errors ++ [finding("packages", "project_roster")]}
          end
        else
          {files, errors}
        end
      end)
    else
      _ -> {[], [finding("mix.exs", "project_roster")]}
    end
  end

  defp baseline(path) do
    try do
      # Parse only literal data; a baseline cannot execute code to accept itself.
      ast = path |> File.read!() |> Code.string_to_quoted!()
      true = Macro.quoted_literal?(ast)
      {rows, []} = Code.eval_quoted(ast, [])
      true = is_list(rows)
      true = Enum.map(rows, fn {file, app, _} -> {file, app} end) == @roster

      entries =
        Map.new(rows, fn {file, _app, deps} ->
          true = is_list(deps) and deps != []

          names =
            Enum.map(deps, fn {name, optional, purpose} ->
              true = is_binary(name) and Regex.match?(~r/\A[a-z][a-z0-9_]*\z/, name)
              true = is_boolean(optional)

              true =
                is_binary(purpose) and String.trim(purpose) != "" and
                  not String.contains?(purpose, ["\n", "\r"])

              name
            end)

          true = names == Enum.sort(Enum.uniq(names))
          {file, deps}
        end)

      {entries, []}
    rescue
      _error -> {%{}, [finding("mix.exs", "missing_justification")]}
    end
  end

  defp evaluate(root, file, app, branch) do
    try do
      {output, code} =
        System.cmd(
          "elixir",
          [
            Path.join(__DIR__, "evaluate_runtime_dependencies.exs"),
            Path.dirname(Path.join(root, file)),
            branch
          ],
          cd: Path.dirname(Path.join(root, file)),
          stderr_to_stdout: true,
          env: [
            {"MIX_ENV", "prod"},
            {"CROSSWAKE_RELEASE", if(branch == "release", do: "1", else: nil)},
            {"ERL_FLAGS", "+S 2:2"}
          ]
        )

      [line] =
        String.split(output, "\n")
        |> Enum.filter(&String.starts_with?(&1, "RUNTIME_DEPENDENCY_PROJECT "))

      result = line |> String.replace_prefix("RUNTIME_DEPENDENCY_PROJECT ", "") |> :json.decode()

      true =
        code == 0 and result["app"] == app and result["branch"] == branch and
          result["environment"] == "prod"

      true =
        Map.keys(result) |> Enum.sort() ==
          ~w(app branch declarations environment execution_id process_id)

      true =
        is_binary(result["execution_id"]) and
          Regex.match?(~r/\A[0-9a-f]{32}\z/, result["execution_id"])

      true =
        is_binary(result["process_id"]) and Regex.match?(~r/\A[0-9]+\z/, result["process_id"])

      true = is_list(result["declarations"]) and result["declarations"] != []
      true = Enum.all?(result["declarations"], &valid_declaration?/1)
      names = Enum.map(result["declarations"], & &1["name"])
      true = names == Enum.sort(Enum.uniq(names))
      {:ok, result}
    rescue
      _error -> :error
    end
  end

  defp valid_declaration?(row) when is_map(row) do
    Enum.sort(Map.keys(row)) == ~w(name optional production runtime) and
      is_binary(row["name"]) and Regex.match?(~r/\A[a-z][a-z0-9_]*\z/, row["name"]) and
      Enum.all?(~w(optional production runtime), &is_boolean(row[&1]))
  end

  defp valid_declaration?(_), do: false
  defp retained?(row), do: row["production"] and row["runtime"]

  defp compare(execution, expected) do
    rows = Map.new(execution["declarations"], &{&1["name"], &1})
    retained = Enum.filter(execution["declarations"], &retained?/1)
    expected_names = Enum.map(expected, &elem(&1, 0))

    added =
      for row <- retained,
          row["name"] not in expected_names,
          do: finding(execution["file"], "dependency_added")

    changed =
      Enum.flat_map(expected, fn {name, optional, _purpose} ->
        case Map.get(rows, name) do
          nil ->
            [finding(execution["file"], "dependency_removed")]

          row ->
            if retained?(row) and row["optional"] == optional,
              do: [],
              else: [finding(execution["file"], "dependency_classification")]
        end
      end)

    added ++ changed
  end

  defp finding(file, category), do: %{file: file, category: category, count: 1}
  defp json(value), do: value |> stringify_keys() |> :json.encode() |> IO.iodata_to_binary()

  defp stringify_keys(map) when is_map(map),
    do: Map.new(map, fn {key, value} -> {to_string(key), stringify_keys(value)} end)

  defp stringify_keys(list) when is_list(list), do: Enum.map(list, &stringify_keys/1)
  defp stringify_keys(value), do: value
end

System.halt(Crosswake.RuntimeDependencies.main(System.argv()))
