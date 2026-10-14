defmodule Crosswake.Shell.IOSHostGenerationHostCommandsTest do
  use ExUnit.Case, async: true

  alias Crosswake.Shell.IOSHostConfig
  alias Crosswake.Shell.IOSHostGeneration
  alias Crosswake.TestSupport.HostCommandFixtures, as: Fixtures

  defp config(router, entry_route_id) do
    %IOSHostConfig{
      router: router,
      origin: "https://study.crosswake.test",
      entry_route_id: entry_route_id,
      app_bundle_id: "org.crosswake.host",
      proof_app_bundle_id: "org.crosswake.host.proof",
      device_signing: %{mode: :automatic, team_id: "ABCDE12345"}
    }
  end

  defp render!(router, entry_route_id) do
    assert {:ok, rendered} = IOSHostGeneration.render(config(router, entry_route_id))
    rendered
  end

  defp activation_capabilities(rendered), do: Jason.decode!(rendered.activation)["capabilities"]

  test "each declaring route renders as entry with activation capabilities equal to its own declaration" do
    assert activation_capabilities(render!(Fixtures.DeclaringRouter, "lesson")) ==
             %{"host.lesson.audio.play" => "1.0.0"}

    assert activation_capabilities(render!(Fixtures.DeclaringRouter, "review")) ==
             %{"host.review.camera.scan" => "1.1.0"}
  end

  test "a non-declaring entry renders empty activation capabilities" do
    assert activation_capabilities(render!(Fixtures.DeclaringRouter, "plain")) == %{}
  end

  test "activation capabilities equal the manifest entry host_commands (parity) for every entry" do
    for entry <- ["lesson", "review", "plain"] do
      rendered = render!(Fixtures.DeclaringRouter, entry)
      manifest_commands = Jason.decode!(rendered.manifest)["routes"][entry]["host_commands"]

      assert activation_capabilities(rendered) == manifest_commands
      assert manifest_commands == Fixtures.declared(Fixtures.DeclaringRouter)[entry]
    end
  end

  test "the same command on two routes projects independently per entry" do
    for entry <- ["lesson", "practice"] do
      assert activation_capabilities(render!(Fixtures.SameCommandRouter, entry)) ==
               %{"host.lesson.audio.play" => "1.0.0"}
    end

    assert activation_capabilities(render!(Fixtures.SameCommandRouter, "plain")) == %{}
  end

  test "two renders of the same entry are byte-identical, and a permuted registry matches" do
    first = render!(Fixtures.DeclaringRouter, "lesson")
    second = render!(Fixtures.DeclaringRouter, "lesson")
    permuted = render!(Fixtures.PermutedRegistryRouter, "lesson")

    assert first.activation == second.activation
    assert first.activation == permuted.activation
    assert first.managed_outputs["Fixtures/route_activation.json"] == first.activation
  end

  test "entry_host_commands/2 reads only the entry route's manifest entry" do
    {:ok, %{manifest: manifest}} =
      Crosswake.Manifest.compile(Fixtures.DeclaringRouter, origin: "https://study.crosswake.test")

    assert IOSHostGeneration.entry_host_commands(manifest, "review") ==
             %{"host.review.camera.scan" => "1.1.0"}

    assert IOSHostGeneration.entry_host_commands(manifest, "plain") == %{}
  end

  describe "shell package gate (D-16c)" do
    @seam_swift_prefix "import Foundation\n\n"

    defp package_dir(version_line) do
      dir = Path.join(System.tmp_dir!(), "seam-gate-#{System.unique_integer([:positive])}")
      source = Path.join(dir, "Sources/CrosswakeShellCore")
      File.mkdir_p!(source)
      File.write!(Path.join(source, "ActivationCoordinator.swift"), @seam_swift_prefix <> version_line)
      on_exit(fn -> File.rm_rf!(dir) end)
      dir
    end

    defp enum_at(version) do
      "public enum HostCommandSeam {\n    public static let version = \"#{version}\"\n}\n"
    end

    defp gated(router, entry, source),
      do: IOSHostGeneration.render(config(router, entry), shell_package: source)

    test "a local package carrying seam 1.0.0 is allowed and projects capabilities" do
      assert {:ok, rendered} = gated(Fixtures.DeclaringRouter, "lesson", {:local, package_dir(enum_at("1.0.0"))})
      assert activation_capabilities(rendered) == %{"host.lesson.audio.play" => "1.0.0"}
    end

    test "a local package at 0.9.0 is blocked, naming the route, command, package and fix" do
      assert {:error, message} =
               gated(Fixtures.DeclaringRouter, "lesson", {:local, package_dir(enum_at("0.9.0"))})

      assert message =~ "route lesson"
      assert message =~ "host.lesson.audio.play"
      assert message =~ "crosswake-shell-core-ios"
      assert message =~ "0.9.0 is older than 1.0.0"
      assert message =~ "Fix:"
    end

    test "a local package without the seam constant is blocked" do
      assert {:error, message} =
               gated(Fixtures.DeclaringRouter, "lesson", {:local, package_dir("struct Other {}\n")})

      assert message =~ "no HostCommandSeam version declaration was found"
      assert message =~ "crosswake-shell-core-ios"
    end

    test "a remote package is blocked because no release carries the seam" do
      assert {:error, message} = gated(Fixtures.DeclaringRouter, "lesson", {:remote, "0.2.11"})
      assert message =~ "route lesson"
      assert message =~ "host.lesson.audio.play"
      assert message =~ "remote crosswake-shell-core-ios 0.2.11 carries no host-command seam release"
    end

    test "an unresolvable project is blocked, never allowed" do
      assert {:error, message} =
               gated(Fixtures.DeclaringRouter, "lesson", {:project, "/nonexistent/crosswake-managed"})

      assert message =~ "could not be determined"
    end

    test "a non-declaring router passes in every context" do
      for source <- [
            {:remote, nil},
            {:remote, "0.2.11"},
            {:local, package_dir("struct Other {}\n")},
            {:project, "/nonexistent/crosswake-managed"}
          ] do
        assert {:ok, _} = gated(Crosswake.TestSupport.RouterFixtures.ManagedRouter, "dashboard", source)
      end
    end

    test "render/1 without a context stays the pure projection" do
      assert activation_capabilities(render!(Fixtures.DeclaringRouter, "lesson")) ==
               %{"host.lesson.audio.play" => "1.0.0"}
    end
  end
end
