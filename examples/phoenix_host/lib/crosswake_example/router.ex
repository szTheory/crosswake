defmodule CrosswakeExample.PageController do
  def init(opts), do: opts
  def call(conn, _opts), do: conn
end

defmodule CrosswakeExample.LibraryLive do
  use Phoenix.LiveView

  def render(assigns) do
    ~H"<div>lesson library</div>"
  end
end

defmodule CrosswakeExample.CameraLive do
  use Phoenix.LiveView

  def render(assigns) do
    ~H"<div>media capture</div>"
  end
end

defmodule CrosswakeExample.Router do
  use Phoenix.Router
  # crosswake:install:start
  import Phoenix.Router, except: [get: 3, get: 4, post: 3, post: 4, put: 3, put: 4, patch: 3, patch: 4, delete: 3, delete: 4, options: 3, options: 4, head: 3, head: 4]
  import Phoenix.LiveView.Router, only: [live_session: 3]
  import Crosswake.Router
  @compile {:no_warn_undefined, CrosswakeExample.Crosswake.Policy}
  @crosswake_policy_module CrosswakeExample.Crosswake.Policy
  _ = @crosswake_policy_module
  # crosswake:install:end

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
  end

  pipeline :saas_portal do
    plug CrosswakeExample.SaaSPortal.Auth, :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/study", CrosswakeExample.LocalFirst do
    pipe_through [:api]
    post "/sync", SyncController, :sync
  end

  scope "/study", CrosswakeExample.LocalFirst do
    pipe_through [:browser]

    crosswake_defaults runtime: :live_view, offline: :cached_read_only, security: :standard do
      live "/session", StudySessionLive,
        crosswake: [
          id: "local-first-study-session",
          runtime: :offline_island,
          offline: :local_first,
          packs: [[id: :daily_study, version: "1.0.0", kind: :content]],
          security: :standard
        ]

      live "/history", StudyHistoryLive,
        crosswake: [
          id: "local-first-study-history",
          runtime: :live_view,
          offline: :cached_read_only,
          security: :standard
        ]
    end
  end

  scope "/" do
    pipe_through [:browser]

    crosswake_defaults runtime: :live_view, offline: :cached_read_only, security: :standard do
      get "/", CrosswakeExample.PageController, :index,
        crosswake: [id: "home"]

      live "/library", CrosswakeExample.LibraryLive,
        crosswake: [
          id: "library",
          cache_contract: :lesson_library_v1,
          packs: [[id: :lesson_library, version: "1.2.0", kind: :content]],
          transfers: [
            [
              id: :lesson_import,
              intent: :import,
              source: :native_picker,
              verification: :required,
              media_types: ["application/pdf"]
            ],
            [
              id: :lesson_export,
              intent: :export,
              destination: :user_visible_files,
              verification: :required,
              media_types: ["application/pdf"]
            ],
            [
              id: :lesson_download,
              intent: :download,
              destination: :app_sandbox,
              verification: :required,
              media_types: ["application/pdf"]
            ]
          ]
        ]


    end
  end

  scope "/saas", CrosswakeExample.SaaSPortal do
    pipe_through [:browser, :saas_portal]

    crosswake_defaults runtime: :live_view, offline: :cached_read_only, security: :standard do
      live_session :saas_portal,
        on_mount: [{CrosswakeExample.SaaSPortal.OnMount, :require_authenticated_member}] do
        live "/dashboard", DashboardLive,
          crosswake: [
            id: "saas-dashboard",
            runtime: :live_view,
            offline: :cached_read_only,
            security: :standard
          ]

        live "/accounts/:id", AccountLive,
          crosswake: [
            id: "saas-account",
            runtime: :live_view,
            offline: :cached_read_only,
            security: :standard
          ]

        live "/approvals", ApprovalsLive,
          crosswake: [
            id: "saas-approvals",
            runtime: :live_view,
            offline: :cached_read_only,
            security: :standard
          ]

        live "/approvals/:id", ApprovalLive,
          crosswake: [
            id: "saas-approval",
            runtime: :live_view,
            entry: :external,
            capabilities: ["haptics.impact"],
            offline: :cached_read_only,
            security: :standard
          ]

        live "/settings/profile", SettingsLive,
          crosswake: [
            id: "saas-profile-settings",
            runtime: :live_view,
            entry: :internal_only,
            offline: :cached_read_only,
            security: :standard
          ]
      end
    end
  end

  scope "/native", CrosswakeExample.SelectiveNative do
    pipe_through [:browser]

    crosswake_defaults runtime: :live_view, offline: :cached_read_only, security: :standard do
      live_session :selective_native,
        on_mount: [{CrosswakeExample.SelectiveNative.OnMount, :require_authenticated_member}] do
        live "/claims", ClaimsLive,
          crosswake: [
            id: "selective-native-claims",
            runtime: :live_view,
            offline: :cached_read_only,
            security: :standard
          ]

        live "/claims/:id", ClaimLive,
          crosswake: [
            id: "selective-native-claim",
            runtime: :live_view,
            offline: :cached_read_only,
            security: :standard
          ]

        live "/claims/:id/capture", ClaimCaptureLive,
          crosswake: [
            id: "selective-native-claim-capture",
            runtime: :native_screen,
            capabilities: [:camera],
            packs: [[id: :camera_capture_assets, version: "1.0.0", kind: :media]],
            transfers: [
              [
                id: :capture_upload,
                intent: :upload,
                source: :native_capture,
                verification: :required,
                media_types: ["image/*"]
              ]
            ],
            offline: :cached_read_only,
            security: :sensitive
          ]

        live "/submissions/:id/review", SubmissionReviewLive,
          crosswake: [
            id: "selective-native-submission-review",
            runtime: :live_view,
            offline: :cached_read_only,
            security: :sensitive
          ]
      end
    end
  end

  scope "/commerce", CrosswakeExample do
    pipe_through [:browser]

    crosswake_defaults runtime: :live_view, offline: :unavailable, security: :standard do
      live "/paywall", PaywallEntryLive, :index,
        crosswake: [
          id: "commerce-paywall-entry",
          runtime: :live_view,
          commerce: [corridor: :subscription_default, role: :paywall_entry]
        ]

      post "/purchase", CorridorController, :purchase,
        crosswake: [
          id: "commerce-purchase-intent",
          runtime: :native_screen,
          commerce: [corridor: :subscription_default, role: :purchase_intent]
        ]

      post "/restore", CorridorController, :restore,
        crosswake: [
          id: "commerce-restore-intent",
          runtime: :native_screen,
          commerce: [corridor: :subscription_default, role: :restore_intent]
        ]
    end
  end

  scope "/gating", CrosswakeExample do
    pipe_through [:browser]

    crosswake_defaults runtime: :live_view, offline: :unavailable, security: :standard do
      live "/beta-feature", BetaFeatureLive,
        crosswake: [
          id: "gating-beta-feature",
          gated_by: :rulestead,
          on_unavailable: :deny
        ]
    end
  end
end
