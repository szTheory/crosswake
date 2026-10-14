defmodule Crosswake.Shell.IOSHostGeneration do
  @moduledoc false

  alias Crosswake.Manifest
  alias Crosswake.Shell.Activation
  alias Crosswake.Shell.IOSHostConfig

  def render(%IOSHostConfig{} = config, opts \\ []) do
    compile_opts =
      [origin: config.origin] ++
        if(is_binary(Keyword.get(opts, :generated_at)),
          do: [generated_at: Keyword.fetch!(opts, :generated_at)],
          else: []
        )

    with {:ok, %{manifest: manifest}} <- Manifest.compile(config.router, compile_opts),
         :ok <- entry_exists(manifest, config.entry_route_id) do
      entry = Map.fetch!(manifest.routes, config.entry_route_id)

      activation =
        Activation.new_request(
          route_id: config.entry_route_id,
          url: config.origin <> entry.path,
          source: :cold_start,
          origin: config.origin,
          manifest_source: :bundled,
          bridge_protocol_version: Crosswake.Bridge.Contract.version(),
          native_runtime_version: "1.0.0",
          capabilities: entry_host_commands(manifest, config.entry_route_id),
          correlation_id: "ios-build-entry"
        )

      manifest_bytes = Manifest.render(manifest)
      activation_bytes = Jason.encode!(Activation.to_map(activation), pretty: true) <> "\n"
      settings_bytes = render_settings(config)

      {
        :ok,
        %{
          manifest: manifest_bytes,
          activation: activation_bytes,
          settings: settings_bytes,
          managed_outputs: %{
            "Fixtures/crosswake_manifest.json" => manifest_bytes,
            "Fixtures/route_activation.json" => activation_bytes,
            "CrosswakeHostSettings.xcconfig" => settings_bytes
          }
        }
      }
    else
      {:error, reason} when is_binary(reason) ->
        {:error, reason}

      {:error, _diagnostic} ->
        {:error, "router policy could not be compiled; repair the declared route policy"}
    end
  end

  @doc false
  # D-07: the entry activation carries only the entry route's own host commands,
  # read from the compiled manifest entry (built by Builder.host_commands_for/2).
  # No config, no route id literal, no other route is consulted.
  def entry_host_commands(manifest, entry_route_id) do
    Map.fetch!(manifest.routes, entry_route_id).host_commands
  end

  defp entry_exists(manifest, route_id) do
    if Map.has_key?(manifest.routes, route_id),
      do: :ok,
      else: {:error, "invalid entry_route_id; select a route declared by the configured router"}
  end

  defp render_settings(config) do
    signing = config.device_signing

    template =
      Application.app_dir(
        :crosswake,
        "priv/templates/crosswake/shell/ios/CrosswakeHostSettings.xcconfig.eex"
      )

    EEx.eval_file(template,
      assigns: [
        app_bundle_id: config.app_bundle_id,
        code_sign_style: if(signing.mode == :automatic, do: "Automatic", else: "Manual"),
        team_id: signing.team_id
      ]
    )
  end
end
