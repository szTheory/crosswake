defmodule Crosswake.ReleaseCandidate.IdentityTest do
  use ExUnit.Case, async: true

  alias Crosswake.ReleaseCandidate.Identity

  @sha_a String.duplicate("a", 40)
  @sha_b String.duplicate("b", 40)
  @sha_c String.duplicate("c", 40)
  @digest_a String.duplicate("1", 64)
  @digest_b String.duplicate("2", 64)
  @digest_c String.duplicate("3", 64)

  test "normalize!/2 accepts any well-formed semver whose coordinates all carry that version" do
    for version <- ["0.2.1", "9.9.9", "12.34.5"] do
      normalized = Identity.normalize!(fixture(version))

      assert normalized.version == version
      assert length(normalized.coordinates) == 3
      assert Enum.all?(normalized.coordinates, &String.ends_with?(&1.coordinate, "@" <> version))
    end
  end

  test "normalize!/2 raises when a coordinate's version suffix disagrees with the declared version" do
    mismatched =
      put_in(fixture("9.9.9"), [:coordinates, Access.at(0), :coordinate], "crosswake@1.0.0")

    assert_raise ArgumentError, ~r/candidate identity is invalid/, fn ->
      Identity.normalize!(mismatched)
    end
  end

  test "normalize!/2 raises for a malformed version under both consistent? true and false" do
    for consistent? <- [true, false] do
      malformed = put_in(fixture("9.9.9"), [:version], "v9.9.9")

      assert_raise ArgumentError, ~r/candidate identity is invalid/, fn ->
        Identity.normalize!(malformed, consistent?: consistent?)
      end
    end
  end

  test "normalize!/2 with consistent?: false accepts any well-formed semver regardless of coordinates" do
    observed = fixture("9.9.9")
    normalized = Identity.normalize!(observed, consistent?: false)

    assert normalized.version == "9.9.9"
  end

  defp fixture(version) do
    %{
      version: version,
      ref: @sha_a,
      head: @sha_a,
      tree: @sha_b,
      base: @sha_c,
      coordinates: [
        %{id: "hex-core", coordinate: "crosswake@#{version}"},
        %{id: "ios-core", coordinate: "crosswake@#{version}"},
        %{id: "android-core", coordinate: "crosswake@#{version}"}
      ],
      config_digests: [%{id: "release-please-config", sha256: @digest_a}],
      workflow_digests: [%{id: "release-please", sha256: @digest_b}],
      package_digests: [
        %{
          id: "crosswake",
          outer_sha256: @digest_a,
          payload_sha256: @digest_b,
          metadata_sha256: @digest_c
        }
      ],
      proofs: [%{id: "package-audit", status: "PASS", sha256: @digest_a}],
      mirror: %{
        split: @sha_a,
        main: @sha_b,
        tag: "v#{version}",
        plan_sha256: @digest_c
      },
      run: %{id: 1234, head: @sha_a, status: "COMPLETED", conclusion: "SUCCESS"}
    }
  end
end
