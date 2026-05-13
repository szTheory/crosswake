defmodule Crosswake.TestSupport.PageController do
  def init(opts), do: opts
  def call(conn, _opts), do: conn
end

defmodule Crosswake.TestSupport.SettingsController do
  def init(opts), do: opts
  def call(conn, _opts), do: conn
end

defmodule Crosswake.TestSupport.AccountController do
  def init(opts), do: opts
  def call(conn, _opts), do: conn
end

defmodule Crosswake.TestSupport.DashboardLive do
  use Phoenix.LiveView

  def render(assigns) do
    ~H"<div>dashboard</div>"
  end
end

defmodule Crosswake.TestSupport.LibraryLive do
  use Phoenix.LiveView

  def render(assigns) do
    ~H"<div>library</div>"
  end
end

defmodule Crosswake.TestSupport.CameraLive do
  use Phoenix.LiveView

  def render(assigns) do
    ~H"<div>camera</div>"
  end
end

defmodule Crosswake.TestSupport.RouterFixtures do
  defmodule ManagedRouter do
    use Crosswake.Router

    scope "/" do
      crosswake_defaults runtime: :live_view, offline: :cached_read_only, security: :standard do
        get "/dashboard", Crosswake.TestSupport.PageController, :index,
          crosswake: [id: "dashboard"]

        live "/library", Crosswake.TestSupport.LibraryLive,
          crosswake: [id: "library", runtime: :offline_island, sync: [:journal]]

        live "/camera", Crosswake.TestSupport.CameraLive, :capture,
          crosswake: [
            id: "camera",
            runtime: :native_screen,
            capabilities: [:camera],
            security: :sensitive
          ]
      end

      get "/settings", Crosswake.TestSupport.SettingsController, :index
    end
  end
end
