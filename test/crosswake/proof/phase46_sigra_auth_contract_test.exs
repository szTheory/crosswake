defmodule Crosswake.Proof.Phase46SigraAuthContractTest do
  use ExUnit.Case, async: true

  alias Crosswake.Manifest

  defmodule AuthPredicatedRouter do
    use Crosswake.Router

    scope "/" do
      crosswake_defaults runtime: :live_view, offline: :unavailable, security: :standard do
        live "/secure", Crosswake.TestSupport.StudySessionLive,
          crosswake: [
            id: "secure",
            runtime: :live_view,
            auth_min_level: :mfa,
            requires_recent_auth: 600
          ]
      end
    end
  end

  defmodule NonAuthRouter do
    use Crosswake.Router

    scope "/" do
      crosswake_defaults runtime: :live_view, offline: :unavailable, security: :standard do
        live "/plain", Crosswake.TestSupport.StudySessionLive,
          crosswake: [id: "plain", runtime: :live_view]
      end
    end
  end

  test "manifest route entries carry auth predicates when declared" do
    assert {:ok, %{manifest: manifest}} = Manifest.compile(AuthPredicatedRouter)
    route = manifest.routes["secure"]
    route_map = Crosswake.Manifest.Types.to_map(route)

    assert route_map["auth_min_level"] == "mfa"
    assert route_map["requires_recent_auth"] == 600
  end

  test "manifest route entries omit auth predicates when undeclared" do
    assert {:ok, %{manifest: manifest}} = Manifest.compile(NonAuthRouter)
    route = manifest.routes["plain"]
    route_map = Crosswake.Manifest.Types.to_map(route)

    refute Map.has_key?(route_map, "auth_min_level")
    refute Map.has_key?(route_map, "requires_recent_auth")
  end

  test "phase 46 auth contract proof stays hermetic" do
    source = File.read!(__ENV__.file) |> String.downcase()

    refute String.contains?(source, "crosswake" <> "example.router")
    refute Regex.match?(~r/code\.require_file\s*\(/, source)
  end
end
