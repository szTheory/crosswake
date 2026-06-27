defmodule Crosswake.Proof.Phase42RulesteadCompanionTest do
  @moduledoc """
  Core hermetic proof lane for Phase 42 Rulestead companion behavior.

  Phase 130 migration note: The adapter source (Crosswake.Companions.Rulestead)
  was extracted to packages/crosswake_rulestead/ in Phase 130 Plan 04.
  The adapter-behavior tests (SC#1 gate/kill-switch) now live in the companion
  package's test lane (D-20 test split). This core test retains:

  - SC#3a: Doctor emits :error "companion.dependency_missing" when rulestead
    companion is enabled and the Rulestead library is absent from core deps.
    Uses a stub companion with companion_id: :rulestead to drive the finding.
  - SC#3b: Doctor does NOT emit dependency_missing when companion is disabled.
  - Hermeticity guard: this file must not reference the example host or require_file.

  The rulestead engine is absent from core deps (no MIX_INCLUDE_RULESTEAD;
  EXTRACT-01 guard enforces this). The stub's validate_dependency/0 returns
  {:error, [SomeAbsentModule]}, driving the SC#3 doctor finding path.

  async: false — :companions is a shared global Application key.
  """

  use ExUnit.Case, async: false

  alias Crosswake.Doctor
  alias Crosswake.TestSupport.ProofAssertions

  # ---------------------------------------------------------------------------
  # Stub rulestead companion for SC#3 doctor tests.
  # Uses companion_id: :rulestead so doctor emits "companion.rulestead" finding.
  # NOT an alias to Crosswake.Companions.Rulestead — avoids EXTRACT-03 (D-20).
  # ---------------------------------------------------------------------------

  defmodule StubRulesteadAbsentCompanion do
    @moduledoc false
    @behaviour Crosswake.Companion

    @impl true
    def companion_id, do: :rulestead

    @impl true
    def enabled?(config), do: Map.get(config, :enabled, false)

    # Simulates engine absent — Rulestead library not loaded in core deps.
    @impl true
    def validate_dependency, do: {:error, [:"Elixir.Rulestead"]}

    @impl true
    def route_gated?(_route, _target), do: :pass

    @impl true
    def kill_switch_active?(_target), do: false

    @impl true
    def report_state do
      %Crosswake.Companion.State{
        companion_id: :rulestead,
        enabled: true,
        dependency_status: {:missing, [:"Elixir.Rulestead"]},
        gate_status: :unconfigured,
        kill_switch_status: :unconfigured,
        checked_at: System.monotonic_time(:millisecond)
      }
    end
  end

  # ---------------------------------------------------------------------------
  # Inline hermetic GatingRouter for SC#3 Doctor.run tests.
  # Uses StudySessionLive (test/support stub) — no phoenix_host dependency.
  # ---------------------------------------------------------------------------

  defmodule GatingRouter do
    use Crosswake.Router

    scope "/" do
      crosswake_defaults runtime: :live_view, offline: :unavailable, security: :standard do
        live "/gating/beta-feature", Crosswake.TestSupport.StudySessionLive,
          crosswake: [
            id: "gating-beta-feature",
            gated_by: :rulestead,
            on_unavailable: :deny
          ]
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Setup: register stub companion + build temp dir for Doctor.run
  # ---------------------------------------------------------------------------

  setup do
    original_companions = Application.get_env(:crosswake, :companions, [])
    original_rulestead_config = Application.get_env(:crosswake, :rulestead, %{})

    Application.put_env(:crosswake, :companions, [StubRulesteadAbsentCompanion])
    Application.put_env(:crosswake, :rulestead, %{enabled: true})

    on_exit(fn ->
      Application.put_env(:crosswake, :companions, original_companions)
      Application.put_env(:crosswake, :rulestead, original_rulestead_config)
    end)

    # Shared temp dir for Doctor.run (SC#3 tests)
    target =
      Path.join(
        System.tmp_dir!(),
        "crosswake-phase42-proof-#{System.unique_integer([:positive])}"
      )

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

    %{target: target, install_manifest_path: install_manifest_path}
  end

  # ---------------------------------------------------------------------------
  # Hermeticity self-assertion
  # ---------------------------------------------------------------------------

  test "phase 42 rulestead proof stays hermetic — no example-host or Code.require_file dependency" do
    source = File.read!(__ENV__.file) |> String.downcase()

    refute String.contains?(source, "crosswake" <> "example.router"),
           "phase 42 rulestead proof must not depend on the example host router; keep the merge-blocking lane hermetic"

    refute Regex.match?(~r/code\.require_file\s*\(/, source),
           "phase 42 rulestead proof must not Code.require_file example-host modules; keep the lane hermetic"
  end

  # ---------------------------------------------------------------------------
  # SC#3a: companion enabled + Rulestead absent -> :error companion.dependency_missing
  # Uses stub companion (NOT Crosswake.Companions.Rulestead alias — avoids EXTRACT-03, D-20)
  # The stub has companion_id: :rulestead and validate_dependency returning {:error, _}
  # ---------------------------------------------------------------------------

  test "SC#3a: Doctor emits companion.dependency_missing :error when rulestead enabled and Rulestead library absent",
       %{target: target, install_manifest_path: install_manifest_path} do
    # setup registers StubRulesteadAbsentCompanion with %{enabled: true}

    report =
      Doctor.run(
        route_source: GatingRouter,
        install_manifest_path: install_manifest_path,
        cwd: target
      )

    finding = Enum.find(report.findings, &(&1.code == "companion.dependency_missing"))

    assert finding != nil,
           ProofAssertions.stable_id_message(
             "proof.sc3a.companion.dependency_missing",
             "Doctor must emit companion.dependency_missing :error when rulestead enabled and engine absent",
             "Doctor.run/1",
             "no companion.dependency_missing finding; findings: #{inspect(Enum.map(report.findings, & &1.code))}",
             "lib/crosswake/doctor/doctor.ex",
             "doctor.ex phase_38_companion_seam_findings/0 emits the finding when validate_dependency/0 returns {:error, _}",
             :merge_blocking
           )

    assert finding.severity == :error,
           "expected :error severity; got #{inspect(finding.severity)}"

    assert String.contains?(finding.message, "Rulestead") or
             String.contains?(finding.message, "rulestead"),
           "expected finding.message to name Rulestead; got: #{inspect(finding.message)}"

    assert finding.check == "companion.rulestead",
           "expected finding.check 'companion.rulestead'; got #{inspect(finding.check)}"
  end

  # ---------------------------------------------------------------------------
  # SC#3b: companion disabled + Rulestead absent -> no dependency_missing finding
  # ---------------------------------------------------------------------------

  test "SC#3b: no companion.dependency_missing finding when rulestead companion is disabled",
       %{target: target, install_manifest_path: install_manifest_path} do
    # Override the companion config to disabled for this test
    Application.put_env(:crosswake, :rulestead, %{enabled: false})

    on_exit(fn ->
      Application.delete_env(:crosswake, :rulestead)
    end)

    report =
      Doctor.run(
        route_source: GatingRouter,
        install_manifest_path: install_manifest_path,
        cwd: target
      )

    dependency_missing_findings =
      Enum.filter(report.findings, &(&1.code == "companion.dependency_missing"))

    assert dependency_missing_findings == [],
           "expected no companion.dependency_missing findings when rulestead is disabled; got: #{inspect(dependency_missing_findings)}"
  end
end
