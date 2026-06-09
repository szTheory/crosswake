defmodule Mix.Tasks.Crosswake.Gen.Sync do
  use Mix.Task

  @shortdoc "Generates host-owned sync components (Ecto schema and Phoenix controller)"

  @switches [dir: :string, app: :string]

  @impl Mix.Task
  def run(args) do
    {opts, _argv, invalid} = OptionParser.parse(args, strict: @switches)

    if invalid != [] do
      Mix.raise("invalid options: #{inspect(invalid)}")
    end

    app_module = opts[:app] || get_app_module()
    app_snake = Macro.underscore(app_module)

    dir = Path.expand(opts[:dir] || File.cwd!())

    schema_dest = Path.join([dir, "lib", app_snake, "sync", "event_log.ex"])
    controller_dest = Path.join([dir, "lib", "#{app_snake}_web", "controllers", "sync_controller.ex"])

    schema_template = Application.app_dir(:crosswake, "priv/templates/crosswake/sync/event_log.ex.eex")
    controller_template = Application.app_dir(:crosswake, "priv/templates/crosswake/sync/sync_controller.ex.eex")

    # If running from source (e.g. in development), Application.app_dir might fail for priv if not compiled,
    # but Mix generators usually run in an environment where priv is available, or we can fallback to local path.
    schema_template = if File.exists?(schema_template), do: schema_template, else: Path.join(File.cwd!(), "priv/templates/crosswake/sync/event_log.ex.eex")
    controller_template = if File.exists?(controller_template), do: controller_template, else: Path.join(File.cwd!(), "priv/templates/crosswake/sync/sync_controller.ex.eex")

    schema_content = EEx.eval_file(schema_template, app_module: app_module)
    controller_content = EEx.eval_file(controller_template, app_module: app_module)

    ensure_file(schema_dest, schema_content)
    ensure_file(controller_dest, controller_content)

    Mix.shell().info("""
    Sync components generated successfully!

    Next steps:
    1. Add the EventLog schema to your Ecto Repo's migrations:
       mix ecto.gen.migration create_crosswake_sync_event_logs
       
       Use the generated fields and unique_index(:crosswake_sync_event_logs, [:idempotency_key])

    2. Mount the generated SyncController in your router:
       post "/sync/replay", #{app_module}Web.SyncController, :replay
    """)
  end

  defp get_app_module do
    case Mix.Project.config()[:app] do
      nil -> "MyApp"
      app -> app |> to_string() |> Macro.camelize()
    end
  end

  defp ensure_file(path, contents) do
    File.mkdir_p!(Path.dirname(path))

    case File.read(path) do
      {:ok, _existing} ->
        Mix.shell().info("  reused #{Path.relative_to_cwd(path)}")
        :reused

      {:error, :enoent} ->
        File.write!(path, contents)
        Mix.shell().info("  created #{Path.relative_to_cwd(path)}")
        :created

      {:error, reason} ->
        Mix.raise("could not create #{path}: #{:file.format_error(reason)}")
    end
  end
end
