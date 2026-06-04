defmodule Crosswake.Proof.Phase65DiagnosticExportSeamTest do
  use ExUnit.Case, async: false

  alias Crosswake.TestSupport.ProofAssertions
  alias Crosswake.Shell.DiagnosticExport
  alias Crosswake.Bridge.Contract, as: BridgeContract
  alias Crosswake.SupportMatrix
  alias Crosswake.Doctor

  # ---------------------------------------------------------------------------
  # DIAG-01 — Fire-and-forget HTTP seam, not a bridge command; no HTTP dep
  #
  # (a) Bridge.Contract.commands/0 must have no "diagnostics.*" entry
  # (b) mix.exs + module source contain no Req/Finch/HTTPoison/Mint/:httpc ref
  # (c) DiagnosticExport.behaviour_info(:callbacks) includes {:export, 1}
  # ---------------------------------------------------------------------------

  @tag :diag_01
  test "Bridge.Contract.commands/0 has no diagnostics.* entry" do
    commands = BridgeContract.commands()

    refute Enum.any?(commands, &String.starts_with?(&1, "diagnostics")),
           ProofAssertions.stable_id_message(
             "proof.diag_01.bridge_commands.no_diagnostics",
             "Bridge.Contract.commands/0 must have no diagnostics.* entry",
             "Crosswake.Bridge.Contract.commands/0",
             "found diagnostics.* command in bridge vocabulary: #{Enum.filter(commands, &String.starts_with?(&1, "diagnostics")) |> inspect()}",
             "lib/crosswake/bridge/contract.ex",
             "diagnostics export is a fire-and-forget HTTP seam, NOT a bridge command (DIAG-01 D-04a)",
             :merge_blocking
           )
  end

  @tag :diag_01
  test "mix.exs deps contain no HTTP-client dependency (Req/Finch/HTTPoison/Mint/:httpc)" do
    source = File.read!(Path.expand("mix.exs", File.cwd!()))
    http_clients = ["Req", "Finch", "HTTPoison", "Mint", ":httpc"]

    for client <- http_clients do
      # Use string splitting to avoid matching our own assertion text
      # We check the deps section by looking for the dep declaration pattern
      refute String.contains?(source, "{:" <> String.downcase(client) <> ",") or
               String.contains?(source, "{:" <> String.downcase(client) <> " ,"),
             ProofAssertions.stable_id_message(
               "proof.diag_01.mix_exs.no_http_client.#{String.downcase(client)}",
               "mix.exs must not declare #{client} as a dependency",
               "mix.exs deps section",
               "found HTTP-client dep #{inspect(client)} in mix.exs",
               "mix.exs",
               "adding an HTTP client dep would introduce a first-party-service claim the library does not own (DIAG-01 D-03/D-04b)",
               :merge_blocking
             )
    end
  end

  @tag :diag_01
  test "DiagnosticExport module source contains no HTTP-client reference" do
    source =
      File.read!(
        Path.expand("lib/crosswake/shell/diagnostic_export.ex", File.cwd!())
      )

    http_clients = ["Req.", "Finch.", "HTTPoison.", "Mint.", ":httpc"]

    for client <- http_clients do
      refute String.contains?(source, client),
             ProofAssertions.stable_id_message(
               "proof.diag_01.module_source.no_http_client.#{client |> String.downcase() |> String.replace(".", "_")}",
               "DiagnosticExport module source must not reference #{client}",
               "lib/crosswake/shell/diagnostic_export.ex",
               "found HTTP-client reference #{inspect(client)} in module source",
               "lib/crosswake/shell/diagnostic_export.ex",
               "no Elixir HTTP-sending code ships in this module (DIAG-01 D-01/D-03)",
               :merge_blocking
             )
    end
  end

  @tag :diag_01
  test "DiagnosticExport.behaviour_info/1 exposes {:export, 1} callback" do
    callbacks = DiagnosticExport.behaviour_info(:callbacks)

    assert {:export, 1} in callbacks,
           ProofAssertions.stable_id_message(
             "proof.diag_01.behaviour_info.export_1",
             "DiagnosticExport.behaviour_info(:callbacks) must include {:export, 1}",
             "Crosswake.Shell.DiagnosticExport.behaviour_info(:callbacks)",
             "missing {:export, 1} in callbacks: #{inspect(callbacks)}",
             "lib/crosswake/shell/diagnostic_export.ex",
             "add @callback export(Envelope.t()) :: :ok | {:error, term()} to the module (DIAG-01 D-02)",
             :merge_blocking
           )
  end

  # ---------------------------------------------------------------------------
  # DIAG-02 — Typed versioned envelope + fixtures normalize
  #
  # - Closed-enum accessors return locked sets
  # - NativeDiagnostic has no :raw_payload key
  # - All six fixtures pass assert_normalized_json_fixture
  # ---------------------------------------------------------------------------

  @tag :diag_02
  test "DiagnosticExport.layers/0 returns [:native, :web, :bridge]" do
    assert DiagnosticExport.layers() == [:native, :web, :bridge],
           ProofAssertions.stable_id_message(
             "proof.diag_02.layers.exact_set",
             "DiagnosticExport.layers/0 must return [:native, :web, :bridge]",
             "Crosswake.Shell.DiagnosticExport.layers/0",
             "layers/0 returned #{inspect(DiagnosticExport.layers())}",
             "lib/crosswake/shell/diagnostic_export.ex",
             "layers enum must be locked to [:native, :web, :bridge] (DIAG-02 D-07)",
             :merge_blocking
           )
  end

  @tag :diag_02
  test "DiagnosticExport.platforms/0 returns [:ios, :android, :web]" do
    assert DiagnosticExport.platforms() == [:ios, :android, :web],
           ProofAssertions.stable_id_message(
             "proof.diag_02.platforms.exact_set",
             "DiagnosticExport.platforms/0 must return [:ios, :android, :web]",
             "Crosswake.Shell.DiagnosticExport.platforms/0",
             "platforms/0 returned #{inspect(DiagnosticExport.platforms())}",
             "lib/crosswake/shell/diagnostic_export.ex",
             "platforms enum must be locked to [:ios, :android, :web] (DIAG-02 D-07)",
             :merge_blocking
           )
  end

  @tag :diag_02
  test "DiagnosticExport.kinds/0 covers the required closed set" do
    kinds = DiagnosticExport.kinds()
    required = [:crash, :termination, :hang, :cpu, :bridge_fault, :web_fault]

    for kind <- required do
      assert kind in kinds,
             ProofAssertions.stable_id_message(
               "proof.diag_02.kinds.includes_#{kind}",
               "kinds/0 must include :#{kind}",
               "Crosswake.Shell.DiagnosticExport.kinds/0",
               "#{inspect(kind)} missing from kinds/0: #{inspect(kinds)}",
               "lib/crosswake/shell/diagnostic_export.ex",
               "kinds enum must cover crash/termination/hang/cpu/bridge_fault/web_fault (DIAG-02 D-08)",
               :merge_blocking
             )
    end
  end

  @tag :diag_02
  test "DiagnosticExport.sources/0 returns [:metrickit, :app_exit_info]" do
    assert DiagnosticExport.sources() == [:metrickit, :app_exit_info],
           ProofAssertions.stable_id_message(
             "proof.diag_02.sources.exact_set",
             "DiagnosticExport.sources/0 must return [:metrickit, :app_exit_info]",
             "Crosswake.Shell.DiagnosticExport.sources/0",
             "sources/0 returned #{inspect(DiagnosticExport.sources())}",
             "lib/crosswake/shell/diagnostic_export.ex",
             "sources enum must be locked to [:metrickit, :app_exit_info] (DIAG-02 D-09)",
             :merge_blocking
           )
  end

  @tag :diag_02
  test "DiagnosticExport.exit_reasons/0 covers the required closed set" do
    exit_reasons = DiagnosticExport.exit_reasons()
    required = [:crash, :anr, :low_memory, :user_requested, :hang, :cpu_resource_limit, :abnormal_exit, :other]

    for reason <- required do
      assert reason in exit_reasons,
             ProofAssertions.stable_id_message(
               "proof.diag_02.exit_reasons.includes_#{reason}",
               "exit_reasons/0 must include :#{reason}",
               "Crosswake.Shell.DiagnosticExport.exit_reasons/0",
               "#{inspect(reason)} missing from exit_reasons/0: #{inspect(exit_reasons)}",
               "lib/crosswake/shell/diagnostic_export.ex",
               "exit_reasons must span both iOS MetricKit and Android ApplicationExitInfo codes (DIAG-02 D-09)",
               :merge_blocking
             )
    end
  end

  @tag :diag_02
  test "NativeDiagnostic struct has no :raw_payload key" do
    nd_fields =
      %DiagnosticExport.NativeDiagnostic{source: :metrickit, exit_reason: :crash}
      |> Map.from_struct()
      |> Map.keys()

    refute :raw_payload in nd_fields,
           ProofAssertions.stable_id_message(
             "proof.diag_02.native_diagnostic.no_raw_payload",
             "NativeDiagnostic struct must not have a :raw_payload field",
             "Crosswake.Shell.DiagnosticExport.NativeDiagnostic",
             ":raw_payload is present in NativeDiagnostic fields: #{inspect(nd_fields)}",
             "lib/crosswake/shell/diagnostic_export.ex",
             "opaque raw_payload passthrough could smuggle PII/tokens — redaction wins (DIAG-02 D-13)",
             :merge_blocking
           )
  end

  @tag :diag_02
  test "fixture native_ios_crash normalizes against to_map/1 output" do
    {:ok, nd} = DiagnosticExport.new_native_diagnostic(%{source: :metrickit, exit_reason: :crash})

    json =
      DiagnosticExport.new_envelope!(%{
        schema_version: DiagnosticExport.schema_version(),
        layer: :native,
        platform: :ios,
        kind: :crash,
        native_runtime_version: "1.0.0",
        correlation_id: "phase65-fixture-native-ios-crash",
        observed_at: "2026-06-04T00:00:00Z",
        native_diagnostic: nd
      })
      |> DiagnosticExport.to_map()
      |> Jason.encode!()

    ProofAssertions.assert_normalized_json_fixture(
      "proof.diag_02.fixture.native_ios_crash",
      json,
      "test/fixtures/diagnostic/native_ios_crash.json",
      source: "DiagnosticExport.to_map/1",
      hint: "regenerate fixture from to_map/1 if envelope schema changed (DIAG-02 D-10)",
      posture: :merge_blocking
    )
  end

  @tag :diag_02
  test "fixture native_ios_metrickit_hang normalizes against to_map/1 output" do
    {:ok, nd} = DiagnosticExport.new_native_diagnostic(%{source: :metrickit, exit_reason: :hang})

    json =
      DiagnosticExport.new_envelope!(%{
        schema_version: DiagnosticExport.schema_version(),
        layer: :native,
        platform: :ios,
        kind: :hang,
        native_runtime_version: "1.0.0",
        correlation_id: "phase65-fixture-native-ios-metrickit-hang",
        observed_at: "2026-06-04T00:00:00Z",
        native_diagnostic: nd
      })
      |> DiagnosticExport.to_map()
      |> Jason.encode!()

    ProofAssertions.assert_normalized_json_fixture(
      "proof.diag_02.fixture.native_ios_metrickit_hang",
      json,
      "test/fixtures/diagnostic/native_ios_metrickit_hang.json",
      source: "DiagnosticExport.to_map/1",
      hint: "regenerate fixture from to_map/1 if envelope schema changed (DIAG-02 D-10)",
      posture: :merge_blocking
    )
  end

  @tag :diag_02
  test "fixture native_android_anr normalizes against to_map/1 output" do
    {:ok, nd} = DiagnosticExport.new_native_diagnostic(%{source: :app_exit_info, exit_reason: :anr})

    json =
      DiagnosticExport.new_envelope!(%{
        schema_version: DiagnosticExport.schema_version(),
        layer: :native,
        platform: :android,
        kind: :hang,
        native_runtime_version: "1.0.0",
        correlation_id: "phase65-fixture-native-android-anr",
        observed_at: "2026-06-04T00:00:00Z",
        native_diagnostic: nd
      })
      |> DiagnosticExport.to_map()
      |> Jason.encode!()

    ProofAssertions.assert_normalized_json_fixture(
      "proof.diag_02.fixture.native_android_anr",
      json,
      "test/fixtures/diagnostic/native_android_anr.json",
      source: "DiagnosticExport.to_map/1",
      hint: "regenerate fixture from to_map/1 if envelope schema changed (DIAG-02 D-10)",
      posture: :merge_blocking
    )
  end

  @tag :diag_02
  test "fixture native_android_low_memory normalizes against to_map/1 output" do
    {:ok, nd} =
      DiagnosticExport.new_native_diagnostic(%{source: :app_exit_info, exit_reason: :low_memory})

    json =
      DiagnosticExport.new_envelope!(%{
        schema_version: DiagnosticExport.schema_version(),
        layer: :native,
        platform: :android,
        kind: :termination,
        native_runtime_version: "1.0.0",
        correlation_id: "phase65-fixture-native-android-low-memory",
        observed_at: "2026-06-04T00:00:00Z",
        native_diagnostic: nd
      })
      |> DiagnosticExport.to_map()
      |> Jason.encode!()

    ProofAssertions.assert_normalized_json_fixture(
      "proof.diag_02.fixture.native_android_low_memory",
      json,
      "test/fixtures/diagnostic/native_android_low_memory.json",
      source: "DiagnosticExport.to_map/1",
      hint: "regenerate fixture from to_map/1 if envelope schema changed (DIAG-02 D-10)",
      posture: :merge_blocking
    )
  end

  @tag :diag_02
  test "fixture web_liveview_fault normalizes against to_map/1 output" do
    json =
      DiagnosticExport.new_envelope!(%{
        schema_version: DiagnosticExport.schema_version(),
        layer: :web,
        platform: :web,
        kind: :web_fault,
        native_runtime_version: "1.0.0",
        correlation_id: "phase65-fixture-web-liveview-fault",
        observed_at: "2026-06-04T00:00:00Z"
      })
      |> DiagnosticExport.to_map()
      |> Jason.encode!()

    ProofAssertions.assert_normalized_json_fixture(
      "proof.diag_02.fixture.web_liveview_fault",
      json,
      "test/fixtures/diagnostic/web_liveview_fault.json",
      source: "DiagnosticExport.to_map/1",
      hint: "regenerate fixture from to_map/1 if envelope schema changed (DIAG-02 D-10)",
      posture: :merge_blocking
    )
  end

  @tag :diag_02
  test "fixture bridge_command_fault normalizes against to_map/1 output" do
    json =
      DiagnosticExport.new_envelope!(%{
        schema_version: DiagnosticExport.schema_version(),
        layer: :bridge,
        platform: :ios,
        kind: :bridge_fault,
        native_runtime_version: "1.0.0",
        correlation_id: "phase65-fixture-bridge-command-fault",
        observed_at: "2026-06-04T00:00:00Z"
      })
      |> DiagnosticExport.to_map()
      |> Jason.encode!()

    ProofAssertions.assert_normalized_json_fixture(
      "proof.diag_02.fixture.bridge_command_fault",
      json,
      "test/fixtures/diagnostic/bridge_command_fault.json",
      source: "DiagnosticExport.to_map/1",
      hint: "regenerate fixture from to_map/1 if envelope schema changed (DIAG-02 D-10)",
      posture: :merge_blocking
    )
  end

  # ---------------------------------------------------------------------------
  # DIAG-03 — forbidden_keys/0 ⟂ allowed_keys/0 + fail-closed sanitize/1
  #
  # - All 19 forbidden keys in forbidden_keys/0
  # - None of the 19 forbidden keys in allowed_keys/0
  # - sanitize/1 round-trip {:ok, _} for valid native-iOS-crash attrs
  # - sanitize/1 returns {:error, :redaction_failed} on forbidden key injection
  # - sanitize/1 returns {:error, :redaction_failed} on out-of-enum layer
  # - sanitize/1 returns {:error, :redaction_failed} on non-map input
  # ---------------------------------------------------------------------------

  @forbidden_keys_canonical [
    :token,
    :raw_token,
    :device_token,
    :registration_token,
    :apns_token,
    :fcm_token,
    :provider_payload,
    :raw_payload,
    :notification_title,
    :notification_body,
    :route_params,
    :actor_id,
    :subject_ref,
    :session_ref,
    :device_id,
    :ip,
    :user_agent,
    :email,
    :provider_response_body
  ]

  @tag :diag_03
  test "all 19 canonical forbidden keys are in DiagnosticExport.forbidden_keys/0" do
    forbidden = DiagnosticExport.forbidden_keys()

    for key <- @forbidden_keys_canonical do
      assert key in forbidden,
             ProofAssertions.stable_id_message(
               "proof.diag_03.forbidden_keys.contains_#{key}",
               "forbidden_keys/0 must include :#{key}",
               "Crosswake.Shell.DiagnosticExport.forbidden_keys/0",
               ":#{key} missing from forbidden_keys/0",
               "lib/crosswake/shell/diagnostic_export.ex",
               "all 19 forbidden keys must be present in the forbidden set (DIAG-03 D-15)",
               :merge_blocking
             )
    end
  end

  @tag :diag_03
  test "none of the 19 canonical forbidden keys are in DiagnosticExport.allowed_keys/0" do
    allowed = DiagnosticExport.allowed_keys()

    for key <- @forbidden_keys_canonical do
      refute key in allowed,
             ProofAssertions.stable_id_message(
               "proof.diag_03.allowed_keys.excludes_#{key}",
               "allowed_keys/0 must NOT include :#{key}",
               "Crosswake.Shell.DiagnosticExport.allowed_keys/0",
               ":#{key} found in allowed_keys/0 — forbidden and allowed sets overlap",
               "lib/crosswake/shell/diagnostic_export.ex",
               "forbidden keys must never appear in the allowed set (DIAG-03 D-15)",
               :merge_blocking
             )
    end
  end

  @tag :diag_03
  test "sanitize/1 round-trip returns {:ok, %Envelope{}} for valid native-iOS-crash attrs" do
    valid_attrs = %{
      schema_version: "1",
      layer: :native,
      platform: :ios,
      kind: :crash,
      native_runtime_version: "1.0.0",
      correlation_id: "phase65-sanitize-roundtrip",
      observed_at: "2026-06-04T00:00:00Z"
    }

    result = DiagnosticExport.sanitize(valid_attrs)

    assert match?({:ok, %DiagnosticExport.Envelope{}}, result),
           ProofAssertions.stable_id_message(
             "proof.diag_03.sanitize.valid_roundtrip",
             "sanitize/1 must return {:ok, %Envelope{}} for valid native-iOS-crash attrs",
             "Crosswake.Shell.DiagnosticExport.sanitize/1",
             "sanitize/1 returned #{inspect(result)} for valid attrs",
             "lib/crosswake/shell/diagnostic_export.ex",
             "fail-closed sanitize must accept valid typed inputs (DIAG-03 D-14)",
             :merge_blocking
           )
  end

  @tag :diag_03
  test "sanitize/1 returns {:error, :redaction_failed} when a forbidden key is injected" do
    for key <- @forbidden_keys_canonical do
      base_attrs = %{
        schema_version: "1",
        layer: :native,
        platform: :ios,
        kind: :crash,
        native_runtime_version: "1.0.0",
        correlation_id: "phase65-sanitize-forbidden",
        observed_at: "2026-06-04T00:00:00Z"
      }

      attrs_with_forbidden = Map.put(base_attrs, key, "injected")

      result = DiagnosticExport.sanitize(attrs_with_forbidden)

      assert result == {:error, :redaction_failed},
             ProofAssertions.stable_id_message(
               "proof.diag_03.sanitize.rejects_forbidden_key_#{key}",
               "sanitize/1 must return {:error, :redaction_failed} when :#{key} is injected",
               "Crosswake.Shell.DiagnosticExport.sanitize/1",
               "sanitize/1 returned #{inspect(result)} — should have rejected forbidden key :#{key}",
               "lib/crosswake/shell/diagnostic_export.ex",
               "fail-closed: any forbidden key must be rejected at sanitize boundary (DIAG-03 D-14)",
               :merge_blocking
             )
    end
  end

  @tag :diag_03
  test "sanitize/1 returns {:error, :redaction_failed} for out-of-enum layer value" do
    invalid_layer_attrs = %{
      schema_version: "1",
      layer: :unknown_layer,
      platform: :ios,
      kind: :crash,
      native_runtime_version: "1.0.0",
      correlation_id: "phase65-sanitize-bad-layer",
      observed_at: "2026-06-04T00:00:00Z"
    }

    result = DiagnosticExport.sanitize(invalid_layer_attrs)

    assert result == {:error, :redaction_failed},
           ProofAssertions.stable_id_message(
             "proof.diag_03.sanitize.rejects_out_of_enum_layer",
             "sanitize/1 must return {:error, :redaction_failed} for out-of-enum layer",
             "Crosswake.Shell.DiagnosticExport.sanitize/1",
             "sanitize/1 returned #{inspect(result)} for layer: :unknown_layer",
             "lib/crosswake/shell/diagnostic_export.ex",
             "fail-closed: out-of-enum values must be rejected (DIAG-03 D-14)",
             :merge_blocking
           )
  end

  @tag :diag_03
  test "sanitize/1 returns {:error, :redaction_failed} for non-map input" do
    for input <- ["a string", 42, :an_atom, nil, [key: "value"]] do
      result = DiagnosticExport.sanitize(input)

      assert result == {:error, :redaction_failed},
             ProofAssertions.stable_id_message(
               "proof.diag_03.sanitize.rejects_non_map",
               "sanitize/1 must return {:error, :redaction_failed} for non-map input",
               "Crosswake.Shell.DiagnosticExport.sanitize/1",
               "sanitize/1 returned #{inspect(result)} for non-map input #{inspect(input)}",
               "lib/crosswake/shell/diagnostic_export.ex",
               "fail-closed: non-map input must be rejected (DIAG-03 D-14)",
               :merge_blocking
             )
    end
  end

  # ---------------------------------------------------------------------------
  # DIAG-04 — Support-truth + advisory doctor readiness present + non-overclaiming
  #
  # - diagnostic_export_support_truth/0 is non-empty
  # - delivery_supported == false
  # - deferred contains the 3 required atoms
  # - telemetry.authority_source == :host_configured_endpoint
  # - posture contains "not a crash-reporting service"
  # - Doctor.run([]) findings include exactly one "diagnostic_export.contract_shipped" with severity :advisory
  # - That finding's message does NOT contain "crash-reporting service"
  # ---------------------------------------------------------------------------

  @tag :diag_04
  test "SupportMatrix.diagnostic_export_support_truth/0 is non-empty" do
    truth = SupportMatrix.diagnostic_export_support_truth()

    assert is_list(truth) and length(truth) > 0,
           ProofAssertions.stable_id_message(
             "proof.diag_04.support_truth.non_empty",
             "diagnostic_export_support_truth/0 must be a non-empty list",
             "Crosswake.SupportMatrix.diagnostic_export_support_truth/0",
             "returned empty list or non-list: #{inspect(truth)}",
             "lib/crosswake/support_matrix/support_matrix.ex",
             "add @diagnostic_export_support_truth attribute with at least one entry (DIAG-04 D-16)",
             :merge_blocking
           )
  end

  @tag :diag_04
  test "diagnostic_export_support_truth/0 entry has delivery_supported == false" do
    [entry | _] = SupportMatrix.diagnostic_export_support_truth()

    assert entry.delivery_supported == false,
           ProofAssertions.stable_id_message(
             "proof.diag_04.support_truth.delivery_supported_false",
             "diagnostic_export_support_truth entry must have delivery_supported: false",
             "Crosswake.SupportMatrix.diagnostic_export_support_truth/0",
             "delivery_supported is #{inspect(entry.delivery_supported)}, expected false",
             "lib/crosswake/support_matrix/support_matrix.ex",
             "native MetricKit/ApplicationExitInfo delivery is not shipped until Phase 67 (DIAG-04 D-16/D-17)",
             :merge_blocking
           )
  end

  @tag :diag_04
  test "diagnostic_export_support_truth/0 entry deferred contains the 3 required atoms" do
    [entry | _] = SupportMatrix.diagnostic_export_support_truth()
    required_deferred = [:native_diagnostic_export, :metrickit_capture, :application_exit_info_capture]

    for atom <- required_deferred do
      assert atom in entry.deferred,
             ProofAssertions.stable_id_message(
               "proof.diag_04.support_truth.deferred.includes_#{atom}",
               "diagnostic_export_support_truth entry must have :#{atom} in deferred",
               "Crosswake.SupportMatrix.diagnostic_export_support_truth/0",
               ":#{atom} missing from deferred: #{inspect(entry.deferred)}",
               "lib/crosswake/support_matrix/support_matrix.ex",
               "all three native-transport deferred atoms must be declared (DIAG-04 D-16)",
               :merge_blocking
             )
    end
  end

  @tag :diag_04
  test "diagnostic_export_support_truth/0 entry telemetry.authority_source == :host_configured_endpoint" do
    [entry | _] = SupportMatrix.diagnostic_export_support_truth()
    authority_source = get_in(entry, [:telemetry, :authority_source])

    assert authority_source == :host_configured_endpoint,
           ProofAssertions.stable_id_message(
             "proof.diag_04.support_truth.authority_source",
             "diagnostic_export_support_truth telemetry.authority_source must be :host_configured_endpoint",
             "Crosswake.SupportMatrix.diagnostic_export_support_truth/0",
             "authority_source is #{inspect(authority_source)}, expected :host_configured_endpoint",
             "lib/crosswake/support_matrix/support_matrix.ex",
             "the host owns the endpoint and data — authority_source must reflect this (DIAG-04 D-16/D-17)",
             :merge_blocking
           )
  end

  @tag :diag_04
  test "diagnostic_export_support_truth/0 entry posture contains 'not a crash-reporting service'" do
    [entry | _] = SupportMatrix.diagnostic_export_support_truth()

    assert String.contains?(entry.posture, "not a crash-reporting service"),
           ProofAssertions.stable_id_message(
             "proof.diag_04.support_truth.posture.no_overclaim",
             "diagnostic_export_support_truth posture must contain 'not a crash-reporting service'",
             "Crosswake.SupportMatrix.diagnostic_export_support_truth/0",
             "posture does not contain 'not a crash-reporting service': #{inspect(entry.posture)}",
             "lib/crosswake/support_matrix/support_matrix.ex",
             "the posture must draw the seam: host owns data, Crosswake is NOT a crash-reporting service (DIAG-04 D-17)",
             :merge_blocking
           )
  end

  @tag :diag_04
  test "Doctor.run/1 findings include exactly one diagnostic_export.contract_shipped advisory finding" do
    report =
      Doctor.run(
        route_source: Crosswake.TestSupport.RouterFixtures.ManagedRouter,
        install_manifest_path: "priv/crosswake/install_manifest.json",
        cwd: File.cwd!()
      )

    matching_findings =
      Enum.filter(
        report.findings,
        &(&1.code == "diagnostic_export.contract_shipped")
      )

    assert length(matching_findings) == 1,
           ProofAssertions.stable_id_message(
             "proof.diag_04.doctor.contract_shipped_exactly_once",
             "Doctor.run/1 findings must include exactly one diagnostic_export.contract_shipped",
             "Crosswake.Doctor.run/1",
             "found #{length(matching_findings)} matching findings (expected exactly 1)",
             "lib/crosswake/doctor/doctor.ex",
             "add the diagnostic_export.contract_shipped advisory check in phase_65_diagnostic_export_findings/0 (DIAG-04 D-18)",
             :merge_blocking
           )

    [finding] = matching_findings

    assert finding.severity == :advisory,
           ProofAssertions.stable_id_message(
             "proof.diag_04.doctor.contract_shipped_severity_advisory",
             "diagnostic_export.contract_shipped finding severity must be :advisory",
             "Crosswake.Doctor.run/1 finding code=diagnostic_export.contract_shipped",
             "severity is #{inspect(finding.severity)}, expected :advisory",
             "lib/crosswake/doctor/doctor.ex",
             "no config is actionable in Phase 65 — finding is informational evidence only (DIAG-04 D-18)",
             :merge_blocking
           )
  end

  @tag :diag_04
  test "diagnostic_export.contract_shipped finding message does not contain 'crash-reporting service'" do
    report =
      Doctor.run(
        route_source: Crosswake.TestSupport.RouterFixtures.ManagedRouter,
        install_manifest_path: "priv/crosswake/install_manifest.json",
        cwd: File.cwd!()
      )

    finding =
      Enum.find(report.findings, &(&1.code == "diagnostic_export.contract_shipped"))

    assert finding != nil,
           "diagnostic_export.contract_shipped finding must be present in Doctor.run/1 output"

    refute String.contains?(finding.message, "crash-reporting service"),
           ProofAssertions.stable_id_message(
             "proof.diag_04.doctor.message_no_overclaim",
             "diagnostic_export.contract_shipped finding message must not contain 'crash-reporting service'",
             "Crosswake.Doctor.run/1 finding code=diagnostic_export.contract_shipped",
             "finding message overclaims 'crash-reporting service': #{inspect(finding.message)}",
             "lib/crosswake/doctor/doctor.ex",
             "the finding message must not imply Crosswake is a crash-reporting service (DIAG-04 D-17/D-18)",
             :merge_blocking
           )
  end

  # ---------------------------------------------------------------------------
  # Hermetic lane guard
  #
  # This file must NOT carry @moduletag, must have no example-host references,
  # and must have no env-flag references (hermetic, env-independent).
  # ---------------------------------------------------------------------------

  test "hermetic lane guard: no @moduletag and no example-host or env-flag references in phase65 proof lane" do
    source = File.read!(__ENV__.file)

    refute Regex.match?(~r/^\s*@moduletag\s+:/m, source),
           "phase65 proof lane must not carry any @moduletag — it is hermetic"

    refute String.contains?(source, "Crosswake" <> "Example."),
           "phase65 proof lane must not reference example-host modules"

    refute String.contains?(source, "MIX_" <> "INCLUDE_"),
           "phase65 proof lane must not reference " <> "MIX_" <> "INCLUDE_* env flags"
  end
end
