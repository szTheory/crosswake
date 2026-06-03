defmodule Crosswake.Manifest.BuilderTest do
  use ExUnit.Case, async: true

  alias Crosswake.Manifest.Builder
  alias Crosswake.Policy.Route

  test "notification_open policy is transferred into RouteEntry" do
    route = %Route{
      id: "notifications-page",
      runtime: :live_view,
      entry: :internal_only,
      notification_open: true
    }

    managed_route = %{
      path: "/notifications",
      metadata: %{crosswake: [id: "notifications-page", runtime: :live_view]},
      helper: "notifications",
      verb: :get
    }

    manifest = Builder.build([route], [managed_route])

    assert manifest.routes["notifications-page"].notification_open == true
  end

  test "notification_open policy with actions is transferred into RouteEntry" do
    route = %Route{
      id: "notifications-page",
      runtime: :live_view,
      entry: :internal_only,
      notification_open: %{actions: [:view, :reply]}
    }

    managed_route = %{
      path: "/notifications",
      metadata: %{crosswake: [id: "notifications-page", runtime: :live_view]},
      helper: "notifications",
      verb: :get
    }

    manifest = Builder.build([route], [managed_route])

    assert manifest.routes["notifications-page"].notification_open == %{actions: [:view, :reply]}
  end
end
