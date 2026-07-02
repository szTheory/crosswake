defmodule Crosswake.Proof.Phase137SigraCleanroomTest do
  # D-137-D audit fix ③: non-vacuous clean-room proof.
  # sigra cannot self-register (packages cannot write to Application env at compile time);
  # the setup must register it explicitly so RouteGate dispatch reaches the sigra companion.
  # Without put_env, auth-predicated routes yield :dependency_missing (fail-closed) — the
  # `refute :dependency_missing` assertion makes that vacuous path a test failure.
  use ExUnit.Case, async: false

  alias Crosswake.Compatibility.RouteGate
  alias Crosswake.Compatibility.Target
  alias Crosswake.Manifest

  defmodule AuthRouter do
    use Crosswake.Router

    scope "/" do
      crosswake_defaults runtime: :live_view, offline: :unavailable, security: :standard do
        live "/secure", Crosswake.TestSupport.StudySessionLive,
          crosswake: [id: "secure", runtime: :live_view, auth_min_level: :mfa]
      end
    end
  end

  setup do
    # REQUIRED: sigra cannot self-register; test must register it explicitly.
    # Without this, auth-predicated routes get :dependency_missing not :step_up_required.
    original = Application.get_env(:crosswake, :companions, [])
    Application.put_env(:crosswake, :companions, [Crosswake.Companions.Sigra])
    on_exit(fn -> Application.put_env(:crosswake, :companions, original) end)
    :ok
  end

  test "clean-room non-vacuity: sigra registered → :step_up_required not :dependency_missing" do
    assert {:ok, %{manifest: manifest}} = Manifest.compile(AuthRouter)
    target = %Target{origin: manifest.host.origin}

    decision = RouteGate.evaluate(manifest, "secure", target, [])

    assert decision.status == :deny
    # Non-vacuous: proves registry dispatch + Finding→Denial translation actually ran.
    # Without Application.put_env above, this would be :dependency_missing (fail-closed sentinel).
    assert decision.denial.reason == :step_up_required
    refute decision.denial.reason == :dependency_missing
  end
end
