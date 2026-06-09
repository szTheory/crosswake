defmodule CrosswakeExampleWeb.OfflineController do
  use CrosswakeExampleWeb, :controller

  def index(conn, _params) do
    # Render the minimal offline HTML layout. It doesn't use LiveView.
    # It must be served without the standard app layout to remain minimal
    # and easy to cache.
    conn
    |> put_root_layout(false)
    |> render(:index, page_title: "Offline Study")
  end
end
