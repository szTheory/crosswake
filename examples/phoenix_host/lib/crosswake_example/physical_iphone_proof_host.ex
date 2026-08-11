defmodule CrosswakeExample.PhysicalIphoneProofHost do
  @moduledoc false

  alias Crosswake.ProofLane.{Config, Generator, PhysicalIphoneContract}
  alias CrosswakeExample.LocalFirst.PhysicalIphoneAuthority

  @host_root Path.expand("../..", __DIR__)
  @repo_root Path.expand("../..", @host_root)
  @ios_project Path.join([@host_root, "native", "ios", "CrosswakeProofLane.xcodeproj"])
  @ios_scheme "CrosswakeProofLane"
  @manifest Path.join(@host_root, ".crosswake/proof_lane.json")
  @evidence_parent Path.join([
                     @repo_root,
                     ".planning",
                     "phases",
                     "162-physical-iphone-adoption-proof",
                     "evidence"
                   ])
  @evidence_destination Path.join(@evidence_parent, "physical_iphone")
  @runtime_key {__MODULE__, :ios_runtime_line}
  @destination_key {__MODULE__, :physical_destination}
  @learning_bundle_root Path.join([
                          @host_root,
                          "native",
                          "ios",
                          "CrosswakeProofLane",
                          "Resources",
                          "ReferenceLearningBundle"
                        ])
  @learning_bundle_assets [
    {"manifest.json", 373, "64e9fa6e3e31e9d05b8ecad369750d654952fb15b4f5ac00cce4eee3867e21ca"},
    {"card-image.png", 924, "47b23c6102091d68642e1f0eb00414f1bb0d9780fe596685685173a6d77d0260"},
    {"pronunciation.aiff", 33_706,
     "5d8b3f72beb26205032d764bc7979f5658c7c9f262427bce2d814f2bf0fabf5b"}
  ]

  # Readiness is observation-only. It can inspect the selected destination,
  # signing inventory, host processes, and the absent fixed destination, but it
  # never builds, resets fixtures, runs tests, or creates evidence.
  def preflight_options do
    [
      inventory: reference_inventory(),
      config: Application.get_env(:crosswake, :proof_lane),
      generated_lane: &generated_lane?/0,
      destination: &destination_ready?/0,
      signing: &signing_ready?/0,
      host: &host_ready?/0,
      fixture_adapter: &fixture_adapter_ready?/0,
      media: &media_ready?/0,
      replay: &PhysicalIphoneAuthority.ready?/0,
      rejection_conflict: &PhysicalIphoneAuthority.ready?/0,
      scoped_session: &PhysicalIphoneAuthority.ready?/0,
      feature_controls: &PhysicalIphoneAuthority.ready?/0,
      destination_parent: &destination_parent_ready?/0
    ]
  end

  # The device report comes only from the generated XCTest executing on the
  # selected signed physical destination. Raw xcodebuild output stays in memory
  # and its private derived-data root is always removed.
  def device_report(%{schema_version: 1, device_class: :physical_iphone}) do
    with {:ok, destination} <- selected_physical_destination(),
         {:ok, team} <- development_team(),
         true <- codesigning_identity_ready?(),
         {:ok, root} <- private_run_root(),
         result <- safely_run_physical_xctest(root, destination, team),
         :ok <- remove_private_run_root(root),
         {:ok, report} <- result do
      Process.put(@runtime_key, destination.runtime_line)
      report
    else
      _ -> {:error, :unavailable}
    end
  rescue
    _ -> {:error, :unavailable}
  end

  def device_report(_), do: {:error, :unavailable}

  # Phoenix executes the backend authority cases independently from XCTest.
  def backend_report(contract), do: PhysicalIphoneAuthority.report(contract)

  # This callback constructs only the allowlisted input. Evidence remains the
  # sole validator and promoter, and the Mix task remains the sole caller.
  def evidence_input(%{
        outcome: "passed",
        schema_version: 1,
        device_class: "physical_iphone",
        assertions: assertions
      }) do
    with runtime when is_binary(runtime) <- Process.delete(@runtime_key),
         {:ok, runtime} <- PhysicalIphoneContract.ios_runtime_line(runtime),
         {:ok, complete_assertions} <- complete_assertions(assertions),
         {:ok, version} <- crosswake_version(),
         {:ok, template_version} <- template_version(),
         {:ok, commit_ref} <- commit_ref() do
      canonical_bytes =
        Jason.encode!(%{
          "schema_version" => PhysicalIphoneContract.schema_version(),
          "device_class" => "physical_iphone",
          "ios_runtime_line" => runtime,
          "outcome" => "passed",
          "assertions" =>
            Enum.map(complete_assertions, fn assertion ->
              %{
                "id" => assertion.id,
                "owner" => Atom.to_string(assertion.owner),
                "outcome" => "passed"
              }
            end)
        })

      %{
        schema_version: Integer.to_string(PhysicalIphoneContract.schema_version()),
        crosswake_version: version,
        template_version: Integer.to_string(template_version),
        commit_ref: commit_ref,
        route_id: "route-1630000000000001",
        assertion_ids: Enum.map(complete_assertions, & &1.id),
        status: :passed,
        outcome: :passed,
        captured_at: DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601(),
        retention_label: :brief,
        device_class: :physical_iphone,
        ios_runtime_line: runtime,
        approved_hashes: [
          %{kind: :physical_iphone_run_contract, canonical_bytes: canonical_bytes}
        ]
      }
    else
      _ -> {:error, :unavailable}
    end
  end

  def evidence_input(_), do: {:error, :unavailable}

  def destination do
    if destination_parent_ready?() == :ok, do: @evidence_destination, else: {:error, :unavailable}
  end

  defp generated_lane? do
    with {:ok, config} <- Config.normalize(Application.get_env(:crosswake, :proof_lane)),
         :ok <- Generator.check(config) do
      :ok
    else
      _ -> :blocked
    end
  end

  defp signing_ready? do
    with {:ok, _team} <- development_team(),
         true <- codesigning_identity_ready?() do
      :ok
    else
      _ -> :blocked
    end
  end

  defp host_ready? do
    if File.regular?(Path.join(@host_root, "mix.exs")) and
         PhysicalIphoneAuthority.ready?() == :ok,
       do: :ok,
       else: :blocked
  end

  defp fixture_adapter_ready? do
    if Enum.all?(@learning_bundle_assets, fn {name, _, _} ->
         File.regular?(Path.join(@learning_bundle_root, name))
       end),
       do: :ok,
       else: :blocked
  end

  defp media_ready? do
    if Enum.all?(@learning_bundle_assets, &asset_matches?/1), do: :ok, else: :blocked
  rescue
    _ -> :blocked
  end

  defp asset_matches?({name, size, digest}) do
    path = Path.join(@learning_bundle_root, name)

    with {:ok, bytes} <- File.read(path),
         true <- byte_size(bytes) == size,
         ^digest <- :crypto.hash(:sha256, bytes) |> Base.encode16(case: :lower) do
      true
    else
      _ -> false
    end
  end

  defp destination_ready? do
    case selected_physical_destination() do
      {:ok, _destination} -> {:ok, :physical_iphone}
      _ -> :blocked
    end
  end

  defp selected_physical_destination do
    case Process.get(@destination_key) do
      %{id: id, runtime_line: runtime_line} = destination
      when is_binary(id) and is_binary(runtime_line) ->
        {:ok, destination}

      _ ->
        discover_physical_destination()
    end
  end

  defp discover_physical_destination do
    with executable when is_binary(executable) <- System.find_executable("xcodebuild"),
         {output, 0} <-
           System.cmd(
             executable,
             ["-project", @ios_project, "-scheme", @ios_scheme, "-showdestinations"],
             stderr_to_stdout: true
           ),
         [id] <- parse_physical_destination_ids(output),
         {:ok, runtime_line} <- physical_runtime_line(id) do
      destination = %{id: id, runtime_line: runtime_line}
      Process.put(@destination_key, destination)
      {:ok, destination}
    else
      _ -> {:error, :unavailable}
    end
  end

  defp parse_physical_destination_ids(output) do
    ~r/\{ platform:iOS,.*?id:([^,}]+)/
    |> Regex.scan(output, capture: :all_but_first)
    |> Enum.map(fn [id] -> String.trim(id) end)
    |> Enum.filter(&String.match?(&1, ~r/^[0-9A-Fa-f-]{20,}$/))
    |> Enum.uniq()
  end

  defp physical_runtime_line(id) do
    with {bytes, 0} <- System.cmd("xcrun", ["xcdevice", "list"], stderr_to_stdout: true),
         {:ok, devices} when is_list(devices) <- Jason.decode(bytes),
         %{"operatingSystemVersion" => version} when is_binary(version) <-
           Enum.find(devices, fn
             %{"identifier" => ^id, "simulator" => false} -> true
             _ -> false
           end),
         [runtime_line] <- Regex.run(~r/^[0-9]+\.[0-9]+/, version) do
      PhysicalIphoneContract.ios_runtime_line(runtime_line)
    else
      _ -> {:error, :unavailable}
    end
  end

  defp development_team do
    case System.get_env("CROSSWAKE_IOS_DEVELOPMENT_TEAM") do
      value when is_binary(value) -> validate_team(value)
      _ -> xcode_development_team()
    end
  end

  defp xcode_development_team do
    with {plist, 0} <- System.cmd("defaults", ["export", "com.apple.dt.Xcode", "-"]),
         [array] <-
           Regex.run(
             ~r/<key>IDEProvisioningTeamIdentifiers<\/key>\s*<array>(.*?)<\/array>/s,
             plist,
             capture: :all_but_first
           ),
         [team] <-
           Regex.scan(~r/<string>([A-Z0-9]{10})<\/string>/, array, capture: :all_but_first)
           |> Enum.map(&hd/1)
           |> Enum.uniq() do
      validate_team(team)
    else
      _ -> {:error, :unavailable}
    end
  end

  defp validate_team(value) do
    value = String.trim(value)

    if String.match?(value, ~r/^[A-Z0-9]{10}$/),
      do: {:ok, value},
      else: {:error, :unavailable}
  end

  defp codesigning_identity_ready? do
    case System.cmd("security", ["find-identity", "-v", "-p", "codesigning"],
           stderr_to_stdout: true
         ) do
      {output, 0} ->
        not String.contains?(output, "0 valid identities found") and
          String.contains?(output, "valid identities found")

      _ ->
        false
    end
  end

  defp private_run_root do
    name =
      "crosswake-physical-" <> Base.url_encode64(:crypto.strong_rand_bytes(18), padding: false)

    root = Path.join(System.tmp_dir!(), name)

    with :ok <- File.mkdir(root),
         :ok <- File.chmod(root, 0o700) do
      {:ok, root}
    else
      _ -> {:error, :unavailable}
    end
  end

  defp run_physical_xctest(root, destination, team) do
    args = [
      "-project",
      @ios_project,
      "-scheme",
      @ios_scheme,
      "-destination",
      "id=#{destination.id}",
      "-derivedDataPath",
      Path.join(root, "DerivedData"),
      "-parallel-testing-enabled",
      "NO",
      "-only-testing:CrosswakeProofLaneUITests/ProofLaneUITests/testReferenceHostPhysicalStudyContract",
      "-allowProvisioningUpdates",
      "CODE_SIGNING_ALLOWED=YES",
      "CODE_SIGNING_REQUIRED=YES",
      "CODE_SIGN_STYLE=Automatic",
      "DEVELOPMENT_TEAM=#{team}",
      "test"
    ]

    env = [
      {"CROSSWAKE_PHYSICAL_IPHONE_CONTRACT_MODE", "1"},
      {"CROSSWAKE_REFERENCE_HOST_PHYSICAL_ADAPTER", "1"}
    ]

    case System.cmd("xcodebuild", args, env: env, stderr_to_stdout: true) do
      {output, 0} -> extract_device_report(output)
      _ -> {:error, :unavailable}
    end
  end

  defp safely_run_physical_xctest(root, destination, team) do
    run_physical_xctest(root, destination, team)
  rescue
    _ -> {:error, :unavailable}
  catch
    _, _ -> {:error, :unavailable}
  end

  defp extract_device_report(output) do
    output
    |> String.split("\n", trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.filter(&(String.starts_with?(&1, "{") and String.ends_with?(&1, "}")))
    |> Enum.filter(fn line ->
      match?(
        {:ok,
         %{
           "schema_version" => 1,
           "device_class" => "physical_iphone",
           "assertions" => _
         }},
        Jason.decode(line)
      )
    end)
    |> case do
      [report] -> {:ok, report}
      _ -> {:error, :unavailable}
    end
  end

  defp remove_private_run_root(root) do
    case File.rm_rf(root) do
      {:ok, _} -> :ok
      _ -> {:error, :unavailable}
    end
  end

  defp complete_assertions(assertions) when is_list(assertions) do
    expected =
      PhysicalIphoneContract.assertions()
      |> Enum.reject(&(&1.owner == :evidence_promotion))
      |> Enum.map(&Map.put(&1, :outcome, :passed))

    if assertions == expected do
      complete =
        expected ++
          [%{id: "PI-REDACTED-PROMOTION", owner: :evidence_promotion, outcome: :passed}]

      case PhysicalIphoneContract.validate_report(complete) do
        :ok -> {:ok, complete}
        _ -> {:error, :unavailable}
      end
    else
      {:error, :unavailable}
    end
  end

  defp complete_assertions(_), do: {:error, :unavailable}

  defp crosswake_version do
    case Application.spec(:crosswake, :vsn) do
      value when is_list(value) -> {:ok, List.to_string(value)}
      value when is_binary(value) -> {:ok, value}
      _ -> {:error, :unavailable}
    end
  end

  defp template_version do
    with {:ok, bytes} <- File.read(@manifest),
         {:ok, %{"template_version" => value}} when is_integer(value) <- Jason.decode(bytes) do
      {:ok, value}
    else
      _ -> {:error, :unavailable}
    end
  end

  defp commit_ref do
    case System.cmd("git", ["-C", @repo_root, "rev-parse", "HEAD"], stderr_to_stdout: true) do
      {value, 0} ->
        value = String.trim(value)

        if String.match?(value, ~r/^(?:[0-9a-f]{40}|[0-9a-f]{64})$/),
          do: {:ok, "git-" <> value},
          else: {:error, :unavailable}

      _ ->
        {:error, :unavailable}
    end
  end

  defp destination_parent_ready? do
    if File.dir?(@evidence_parent) and not File.exists?(@evidence_destination),
      do: :ok,
      else: :blocked
  end

  defp reference_inventory do
    [
      [
        route_id: "route-1630000000000001",
        path_pattern: "/study/session",
        runtime_owner: %{status: :confirmed_sanitized, value: :offline_island},
        offline_posture: %{status: :confirmed_sanitized, value: :local_first},
        mutation_categories: %{status: :confirmed_sanitized, value: [:answer_submission]},
        staleness_class: %{status: :confirmed_sanitized, value: :bounded},
        auth: %{status: :confirmed_sanitized, value: :authenticated},
        recent_auth: %{status: :confirmed_sanitized, value: :not_required},
        scope_posture: %{
          status: :confirmed_sanitized,
          value: %{
            scope: :opaque_partitioned,
            logout: :stops_replay,
            account_switch: :stops_replay
          }
        },
        media_requirement: %{
          status: :confirmed_sanitized,
          value: %{
            requirement: :required,
            size_band: :tiny,
            codec_family: :aac,
            integrity: :verified
          }
        },
        fallbacks: %{
          status: :confirmed_sanitized,
          value: %{
            online: :serve,
            offline: :queue_local,
            denied: :block,
            corrupt_pack: :block,
            disabled: :retain_and_block
          }
        },
        disablement: %{
          status: :confirmed_sanitized,
          value: %{entry: :server_enforced, replay: :server_reauthorized}
        },
        queued_data_retention: %{status: :confirmed_sanitized, value: :retain_until_resolution}
      ]
    ]
  end
end
