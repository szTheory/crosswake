defmodule Crosswake.Proof.Phase33CommerceCorridorRoutesTest do
  @moduledoc """
  Hermetic merge-blocking proof lane for the Phase 33 paywall corridor route
  topology.

  Asserts the truth Success Criterion #2 gates on: the three
  `:subscription_default` corridor route declarations land in the manifest with
  the correct corridor metadata and role ownership.

  This test is fully hermetic by design (mirrors
  `Phase23CommerceSupportProofTest`): it declares an in-line router fixture and
  asserts against the canonical `Crosswake.Manifest` builder. It never depends
  on the compiled example host (`CrosswakeExample.*`), never hits the network,
  and runs UNtagged inside the merge-blocking lane (`phase34-proof.yml` picks it
  up via the broad `mix test --exclude requires_example_host` run). Role
  ownership is sourced from `Crosswake.Policy.CorridorProfiles` and is therefore
  router-independent — the fixture proves the same corridor metadata the example
  host produces. The example host's literal `post`/`live` route shapes are
  separately gated by `mix compile --warnings-as-errors` on the example host.
  """

  use ExUnit.Case, async: true

  alias Crosswake.Manifest

  defmodule CommerceCorridorRoutesRouter do
    use Crosswake.Router

    scope "/commerce" do
      crosswake_defaults runtime: :live_view, offline: :unavailable, security: :standard do
        live "/paywall", Crosswake.TestSupport.StudySessionLive,
          crosswake: [
            id: "commerce-paywall-entry",
            runtime: :live_view,
            commerce: [corridor: :subscription_default, role: :paywall_entry]
          ]

        live "/purchase", Crosswake.TestSupport.StudySessionLive,
          crosswake: [
            id: "commerce-purchase-intent",
            runtime: :native_screen,
            commerce: [corridor: :subscription_default, role: :purchase_intent]
          ]

        live "/restore", Crosswake.TestSupport.StudySessionLive,
          crosswake: [
            id: "commerce-restore-intent",
            runtime: :native_screen,
            commerce: [corridor: :subscription_default, role: :restore_intent]
          ]
      end
    end
  end

  test "the subscription_default commerce corridor lands in the manifest with correct role ownership" do
    assert {:ok, %{manifest: manifest}} = Manifest.compile(CommerceCorridorRoutesRouter)

    corridor = manifest.commerce_corridors["subscription_default"]
    assert corridor != nil, "expected subscription_default commerce corridor in manifest"

    assert corridor.role_ownership.paywall_entry == :phoenix_owned
    assert corridor.role_ownership.purchase_intent == :native_or_companion_required
    assert corridor.role_ownership.restore_intent == :native_or_companion_required
  end

  test "all three corridor route declarations land in the manifest with subscription_default + correct role" do
    assert {:ok, %{manifest: manifest}} = Manifest.compile(CommerceCorridorRoutesRouter)

    paywall_route = manifest.routes["commerce-paywall-entry"]
    assert paywall_route != nil, "expected commerce-paywall-entry in manifest.routes"
    assert paywall_route.commerce.corridor_ref == "subscription_default"
    assert paywall_route.commerce.role == :paywall_entry
    assert paywall_route.runtime == :live_view

    purchase_route = manifest.routes["commerce-purchase-intent"]
    assert purchase_route != nil, "expected commerce-purchase-intent in manifest.routes"
    assert purchase_route.commerce.corridor_ref == "subscription_default"
    assert purchase_route.commerce.role == :purchase_intent
    assert purchase_route.runtime == :native_screen

    restore_route = manifest.routes["commerce-restore-intent"]
    assert restore_route != nil, "expected commerce-restore-intent in manifest.routes"
    assert restore_route.commerce.corridor_ref == "subscription_default"
    assert restore_route.commerce.role == :restore_intent
    assert restore_route.runtime == :native_screen
  end

  test "phase 33 corridor proof stays hermetic and does not depend on the example host" do
    source = File.read!(__ENV__.file) |> String.downcase()

    # Match the example-host *router* dependency specifically (mirrors the
    # phase 23 hermeticity guard) rather than the bare module prefix, which
    # would match this test's own moduledoc.
    refute String.contains?(source, "crosswake" <> "example.router"),
           "phase 33 corridor proof must not depend on the example host router; keep the merge-blocking lane hermetic"

    refute Regex.match?(~r/code\.require_file\s*\(/, source),
           "phase 33 corridor proof must not Code.require_file example-host modules; keep the lane hermetic"
  end
end
