defmodule Crosswake.DoctorTest do
  use ExUnit.Case, async: true

  alias Crosswake.Doctor

  @allowed_bridge_commands [
    "app.info.get",
    "files.pick",
    "haptics.impact",
    "notifications.token.get",
    "permissions.status",
    "share.invoke",
    "transfer.download",
    "transfer.export",
    "transfer.import",
    "transfer.upload.prepare"
  ]
  alias Crosswake.Doctor.Check
  alias Crosswake.Doctor.Formatter
  alias Crosswake.Doctor.JSONFormatter
  alias Crosswake.Offline.Status
  alias Crosswake.Offline.SafeObservation
  alias Crosswake.Offline.Telemetry
  alias Crosswake.SupportMatrix
  alias Mix.Tasks.Crosswake.Gen.NativeControlsUi

  test "static readiness excludes runtime and active-scope data" do
    assert {:ok, observation} =
             SafeObservation.new(%{
               route_id: "route-0123456789abcdef",
               runtime: :offline_island,
               lifecycle: :replayed,
               outcome: :accepted,
               denial: :none,
               measurements: %{event_count: 1},
               configuration: :configured,
               adapter_readiness: :blocked
             })

    assert {:ok, readiness} = Doctor.static_readiness(observation)

    assert readiness == %{
             configuration: :configured,
             adapter_readiness: :blocked
           }
  end

  test "static readiness rejects forged observations without returning detail" do
    assert {:ok, observation} =
             SafeObservation.new(%{
               route_id: "route-0123456789abcdef",
               runtime: :offline_island,
               lifecycle: :replayed,
               outcome: :accepted,
               denial: :none,
               measurements: %{event_count: 1},
               configuration: :configured,
               adapter_readiness: :blocked
             })

    forged = Map.put(observation, :adapter_readiness, :canary_readiness)

    assert {:error,
            %SafeObservation.Error{
              rule_id: "CW-SAFE-OBSERVATION-READINESS",
              path: :adapter_readiness
            }} = Doctor.static_readiness(forged)
  end

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

  test "doctor reports shell, bridge, route unavailable, pack posture, and proof verification requirements",
       %{target: target, install_manifest_path: install_manifest_path} do
    report =
      Doctor.run(
        route_source: Crosswake.TestSupport.RouterFixtures.ManagedRouter,
        install_manifest_path: install_manifest_path,
        cwd: target
      )

    # Honest blocking posture: unverified shell proofs are :error (not :warning).
    # status: :error means CI gates on doctor status will catch unverified hosts.
    # The test MUST assert :error here — changing this to :ok would confirm
    # the WR-04 posture regression rather than catch it.
    assert report.status == :error
    assert report.manifest != nil
    assert report.support.status == :verification_required
    assert report.shells.ios.generated.ok?
    assert report.shells.android.route_unavailable.ok?
    assert report.shells.ios.proof.status == :verification_required
    assert report.shells.android.proof.status == :verification_required
    assert report.bridge.allowed_commands == @allowed_bridge_commands
    assert report.offline.status == :supported
    assert report.support.release_policy.crosswake_version == Mix.Project.config()[:version]
    assert report.support.release_policy.manifest_schema_version == "1.1.0"

    assert report.support.release_policy.bridge_protocol_version ==
             Crosswake.Bridge.Contract.version()

    assert report.support.release_policy.native_runtime_version == "1.0.0"
    assert report.support.release_policy.package_version_truth =~ "Package versions alone"
    assert report.offline.states == Enum.map(Status.states(), &Atom.to_string/1)

    assert report.offline.telemetry.metadata_keys ==
             Enum.map(Telemetry.metadata_keys(), &Atom.to_string/1)

    assert report.offline.routes["library"]["offline"] == "cached_read_only"
    assert report.offline.routes["study-session"]["sync_seam"] == "study_reviews"

    assert report.bridge.denial_reasons |> Enum.sort() ==
             Enum.sort([
               "commerce_corridor",
               "compatibility_mismatch",
               "dependency_missing",
               "external_entry_denied",
               "gate_denied",
               "inactive_route",
               "kill_switch_active",
               "notification_open_denied",
               "origin_denied",
               "pack_incompatible",
               # Phase 154, D-12: the 14th closed reason, added by the control-contract seam.
               "shell_unreachable",
               "step_up_required",
               "undeclared_capability",
               "unavailable_capability"
             ])

    assert Enum.any?(
             report.findings,
             &(&1.check == "shell_activation" and &1.severity == :advisory)
           )

    assert Enum.any?(report.findings, &(&1.check == "bridge_posture" and &1.severity == :warning))

    assert Enum.any?(
             report.findings,
             &(&1.check == "proof_posture" and &1.code == "proof_hook_verification_required")
           )

    assert Enum.any?(
             report.findings,
             &(&1.check == "support_posture" and &1.code == "support_claim_verification_required")
           )
  end

  test "doctor reports status :error when a shell proof hook exits non-zero (:failed posture)",
       %{target: target, install_manifest_path: install_manifest_path} do
    # Compensating assertion: a :failed shell (exit_status 1) must produce status: :error.
    # This locks the honest posture so a :failed shell can never silently pass doctor.
    android_proof = write_proof_hook!(target, "android", 1, "android proof failed")

    report =
      Doctor.run(
        route_source: Crosswake.TestSupport.RouterFixtures.ManagedRouter,
        install_manifest_path: install_manifest_path,
        cwd: target,
        check_native_tools?: true,
        android_proof_hook_path: android_proof
      )

    assert report.status == :error,
           "doctor must report status: :error when a shell proof hook fails (exits non-zero) — got: #{inspect(report.status)}"

    assert Enum.any?(
             report.findings,
             &(&1.check == "proof_posture" and &1.code == "proof_hook_failed")
           ),
           "doctor must include a proof_hook_failed finding for a failing shell proof hook"
  end

  test "doctor findings are structured and formatter output stays stable when proof hooks pass",
       %{
         target: target,
         install_manifest_path: install_manifest_path
       } do
    ios_proof = write_proof_hook!(target, "ios", 0, "ios proof passed")
    android_proof = write_proof_hook!(target, "android", 0, "android proof passed")

    report =
      Doctor.run(
        route_source: Crosswake.TestSupport.RouterFixtures.ManagedRouter,
        install_manifest_path: install_manifest_path,
        cwd: target,
        check_native_tools?: true,
        ios_proof_hook_path: ios_proof,
        android_proof_hook_path: android_proof
      )

    assert report.status == :ok
    assert report.support.status == :supported
    assert Enum.all?(report.findings, &match?(%Check{}, &1))

    human = Formatter.render(report)
    json = JSONFormatter.render(report)
    decoded = Jason.decode!(json)

    assert human =~ "support posture: supported"
    assert human =~ "release policy:"
    assert human =~ "manifest_schema_version=1.1.0"
    assert human =~ "bridge_protocol_version=#{Crosswake.Bridge.Contract.version()}"
    assert human =~ "native_runtime_version=1.0.0"
    assert human =~ "Package versions alone do not determine support truth"
    assert human =~ "route unavailable=yes"
    assert human =~ "bridge posture: crosswake.bridge@1.1.0"
    assert human =~ "offline posture: supported"
    assert human =~ "queued_for_replay"
    assert human =~ "proof=supported"
    # Phase 23 WR-05 parity fix: human formatter renders offline telemetry
    # (metadata_keys + terminal_outcomes) so operator-facing posture matches
    # the JSON output's telemetry block, instead of silently dropping fields.
    assert human =~ "telemetry: metadata_keys="
    assert human =~ "terminal_outcomes="
    assert human =~ "accepted"
    assert human =~ "conflict"

    assert decoded["status"] == "ok"
    assert decoded["support"]["status"] == "supported"
    assert decoded["support"]["release_policy"]["manifest_schema_version"] == "1.1.0"

    assert decoded["support"]["release_policy"]["bridge_protocol_version"] ==
             Crosswake.Bridge.Contract.version()

    assert decoded["support"]["release_policy"]["native_runtime_version"] == "1.0.0"

    assert decoded["support"]["release_policy"]["package_version_truth"] =~
             "Package versions alone"

    assert decoded["shells"]["ios"]["proof"]["status"] == "supported"
    assert decoded["shells"]["android"]["proof"]["status"] == "supported"
    assert decoded["bridge"]["allowed_commands"] == @allowed_bridge_commands
    assert decoded["offline"]["status"] == "supported"
    assert decoded["offline"]["routes"]["study-session"]["sync_seam"] == "study_reviews"
    assert "conflict_requires_attention" in decoded["offline"]["states"]
    assert Enum.any?(decoded["findings"], &(&1["severity"] == "advisory"))
    refute Map.has_key?(decoded, "publish_readiness")
    refute human =~ "Publish readiness"
  end

  test "doctor exposes publish readiness only when check_publish? is enabled", %{
    target: target,
    install_manifest_path: install_manifest_path
  } do
    default_report =
      Doctor.run(
        route_source: __MODULE__.CommerceCorridorRouter,
        install_manifest_path: install_manifest_path,
        cwd: target
      )

    assert default_report.publish_readiness == nil

    report =
      Doctor.run(
        route_source: __MODULE__.CommerceCorridorRouter,
        install_manifest_path: install_manifest_path,
        cwd: target,
        check_publish?: true
      )

    assert report.publish_readiness.schema_version == "1.0.0"
    assert report.publish_readiness.status == :not_ready
    assert is_map(report.publish_readiness.summary)

    categories = Enum.map(report.publish_readiness.checks, & &1.category)
    assert :publish_parity in categories
    assert :provider_adapter_readiness in categories
    assert :native_shell_verification_gap in categories

    assert Enum.any?(report.findings, fn finding ->
             finding.code == "diag.provider.adapter_shipped_seams" and
               finding.check == "provider_adapter_readiness" and
               finding.message =~ "StoreKit" and finding.message =~ "Play Billing"
           end)

    assert Enum.any?(report.findings, fn finding ->
             finding.code == "diag.shell.verification_required" and
               finding.details.claim_scope == "Native shell verification and rebuild readiness"
           end)
  end

  defmodule CommerceCorridorRouter do
    use Crosswake.Router

    scope "/" do
      crosswake_defaults runtime: :live_view, offline: :unavailable, security: :sensitive do
        live("/billing", Crosswake.TestSupport.StudySessionLive,
          crosswake: [
            id: "billing",
            runtime: :live_view,
            capabilities: ["purchase_intent"],
            commerce: [corridor: :subscription_default, role: :purchase_intent]
          ]
        )
      end
    end
  end

  defmodule UndeclaredCommerceCorridorRouter do
    use Crosswake.Router

    scope "/" do
      crosswake_defaults runtime: :live_view, offline: :unavailable, security: :sensitive do
        live("/billing", Crosswake.TestSupport.StudySessionLive,
          crosswake: [
            id: "billing",
            runtime: :live_view,
            capabilities: ["purchase_intent"],
            commerce: [corridor: :missing_subscription_profile, role: :purchase_intent]
          ]
        )
      end
    end
  end

  test "doctor emits canonical commerce corridor findings and keeps taxonomy parity with support matrix",
       %{
         target: target,
         install_manifest_path: install_manifest_path
       } do
    report =
      Doctor.run(
        route_source: CommerceCorridorRouter,
        install_manifest_path: install_manifest_path,
        cwd: target
      )

    corridor_findings =
      report.findings
      |> Enum.filter(&String.starts_with?(&1.code, "commerce.corridor."))

    emitted_codes =
      corridor_findings
      |> Enum.map(& &1.code)
      |> Enum.uniq()
      |> Enum.sort()

    assert "commerce.corridor.runtime_incompatible" in emitted_codes
    assert "commerce.corridor.prerequisite_missing" in emitted_codes

    # Denial-taxonomy parity is scoped to findings produced by the corridor denial check
    # (check: "commerce_corridor"). The commerce_summary check publishes typed
    # non-denial codes like commerce.corridor.native_rebuild_required which live in
    # the commerce.* family but are not denial codes.
    denial_emitted_codes =
      corridor_findings
      |> Enum.filter(&(&1.check == "commerce_corridor"))
      |> Enum.map(& &1.code)
      |> Enum.uniq()
      |> Enum.sort()

    assert MapSet.subset?(
             MapSet.new(denial_emitted_codes),
             MapSet.new(SupportMatrix.commerce_corridor_denial_codes())
           )

    assert Enum.any?(corridor_findings, fn finding ->
             finding.details[:corridor_ref] == "subscription_default" and
               finding.details[:role] == :purchase_intent and
               finding.details[:denial_code] == finding.code and
               finding.details[:fallback_hint] == "return_to_phoenix_guidance"
           end)

    human = Formatter.render(report)
    decoded = JSONFormatter.render(report) |> Jason.decode!()

    assert human =~ "commerce.corridor.runtime_incompatible"
    assert human =~ "corridor_ref=subscription_default"
    assert human =~ "denial_code=commerce.corridor.prerequisite_missing"
    assert human =~ "fallback_hint=return_to_phoenix_guidance"

    assert Enum.any?(decoded["findings"], fn finding ->
             finding["code"] == "commerce.corridor.runtime_incompatible" and
               finding["corridor_ref"] == "subscription_default" and
               finding["role"] == "purchase_intent" and
               finding["denial_code"] == "commerce.corridor.runtime_incompatible" and
               finding["fallback_hint"] == "return_to_phoenix_guidance"
           end)
  end

  test "doctor maps undeclared corridor compile failures onto canonical commerce denial IDs", %{
    target: target,
    install_manifest_path: install_manifest_path
  } do
    report =
      Doctor.run(
        route_source: UndeclaredCommerceCorridorRouter,
        install_manifest_path: install_manifest_path,
        cwd: target
      )

    assert Enum.any?(report.findings, fn finding ->
             finding.code == "commerce.corridor.undeclared" and
               finding.check == "commerce_corridor" and
               finding.details[:denial_code] == "commerce.corridor.undeclared"
           end)
  end

  defmodule PaywallCorridorRouter do
    use Crosswake.Router

    scope "/" do
      crosswake_defaults runtime: :live_view, offline: :unavailable, security: :sensitive do
        live("/paywall", Crosswake.TestSupport.StudySessionLive,
          crosswake: [
            id: "paywall",
            runtime: :live_view,
            commerce: [corridor: :subscription_default, role: :paywall_entry]
          ]
        )
      end
    end
  end

  defmodule PurchaseCorridorRouter do
    use Crosswake.Router

    scope "/" do
      crosswake_defaults runtime: :native_screen, offline: :unavailable, security: :sensitive do
        live("/buy", Crosswake.TestSupport.StudySessionLive,
          crosswake: [
            id: "buy",
            runtime: :native_screen,
            commerce: [corridor: :subscription_default, role: :purchase_intent]
          ]
        )
      end
    end
  end

  test "doctor exposes a typed commerce_summary surface with the canonical keys", %{
    target: target,
    install_manifest_path: install_manifest_path
  } do
    report =
      Doctor.run(
        route_source: PaywallCorridorRouter,
        install_manifest_path: install_manifest_path,
        cwd: target
      )

    summary = report.commerce_summary

    assert is_map(summary)

    assert MapSet.new(Map.keys(summary)) ==
             MapSet.new([
               :corridors,
               :prerequisites,
               :snapshot_freshness,
               :proof_posture,
               :rebuild_requirements
             ])

    assert Enum.any?(summary.corridors, fn corridor ->
             corridor.route_id == "paywall" and corridor.role == "paywall_entry" and
               corridor.proof_class == :merge_blocking
           end)

    assert Map.has_key?(summary.prerequisites, "paywall")
    assert summary.snapshot_freshness in [:fresh, :stale, :unknown, :not_applicable]
    assert is_map(summary.proof_posture)
    assert Map.has_key?(summary.proof_posture, :merge_blocking)
    assert Map.has_key?(summary.proof_posture, :advisory)
    assert is_list(summary.rebuild_requirements)
  end

  test "commerce_summary returns the not_applicable freshness baseline when no commerce routes exist",
       %{target: target, install_manifest_path: install_manifest_path} do
    report =
      Doctor.run(
        route_source: Crosswake.TestSupport.RouterFixtures.ManagedRouter,
        install_manifest_path: install_manifest_path,
        cwd: target
      )

    assert report.commerce_summary.snapshot_freshness == :not_applicable
    assert report.commerce_summary.corridors == []
    assert report.commerce_summary.rebuild_requirements == []
    refute Enum.any?(report.findings, &(&1.code == "commerce.entitlement.stale_snapshot"))
    refute Enum.any?(report.findings, &(&1.code == "commerce.corridor.native_rebuild_required"))
  end

  test "commerce_summary does not emit commerce.corridor.role_unknown when every route role maps to canonical SupportMatrix taxonomy",
       %{target: target, install_manifest_path: install_manifest_path} do
    # Forward-compatible fail-closed contract: when a commerce route's role is
    # not in Crosswake.SupportMatrix.commerce_corridors/0, doctor must emit a
    # merge-blocking commerce.corridor.role_unknown finding (paired with an
    # explicit :unknown row in commerce_summary.corridors). Today the manifest
    # validator rejects unknown roles before they reach doctor, so the canonical
    # fixtures never trigger the finding — assert that, so a future change that
    # widens corridor role acceptance without updating the SupportMatrix
    # taxonomy fails this test rather than silently producing :unknown rows.
    report =
      Doctor.run(
        route_source: PaywallCorridorRouter,
        install_manifest_path: install_manifest_path,
        cwd: target,
        entitlement_snapshot_freshness: :fresh
      )

    refute Enum.any?(report.findings, &(&1.code == "commerce.corridor.role_unknown")),
           "canonical fixtures should not surface commerce.corridor.role_unknown; got findings: #{inspect(Enum.map(report.findings, & &1.code))}"

    # Every emitted corridor row has a resolved (non-:unknown) proof_class.
    refute Enum.any?(report.commerce_summary.corridors, &(&1.proof_class == :unknown)),
           "no commerce_summary corridor row should carry :unknown proof_class for canonical fixtures"
  end

  test "stale entitlement freshness emits a merge-blocking warning finding", %{
    target: target,
    install_manifest_path: install_manifest_path
  } do
    report =
      Doctor.run(
        route_source: PaywallCorridorRouter,
        install_manifest_path: install_manifest_path,
        cwd: target,
        entitlement_snapshot_freshness: :stale
      )

    stale_finding =
      Enum.find(report.findings, &(&1.code == "commerce.entitlement.stale_snapshot"))

    assert stale_finding
    assert stale_finding.severity == :warning
    assert stale_finding.check == "commerce_summary"
    assert stale_finding.details[:proof_class] == "merge_blocking"
    assert stale_finding.details[:freshness] == "stale"
    assert report.commerce_summary.snapshot_freshness == :stale

    assert "commerce.entitlement.stale_snapshot" in report.commerce_summary.proof_posture.merge_blocking
  end

  test "unknown entitlement freshness defaults to fail-closed merge-blocking truth when commerce routes exist",
       %{target: target, install_manifest_path: install_manifest_path} do
    report =
      Doctor.run(
        route_source: PaywallCorridorRouter,
        install_manifest_path: install_manifest_path,
        cwd: target
      )

    assert report.commerce_summary.snapshot_freshness == :unknown

    assert Enum.any?(
             report.findings,
             &(&1.code == "commerce.entitlement.stale_snapshot" and
                 &1.details[:proof_class] == "merge_blocking")
           )
  end

  test "entitlement_snapshot_freshness: :not_applicable is coerced to :unknown when commerce routes are present",
       %{target: target, install_manifest_path: install_manifest_path} do
    # :not_applicable is reserved as the default when no commerce routes are
    # declared. When commerce routes ARE present, accepting :not_applicable
    # would silently bypass the fail-closed stale-snapshot finding. Phase 23
    # D-04 requires stale/unknown to be merge-blocking and fail-closed; coerce
    # :not_applicable -> :unknown so the diagnostic still fires.
    report =
      Doctor.run(
        route_source: PaywallCorridorRouter,
        install_manifest_path: install_manifest_path,
        cwd: target,
        entitlement_snapshot_freshness: :not_applicable
      )

    assert report.commerce_summary.snapshot_freshness == :unknown,
           "expected :not_applicable to be coerced to :unknown when commerce routes are present"

    assert Enum.any?(
             report.findings,
             &(&1.code == "commerce.entitlement.stale_snapshot" and
                 &1.details[:proof_class] == "merge_blocking")
           ),
           "expected merge-blocking stale_snapshot finding even with :not_applicable opt + commerce routes"
  end

  test "fresh entitlement freshness suppresses the stale snapshot finding", %{
    target: target,
    install_manifest_path: install_manifest_path
  } do
    report =
      Doctor.run(
        route_source: PaywallCorridorRouter,
        install_manifest_path: install_manifest_path,
        cwd: target,
        entitlement_snapshot_freshness: :fresh
      )

    assert report.commerce_summary.snapshot_freshness == :fresh
    refute Enum.any?(report.findings, &(&1.code == "commerce.entitlement.stale_snapshot"))
  end

  test "native rebuild requirements are derived from canonical support matrix metadata", %{
    target: target,
    install_manifest_path: install_manifest_path
  } do
    report =
      Doctor.run(
        route_source: PurchaseCorridorRouter,
        install_manifest_path: install_manifest_path,
        cwd: target,
        entitlement_snapshot_freshness: :fresh
      )

    rebuild_finding =
      Enum.find(report.findings, &(&1.code == "commerce.corridor.native_rebuild_required"))

    assert rebuild_finding
    assert rebuild_finding.severity == :warning
    assert rebuild_finding.check == "commerce_summary"
    assert rebuild_finding.details[:role] == "purchase_intent"
    assert rebuild_finding.details[:route_id] == "buy"
    assert rebuild_finding.details[:proof_class] == "merge_blocking"

    expected_rebuild_roles =
      SupportMatrix.commerce_corridors()
      |> Enum.filter(& &1.native_rebuild_required)
      |> Enum.map(& &1.corridor_role)

    assert "purchase_intent" in expected_rebuild_roles

    assert Enum.any?(report.commerce_summary.rebuild_requirements, fn requirement ->
             requirement.role == "purchase_intent" and requirement.route_id == "buy"
           end)
  end

  test "native_rebuild_satisfied? suppresses the native rebuild finding without removing rebuild_requirements truth",
       %{target: target, install_manifest_path: install_manifest_path} do
    report =
      Doctor.run(
        route_source: PurchaseCorridorRouter,
        install_manifest_path: install_manifest_path,
        cwd: target,
        entitlement_snapshot_freshness: :fresh,
        native_rebuild_satisfied?: true
      )

    refute Enum.any?(report.findings, &(&1.code == "commerce.corridor.native_rebuild_required"))

    assert Enum.any?(report.commerce_summary.rebuild_requirements, fn requirement ->
             requirement.role == "purchase_intent"
           end)
  end

  test "phase 19 commerce corridor findings now carry proof_class labels", %{
    target: target,
    install_manifest_path: install_manifest_path
  } do
    report =
      Doctor.run(
        route_source: CommerceCorridorRouter,
        install_manifest_path: install_manifest_path,
        cwd: target
      )

    assert Enum.all?(
             report.findings
             |> Enum.filter(&String.starts_with?(&1.code, "commerce.corridor.")),
             fn finding -> Map.has_key?(finding.details, :proof_class) end
           )
  end

  defmodule BoundaryViolationRouter do
    use Crosswake.Router

    scope "/" do
      crosswake_defaults runtime: :offline_island, offline: :local_first, security: :standard do
        live("/violator", Crosswake.TestSupport.StudySessionLive,
          crosswake: [
            id: "violator",
            island_contract: :violator_v1,
            capabilities: ["background_sync", "generic_plugin_bus"]
          ]
        )
      end
    end
  end

  test "doctor catches explicit v1 boundaries like background_sync on offline_island", %{
    target: target,
    install_manifest_path: install_manifest_path
  } do
    report =
      Doctor.run(
        route_source: BoundaryViolationRouter,
        install_manifest_path: install_manifest_path,
        cwd: target
      )

    assert report.status == :error

    sync_finding =
      Enum.find(
        report.findings,
        &(&1.code == "unsupported_capability" and &1.details.capability == "background_sync")
      )

    assert sync_finding
    assert sync_finding.severity == :error
    assert sync_finding.message =~ "requests background_sync which is an explicit v1 boundary"

    plugin_finding =
      Enum.find(
        report.findings,
        &(&1.code == "unsupported_capability" and &1.details.capability == "generic_plugin_bus")
      )

    assert plugin_finding
    assert plugin_finding.severity == :error

    assert plugin_finding.message =~
             "requests generic_plugin_bus which is an explicit v1 boundary"
  end

  # -- Phase 23 Plan 04 Task 3: advisory proof-boundary contract --
  #
  # The advisory boundary contract requires that any advisory-class finding
  # surfaced by the doctor pipeline carries an explicit `promotion_path` hint
  # explaining what would need to change for the finding to become merge-blocking.
  # Advisory findings never assert core support truth; they are visible
  # supplementary evidence. These tests reinforce that contract at the unit
  # level alongside the proof-lane integration test in
  # test/crosswake/proof/phase23_commerce_support_proof_test.exs.

  test "advisory commerce findings (when emitted) cannot assert core support truth and carry explicit provider context",
       %{target: target, install_manifest_path: install_manifest_path} do
    report =
      Doctor.run(
        route_source: PurchaseCorridorRouter,
        install_manifest_path: install_manifest_path,
        cwd: target,
        entitlement_snapshot_freshness: :fresh,
        native_rebuild_satisfied?: true
      )

    advisory_commerce_findings =
      report.findings
      |> Enum.filter(fn finding ->
        (String.starts_with?(finding.code, "commerce.") or
           finding.check in ["commerce_corridor", "commerce_summary"]) and
          Map.get(finding.details, :proof_class) in ["advisory", :advisory]
      end)

    # Today no commerce finding emits proof_class :advisory directly — every
    # corridor row is merge_blocking. The advisory_provider_proof flag rides
    # alongside in commerce_summary.proof_posture.advisory entries. Assert the
    # contract that IF such findings appear, they must never claim merge-blocking
    # core support truth.
    for finding <- advisory_commerce_findings do
      refute Map.get(finding.details, :proof_class) in ["merge_blocking", :merge_blocking],
             "advisory commerce finding #{finding.code} cannot also claim merge_blocking proof_class"

      assert finding.severity in [:advisory, :warning],
             "advisory commerce finding #{finding.code} must have advisory/warning severity, not error"
    end

    # The commerce_summary.proof_posture surface separates merge_blocking from
    # advisory lists; this is the canonical place advisory commerce results
    # appear. Assert that the two lists are disjoint (an advisory entry cannot
    # double-count as merge_blocking core support truth).
    summary = report.commerce_summary

    overlap =
      MapSet.intersection(
        MapSet.new(summary.proof_posture.merge_blocking),
        MapSet.new(summary.proof_posture.advisory)
      )

    assert MapSet.size(overlap) == 0,
           "commerce_summary.proof_posture merge_blocking and advisory lists must be disjoint, got overlap #{inspect(MapSet.to_list(overlap))}"
  end

  test "advisory findings include a promotion_path hint explaining merge-blocking promotion requirements",
       %{target: target, install_manifest_path: install_manifest_path} do
    # The doctor capability_proof_advisory finding is the canonical advisory
    # finding shape today. It must carry an explicit promotion_path hint so
    # operators can see what would need to change for the finding's lane to
    # become merge-blocking (matches the contract language in
    # .github/workflows/phase23-proof.yml).
    report =
      Doctor.run(
        route_source: Crosswake.TestSupport.RouterFixtures.ManagedRouter,
        install_manifest_path: install_manifest_path,
        cwd: target
      )

    advisory_findings =
      report.findings
      |> Enum.filter(fn finding ->
        finding.severity == :advisory and
          Map.get(finding.details, :proof_class) in ["advisory", :advisory]
      end)

    assert advisory_findings != [],
           "expected at least one advisory finding (e.g. capability_proof_advisory) from the fixture router"

    for finding <- advisory_findings do
      assert Map.has_key?(finding.details, :promotion_path),
             "advisory finding #{finding.code} missing :promotion_path hint in details"

      promotion_path = Map.get(finding.details, :promotion_path)

      assert is_binary(promotion_path) and promotion_path != "",
             "advisory finding #{finding.code} promotion_path must be a non-empty string, got #{inspect(promotion_path)}"

      # The promotion_path must explicitly reference the requirement/roadmap
      # scope change requirement so operators cannot misread advisory passing
      # as a green-light for support promotion.
      assert promotion_path =~ ~r/requirement|roadmap/i,
             "advisory finding #{finding.code} promotion_path must mention requirement/roadmap scope change, got #{inspect(promotion_path)}"
    end
  end

  defmodule GatingIntegrationRouter do
    use Crosswake.Router

    scope "/" do
      crosswake_defaults runtime: :live_view, offline: :unavailable, security: :standard do
        live("/gated-feature", Crosswake.TestSupport.StudySessionLive,
          crosswake: [
            id: "gated_feature",
            runtime: :live_view,
            gated_by: :unregistered_companion
          ]
        )
      end
    end
  end

  defmodule AuthPredicatedIntegrationRouter do
    use Crosswake.Router

    scope "/" do
      crosswake_defaults runtime: :live_view, offline: :unavailable, security: :standard do
        live("/auth-secure", Crosswake.TestSupport.StudySessionLive,
          crosswake: [
            id: "auth_secure",
            runtime: :live_view,
            auth_min_level: :mfa,
            requires_recent_auth: 600
          ]
        )
      end
    end
  end

  test "gating findings surface in formatted Doctor output (human and JSON)", %{
    target: target,
    install_manifest_path: install_manifest_path
  } do
    # No companions registered — Application.get_env returns [] by default.
    # A route gated by an unregistered companion produces both findings:
    #   :advisory "gating.route_gated"          — one per gated route
    #   :error   "gating.flag_reference_unknown" — companion not in registry
    report =
      Doctor.run(
        route_source: GatingIntegrationRouter,
        install_manifest_path: install_manifest_path,
        cwd: target
      )

    gating_findings = Enum.filter(report.findings, &String.starts_with?(&1.code, "gating."))

    assert Enum.any?(
             gating_findings,
             &(&1.code == "gating.route_gated" and &1.severity == :advisory)
           )

    assert Enum.any?(
             gating_findings,
             &(&1.code == "gating.flag_reference_unknown" and &1.severity == :error)
           )

    human = Formatter.render(report)
    decoded = JSONFormatter.render(report) |> Jason.decode!()

    assert human =~ "gating.route_gated"
    assert human =~ "gating.flag_reference_unknown"

    finding_codes = Enum.map(decoded["findings"], & &1["code"])
    assert "gating.route_gated" in finding_codes
    assert "gating.flag_reference_unknown" in finding_codes
  end

  test "auth findings surface in formatted Doctor output (human and JSON) without sensitive artifacts",
       %{target: target, install_manifest_path: install_manifest_path} do
    report =
      Doctor.run(
        route_source: AuthPredicatedIntegrationRouter,
        install_manifest_path: install_manifest_path,
        cwd: target
      )

    auth_findings = Enum.filter(report.findings, &String.starts_with?(&1.code, "auth."))

    assert Enum.any?(
             auth_findings,
             &(&1.code == "auth.route_predicated" and
                 &1.details[:route_id] == "auth_secure" and
                 &1.details[:auth_min_level] == :mfa and
                 &1.details[:requires_recent_auth] == 600 and
                 &1.details[:auth_posture] == :strict_recent)
           )

    assert Enum.any?(auth_findings, &(&1.code == "auth.step_up_required_contract"))

    human = Formatter.render(report)
    decoded = JSONFormatter.render(report) |> Jason.decode!()

    assert human =~ "auth.route_predicated"
    assert human =~ "auth.step_up_required_contract"
    assert human =~ "route_id=auth_secure"
    assert human =~ "auth_min_level=mfa"
    assert human =~ "requires_recent_auth=600"
    assert human =~ "auth_posture=strict_recent"

    json_route_finding =
      Enum.find(decoded["findings"], fn finding ->
        finding["code"] == "auth.route_predicated"
      end)

    assert json_route_finding["details"]["route_id"] == "auth_secure"
    assert json_route_finding["details"]["auth_min_level"] == "mfa"
    assert json_route_finding["details"]["requires_recent_auth"] == 600
    assert json_route_finding["details"]["auth_posture"] == "strict_recent"

    contract_finding =
      Enum.find(decoded["findings"], &(&1["code"] == "auth.step_up_required_contract"))

    assert contract_finding

    assert contract_finding["details"]["shipped_contracts"] == [
             "session_authority",
             "handoff_ticket",
             "server_record_redemption",
             "step_up_intent",
             "plug_liveview_ceremony",
             "auth_return_boundary",
             "auth_return_attempt"
           ]

    assert contract_finding["details"]["handoff"]["authority_source"] == "server_record"
    assert contract_finding["details"]["step_up"]["status"] == "shipped"
    assert contract_finding["details"]["auth_return"]["status"] == "shipped"
    # D-137-03: denial_codes and safe_detail_keys are runtime-populated from Sigra.
    # Without Sigra in :companions, sentinel [] is returned. Non-vacuous assertions
    # live in packages/crosswake_sigra/test/ (phase58_auth_diagnostics_closeout_test.exs).
    assert is_list(contract_finding["details"]["denial_codes"])
    assert is_list(contract_finding["details"]["safe_detail_keys"])
    refute "handoff" in contract_finding["details"]["deferred"]
    refute "ceremony" in contract_finding["details"]["deferred"]

    sensitive_artifacts = [
      "session_id",
      "actor_id",
      "access_token",
      "raw_refresh_token",
      "passkey_credential"
    ]

    auth_human_lines =
      human
      |> String.split("\n")
      |> Enum.filter(&String.contains?(&1, " auth."))
      |> Enum.join("\n")

    auth_json_payload =
      decoded["findings"]
      |> Enum.filter(&String.starts_with?(&1["code"] || "", "auth."))
      |> Jason.encode!()
      |> String.downcase()

    for artifact <- sensitive_artifacts do
      refute String.contains?(String.downcase(auth_human_lines), artifact)
      refute String.contains?(auth_json_payload, artifact)
    end
  end

  defmodule NotificationIntegrationRouter do
    use Crosswake.Router

    scope "/" do
      crosswake_defaults runtime: :live_view, offline: :unavailable, security: :standard do
        live("/notify", Crosswake.TestSupport.StudySessionLive,
          crosswake: [
            id: "notify",
            runtime: :live_view,
            capabilities: ["notification_token"],
            notification_open: true
          ]
        )
      end
    end
  end

  test "notification findings surface in formatted Doctor output when configured", %{
    target: target,
    install_manifest_path: install_manifest_path
  } do
    report =
      Doctor.run(
        route_source: NotificationIntegrationRouter,
        install_manifest_path: install_manifest_path,
        cwd: target
      )

    notification_findings =
      Enum.filter(report.findings, &String.starts_with?(&1.code, "notification."))

    assert Enum.any?(
             notification_findings,
             &(&1.code == "notification.telemetry_contract" and &1.severity == :advisory)
           )

    assert Enum.any?(
             notification_findings,
             &(&1.code == "notification.delivery_deferred" and &1.severity == :advisory)
           )
  end

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

    write_file!(
      Path.join(ios_root, "CrosswakeShell/Info.plist"),
      "WKAppBoundDomains\nNSCameraUsageDescription\nNSPhotoLibraryUsageDescription\naps-environment\nNSPrivacyCollectedDataTypeDeviceID\ncom.apple.developer.associated-domains\n"
    )

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

  # Phase 65 — DIAG-04: unconditional :advisory doctor finding
  describe "phase_65_diagnostic_export finding (DIAG-04)" do
    test "run/1 includes exactly one finding with code diagnostic_export.contract_shipped",
         %{target: target, install_manifest_path: install_manifest_path} do
      report =
        Doctor.run(
          route_source: Crosswake.TestSupport.RouterFixtures.ManagedRouter,
          install_manifest_path: install_manifest_path,
          cwd: target
        )

      matching = Enum.filter(report.findings, &(&1.code == "diagnostic_export.contract_shipped"))
      assert length(matching) == 1
    end

    test "the diagnostic_export.contract_shipped finding has severity :advisory",
         %{target: target, install_manifest_path: install_manifest_path} do
      report =
        Doctor.run(
          route_source: Crosswake.TestSupport.RouterFixtures.ManagedRouter,
          install_manifest_path: install_manifest_path,
          cwd: target
        )

      finding =
        Enum.find(report.findings, &(&1.code == "diagnostic_export.contract_shipped"))

      assert finding != nil
      assert finding.severity == :advisory
    end

    test "the finding fires unconditionally — no notification routes in manifest",
         %{target: target, install_manifest_path: install_manifest_path} do
      # Run with a manifest that has no notification routes; finding must still appear
      # (unconditional — not gated on notification/manifest state, unlike phase_62)
      report =
        Doctor.run(
          route_source: Crosswake.TestSupport.RouterFixtures.ManagedRouter,
          install_manifest_path: install_manifest_path,
          cwd: target
        )

      matching = Enum.filter(report.findings, &(&1.code == "diagnostic_export.contract_shipped"))

      assert length(matching) == 1,
             "diagnostic_export.contract_shipped must fire unconditionally regardless of notification routes"
    end

    test "the finding message does NOT contain the phrase 'crash-reporting service'",
         %{target: target, install_manifest_path: install_manifest_path} do
      report =
        Doctor.run(
          route_source: Crosswake.TestSupport.RouterFixtures.ManagedRouter,
          install_manifest_path: install_manifest_path,
          cwd: target
        )

      finding =
        Enum.find(report.findings, &(&1.code == "diagnostic_export.contract_shipped"))

      assert finding != nil

      refute String.contains?(finding.message, "crash-reporting service"),
             "doctor finding message must not contain 'crash-reporting service' (seam language lives in SupportMatrix posture)"
    end

    test "the finding details carry delivery_supported: false",
         %{target: target, install_manifest_path: install_manifest_path} do
      report =
        Doctor.run(
          route_source: Crosswake.TestSupport.RouterFixtures.ManagedRouter,
          install_manifest_path: install_manifest_path,
          cwd: target
        )

      finding =
        Enum.find(report.findings, &(&1.code == "diagnostic_export.contract_shipped"))

      assert finding != nil
      assert finding.details.delivery_supported == false
    end

    test "the finding details carry the 3-atom deferred list",
         %{target: target, install_manifest_path: install_manifest_path} do
      report =
        Doctor.run(
          route_source: Crosswake.TestSupport.RouterFixtures.ManagedRouter,
          install_manifest_path: install_manifest_path,
          cwd: target
        )

      finding =
        Enum.find(report.findings, &(&1.code == "diagnostic_export.contract_shipped"))

      assert finding != nil
      assert :native_diagnostic_export in finding.details.deferred
      assert :metrickit_capture in finding.details.deferred
      assert :application_exit_info_capture in finding.details.deferred
    end

    test "the finding details carry authority_source: :host_configured_endpoint",
         %{target: target, install_manifest_path: install_manifest_path} do
      report =
        Doctor.run(
          route_source: Crosswake.TestSupport.RouterFixtures.ManagedRouter,
          install_manifest_path: install_manifest_path,
          cwd: target
        )

      finding =
        Enum.find(report.findings, &(&1.code == "diagnostic_export.contract_shipped"))

      assert finding != nil
      assert finding.details.authority_source == :host_configured_endpoint
    end
  end

  # Phase 154 — D-58/D-59/D-63: doctor's legacy-capability-id advisory
  defmodule LegacyCapabilityRouter do
    use Crosswake.Router

    scope "/" do
      get("/legacy-one", Crosswake.TestSupport.PageController, :index,
        crosswake: [
          id: "legacy-one",
          runtime: :live_view,
          security: :standard,
          capabilities: ["haptics.impact"]
        ]
      )

      get("/legacy-two", Crosswake.TestSupport.PageController, :index,
        crosswake: [
          id: "legacy-two",
          runtime: :live_view,
          security: :standard,
          capabilities: ["haptics.impact"]
        ]
      )
    end
  end

  defmodule FamilyOnlyCapabilityRouter do
    use Crosswake.Router

    scope "/" do
      get("/family-only", Crosswake.TestSupport.PageController, :index,
        crosswake: [
          id: "family-only",
          runtime: :live_view,
          security: :standard,
          capabilities: ["haptics"]
        ]
      )
    end
  end

  defmodule RebuildRequiredRouter do
    use Crosswake.Router

    scope "/" do
      get("/native-rebuild", Crosswake.TestSupport.PageController, :index,
        crosswake: [
          id: "native-rebuild",
          runtime: :live_view,
          security: :standard,
          capabilities: ["file_picker"]
        ]
      )

      get("/companion-rebuild", Crosswake.TestSupport.PageController, :index,
        crosswake: [
          id: "companion-rebuild",
          runtime: :live_view,
          security: :standard,
          capabilities: ["notification_token"]
        ]
      )
    end
  end

  describe "legacy capability id doctor advisory (D-58, D-59, D-63)" do
    test "a manifest whose route declares only family ids produces zero legacy-id advisory findings",
         %{target: target, install_manifest_path: install_manifest_path} do
      report =
        Doctor.run(
          route_source: FamilyOnlyCapabilityRouter,
          install_manifest_path: install_manifest_path,
          cwd: target
        )

      assert Enum.filter(report.findings, &(&1.code == "capability.legacy_capability_id")) == []
    end

    test "a manifest whose route declares a legacy id produces exactly one advisory finding for that route, naming both ids",
         %{target: target, install_manifest_path: install_manifest_path} do
      report =
        Doctor.run(
          route_source: LegacyCapabilityRouter,
          install_manifest_path: install_manifest_path,
          cwd: target
        )

      matching =
        Enum.filter(report.findings, fn finding ->
          finding.code == "capability.legacy_capability_id" and
            finding.details.route_id == "legacy-one"
        end)

      assert length(matching) == 1

      [finding] = matching
      assert finding.message =~ "haptics.impact"
      assert finding.message =~ "haptics"
      assert finding.details.legacy_capability_id == "haptics.impact"
      assert finding.details.family_capability_id == "haptics"
    end

    test "the finding severity is advisory (:warning) — never :error — so a legacy declaration never fails doctor (D-58, D-63)",
         %{target: target, install_manifest_path: install_manifest_path} do
      report =
        Doctor.run(
          route_source: LegacyCapabilityRouter,
          install_manifest_path: install_manifest_path,
          cwd: target
        )

      legacy_findings =
        Enum.filter(report.findings, &(&1.code == "capability.legacy_capability_id"))

      assert legacy_findings != []
      assert Enum.all?(legacy_findings, &(&1.severity != :error))
      assert Enum.all?(legacy_findings, &(&1.severity == :warning))
    end

    test "two routes declaring the same legacy id produce two findings, one per route",
         %{target: target, install_manifest_path: install_manifest_path} do
      report =
        Doctor.run(
          route_source: LegacyCapabilityRouter,
          install_manifest_path: install_manifest_path,
          cwd: target
        )

      legacy_findings =
        Enum.filter(report.findings, &(&1.code == "capability.legacy_capability_id"))

      assert length(legacy_findings) == 2

      assert legacy_findings |> Enum.map(& &1.details.route_id) |> Enum.sort() ==
               ["legacy-one", "legacy-two"]
    end
  end

  describe "capability rebuild finding (D-49, CTRL-05)" do
    test "a manifest whose declared capabilities are all rebuild: :none produces an empty capability-rebuild findings list",
         %{target: target, install_manifest_path: install_manifest_path} do
      report =
        Doctor.run(
          route_source: FamilyOnlyCapabilityRouter,
          install_manifest_path: install_manifest_path,
          cwd: target
        )

      assert Enum.filter(
               report.findings,
               &(&1.code == "bridge.capability.native_rebuild_required")
             ) ==
               []
    end

    test "a route declaring a rebuild: :native_required capability produces exactly one finding naming the route, capability, and rebuild class",
         %{target: target, install_manifest_path: install_manifest_path} do
      report =
        Doctor.run(
          route_source: RebuildRequiredRouter,
          install_manifest_path: install_manifest_path,
          cwd: target
        )

      matching =
        Enum.filter(report.findings, fn finding ->
          finding.code == "bridge.capability.native_rebuild_required" and
            finding.details.route_id == "native-rebuild"
        end)

      assert length(matching) == 1

      [finding] = matching
      assert finding.message =~ "native-rebuild"
      assert finding.message =~ "file_picker"
      assert finding.message =~ "native"
      assert finding.details.capability_id == "file_picker"
      assert finding.details.rebuild == "native_required"
      assert finding.severity == :warning
    end

    test "a rebuild: :companion_required capability produces a finding whose hint points at the companion rebuild path, not the native one",
         %{target: target, install_manifest_path: install_manifest_path} do
      report =
        Doctor.run(
          route_source: RebuildRequiredRouter,
          install_manifest_path: install_manifest_path,
          cwd: target
        )

      [finding] =
        Enum.filter(report.findings, fn finding ->
          finding.code == "bridge.capability.native_rebuild_required" and
            finding.details.route_id == "companion-rebuild"
        end)

      assert finding.details.capability_id == "notification_token"
      assert finding.details.rebuild == "companion_required"
      assert finding.hint =~ "companion package"
      refute finding.hint =~ "rebuild and resubmit the native shell binary"
    end

    test "a capability with a non-:none rebuild class declared on no active route produces no finding",
         %{target: target, install_manifest_path: install_manifest_path} do
      report =
        Doctor.run(
          route_source: RebuildRequiredRouter,
          install_manifest_path: install_manifest_path,
          cwd: target
        )

      # media_capture is rebuild: :native_required in the catalog but is not
      # declared on any route in RebuildRequiredRouter — no finding names it.
      refute Enum.any?(report.findings, fn finding ->
               finding.code == "bridge.capability.native_rebuild_required" and
                 finding.details.capability_id == "media_capture"
             end)
    end

    test "repeated runs over the same manifest emit capability-rebuild findings in identical order",
         %{target: target, install_manifest_path: install_manifest_path} do
      report1 =
        Doctor.run(
          route_source: RebuildRequiredRouter,
          install_manifest_path: install_manifest_path,
          cwd: target
        )

      report2 =
        Doctor.run(
          route_source: RebuildRequiredRouter,
          install_manifest_path: install_manifest_path,
          cwd: target
        )

      extract = fn report ->
        report.findings
        |> Enum.filter(&(&1.code == "bridge.capability.native_rebuild_required"))
        |> Enum.map(&{&1.details.route_id, &1.details.capability_id})
      end

      assert extract.(report1) == extract.(report2)
      assert extract.(report1) != []
    end
  end

  # D-37: the bridge hook wiring check is a BEST-EFFORT host-file grep. The
  # authoritative detector is the runtime ack deadline in Crosswake.Bridge; these
  # tests assert the advisory nudge, and that it never escalates past advisory.
  describe "bridge hook wiring findings" do
    setup do
      host =
        Path.join(
          System.tmp_dir!(),
          "crosswake-bridge-hook-#{System.unique_integer([:positive])}"
        )

      File.mkdir_p!(host)
      on_exit(fn -> File.rm_rf!(host) end)

      %{host: host}
    end

    test "reports a finding when no hook reference exists in either tree", %{host: host} do
      File.mkdir_p!(Path.join(host, "lib/demo_web"))

      File.write!(
        Path.join(host, "lib/demo_web/layouts.ex"),
        "defmodule DemoWeb.Layouts do\nend\n"
      )

      findings = Doctor.bridge_hook_wiring_findings(host)

      assert [%Check{} = finding] = findings
      assert finding.code == "bridge.hook.not_wired"
      assert finding.severity == :advisory
      assert finding.message =~ "CrosswakeBridge"
      assert finding.hint =~ "never authoritative"
      assert finding.details.authoritative == false
    end

    test "reports nothing when the hook is found in a HEEx-only host with no assets directory",
         %{host: host} do
      # This is the shape of this repository's own reference host: NO bundler, no
      # assets tree at all, the hook element inline in a template. An assets-only
      # grep would false-negative here — which is exactly why D-37 requires both.
      File.mkdir_p!(Path.join(host, "lib/demo_web/components"))

      File.write!(
        Path.join(host, "lib/demo_web/components/layouts.ex"),
        ~s|<div id="crosswake-bridge" phx-hook="CrosswakeBridge" phx-update="ignore"></div>|
      )

      refute File.exists?(Path.join(host, "assets"))

      assert Doctor.bridge_hook_wiring_findings(host) == []
    end

    test "reports nothing when the hook is found in the assets tree only", %{host: host} do
      File.mkdir_p!(Path.join(host, "assets/js"))

      File.write!(
        Path.join(host, "assets/js/app.js"),
        ~s|import {CrosswakeBridge} from "crosswake";\n|
      )

      assert Doctor.bridge_hook_wiring_findings(host) == []
    end

    test "warns when an ejected copy's stamped protocol version is behind the contract", %{
      host: host
    } do
      File.mkdir_p!(Path.join(host, "priv/static"))
      File.mkdir_p!(Path.join(host, "assets/js"))
      File.write!(Path.join(host, "assets/js/app.js"), "CrosswakeBridge")

      File.write!(
        Path.join(host, "priv/static/crosswake.esm.js"),
        "/* crosswake:bridge-hook:ejected protocol=0.9.0 */\nexport const CrosswakeBridge = {};\n"
      )

      assert [%Check{} = finding] = Doctor.bridge_hook_wiring_findings(host)
      assert finding.code == "bridge.hook.ejected_protocol_drift"
      assert finding.severity == :warning
      assert finding.details.stamped_protocol_version == "0.9.0"
      assert finding.details.contract_version == Crosswake.Bridge.Contract.version()
    end

    test "an ejected copy stamped at the current protocol produces no drift finding", %{
      host: host
    } do
      File.mkdir_p!(Path.join(host, "priv/static"))
      File.mkdir_p!(Path.join(host, "assets/js"))
      File.write!(Path.join(host, "assets/js/app.js"), "CrosswakeBridge")

      File.write!(
        Path.join(host, "priv/static/crosswake.esm.js"),
        "/* crosswake:bridge-hook:ejected protocol=#{Crosswake.Bridge.Contract.version()} */\n"
      )

      assert Doctor.bridge_hook_wiring_findings(host) == []
    end

    test "the wiring grep never fails doctor on its own", %{host: host} do
      File.mkdir_p!(Path.join(host, "lib"))

      findings = Doctor.bridge_hook_wiring_findings(host)

      refute Enum.any?(findings, &(&1.severity == :error)),
             "the best-effort grep must never produce an error-severity finding (D-37)"
    end
  end

  # Phase 155 D-40: two findings for `mix crosswake.gen.native_controls_ui`'s
  # generated, host-owned files. Neither may overclaim what it inspected — the
  # stamp finding is a version-integer comparison, the wiring finding is a
  # best-effort grep that can never fail doctor's exit code.
  describe "native controls ui findings" do
    setup do
      host =
        Path.join(
          System.tmp_dir!(),
          "crosswake-native-controls-ui-#{System.unique_integer([:positive])}"
        )

      File.mkdir_p!(Path.join(host, "lib/demo_web/components"))
      File.mkdir_p!(Path.join(host, "priv/static/assets"))
      on_exit(fn -> File.rm_rf!(host) end)

      %{
        host: host,
        component_path: Path.join(host, "lib/demo_web/components/crosswake_fallbacks.ex"),
        stylesheet_path: Path.join(host, "priv/static/assets/crosswake_fallback.css")
      }
    end

    defp component_fixture(version) do
      """
      # crosswake:native-controls-ui template_version=#{version}
      #
      # Host-owned copy generated by `mix crosswake.gen.native_controls_ui`.

      defmodule DemoWeb.CrosswakeFallbacks do
        use Phoenix.Component
      end
      """
    end

    defp stylesheet_fixture(version) do
      """
      /* crosswake:native-controls-ui template_version=#{version}
       *
       * Host-owned copy generated by `mix crosswake.gen.native_controls_ui`.
       */

      .cwfb-modal { display: block; }
      """
    end

    test "a stamp matching the current template_version produces no drift finding (negative control)",
         %{host: host, component_path: component_path, stylesheet_path: stylesheet_path} do
      current = NativeControlsUi.template_version()

      File.write!(component_path, component_fixture(current))
      File.write!(stylesheet_path, stylesheet_fixture(current))

      # Referenced elsewhere so this test isolates the stamp check from the
      # wiring check.
      File.write!(
        Path.join(host, "lib/demo_web/some_live.ex"),
        "defmodule DemoWeb.SomeLive do\n  DemoWeb.CrosswakeFallbacks\nend\n"
      )

      findings = Doctor.native_controls_ui_findings(host)

      refute Enum.any?(findings, &(&1.code == "native_controls_ui.stamp_drift")),
             "a stamp matching the current template_version must not produce a drift finding"
    end

    test "a stamp behind the current template_version produces a stamp-drift warning naming the file and both versions",
         %{host: host, component_path: component_path} do
      current = NativeControlsUi.template_version()
      stamped = current - 1

      File.write!(component_path, component_fixture(stamped))

      File.write!(
        Path.join(host, "lib/demo_web/some_live.ex"),
        "defmodule DemoWeb.SomeLive do\n  DemoWeb.CrosswakeFallbacks\nend\n"
      )

      assert [%Check{} = finding] =
               Doctor.native_controls_ui_findings(host)
               |> Enum.filter(&(&1.code == "native_controls_ui.stamp_drift"))

      assert finding.severity == :warning
      assert finding.message =~ "crosswake_fallbacks.ex"
      assert finding.message =~ "template_version=#{stamped}"
      assert finding.message =~ "template_version=#{current}"
      assert finding.details.stamped_template_version == stamped
      assert finding.details.current_template_version == current

      # The remediation must not tell the adopter to regenerate over their
      # edits — there is no --force and never will be (D-40).
      assert finding.hint =~ "no --force"
      assert finding.hint =~ "apply by hand"
      refute finding.hint =~ "regenerate the file"
    end

    test "a stylesheet stamp behind the current template_version also produces a drift finding",
         %{host: host, stylesheet_path: stylesheet_path} do
      current = NativeControlsUi.template_version()
      stamped = current - 1

      File.write!(stylesheet_path, stylesheet_fixture(stamped))

      assert Enum.any?(
               Doctor.native_controls_ui_findings(host),
               &(&1.code == "native_controls_ui.stamp_drift" and
                   &1.details.path =~ "crosswake_fallback.css")
             )
    end

    test "an advisory wiring finding fires when the generated component has no host reference, and it says 'could not find' rather than 'is not wired'",
         %{host: host, component_path: component_path} do
      current = NativeControlsUi.template_version()
      File.write!(component_path, component_fixture(current))

      assert [%Check{} = finding] =
               Doctor.native_controls_ui_findings(host)
               |> Enum.filter(&(&1.code == "native_controls_ui.wiring"))

      assert finding.severity == :advisory
      assert finding.message =~ "could not find"
      refute finding.message =~ "is not wired"
      assert finding.details.authoritative == false
    end

    test "the wiring finding never fails doctor on its own", %{
      host: host,
      component_path: component_path
    } do
      current = NativeControlsUi.template_version()
      File.write!(component_path, component_fixture(current))

      findings = Doctor.native_controls_ui_findings(host)

      refute Enum.any?(findings, &(&1.severity == :error)),
             "the best-effort wiring grep must never produce an error-severity finding (D-40)"
    end
  end
end
