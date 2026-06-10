defmodule Crosswake.Doctor.ThreadlineTest do
  # async: false — these tests mutate global Application env
  # (:crosswake, :audit_ledger) via put_env/delete_env, and Doctor.run/1 reads
  # that key with Application.get_env. Running concurrently with any other test
  # that calls Doctor.run/1 would leak spurious :audit_ledger values across
  # tests and produce non-deterministic threadline findings (WR-01).
  use ExUnit.Case, async: false

  alias Crosswake.Doctor

  setup do
    target =
      Path.join(System.tmp_dir!(), "crosswake-doctor-#{System.unique_integer([:positive])}")

    router_path = Path.join(target, "lib/demo_web/router.ex")
    policy_path = Path.join(target, "lib/demo_web/crosswake/policy.ex")
    install_manifest_path = Path.join(target, "priv/crosswake/install_manifest.json")

    File.mkdir_p!(Path.dirname(router_path))
    File.mkdir_p!(Path.dirname(policy_path))
    File.mkdir_p!(Path.dirname(install_manifest_path))

    File.write!(
      router_path,
      """
      defmodule DemoWeb.Router do
        # crosswake:install:start
        import Crosswake.Router
        # crosswake:install:end
      end
      """
    )

    File.write!(policy_path, "defmodule DemoWeb.Crosswake.Policy do\nend\n")

    install_manifest =
      Jason.encode!(%{
        schema_version: 1,
        crosswake_version: "0.1.0",
        router_path: Path.relative_to(router_path, target),
        web_module: "DemoWeb",
        policy_module: "DemoWeb.Crosswake.Policy",
        files: %{created_or_reused: [Path.relative_to(policy_path, target)]},
        markers: ["# crosswake:install:start", "# crosswake:install:end"]
      })

    File.write!(install_manifest_path, install_manifest)
    write_shell_artifacts!(target)
    write_proof_hook!(target, "ios", 0, "ios proof passed")
    write_proof_hook!(target, "android", 0, "android proof passed")

    %{
      target: target,
      install_manifest_path: install_manifest_path
    }
  end

  # Phase 95: Threadline posture doctor checks (OPER-03)
  describe "phase_95_threadline_findings (OPER-03)" do
    test "emits threadline.plug_missing :advisory when plug is absent from router",
         %{target: target, install_manifest_path: install_manifest_path} do
      # Default setup router does NOT have plug Crosswake.Plug.Threadline
      report =
        Doctor.run(
          route_source: Crosswake.TestSupport.RouterFixtures.ManagedRouter,
          install_manifest_path: install_manifest_path,
          cwd: target
        )

      finding = Enum.find(report.findings, &(&1.code == "threadline.plug_missing"))
      assert finding != nil
      assert finding.severity == :advisory
      assert finding.check == "threadline_posture"
    end

    test "does NOT emit threadline.plug_missing when plug is present in router",
         %{target: target, install_manifest_path: install_manifest_path} do
      router_path = Path.join(target, "lib/demo_web/router.ex")

      File.write!(
        router_path,
        """
        defmodule DemoWeb.Router do
          # crosswake:install:start
          import Crosswake.Router
          plug Crosswake.Plug.Threadline
          # crosswake:install:end
        end
        """
      )

      report =
        Doctor.run(
          route_source: Crosswake.TestSupport.RouterFixtures.ManagedRouter,
          install_manifest_path: install_manifest_path,
          cwd: target
        )

      refute Enum.any?(report.findings, &(&1.code == "threadline.plug_missing"))
    end

    test "emits threadline.ledger_not_configured :advisory when audit_ledger is not configured",
         %{target: target, install_manifest_path: install_manifest_path} do
      # Save prior value and restore it in on_exit to avoid cross-test races
      prev = Application.get_env(:crosswake, :audit_ledger)

      on_exit(fn ->
        if prev != nil do
          Application.put_env(:crosswake, :audit_ledger, prev)
        else
          Application.delete_env(:crosswake, :audit_ledger)
        end
      end)

      # Ensure :audit_ledger is not set
      Application.delete_env(:crosswake, :audit_ledger)

      report =
        Doctor.run(
          route_source: Crosswake.TestSupport.RouterFixtures.ManagedRouter,
          install_manifest_path: install_manifest_path,
          cwd: target
        )

      finding = Enum.find(report.findings, &(&1.code == "threadline.ledger_not_configured"))
      assert finding != nil
      assert finding.severity == :advisory
      assert finding.check == "threadline_posture"
    end

    # PII field detection test using a test schema
    defmodule PiiLedgerSchema do
      def __schema__(:fields) do
        # actor_ref is in the forbidden_metadata_keys list
        [:thread_id, :correlation_id, :route_id, :actor_ref, :actor_kind, :event_class,
         :event_type, :outcome, :provenance, :occurred_at, :recorded_at, :idempotency_key,
         :metadata, :row_hash, :prev_hash,
         # PII-forbidden field
         :email]
      end
    end

    test "emits threadline.pii_forbidden_field_present :error when schema has PII forbidden fields",
         %{target: target, install_manifest_path: install_manifest_path} do
      Application.put_env(:crosswake, :audit_ledger, schema: PiiLedgerSchema)

      on_exit(fn -> Application.delete_env(:crosswake, :audit_ledger) end)

      report =
        Doctor.run(
          route_source: Crosswake.TestSupport.RouterFixtures.ManagedRouter,
          install_manifest_path: install_manifest_path,
          cwd: target
        )

      finding = Enum.find(report.findings, &(&1.code == "threadline.pii_forbidden_field_present"))
      assert finding != nil
      assert finding.severity == :error
      assert finding.check == "threadline_posture"
      assert :email in finding.details.offending_keys
      # :actor_ref is a canonical column — must NOT be falsely flagged as PII (CR-01)
      refute :actor_ref in finding.details.offending_keys
    end

    defmodule DriftLedgerSchema do
      def __schema__(:fields) do
        # Missing :idempotency_key, :row_hash, :prev_hash
        [:thread_id, :correlation_id, :route_id, :actor_ref, :actor_kind, :event_class,
         :event_type, :outcome, :provenance, :occurred_at, :recorded_at, :metadata]
      end
    end

    test "emits threadline.ledger_schema_drift :warning when schema is missing canonical columns",
         %{target: target, install_manifest_path: install_manifest_path} do
      Application.put_env(:crosswake, :audit_ledger, schema: DriftLedgerSchema)

      on_exit(fn -> Application.delete_env(:crosswake, :audit_ledger) end)

      report =
        Doctor.run(
          route_source: Crosswake.TestSupport.RouterFixtures.ManagedRouter,
          install_manifest_path: install_manifest_path,
          cwd: target
        )

      finding = Enum.find(report.findings, &(&1.code == "threadline.ledger_schema_drift"))
      assert finding != nil
      assert finding.severity == :warning
      assert finding.check == "threadline_posture"
      assert :idempotency_key in finding.details.missing_columns
      assert :row_hash in finding.details.missing_columns
      assert :prev_hash in finding.details.missing_columns
    end

    # Canonical schema fixture — exactly the 15 LEDG-02 columns, including :actor_ref
    defmodule CanonicalLedgerSchema do
      def __schema__(:fields) do
        [:thread_id, :correlation_id, :route_id, :actor_ref, :actor_kind, :event_class,
         :event_type, :outcome, :provenance, :occurred_at, :recorded_at, :idempotency_key,
         :metadata, :row_hash, :prev_hash]
      end
    end

    # CR-02 + CR-01: bare-atom config must enter schema checks and canonical schema must pass
    test "runs threadline schema checks with bare-atom audit_ledger config and canonical schema passes",
         %{target: target, install_manifest_path: install_manifest_path} do
      # Bare-atom config — the documented canonical shape (audit_ledger: MyApp.Audit.Ledger)
      Application.put_env(:crosswake, :audit_ledger, CanonicalLedgerSchema)

      on_exit(fn -> Application.delete_env(:crosswake, :audit_ledger) end)

      report =
        Doctor.run(
          route_source: Crosswake.TestSupport.RouterFixtures.ManagedRouter,
          install_manifest_path: install_manifest_path,
          cwd: target
        )

      # Checks ran AND passed — no false PII error, no false drift warning
      refute Enum.any?(report.findings, &(&1.code == "threadline.pii_forbidden_field_present")),
             "Canonical schema must not produce a PII false-positive (CR-01)"

      refute Enum.any?(report.findings, &(&1.code == "threadline.ledger_schema_drift")),
             "Canonical schema must not produce a drift warning (schema checks must have run via bare-atom config — CR-02)"
    end

    # IN-06: a loadable module that is not an Ecto schema must yield a distinct
    # invalid-schema advisory, not a misleading "missing all 15 columns" drift warning
    defmodule NotAnEctoSchema do
      @moduledoc false
      def some_function, do: :ok
    end

    test "emits threadline.ledger_schema_invalid :advisory when configured module is not an Ecto schema",
         %{target: target, install_manifest_path: install_manifest_path} do
      Application.put_env(:crosswake, :audit_ledger, NotAnEctoSchema)

      on_exit(fn -> Application.delete_env(:crosswake, :audit_ledger) end)

      report =
        Doctor.run(
          route_source: Crosswake.TestSupport.RouterFixtures.ManagedRouter,
          install_manifest_path: install_manifest_path,
          cwd: target
        )

      finding = Enum.find(report.findings, &(&1.code == "threadline.ledger_schema_invalid"))
      assert finding != nil
      assert finding.severity == :advisory
      assert finding.check == "threadline_posture"

      # The misleading "missing all 15 columns" drift warning must NOT fire,
      # and the PII check must not silently pass alongside it (IN-06)
      refute Enum.any?(report.findings, &(&1.code == "threadline.ledger_schema_drift")),
             "Non-Ecto module must produce ledger_schema_invalid, not a drift warning for all columns"

      refute Enum.any?(report.findings, &(&1.code == "threadline.pii_forbidden_field_present"))
    end

    # CR-04: keyword config without :schema key must not crash the doctor
    test "does not crash on keyword audit_ledger config missing :schema key",
         %{target: target, install_manifest_path: install_manifest_path} do
      Application.put_env(:crosswake, :audit_ledger, foo: :bar)

      on_exit(fn -> Application.delete_env(:crosswake, :audit_ledger) end)

      # Must return a report without raising ArgumentError
      report =
        Doctor.run(
          route_source: Crosswake.TestSupport.RouterFixtures.ManagedRouter,
          install_manifest_path: install_manifest_path,
          cwd: target
        )

      assert report != nil
    end

    # CR-05: map config with string :schema value must not crash the doctor (fail-closed guard)
    test "does not crash on string :schema value in map config",
         %{target: target, install_manifest_path: install_manifest_path} do
      # String module name — classic config/runtime.exs + System.get_env pattern
      Application.put_env(:crosswake, :audit_ledger, %{schema: "MyApp.Audit.Ledger"})

      on_exit(fn -> Application.delete_env(:crosswake, :audit_ledger) end)

      # Must return a report without raising FunctionClauseError from Code.ensure_loaded?/1
      report =
        Doctor.run(
          route_source: Crosswake.TestSupport.RouterFixtures.ManagedRouter,
          install_manifest_path: install_manifest_path,
          cwd: target
        )

      assert report != nil
    end
  end

  # Helpers copied from Crosswake.DoctorTest — the setup above requires the
  # same on-disk shell artifacts and proof hooks so Doctor.run/1 sees a
  # complete host fixture.
  defp write_shell_artifacts!(target) do
    ios_root = Path.join(target, "native/ios/crosswake_shell")
    android_root = Path.join(target, "native/android/crosswake_shell")

    write_file!(Path.join(ios_root, "README.md"), "host-owned scaffold once\n")

    write_file!(
      Path.join(ios_root, "CrosswakeShell.xcodeproj/project.pbxproj"),
      "PBXNativeTarget\n"
    )

    write_file!(
      Path.join(ios_root, "CrosswakeShell/CrosswakeShellApp.swift"),
      "ActivationCoordinator.bundled\nonOpenURL\nonContinueUserActivity\n"
    )

    write_file!(
      Path.join(ios_root, "CrosswakeShell/ActivationCoordinator.swift"),
      "packIncompatible\ninactiveRoute\nexternalEntryDenied\n"
    )

    write_file!(
      Path.join(ios_root, "CrosswakeShell/LiveViewContainerViewController.swift"),
      "WKWebView\nWKNavigationDelegate\nsame-origin\n"
    )

    write_file!(Path.join(ios_root, "CrosswakeShell/Info.plist"), "WKAppBoundDomains\nNSCameraUsageDescription\nNSPhotoLibraryUsageDescription\naps-environment\nNSPrivacyCollectedDataTypeDeviceID\ncom.apple.developer.associated-domains\n")

    write_file!(
      Path.join(ios_root, "CrosswakeShell/RouteUnavailableView.swift"),
      "Update app\nOpen safe fallback\n"
    )

    write_file!(
      Path.join(ios_root, "CrosswakeShell/BridgeChannel.swift"),
      "app.info.get\nfiles.pick\nhaptics.impact\npermissions.status\ntransfer.download\ntransfer.export\ntransfer.import\ntransfer.upload.prepare\nrequest\nreply\n"
    )

    write_file!(
      Path.join(ios_root, "Fixtures/crosswake_manifest.json"),
      ~s({"manifest_schema_version":"1.0.0"})
    )

    write_file!(
      Path.join(ios_root, "Fixtures/route_denial.json"),
      ~s({"reason":"pack_incompatible"})
    )

    write_file!(Path.join(android_root, "README.md"), "host-owned scaffold once\n")

    write_file!(
      Path.join(android_root, "app/build.gradle"),
      "applicationId \"dev.crosswake.shell\"\n"
    )

    write_file!(
      Path.join(android_root, "app/src/main/java/dev/crosswake/shell/MainActivity.kt"),
      "ActivationCoordinator.bundled\n"
    )

    write_file!(
      Path.join(android_root, "app/src/main/java/dev/crosswake/shell/ActivationCoordinator.kt"),
      "pack_incompatible\ninactive_route\nexternal_entry_denied\n"
    )

    write_file!(
      Path.join(android_root, "app/src/main/java/dev/crosswake/shell/LiveViewFragment.kt"),
      "WebView\nAllowlisted\n"
    )

    write_file!(
      Path.join(android_root, "app/src/main/AndroidManifest.xml"),
      "android.intent.category.BROWSABLE\nandroid.intent.action.VIEW\nPOST_NOTIFICATIONS\nandroid.permission.CAMERA\nandroid.permission.VIBRATE\n"
    )

    write_file!(
      Path.join(android_root, "app/src/main/res/layout/activity_route_unavailable.xml"),
      "Update app\nOpen safe fallback\n"
    )

    write_file!(
      Path.join(android_root, "app/src/main/java/dev/crosswake/shell/BridgeChannel.kt"),
      "app.info.get\nfiles.pick\nhaptics.impact\npermissions.status\ntransfer.download\ntransfer.export\ntransfer.import\ntransfer.upload.prepare\nrequest\nreply\n"
    )

    write_file!(
      Path.join(android_root, "app/src/main/assets/crosswake_manifest.json"),
      ~s({"manifest_schema_version":"1.0.0"})
    )

    write_file!(
      Path.join(android_root, "app/src/main/assets/route_denial.json"),
      ~s({"reason":"pack_incompatible"})
    )
  end

  defp write_proof_hook!(target, platform, exit_status, output) do
    path =
      case platform do
        "ios" -> Path.join(target, "script/verify_generated_ios_shell.sh")
        "android" -> Path.join(target, "script/verify_generated_android_shell.sh")
      end

    write_file!(
      path,
      """
      #!/usr/bin/env bash
      echo #{inspect(output)}
      exit #{exit_status}
      """
    )

    File.chmod!(path, 0o755)
    path
  end

  defp write_file!(path, contents) do
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, contents)
  end
end
