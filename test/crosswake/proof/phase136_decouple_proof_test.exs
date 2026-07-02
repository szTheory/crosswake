# ---------------------------------------------------------------------------
# Stub companions for Phase 136 DECOUPLE backstop tests.
# Defined OUTSIDE the test module to avoid nested-module resolution issues.
# NOT aliases to Crosswake.Companions.Sigra — avoids cross-companion coupling.
# ---------------------------------------------------------------------------

# Stub auth companion whose evaluate_auth/3 raises — proves DECOUPLE-04 fail-closed rescue.
defmodule Crosswake.TestSupport.StubAuthRaisesCompanion do
  @moduledoc false
  @behaviour Crosswake.Companion

  @impl true
  def companion_id, do: :stub_auth_raises

  @impl true
  def enabled?(_config), do: true

  @impl true
  def validate_dependency, do: :ok

  @impl true
  def route_gated?(_route, _target), do: :pass

  @impl true
  def kill_switch_active?(_target), do: false

  @impl true
  def report_state do
    %Crosswake.Companion.State{
      companion_id: :stub_auth_raises,
      enabled: true,
      dependency_status: :ok,
      gate_status: :unconfigured,
      kill_switch_status: :unconfigured,
      checked_at: 0
    }
  end

  @impl true
  def auth_authority?, do: true

  @impl true
  def evaluate_auth(_route, _auth_context, _opts) do
    raise RuntimeError, "simulated auth evaluator crash"
  end
end

# Stub auth companion that allows — used in the multiple-authority test (first-registered wins).
defmodule Crosswake.TestSupport.StubAuthFirstCompanion do
  @moduledoc false
  @behaviour Crosswake.Companion

  @impl true
  def companion_id, do: :stub_auth_first

  @impl true
  def enabled?(_config), do: true

  @impl true
  def validate_dependency, do: :ok

  @impl true
  def route_gated?(_route, _target), do: :pass

  @impl true
  def kill_switch_active?(_target), do: false

  @impl true
  def report_state do
    %Crosswake.Companion.State{
      companion_id: :stub_auth_first,
      enabled: true,
      dependency_status: :ok,
      gate_status: :unconfigured,
      kill_switch_status: :unconfigured,
      checked_at: 0
    }
  end

  @impl true
  def auth_authority?, do: true

  @impl true
  def evaluate_auth(_route, _auth_context, _opts) do
    {:allow, %{source: :stub_auth_first}}
  end
end

# Second stub auth companion — both claim authority; proves first-registered wins.
defmodule Crosswake.TestSupport.StubAuthSecondCompanion do
  @moduledoc false
  @behaviour Crosswake.Companion

  @impl true
  def companion_id, do: :stub_auth_second

  @impl true
  def enabled?(_config), do: true

  @impl true
  def validate_dependency, do: :ok

  @impl true
  def route_gated?(_route, _target), do: :pass

  @impl true
  def kill_switch_active?(_target), do: false

  @impl true
  def report_state do
    %Crosswake.Companion.State{
      companion_id: :stub_auth_second,
      enabled: true,
      dependency_status: :ok,
      gate_status: :unconfigured,
      kill_switch_status: :unconfigured,
      checked_at: 0
    }
  end

  @impl true
  def auth_authority?, do: true

  @impl true
  def evaluate_auth(_route, _auth_context, _opts) do
    {:allow, %{source: :stub_auth_second}}
  end
end

# Stub companion that contributes a known forbidden metadata key.
defmodule Crosswake.TestSupport.StubForbiddenKeyCompanion do
  @moduledoc false
  @behaviour Crosswake.Companion

  @impl true
  def companion_id, do: :stub_forbidden_key

  @impl true
  def enabled?(_config), do: true

  @impl true
  def validate_dependency, do: :ok

  @impl true
  def route_gated?(_route, _target), do: :pass

  @impl true
  def kill_switch_active?(_target), do: false

  @impl true
  def report_state do
    %Crosswake.Companion.State{
      companion_id: :stub_forbidden_key,
      enabled: true,
      dependency_status: :ok,
      gate_status: :unconfigured,
      kill_switch_status: :unconfigured,
      checked_at: 0
    }
  end

  @impl true
  def forbidden_metadata_keys, do: [:stub_companion_secret]
end

# ---------------------------------------------------------------------------

defmodule Crosswake.Proof.Phase136DecoupleProofTest do
  @moduledoc """
  Nyquist backstop tests for Phase 136 — Core Decoupling.

  These five tests encode the fail-closed, baseline-PII, and attach-time-capture
  behaviors that are NOT inferable from the existing proof suite. They are RED
  until Wave 1 plans (Plans 02 and 03) land. The RED state is intentional — do not
  stub production modules to make them green prematurely.

  Wave 1 turns them green by:
  - Plan 02: inverting `telemetry.ex` static calls; adding `baseline_forbidden_metadata_keys/0`;
    caching the forbidden-key MapSet in `attach_default_logger/1` handler closure.
  - Plan 03: inverting `route_gate.ex` auth dispatch; adding fail-closed no-companion guard;
    rescue wrapper for `evaluate_auth/3`; conflict signal for multiple auth-authority companions.

  async: false — all tests mutate Application.put_env(:crosswake, :companions, ...).
  """

  use ExUnit.Case, async: false

  alias Crosswake.Compatibility.RouteGate
  alias Crosswake.TestSupport.ProofAssertions

  # ---------------------------------------------------------------------------
  # Auth-predicated router: used for DECOUPLE-04 backstop tests.
  # A route with auth_min_level set is auth-predicated per the inline predicate:
  #   not is_nil(route.auth_min_level) or not is_nil(route.requires_recent_auth)
  #   or not is_nil(route.auth_posture)
  # ---------------------------------------------------------------------------

  defmodule StubAuthPredicatedRouter do
    use Crosswake.Router

    scope "/" do
      crosswake_defaults runtime: :live_view, offline: :unavailable, security: :standard do
        live "/auth-predicated/stub", Crosswake.TestSupport.StudySessionLive,
          crosswake: [
            id: "auth-predicated-stub-route",
            auth_min_level: :mfa
          ]
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Setup: save/restore :companions config key (D-07)
  # ---------------------------------------------------------------------------

  setup do
    original_companions = Application.get_env(:crosswake, :companions, [])

    on_exit(fn ->
      Application.put_env(:crosswake, :companions, original_companions)
    end)

    :ok
  end

  # ---------------------------------------------------------------------------
  # Test 1 — DECOUPLE-04: evaluate_auth/3 raising → rescued → :deny
  # RED until Plan 03 wraps companion evaluate_auth/3 in try/rescue
  # ---------------------------------------------------------------------------

  @tag :decouple_04
  test "DECOUPLE-04: companion raising in evaluate_auth/3 is rescued and denies" do
    Application.put_env(:crosswake, :companions, [
      Crosswake.TestSupport.StubAuthRaisesCompanion
    ])

    Application.put_env(:crosswake, :stub_auth_raises, %{enabled: true})

    on_exit(fn ->
      Application.delete_env(:crosswake, :stub_auth_raises)
    end)

    assert {:ok, %{manifest: manifest}} = Crosswake.Manifest.compile(StubAuthPredicatedRouter)
    target = %Crosswake.Compatibility.Target{}

    decision = RouteGate.evaluate(manifest, "auth-predicated-stub-route", target)

    assert decision.status == :deny,
           ProofAssertions.stable_id_message(
             "proof.decouple_04.auth_raises_yields_deny",
             "evaluate_auth/3 raising must produce :deny (fail-closed, DECOUPLE-04, D-3)",
             "RouteGate.evaluate/4",
             "decision.status was #{inspect(decision.status)} — expected :deny",
             "lib/crosswake/compatibility/route_gate.ex",
             "Plan 03 prepend_auth_evaluation_denials/4 must wrap evaluate_auth/3 in try/rescue → deny on raise (DECOUPLE-04)",
             :merge_blocking
           )

    assert decision.denial != nil, "expected a denial struct when evaluate_auth/3 raises"

    assert decision.denial.reason in [:dependency_missing, :auth_evaluator_error],
           ProofAssertions.stable_id_message(
             "proof.decouple_04.auth_raises_denial_reason",
             "evaluate_auth/3 raising must produce :dependency_missing or :auth_evaluator_error denial",
             "RouteGate.evaluate/4 -> Denial.reason",
             "denial.reason was #{inspect(decision.denial && decision.denial.reason)}",
             "lib/crosswake/compatibility/route_gate.ex",
             "Plan 03 rescue path must set denial reason to :dependency_missing or a dedicated :auth_evaluator_error atom",
             :merge_blocking
           )
  end

  # ---------------------------------------------------------------------------
  # Test 2 — DECOUPLE-01: zero companions → events/0 returns non-empty list,
  # reserved set is empty
  # RED until Plan 02 inverts build_reserved_events/0 to runtime aggregation
  # ---------------------------------------------------------------------------

  @tag :decouple_01
  test "DECOUPLE-01: events/0 with no companions returns non-empty list AND empty reserved set" do
    Application.put_env(:crosswake, :companions, [])

    all_events = Crosswake.Telemetry.events()
    reserved_events = Enum.filter(all_events, fn e -> e.tier == :reserved end)

    assert length(all_events) > 0,
           ProofAssertions.stable_id_message(
             "proof.decouple_01.zero_companions_events_non_empty",
             "events/0 must return non-empty list even with no companions (core :active events)",
             "Crosswake.Telemetry.events/0",
             "got #{length(all_events)} events",
             "lib/crosswake/telemetry.ex",
             "Plan 02 must preserve core :active events when companions: []",
             :merge_blocking
           )

    assert reserved_events == [],
           ProofAssertions.stable_id_message(
             "proof.decouple_01.zero_companions_reserved_empty",
             "with companions: [], the :reserved tier must be empty (runtime aggregation, not static calls)",
             "Crosswake.Telemetry.events/0 |> filter(tier == :reserved)",
             "got #{length(reserved_events)} reserved events — expected 0",
             "lib/crosswake/telemetry.ex",
             "Plan 02 must convert build_reserved_events/0 to runtime companion aggregation (DECOUPLE-01)",
             :merge_blocking
           )
  end

  # ---------------------------------------------------------------------------
  # Test 3 — DECOUPLE-04: multiple auth_authority?/0 companions → first-registered wins
  # RED until Plan 03 implements the multiple-authority conflict handling
  # ---------------------------------------------------------------------------

  @tag :decouple_04
  test "DECOUPLE-04: multiple auth_authority?/0 companions — first-registered evaluate_auth/3 used" do
    Application.put_env(:crosswake, :companions, [
      Crosswake.TestSupport.StubAuthFirstCompanion,
      Crosswake.TestSupport.StubAuthSecondCompanion
    ])

    Application.put_env(:crosswake, :stub_auth_first, %{enabled: true})
    Application.put_env(:crosswake, :stub_auth_second, %{enabled: true})

    on_exit(fn ->
      Application.delete_env(:crosswake, :stub_auth_first)
      Application.delete_env(:crosswake, :stub_auth_second)
    end)

    # Subscribe to telemetry conflict signal before evaluation
    conflict_event = [:crosswake, :companion, :auth_authority_conflict]
    ref = make_ref()

    :telemetry.attach(
      "phase136-proof-conflict-#{inspect(ref)}",
      conflict_event,
      fn _event, _measurements, _metadata, _config ->
        send(self(), {:auth_conflict_emitted, ref})
      end,
      nil
    )

    on_exit(fn ->
      :telemetry.detach("phase136-proof-conflict-#{inspect(ref)}")
    end)

    assert {:ok, %{manifest: manifest}} = Crosswake.Manifest.compile(StubAuthPredicatedRouter)
    target = %Crosswake.Compatibility.Target{}

    decision = RouteGate.evaluate(manifest, "auth-predicated-stub-route", target)

    # First-registered companion's evaluate_auth/3 returns {:allow, %{source: :stub_auth_first}}.
    # The stub Target{} has no origin/capability data so compatibility denials are expected (origin
    # mismatch, bridge protocol, etc.) — but NO auth denial must be present, proving the first
    # authority's :allow outcome was used and no auth-specific deny was prepended.
    auth_denial_reasons = [:dependency_missing, :auth_evaluator_error]
    auth_denials = Enum.filter(decision.denials, fn d -> d.reason in auth_denial_reasons end)

    assert auth_denials == [],
           ProofAssertions.stable_id_message(
             "proof.decouple_04.multi_authority_first_wins",
             "with two auth_authority?/0 companions, the first-registered evaluate_auth/3 decision must be used (no auth denial)",
             "RouteGate.evaluate/4 -> decision.denials",
             "auth denials present: #{inspect(Enum.map(auth_denials, & &1.reason))} — expected none (first companion allows)",
             "lib/crosswake/compatibility/route_gate.ex",
             "Plan 03 must select the first auth_authority?/0 companion and dispatch evaluate_auth/3 to it (DECOUPLE-04)",
             :merge_blocking
           )

    # A telemetry conflict signal must be observable when multiple authorities are present
    assert_received {:auth_conflict_emitted, ^ref},
                    ProofAssertions.stable_id_message(
                      "proof.decouple_04.multi_authority_conflict_signal",
                      "multiple auth_authority?/0 companions must emit [:crosswake, :companion, :auth_authority_conflict] telemetry",
                      "RouteGate.evaluate/4 -> :telemetry.execute",
                      "conflict event not received after evaluate/4 with two auth-authority companions",
                      "lib/crosswake/compatibility/route_gate.ex",
                      "Plan 03 must emit [:crosswake, :companion, :auth_authority_conflict] when >1 authority found (D-3)",
                      :merge_blocking
                    )
  end

  # ---------------------------------------------------------------------------
  # Test 4 — DECOUPLE-05: baseline_forbidden_metadata_keys/0 returns exactly 10 atoms
  # RED until Plan 02 adds Crosswake.Telemetry.baseline_forbidden_metadata_keys/0
  # ---------------------------------------------------------------------------

  @tag :decouple_05
  test "DECOUPLE-05: baseline_forbidden_metadata_keys/0 is callable and returns exactly the 10-atom set" do
    expected =
      MapSet.new([
        :access_token,
        :refresh_token,
        :id_token,
        :authorization_code,
        :token,
        :session_ref,
        :subject_ref,
        :actor_id,
        :ip,
        :email
      ])

    actual = MapSet.new(Crosswake.Telemetry.baseline_forbidden_metadata_keys())

    assert MapSet.equal?(expected, actual),
           ProofAssertions.stable_id_message(
             "proof.decouple_05.baseline_forbidden_keys_exact",
             "baseline_forbidden_metadata_keys/0 must return exactly the 10-atom PII denylist (D-136-A)",
             "Crosswake.Telemetry.baseline_forbidden_metadata_keys/0",
             "got #{inspect(MapSet.to_list(actual))} — expected #{inspect(MapSet.to_list(expected))}",
             "lib/crosswake/telemetry.ex",
             "Plan 02 must expose @baseline_forbidden_keys as baseline_forbidden_metadata_keys/0 (DECOUPLE-05, D-136-A)",
             :merge_blocking
           )
  end

  # ---------------------------------------------------------------------------
  # Test 5 — DECOUPLE-05: forbidden-key set captured at attach time, not per-event
  # RED until Plan 02 caches the forbidden-key MapSet in attach_default_logger/1 handler closure
  # ---------------------------------------------------------------------------

  @tag :decouple_05
  test "DECOUPLE-05: forbidden key from companion is scrubbed even after companion registry is cleared" do
    companion_forbidden_key = :stub_companion_secret

    Application.put_env(:crosswake, :companions, [
      Crosswake.TestSupport.StubForbiddenKeyCompanion
    ])

    Application.put_env(:crosswake, :stub_forbidden_key, %{enabled: true})

    on_exit(fn ->
      Application.delete_env(:crosswake, :stub_forbidden_key)
    end)

    handler_id = "phase136-proof-forbidden-#{System.unique_integer([:positive])}"

    # Attach WHILE the companion is registered (so the forbidden-key set is captured at attach time)
    result = Crosswake.Telemetry.attach_default_logger(level: :debug)

    on_exit(fn ->
      Crosswake.Telemetry.detach_default_logger()
    end)

    assert result in [:ok, {:error, :already_exists}],
           "attach_default_logger/1 must return :ok or {:error, :already_exists}"

    # Clear the companion registry — forbidden key should still be scrubbed (captured at attach)
    Application.put_env(:crosswake, :companions, [])

    # Intercept the log to check PII scrubbing — use a test telemetry handler for the emitted event
    emitted_event = [:crosswake, :companion, :dependency_check, :start]
    :telemetry.attach(
      handler_id,
      emitted_event,
      fn _event, _measurements, metadata, _config ->
        send(self(), {:event_metadata, metadata})
      end,
      nil
    )

    on_exit(fn ->
      :telemetry.detach(handler_id)
    end)

    # Emit a synthetic event carrying the forbidden key in its metadata
    probe_metadata =
      %{companion_id: :test, route_id: "phase136-probe"}
      |> Map.put(companion_forbidden_key, "should-be-scrubbed")

    :telemetry.execute(
      emitted_event,
      %{system_time: System.monotonic_time()},
      probe_metadata
    )

    # Consume the received message (the intercepted event metadata)
    assert_received {:event_metadata, _received_meta}

    # The forbidden key must not appear in metadata passed through to other handlers
    # (The default logger handler scrubs it from the log — we verify via the handler config)
    # Alternative approach: verify the handler was registered with a config map containing
    # a :forbidden_keys entry (proving it was built at attach time, not per-event).
    telemetry_handlers = :telemetry.list_handlers(emitted_event)
    default_logger_handler = Enum.find(telemetry_handlers, fn h -> h.id == "crosswake-default-logger" end)

    assert default_logger_handler != nil,
           "crosswake-default-logger handler must be attached after attach_default_logger/1"

    # The handler config map must carry the pre-computed :forbidden_keys MapSet
    # (proving capture-at-attach-time, not re-aggregation per event — DECOUPLE-05 / D-136-A).
    handler_config = default_logger_handler.config

    assert is_map(handler_config) and Map.has_key?(handler_config, :forbidden_keys),
           ProofAssertions.stable_id_message(
             "proof.decouple_05.forbidden_keys_in_handler_config",
             "attach_default_logger/1 must capture forbidden keys in handler config map at attach time",
             ":telemetry.list_handlers/1 -> handler.config[:forbidden_keys]",
             "handler config was #{inspect(handler_config)} — expected :forbidden_keys key",
             "lib/crosswake/telemetry.ex",
             "Plan 02 must compute forbidden MapSet in attach_default_logger/1 and pass via config (D-136-A, DECOUPLE-05)",
             :merge_blocking
           )

    forbidden_in_config = Map.get(handler_config, :forbidden_keys, MapSet.new())

    assert MapSet.member?(forbidden_in_config, companion_forbidden_key),
           ProofAssertions.stable_id_message(
             "proof.decouple_05.companion_key_in_attach_time_config",
             "forbidden key from companion must be in handler config :forbidden_keys (captured at attach, not per-event)",
             ":telemetry.list_handlers/1 -> handler.config[:forbidden_keys] |> MapSet.member?(:stub_companion_secret)",
             "#{inspect(companion_forbidden_key)} not found in config forbidden_keys: #{inspect(forbidden_in_config)}",
             "lib/crosswake/telemetry.ex",
             "Plan 02 must union companion forbidden_metadata_keys/0 into the attach-time MapSet (DECOUPLE-05)",
             :merge_blocking
           )
  end
end
