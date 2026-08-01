defmodule Crosswake.ProofLane.ConfigTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

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

  test "accepts only a normalized non-root native/ios shell root" do
    root =
      Path.join(
        System.tmp_dir!(),
        "crosswake-proof-lane-config-#{System.unique_integer([:positive])}"
      )

    ios_shell_root = Path.join(root, "native/ios")

    assert {:ok, config} = Config.normalize(Map.put(@valid, :ios_shell_root, ios_shell_root))
    assert {:ok, ^root} = Config.host_root(config)

    unsafe_roots = [
      "/tmp/not-the-native-ios-root",
      "/native/ios",
      Path.join(ios_shell_root, "generated"),
      Path.join(root, "not-native/ios"),
      Path.join(root, "native/ios/.."),
      Path.join(root, "native//ios"),
      ios_shell_root <> "/",
      "native/ios"
    ]

    Enum.each(unsafe_roots, fn unsafe_root ->
      assert {:error, %{rule_id: "PL-CONFIG-VALUE", key: "ios_shell_root"} = error} =
               Config.normalize(Map.put(@valid, :ios_shell_root, unsafe_root))

      assert Exception.message(error) ==
               "PL-CONFIG-VALUE: ios_shell_root; use the documented local proof-lane shape"

      refute Exception.message(error) =~ unsafe_root
      refute inspect(error) =~ unsafe_root
    end)
  end

  test "rejects unknown, missing, duplicate, and non-atom keys without echoing input" do
    secret = "credential-bearing-value-must-not-echo"

    for input <- [
          Map.put(@valid, :unexpected, secret),
          Map.delete(@valid, :route_id),
          Map.to_list(@valid) ++ [route_id: "route-fedcba9876543210"],
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

  test "rejects TypeScript-unsafe endpoint characters without echoing them" do
    for {key, unsafe_value} <- [
          {:sync_path, "/study/\"sync"},
          {:sync_path, "/study\\\\sync"},
          {:evidence_path, "/_proof/\"evidence"},
          {:evidence_path, "/_proof\\\\evidence"}
        ] do
      assert {:error, %{rule_id: "PL-CONFIG-VALUE", key: returned_key} = error} =
               Config.normalize(Map.put(@valid, key, unsafe_value))

      assert returned_key == Atom.to_string(key)

      assert Exception.message(error) ==
               "PL-CONFIG-VALUE: #{returned_key}; use the documented local proof-lane shape"

      refute Exception.message(error) =~ unsafe_value
      refute inspect(error) =~ unsafe_value
    end
  end

  test "accepts only declarative safe mutation field segments" do
    assert {:ok, _} =
             Config.normalize(Map.put(@valid, :mutation_id_path, "record.client_mutation_id"))

    assert {:error, _} =
             Config.normalize(Map.put(@valid, :mutation_id_path, "record[mutation_id]"))
  end

  test "selected Phoenix config reaches the same normalizer as application config" do
    root = Path.join(System.tmp_dir!(), "crosswake-config-#{System.unique_integer([:positive])}")
    config_path = Path.join(root, "proof_lane.exs")
    ios_root = Path.join(root, "native/ios")
    previous = Application.get_env(:crosswake, :proof_lane)

    File.mkdir_p!(root)

    File.write!(config_path, """
    import Config

    config :crosswake, :proof_lane,
      route_id: \"route-0123456789abcdef\",
      route_path: \"/study/:id\",
      indexed_db_database: \"proof_lane\",
      indexed_db_store: \"mutations\",
      mutation_id_path: \"client_mutation_id\",
      sync_path: \"/study/sync\",
      evidence_path: \"/_proof/evidence\",
      router: CrosswakeWeb.Router,
      ios_shell_root: \"#{ios_root}\"
    """)

    Application.put_env(:crosswake, :proof_lane, Map.put(@valid, :ios_shell_root, ios_root))

    try do
      assert {:ok, expected} = Config.normalize(Application.get_env(:crosswake, :proof_lane))

      assert capture_io(fn ->
               Mix.Task.rerun("crosswake.gen.proof_lane", [
                 "ios",
                 "--config",
                 config_path,
                 "--diff"
               ])
             end) =~ "missing"

      {selected_config, _imports} = Elixir.Config.Reader.read_imports!(config_path)
      assert {:ok, ^expected} = Config.normalize(selected_config[:crosswake][:proof_lane])
    after
      if previous,
        do: Application.put_env(:crosswake, :proof_lane, previous),
        else: Application.delete_env(:crosswake, :proof_lane)

      File.rm_rf!(root)
    end
  end
end
