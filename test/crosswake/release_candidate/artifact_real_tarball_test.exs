defmodule Crosswake.ReleaseCandidate.ArtifactRealTarballTest do
  @moduledoc """
  Real Hex tarballs through `Crosswake.ReleaseCandidate.Artifact`, not invented fixtures.

  The fixtures (see `test/fixtures/hex_tarballs/README.md`) are the public pre-2.6 Hex tarball of
  `crosswake_rulestead` 0.1.1, a Hex 2.6+ rebuild of the same tag, and the public `crosswake`
  0.2.13 tarball. Assertions state relations and shapes only. Every Hex version is read from the
  fixtures, and no digest is written down as an expected value.
  """

  use ExUnit.Case, async: true

  alias Crosswake.ReleaseCandidate.Artifact

  @public_rulestead "crosswake_rulestead-0.1.1.public.tar"
  @rebuild_rulestead "crosswake_rulestead-0.1.1.rebuild.tar"
  @public_core "crosswake-0.2.13.public.tar"

  @candidate_ref String.duplicate("a", 40)

  test "floor: the rulestead rebuild carries a Hex 2.6+ build_env" do
    build_envs = build_env_terms(fixture_metadata_terms!(@rebuild_rulestead))

    assert [{"build_env", [{"hex", version}]}] = build_envs
    assert Version.compare(version, "2.6.0") in [:eq, :gt]
  end

  test "floor: the public rulestead tarball has no build_env" do
    assert [] == build_env_terms(fixture_metadata_terms!(@public_rulestead))
  end

  test "floor: the public core 0.2.13 carries a Hex 2.6+ build_env" do
    build_envs = build_env_terms(fixture_metadata_terms!(@public_core))

    assert [{"build_env", [{"hex", version}]}] = build_envs
    assert Version.compare(version, "2.6.0") in [:eq, :gt]
  end

  test "equality: public tarball and Hex 2.6+ rebuild of the same tag give equal digests" do
    public = observe!(@public_rulestead, "crosswake_rulestead", "0.1.1")
    rebuild = observe!(@rebuild_rulestead, "crosswake_rulestead", "0.1.1")

    assert public.metadata_digest =~ ~r/\A[0-9a-f]{64}\z/
    assert rebuild.metadata_digest =~ ~r/\A[0-9a-f]{64}\z/
    assert public.payload_digest =~ ~r/\A[0-9a-f]{64}\z/
    assert rebuild.payload_digest =~ ~r/\A[0-9a-f]{64}\z/

    assert public.payload_digest == rebuild.payload_digest
    assert public.metadata_digest == rebuild.metadata_digest
  end

  # -- helpers ---------------------------------------------------------------------------------

  defp fixture_path(name),
    do: Path.join(Path.expand("../../fixtures/hex_tarballs", __DIR__), name)

  defp build_env_terms(terms), do: Enum.filter(terms, &match?({"build_env", _}, &1))

  # Copies the fixture into a fresh directory and unpacks it the way the official Hex unpack lays
  # it out: outer tar, then contents.tar.gz, with the metadata copied to hex_metadata.config.
  defp unpack!(fixture_name) do
    dir =
      Path.join(
        System.tmp_dir!(),
        "crosswake-real-tarball-#{System.unique_integer([:positive, :monotonic])}-#{:erlang.phash2(make_ref())}"
      )

    outer = Path.join(dir, "outer")
    root = Path.join(dir, "unpacked")
    tarball = Path.join(dir, fixture_name)

    File.mkdir_p!(outer)
    File.mkdir_p!(root)
    File.cp!(fixture_path(fixture_name), tarball)
    on_exit(fn -> File.rm_rf(dir) end)

    :ok = :erl_tar.extract(String.to_charlist(tarball), [{:cwd, String.to_charlist(outer)}])

    :ok =
      :erl_tar.extract(
        String.to_charlist(Path.join(outer, "contents.tar.gz")),
        [:compressed, {:cwd, String.to_charlist(root)}]
      )

    File.cp!(Path.join(outer, "metadata.config"), Path.join(root, "hex_metadata.config"))

    %{dir: dir, tarball: tarball, root: root}
  end

  defp observe!(fixture_name, package, version, mutate_fun \\ &Function.identity/1) do
    %{dir: dir, tarball: tarball, root: root} = unpack!(fixture_name)
    mutate_fun.(root)

    outer_checksum =
      :crypto.hash(:sha256, File.read!(tarball)) |> Base.encode16(case: :lower)

    Artifact.inspect_single!(
      %{
        package: package,
        version: version,
        candidate_ref: @candidate_ref,
        tarball: tarball,
        unpacked_root: root,
        outer_checksum: outer_checksum,
        source: "built_tarball"
      },
      dir
    )
  end

  defp metadata_terms!(root) do
    {:ok, terms} = :file.consult(String.to_charlist(Path.join(root, "hex_metadata.config")))
    terms
  end

  defp fixture_metadata_terms!(fixture_name), do: metadata_terms!(unpack!(fixture_name).root)

  # `fun` maps the list of metadata terms to the list to write back.
  defp rewrite_metadata!(root, fun) do
    path = Path.join(root, "hex_metadata.config")
    rewritten = root |> metadata_terms!() |> fun.()
    File.write!(path, Enum.map(rewritten, &:io_lib.format("~tp.~n", [&1])))
  end

  defp put_build_env(value) do
    fn root ->
      rewrite_metadata!(root, fn terms ->
        Enum.reject(terms, &match?({"build_env", _}, &1)) ++ [{"build_env", value}]
      end)
    end
  end

  defp drop_build_env do
    fn root ->
      rewrite_metadata!(root, fn terms -> Enum.reject(terms, &match?({"build_env", _}, &1)) end)
    end
  end

  # Reads V from the fixture's own `{"build_env", [{"hex", V}]}`.
  defp fixture_hex_version!(fixture_name) do
    [{"build_env", [{"hex", version}]}] = build_env_terms(fixture_metadata_terms!(fixture_name))
    version
  end
end
