defmodule Crosswake.Proof.Phase138ChimewayCleanroomTest do
  # Non-vacuous clean-room proof for the crosswake_chimeway package.
  #
  # CHIME-02: chimeway has NO runtime/prod crosswake_sigra dependency.
  # This proof registers chimeway via put_env and asserts REAL chimeway behavior
  # with sigra runtime-absent:
  #   1. chimeway telemetry events appear in Crosswake.Telemetry.events/0
  #   2. chimeway forbidden keys land in the attach-time handler forbidden set
  #   3. chimeway is NOT an auth authority
  #   4. chimeway mix.exs carries no non-test crosswake_sigra dep
  #
  # RESEARCH A2 CORRECTION: Crosswake.Telemetry.forbidden_metadata_keys/0 does NOT
  # exist as a public aggregator function. The attach-time handler.config[:forbidden_keys]
  # MapSet is the REAL seam (DECOUPLE-05) — read via :telemetry.list_handlers([:crosswake])
  # after attach_default_logger/0.
  #
  # async: false — companion registration (Application.put_env) + logger attachment
  # (handler ETS table) are process-global state and must not race with other tests.
  use ExUnit.Case, async: false

  alias Crosswake.Companions.Chimeway
  alias Crosswake.Companions.Chimeway.Telemetry, as: ChimewayTelemetry

  @handler_id "crosswake-default-logger"

  setup do
    # Ensure handler is detached before each test (leftover from prior test run)
    :telemetry.detach(@handler_id)

    # Ensure the chimeway module is loaded in the BEAM before function_exported?/3 checks.
    # In ExUnit, modules compiled as part of the current app (crosswake_chimeway) are
    # compiled into BEAM files but not automatically loaded until first reference.
    # Crosswake.Telemetry.events/0 uses function_exported?/3 which returns false for
    # unloaded modules — Code.ensure_loaded!/1 forces the module into the BEAM table.
    Code.ensure_loaded!(Chimeway)

    # Register chimeway so the :companions registry is populated for tests 1 and 2
    prior_companions = Application.get_env(:crosswake, :companions, [])
    Application.put_env(:crosswake, :companions, [Chimeway])

    on_exit(fn ->
      # Restore companions env
      Application.put_env(:crosswake, :companions, prior_companions)
      # Best-effort detach (ignore :not_found on tests that didn't attach)
      Crosswake.Telemetry.detach_default_logger()
    end)

    :ok
  end

  # Test 1: Telemetry events aggregation — non-vacuous.
  # With chimeway registered, Crosswake.Telemetry.events/0 calls chimeway's
  # telemetry_events/0 callback (via the :companions registry). The filtered
  # list MUST be non-empty; without registration it would be empty (vacuous pass).
  test "chimeway telemetry events appear in Crosswake.Telemetry.events/0 when registered" do
    all_events = Crosswake.Telemetry.events()
    chimeway_event_names = ChimewayTelemetry.event_names()

    chimeway_events =
      Enum.filter(all_events, fn %{event: event} -> event in chimeway_event_names end)

    assert chimeway_events != [],
           "Vacuity guard: chimeway events must be non-empty in Crosswake.Telemetry.events/0 " <>
             "when chimeway is registered in :companions. Got 0 events — check that " <>
             "Chimeway.telemetry_events/0 callback is implemented and setup put_env is active."
  end

  # Test 2: Forbidden keys in attach-time handler config — RESEARCH A2 correction.
  # Crosswake.Telemetry.forbidden_metadata_keys/0 does NOT exist as a public aggregator.
  # The real seam is the handler.config[:forbidden_keys] MapSet built at attach time
  # by attach_default_logger/0 (DECOUPLE-05). With chimeway registered (setup put_env),
  # every key from ChimewayTelemetry.forbidden_metadata_keys() MUST be in the MapSet.
  test "chimeway forbidden keys appear in attach-time handler config[:forbidden_keys]" do
    :ok = Crosswake.Telemetry.attach_default_logger()

    # Find the crosswake-default-logger handler and read its config[:forbidden_keys]
    handlers = :telemetry.list_handlers([:crosswake])

    handler =
      Enum.find(handlers, fn %{id: id} -> id == @handler_id end)

    assert handler != nil,
           "Expected handler '#{@handler_id}' to be registered after attach_default_logger/0"

    forbidden_keys_mapset = handler.config[:forbidden_keys]

    assert forbidden_keys_mapset != nil,
           "Expected handler.config[:forbidden_keys] to be a MapSet (DECOUPLE-05 attach-time capture)"

    chimeway_forbidden = ChimewayTelemetry.forbidden_metadata_keys()
    # Note: chimeway_forbidden is a compile-time known non-empty list; we don't assert
    # != [] here (Elixir's type checker correctly flags this as always-true). Instead we
    # assert that EACH key lands in the handler MapSet — that's the real seam proof.

    for key <- chimeway_forbidden do
      assert MapSet.member?(forbidden_keys_mapset, key),
             "Expected chimeway forbidden key #{inspect(key)} to be present in " <>
               "handler.config[:forbidden_keys] MapSet. " <>
               "Found: #{inspect(MapSet.to_list(forbidden_keys_mapset))}. " <>
               "Note: Crosswake.Telemetry.forbidden_metadata_keys/0 does NOT exist " <>
               "(RESEARCH A2); use the attach-time handler config MapSet."
    end
  end

  # Test 3: Chimeway is notification-only, not an auth authority (CHIME-02).
  # The auth_authority?/0 callback is NOT defined on Chimeway — only companions
  # that evaluate auth (like Sigra) implement it. Chimeway is notification-only.
  test "chimeway does not export auth_authority?/0 — notification-only companion" do
    refute function_exported?(Chimeway, :auth_authority?, 0),
           "Chimeway must NOT export auth_authority?/0 — it is notification-only, " <>
             "not an auth authority. Only auth companions (sigra) implement auth_authority?/0."
  end

  # Test 4: Runtime deps vacuity guard — no non-test crosswake_sigra dep.
  # The phase71 test-only dep {:crosswake_sigra, path: ..., only: :test} is ALLOWED.
  # A runtime/prod sigra dep is FORBIDDEN (CHIME-02 invariant).
  # This test reads Mix.Project.config()[:deps] to verify at the Mix level.
  test "crosswake_chimeway mix.exs has no non-test crosswake_sigra dep" do
    all_deps = Mix.Project.config()[:deps]

    # Normalize each dep to {name, opts} — deps can be:
    #   {name, version_req}  (2-tuple)
    #   {name, opts}         (2-tuple with keyword opts)
    #   {name, version_req, opts} (3-tuple)
    runtime_sigra_deps =
      all_deps
      |> Enum.filter(fn dep ->
        {dep_name, dep_opts} =
          case dep do
            {name, opts} when is_list(opts) -> {name, opts}
            {name, _version_req} -> {name, []}
            {name, _version_req, opts} -> {name, opts}
            _ -> {nil, []}
          end

        # Only flag crosswake_sigra deps that are NOT scoped to :test
        dep_name == :crosswake_sigra and
          Keyword.get(dep_opts, :only) not in [:test, [:test]]
      end)

    assert runtime_sigra_deps == [],
           "CHIME-02 violation: crosswake_chimeway has a non-test crosswake_sigra dep. " <>
             "The phase71 test-only {:crosswake_sigra, path: ..., only: :test} dep is the " <>
             "sole permitted sigra reference. Runtime/prod sigra deps are forbidden. " <>
             "Found: #{inspect(runtime_sigra_deps)}"
  end
end
