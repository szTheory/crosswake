defmodule Crosswake.TelemetryTest do
  @moduledoc """
  Unit tests for Crosswake.Telemetry.attach_default_logger/1 and detach_default_logger/0.

  Covers TELEM-03: the opt-in default logger, double-attach guard, exception level override
  (D-14), and PII key scrubbing (D-15).

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
end
