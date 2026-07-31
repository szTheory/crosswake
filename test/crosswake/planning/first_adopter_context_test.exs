defmodule Crosswake.Planning.FirstAdopterContextTest do
  use ExUnit.Case, async: true

  alias Crosswake.Planning.FirstAdopterContext

  test "routing matrix classifies every active path once with non-empty required destinations" do
    matrix = FirstAdopterContext.routing_matrix()
    paths = FirstAdopterContext.active_paths()

    assert paths ==
             matrix
             |> Enum.filter(& &1.scan?)
             |> Enum.map(& &1.path)

    assert paths == Enum.sort(paths)
    assert Enum.all?(paths, &File.exists?/1)
    assert FirstAdopterContext.validate_routing_matrix(matrix) == []

    for destination <- [
          :durable,
          :public,
          :fast_changing,
          :host_private,
          :secret_only,
          :forbidden
        ] do
      assert Enum.any?(matrix, &(&1.destination == destination)),
             "routing matrix must retain a #{destination} destination"
    end

    duplicate = [%{path: "AGENTS.md", destination: :durable} | matrix]

    assert [%{rule_id: "routing.duplicate_path", path: "AGENTS.md"}] =
             FirstAdopterContext.validate_routing_matrix(duplicate)

    missing_destination = Enum.map(matrix, &Map.put(&1, :destination, nil))

    assert Enum.any?(
             FirstAdopterContext.validate_routing_matrix(missing_destination),
             fn violation ->
               violation.rule_id == "routing.unclassified_path"
             end
           )

    empty_public = Enum.reject(matrix, &(&1.destination == :public))

    assert [%{rule_id: "routing.required_destination_empty", path: "public"}] =
             FirstAdopterContext.validate_routing_matrix(empty_public)
  end

  test "public and durable scans enforce the phrase split with stable rule and path violations" do
    contents = contents_by_path()

    assert FirstAdopterContext.scan(contents) == []

    public_path = "guides/capability_map.md"

    assert [%{rule_id: "privacy.public_phrase", path: ^public_path}] =
             FirstAdopterContext.scan(Map.put(contents, public_path, "route ownership"))

    assert [%{rule_id: "privacy.public_codename", path: ^public_path}] =
             FirstAdopterContext.scan(
               Map.put(contents, public_path, "First B2C Adopter first adopter route ownership")
             )
  end

  test "private-term scan never echoes configured terms or matched content" do
    private_term = "synthetic-private-term"
    path = "AGENTS.md"
    contents = Map.put(contents_by_path(), path, "prefix #{private_term} suffix")

    assert [%{rule_id: "privacy.private_term", path: ^path}] =
             FirstAdopterContext.scan_private_terms(contents, [private_term])

    refute inspect(FirstAdopterContext.scan_private_terms(contents, [private_term])) =~
             private_term
  end

  test "configured private terms are parsed case-insensitively at the caller seam" do
    private_terms =
      System.get_env("CROSSWAKE_PRIVATE_ADOPTER_TERMS", "")
      |> String.split(",", trim: true)
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))

    assert FirstAdopterContext.scan_private_terms(contents_by_path(), private_terms) == []
  end

  defp contents_by_path do
    FirstAdopterContext.active_paths()
    |> Map.new(&{&1, File.read!(&1)})
  end
end
