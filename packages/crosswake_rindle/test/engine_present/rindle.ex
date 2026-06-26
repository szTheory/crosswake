defmodule Rindle do
  @moduledoc """
  Fake top-level Rindle stub for the engine-present advisory lane (D-33).

  This module is compiled ONLY when ENGINE_PRESENT_LANE=1 is set, which appends
  test/engine_present/ to elixirc_paths(:test) in the package mix.exs.

  Purpose: makes Code.ensure_loaded?(Rindle) return true at RUNTIME without
  compile-baking engine presence. The advisory lane alias (mix engine-present.test)
  runs mix clean before loading this stub to prevent a stale .beam from leaking
  into the engine-absent hermetic lane.

  This is NOT a real Rindle implementation — it is purely a presence stub for
  testing the validate_dependency/0 :ok path. It carries no public API.
  """
end
