defmodule Crosswake.Guides.QuickStartAdoptionDriftTest do
  use ExUnit.Case, async: true

  @quick_start_path "examples/QUICK_START.md"
  @adoption_path "guides/adoption.md"
  @phoenix_config_path "examples/phoenix_host/config/config.exs"
  @playwright_config_path "examples/phoenix_host/playwright.config.ts"
  @phoenix_mix_path "examples/phoenix_host/mix.exs"

  @setup_aliases MapSet.new(["setup", "ecto.setup", "ecto.reset"])

  @quick_start_paths [
    {"examples/phoenix_host", ["examples/phoenix_host"]},
    {"examples/ios_shell_host/CrosswakeShell.xcodeproj",
     ["examples/ios_shell_host/CrosswakeShell.xcodeproj"]},
    {"examples/android_shell_host", ["examples/android_shell_host"]},
    {"examples/phoenix_host/e2e/offline_sync.spec.ts",
     ["examples/phoenix_host/e2e/offline_sync.spec.ts", "e2e/offline_sync.spec.ts"]},
    {"script/verify_bounded_bridge_proof.sh", ["script/verify_bounded_bridge_proof.sh"]},
    {"script/verify_phase5_example_hosts.sh", ["script/verify_phase5_example_hosts.sh"]}
  ]

  @native_paths [
    "examples/ios_shell_host/CrosswakeShell.xcodeproj",
    "examples/android_shell_host"
  ]

  test "source-derived facts used by the drift scanner are readable" do
    assert current_version() =~ ~r/^\d+\.\d+\.\d+/
    assert phoenix_host_port() == playwright_port()
    assert MapSet.subset?(@setup_aliases, setup_aliases())

    assert Enum.all?(@quick_start_paths, fn {path, _aliases} -> existing_path?(path) end)
  end

  test "quick start and adoption guide match source-derived route proof truth" do
    failures =
      scan_quick_start({@quick_start_path, File.read!(@quick_start_path)}) ++
        scan_adoption({@adoption_path, File.read!(@adoption_path)})

    assert_no_drift_failures(failures)
  end

  test "quick start scanner rejects stale ports, commands, paths, and native labels" do
    quick_start = File.read!(@quick_start_path)
    port = phoenix_host_port()

    assert_failure_category(
      scan_quick_start(
        {"synthetic/quick_start_wrong_port.md", String.replace(quick_start, port, "4000")}
      ),
      :wrong_port
    )

    assert_failure_category(
      scan_quick_start(
        {"synthetic/quick_start_missing_setup.md",
         String.replace(quick_start, "mix setup", "mix deps.get")}
      ),
      :missing_command
    )

    assert_failure_category(
      scan_quick_start(
        {"synthetic/quick_start_missing_path.md",
         quick_start <> "\nSee `examples/not_a_real_host`.\n"}
      ),
      :missing_path
    )

    without_native_labels =
      quick_start
      |> String.replace(~r/advisory/i, "optional")
      |> String.replace("checked-in public-coordinate proof", "checked-in native proof")

    assert_failure_category(
      scan_quick_start({"synthetic/quick_start_missing_native_labels.md", without_native_labels}),
      :missing_native_label
    )
  end

  test "adoption scanner rejects stale offline-authority wording" do
    adoption = File.read!(@adoption_path)

    stale_cases = [
      {"synthetic/adoption_mutate.md",
       adoption <> "\nCall `Crosswake.mutate(...)` for local writes.\n"},
      {"synthetic/adoption_sync_engine.md",
       adoption <> "\nUse the Sync Engine (Bridge) for replay.\n"},
      {"synthetic/adoption_bridge_owned_queue.md",
       adoption <> "\nThe bridge-owned mutation queue replays offline writes.\n"}
    ]

    for {path, contents} <- stale_cases do
      assert_failure_category(
        scan_adoption({path, contents}),
        :forbidden_offline_authority
      )
    end
  end

  test "adoption scanner rejects missing app-owned offline proof teaching" do
    adoption = File.read!(@adoption_path)

    missing_proof_cases = [
      {"synthetic/adoption_no_indexeddb.md",
       String.replace(adoption, "IndexedDB", "browser storage")},
      {"synthetic/adoption_no_flush.md",
       String.replace(adoption, "flushOutbox", "flushQueuedWork")},
      {"synthetic/adoption_no_sync_endpoint.md",
       String.replace(adoption, "/study/sync", "/sync")},
      {"synthetic/adoption_no_mutation_id.md",
       String.replace(adoption, "client_mutation_id", "client_event_id")},
      {"synthetic/adoption_no_idempotency.md",
       String.replace(adoption, "on_conflict: :nothing", "server upsert behavior")},
      {"synthetic/adoption_no_outbox_deletion.md",
       String.replace(adoption, ~r/\b(?:deleted|removed|deletes)\b/i, "cleared")},
      {"synthetic/adoption_no_outcomes.md",
       adoption
       |> String.replace(~r/\baccepted\b/i, "saved")
       |> String.replace(~r/\brejected\b/i, "invalid")
       |> String.replace(~r/\bconflict\b/i, "disagreement")}
    ]

    for {path, contents} <- missing_proof_cases do
      assert_failure_category(scan_adoption({path, contents}), :missing_offline_proof)
    end
  end

  defp current_version do
    Application.spec(:crosswake, :vsn) |> to_string()
  end

  defp phoenix_host_port do
    @phoenix_config_path
    |> File.read!()
    |> source_port!(~r/System\.get_env\("PORT"\)\s*\|\|\s*"(\d+)"/, @phoenix_config_path)
  end

  defp playwright_port do
    contents = File.read!(@playwright_config_path)

    base_url_port =
      source_port!(
        contents,
        ~r/baseURL:\s*['"]http:\/\/localhost:(\d+)['"]/,
        @playwright_config_path
      )

    web_server_port =
      source_port!(contents, ~r/\bport:\s*(\d+)/, @playwright_config_path)

    if base_url_port == web_server_port do
      base_url_port
    else
      raise "Playwright baseURL port #{base_url_port} does not match webServer port #{web_server_port}"
    end
  end

  defp setup_aliases do
    @phoenix_mix_path
    |> File.read!()
    |> then(fn contents ->
      ~r/(?:^|\s)(setup|"ecto\.setup"|"ecto\.reset"):\s*\[/m
      |> Regex.scan(contents)
      |> Enum.map(fn [_match, alias_name] -> String.trim(alias_name, "\"") end)
      |> MapSet.new()
    end)
  end

  defp existing_path?(path), do: File.exists?(path)

  defp scan_quick_start(doc) do
    {path, contents} = normalize_doc(doc)
    port = phoenix_host_port()

    source_failures =
      setup_alias_failures() ++ source_path_failures(@quick_start_paths)

    quick_start_failures =
      [
        require_contains(path, contents, "mix setup", :missing_command, "document `mix setup`"),
        require_contains(
          path,
          contents,
          "PORT=#{port} mix phx.server",
          :missing_command,
          "document the source-derived Phoenix host server command"
        ),
        require_contains(
          path,
          contents,
          "http://localhost:#{port}",
          :missing_command,
          "document the source-derived Phoenix host URL"
        ),
        require_contains(
          path,
          contents,
          "/offline",
          :missing_route,
          "document the offline route"
        ),
        require_contains(
          path,
          contents,
          "/bridge-proof",
          :missing_route,
          "document the bounded bridge proof route"
        ),
        require_contains(
          path,
          contents,
          "/study/sync",
          :missing_route,
          "document the offline replay sync endpoint"
        ),
        require_contains(path, contents, "npm ci", :missing_command, "document npm install"),
        require_contains(
          path,
          contents,
          "npx playwright install chromium",
          :missing_command,
          "document Chromium install for Playwright"
        ),
        require_contains(
          path,
          contents,
          "npx playwright test e2e/offline_sync.spec.ts",
          :missing_command,
          "document the offline replay Playwright spec"
        ),
        require_contains(
          path,
          contents,
          "MIX_ENV=test",
          :missing_command,
          "document that Playwright starts a test Phoenix server"
        ),
        require_contains(
          path,
          contents,
          "/_e2e",
          :missing_route,
          "document the gated E2E inspection route"
        ),
        require_regex(
          path,
          contents,
          ~r/\bstop\b[\s\S]{0,180}(?:phx\.server|dev server|Phoenix)/i,
          :missing_command,
          "tell readers to stop the dev server before Playwright starts its own server"
        ),
        require_contains(
          path,
          contents,
          "bash script/verify_bounded_bridge_proof.sh",
          :missing_command,
          "document the bounded bridge proof script from the repo root"
        ),
        require_contains(
          path,
          contents,
          "CROSSWAKE_PHASE5_NATIVE_PROOFS=0 bash script/verify_phase5_example_hosts.sh",
          :missing_command,
          "document the native-skipped phase5 proof script from the repo root"
        )
      ]
      |> List.flatten()

    source_failures ++
      quick_start_failures ++
      required_path_doc_failures(path, contents, @quick_start_paths) ++
      documented_path_failures(path, contents) ++
      wrong_port_failures(path, contents, port) ++
      native_label_failures(path, contents) ++
      forbidden_language_failures(path, contents)
  end

  defp scan_adoption(doc) do
    {path, contents} = normalize_doc(doc)

    [
      require_contains(
        path,
        contents,
        "IndexedDB",
        :missing_offline_proof,
        "teach the app-owned IndexedDB outbox"
      ),
      require_contains(
        path,
        contents,
        "flushOutbox",
        :missing_offline_proof,
        "teach the app-owned flush function"
      ),
      require_contains(
        path,
        contents,
        "/study/sync",
        :missing_offline_proof,
        "teach the route-local sync endpoint"
      ),
      require_contains(
        path,
        contents,
        "client_mutation_id",
        :missing_offline_proof,
        "teach idempotency by client mutation id"
      ),
      require_contains(
        path,
        contents,
        "on_conflict: :nothing",
        :missing_offline_proof,
        "teach Ecto idempotent insert behavior"
      ),
      require_regex(
        path,
        contents,
        ~r/\bidempotent\b/i,
        :missing_offline_proof,
        "teach duplicate replay idempotency"
      ),
      require_regex(
        path,
        contents,
        ~r/\baccepted\b/i,
        :missing_offline_proof,
        "document accepted replay outcomes"
      ),
      require_regex(
        path,
        contents,
        ~r/\brejected\b/i,
        :missing_offline_proof,
        "document rejected replay outcomes"
      ),
      require_regex(
        path,
        contents,
        ~r/\bconflict\b/i,
        :missing_offline_proof,
        "document conflict replay outcomes"
      ),
      require_regex(
        path,
        contents,
        ~r/(?:deleted|removed)[^\n.]*outbox|outbox[^\n.]*(?:deleted|removed)/i,
        :missing_offline_proof,
        "document that accepted outbox records are deleted"
      ),
      require_contains(
        path,
        contents,
        "examples/phoenix_host/priv/static/offline_study.js",
        :missing_offline_proof,
        "name the current browser island implementation"
      ),
      require_contains(
        path,
        contents,
        "CrosswakeExample.LocalFirst.SyncController",
        :missing_offline_proof,
        "name the current sync controller"
      ),
      require_contains(
        path,
        contents,
        "CrosswakeExample.LocalFirst.Study.sync_events/1",
        :missing_offline_proof,
        "name the current reconciliation context"
      ),
      require_contains(
        path,
        contents,
        "CrosswakeExample.LocalFirst.ReviewEvent",
        :missing_offline_proof,
        "name the current Ecto schema"
      )
    ]
    |> List.flatten()
    |> Kernel.++(documented_path_failures(path, contents))
    |> Kernel.++(forbidden_language_failures(path, contents))
  end

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

  defp assert_no_drift_failures(failures) do
    assert failures == [],
           "quick-start/adoption drift found:\n" <> format_failures(failures)
  end

  defp assert_failure_category(failures, category) do
    assert Enum.any?(failures, &(&1.category == category)),
           "expected #{inspect(category)} failure, got:\n" <> format_failures(failures)
  end

  defp normalize_doc({path, contents}), do: {path, contents}

  defp source_port!(contents, regex, path) do
    case Regex.run(regex, contents) do
      [_match, port] -> port
      _ -> raise "could not derive port from #{path}"
    end
  end

  defp setup_alias_failures do
    aliases = setup_aliases()

    @setup_aliases
    |> Enum.reject(&MapSet.member?(aliases, &1))
    |> Enum.map(fn alias_name ->
      failure(@phoenix_mix_path, :source_drift,
        detail: "expected Phoenix host mix alias #{alias_name}"
      )
    end)
  end

  defp source_path_failures(paths) do
    paths
    |> Enum.reject(fn {path, _aliases} -> existing_path?(path) end)
    |> Enum.map(fn {path, _aliases} ->
      failure(path, :missing_path, detail: "expected source path to exist")
    end)
  end

  defp required_path_doc_failures(doc_path, contents, paths) do
    Enum.flat_map(paths, fn {path, aliases} ->
      cond do
        not existing_path?(path) ->
          [
            failure(path, :missing_path,
              detail: "expected source path to exist before accepting documentation"
            )
          ]

        Enum.any?(aliases, &String.contains?(contents, &1)) ->
          []

        true ->
          [
            failure(doc_path, :missing_path,
              detail: "document current path #{path} with one of #{Enum.join(aliases, ", ")}"
            )
          ]
      end
    end)
  end

  defp documented_path_failures(doc_path, contents) do
    contents
    |> documented_paths()
    |> Enum.reject(&existing_path?/1)
    |> Enum.map(fn missing_path ->
      failure(doc_path, :missing_path,
        line: line_number(contents, missing_path),
        claim: missing_path,
        detail: "documented repo path does not exist"
      )
    end)
  end

  defp documented_paths(contents) do
    ~r/(?:examples|script)\/[A-Za-z0-9_.\/-]+/
    |> Regex.scan(contents)
    |> Enum.map(fn [path] -> String.trim_trailing(path, ".,);:`]") end)
    |> Enum.reject(&String.ends_with?(&1, "/"))
    |> Enum.uniq()
  end

  defp wrong_port_failures(path, contents, expected_port) do
    contents
    |> lines()
    |> Enum.flat_map(fn {line, line_number} ->
      ~r/(?:localhost:|PORT=)(\d+)/
      |> Regex.scan(line)
      |> Enum.reject(fn [_match, port] -> port == expected_port end)
      |> Enum.map(fn [claim, _port] ->
        failure(path, :wrong_port,
          line: line_number,
          claim: claim,
          detail: "expected source-derived port #{expected_port}"
        )
      end)
    end)
  end

  defp native_label_failures(path, contents) do
    Enum.flat_map(@native_paths, fn native_path ->
      if String.contains?(contents, native_path) and
           not native_labels_near?(contents, native_path) do
        [
          failure(path, :missing_native_label,
            line: line_number(contents, native_path),
            claim: native_path,
            detail:
              "native host paths must be labeled checked-in public-coordinate proof and published-coordinate mode"
          )
        ]
      else
        []
      end
    end)
  end

  defp native_labels_near?(contents, native_path) do
    contents
    |> context_window(native_path, 1_500)
    |> String.downcase()
    |> then(fn context ->
      String.contains?(context, "checked-in public-coordinate proof") and
        String.contains?(context, "published-coordinate mode")
    end)
  end

  defp forbidden_language_failures(path, contents) do
    forbidden_checks = [
      {"Crosswake.mutate", ~r/Crosswake\.mutate/},
      {"Sync Engine (Bridge)", ~r/Sync Engine \(Bridge\)/},
      {"bridge-owned mutation queue", ~r/\bbridge[- ]owned\s+(?:offline\s+)?mutation\s+queue\b/i},
      {"bridge owns mutation queue",
       ~r/\bbridge\s+owns?\s+(?:the\s+)?(?:offline\s+)?mutation\s+queue\b/i},
      {"mutation queue owned by bridge",
       ~r/\bmutation\s+queue\s+owned\s+by\s+(?:the\s+)?bridge\b/i},
      {"native proof overclaim",
       ~r/\bchecked-in public-coordinate proof\b.*\b(simulator|emulator|physical-device|device)\s+support\b/i}
    ]

    Enum.flat_map(forbidden_checks, fn {label, regex} ->
      contents
      |> lines()
      |> Enum.flat_map(fn {line, line_number} ->
        if Regex.match?(regex, line) and not negated?(line) do
          [
            failure(path, :forbidden_offline_authority,
              line: line_number,
              claim: line,
              detail: "remove stale offline-authority wording: #{label}"
            )
          ]
        else
          []
        end
      end)
    end)
  end

  defp negated?(line) do
    lowered = String.downcase(line)

    String.contains?(lowered, " not ") or
      String.contains?(lowered, " does not ") or
      String.contains?(lowered, " cannot ") or
      String.contains?(lowered, " never ") or
      String.contains?(lowered, " without ")
  end

  defp require_contains(path, contents, needle, category, detail) do
    if String.contains?(contents, needle) do
      []
    else
      [failure(path, category, detail: detail)]
    end
  end

  defp require_regex(path, contents, regex, category, detail) do
    if Regex.match?(regex, contents) do
      []
    else
      [failure(path, category, detail: detail)]
    end
  end

  defp line_number(contents, needle_or_regex) do
    contents
    |> lines()
    |> Enum.find_value(fn {line, line_number} ->
      cond do
        is_binary(needle_or_regex) and String.contains?(line, needle_or_regex) -> line_number
        is_struct(needle_or_regex, Regex) and Regex.match?(needle_or_regex, line) -> line_number
        true -> nil
      end
    end)
  end

  defp context_window(contents, needle, radius) do
    case :binary.match(contents, needle) do
      {index, length} ->
        start = max(index - radius, 0)
        stop = min(index + length + radius, byte_size(contents))
        binary_part(contents, start, stop - start)

      :nomatch ->
        ""
    end
  end

  defp lines(contents) do
    contents
    |> String.split("\n")
    |> Enum.with_index(1)
  end
end
