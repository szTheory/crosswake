defmodule Crosswake.TestSupport.PageController do
end

defmodule Crosswake.TestSupport.SettingsController do
end

defmodule Crosswake.TestSupport.AccountController do
end

defmodule Crosswake.TestSupport.DashboardLive do
end

defmodule Crosswake.TestSupport.LibraryLive do
end

defmodule Crosswake.TestSupport.CameraLive do
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
