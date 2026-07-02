defmodule Crosswake.Proof.Phase139ThreadlineCleanroomTest do
  @moduledoc """
  Vacuity-safe clean-room proof for Phase 139 crosswake_threadline extraction.

  Proves three module-shipment canaries (the key modules compiled and are callable)
  AND that neither sibling companion is a dep (THREAD-02: zero-sibling-dep invariant),
  read from the real dep list — non-vacuous.

  async: true — threadline is NOT a :companions registrant; no Application.put_env,
  no process-global mutation. Contrast chimeway's async: false.

  No setup block — pure module-level assertions, no shared state.
  """

  use ExUnit.Case, async: true

  # ---------------------------------------------------------------------------
  # Canary 1: Threadline.Telemetry shipped
  # ---------------------------------------------------------------------------

  test "Crosswake.Threadline.Telemetry.event_names/0 ships exactly 3 request-span event names" do
    event_names = Crosswake.Threadline.Telemetry.event_names()

    assert is_list(event_names),
           "Telemetry.event_names/0 must return a list — module did not ship in tarball"

    assert length(event_names) == 3,
           "Telemetry.event_names/0 must return exactly 3 request-span names (:start/:stop/:exception); " <>
             "got #{length(event_names)} — if the module was not included in the tarball, " <>
             "verify 'lib' is in the files: list in mix.exs"

    assert [:crosswake, :threadline, :request, :start] in event_names,
           "[:crosswake, :threadline, :request, :start] must be in event_names/0"

    assert [:crosswake, :threadline, :request, :stop] in event_names,
           "[:crosswake, :threadline, :request, :stop] must be in event_names/0"

    assert [:crosswake, :threadline, :request, :exception] in event_names,
           "[:crosswake, :threadline, :request, :exception] must be in event_names/0"
  end

  # ---------------------------------------------------------------------------
  # Canary 2: Plug.Threadline shipped (optional-dep guard: Plug.Conn must be loaded)
  # ---------------------------------------------------------------------------

  test "Crosswake.Plug.Threadline.init/1 ships with the correct header_name default" do
    if Code.ensure_loaded?(Plug.Conn) do
      opts = Crosswake.Plug.Threadline.init([])

      assert is_list(opts),
             "Plug.Threadline.init/1 must return a keyword list — module did not ship in tarball"

      assert opts[:header_name] == "x-crosswake-thread-id",
             "Plug.Threadline.init/1 must default header_name to 'x-crosswake-thread-id'; " <>
               "got #{inspect(opts[:header_name])}"
    else
      # Plug.Conn not loaded in this env — skip rather than fail (optional dep guard).
      # The phase92_server_propagation_closeout_test.exs covers Plug.Threadline behavior.
      assert true, "Plug.Conn not loaded — Plug.Threadline is optional, skipping canary"
    end
  end

  # ---------------------------------------------------------------------------
  # Canary 3: Audit.Ledger.actor_ref/2 shipped and returns 64-char hex
  # ---------------------------------------------------------------------------

  test "Crosswake.Audit.Ledger.actor_ref/2 ships and returns a 64-character hex string (SHA-256 HMAC)" do
    result = Crosswake.Audit.Ledger.actor_ref("test-user-id", secret: "test-secret")

    assert is_binary(result),
           "Audit.Ledger.actor_ref/2 must return a binary — module did not ship in tarball"

    assert byte_size(result) == 64,
           "Audit.Ledger.actor_ref/2 must return a 64-character lowercase hex string " <>
             "(SHA-256 HMAC encoded as base16); got #{byte_size(result)} bytes: #{inspect(result)}"

    assert result =~ ~r/^[0-9a-f]{64}$/,
           "Audit.Ledger.actor_ref/2 must return lowercase hex; got #{inspect(result)}"
  end

  # ---------------------------------------------------------------------------
  # Vacuity guard: real dep list has zero sibling companions (THREAD-02)
  # ---------------------------------------------------------------------------

  test "crosswake_threadline deps list contains no sibling companion deps (THREAD-02: zero-sibling-dep invariant)" do
    dep_names =
      Mix.Project.config()[:deps]
      |> Enum.map(fn
        {name, _version} -> name
        {name, _version, _opts} -> name
        {name} -> name
      end)

    # Non-vacuous: the dep list is not empty — we read the real package deps
    refute dep_names == [],
           "dep_names must not be empty — test would be vacuous if deps list were empty"

    refute :crosswake_sigra in dep_names,
           "crosswake_threadline MUST NOT depend on :crosswake_sigra in any env " <>
             "(THREAD-02: zero-sibling-dep invariant — companions must depend only on core)"

    refute :crosswake_chimeway in dep_names,
           "crosswake_threadline MUST NOT depend on :crosswake_chimeway in any env " <>
             "(THREAD-02: zero-sibling-dep invariant — companions must depend only on core)"
  end
end
