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
          crosswake: [
            id: "library",
            cache_contract: :lesson_library_v1,
            packs: [[id: :lesson_library, version: "1.2.0", kind: :content]]
          ]

        live "/study-session", Crosswake.TestSupport.StudySessionLive,
          crosswake: [
            id: "study-session",
            runtime: :offline_island,
            offline: :local_first,
            island_contract: :study_session_v1,
            packs: [[id: :study_session_media, version: "3.0.0", kind: :media]],
            sync: [:study_reviews]
          ]

        live "/camera", Crosswake.TestSupport.CameraLive, :capture,
          crosswake: [
            id: "camera",
            runtime: :native_screen,
            capabilities: [:camera],
            packs: [[id: :camera_capture_assets, version: "1.0.0", kind: :media]],
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
                         packs: [[id: :core_content, version: "1.0.0", kind: :content]],
                         sync: ["catalog"],
                         security: :standard do
        get "/reader", Crosswake.TestSupport.PageController, :index,
          crosswake: [id: "reader", runtime: :live_view, cache_contract: :reader_catalog_v1]

        live "/study-session", Crosswake.TestSupport.StudySessionLive,
          crosswake: [
            id: "study-session",
            runtime: :offline_island,
            offline: :local_first,
            capabilities: ["scanner"],
            packs: [[id: :offline_bundle, version: "2.1.0", kind: :content]],
            sync: ["drafts"],
            island_contract: :study_session_v1
          ]

        live "/capture", Crosswake.TestSupport.CameraLive, :capture,
          crosswake: [
            id: "capture",
            runtime: :native_screen,
            offline: :local_first,
            capabilities: ["camera.capture"],
            packs: [[id: :capture_pack, version: "1.0.0", kind: :media]],
            sync: ["uploads"],
            security: :sensitive
          ]
      end

      get "/public", Crosswake.TestSupport.SettingsController, :index
    end
  end
end
