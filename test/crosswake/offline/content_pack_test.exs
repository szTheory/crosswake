defmodule Crosswake.Offline.ContentPackTest do
  use ExUnit.Case, async: true
  alias Crosswake.Offline.ContentPack

  describe "struct definition" do
    test "successfully creates ContentPack given valid keys" do
      pack = %ContentPack{
        id: "data_core",
        version: "1.0.0",
        kind: :content,
        integrity: %{"sha256" => "hash123"},
        assets: ["/css/app.css"],
        data_payloads: ["/api/offline/pack_v1"]
      }

      assert pack.id == "data_core"
      assert pack.version == "1.0.0"
      assert pack.kind == :content
      assert pack.integrity == %{"sha256" => "hash123"}
      assert pack.assets == ["/css/app.css"]
      assert pack.data_payloads == ["/api/offline/pack_v1"]
    end

    test "enforces required keys :id, :version, :kind" do
      assert_raise ArgumentError, fn ->
        struct!(ContentPack, %{})
      end
    end

    test "json encodes correctly matching expected keys" do
      pack = %ContentPack{
        id: "data_core",
        version: "1.0.0",
        kind: :content,
        integrity: %{"sha256" => "hash123"},
        assets: ["/css/app.css"],
        data_payloads: ["/api/offline/pack_v1"]
      }

      json = Jason.encode!(pack)
      decoded = Jason.decode!(json)

      assert decoded["id"] == "data_core"
      assert decoded["version"] == "1.0.0"
      assert decoded["kind"] == "content"
      assert decoded["integrity"] == %{"sha256" => "hash123"}
      assert decoded["assets"] == ["/css/app.css"]
      assert decoded["data_payloads"] == ["/api/offline/pack_v1"]
    end
  end
end
