defmodule CrosswakeExample.OfflineController do
  use Phoenix.Controller, formats: [:html]

  def index(conn, _params) do
    # Render the minimal offline HTML layout. It doesn't use LiveView.
    # It must be served without the standard app layout to remain minimal
    # and easy to cache.
    conn
    |> put_view(CrosswakeExample.OfflineHTML)
    |> put_root_layout(false)
    |> render(:index, page_title: "Offline Study")
  end
end
