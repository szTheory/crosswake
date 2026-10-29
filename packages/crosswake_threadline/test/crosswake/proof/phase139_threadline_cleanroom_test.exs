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

  @tag :threadline_plug
  test "Crosswake.Plug.Threadline.init/1 ships with the correct header_name default" do
    assert Code.ensure_loaded?(Plug.Conn), "threadline_plug: dependency_required"
    assert Code.ensure_loaded?(Crosswake.Plug.Threadline), "threadline_plug: module_required"
    opts = Crosswake.Plug.Threadline.init([])
    assert is_list(opts), "threadline_plug: options_required"

    assert opts[:header_name] == "x-crosswake-thread-id",
           "threadline_plug: default_header_required"
  end

  @tag :optional_plug_control
  test "optional Plug subprocess lanes distinguish excluded, missing and real proof" do
    {disabled, disabled_exit} = plug_consumer(nil, false)
    assert disabled_exit == 0, "threadline_plug: disabled consumer failed"
    assert disabled =~ "2 excluded", "threadline_plug: disabled canary was not excluded"
    assert disabled =~ "3 tests, 0 failures", "threadline_plug: shipment canaries did not execute"

    {missing, missing_exit} = plug_consumer("1", true)
    assert missing_exit != 0, "threadline_plug: missing enabled dependency passed"

    assert missing =~ "threadline_plug: dependency_required",
           "threadline_plug: missing diagnostic"

    assert missing =~ "4 tests, 1 failure", "threadline_plug: required canaries did not execute"

    {enabled, enabled_exit} = plug_consumer("1", false)
    assert enabled_exit == 0, "threadline_plug: real enabled consumer failed"
    assert enabled =~ "4 tests, 0 failures", "threadline_plug: real canary did not execute"
    assert enabled =~ "1 excluded", "threadline_plug: unexpected exclusion count"
    IO.puts("optional_plug_control: disabled exit #{disabled_exit} executed 3 excluded 2")

    IO.puts(
      "optional_plug_control: missing exit #{missing_exit} executed 4 failures 1 excluded 1"
    )

    IO.puts("optional_plug_control: enabled exit #{enabled_exit} executed 4 excluded 1")
  end

  defp plug_consumer(request, remove_plug?) do
    paths =
      :code.get_path()
      |> Enum.reject(fn path ->
        remove_plug? and Path.basename(Path.dirname(to_string(path))) == "plug"
      end)
      |> Enum.flat_map(fn path -> ["-pa", to_string(path)] end)

    script = """
    Mix.start()
    Code.require_file("mix.exs")
    Code.require_file("test/test_helper.exs")
    ExUnit.configure(exclude: ExUnit.configuration()[:exclude] ++ [optional_plug_control: true])
    if #{remove_plug?} and Code.ensure_loaded?(Plug.Conn), do: raise("threadline_plug: isolation_failed")
    Code.require_file("test/crosswake/proof/phase139_threadline_cleanroom_test.exs")
    """

    System.cmd(System.find_executable("elixir"), ["--erl", "+S 2:2"] ++ paths ++ ["-e", script],
      env: [{"MIX_INCLUDE_THREADLINE_PLUG", request}],
      stderr_to_stdout: true
    )
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
