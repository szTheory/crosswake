defmodule Crosswake.OperatorInspectionHostCommandsTest do
  use ExUnit.Case, async: true

  alias Crosswake.OperatorInspection
  alias Crosswake.OperatorInspection.Formatter
  alias Crosswake.TestSupport.HostCommandFixtures.DeclaringRouter

  defp document do
    {:ok, %{manifest: manifest}} =
      Crosswake.Manifest.compile(DeclaringRouter, origin: "https://study.crosswake.test")

    OperatorInspection.from_manifest(manifest)
  end

  defp route(document, id), do: Map.fetch!(document.routes, id)

  test "a declaring route shows its runtime and host command with owner host" do
    lesson = route(document(), "lesson")
    assert lesson.runtime == :offline_island

    entry = Enum.find(lesson.capabilities, &(&1["id"] == "host.lesson.audio.play"))
    assert entry["owner"] == "host"
    assert entry["family"] == "host_command"
  end

  test "a non-declaring route has no host command entry" do
    plain = route(document(), "plain")
    assert plain.capabilities == []
  end

  test "human output lists the host command id" do
    output = document() |> Formatter.render() |> IO.iodata_to_binary()
    assert output =~ "host.lesson.audio.play"
    assert output =~ "host.review.camera.scan"
  end
end
