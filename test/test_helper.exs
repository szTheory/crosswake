ExUnit.start()

# Build the default exclude list once (a second ExUnit.configure(exclude:) call
# would replace, not merge, the list).
#
# - advisory_only: excluded unless MIX_INCLUDE_RULESTEAD=1 (existing behavior).
# - collateral_binaries: the See It Run collateral assets are runtime/human-
#   produced (web via bin/capture-collateral.sh; native via the human-gated steps
#   in brandbook/collateral/see-it-run/README.md), so the existence guard is
#   excluded by default to keep the suite green before binaries land. Run it with
#   `mix test --include collateral_binaries` (or CROSSWAKE_INCLUDE_COLLATERAL=1)
#   once the maintainer commits the real binaries.
exclude =
  []
  |> then(fn acc ->
    if System.get_env("MIX_INCLUDE_RULESTEAD") == "1", do: acc, else: [{:advisory_only, true} | acc]
  end)
  |> then(fn acc ->
    if System.get_env("CROSSWAKE_INCLUDE_COLLATERAL") == "1",
      do: acc,
      else: [{:collateral_binaries, true} | acc]
  end)
  |> then(fn acc ->
    # :engine_present — tests that require the Rulestead/Rindle engine to be loaded.
    # Excluded in hermetic mode (default). Run with MIX_ENGINE_PRESENT=1 in the
    # advisory engine-present CI lane (D-33, Phase 130 COMPAT-01 enforcement).
    if System.get_env("MIX_ENGINE_PRESENT") == "1",
      do: acc,
      else: [{:engine_present, true} | acc]
  end)

if exclude != [], do: ExUnit.configure(exclude: exclude)
