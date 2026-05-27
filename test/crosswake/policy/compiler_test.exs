Code.require_file("../../support/router_fixtures.ex", __DIR__)

defmodule Crosswake.Policy.CompilerTest do
  use ExUnit.Case, async: true

  alias Crosswake.Policy.Compiler
  alias Crosswake.Policy.Route
  alias Crosswake.TestSupport.RouterFixtures.ManagedRouter

  test "valid routes across all three public runtimes compile into normalized policy output" do
    assert {:ok, %{routes: routes, warnings: []}} = Compiler.compile(ManagedRouter)

    assert Enum.map(routes, &{&1.id, &1.runtime}) == [
             {"dashboard", :live_view},
             {"library", :live_view},
             {"study-session", :offline_island},
             {"camera", :native_screen}
           ]

    assert Enum.all?(routes, &match?(%Route{}, &1))
  end

  test "duplicate ids, missing required metadata, invalid enum values, and adapter runtime fail compilation" do
    routes = [
      route("/dashboard", helper: "page", crosswake: [id: "shared", runtime: :live_view]),
      route("/library", helper: "library", crosswake: [id: "shared", runtime: :offline_island, offline: :local_first, security: :standard]),
      route("/missing-runtime", helper: "missing", crosswake: [id: "missing-runtime"]),
      route("/bad-offline", helper: "bad_offline", crosswake: [id: "bad-offline", runtime: :native_screen, offline: :sometimes]),
      route("/adapter", helper: "adapter", crosswake: [id: "adapter-route", runtime: :adapter])
    ]

    assert {:error, %{errors: errors, warnings: []}} = Compiler.compile(routes)

    assert Enum.any?(errors, &String.contains?(&1.message, "duplicate id"))
    assert Enum.any?(errors, &String.contains?(&1.message, "required :runtime"))
    assert Enum.any?(errors, &String.contains?(&1.message, "invalid value for :offline"))
    assert Enum.any?(errors, &String.contains?(&1.message, "runtime :adapter"))
  end

  test "semantic contradictions fail while environment-dependent checks stay out of compile time" do
    routes = [
      route("/live-local-first",
        helper: "live_local_first",
        crosswake: [id: "live-local-first", runtime: :live_view, offline: :local_first, security: :standard]
      ),
      route("/island-cached",
        helper: "island_cached",
        crosswake: [id: "island-cached", runtime: :offline_island, offline: :unavailable, security: :standard]
      ),
      route("/sync-without-local-first",
        helper: "sync_without_local_first",
        crosswake: [id: "sync-without-local-first", runtime: :native_screen, sync: ["uploads"], offline: :unavailable, security: :sensitive]
      ),
      route("/study-share",
        helper: "study_share",
        crosswake: [
          id: "study-share",
          runtime: :offline_island,
          offline: :local_first,
          entry: :external,
          security: :standard
        ]
      )
    ]

    assert {:error, %{errors: errors}} = Compiler.compile(routes)

    assert Enum.any?(errors, &String.contains?(&1.message, "live_view routes cannot declare offline :local_first"))
    assert Enum.any?(errors, &String.contains?(&1.message, "offline_island routes cannot declare offline :unavailable"))
    assert Enum.any?(errors, &String.contains?(&1.message, "sync declarations require offline support"))
    assert Enum.any?(errors, &String.contains?(&1.message, "entry :external is not supported on offline_island routes"))

    assert {:ok, %{routes: [route], warnings: []}} =
             Compiler.compile([
               route("/camera",
                 helper: "camera",
                 crosswake: [
                   id: "camera",
                   runtime: :native_screen,
                   offline: :local_first,
                   capabilities: ["camera.capture"],
                   packs: [[id: "capture_pack", version: "1.0.0", kind: :media]],
                   sync: ["uploads"],
                   security: :sensitive
                 ]
               )
             ])

    assert %Route{id: "camera", runtime: :native_screen, offline: :local_first} = route
  end

  test "normalized commerce capabilities compile successfully" do
    assert {:ok, %{routes: [route], warnings: []}} =
             Compiler.compile([
               route("/commerce",
                 helper: "commerce",
                 crosswake: [
                   id: "commerce",
                   runtime: :live_view,
                   security: :standard,
                   offline: :unavailable,
                   capabilities: [
                     "paywall_entry",
                     "purchase_intent",
                     "restore_intent",
                     "entitlement_snapshot",
                     "reconciliation_evidence"
                   ]
                 ]
               )
             ])

    assert %Route{id: "commerce"} = route
  end

  test "provider-neutral commerce corridor declarations compile into normalized route metadata" do
    assert {:ok, %{routes: [route], warnings: []}} =
             Compiler.compile([
               route("/paywall",
                 helper: "paywall",
                 crosswake: [
                   id: "paywall",
                   runtime: :live_view,
                   security: :standard,
                   commerce: [corridor: :subscription_default, role: :paywall_entry]
                 ]
               )
             ])

    assert route.commerce == %{corridor: "subscription_default", role: :paywall_entry}
  end

  test "provider-specific commerce vocabulary fails with explicit errors and guidance" do
    routes = [
      route("/paywall",
        helper: "paywall",
        crosswake: [
          id: "paywall",
          runtime: :live_view,
          security: :standard,
          commerce: [corridor: :subscription_default, role: :storekit]
        ]
      ),
      route("/purchase",
        helper: "purchase",
        crosswake: [
          id: "purchase",
          runtime: :live_view,
          security: :standard,
          commerce: [corridor: :play_billing, role: :purchase_intent]
        ]
      )
    ]

    assert {:error, %{errors: errors}} = Compiler.compile(routes)

    assert Enum.any?(errors, &String.contains?(&1.message, "provider-specific commerce role :storekit"))
    assert Enum.any?(errors, &String.contains?(&1.message, "provider-specific corridor vocabulary \"play_billing\""))

    assert Enum.any?(errors, fn error ->
             error.hint ==
               "use commerce: [corridor: :subscription_default, role: :paywall_entry]"
           end)
  end

  test "route entry declarations compile with explicit default and override semantics" do
    assert {:ok, %{routes: routes, warnings: []}} =
             Compiler.compile([
               route("/approvals/:id",
                 helper: "approval",
                 crosswake: [
                   id: "approval",
                   runtime: :live_view,
                   offline: :cached_read_only,
                   entry: :external,
                   security: :standard
                 ]
               ),
               route("/settings/profile",
                 helper: "settings",
                 crosswake: [
                   id: "settings",
                   runtime: :live_view,
                   offline: :cached_read_only,
                   security: :standard
                 ]
               )
             ])

    assert Enum.find(routes, &(&1.id == "approval")).entry == :external
    assert Enum.find(routes, &(&1.id == "settings")).entry == :internal_only
  end

  defp route(path, opts) do
    metadata =
      case Keyword.fetch(opts, :crosswake) do
        {:ok, crosswake} -> %{crosswake: crosswake}
        :error -> %{}
      end

    %{
      path: path,
      metadata: metadata,
      helper: Keyword.get(opts, :helper, "route"),
      verb: Keyword.get(opts, :verb, :get)
    }
  end
end
