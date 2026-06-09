defmodule Mix.Tasks.Crosswake.Gen.Audit do
  use Mix.Task

  @shortdoc "Generates host-owned audit ledger components (Ecto schema and migration)"

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

    schema_dest = Path.join([dir, "lib", app_snake, "audit", "ledger.ex"])

    schema_template = Application.app_dir(:crosswake, "priv/templates/crosswake/audit/ledger.ex.eex")
    migration_template = Application.app_dir(:crosswake, "priv/templates/crosswake/audit/migration.exs.eex")

    schema_template = if File.exists?(schema_template), do: schema_template, else: Path.join(File.cwd!(), "priv/templates/crosswake/audit/ledger.ex.eex")
    migration_template = if File.exists?(migration_template), do: migration_template, else: Path.join(File.cwd!(), "priv/templates/crosswake/audit/migration.exs.eex")

    schema_content = EEx.eval_file(schema_template, app_module: app_module)
    migration_content = EEx.eval_file(migration_template, app_module: app_module)

    ensure_file(schema_dest, schema_content)
    
    # Ensure migrations directory exists
    migrations_dir = Path.join([dir, "priv", "repo", "migrations"])
    File.mkdir_p!(migrations_dir)
    
    # Check if migration exists
    existing_migration = Enum.find(File.ls!(migrations_dir), fn file ->
      String.ends_with?(file, "_create_crosswake_audit_events.exs")
    end)
    
    if existing_migration do
      Mix.shell().info("  reused #{Path.join(["priv", "repo", "migrations", existing_migration])}")
    else
      timestamp = Calendar.strftime(DateTime.utc_now(), "%Y%m%d%H%M%S")
      filename = "#{timestamp}_create_crosswake_audit_events.exs"
      migration_dest = Path.join(migrations_dir, filename)
      
      File.write!(migration_dest, migration_content)
      Mix.shell().info("  created #{Path.relative_to_cwd(migration_dest)}")
    end

    Mix.shell().info("""
    Audit ledger components generated successfully!

    Next steps:
    1. Run your migrations:
       mix ecto.migrate
       
    2. Start recording audit events in your multi transactions:
       Ecto.Multi.new()
       |> #{app_module}.Audit.Ledger.record_in_multi(:audit_event, %{...})
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
