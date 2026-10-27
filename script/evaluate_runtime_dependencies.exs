# One fresh VM evaluates one project and one branch. No dependency task is run.
defmodule Crosswake.DependencyEvaluator do
  @moduledoc false

  def main([project, branch]) when branch in ["local", "release"] do
    try do
      true = System.get_env("MIX_ENV") == "prod"
      true = System.get_env("CROSSWAKE_RELEASE") == if(branch == "release", do: "1", else: nil)
      Mix.start()
      Mix.env(:prod)
      Code.compile_file(Path.join(project, "mix.exs"))
      config = Mix.Project.config()
      app = Keyword.fetch!(config, :app) |> name!()
      declarations = Keyword.fetch!(config, :deps)
      true = is_list(declarations) and declarations != []
      normalized = Enum.map(declarations, &normalize!/1) |> Enum.sort_by(& &1["name"])
      true = length(Enum.uniq_by(normalized, & &1["name"])) == length(normalized)

      result = %{
        "app" => app,
        "branch" => branch,
        "environment" => Atom.to_string(Mix.env()),
        "execution_id" => Base.encode16(:crypto.strong_rand_bytes(16), case: :lower),
        "process_id" => System.pid(),
        "declarations" => normalized
      }

      IO.puts("RUNTIME_DEPENDENCY_PROJECT " <> IO.iodata_to_binary(:json.encode(result)))
      0
    rescue
      _error ->
        IO.puts("runtime_dependencies refused=project_evaluation")
        2
    catch
      _kind, _reason ->
        IO.puts("runtime_dependencies refused=project_evaluation")
        2
    end
  end

  def main(_), do: 2

  defp normalize!({app, opts}) when is_list(opts), do: normalized!(app, opts)
  defp normalize!({app, requirement}) when is_binary(requirement), do: normalized!(app, [])
  defp normalize!({app, %Regex{}}), do: normalized!(app, [])

  defp normalize!({app, requirement, opts})
       when (is_binary(requirement) or is_struct(requirement, Regex)) and is_list(opts),
       do: normalized!(app, opts)

  defp normalized!(app, opts) do
    true = Keyword.keyword?(opts)
    true = length(Keyword.keys(opts)) == length(Enum.uniq(Keyword.keys(opts)))
    runtime = Keyword.get(opts, :runtime, true)
    optional = Keyword.get(opts, :optional, false)
    true = is_boolean(runtime) and is_boolean(optional)
    only = Keyword.get(opts, :only, [:prod]) |> List.wrap()
    true = Enum.all?(only, &is_atom/1)

    %{
      "name" => name!(app),
      "production" => :prod in only,
      "runtime" => runtime,
      "optional" => optional
    }
  end

  defp name!(app) when is_atom(app) do
    name = Atom.to_string(app)
    true = Regex.match?(~r/\A[a-z][a-z0-9_]*\z/, name)
    name
  end
end

System.halt(Crosswake.DependencyEvaluator.main(System.argv()))
