defmodule Crosswake.Proof.Phase39RoutePolicyGatingTest do
  @moduledoc """
  Hermetic merge-blocking proof lane for Phase 39 route-policy gating DSL and manifest binding.

  Proves GATE-01 (DSL validation): `gated_by` and `on_unavailable` keys are
  compile-time-validated, with atom-identifier enforcement and cross-key constraints.

  This test is fully hermetic by design: it never depends on the compiled example
  host (CrosswakeExample.*), never hits the network, never launches a simulator,
  and never calls Code.require_file. It runs UNtagged so the existing
  phase34-proof.yml `mix test --exclude requires_example_host` lane picks it up
  with no new CI file (D-10).
  """

  use ExUnit.Case, async: true

  alias Crosswake.Policy.Route
  alias Crosswake.Policy.Schema

  # ---------------------------------------------------------------------------
  # Hermeticity self-assertion
  # ---------------------------------------------------------------------------

  test "phase 39 route policy gating proof stays hermetic — no example-host or Code.require_file dependency" do
    source = File.read!(__ENV__.file) |> String.downcase()

    refute String.contains?(source, "crosswake" <> "example.router"),
           "phase 39 gating proof must not depend on the example host router; keep the merge-blocking lane hermetic"

    refute Regex.match?(~r/code\.require_file\s*\(/, source),
           "phase 39 gating proof must not Code.require_file example-host modules; keep the lane hermetic"
  end

  # ---------------------------------------------------------------------------
  # GATE-01: validate_flag_key/1 — atom identifier validator (Task 1)
  # ---------------------------------------------------------------------------

  describe "Schema.validate_flag_key/1" do
    test "accepts plain snake_case atoms" do
      assert Schema.validate_flag_key(:my_flag) == {:ok, :my_flag}
      assert Schema.validate_flag_key(:feature_rollout_v2) == {:ok, :feature_rollout_v2}
      assert Schema.validate_flag_key(:gating_enabled?) == {:ok, :gating_enabled?}
    end

    test "returns atom (not string) on success — D-04 pitfall guard" do
      {:ok, result} = Schema.validate_flag_key(:my_flag)
      assert is_atom(result), "validate_flag_key must return the atom, not a string"
      assert result == :my_flag
    end

    test "rejects boolean true" do
      assert {:error, msg} = Schema.validate_flag_key(true)
      assert String.contains?(msg, "plain atom identifier")
    end

    test "rejects boolean false" do
      assert {:error, msg} = Schema.validate_flag_key(false)
      assert String.contains?(msg, "plain atom identifier")
    end

    test "rejects nil" do
      assert {:error, msg} = Schema.validate_flag_key(nil)
      assert String.contains?(msg, "plain atom identifier")
    end

    test "rejects strings" do
      assert {:error, msg} = Schema.validate_flag_key("my_flag")
      assert String.contains?(msg, "plain atom identifier")
    end

    test "rejects integers" do
      assert {:error, msg} = Schema.validate_flag_key(123)
      assert String.contains?(msg, "plain atom identifier")
    end

    test "rejects quoted atoms with dots" do
      assert {:error, msg} = Schema.validate_flag_key(:"feature.flag")
      assert String.contains?(msg, "plain atom identifier")
    end

    test "rejects quoted atoms with hyphens" do
      assert {:error, msg} = Schema.validate_flag_key(:"my-flag")
      assert String.contains?(msg, "plain atom identifier")
    end

    test "rejects CamelCase atoms" do
      assert {:error, msg} = Schema.validate_flag_key(:CamelCase)
      assert String.contains?(msg, "plain atom identifier")
    end

    test "rejects camelCase atoms" do
      assert {:error, msg} = Schema.validate_flag_key(:camelCase)
      assert String.contains?(msg, "plain atom identifier")
    end
  end

  # ---------------------------------------------------------------------------
  # GATE-01: validate_on_unavailable/1 validator (Task 1)
  # ---------------------------------------------------------------------------

  describe "Schema.validate_on_unavailable/1" do
    test "accepts nil" do
      assert Schema.validate_on_unavailable(nil) == {:ok, nil}
    end

    test "accepts :deny" do
      assert Schema.validate_on_unavailable(:deny) == {:ok, :deny}
    end

    test "accepts {:fallback_phoenix, valid_atom}" do
      assert Schema.validate_on_unavailable({:fallback_phoenix, :home}) ==
               {:ok, {:fallback_phoenix, :home}}
    end

    test "rejects {:fallback_phoenix, string}" do
      assert {:error, msg} = Schema.validate_on_unavailable({:fallback_phoenix, "home"})
      assert String.contains?(msg, "fallback_phoenix")
    end

    test "rejects {:fallback_phoenix, atom with hyphen}" do
      assert {:error, msg} = Schema.validate_on_unavailable({:fallback_phoenix, :"bad-id"})
      assert String.contains?(msg, "fallback_phoenix")
    end

    test "rejects unknown atoms" do
      assert {:error, msg} = Schema.validate_on_unavailable(:something_else)
      assert String.contains?(msg, "on_unavailable")
    end
  end

  # ---------------------------------------------------------------------------
  # GATE-01 SC#1: Route happy paths (Task 2)
  # ---------------------------------------------------------------------------

  describe "Route.new!/1 with gating" do
    test "gated_by: :my_flag yields correct struct fields" do
      route = Route.new!(id: "r", runtime: :live_view, gated_by: :my_flag)
      assert route.gated_by == :my_flag
      # D-04: atom preserved, not string
      assert is_atom(route.gated_by)
      # Pitfall 5: inspect/1 produces unquoted atom
      assert inspect(route.gated_by) == ":my_flag"
    end

    test "gated_by: :my_flag without on_unavailable defaults to :deny (fail-closed — D-05d)" do
      route = Route.new!(id: "r", runtime: :live_view, gated_by: :my_flag)
      assert route.on_unavailable == :deny
    end

    test "explicit on_unavailable: {:fallback_phoenix, :home} is preserved" do
      route =
        Route.new!(
          id: "r",
          runtime: :live_view,
          gated_by: :my_flag,
          on_unavailable: {:fallback_phoenix, :home}
        )

      assert route.on_unavailable == {:fallback_phoenix, :home}
    end

    test "non-gated route has nil gated_by and nil on_unavailable (boundary — D-05d)" do
      route = Route.new!(id: "home", runtime: :live_view)
      assert route.gated_by == nil
      assert route.on_unavailable == nil
    end
  end

  # ---------------------------------------------------------------------------
  # GATE-01 SC#1: Route error cases (Task 2)
  # ---------------------------------------------------------------------------

  describe "Route.new!/1 gating error cases" do
    test "gated_by: true raises NimbleOptions.ValidationError with plain atom identifier message" do
      assert_raise NimbleOptions.ValidationError, ~r/plain atom identifier/, fn ->
        Route.new!(id: "bad", runtime: :live_view, gated_by: true)
      end
    end

    test "gated_by: string raises NimbleOptions.ValidationError" do
      assert_raise NimbleOptions.ValidationError, ~r/plain atom identifier/, fn ->
        Route.new!(id: "bad", runtime: :live_view, gated_by: "string")
      end
    end

    test "gated_by: quoted dot atom raises NimbleOptions.ValidationError" do
      assert_raise NimbleOptions.ValidationError, ~r/plain atom identifier/, fn ->
        Route.new!(id: "bad", runtime: :live_view, gated_by: :"feature.flag")
      end
    end

    test "on_unavailable without gated_by returns error with 'requires gated_by' message" do
      assert {:error, error} = Route.new(id: "bad", runtime: :live_view, on_unavailable: :deny)
      assert error.key == :on_unavailable
      assert String.contains?(error.message, "requires gated_by")
    end
  end
end
