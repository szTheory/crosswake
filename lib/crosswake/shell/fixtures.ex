defmodule Crosswake.Shell.Fixtures do
  @moduledoc """
  Canonical bundled shell fixtures derived from manifest truth, shared activation
  contracts, and stable denial vocabulary.
  """

  alias Crosswake.Manifest
  alias Crosswake.Manifest.Types
  alias Crosswake.Shell.Activation
  alias Crosswake.Shell.Denial
  alias Crosswake.SupportMatrix

  @declared_pack_requirements %{"shell.chrome" => "1.0.0"}
  @installed_packs %{"shell.chrome" => "1.0.0"}
  @capabilities %{"app.info.get" => "1.0.0"}

  @spec export(String.t()) :: %{optional(String.t()) => String.t()}
  def export(platform) when platform in ["ios", "android"] do
    fixture_root = fixture_root(platform)

    %{
      Path.join(fixture_root, "crosswake_manifest.json") => manifest_json(),
      Path.join(fixture_root, "route_activation.json") => activation_json(platform),
      Path.join(fixture_root, "route_denial.json") => denial_json(),
      Path.join(fixture_root, "declared_pack_requirements.json") =>
        json!(@declared_pack_requirements),
      Path.join(fixture_root, "installed_packs.json") => json!(@installed_packs)
    }
  end

  @spec manifest() :: Types.Root.t()
  def manifest do
    Types.new_root(
      crosswake_version: Mix.Project.config()[:version] || "dev",
      generated_at: "2026-05-15T00:00:00Z",
      host: Types.new_host(),
      compatibility: Types.new_compatibility(),
      support_matrix: SupportMatrix.canonical(),
      capability_registry: %{
        "app.info.get" => Types.new_capability(id: "app.info.get", version: "1.0.0")
      },
      routes: %{
        "dashboard" =>
          Types.new_route_entry(
            id: "dashboard",
            path: "/dashboard",
            runtime: :live_view,
            offline: :unavailable,
            capabilities: ["app.info.get"],
            packs: ["shell.chrome@1.0.0"],
            allowlisted_origins: [Types.default_origin()]
          )
      }
    )
  end

  defp activation_json(platform) do
    platform
    |> activation_request()
    |> Activation.to_map()
    |> json!()
  end

  defp activation_request(platform) do
    Activation.new_request(
      route_id: "dashboard",
      url: "#{Types.default_origin()}/dashboard",
      source: if(platform == "android", do: :deep_link, else: :cold_start),
      manifest_source: :bundled,
      bridge_protocol_version: "1.0.0",
      native_runtime_version: "1.0.0",
      correlation_id: "#{platform}-bootstrap-1",
      declared_pack_requirements: @declared_pack_requirements,
      installed_packs: @installed_packs,
      capabilities: @capabilities
    )
  end

  defp denial_json do
    Denial.new(
      reason: :pack_incompatible,
      route_id: "dashboard",
      message: "The shell is missing a compatible declared pack for this route.",
      hint: "ship the required compatible shell pack before activating the route",
      details: %{
        required_pack: "shell.chrome@1.0.0",
        installed_packs: @installed_packs
      },
      recovery: %{
        actions: ["retry", "update_app"],
        mode: "fail_closed"
      }
    )
    |> Denial.to_map()
    |> json!()
  end

  defp manifest_json do
    manifest()
    |> Manifest.render()
  end

  defp fixture_root("ios"), do: "Fixtures"
  defp fixture_root("android"), do: "assets"

  defp json!(value),
    do: Jason.encode_to_iodata!(value, pretty: true) |> IO.iodata_to_binary() |> Kernel.<>("\n")
end
