# ---------------------------------------------------------------------------
# Stub companion for Phase 139 anti-drift PII-floor test (D-5).
# Defined outside the test module to avoid nested-module resolution issues.
# This stub contributes the threadline domain's forbidden metadata keys to the
# companion union — proving every core baseline key has companion provenance.
# The keys here are the threadline domain keys; the companion-domain provenance
# comment references "threadline's domain" without naming the package atom.
# ---------------------------------------------------------------------------

defmodule Crosswake.TestSupport.StubThreadlineDomainCompanion do
  @moduledoc false
  @behaviour Crosswake.Companion

  # Threadline domain forbidden keys — the 20-key denylist owned by the audit/correlation
  # observer companion. This is a superset of the core baseline (which has 11 keys);
  # the baseline keys are a curated universal floor, all of which have threadline provenance.
  # companion-domain keys (credential_id, device_id, etc.) exceed the floor legitimately.
  @threadline_domain_forbidden_keys [
    :access_token,
    :actor_id,
    :actor_ref,
    :authorization_code,
    :credential_id,
    :device_id,
    :email,
    :id_token,
    :ip,
    :nonce,
    :org_id,
    :passkey_credential_id,
    :pkce_verifier,
    :provider_payload,
    :raw_return_to,
    :refresh_token,
    :return_to,
    :session_ref,
    :subject_ref,
    :user_agent
  ]

  @impl true
  def companion_id, do: :stub_threadline_domain

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
      companion_id: :stub_threadline_domain,
      enabled: true,
      dependency_status: :ok,
      gate_status: :unconfigured,
      kill_switch_status: :unconfigured,
      checked_at: 0
    }
  end

  @impl true
  def forbidden_metadata_keys, do: @threadline_domain_forbidden_keys
end

# Additionally, a stub that contributes :token (chimeway domain — covers the
# one core baseline key not in the threadline domain list above).
defmodule Crosswake.TestSupport.StubChimewayDomainCompanion do
  @moduledoc false
  @behaviour Crosswake.Companion

  # Chimeway domain includes :token (session token used in notification flows).
  # This is one of the 11 core baseline keys not in the threadline domain list.
  @chimeway_domain_forbidden_keys [:token, :raw_token, :device_token, :session_ref, :subject_ref,
    :actor_id, :ip, :email, :device_id, :user_agent, :provider_payload]

  @impl true
  def companion_id, do: :stub_chimeway_domain

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
      companion_id: :stub_chimeway_domain,
      enabled: true,
      dependency_status: :ok,
      gate_status: :unconfigured,
      kill_switch_status: :unconfigured,
      checked_at: 0
    }
  end

  @impl true
  def forbidden_metadata_keys, do: @chimeway_domain_forbidden_keys
end

defmodule Crosswake.TelemetryTest do
  @moduledoc """
  Unit tests for Crosswake.Telemetry.attach_default_logger/1 and detach_default_logger/0.

  Covers TELEM-03: the opt-in default logger, double-attach guard, exception level override
  (D-14), and PII key scrubbing (D-15).

  Also covers Phase 139 D-5 anti-drift PII-floor test: asserts core_baseline ⊆
  union(registered-companion forbidden_metadata_keys), ensuring every floor key has
  companion provenance. The inverse is NOT asserted (companion-domain keys legitimately
  exceed the floor).

  async: false — the telemetry handler table is a global ETS-backed registry. Tests must
  run sequentially to avoid one test observing another test's handler attachment state.
  All tests detach in on_exit to ensure isolation between test runs.

  Wave 0: these tests fail RED until the Crosswake.Telemetry facade (plan 02/03) lands.
  """

  use ExUnit.Case, async: false
  import ExUnit.CaptureLog

  @handler_id "crosswake-default-logger"

  # ---------------------------------------------------------------------------
  # Setup: detach any stale handler so tests start from a clean state (D-13)
  # ---------------------------------------------------------------------------

  setup do
    # Best-effort detach of any left-over handler (ignore :not_found)
    :telemetry.detach(@handler_id)

    on_exit(fn ->
      Crosswake.Telemetry.detach_default_logger()
    end)

    :ok
  end

  # ---------------------------------------------------------------------------
  # Test 1: attach_default_logger/0 registers a handler and returns :ok
  # RED until plan 02/03 creates Crosswake.Telemetry.attach_default_logger/1
  # ---------------------------------------------------------------------------

  test "attach_default_logger/0 (default opts) returns :ok and registers the crosswake-default-logger handler" do
    result = Crosswake.Telemetry.attach_default_logger()

    assert result == :ok,
           "attach_default_logger/0 must return :ok on first attach; got #{inspect(result)}"

    handlers = :telemetry.list_handlers([:crosswake])

    handler_ids = Enum.map(handlers, fn %{id: id} -> id end)

    assert @handler_id in handler_ids,
           "expected handler id #{inspect(@handler_id)} to be registered; found: #{inspect(handler_ids)}"
  end

  # ---------------------------------------------------------------------------
  # Test 2: double-attach returns {:error, :already_exists}
  # Relies on :telemetry's built-in guard (D-13 — no custom guard added to the impl)
  # RED until plan 02/03 creates Crosswake.Telemetry.attach_default_logger/1
  # ---------------------------------------------------------------------------

  test "a second attach_default_logger call returns {:error, :already_exists}" do
    :ok = Crosswake.Telemetry.attach_default_logger()

    result = Crosswake.Telemetry.attach_default_logger()

    assert result == {:error, :already_exists},
           "second attach must return {:error, :already_exists}; got #{inspect(result)}"
  end

  # ---------------------------------------------------------------------------
  # Test 3: detach_default_logger/0 returns :ok; a second detach returns {:error, :not_found}
  # RED until plan 02/03 creates Crosswake.Telemetry.detach_default_logger/0
  # ---------------------------------------------------------------------------

  test "detach_default_logger/0 returns :ok; a second call returns {:error, :not_found}" do
    :ok = Crosswake.Telemetry.attach_default_logger()

    first_detach = Crosswake.Telemetry.detach_default_logger()
    assert first_detach == :ok,
           "first detach_default_logger/0 must return :ok; got #{inspect(first_detach)}"

    second_detach = Crosswake.Telemetry.detach_default_logger()
    assert second_detach == {:error, :not_found},
           "second detach_default_logger/0 must return {:error, :not_found}; got #{inspect(second_detach)}"
  end

  # ---------------------------------------------------------------------------
  # Test 4: :exception events are always logged at :error regardless of configured level
  # D-14: attach with level: :info, emit :exception, assert captured log contains error line.
  # RED until plan 02/03 creates the handler with exception-level override.
  # ---------------------------------------------------------------------------

  test ":exception events are logged at :error level even when configured level is :info" do
    :ok = Crosswake.Telemetry.attach_default_logger(level: :info)

    # Pick any [:crosswake,...] active event name to test the :exception path.
    # We use the threadline exception event because it is always declared.
    exception_event = [:crosswake, :threadline, :request, :exception]

    log =
      capture_log(fn ->
        :telemetry.execute(exception_event, %{duration: 100}, %{kind: :error, reason: "test"})
      end)

    assert log =~ "[error]" or log =~ "error",
           "[D-14] expected :exception event to produce an [error] log line even with level: :info configured; captured log: #{inspect(log)}"

    assert log =~ "[crosswake]",
           "[D-20] expected log to include the [crosswake] prefix; captured log: #{inspect(log)}"
  end

  # ---------------------------------------------------------------------------
  # Test 5: PII-safety — a forbidden metadata key (:access_token) is NOT in logged output
  # D-15: forbidden_metadata_keys denylist must scrub PII before logging.
  # RED until plan 02/03 implements the PII scrub in the default logger handler.
  # ---------------------------------------------------------------------------

  test "PII-safety: a forbidden metadata key (:access_token) present on an event is NOT logged" do
    :ok = Crosswake.Telemetry.attach_default_logger()

    # Emit any [:crosswake,...] event carrying :access_token as a forbidden metadata key.
    test_event = [:crosswake, :threadline, :request, :stop]

    log =
      capture_log(fn ->
        :telemetry.execute(
          test_event,
          %{duration: 50},
          %{thread_id: "safe-id", source: :inbound, access_token: "super-secret-token-value"}
        )
      end)

    refute log =~ "super-secret-token-value",
           "[D-15] PII value 'super-secret-token-value' must not appear in the captured log; got: #{inspect(log)}"

    refute log =~ "access_token",
           "[D-15] PII key ':access_token' must not appear in the captured log; got: #{inspect(log)}"
  end

  # ---------------------------------------------------------------------------
  # Test 6: Phase 139 D-5 anti-drift PII-floor subset test
  # Asserts: core_baseline ⊆ union(registered-companion forbidden_metadata_keys).
  # Every key in the core universal floor must have companion provenance — i.e. at
  # least one registered companion declares it in their forbidden_metadata_keys/0.
  # The INVERSE is NOT asserted: companion-domain keys legitimately exceed the floor.
  # This test fails loudly if a future edit adds a floor key with zero companion provenance.
  # Non-vacuous: companions are registered via put_env (not an empty union).
  # ---------------------------------------------------------------------------

  describe "Phase 139 D-5 anti-drift PII-floor subset test" do
    setup do
      original_companions = Application.get_env(:crosswake, :companions, [])

      Application.put_env(:crosswake, :companions, [
        Crosswake.TestSupport.StubThreadlineDomainCompanion,
        Crosswake.TestSupport.StubChimewayDomainCompanion
      ])

      on_exit(fn ->
        Application.put_env(:crosswake, :companions, original_companions)
      end)

      :ok
    end

    test "core_baseline ⊆ union(companion forbidden_metadata_keys) — every floor key has companion provenance (D-5, Phase 139)" do
      # Get the core universal floor
      baseline = Crosswake.Telemetry.baseline_forbidden_metadata_keys()
      baseline_set = MapSet.new(baseline)

      # Build the union of all registered companion forbidden_metadata_keys/0 (non-vacuous: companions registered above)
      companion_union =
        Application.get_env(:crosswake, :companions, [])
        |> Enum.flat_map(fn mod ->
          if function_exported?(mod, :forbidden_metadata_keys, 0), do: mod.forbidden_metadata_keys(), else: []
        end)
        |> MapSet.new()

      # Non-vacuity check: the companion union must not be empty
      refute MapSet.size(companion_union) == 0,
             "companion union must not be empty — test is vacuous if no companions are registered"

      # Core subset assertion (D-5): every core floor key must appear in the companion union.
      # A floor key without companion provenance means it was added to core without a companion
      # declaring responsibility for it — that is a PII-floor drift bug.
      keys_without_provenance =
        MapSet.difference(baseline_set, companion_union)
        |> MapSet.to_list()

      assert keys_without_provenance == [],
             "Anti-drift (D-5 / Phase 139): the following core baseline floor keys have NO companion provenance — " <>
               "every floor key must be declared by at least one companion's forbidden_metadata_keys/0 to ensure " <>
               "the PII scrub is non-redundant with the floor: #{inspect(keys_without_provenance)}"
    end

    test "baseline_forbidden_metadata_keys/0 returns exactly the 11-atom post-Phase-139 universal floor (count guard)" do
      baseline = Crosswake.Telemetry.baseline_forbidden_metadata_keys()

      # 11-atom floor post Phase 139: 10 original + :actor_ref (curated universal-floor delta, D-5).
      # If this count changes, update this test AND the floor comment in telemetry.ex.
      assert length(baseline) == 11,
             "baseline_forbidden_metadata_keys/0 must return exactly 11 atoms post-Phase-139 " <>
               "(10 original + :actor_ref curated universal-floor delta). Got #{length(baseline)}: #{inspect(baseline)}"

      # Spot-check the critical floor keys
      assert :access_token in baseline
      assert :actor_ref in baseline
      assert :email in baseline
      assert :token in baseline
      assert :ip in baseline
    end
  end

  # ---------------------------------------------------------------------------
  # Phase 154 Plan 04: the 5-event bridge catalog (D-22, Task 2)
  #
  # events/0 derives its :active tier at runtime with zero hardcoded catalogs
  # elsewhere (D-05) — this test proves the auto-derivation mechanism scales to a
  # brand-new subsystem (Crosswake.Bridge) without any special-casing in
  # attach_default_logger/1 or the merge-blocking phase133 contract test, both of
  # which already derive their event name lists from events/0 at call time.
  # ---------------------------------------------------------------------------

  describe "Phase 154 bridge telemetry catalog (D-22)" do
    test "events/0's :active tier includes exactly the 5 bridge events (push, reply, dropped, hook_ack, hook_missing)" do
      bridge_events =
        Crosswake.Telemetry.events()
        |> Enum.filter(fn e -> match?([:crosswake, :bridge | _], e.event) and e.tier == :active end)

      bridge_suffixes = Enum.map(bridge_events, fn %{event: [:crosswake, :bridge, suffix]} -> suffix end)

      assert Enum.sort(bridge_suffixes) == Enum.sort([:push, :reply, :dropped, :hook_ack, :hook_missing]),
             "expected exactly the 5 Phase 154 bridge events in events/0; got #{inspect(bridge_suffixes)}"

      for entry <- bridge_events do
        assert is_binary(entry.description) and entry.description != ""
        assert is_list(entry.measurements) and entry.measurements != []
        assert is_list(entry.metadata) and entry.metadata != []
      end
    end
  end
end
