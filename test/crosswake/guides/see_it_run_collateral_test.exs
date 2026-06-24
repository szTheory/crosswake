defmodule Crosswake.Guides.SeeItRunCollateralTest do
  use ExUnit.Case, async: true

  # Deferred collateral-existence guard (D-19). The See It Run collateral assets
  # are NOT committed in the scaffolding state — the web PNGs are produced at
  # runtime by bin/capture-collateral.sh and the native binaries are human-gated
  # (see brandbook/collateral/see-it-run/README.md). This module is excluded by
  # default (see test/test_helper.exs) so the suite stays green before binaries
  # land. Once the maintainer commits the real assets, run the zero-human guard:
  #
  #   mix test --include collateral_binaries
  #   # or
  #   CROSSWAKE_INCLUDE_COLLATERAL=1 mix test test/crosswake/guides/see_it_run_collateral_test.exs
  @moduletag :collateral_binaries

  @collateral_dir "brandbook/collateral/see-it-run"

  @web_assets ["web-home.png", "web-offline.png", "web-bridge-proof.png"]
  @native_assets [
    "ios-simulator.png",
    "android-emulator.png",
    "three-runtime-montage.png",
    "see-it-run.gif"
  ]

  for asset <- @web_assets ++ @native_assets do
    test "collateral asset #{asset} exists and is non-empty" do
      path = Path.join(@collateral_dir, unquote(asset))
      assert File.exists?(path), "expected collateral asset #{path} to exist"
      assert File.stat!(path).size > 0, "expected collateral asset #{path} to be non-empty"
    end
  end
end
