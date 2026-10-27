exclude =
  [:requires_example_host, :advisory_only]
  |> then(fn acc ->
    if System.get_env("MIX_INCLUDE_THREADLINE_PLUG") == "1",
      do: acc,
      else: [{:threadline_plug, true} | acc]
  end)

ExUnit.start(exclude: exclude)
