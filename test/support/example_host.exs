defmodule Crosswake.TestSupport.ExampleHost do
  @app_root Path.expand("../../examples/phoenix_host", __DIR__)

  def load! do
    @app_root
    |> Path.join("_build/dev/lib/*/ebin")
    |> Path.wildcard()
    |> Enum.each(&Code.prepend_path/1)

    :ok
  end
end
