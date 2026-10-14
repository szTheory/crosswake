defmodule Crosswake.TestSupport.HostCommandFixtures do
  @moduledoc false

  defmodule DeclaringRouter do
    use Phoenix.Router

    import Phoenix.Router,
      except: [
        get: 3,
        get: 4,
        post: 3,
        post: 4,
        put: 3,
        put: 4,
        patch: 3,
        patch: 4,
        delete: 3,
        delete: 4,
        options: 3,
        options: 4,
        head: 3,
        head: 4
      ]

    import Phoenix.LiveView.Router, except: [live: 2, live: 3, live: 4], warn: false
    import Crosswake.Router

    crosswake_host_commands([
      {"host.lesson.audio.play", "1.0.0"},
      {"host.review.camera.scan", "1.1.0"}
    ])

    scope "/" do
      live("/lesson", Crosswake.TestSupport.StudySessionLive,
        crosswake: [
          id: "lesson",
          runtime: :offline_island,
          offline: :local_first,
          island_contract: :lesson_v1,
          security: :sensitive,
          capabilities: ["host.lesson.audio.play"]
        ]
      )

      live("/review", Crosswake.TestSupport.DashboardLive,
        crosswake: [
          id: "review",
          runtime: :live_view,
          offline: :cached_read_only,
          security: :standard,
          capabilities: ["host.review.camera.scan"]
        ]
      )

      live("/plain", Crosswake.TestSupport.LibraryLive,
        crosswake: [id: "plain", runtime: :live_view, offline: :unavailable]
      )
    end
  end

  defmodule UseSugarRouter do
    use Crosswake.Router,
      host_commands: [
        {"host.lesson.audio.play", "1.0.0"},
        {"host.review.camera.scan", "1.1.0"}
      ]

    scope "/" do
      live("/lesson", Crosswake.TestSupport.StudySessionLive,
        crosswake: [
          id: "lesson",
          runtime: :offline_island,
          offline: :local_first,
          island_contract: :lesson_v1,
          security: :sensitive,
          capabilities: ["host.lesson.audio.play"]
        ]
      )

      live("/review", Crosswake.TestSupport.DashboardLive,
        crosswake: [
          id: "review",
          runtime: :live_view,
          offline: :cached_read_only,
          security: :standard,
          capabilities: ["host.review.camera.scan"]
        ]
      )

      live("/plain", Crosswake.TestSupport.LibraryLive,
        crosswake: [id: "plain", runtime: :live_view, offline: :unavailable]
      )
    end
  end

  defmodule NoRegistryRouter do
    use Crosswake.Router

    scope "/" do
      live("/lesson", Crosswake.TestSupport.DashboardLive,
        crosswake: [
          id: "lesson",
          runtime: :live_view,
          offline: :cached_read_only,
          security: :standard,
          capabilities: ["host.lesson.audio.play"]
        ]
      )
    end
  end

  defmodule NativeScreenRouter do
    use Crosswake.Router

    crosswake_host_commands([{"host.lesson.audio.play", "1.0.0"}])

    scope "/" do
      live("/scan", Crosswake.TestSupport.DashboardLive,
        crosswake: [
          id: "scan",
          runtime: :native_screen,
          offline: :unavailable,
          security: :standard,
          capabilities: ["host.lesson.audio.play"]
        ]
      )
    end
  end

  defmodule MisspelledRouter do
    use Crosswake.Router

    crosswake_host_commands([{"host.lesson.audio.play", "1.0.0"}])

    scope "/" do
      live("/lesson", Crosswake.TestSupport.DashboardLive,
        crosswake: [
          id: "lesson",
          runtime: :live_view,
          offline: :unavailable,
          security: :standard,
          capabilities: ["host.lesson.audio.ply"]
        ]
      )
    end
  end

  defmodule PermutedRegistryRouter do
    use Phoenix.Router

    import Phoenix.Router,
      except: [
        get: 3,
        get: 4,
        post: 3,
        post: 4,
        put: 3,
        put: 4,
        patch: 3,
        patch: 4,
        delete: 3,
        delete: 4,
        options: 3,
        options: 4,
        head: 3,
        head: 4
      ]

    import Phoenix.LiveView.Router, except: [live: 2, live: 3, live: 4], warn: false
    import Crosswake.Router

    crosswake_host_commands([
      {"host.review.camera.scan", "1.1.0"},
      {"host.lesson.audio.play", "1.0.0"}
    ])

    scope "/" do
      live("/lesson", Crosswake.TestSupport.StudySessionLive,
        crosswake: [
          id: "lesson",
          runtime: :offline_island,
          offline: :local_first,
          island_contract: :lesson_v1,
          security: :sensitive,
          capabilities: ["host.lesson.audio.play"]
        ]
      )

      live("/review", Crosswake.TestSupport.DashboardLive,
        crosswake: [
          id: "review",
          runtime: :live_view,
          offline: :cached_read_only,
          security: :standard,
          capabilities: ["host.review.camera.scan"]
        ]
      )

      live("/plain", Crosswake.TestSupport.LibraryLive,
        crosswake: [id: "plain", runtime: :live_view, offline: :unavailable]
      )
    end
  end
end
