import Config

config :crosswake_example, CrosswakeExample.Endpoint,
  code_reloader: true,
  check_origin: false,
  live_reload: [
    patterns: [
      ~r"lib/.+\.ex(s)?$",
      ~r"priv/static/.+\.(css|js)$"
    ],
    interval: 1500
  ]

config :crosswake_example, CrosswakeExample.Repo,
  show_sensitive_data_on_connection_error: true
