defmodule CrosswakeExample.OfflineController do
  use Phoenix.Controller, formats: [:html]

  use Phoenix.VerifiedRoutes,
    endpoint: CrosswakeExample.Endpoint,
    router: CrosswakeExample.Router,
    statics: ~w()

  alias CrosswakeExample.PageTitle
  alias Crosswake.Offline.Contracts

  def index(conn, _params) do
    # Render the minimal offline HTML layout. It doesn't use LiveView.
    # It must be served without the standard app layout to remain minimal
    # and easy to cache.

    island =
      Contracts.new_study_session_island(
        "study_session_v1",
        route_id: "study-session",
        sync_seam: "study_reviews",
        storage_budget: {:mb, 50},
        reserve_for_journal: {:mb, 5},
        eviction: :manual
      )

    conn
    |> put_view(CrosswakeExample.OfflineHTML)
    |> put_root_layout(false)
    |> render(
      :index,
      page_title: PageTitle.learn("Offline Study"),
      island: island,
      recovery_route: recovery_route_capability()
    )
  end

  # The review page is a real host-owned GET destination (D-11). It reads the active
  # scope's retained work from the learner's own device; nothing is fetched or sent
  # unless the learner chooses Try again.
  def review(conn, _params) do
    conn
    |> put_view(CrosswakeExample.OfflineHTML)
    |> put_root_layout(false)
    |> render(:review, page_title: PageTitle.learn("Review Saved Answers"))
  end

  defp recovery_route_capability, do: %{status: "available", destination: ~p"/offline/review"}
end
