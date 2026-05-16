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

defmodule Crosswake.TestSupport.StudySessionLive do
  use Phoenix.LiveView

  def render(assigns) do
    ~H"<div>study session</div>"
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
          crosswake: [id: "library", cache_contract: :lesson_library_v1]

        live "/study-session", Crosswake.TestSupport.StudySessionLive,
          crosswake: [
            id: "study-session",
            runtime: :offline_island,
            offline: :local_first,
            island_contract: :study_session_v1,
            sync: [:study_reviews]
          ]

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

  defmodule DefaultsRouter do
    use Crosswake.Router

    scope "/" do
      crosswake_defaults offline: :cached_read_only,
                         capabilities: ["push.notifications"],
                         packs: ["core.content"],
                         sync: ["catalog"],
                         security: :standard do
        get "/reader", Crosswake.TestSupport.PageController, :index,
          crosswake: [id: "reader", runtime: :live_view, cache_contract: :reader_catalog_v1]

        crosswake_defaults runtime: :offline_island,
                           offline: :local_first,
                           capabilities: ["scanner"],
                           packs: ["offline.bundle"],
                           sync: ["drafts"],
                           island_contract: :study_session_v1 do
          live "/study-session", Crosswake.TestSupport.StudySessionLive,
            crosswake: [id: "study-session"]

          live "/capture", Crosswake.TestSupport.CameraLive, :capture,
            crosswake: [
              id: "capture",
              runtime: :native_screen,
              offline: :local_first,
              capabilities: ["camera.capture"],
              packs: ["capture.pack"],
              sync: ["uploads"],
              security: :sensitive
            ]
        end
      end

      get "/public", Crosswake.TestSupport.SettingsController, :index
    end
  end
end
