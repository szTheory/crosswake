defmodule Crosswake.Guides.CompanionsTest do
  use ExUnit.Case, async: false

  alias Crosswake.Doctor
  alias Crosswake.SupportMatrix

  @guide_path Path.join([File.cwd!(), "guides", "companions.md"])

  defmodule AuthPredicatedRouter do
    use Crosswake.Router

    scope "/" do
      crosswake_defaults runtime: :live_view, offline: :unavailable, security: :standard do
        live "/secure", Crosswake.TestSupport.StudySessionLive,
          crosswake: [
            id: "secure",
            runtime: :live_view,
            auth_min_level: :mfa,
            requires_recent_auth: 600
          ]
      end
    end
  end

  setup_all do
    content = File.read!(@guide_path)
    %{content: content}
  end

  test "includes required anchor vocabulary", %{content: content} do
    assert content =~ "Crosswake.Companion"
    assert content =~ "companion_id/0"
    assert content =~ "enabled?/1"
    assert content =~ "route_gated?/2"
    assert content =~ "kill_switch_active?/1"
    assert content =~ "validate_dependency/0"
    assert content =~ "report_state/0"
    assert content =~ "lib/crosswake/companions/<name>/"
    assert content =~ "[:crosswake, :companion, :validate_dependency]"
    assert content =~ "fail-closed"
    assert content =~ "gated_by"
    assert content =~ "on_unavailable"
    assert content =~ "MockFlagSource"
    assert content =~ "set_flag/2"
    assert content =~ ":gate_denied"
    assert content =~ ":kill_switch_active"
    assert content =~ "AuthContext"
    assert content =~ "SessionAuthorityLane"
    assert content =~ "auth_min_level"
    assert content =~ "requires_recent_auth"
    assert content =~ ":step_up_required"
    assert content =~ "companion.dependency_missing"
    assert content =~ "auth.route_predicated"
    assert content =~ "auth.step_up_required_contract"
  end

  test "includes explicit deferred non-goals", %{content: content} do
    assert content =~ "Chimeway"
    assert content =~ "Full Sigra machinery"
    assert content =~ "Threadline"
    assert content =~ "Separate-package extraction"
  end

  test "live code guard — contract and support modules export expected functions" do
    Code.ensure_loaded!(Crosswake.Companion)
    Code.ensure_loaded!(Crosswake.Companion.State)
    Code.ensure_loaded!(Crosswake.Companions.Rulestead)
    Code.ensure_loaded!(Crosswake.Companions.Rulestead.MockFlagSource)
    Code.ensure_loaded!(Crosswake.Companions.Rindle)
    Code.ensure_loaded!(Crosswake.Companions.Sigra.Contracts)
    Code.ensure_loaded!(Crosswake.SupportMatrix)
    Code.ensure_loaded!(Crosswake.Shell.Denial)

    assert function_exported?(Crosswake.Companions.Rulestead, :validate_dependency, 0)
    assert function_exported?(Crosswake.Companions.Rulestead.MockFlagSource, :set_flag, 2)
    assert function_exported?(Crosswake.Companions.Rindle, :validate_dependency, 0)
    assert function_exported?(Crosswake.SupportMatrix, :gating_truth, 0)
    assert function_exported?(Crosswake.SupportMatrix, :auth_contract_truth, 0)
    assert function_exported?(Crosswake.Shell.Denial, :reasons, 0)
  end

  test "documented companion ids stay parity-locked with runtime gating truth", %{content: content} do
    original_companions = Application.get_env(:crosswake, :companions)

    Application.put_env(:crosswake, :companions, [
      Crosswake.Companions.Rulestead,
      Crosswake.Companions.Rindle
    ])

    on_exit(fn ->
      if is_nil(original_companions) do
        Application.delete_env(:crosswake, :companions)
      else
        Application.put_env(:crosswake, :companions, original_companions)
      end
    end)

    runtime_ids =
      SupportMatrix.gating_truth()
      |> Enum.map(&Atom.to_string(&1.companion_id))
      |> Enum.sort()

    documented_ids =
      ~r/Companion id:\s+`:([a-z_]+)`/
      |> Regex.scan(content)
      |> Enum.map(fn [_, companion_id] -> companion_id end)
      |> Enum.sort()

    assert documented_ids == runtime_ids

    assert content =~
             "It intentionally has no runtime `Companion id:` marker yet because it is not a `Crosswake.Companion` optional dependency surface in v3.5."
  end

  test "auth predicates and denial vocabulary stay parity-locked to support and shell truth", %{content: content} do
    rows = SupportMatrix.auth_contract_truth()

    assert [_ | _] = rows

    for %{route_predicates: predicates, denial_vocabulary: denial} <- rows do
      for predicate <- predicates do
        assert content =~ Atom.to_string(predicate),
               "guide missing auth predicate #{inspect(predicate)} from SupportMatrix.auth_contract_truth/0"
      end

      assert content =~ Atom.to_string(denial),
             "guide missing auth denial vocabulary #{inspect(denial)} from SupportMatrix.auth_contract_truth/0"
    end

    denial_reasons = Crosswake.Shell.Denial.reasons()

    assert :gate_denied in denial_reasons
    assert :kill_switch_active in denial_reasons
    assert :step_up_required in denial_reasons
  end

  test "doctor finding codes are asserted from live Doctor.run/1 output", %{content: content} do
    original_companions = Application.get_env(:crosswake, :companions)
    original_rulestead = Application.get_env(:crosswake, :rulestead)
    original_rindle = Application.get_env(:crosswake, :rindle)

    Application.put_env(:crosswake, :companions, [
      Crosswake.Companions.Rulestead,
      Crosswake.Companions.Rindle
    ])

    Application.put_env(:crosswake, :rulestead, %{enabled: true})
    Application.put_env(:crosswake, :rindle, %{enabled: true})

    on_exit(fn ->
      restore_env(:companions, original_companions)
      restore_env(:rulestead, original_rulestead)
      restore_env(:rindle, original_rindle)
    end)

    report =
      Doctor.run(
        route_source: AuthPredicatedRouter,
        install_manifest_path: "priv/crosswake/install_manifest.json",
        cwd: File.cwd!()
      )

    codes = report.findings |> Enum.map(& &1.code)

    assert "companion.dependency_missing" in codes
    assert "auth.route_predicated" in codes
    assert "auth.step_up_required_contract" in codes

    assert content =~ "companion.dependency_missing"
    assert content =~ "auth.route_predicated"
    assert content =~ "auth.step_up_required_contract"
  end

  defp restore_env(key, nil), do: Application.delete_env(:crosswake, key)
  defp restore_env(key, value), do: Application.put_env(:crosswake, key, value)
end
