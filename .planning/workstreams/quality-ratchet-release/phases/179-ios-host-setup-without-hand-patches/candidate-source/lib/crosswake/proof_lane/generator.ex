defmodule Crosswake.ProofLane.Generator do
  @moduledoc "Renders a host-owned proof lane with atomic, missing-only writes."

  alias Crosswake.ProofLane.{Config, GeneratorFS}
  alias Crosswake.Shell.{IOSHostConfig, IOSHostProjectMigration}

  @schema_version 1
  @template_version 6
  @templates [
    {"test/crosswake_proof_lane/crosswake_proof_lane_test.exs",
     "test/crosswake_proof_lane_test.exs.eex"},
    {"e2e/crosswake_proof_lane/proof_lane.spec.ts", "e2e/proof_lane.spec.ts.eex"},
    {"e2e/crosswake_proof_lane/support/proof_lane.ts", "e2e/support/proof_lane.ts.eex"},
    {"e2e/crosswake_proof_lane/support/proof_lane_host_adapter.ts",
     "e2e/support/proof_lane_host_adapter.ts.eex"},
    {"physical_iphone/physical_iphone_proof_host.ex",
     "physical_iphone/physical_iphone_proof_host.ex.eex"},
    {"CrosswakeProofLane/ProofLaneDriver.swift", "ios/ProofLaneDriver.swift.eex"},
    {"CrosswakeProofLane/ProofLaneApp.swift", "ios/ProofLaneApp.swift.eex"},
    {"CrosswakeProofLane/Resources/pronunciation-pack-fixture.bin",
     "ios/Resources/pronunciation-pack-fixture.bin.eex"},
    {"CrosswakeProofLaneTests/ProofLaneContractTests.swift",
     "ios/CrosswakeProofLaneTests/ProofLaneContractTests.swift.eex"},
    {"CrosswakeProofLaneUITests/ProofLaneUITests.swift",
     "ios/CrosswakeProofLaneUITests/ProofLaneUITests.swift.eex"},
    {"CrosswakeProofLane.xcodeproj/project.pbxproj",
     "ios/CrosswakeProofLane.xcodeproj/project.pbxproj.eex"},
    {"CrosswakeProofLane.xcodeproj/xcshareddata/xcschemes/CrosswakeProofLane.xcscheme",
     "ios/CrosswakeProofLane.xcodeproj/xcshareddata/xcschemes/CrosswakeProofLane.xcscheme.eex"}
  ]

  @type finding :: %{rule_id: String.t(), path: String.t(), remediation: String.t()}
  @type diff_entry :: %{path: String.t(), status: :missing | :different | :current}

  @spec generate(Config.t(), term()) ::
          {:ok, [%{path: String.t(), status: :created | :reused}]}
          | {:error, {String.t(), String.t()}}
  def generate(%Config{} = config, host_config \\ nil) do
    config = normalize!(config)
    host_config = normalize_host!(host_config)
    root = host_root!(config)
    desired = desired(config, host_config)

    GeneratorFS.with_lifecycle(fn ->
      :global.trans({{__MODULE__, root}, self()}, fn ->
        with :ok <- preflight_destinations(root, desired),
             {:ok, results} <- ensure_files(root, desired),
             :ok <- interrupt_before_manifest(),
             {:ok, manifest_result} <- ensure_manifest(root, desired) do
          {:ok, Enum.sort_by(results ++ [manifest_result], & &1.path)}
        end
      end)
    end)
  end

  @spec recover(Config.t()) :: {:ok, :recovered} | {:error, {String.t(), String.t()}}
  def recover(%Config{} = config) do
    config = normalize!(config)
    root = host_root!(config)

    GeneratorFS.with_lifecycle(fn ->
      :global.trans({{__MODULE__, root}, self()}, fn -> recover_managed_settings(root) end)
    end)
  end

  def migrate_project_settings(%Config{} = config, opts \\ []) do
    config = normalize!(config)
    root = host_root!(config)
    relative = "native/ios/CrosswakeProofLane.xcodeproj/project.pbxproj"

    GeneratorFS.with_lifecycle(fn ->
      :global.trans({{__MODULE__, root}, self()}, fn ->
        with :ok <- no_settings_recovery(root),
             {:ok, bytes} <- GeneratorFS.read(root, relative),
             {:ok, preview} <- IOSHostProjectMigration.preview_proof_contents(bytes),
             :ok <-
               maybe_apply_project_migration(
                 root,
                 relative,
                 bytes,
                 preview.contents,
                 opts
               ) do
          {:ok, preview}
        else
          {:error, :unsafe} ->
            {:error, {"PL-GENERATE-DESTINATION", "proof project"}}

          {:error, :missing} ->
            {:error, {"PL-GENERATE-MISSING", "proof project"}}

          {:error, {rule, path}} when is_binary(rule) and is_binary(path) ->
            {:error, {rule, path}}

          _ ->
            {:error, {"PL-GENERATE-MIGRATION", "proof project"}}
        end
      end)
    end)
  end

  @spec check(Config.t(), term()) :: :ok | {:error, [finding()]}
  def check(%Config{} = config, host_config \\ nil) do
    config = normalize!(config)
    host_config = normalize_host!(host_config)
    root = host_root!(config)
    desired = desired(config, host_config)

    GeneratorFS.with_lifecycle(fn ->
      findings =
        missing_findings(root, desired) ++
          managed_settings_findings(root) ++
          manifest_findings(root, desired)

      case findings |> Enum.uniq() |> Enum.sort_by(& &1.path) do
        [] -> :ok
        findings -> {:error, findings}
      end
    end)
  end

  @spec diff(Config.t(), term()) :: [diff_entry()]
  def diff(%Config{} = config, host_config \\ nil) do
    config = normalize!(config)
    host_config = normalize_host!(host_config)
    root = host_root!(config)
    desired = desired(config, host_config)

    GeneratorFS.with_lifecycle(fn ->
      desired
      |> Kernel.++([manifest_desired(desired)])
      |> Enum.map(fn %{path: path, relative: relative, contents: contents} ->
        status =
          case GeneratorFS.read(root, relative) do
            {:ok, ^contents} -> :current
            {:ok, _} -> :different
            _ -> :missing
          end

        %{path: path, status: status}
      end)
      |> Enum.sort_by(& &1.path)
    end)
  end

  defp desired(config, host_config) do
    proof_app_bundle_id =
      if host_config, do: host_config.proof_app_bundle_id, else: "dev.crosswake.prooflane"

    device_signing =
      if host_config, do: host_config.device_signing, else: %{mode: :automatic, team_id: ""}

    templates = [
      {"CrosswakeProofSettings.xcconfig", "ios/CrosswakeProofSettings.xcconfig.eex"} | @templates
    ]

    Enum.map(templates, fn {relative, template} ->
      %{
        path: relative,
        relative: destination_relative(relative),
        contents: render(template, config, proof_app_bundle_id, device_signing)
      }
    end)
  end

  defp preflight_destinations(root, desired) do
    settings = Enum.find(desired, &(&1.path == "CrosswakeProofSettings.xcconfig"))
    all_destinations = desired ++ [manifest_desired(desired)]

    with :ok <- preflight_files(root, all_destinations),
         {:ok, _prior} <- managed_prior(root, settings.relative),
         :ok <- no_settings_recovery(root) do
      :ok
    else
      :unrecognized -> {:error, {"PL-GENERATE-OWNERSHIP", settings.path}}
      :regular -> {:error, {"PL-GENERATE-INTERRUPTED", "settings"}}
      :unsafe -> {:error, {"PL-GENERATE-DESTINATION", "settings"}}
      {:error, _} = error -> error
    end
  end

  defp preflight_files(root, destinations) do
    Enum.reduce_while(destinations, :ok, fn %{path: path, relative: relative}, :ok ->
      case GeneratorFS.status(root, relative) do
        status when status in [:regular, :missing] -> {:cont, :ok}
        :unsafe -> {:halt, {:error, {"PL-GENERATE-DESTINATION", path}}}
      end
    end)
  end

  defp ensure_files(root, desired) do
    Enum.reduce_while(desired, {:ok, []}, fn entry, {:ok, results} ->
      result =
        if entry.path == "CrosswakeProofSettings.xcconfig",
          do: ensure_managed_settings(root, entry.relative, entry.contents, entry.path),
          else: ensure_missing(root, entry.relative, entry.contents, entry.path)

      case result do
        {:ok, result} -> {:cont, {:ok, [result | results]}}
        {:error, _} = error -> {:halt, error}
      end
    end)
  end

  defp ensure_manifest(root, desired) do
    manifest = manifest_desired(desired)

    case GeneratorFS.read(root, manifest.relative) do
      {:ok, _} ->
        {:ok, %{path: manifest.path, status: :reused}}

      {:error, :missing} ->
        ensure_missing(root, manifest.relative, manifest.contents, manifest.path)

      {:error, :unsafe} ->
        {:error, {"PL-GENERATE-DESTINATION", manifest.path}}
    end
  end

  defp ensure_missing(root, relative, contents, relative_path) do
    case GeneratorFS.write(root, relative, contents) do
      {:ok, status} -> {:ok, %{path: relative_path, status: status}}
      {:error, _} = error -> error
    end
  end

  defp ensure_managed_settings(root, relative, contents, display_path) do
    pending = "native/ios/.crosswake/ios_proof_settings.pending"
    stage = "native/ios/.crosswake/ios_proof_settings.stage.json"
    temp = "native/ios/.crosswake/ios_proof_settings.next"

    with :ok <- no_settings_recovery(root),
         {:ok, prior} <- managed_prior(root, relative),
         :ok <- publish_managed_settings(root, relative, contents, pending, stage, temp, prior) do
      {:ok, %{path: display_path, status: if(is_nil(prior), do: :created, else: :reused)}}
    else
      :regular -> {:error, {"PL-GENERATE-INTERRUPTED", "settings"}}
      :unsafe -> {:error, {"PL-GENERATE-DESTINATION", display_path}}
      {:error, _} = error -> error
      :unrecognized -> {:error, {"PL-GENERATE-OWNERSHIP", display_path}}
      other -> {:error, {"PL-GENERATE-WRITE", display_path <> ":" <> inspect(other)}}
    end
  end

  defp managed_prior(root, relative) do
    case GeneratorFS.read(root, relative) do
      {:error, :missing} ->
        {:ok, nil}

      {:error, :unsafe} ->
        {:error, {"PL-GENERATE-DESTINATION", relative}}

      {:ok, prior} ->
        case managed_body(prior) do
          {:ok, _body} -> {:ok, prior}
          :error -> :unrecognized
        end
    end
  end

  defp publish_managed_settings(root, relative, contents, pending, stage, temp, prior) do
    with :ok <- write_stage(root, stage, prior, contents),
         {:ok, _} <- GeneratorFS.write(root, pending, "crosswake proof settings update pending\n"),
         {:ok, _} <- GeneratorFS.write(root, temp, contents),
         :ok <- replace_regular(root, temp, relative),
         true <- GeneratorFS.read(root, relative) == {:ok, contents},
         false <- Process.get(:crosswake_proof_settings_interrupt_after_publish, false),
         :ok <- remove_regular(root, pending),
         :ok <- remove_regular(root, stage) do
      :ok
    else
      true -> {:error, {"PL-GENERATE-INTERRUPTED", "settings"}}
      false -> {:error, {"PL-GENERATE-INTERRUPTED", "settings"}}
      {:error, _} = error -> error
      _ -> {:error, {"PL-GENERATE-INTERRUPTED", "settings"}}
    end
  end

  defp write_stage(root, stage, prior, desired) do
    payload = %{
      "version" => 2,
      "prior" => if(is_binary(prior), do: Base.encode64(prior), else: nil),
      "desired" => Base.encode64(desired)
    }

    case GeneratorFS.write(root, stage, Jason.encode!(payload)) do
      {:ok, :created} -> :ok
      {:ok, :reused} -> {:error, {"PL-GENERATE-INTERRUPTED", "settings"}}
      {:error, _} = error -> error
    end
  end

  defp replace_regular(root, temp, relative) do
    with :regular <- GeneratorFS.status(root, temp),
         status when status in [:regular, :missing] <- GeneratorFS.status(root, relative),
         :ok <- File.rename(Path.join(root, temp), Path.join(root, relative)) do
      :ok
    else
      :unsafe -> {:error, {"PL-GENERATE-DESTINATION", relative}}
      _ -> {:error, {"PL-GENERATE-WRITE", relative}}
    end
  end

  defp remove_regular(root, relative) do
    case GeneratorFS.status(root, relative) do
      :missing ->
        :ok

      :regular ->
        if(File.rm(Path.join(root, relative)) == :ok,
          do: :ok,
          else: {:error, {"PL-GENERATE-WRITE", relative}}
        )

      :unsafe ->
        {:error, {"PL-GENERATE-DESTINATION", relative}}
    end
  end

  defp managed_settings_findings(root) do
    settings = "native/ios/CrosswakeProofSettings.xcconfig"
    pending = "native/ios/.crosswake/ios_proof_settings.pending"
    journal = no_settings_recovery(root)

    cond do
      journal != :ok ->
        {:error, {rule, _}} = journal

        [
          finding(
            rule,
            pending,
            "run mix crosswake.gen.proof_lane ios --recover"
          )
        ]

      GeneratorFS.status(root, settings) == :unsafe ->
        [finding("PL-GENERATE-DESTINATION", settings, "use a contained iOS host root")]

      GeneratorFS.status(root, settings) == :missing ->
        [finding("PL-GENERATE-MISSING", settings, "run mix crosswake.gen.proof_lane ios")]

      match?({:ok, _}, managed_prior(root, settings)) ->
        []

      true ->
        [
          finding(
            "PL-GENERATE-OWNERSHIP",
            settings,
            "restore recognized managed settings or run the project migration"
          )
        ]
    end
  end

  defp managed_body(contents) do
    with [digest, body] <-
           Regex.run(
             ~r/\A\/\/ crosswake-managed-settings-sha256:([a-f0-9]{64})\n([\s\S]*)\z/,
             contents,
             capture: :all_but_first
           ),
         actual <- :crypto.hash(:sha256, body) |> Base.encode16(case: :lower),
         true <- actual == digest do
      {:ok, body}
    else
      _ -> :error
    end
  end

  defp recover_managed_settings(root) do
    pending = "native/ios/.crosswake/ios_proof_settings.pending"
    stage = "native/ios/.crosswake/ios_proof_settings.stage.json"
    settings = "native/ios/CrosswakeProofSettings.xcconfig"
    temp = "native/ios/.crosswake/ios_proof_settings.restore"

    with :ok <- recoverable_journal(root, pending, stage),
         {:ok, bytes} <- GeneratorFS.read(root, stage),
         {:ok, %{"version" => version, "prior" => prior} = staged} <- Jason.decode(bytes),
         true <- version in [1, 2],
         {:ok, prior_bytes} <- decode_optional_staged_bytes(prior),
         {:ok, desired_bytes} <- recovery_desired(version, staged),
         {:ok, current} <- recovery_current_is_known(root, settings, prior_bytes, desired_bytes),
         :ok <-
           recovery_temporary_is_known(
             root,
             "native/ios/.crosswake/ios_proof_settings.next",
             desired_bytes
           ),
         :ok <- recovery_temporary_is_known(root, temp, prior_bytes),
         :ok <- restore_prior(root, settings, temp, prior, current),
         :ok <- remove_regular(root, "native/ios/.crosswake/ios_proof_settings.next"),
         :ok <- remove_regular(root, temp),
         :ok <- remove_regular(root, pending),
         :ok <- remove_regular(root, stage) do
      {:ok, :recovered}
    else
      :missing -> {:error, {"PL-GENERATE-NO-RECOVERY", "settings"}}
      :unsafe -> {:error, {"PL-GENERATE-DESTINATION", pending}}
      {:error, :unsafe} -> {:error, {"PL-GENERATE-DESTINATION", "settings"}}
      {:error, {rule, path}} when is_binary(rule) and is_binary(path) -> {:error, {rule, path}}
      _ -> {:error, {"PL-GENERATE-RECOVERY", "settings"}}
    end
  end

  defp maybe_apply_project_migration(root, relative, expected, contents, opts) do
    if Keyword.get(opts, :apply, false) do
      temp = relative <> ".crosswake-migration-tmp"

      with {:ok, _} <-
             GeneratorFS.write(root, temp, contents,
               before_publish: Keyword.get(opts, :before_apply)
             ),
           {:ok, ^contents} <- GeneratorFS.read(root, temp),
           {:ok, ^expected} <- GeneratorFS.read(root, relative),
           :ok <- File.rename(Path.join(root, temp), Path.join(root, relative)),
           true <- GeneratorFS.read(root, relative) == {:ok, contents} do
        :ok
      else
        _ -> {:error, {"PL-GENERATE-MIGRATION-CONFLICT", "proof project"}}
      end
    else
      :ok
    end
  end

  defp recovery_current_is_known(root, settings, prior_bytes, desired_bytes) do
    case GeneratorFS.read(root, settings) do
      {:ok, current} when current == desired_bytes or current == prior_bytes ->
        {:ok, {:ok, current}}

      {:error, :missing} when is_nil(prior_bytes) ->
        {:ok, {:error, :missing}}

      _ when desired_bytes == :legacy ->
        {:error, {"PL-GENERATE-RECOVERY-LEGACY", "settings"}}

      _ ->
        {:error, {"PL-GENERATE-RECOVERY-CONFLICT", "settings"}}
    end
  end

  defp recovery_desired(1, _), do: {:ok, :legacy}
  defp recovery_desired(2, staged), do: decode_staged_bytes(Map.get(staged, "desired"))

  defp recovery_temporary_is_known(root, relative, expected) do
    case GeneratorFS.read(root, relative) do
      {:error, :missing} -> :ok
      {:ok, ^expected} when is_binary(expected) -> :ok
      {:error, :unsafe} -> {:error, {"PL-GENERATE-DESTINATION", "settings"}}
      _ -> {:error, {"PL-GENERATE-RECOVERY-CONFLICT", "settings"}}
    end
  end

  defp recoverable_journal(root, pending, stage) do
    case {GeneratorFS.status(root, pending), GeneratorFS.status(root, stage)} do
      {:missing, :missing} -> {:error, {"PL-GENERATE-NO-RECOVERY", "settings"}}
      {:unsafe, _} -> {:error, {"PL-GENERATE-DESTINATION", "settings"}}
      {_, :unsafe} -> {:error, {"PL-GENERATE-DESTINATION", "settings"}}
      {_, :regular} -> :ok
      _ -> {:error, {"PL-GENERATE-RECOVERY", "settings"}}
    end
  end

  defp no_settings_recovery(root) do
    statuses =
      Enum.map(
        ["pending", "stage.json", "next", "restore"],
        &GeneratorFS.status(root, "native/ios/.crosswake/ios_proof_settings." <> &1)
      )

    cond do
      :unsafe in statuses -> {:error, {"PL-GENERATE-DESTINATION", "settings"}}
      :regular in statuses -> {:error, {"PL-GENERATE-INTERRUPTED", "settings"}}
      true -> :ok
    end
  end

  defp decode_staged_bytes(encoded) when is_binary(encoded) do
    case Base.decode64(encoded) do
      {:ok, bytes} -> {:ok, bytes}
      _ -> :error
    end
  end

  defp decode_staged_bytes(_), do: :error

  defp decode_optional_staged_bytes(nil), do: {:ok, nil}
  defp decode_optional_staged_bytes(encoded), do: decode_staged_bytes(encoded)

  defp restore_prior(root, settings, _temp, nil, current) do
    if GeneratorFS.read(root, settings) == current,
      do: remove_regular(root, settings),
      else: {:error, {"PL-GENERATE-RECOVERY-CONFLICT", "settings"}}
  end

  defp restore_prior(root, settings, temp, encoded, current) when is_binary(encoded) do
    with {:ok, prior} <- Base.decode64(encoded),
         {:ok, _} <- GeneratorFS.write(root, temp, prior),
         {:ok, ^prior} <- GeneratorFS.read(root, temp),
         true <- GeneratorFS.read(root, settings) == current,
         :ok <- File.rename(Path.join(root, temp), Path.join(root, settings)),
         true <- GeneratorFS.read(root, settings) == {:ok, prior} do
      :ok
    else
      false -> {:error, {"PL-GENERATE-RECOVERY-CONFLICT", "settings"}}
      _ -> {:error, {"PL-GENERATE-RECOVERY", "settings"}}
    end
  end

  defp restore_prior(_, _, _, _, _), do: {:error, {"PL-GENERATE-RECOVERY", "settings"}}

  defp interrupt_before_manifest do
    if Process.get(:crosswake_proof_lane_interrupt_before_manifest) do
      {:error, {"PL-GENERATE-INTERRUPTED", "manifest"}}
    else
      :ok
    end
  end

  defp missing_findings(root, desired) do
    Enum.flat_map(desired, fn %{path: path, relative: relative} ->
      case GeneratorFS.status(root, relative) do
        :regular -> []
        :missing -> [finding("PL-GENERATE-MISSING", path, "run mix crosswake.gen.proof_lane ios")]
        :unsafe -> [finding("PL-GENERATE-DESTINATION", path, "use a contained iOS shell root")]
      end
    end)
  end

  defp manifest_findings(root, desired) do
    manifest = manifest_desired(desired)

    case GeneratorFS.read(root, manifest.relative) do
      {:ok, contents} when contents == manifest.contents ->
        []

      {:ok, _} ->
        [
          finding(
            "PL-GENERATE-PROVENANCE",
            manifest.path,
            "review template provenance and run the generator"
          )
        ]

      {:error, :missing} ->
        [finding("PL-GENERATE-MISSING", manifest.path, "run mix crosswake.gen.proof_lane ios")]

      _ ->
        [finding("PL-GENERATE-DESTINATION", manifest.path, "use a contained iOS shell root")]
    end
  end

  defp manifest_desired(desired) do
    %{
      path: ".crosswake/proof_lane.json",
      relative: ".crosswake/proof_lane.json",
      contents:
        Jason.encode!(%{
          "schema_version" => @schema_version,
          "template_version" => @template_version,
          "paths" => Enum.map(desired, & &1.path),
          "provenance" => "crosswake:proof-lane"
        })
    }
  end

  defp finding(rule_id, path, remediation),
    do: %{rule_id: rule_id, path: path, remediation: remediation}

  defp host_root!(config) do
    case Config.host_root(config) do
      {:ok, root} -> root
      {:error, error} -> raise error
    end
  end

  defp normalize!(%Config{} = config) do
    case Config.normalize(Map.from_struct(config)) do
      {:ok, normalized} -> normalized
      {:error, error} -> raise error
    end
  end

  defp destination_relative(relative) do
    cond do
      String.starts_with?(relative, "CrosswakeProofLane") ->
        Path.join(["native", "ios", relative])

      relative == "CrosswakeProofSettings.xcconfig" ->
        Path.join(["native", "ios", relative])

      true ->
        relative
    end
  end

  defp render(template, config, proof_app_bundle_id, device_signing) do
    rendered =
      EEx.eval_file(template_path(template),
        assigns: [
          config: config,
          template_version: @template_version,
          proof_app_bundle_id: proof_app_bundle_id,
          proof_test_bundle_id: proof_app_bundle_id <> ".tests",
          proof_ui_bundle_id: proof_app_bundle_id <> ".uitests",
          code_sign_style: if(device_signing.mode == :manual, do: "Manual", else: "Automatic"),
          team_id: device_signing.team_id
        ]
      )

    cond do
      template == "ios/CrosswakeProofLane.xcodeproj/project.pbxproj.eex" ->
        wire_proof_settings(rendered)

      template == "ios/CrosswakeProofSettings.xcconfig.eex" ->
        digest = :crypto.hash(:sha256, rendered) |> Base.encode16(case: :lower)
        "// crosswake-managed-settings-sha256:#{digest}\n" <> rendered

      true ->
        rendered
    end
  end

  defp wire_proof_settings(contents) do
    Enum.reduce(70..75, contents, fn number, project ->
      id = "A100000000000000000000" <> Integer.to_string(number)

      variable =
        cond do
          number <= 71 -> "CROSSWAKE_PROOF_APP_BUNDLE_ID"
          number <= 73 -> "CROSSWAKE_PROOF_TEST_BUNDLE_ID"
          true -> "CROSSWAKE_PROOF_UI_BUNDLE_ID"
        end

      pattern = Regex.compile!("(?m)^(\\s*" <> id <> " = \\{isa = XCBuildConfiguration;)(.*)$")

      Regex.replace(pattern, project, fn _, prefix, rest ->
        rest =
          String.replace(
            rest,
            "PRODUCT_BUNDLE_IDENTIFIER = dev.crosswake.prooflane;",
            "PRODUCT_BUNDLE_IDENTIFIER = \"$(#{variable})\";"
          )

        rest =
          String.replace(
            rest,
            "PRODUCT_BUNDLE_IDENTIFIER = dev.crosswake.prooflane.tests;",
            "PRODUCT_BUNDLE_IDENTIFIER = \"$(#{variable})\";"
          )

        rest =
          String.replace(
            rest,
            "PRODUCT_BUNDLE_IDENTIFIER = dev.crosswake.prooflane.uitests;",
            "PRODUCT_BUNDLE_IDENTIFIER = \"$(#{variable})\";"
          )

        rest = String.replace(rest, "CODE_SIGNING_ALLOWED = NO; CODE_SIGNING_REQUIRED = NO; ", "")

        rest =
          String.replace(
            rest,
            "buildSettings = {",
            "baseConfigurationReference = A10000000000000000000019 /* CrosswakeProofSettings.xcconfig */; buildSettings = {",
            global: false
          )

        prefix <> rest
      end)
    end)
  end

  defp normalize_host!(nil), do: nil
  defp normalize_host!(%IOSHostConfig{} = config), do: config

  defp normalize_host!(config) do
    case IOSHostConfig.normalize(config) do
      {:ok, normalized} -> normalized
      {:error, reason} -> raise ArgumentError, "invalid iOS host configuration: #{reason}"
    end
  end

  defp template_path(template) do
    Application.app_dir(:crosswake, Path.join("priv/templates/crosswake/proof_lane", template))
  end
end
