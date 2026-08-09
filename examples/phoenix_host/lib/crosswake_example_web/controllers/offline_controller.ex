defmodule CrosswakeExample.OfflineController do
  use Phoenix.Controller, formats: [:html]

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

  # TODO-002 has not supplied a concrete saved-answer recovery route. Keep the
  # browser closed until Phoenix can resolve one explicit GET capability.
  defp recovery_route_capability, do: %{status: "unavailable", destination: nil}
end
