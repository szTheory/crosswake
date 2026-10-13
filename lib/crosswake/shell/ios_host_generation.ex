defmodule Crosswake.Shell.IOSHostGeneration do
  @moduledoc false

  alias Crosswake.Manifest
  alias Crosswake.Shell.Activation
  alias Crosswake.Shell.IOSHostConfig

  def render(%IOSHostConfig{} = config) do
    with {:ok, %{manifest: manifest}} <- Manifest.compile(config.router, origin: config.origin),
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
          correlation_id: "ios-build-entry"
        )

      {
        :ok,
        %{
          manifest: Manifest.render(manifest),
          activation: Jason.encode!(Activation.to_map(activation), pretty: true) <> "\n",
          settings: render_settings(config)
        }
      }
    else
      {:error, reason} when is_binary(reason) ->
        {:error, reason}

      {:error, _diagnostic} ->
        {:error, "router policy could not be compiled; repair the declared route policy"}
    end
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
