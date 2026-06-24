defmodule Crosswake.Guides.PortRegistryTest do
  use ExUnit.Case, async: true

  @port_registry_path "docs/PORT-REGISTRY.md"
  @env_path "examples/phoenix_host/.env"
  @runtime_config_path "examples/phoenix_host/config/runtime.exs"

  test "source-derived facts are readable" do
    assert committed_port() =~ ~r/^\d+$/
    assert File.exists?(@port_registry_path)
    assert File.exists?(@env_path)
  end

  test "PORT-REGISTRY mentions COMPOSE_PROJECT_NAME, 10.0.2.2, and the crosswake seed row" do
    contents = File.read!(@port_registry_path)
    port = committed_port()

    failures =
      [
        require_contains(@port_registry_path, contents, "COMPOSE_PROJECT_NAME", :missing_caveat,
          "document COMPOSE_PROJECT_NAME namespacing caveat"),
        require_contains(@port_registry_path, contents, "10.0.2.2", :missing_android_note,
          "document Android emulator host loopback address"),
        require_contains(@port_registry_path, contents, port, :wrong_port,
          "registry must list the source-derived port"),
        require_contains(@port_registry_path, contents, "crosswake", :missing_seed_row,
          "registry must have a crosswake seed row")
      ]
      |> List.flatten()

    assert failures == [],
           "PORT-REGISTRY drift found:\n" <> format_failures(failures)
  end

  test "PORT-REGISTRY scanner rejects missing COMPOSE_PROJECT_NAME" do
    contents = File.read!(@port_registry_path)
    without_caveat = String.replace(contents, "COMPOSE_PROJECT_NAME", "PROJECT_NAME")

    assert_failure_category(
      scan_registry({"synthetic/port_registry_no_compose.md", without_caveat}),
      :missing_caveat
    )
  end

  test "PORT-REGISTRY scanner rejects missing 10.0.2.2 Android note" do
    contents = File.read!(@port_registry_path)
    without_android = String.replace(contents, "10.0.2.2", "10.0.2.3")

    assert_failure_category(
      scan_registry({"synthetic/port_registry_no_android.md", without_android}),
      :missing_android_note
    )
  end

  # ---------------------------------------------------------------------------
  # Scanner
  # ---------------------------------------------------------------------------

  defp scan_registry({path, contents}) do
    port = committed_port()

    [
      require_contains(path, contents, "COMPOSE_PROJECT_NAME", :missing_caveat,
        "document COMPOSE_PROJECT_NAME namespacing caveat"),
      require_contains(path, contents, "10.0.2.2", :missing_android_note,
        "document Android emulator host loopback address"),
      require_contains(path, contents, port, :wrong_port,
        "registry must list the source-derived port"),
      require_contains(path, contents, "crosswake", :missing_seed_row,
        "registry must have a crosswake seed row")
    ]
    |> List.flatten()
  end

  # ---------------------------------------------------------------------------
  # Source-derived port extraction (verbatim from quick_start_adoption_drift_test.exs)
  # ---------------------------------------------------------------------------

  defp committed_port do
    @runtime_config_path
    |> File.read!()
    |> source_port!(~r/System\.get_env\("PORT"\)\s*\|\|\s*"(\d+)"/, @runtime_config_path)
  end

  defp source_port!(contents, regex, path) do
    case Regex.run(regex, contents) do
      [_match, port] -> port
      _ -> raise "could not derive port from #{path}"
    end
  end

  # ---------------------------------------------------------------------------
  # Failure struct + formatting (verbatim from quick_start_adoption_drift_test.exs)
  # ---------------------------------------------------------------------------

  defp failure(path, category, opts) do
    %{
      path: path,
      line: Keyword.get(opts, :line),
      category: category,
      claim: Keyword.get(opts, :claim),
      detail: Keyword.fetch!(opts, :detail)
    }
  end

  defp format_failures(failures) do
    Enum.map_join(failures, "\n", fn failure ->
      location =
        if failure.line do
          "#{failure.path}:#{failure.line}"
        else
          failure.path
        end

      claim =
        failure.claim
        |> to_string()
        |> String.trim()

      claim_suffix = if claim == "", do: "", else: " -- #{claim}"

      "- #{location} [#{failure.category}] #{failure.detail}#{claim_suffix}"
    end)
  end

  defp assert_failure_category(failures, category) do
    assert Enum.any?(failures, &(&1.category == category)),
           "expected #{inspect(category)} failure, got:\n" <> format_failures(failures)
  end

  # ---------------------------------------------------------------------------
  # require_contains (verbatim from quick_start_adoption_drift_test.exs)
  # ---------------------------------------------------------------------------

  defp require_contains(path, contents, needle, category, detail) do
    if String.contains?(contents, needle) do
      []
    else
      [failure(path, category, detail: detail)]
    end
  end
end
