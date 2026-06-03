defmodule Mix.Tasks.Crosswake.InspectTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  @task "crosswake.inspect"

  test "mix crosswake.inspect emits human-readable route inventory" do
    output =
      capture_io(fn ->
        Mix.Task.reenable(@task)

        Mix.Task.run(@task, [
          "--router",
          "Elixir.Crosswake.TestSupport.RouterFixtures.ManagedRouter"
        ])
      end)

    assert output =~ "Crosswake operator inspection"
    assert output =~ "dashboard /dashboard runtime=live_view owner=phoenix"
    assert output =~ "study-session /study-session runtime=offline_island owner=offline_island"
    assert output =~ "support="
    assert output =~ "proof="
  end

  test "mix crosswake.inspect emits stable json route inventory" do
    output =
      capture_io(fn ->
        Mix.Task.reenable(@task)

        Mix.Task.run(@task, [
          "--router",
          "Elixir.Crosswake.TestSupport.RouterFixtures.ManagedRouter",
          "--format",
          "json"
        ])
      end)

    decoded = Jason.decode!(output)

    assert decoded["schema_version"] == "1.0.0"
    assert decoded["routes"]["dashboard"]["path"] == "/dashboard"
    assert decoded["routes"]["study-session"]["runtime"] == "offline_island"
    assert decoded["indexes"]["by_runtime"]["live_view"] == ["dashboard", "library"]
  end

  test "mix crosswake.inspect rejects unsupported formats and missing routers" do
    assert_raise Mix.Error, ~r/pass --router/, fn ->
      Mix.Task.reenable(@task)
      Mix.Task.run(@task, [])
    end

    assert_raise Mix.Error, ~r/unsupported format/, fn ->
      Mix.Task.reenable(@task)

      Mix.Task.run(@task, [
        "--router",
        "Elixir.Crosswake.TestSupport.RouterFixtures.ManagedRouter",
        "--format",
        "yaml"
      ])
    end

    assert_raise Mix.Error,
                 ~r/router module Elixir.Crosswake.DoesNotExist is not available/,
                 fn ->
                   Mix.Task.reenable(@task)

                   Mix.Task.run(@task, [
                     "--router",
                     "Elixir.Crosswake.DoesNotExist"
                   ])
                 end
  end
end
