defmodule Crosswake.ProofLane.ConfigTest do
  use ExUnit.Case, async: true

  alias Crosswake.ProofLane.Config

  @valid %{
    route_id: "route-0123456789abcdef",
    route_path: "/study/:id",
    indexed_db_database: "proof_lane",
    indexed_db_store: "mutations",
    mutation_id_path: "client_mutation_id",
    sync_path: "/study/sync",
    evidence_path: "/_proof/evidence",
    router: CrosswakeWeb.Router,
    ios_shell_root: "/tmp/crosswake-proof-lane/native/ios"
  }

  test "normalizes exactly the nine supported keys" do
    assert {:ok, %Config{} = config} = Config.normalize(@valid)
    assert Map.keys(Map.from_struct(config)) |> Enum.sort() == Map.keys(@valid) |> Enum.sort()
  end

  test "rejects unknown, missing, duplicate, and non-atom keys without echoing input" do
    secret = "credential-bearing-value-must-not-echo"

    for input <- [
          Map.put(@valid, :unexpected, secret),
          Map.delete(@valid, :route_id),
          Keyword.merge(Map.to_list(@valid), route_id: "route-fedcba9876543210"),
          Map.put(@valid, "route_id", secret)
        ] do
      assert {:error, error} = Config.normalize(input)
      assert error.rule_id =~ "PL-CONFIG-"
      refute Exception.message(error) =~ secret
      refute inspect(error) =~ secret
    end
  end

  test "rejects unsafe or incorrectly typed values with a stable canonical key" do
    cases = [
      {:route_id, "route-ABC"},
      {:route_path, "/study/../secret"},
      {:indexed_db_database, 123},
      {:indexed_db_store, "bad/name"},
      {:mutation_id_path, "client_mutation_id.__proto__"},
      {:sync_path, "https://host.invalid/secret?token=leak"},
      {:evidence_path, "/proof#token=leak"},
      {:router, "CrosswakeWeb.Router"},
      {:ios_shell_root, "/tmp/crosswake/../outside"}
    ]

    Enum.each(cases, fn {key, value} ->
      assert {:error, %{key: returned_key, rule_id: rule_id} = error} =
               Config.normalize(Map.put(@valid, key, value))

      assert returned_key == Atom.to_string(key)
      assert rule_id =~ "PL-CONFIG-"
      refute Exception.message(error) =~ to_string(value)
    end)
  end

  test "accepts only declarative safe mutation field segments" do
    assert {:ok, _} = Config.normalize(Map.put(@valid, :mutation_id_path, "record.client_mutation_id"))
    assert {:error, _} = Config.normalize(Map.put(@valid, :mutation_id_path, "record[mutation_id]"))
  end
end
