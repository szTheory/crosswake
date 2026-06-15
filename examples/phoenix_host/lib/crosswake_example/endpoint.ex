defmodule CrosswakeExample.Endpoint do
  use Phoenix.Endpoint, otp_app: :crosswake_example

  @session_options [
    store: :cookie,
    key: "_crosswake_example_key",
    signing_salt: "crosswake"
  ]

  socket("/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]])

  plug(Plug.Static,
    at: "/",
    from: :crosswake_example,
    gzip: false,
    only: ~w(css offline_study.js storage_budget.test.js storage_logic.js)
  )

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
