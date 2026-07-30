defmodule CrosswakeExample.Endpoint do
  use Phoenix.Endpoint, otp_app: :crosswake_example

  @session_options [
    store: :cookie,
    key: "_crosswake_example_key",
    signing_salt: "crosswake"
  ]

  socket("/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]])

  if code_reloading? do
    socket("/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket)
    plug(Phoenix.LiveReloader)
    plug(Phoenix.CodeReloader)
  end

  plug(Plug.Static,
    at: "/",
    from: :crosswake_example,
    gzip: false,
    only: ~w(brand css offline_study.js storage_budget.test.js storage_logic.js)
  )

  plug(Plug.Static,
    at: "/phoenix",
    from: :phoenix,
    gzip: false,
    only: ~w(phoenix.mjs)
  )

  plug(Plug.Static,
    at: "/phoenix_live_view",
    from: :phoenix_live_view,
    gzip: false,
    only: ~w(phoenix_live_view.esm.js)
  )

  # crosswake:install:start
  plug(Plug.Static,
    at: "/crosswake",
    from: :crosswake,
    gzip: false,
    only: ~w(crosswake.esm.js)
  )
  # crosswake:install:end

  plug(Plug.RequestId)
  plug(Plug.Telemetry, event_prefix: [:phoenix, :endpoint])

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Jason
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)
  plug(Plug.Session, @session_options)
  plug(CrosswakeExample.Router)
end
