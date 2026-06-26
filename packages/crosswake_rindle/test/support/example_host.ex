defmodule Crosswake.TestSupport.ExampleHost do
  @moduledoc """
  Package-local stand-in for the core `Crosswake.TestSupport.ExampleHost` loader.

  In the monorepo, the live proof (`phase45_rindle_live_test.exs`, tagged
  `:requires_example_host`) prepends the compiled `examples/phoenix_host` ebin
  paths so the real LiveView host modules are loadable. The standalone
  `crosswake_rindle` package ships no Phoenix example host, so that test is
  excluded by default (`:requires_example_host` is in test_helper.exs exclusions).

  This stub exists only so the excluded test's `setup_all` reference resolves at
  compile time (avoiding an undefined-function warning under
  `--warnings-as-errors`). It is a no-op: the media helpers the proof tests use
  are loaded directly via `Code.require_file/2` from `test/support/example_host/`.
  """

  @spec load!() :: :ok
  def load!, do: :ok
end
