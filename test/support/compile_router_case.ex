defmodule Crosswake.TestSupport.CompileRouterCase do
  @moduledoc false

  import ExUnit.Assertions
  import ExUnit.CaptureIO

  alias Crosswake.Policy.Compiler
  alias Crosswake.Policy.Diagnostic

  def compile_with_warning_output!(router) do
    warning_output =
      capture_io(:stderr, fn ->
        case Compiler.compile(router, warn_on_unmanaged?: true, emit_warnings?: true) do
          {:ok, result} ->
            send(self(), {:compile_result, result})

          {:error, %Diagnostic{} = diagnostic} ->
            flunk("expected successful compilation, got diagnostic:\n#{Diagnostic.format(diagnostic)}")
        end
      end)

    result =
      receive do
        {:compile_result, result} -> result
      after
        1000 -> flunk("expected compiler result")
      end

    {result, warning_output}
  end
end
