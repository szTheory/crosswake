defmodule Mix.Tasks.Crosswake.Gen.ShellTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  @task "crosswake.gen.shell"

  test "generates host-owned ios and android shell skeletons with ownership docs" do
    target = tmp_dir!("crosswake-shell")

    ios_output =
      capture_io(fn ->
        Mix.Task.reenable(@task)
        Mix.Task.run(@task, ["ios", "--target", target])
      end)

    assert ios_output =~ "Crosswake ios shell scaffold complete"

    ios_readme = Path.join(target, "native/ios/crosswake_shell/README.md")
    ios_source = Path.join(target, "native/ios/crosswake_shell/Sources/AppShell.swift")

    ios_fixture =
      Path.join(target, "native/ios/crosswake_shell/Fixtures/phase1_route_policy.json")

    assert File.read!(ios_readme) =~ "host-owned"
    assert File.read!(ios_readme) =~ "editable"
    assert File.read!(ios_readme) =~ "Phase 1"
    assert File.read!(ios_source) =~ "Phase 1 route-policy scaffold only"
    assert File.read!(ios_fixture) =~ "\"ownership\": \"host-owned\""

    android_output =
      capture_io(fn ->
        Mix.Task.reenable(@task)
        Mix.Task.run(@task, ["android", "--target", target])
      end)

    assert android_output =~ "Crosswake android shell scaffold complete"

    android_readme = Path.join(target, "native/android/crosswake_shell/README.md")

    android_source =
      Path.join(
        target,
        "native/android/crosswake_shell/app/src/main/java/dev/crosswake/shell/AppShell.kt"
      )

    android_fixture =
      Path.join(
        target,
        "native/android/crosswake_shell/app/src/main/assets/phase1_route_policy.json"
      )

    assert File.read!(android_readme) =~ "host-owned"
    assert File.read!(android_readme) =~ "editable"
    assert File.read!(android_readme) =~ "Phase 1"
    assert File.read!(android_source) =~ "Phase 1 route-policy scaffold only"
    assert File.read!(android_fixture) =~ "\"ownership\": \"host-owned\""
  end

  defp tmp_dir!(prefix) do
    path = Path.join(System.tmp_dir!(), "#{prefix}-#{System.unique_integer([:positive])}")
    File.rm_rf!(path)
    File.mkdir_p!(path)
    path
  end
end
