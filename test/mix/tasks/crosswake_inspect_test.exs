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

  describe "host origin line" do
    @router "Elixir.Crosswake.TestSupport.RouterFixtures.ManagedRouter"

    defp declaration(origin, extra \\ []) do
      [
        router: Crosswake.TestSupport.RouterFixtures.ManagedRouter,
        origin: origin,
        entry_route_id: "route-0123456789abcdef",
        app_bundle_id: "org.crosswake.host",
        proof_app_bundle_id: "org.crosswake.host.proof",
        device_signing: [mode: :manual, team_id: "ABCDE12345"]
      ] ++ extra
    end

    defp run_inspect(args \\ []) do
      capture_io(fn ->
        Mix.Task.reenable(@task)
        Mix.Task.run(@task, ["--router", @router] ++ args)
      end)
    end

    defp with_ios_host(value, fun) do
      previous = Application.get_env(:crosswake, :ios_host)

      if value,
        do: Application.put_env(:crosswake, :ios_host, value),
        else: Application.delete_env(:crosswake, :ios_host)

      try do
        fun.()
      after
        if previous,
          do: Application.put_env(:crosswake, :ios_host, previous),
          else: Application.delete_env(:crosswake, :ios_host)
      end
    end

    test "local declaration adds the local loopback line last" do
      with_ios_host(declaration("http://127.0.0.1:4790", origin_mode: :local_loopback), fn ->
        output = run_inspect()

        assert String.trim_trailing(output) |> String.split("\n") |> List.last() ==
                 "host origin: http://127.0.0.1:4790 (local loopback mode, Simulator only, not production-ready)"
      end)
    end

    test "HTTPS declaration adds a plain host origin line last" do
      with_ios_host(declaration("https://study.crosswake.test"), fn ->
        output = run_inspect()

        assert String.trim_trailing(output) |> String.split("\n") |> List.last() ==
                 "host origin: https://study.crosswake.test"
      end)
    end

    test "no declaration or a refused declaration prints no host origin line" do
      with_ios_host(nil, fn -> refute run_inspect() =~ "host origin:" end)
      with_ios_host([origin: "ftp://nope"], fn -> refute run_inspect() =~ "host origin:" end)
    end

    test "json output is byte-equal with and without a local declaration" do
      bare = with_ios_host(nil, fn -> run_inspect(["--format", "json"]) end)

      local =
        with_ios_host(declaration("http://127.0.0.1:4790", origin_mode: :local_loopback), fn ->
          run_inspect(["--format", "json"])
        end)

      assert bare == local
      refute local =~ "host origin"
    end

    test "the line never carries the entry route or bundle ids" do
      with_ios_host(declaration("http://127.0.0.1:4790", origin_mode: :local_loopback), fn ->
        line = run_inspect() |> String.split("\n") |> Enum.find(&(&1 =~ "host origin:"))
        refute line =~ "route-0123456789abcdef"
        refute line =~ "org.crosswake"
      end)
    end
  end
end
